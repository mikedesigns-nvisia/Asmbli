import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agent_mcp_server_config.dart';
import '../models/mcp_server_config.dart';
import '../models/mcp_server_process.dart';
import '../models/mcp_catalog_entry.dart';
import '../mcp/process/mcp_process_manager.dart' as new_mcp;
import 'mcp_catalog_service.dart';
import 'desktop/desktop_storage_service.dart';
import '../utils/app_logger.dart';
import '../di/service_locator.dart';

/// Consolidated service for Agent MCP integration
/// Combines functionality from DirectMCPAgentService and AgentMCPConfigurationService
/// Handles:
/// 1. Agent-specific MCP configuration
/// 2. Tool execution
/// 3. Session management
class AgentMCPService {
  final MCPCatalogService _catalogService;
  final DesktopStorageService _storage;
  final new_mcp.MCPProcessManager _mcpManager;

  // Cache for agent configurations
  final Map<String, List<AgentMCPServerConfig>> _agentConfigsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidDuration = Duration(minutes: 15);

  // Active sessions: ServerId -> Session
  final Map<String, new_mcp.MCPServerSession> _sessions = {};

  AgentMCPService(
    this._catalogService,
    this._storage,
  ) : _mcpManager = new_mcp.MCPProcessManager.instance;

  // ===========================================================================
  // Configuration Management (from AgentMCPConfigurationService)
  // ===========================================================================

  /// Get all MCP server configurations for a specific agent
  Future<List<AgentMCPServerConfig>> getAgentMCPConfigs(String agentId) async {
    if (_agentConfigsCache.containsKey(agentId) && _isCacheValid(agentId)) {
      return _agentConfigsCache[agentId]!;
    }

    try {
      final configsData = _storage.getHiveData<String>('agent_mcp_configs', agentId);
      final configs = <AgentMCPServerConfig>[];

      if (configsData != null) {
        final configsList = jsonDecode(configsData) as List<dynamic>;
        configs.addAll(configsList.map((json) => _agentMCPConfigFromJson(json as Map<String, dynamic>)));
      }

      _agentConfigsCache[agentId] = configs;
      _cacheTimestamps[agentId] = DateTime.now();

      return configs;
    } catch (e) {
      AppLogger.error('Failed to load agent MCP configs', error: e, component: 'AgentMCPService');
      return [];
    }
  }

  /// Enable a GitHub MCP registry tool for an agent
  Future<AgentMCPServerConfig> enableGitHubMCPToolForAgent(
    String agentId,
    String catalogEntryId, {
    Map<String, String> environmentVars = const {},
    List<String> requiredCapabilities = const [],
    int priority = 0,
    bool autoStart = true,
  }) async {
    final catalogEntry = await _catalogService.getCatalogEntry(catalogEntryId);
    if (catalogEntry == null) {
      throw Exception('MCP catalog entry not found: $catalogEntryId');
    }

    final serverConfig = MCPServerConfig(
      id: catalogEntry.id,
      name: catalogEntry.name,
      url: catalogEntry.remoteUrl ?? 'github://registry/${catalogEntry.id}',
      command: catalogEntry.command,
      args: catalogEntry.args,
      env: {
        ...catalogEntry.defaultEnvVars,
        ...environmentVars,
      },
      workingDirectory: null,
      type: 'github_registry',
      enabled: true,
      transportType: catalogEntry.transport,
      requiredEnvVars: catalogEntry.requiredEnvVars,
      optionalEnvVars: catalogEntry.optionalEnvVars,
      setupInstructions: catalogEntry.setupInstructions,
      capabilities: catalogEntry.capabilities,
      description: catalogEntry.description,
    );

    final agentConfig = AgentMCPServerConfig(
      agentId: agentId,
      serverId: catalogEntry.id,
      serverConfig: serverConfig,
      isEnabled: true,
      agentSpecificEnv: environmentVars,
      requiredCapabilities: requiredCapabilities,
      priority: priority,
      autoStart: autoStart,
    );

    await _saveAgentMCPConfig(agentConfig);
    return agentConfig;
  }

  /// Disable/remove MCP tool from agent
  Future<void> disableMCPToolForAgent(String agentId, String serverId) async {
    final configs = await getAgentMCPConfigs(agentId);
    final updatedConfigs = configs.where((config) => config.serverId != serverId).toList();
    await _saveAgentMCPConfigs(agentId, updatedConfigs);
    
    // Also stop the server if running
    await stopServer(serverId);
  }

