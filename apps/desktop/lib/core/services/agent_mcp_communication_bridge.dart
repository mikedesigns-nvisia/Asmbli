import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agent_terminal.dart';
import '../models/mcp_server_process.dart';
import '../models/mcp_connection.dart';
import '../models/mcp_server_config.dart';
import 'agent_terminal_manager.dart';
import '../mcp/process/mcp_process_manager.dart' as new_mcp;
import '../utils/app_logger.dart';

/// Bridge service for seamless communication between agents and MCP tools
/// Now using the production-ready MCP system
class AgentMCPCommunicationBridge {
  final AgentTerminalManager _terminalManager;
  final new_mcp.MCPProcessManager _newMcpManager;
  final Map<String, Map<String, String>> _agentCredentials = {};
  final Map<String, StreamSubscription> _outputSubscriptions = {};

  AgentMCPCommunicationBridge(
    this._terminalManager,
  ) : _newMcpManager = new_mcp.MCPProcessManager.instance;

  /// Execute MCP tool call through agent's terminal
  Future<MCPToolResult> executeMCPTool(
    String agentId,
    String serverId,
    String toolName,
    Map<String, dynamic> parameters, {
    Duration? timeout,
  }) async {
    final startTime = DateTime.now();

    try {
      AppLogger.info(
        'Executing MCP tool through agent: $agentId -> $serverId:$toolName',
        component: 'AgentMCP',
      );

      // Get or start MCP server session using our new system
      final session = await _getOrStartMCPSession(agentId, serverId);

      if (!session.isHealthy) {
        throw MCPCommunicationException('MCP session for $serverId is not healthy');
      }

      // Execute tool call using our production MCP system
      final result = await session.callTool(toolName, parameters);

      // Format result for conversation integration
      final formattedResult = MCPToolResult(
        agentId: agentId,
        serverId: serverId,
        toolName: toolName,
        success: true,
        result: result,
        executionTime: DateTime.now().difference(startTime),
        timestamp: DateTime.now(),
      );

      AppLogger.info(
        'MCP tool execution completed successfully: ${formattedResult.executionTime.inMilliseconds}ms',
        component: 'AgentMCP',
      );

      return formattedResult;
    } catch (e) {
      AppLogger.error(
        'Failed to execute MCP tool $toolName on $serverId for agent $agentId',
        component: 'AgentMCP',
        error: e,
      );

      return MCPToolResult(
        agentId: agentId,
        serverId: serverId,
        toolName: toolName,
        success: false,
        error: e.toString(),
        executionTime: DateTime.now().difference(startTime),
        timestamp: DateTime.now(),
      );
    }
  }

  /// Get or start MCP server session for an agent
  Future<new_mcp.MCPServerSession> _getOrStartMCPSession(String agentId, String serverId) async {
    // Try to get existing session
    final existingSession = _newMcpManager.getSessionByConfigId(serverId);
    if (existingSession != null && existingSession.isHealthy) {
      return existingSession;
    }

    // Get server configuration from agent terminal
    final terminal = _terminalManager.getTerminal(agentId);
    if (terminal == null) {
      throw MCPCommunicationException('No terminal found for agent $agentId');
    }

    final serverProcess = terminal.mcpServers
        .where((s) => s.serverId == serverId)
        .firstOrNull;

    if (serverProcess == null) {
      throw MCPCommunicationException('MCP server $serverId not found for agent $agentId');
    }

    // Convert old server process to new config format
    final config = _convertToNewConfig(serverProcess, agentId);

    // Start new session
    return await _newMcpManager.startServer(config);
  }

