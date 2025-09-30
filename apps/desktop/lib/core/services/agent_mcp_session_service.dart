import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mcp_server_process.dart';
import '../models/mcp_connection.dart';
import 'agent_mcp_configuration_service.dart';
import 'mcp_process_manager.dart';
import 'mcp_protocol_handler.dart';
import 'production_logger.dart';
import '../di/service_locator.dart';

/// Result of an MCP tool execution
class MCPToolExecutionResult {
  final bool success;
  final String toolName;
  final Map<String, dynamic>? result;
  final String? error;
  final Duration executionTime;
  final String agentId;
  final String serverId;

  const MCPToolExecutionResult({
    required this.success,
    required this.toolName,
    this.result,
    this.error,
    required this.executionTime,
    required this.agentId,
    required this.serverId,
  });

  factory MCPToolExecutionResult.success({
    required String toolName,
    required Map<String, dynamic> result,
    required Duration executionTime,
    required String agentId,
    required String serverId,
  }) {
    return MCPToolExecutionResult(
      success: true,
      toolName: toolName,
      result: result,
      executionTime: executionTime,
      agentId: agentId,
      serverId: serverId,
    );
  }

  factory MCPToolExecutionResult.failure({
    required String toolName,
    required String error,
    required Duration executionTime,
    required String agentId,
    required String serverId,
  }) {
    return MCPToolExecutionResult(
      success: false,
      toolName: toolName,
      error: error,
      executionTime: executionTime,
      agentId: agentId,
      serverId: serverId,
    );
  }
}

/// Request to execute an MCP tool for an agent
class MCPToolExecutionRequest {
  final String agentId;
  final String serverId;
  final String toolName;
  final Map<String, dynamic> parameters;
  final Duration? timeout;

  const MCPToolExecutionRequest({
    required this.agentId,
    required this.serverId,
    required this.toolName,
    required this.parameters,
    this.timeout = const Duration(seconds: 30),
  });
}

/// Service that manages MCP tool execution sessions for agents
/// Handles the complete flow: agent → MCP server → tool execution → results
@Deprecated('Will be consolidated into AgentMCPService. See docs/SERVICE_CONSOLIDATION_PLAN.md')
class AgentMCPSessionService {
  final AgentMCPConfigurationService _configService;
  final MCPProcessManager _processManager;
  final MCPProtocolHandler _protocolHandler;

  // Active sessions: agentId:serverId → MCPServerProcess
  final Map<String, MCPServerProcess> _activeSessions = {};
  final Map<String, MCPConnection> _activeConnections = {};
  final Map<String, DateTime> _lastActivity = {};

  // Session cleanup timer
  Timer? _cleanupTimer;
  static const Duration _sessionTimeout = Duration(minutes: 10);

  AgentMCPSessionService(
    this._configService,
    this._processManager,
    this._protocolHandler,
  ) {
    _startCleanupTimer();
  }

  /// Execute an MCP tool for an agent
  Future<MCPToolExecutionResult> executeTool(MCPToolExecutionRequest request) async {
    final startTime = DateTime.now();
    final sessionId = '${request.agentId}:${request.serverId}';

    try {
      ProductionLogger.instance.info(
        'Executing MCP tool for agent',
        data: {
          'agent_id': request.agentId,
          'server_id': request.serverId,
          'tool_name': request.toolName,
          'parameters': request.parameters,
        },
        category: 'agent_mcp_session',
      );

      // Step 1: Ensure agent has this MCP server configured
      final isConfigured = await _configService.isAgentMCPToolEnabled(
        request.agentId,
        request.serverId,
      );

      if (!isConfigured) {
        throw Exception('MCP server ${request.serverId} not configured for agent ${request.agentId}');
      }

      // Step 2: Get or create MCP server session
      final serverProcess = await _ensureServerSession(request.agentId, request.serverId);

      // Step 3: Get or create connection to server
      final connection = await _ensureConnection(sessionId, serverProcess);

      // Step 4: Execute tool via JSON-RPC
      final toolResult = await _executeToolOnServer(
        connection,
        request.toolName,
        request.parameters,
        request.timeout ?? const Duration(seconds: 30),
      );

      // Step 5: Update activity tracking
      _lastActivity[sessionId] = DateTime.now();

      final executionTime = DateTime.now().difference(startTime);

      ProductionLogger.instance.info(
        'MCP tool execution completed',
        data: {
          'agent_id': request.agentId,
          'server_id': request.serverId,
          'tool_name': request.toolName,
          'success': true,
          'execution_time_ms': executionTime.inMilliseconds,
        },
        category: 'agent_mcp_session',
      );

      return MCPToolExecutionResult.success(
        toolName: request.toolName,
        result: toolResult,
        executionTime: executionTime,
        agentId: request.agentId,
        serverId: request.serverId,
      );

    } catch (e, stackTrace) {
      final executionTime = DateTime.now().difference(startTime);

      ProductionLogger.instance.error(
        'MCP tool execution failed',
        data: {
          'agent_id': request.agentId,
          'server_id': request.serverId,
          'tool_name': request.toolName,
          'error': e.toString(),
          'execution_time_ms': executionTime.inMilliseconds,
        },
        category: 'agent_mcp_session',
        stackTrace: stackTrace,
      );

      return MCPToolExecutionResult.failure(
        toolName: request.toolName,
        error: e.toString(),
        executionTime: executionTime,
        agentId: request.agentId,
        serverId: request.serverId,
      );
    }
  }