  /// Get enabled MCP server IDs for an agent
  Future<List<String>> getEnabledMCPServerIds(String agentId) async {
    final configs = await getAgentMCPConfigs(agentId);
    return configs
        .where((config) => config.isEnabled)
        .map((config) => config.serverId)
        .toList();
  }

  // Compatibility methods for AgentMCPSessionService
  /// Check if a specific MCP server is enabled for an agent
  Future<bool> isAgentMCPToolEnabled(String agentId, String serverId) async {
    final enabledIds = await getEnabledMCPServerIds(agentId);
    return enabledIds.contains(serverId);
  }

  /// Retrieve environment variables for a given agent/server configuration
  Future<Map<String, String>> getAgentMCPEnvironment(String agentId, String serverId) async {
    final configs = await getAgentMCPConfigs(agentId);
    try {
      final config = configs.firstWhere((c) => c.serverId == serverId);
      return config.serverConfig.env ?? {};
    } catch (e) {
      // Server not found
      return {};
    }
  }

  /// Sync agent server configurations with a list of server IDs from the UI
  /// This bridges the gap between the Tools UI (which updates Agent.configuration)
  /// and the execution layer (which uses agent_mcp_configs)
  Future<void> syncAgentServerConfigs(
    String agentId,
    List<String> desiredServerIds,
  ) async {
    try {
      final currentConfigs = await getAgentMCPConfigs(agentId);
      final currentServerIds = currentConfigs.map((c) => c.serverId).toSet();
      final desiredServerIdSet = desiredServerIds.toSet();

      // Find servers to enable (new servers not in current config)
      final serversToEnable = desiredServerIdSet.difference(currentServerIds);

      // Find servers to disable (servers in current config but not in desired list)
      final serversToDisable = currentServerIds.difference(desiredServerIdSet);

      AppLogger.info(
        'Syncing agent MCP configs: Enable ${serversToEnable.length}, Disable ${serversToDisable.length}',
        component: 'AgentMCPService',
      );

      // Enable new servers
      for (final serverId in serversToEnable) {
        try {
          await enableGitHubMCPToolForAgent(
            agentId,
            serverId,
            environmentVars: {}, // No env vars by default, user can configure later
          );
          AppLogger.info(
            'Enabled MCP server: $serverId for agent: $agentId',
            component: 'AgentMCPService',
          );
        } catch (e) {
          AppLogger.error(
            'Failed to enable MCP server: $serverId',
            error: e,
            component: 'AgentMCPService',
          );
          // Continue with other servers even if one fails
        }
      }

      // Disable removed servers
      for (final serverId in serversToDisable) {
        try {
          await disableMCPToolForAgent(agentId, serverId);
          AppLogger.info(
            'Disabled MCP server: $serverId for agent: $agentId',
            component: 'AgentMCPService',
          );
        } catch (e) {
          AppLogger.error(
            'Failed to disable MCP server: $serverId',
            error: e,
            component: 'AgentMCPService',
          );
        }
      }

      // Update configs for servers that remain (preserve env vars and settings)
      final remainingServerIds = currentServerIds.intersection(desiredServerIdSet);
      if (remainingServerIds.isNotEmpty) {
        final updatedConfigs = currentConfigs
            .where((config) => remainingServerIds.contains(config.serverId))
            .map((config) => config.copyWith(isEnabled: true))
            .toList();
        
        // Add newly enabled servers to the list
        final newConfigs = currentConfigs
            .where((config) => serversToEnable.contains(config.serverId))
            .toList();
        
        updatedConfigs.addAll(newConfigs);
        
        await _saveAgentMCPConfigs(agentId, updatedConfigs);
      }

      AppLogger.info(
        'Successfully synced MCP configs for agent: $agentId',
        component: 'AgentMCPService',
      );
    } catch (e) {
      AppLogger.error(
        'Failed to sync agent MCP configs',
        error: e,
        component: 'AgentMCPService',
      );
      rethrow;
    }
  }

  // ===========================================================================
  // Tool Execution & Session Management (from DirectMCPAgentService)
  // ===========================================================================

