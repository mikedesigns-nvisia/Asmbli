import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agent_mcp_server_config.dart';
import '../models/mcp_catalog_entry.dart';
import '../models/mcp_server_process.dart';
import 'mcp_catalog_service.dart';
import 'desktop/desktop_storage_service.dart';
import '../di/service_locator.dart';

/// Service for managing MCP server configurations for specific agents
/// Links agents to GitHub MCP registry tools and manages their configurations
@Deprecated('Will be consolidated into AgentMCPService. See docs/SERVICE_CONSOLIDATION_PLAN.md')
class AgentMCPConfigurationService {
  final MCPCatalogService _catalogService;
  final DesktopStorageService _storage;

  // Cache for agent configurations
  final Map<String, List<AgentMCPServerConfig>> _agentConfigsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidDuration = Duration(minutes: 15);

  AgentMCPConfigurationService(
    this._catalogService,
    this._storage,
  );

  /// Get all MCP server configurations for a specific agent
  Future<List<AgentMCPServerConfig>> getAgentMCPConfigs(String agentId) async {
    // Check cache first
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

      // Update cache
      _agentConfigsCache[agentId] = configs;
      _cacheTimestamps[agentId] = DateTime.now();

      return configs;
    } catch (e) {
      print('⚠️ Failed to load agent MCP configs: $e');
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
    // Get the catalog entry
    final catalogEntry = await _catalogService.getCatalogEntry(catalogEntryId);
    if (catalogEntry == null) {
      throw Exception('MCP catalog entry not found: $catalogEntryId');
    }

    // Create server configuration from catalog entry
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

    // Create agent-specific configuration
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

    // Save the configuration
    await _saveAgentMCPConfig(agentConfig);

    return agentConfig;
  }

  /// Disable/remove MCP tool from agent
  Future<void> disableMCPToolForAgent(String agentId, String serverId) async {
    final configs = await getAgentMCPConfigs(agentId);
    final updatedConfigs = configs.where((config) => config.serverId != serverId).toList();

    await _saveAgentMCPConfigs(agentId, updatedConfigs);
  }

  /// Update agent-specific environment variables for an MCP tool
  Future<AgentMCPServerConfig> updateAgentMCPEnvironment(
    String agentId,
    String serverId,
    Map<String, String> environmentVars,
  ) async {
    final configs = await getAgentMCPConfigs(agentId);
    final configIndex = configs.indexWhere((config) => config.serverId == serverId);

    if (configIndex == -1) {
      throw Exception('MCP server configuration not found for agent');
    }

    final updatedConfig = configs[configIndex].copyWith(
      agentSpecificEnv: {
        ...configs[configIndex].agentSpecificEnv,
        ...environmentVars,
      },
    );

    configs[configIndex] = updatedConfig;
    await _saveAgentMCPConfigs(agentId, configs);

    return updatedConfig;
  }

  /// Get available GitHub MCP tools that can be added to an agent
  Future<List<MCPCatalogEntry>> getAvailableGitHubMCPTools({
    String? searchQuery,
    List<String>? tags,
    bool featuredOnly = false,
  }) async {
    final entries = await _catalogService.getAllEntries();

    var filteredEntries = entries;

    // Filter by search query
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filteredEntries = filteredEntries.where((entry) =>
        entry.name.toLowerCase().contains(query) ||
        entry.description.toLowerCase().contains(query) ||
        entry.tags.any((tag) => tag.toLowerCase().contains(query))
      ).toList();
    }

    // Filter by tags
    if (tags != null && tags.isNotEmpty) {
      filteredEntries = filteredEntries.where((entry) =>
        tags.any((tag) => entry.tags.contains(tag))
      ).toList();
    }

    // Filter by featured status
    if (featuredOnly) {
      filteredEntries = filteredEntries.where((entry) => entry.isFeatured).toList();
    }