  /// Get available tools for an agent from a specific MCP server
  Future<List<String>> getAvailableTools(String agentId, String serverId) async {
    try {
      final sessionId = '$agentId:$serverId';

      // Ensure agent has this server configured
      final isConfigured = await _configService.isAgentMCPToolEnabled(agentId, serverId);
      if (!isConfigured) {
        return [];
      }

      // Get or create server session
      final serverProcess = await _ensureServerSession(agentId, serverId);
      final connection = await _ensureConnection(sessionId, serverProcess);

      // Query available tools via MCP protocol
      final tools = await _queryAvailableTools(connection);
      return tools;

    } catch (e) {
      ProductionLogger.instance.warning(
        'Failed to get available tools',
        data: {
          'agent_id': agentId,
          'server_id': serverId,
          'error': e.toString(),
        },
        category: 'agent_mcp_session',
      );
      return [];
    }
  }

  /// Ensure MCP server is running for the agent
  Future<MCPServerProcess> _ensureServerSession(String agentId, String serverId) async {
    final sessionId = '$agentId:$serverId';

    // Check if we already have an active session
    final existing = _activeSessions[sessionId];
    if (existing != null && existing.status == MCPServerStatus.running) {
      return existing;
    }

    // Get agent's environment configuration for this server
    final environment = await _configService.getAgentMCPEnvironment(agentId, serverId);

    // Start MCP server process
    final serverProcess = await _processManager.startServer(
      serverId: serverId,
      agentId: agentId,
      credentials: environment,
      environment: environment,
    );

    _activeSessions[sessionId] = serverProcess;
    _lastActivity[sessionId] = DateTime.now();

    return serverProcess;
  }

  /// Ensure connection to MCP server
  Future<MCPConnection> _ensureConnection(String sessionId, MCPServerProcess serverProcess) async {
    // Check if we already have an active connection
    final existing = _activeConnections[sessionId];
    if (existing != null && existing.status == MCPConnectionStatus.connected) {
      return existing;
    }

    // Establish new connection
    final connection = await _protocolHandler.establishConnection(serverProcess);
    _activeConnections[sessionId] = connection;

    return connection;
  }

  /// Execute tool on MCP server via JSON-RPC
  Future<Map<String, dynamic>> _executeToolOnServer(
    MCPConnection connection,
    String toolName,
    Map<String, dynamic> parameters,
    Duration timeout,
  ) async {
    // Create JSON-RPC request for tool execution
    final request = {
      'jsonrpc': '2.0',
      'id': DateTime.now().millisecondsSinceEpoch,
      'method': 'tools/call',
      'params': {
        'name': toolName,
        'arguments': parameters,
      },
    };

    // Send request and wait for response
    final response = await connection.request('tools/call', {
      'name': toolName,
      'arguments': parameters,
    }).timeout(timeout);

    if (response.error != null) {
      throw Exception('MCP tool execution error: ${response.error}');
    }

    return response.result as Map<String, dynamic>;
  }

  /// Query available tools from MCP server
  Future<List<String>> _queryAvailableTools(MCPConnection connection) async {
    final response = await connection.request('tools/list', {});

    if (response.error != null) {
      throw Exception('Failed to query tools: ${response.error}');
    }

    final tools = response.result!['tools'] as List<dynamic>;
    return tools.map((tool) => tool['name'] as String).toList();
  }

  /// Start cleanup timer for inactive sessions
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupInactiveSessions();
    });
  }

  /// Clean up inactive sessions to free resources
  void _cleanupInactiveSessions() async {
    final now = DateTime.now();
    final toRemove = <String>[];

    for (final entry in _lastActivity.entries) {
      final sessionId = entry.key;
      final lastActivity = entry.value;

      if (now.difference(lastActivity) > _sessionTimeout) {
        toRemove.add(sessionId);
      }
    }

    for (final sessionId in toRemove) {
      await _closeSession(sessionId);
    }
  }

  /// Close a specific session
  Future<void> _closeSession(String sessionId) async {
    try {
      // Close connection
      final connection = _activeConnections[sessionId];
      if (connection != null) {
        await connection.close();
        _activeConnections.remove(sessionId);
      }

      // Stop server process
      final serverProcess = _activeSessions[sessionId];
      if (serverProcess != null) {
        await _processManager.stopServer(serverProcess.id);
        _activeSessions.remove(sessionId);
      }

      _lastActivity.remove(sessionId);

      ProductionLogger.instance.info(
        'Closed inactive MCP session',
        data: {'session_id': sessionId},
        category: 'agent_mcp_session',
      );

    } catch (e) {
      ProductionLogger.instance.warning(
        'Error closing MCP session',
        data: {'session_id': sessionId, 'error': e.toString()},
        category: 'agent_mcp_session',
      );
    }
  }

  /// Get session statistics
  Map<String, dynamic> getSessionStats() {
    return {
      'active_sessions': _activeSessions.length,
      'active_connections': _activeConnections.length,
      'session_details': _activeSessions.keys.toList(),
    };
  }

  /// Clean up all resources
  Future<void> dispose() async {
    _cleanupTimer?.cancel();

    // Close all active sessions
    final sessionIds = _activeSessions.keys.toList();
    for (final sessionId in sessionIds) {
      await _closeSession(sessionId);
    }
  }
}

/// Provider for Agent MCP Session Service
final agentMCPSessionServiceProvider = Provider<AgentMCPSessionService>((ref) {
  // Use ServiceLocator instead of placeholder providers
  return ServiceLocator.instance.get<AgentMCPSessionService>();
});