  /// Execute MCP tool
  Future<MCPExecutionResult> executeTool(
    String toolName,
    Map<String, dynamic> arguments, {
    String? agentId,
    String? serverId,
    MCPServerConfig? serverConfig,
    Duration? timeout,
  }) async {
    final startTime = DateTime.now();
    String? effectiveServerId = serverId;

    try {
      AppLogger.info(
        'Executing MCP tool: $toolName (Server: $serverId)',
        component: 'AgentMCPService',
      );

      new_mcp.MCPServerSession session;

      if (serverId != null && _sessions.containsKey(serverId)) {
        session = _sessions[serverId]!;
      } else if (serverConfig != null) {
        effectiveServerId = serverConfig.id;
        session = await _getOrCreateSession(serverConfig.id, serverConfig);
      } else if (agentId != null) {
        // Fallback: try to find an enabled server for this agent that has the tool?
        // Or use a default server convention.
        // For now, we maintain the legacy behavior of "default-agentId" if no specific server targeted
        // But ideally, we should route based on tool name if possible, or require serverId.
        // Assuming the caller knows the serverId (which ConversationBusinessService does).
        final defaultServerId = 'default-$agentId';
        effectiveServerId = defaultServerId;
        session = await _getOrCreateSession(defaultServerId, _createDefaultConfig(agentId));
      } else {
        throw AgentMCPException('No serverId, serverConfig, or agentId provided for tool execution');
      }

      if (!session.isHealthy) {
        throw AgentMCPException('MCP session for server $effectiveServerId is not healthy');
      }

      final result = await session.callTool(toolName, arguments);
      final executionTime = DateTime.now().difference(startTime);

      return MCPExecutionResult(
        success: true,
        result: result,
        executionTime: executionTime,
        timestamp: DateTime.now(),
        toolName: toolName,
        serverId: effectiveServerId ?? 'unknown',
        arguments: arguments,
      );

    } catch (e) {
      final executionTime = DateTime.now().difference(startTime);
      AppLogger.error('MCP tool execution failed: $toolName', error: e, component: 'AgentMCPService');

      return MCPExecutionResult(
        success: false,
        error: e.toString(),
        executionTime: executionTime,
        timestamp: DateTime.now(),
        toolName: toolName,
        serverId: effectiveServerId ?? 'unknown',
        arguments: arguments,
      );
    }
  }

  /// Get available tools for an agent/server
  Future<List<MCPToolDefinition>> getAvailableTools({
    String? agentId,
    String? serverId,
    MCPServerConfig? serverConfig,
  }) async {
    try {
      new_mcp.MCPServerSession session;
      
      if (serverId != null && _sessions.containsKey(serverId)) {
        session = _sessions[serverId]!;
      } else if (serverConfig != null) {
        session = await _getOrCreateSession(serverConfig.id, serverConfig);
      } else if (agentId != null) {
        final defaultServerId = 'default-$agentId';
        session = await _getOrCreateSession(defaultServerId, _createDefaultConfig(agentId));
      } else {
        return [];
      }

      final tools = await session.getTools();

      return tools.map((tool) => MCPToolDefinition(
        name: tool['name'] as String? ?? 'unknown',
        description: tool['description'] as String? ?? '',
        parameters: tool['inputSchema'] as Map<String, dynamic>? ?? {},
      )).toList();

    } catch (e) {
      AppLogger.error('Failed to get available tools', error: e, component: 'AgentMCPService');
      return [];
    }
  }

  /// Start a specific server
  Future<void> startServer(MCPServerConfig config) async {
    await _getOrCreateSession(config.id, config);
  }

  /// Stop a specific server
  Future<void> stopServer(String serverId) async {
    final session = _sessions[serverId];
    if (session != null) {
      await _mcpManager.stopServer(session.sessionId);
      _sessions.remove(serverId);
      AppLogger.info('MCP server stopped: $serverId', component: 'AgentMCPService');
    }
  }

  /// Start all enabled servers for an agent
  Future<void> startAgentServers(String agentId) async {
    final configs = await getAgentMCPConfigs(agentId);
    for (final config in configs) {
      if (config.isEnabled && config.autoStart) {
        try {
          // Merge agent-specific env vars
          final effectiveConfig = config.serverConfig.copyWith(
            env: {
              ...?config.serverConfig.env,
              ...config.agentSpecificEnv,
            }
          );
          await startServer(effectiveConfig);
        } catch (e) {
          AppLogger.error('Failed to start agent server: ${config.serverId}', error: e, component: 'AgentMCPService');
        }
      }
    }
  }