    return filteredEntries;
  }

  /// Get enabled MCP server IDs for an agent
  Future<List<String>> getEnabledMCPServerIds(String agentId) async {
    final configs = await getAgentMCPConfigs(agentId);
    return configs
        .where((config) => config.isEnabled)
        .map((config) => config.serverId)
        .toList();
  }

  /// Check if an agent has a specific MCP tool enabled
  Future<bool> isAgentMCPToolEnabled(String agentId, String serverId) async {
    final configs = await getAgentMCPConfigs(agentId);
    return configs.any((config) =>
      config.serverId == serverId && config.isEnabled
    );
  }

  /// Get agent-specific environment for MCP server
  Future<Map<String, String>> getAgentMCPEnvironment(String agentId, String serverId) async {
    final configs = await getAgentMCPConfigs(agentId);
    final config = configs.firstWhere(
      (config) => config.serverId == serverId,
      orElse: () => throw Exception('MCP server configuration not found'),
    );

    return {
      ...config.serverConfig.env ?? {},
      ...config.agentSpecificEnv,
    };
  }

  /// Get MCP server configuration for agent
  Future<AgentMCPServerConfig?> getAgentMCPConfig(String agentId, String serverId) async {
    final configs = await getAgentMCPConfigs(agentId);
    try {
      return configs.firstWhere((config) => config.serverId == serverId);
    } catch (e) {
      return null;
    }
  }

  /// Mark MCP server as used (for analytics/priority)
  Future<void> markMCPServerUsed(String agentId, String serverId) async {
    final configs = await getAgentMCPConfigs(agentId);
    final configIndex = configs.indexWhere((config) => config.serverId == serverId);

    if (configIndex != -1) {
      configs[configIndex] = configs[configIndex].copyWith(
        lastUsed: DateTime.now(),
      );
      await _saveAgentMCPConfigs(agentId, configs);
    }
  }

  /// Get MCP servers sorted by priority and usage
  Future<List<AgentMCPServerConfig>> getOrderedMCPServers(String agentId) async {
    final configs = await getAgentMCPConfigs(agentId);

    configs.sort((a, b) {
      // First sort by enabled status
      if (a.isEnabled != b.isEnabled) {
        return b.isEnabled ? 1 : -1;
      }

      // Then by priority (higher priority first)
      if (a.priority != b.priority) {
        return b.priority.compareTo(a.priority);
      }

      // Then by last used (more recent first)
      if (a.lastUsed != null && b.lastUsed != null) {
        return b.lastUsed!.compareTo(a.lastUsed!);
      } else if (a.lastUsed != null) {
        return -1;
      } else if (b.lastUsed != null) {
        return 1;
      }

      // Finally by name
      return a.serverConfig.name.compareTo(b.serverConfig.name);
    });

    return configs;
  }

  /// Clear cache for specific agent
  void clearAgentCache(String agentId) {
    _agentConfigsCache.remove(agentId);
    _cacheTimestamps.remove(agentId);
  }

  /// Clear all cache
  void clearAllCache() {
    _agentConfigsCache.clear();
    _cacheTimestamps.clear();
  }

  // Private methods

  bool _isCacheValid(String agentId) {
    final timestamp = _cacheTimestamps[agentId];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheValidDuration;
  }

  Future<void> _saveAgentMCPConfig(AgentMCPServerConfig config) async {
    final configs = await getAgentMCPConfigs(config.agentId);

    // Update existing or add new
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

    // Update cache
    _agentConfigsCache[agentId] = configs;
    _cacheTimestamps[agentId] = DateTime.now();
  }

  Map<String, dynamic> _agentMCPConfigToJson(AgentMCPServerConfig config) {
    return {
      'agentId': config.agentId,
      'serverId': config.serverId,
      'serverConfig': {
        'id': config.serverConfig.id,
        'name': config.serverConfig.name,
        'url': config.serverConfig.url,
        'command': config.serverConfig.command,
        'args': config.serverConfig.args,
        'env': config.serverConfig.env,
        'workingDirectory': config.serverConfig.workingDirectory,
        'type': config.serverConfig.type,
        'enabled': config.serverConfig.enabled,
        'transportType': config.serverConfig.transportType.toString(),
        'requiredEnvVars': config.serverConfig.requiredEnvVars,
        'optionalEnvVars': config.serverConfig.optionalEnvVars,
        'setupInstructions': config.serverConfig.setupInstructions,
        'capabilities': config.serverConfig.capabilities,
        'description': config.serverConfig.description,
      },
      'isEnabled': config.isEnabled,
      'lastUsed': config.lastUsed?.toIso8601String(),
      'agentSpecificEnv': config.agentSpecificEnv,
      'requiredCapabilities': config.requiredCapabilities,
      'priority': config.priority,
      'autoStart': config.autoStart,
    };
  }

  AgentMCPServerConfig _agentMCPConfigFromJson(Map<String, dynamic> json) {
    final serverConfigJson = json['serverConfig'] as Map<String, dynamic>;

    return AgentMCPServerConfig(
      agentId: json['agentId'] as String,
      serverId: json['serverId'] as String,
      serverConfig: MCPServerConfig(
        id: serverConfigJson['id'] as String,
        name: serverConfigJson['name'] as String,
        url: serverConfigJson['url'] as String,
        command: serverConfigJson['command'] as String,
        args: List<String>.from(serverConfigJson['args'] as List),
        env: Map<String, String>.from(serverConfigJson['env'] as Map? ?? {}),
        workingDirectory: serverConfigJson['workingDirectory'] as String?,
        type: serverConfigJson['type'] as String,
        enabled: serverConfigJson['enabled'] as bool,
        transportType: MCPTransportType.values.firstWhere(
          (e) => e.toString() == serverConfigJson['transportType'],
          orElse: () => MCPTransportType.stdio,
        ),
        requiredEnvVars: Map<String, String>.from(serverConfigJson['requiredEnvVars'] as Map? ?? {}),
        optionalEnvVars: Map<String, String>.from(serverConfigJson['optionalEnvVars'] as Map? ?? {}),
        setupInstructions: serverConfigJson['setupInstructions'] as String?,
        capabilities: List<String>.from(serverConfigJson['capabilities'] as List? ?? []),
        description: serverConfigJson['description'] as String?,
      ),
      isEnabled: json['isEnabled'] as bool,
      lastUsed: json['lastUsed'] != null ? DateTime.parse(json['lastUsed'] as String) : null,
      agentSpecificEnv: Map<String, String>.from(json['agentSpecificEnv'] as Map? ?? {}),
      requiredCapabilities: List<String>.from(json['requiredCapabilities'] as List? ?? []),
      priority: json['priority'] as int? ?? 0,
      autoStart: json['autoStart'] as bool? ?? true,
    );
  }
}

/// Provider for Agent MCP Configuration Service
final agentMCPConfigurationServiceProvider = Provider<AgentMCPConfigurationService>((ref) {
  // Use ServiceLocator instead of direct initialization
  return ServiceLocator.instance.get<AgentMCPConfigurationService>();
});

/// Provider for agent MCP configurations
final agentMCPConfigsProvider = FutureProvider.family<List<AgentMCPServerConfig>, String>((ref, agentId) async {
  final service = ref.read(agentMCPConfigurationServiceProvider);
  return service.getAgentMCPConfigs(agentId);
});

/// Provider for enabled MCP server IDs for an agent
final enabledAgentMCPServerIdsProvider = FutureProvider.family<List<String>, String>((ref, agentId) async {
  final service = ref.read(agentMCPConfigurationServiceProvider);
  return service.getEnabledMCPServerIds(agentId);
});

/// Provider for available GitHub MCP tools
final availableGitHubMCPToolsProvider = FutureProvider.family<List<MCPCatalogEntry>, String?>((ref, searchQuery) async {
  final service = ref.read(agentMCPConfigurationServiceProvider);
  return service.getAvailableGitHubMCPTools(searchQuery: searchQuery);
});