  /// Convert old MCPServerProcess to new MCPServerConfig
  MCPServerConfig _convertToNewConfig(MCPServerProcess serverProcess, String agentId) {
    // Get credentials for this agent/server
    final credentials = _agentCredentials[agentId]?[serverProcess.serverId];
    Map<String, String> env = Map<String, String>.from(serverProcess.config.environment);

    if (credentials != null) {
      try {
        final decodedCreds = jsonDecode(credentials) as Map<String, dynamic>;
        env.addAll(decodedCreds.map((k, v) => MapEntry(k, v.toString())));
      } catch (e) {
        AppLogger.warning('Failed to decode credentials for $agentId:${serverProcess.serverId}', component: 'AgentMCP');
      }
    }

    // Use the existing config but update certain fields
    return serverProcess.config.copyWith(
      environment: env,
      enabled: true,
      timeout: 30,
      autoReconnect: true,
    );
  }

  /// Set up secure credential management for MCP server authentication
  Future<void> setupCredentialsForAgent(
    String agentId,
    String serverId,
    Map<String, String> credentials,
  ) async {
    try {
      AppLogger.info(
        'Setting up credentials for agent MCP server: $agentId:$serverId',
        component: 'AgentMCP',
      );

      // Store credentials securely
      _agentCredentials[agentId] ??= {};
      _agentCredentials[agentId]![serverId] = jsonEncode(credentials);

      // Inject credentials into agent's terminal environment
      final terminal = _terminalManager.getTerminal(agentId);
      if (terminal != null) {
        for (final entry in credentials.entries) {
          await terminal.setEnvironment(entry.key, entry.value);
        }
      }

      AppLogger.info(
        'Credentials set up successfully for $agentId:$serverId',
        component: 'AgentMCP',
      );
    } catch (e) {
      AppLogger.error(
        'Failed to setup credentials for agent $agentId:$serverId',
        component: 'AgentMCP',
        error: e,
      );
      rethrow;
    }
  }

  /// Get available tools for agent's MCP servers
  Future<List<MCPToolInfo>> getAvailableToolsForAgent(String agentId) async {
    try {
      final terminal = _terminalManager.getTerminal(agentId);
      if (terminal == null) {
        return [];
      }

      final allTools = <MCPToolInfo>[];

      for (final serverProcess in terminal.mcpServers) {
        if (serverProcess.status == MCPServerStatus.running) {
          try {
            final session = await _getOrStartMCPSession(agentId, serverProcess.serverId);
            final tools = await session.getTools();

            for (final tool in tools) {
              allTools.add(MCPToolInfo(
                serverId: serverProcess.serverId,
                name: tool['name'] as String? ?? 'unknown',
                description: tool['description'] as String? ?? '',
                parameters: tool['inputSchema'] as Map<String, dynamic>? ?? {},
              ));
            }
          } catch (e) {
            AppLogger.warning(
              'Failed to get tools from MCP server ${serverProcess.serverId} for agent $agentId',
              component: 'AgentMCP',
              error: e,
            );
          }
        }
      }

      AppLogger.info(
        'Retrieved ${allTools.length} available tools for agent $agentId',
        component: 'AgentMCP',
      );

      return allTools;
    } catch (e) {
      AppLogger.error(
        'Failed to get available tools for agent $agentId',
        component: 'AgentMCP',
        error: e,
      );
      return [];
    }
  }

  /// Stream MCP server outputs for agent
  Stream<MCPServerOutput> streamMCPOutputForAgent(String agentId) async* {
    final terminal = _terminalManager.getTerminal(agentId);
    if (terminal == null) return;

    final controller = StreamController<MCPServerOutput>();

    // Subscribe to each MCP server's output using our new system
    for (final serverProcess in terminal.mcpServers) {
      try {
        final session = await _getOrStartMCPSession(agentId, serverProcess.serverId);

        // For now, we'll simulate output streaming since our new system
        // focuses on request/response. In the future, we could add
        // notification streaming to the MCP communicator.
        controller.add(MCPServerOutput(
          agentId: agentId,
          serverId: serverProcess.serverId,
          content: 'MCP server ${serverProcess.serverId} is ready',
          timestamp: DateTime.now(),
          type: MCPOutputType.info,
        ));
      } catch (e) {
        controller.add(MCPServerOutput(
          agentId: agentId,
          serverId: serverProcess.serverId,
          content: 'Error connecting to MCP server: $e',
          timestamp: DateTime.now(),
          type: MCPOutputType.error,
        ));
      }
    }

    yield* controller.stream;
  }