  // ===========================================================================
  // Internal Helpers
  // ===========================================================================

  Future<new_mcp.MCPServerSession> _getOrCreateSession(
    String serverId,
    MCPServerConfig config,
  ) async {
    final existingSession = _sessions[serverId];
    if (existingSession != null && existingSession.isHealthy) {
      return existingSession;
    }

    final session = await _mcpManager.startServer(config);
    _sessions[serverId] = session;
    return session;
  }

  MCPServerConfig _createDefaultConfig(String agentId) {
    return MCPServerConfig(
      id: 'default-$agentId',
      name: 'Default MCP Server for $agentId',
      url: 'local://agent-$agentId',
      command: 'echo',
      args: ['MCP server not configured'],
      enabled: true,
      timeout: 30,
      autoReconnect: false,
    );
  }

  bool _isCacheValid(String agentId) {
    final timestamp = _cacheTimestamps[agentId];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheValidDuration;
  }

  Future<void> _saveAgentMCPConfig(AgentMCPServerConfig config) async {
    final configs = await getAgentMCPConfigs(config.agentId);
    final existingIndex = configs.indexWhere((c) => c.serverId == config.serverId);
    if (existingIndex != -1) {
      configs[existingIndex] = config;
    } else {
      configs.add(config);
    }
    await _saveAgentMCPConfigs(config.agentId, configs);
  }

  Future<void> _saveAgentMCPConfigs(String agentId, List<AgentMCPServerConfig> configs) async {
    final configsJson = configs.map((config) => _agentMCPConfigToJson(config)).toList();
    await _storage.setHiveData('agent_mcp_configs', agentId, jsonEncode(configsJson));
    _agentConfigsCache[agentId] = configs;
    _cacheTimestamps[agentId] = DateTime.now();
  }

  Map<String, dynamic> _agentMCPConfigToJson(AgentMCPServerConfig config) {
    // ... (Same JSON serialization logic as before)
    return {
      'agentId': config.agentId,
      'serverId': config.serverId,
      'serverConfig': config.serverConfig.toJson(),
      'isEnabled': config.isEnabled,
      'lastUsed': config.lastUsed?.toIso8601String(),
      'agentSpecificEnv': config.agentSpecificEnv,
      'requiredCapabilities': config.requiredCapabilities,
      'priority': config.priority,
      'autoStart': config.autoStart,
    };
  }

  AgentMCPServerConfig _agentMCPConfigFromJson(Map<String, dynamic> json) {
    // ... (Same JSON deserialization logic as before)
    return AgentMCPServerConfig(
      agentId: json['agentId'] as String,
      serverId: json['serverId'] as String,
      serverConfig: MCPServerConfig.fromJson(json['serverConfig'] as Map<String, dynamic>),
      isEnabled: json['isEnabled'] as bool,
      lastUsed: json['lastUsed'] != null ? DateTime.parse(json['lastUsed'] as String) : null,
      agentSpecificEnv: Map<String, String>.from(json['agentSpecificEnv'] as Map? ?? {}),
      requiredCapabilities: List<String>.from(json['requiredCapabilities'] as List? ?? []),
      priority: json['priority'] as int? ?? 0,
      autoStart: json['autoStart'] as bool? ?? true,
    );
  }
}

/// Result of an MCP tool execution
class MCPExecutionResult {
  final bool success;
  final Map<String, dynamic>? result;
  final String? error;
  final Duration executionTime;
  final DateTime timestamp;
  final String toolName;
  final String serverId;
  final Map<String, dynamic> arguments;

  const MCPExecutionResult({
    required this.success,
    this.result,
    this.error,
    required this.executionTime,
    required this.timestamp,
    this.toolName = '',
    this.serverId = '',
    this.arguments = const {},
  });
}

class MCPToolDefinition {
  final String name;
  final String description;
  final Map<String, dynamic> parameters;

  const MCPToolDefinition({
    required this.name,
    required this.description,
    required this.parameters,
  });
}

class AgentMCPException implements Exception {
  final String message;
  const AgentMCPException(this.message);
  @override
  String toString() => 'AgentMCPException: $message';
}

/// Provider for AgentMCPService
final agentMCPServiceProvider = Provider<AgentMCPService>((ref) {
  return ServiceLocator.instance.get<AgentMCPService>();
});