  /// Health check for agent's MCP servers
  Future<Map<String, bool>> getHealthStatusForAgent(String agentId) async {
    final terminal = _terminalManager.getTerminal(agentId);
    if (terminal == null) {
      return {};
    }

    final healthStatus = <String, bool>{};

    for (final serverProcess in terminal.mcpServers) {
      try {
        final session = await _getOrStartMCPSession(agentId, serverProcess.serverId);
        healthStatus[serverProcess.serverId] = session.isHealthy;
      } catch (e) {
        healthStatus[serverProcess.serverId] = false;
      }
    }

    return healthStatus;
  }

  /// Shutdown all MCP servers for an agent
  Future<void> shutdownMCPServersForAgent(String agentId) async {
    final terminal = _terminalManager.getTerminal(agentId);
    if (terminal == null) return;

    AppLogger.info('Shutting down MCP servers for agent $agentId', component: 'AgentMCP');

    for (final serverProcess in terminal.mcpServers) {
      try {
        final session = _newMcpManager.getSessionByConfigId(serverProcess.serverId);
        if (session != null) {
          await _newMcpManager.stopServer(session.sessionId);
        }
      } catch (e) {
        AppLogger.warning(
          'Failed to shutdown MCP server ${serverProcess.serverId} for agent $agentId',
          component: 'AgentMCP',
          error: e,
        );
      }
    }

    // Cancel output subscriptions
    final subscriptionsToCancel = _outputSubscriptions.keys
        .where((key) => key.startsWith('$agentId:'))
        .toList();

    for (final key in subscriptionsToCancel) {
      await _outputSubscriptions[key]?.cancel();
      _outputSubscriptions.remove(key);
    }

    // Clear credentials
    _agentCredentials.remove(agentId);

    AppLogger.info('MCP servers shutdown completed for agent $agentId', component: 'AgentMCP');
  }

  /// Dispose resources
  Future<void> dispose() async {
    for (final subscription in _outputSubscriptions.values) {
      await subscription.cancel();
    }
    _outputSubscriptions.clear();
    _agentCredentials.clear();
  }
}

/// Exception for MCP communication errors
class MCPCommunicationException implements Exception {
  final String message;
  const MCPCommunicationException(this.message);

  @override
  String toString() => 'MCPCommunicationException: $message';
}

/// Result of an MCP tool execution
class MCPToolResult {
  final String agentId;
  final String serverId;
  final String toolName;
  final bool success;
  final Map<String, dynamic>? result;
  final String? error;
  final Duration executionTime;
  final DateTime timestamp;

  const MCPToolResult({
    required this.agentId,
    required this.serverId,
    required this.toolName,
    required this.success,
    this.result,
    this.error,
    required this.executionTime,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'MCPToolResult(agent: $agentId, server: $serverId, tool: $toolName, '
           'success: $success, time: ${executionTime.inMilliseconds}ms)';
  }
}

/// Information about an available MCP tool
class MCPToolInfo {
  final String serverId;
  final String name;
  final String description;
  final Map<String, dynamic> parameters;

  const MCPToolInfo({
    required this.serverId,
    required this.name,
    required this.description,
    required this.parameters,
  });

  @override
  String toString() => 'MCPToolInfo($serverId:$name - $description)';
}

/// MCP server output for streaming
class MCPServerOutput {
  final String agentId;
  final String serverId;
  final String content;
  final DateTime timestamp;
  final MCPOutputType type;

  const MCPServerOutput({
    required this.agentId,
    required this.serverId,
    required this.content,
    required this.timestamp,
    required this.type,
  });

  @override
  String toString() => 'MCPServerOutput($agentId:$serverId - ${type.name}: $content)';
}

/// Types of MCP output
enum MCPOutputType {
  stdout,
  stderr,
  info,
  warning,
  error,
}