import 'dart:async';
import '../models/mcp_server_config.dart';
import '../mcp/process/mcp_process_manager.dart' as new_mcp;
import '../utils/app_logger.dart';

/// Direct MCP service for agents - bypasses complex terminal manager dependencies
/// This provides a simple interface for agents to execute MCP tools
@Deprecated('Will be consolidated into AgentMCPService. See docs/SERVICE_CONSOLIDATION_PLAN.md')
class DirectMCPAgentService {
  final new_mcp.MCPProcessManager _mcpManager;
  final Map<String, new_mcp.MCPServerSession> _agentSessions = {};

  static DirectMCPAgentService? _instance;
  static DirectMCPAgentService get instance => _instance ??= DirectMCPAgentService._();

  DirectMCPAgentService._() : _mcpManager = new_mcp.MCPProcessManager.instance;

  /// Execute MCP tool for an agent
  Future<MCPExecutionResult> executeTool({
    required String agentId,
    required String toolName,
    required Map<String, dynamic> arguments,
    MCPServerConfig? serverConfig,
    Duration? timeout,
  }) async {
    final startTime = DateTime.now();

    try {
      AppLogger.info(
        'Direct MCP tool execution: $agentId -> $toolName',
        component: 'DirectMCP',
      );

      // Get or create MCP session for this agent
      final session = await _getOrCreateSession(agentId, serverConfig);

      if (!session.isHealthy) {
        throw DirectMCPException('MCP session for agent $agentId is not healthy');
      }

      // Execute the tool
      final result = await session.callTool(toolName, arguments);

      final executionTime = DateTime.now().difference(startTime);

      AppLogger.info(
        'MCP tool execution completed: ${executionTime.inMilliseconds}ms',
        component: 'DirectMCP',
      );

      return MCPExecutionResult(
        success: true,
        result: result,
        executionTime: executionTime,
        timestamp: DateTime.now(),
      );

    } catch (e) {
      final executionTime = DateTime.now().difference(startTime);

      AppLogger.error(
        'MCP tool execution failed for agent $agentId: $toolName',
        component: 'DirectMCP',
        error: e,
      );

      return MCPExecutionResult(
        success: false,
        error: e.toString(),
        executionTime: executionTime,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Get available tools for an agent
  Future<List<MCPToolDefinition>> getAvailableTools({
    required String agentId,
    MCPServerConfig? serverConfig,
  }) async {
    try {
      final session = await _getOrCreateSession(agentId, serverConfig);
      final tools = await session.getTools();

      return tools.map((tool) => MCPToolDefinition(
        name: tool['name'] as String? ?? 'unknown',
        description: tool['description'] as String? ?? '',
        parameters: tool['inputSchema'] as Map<String, dynamic>? ?? {},
      )).toList();

    } catch (e) {
      AppLogger.error(
        'Failed to get available tools for agent $agentId',
        component: 'DirectMCP',
        error: e,
      );
      return [];
    }
  }

  /// Get or create MCP session for an agent
  Future<new_mcp.MCPServerSession> _getOrCreateSession(
    String agentId,
    MCPServerConfig? serverConfig,
  ) async {
    // Check for existing session
    final existingSession = _agentSessions[agentId];
    if (existingSession != null && existingSession.isHealthy) {
      return existingSession;
    }

    // Create new session with provided config or default
    final config = serverConfig ?? _createDefaultConfig(agentId);
    final session = await _mcpManager.startServer(config);

    _agentSessions[agentId] = session;
    return session;
  }

  /// Create default MCP server config for an agent
  MCPServerConfig _createDefaultConfig(String agentId) {
    return MCPServerConfig(
      id: 'default-$agentId',
      name: 'Default MCP Server for $agentId',
      url: 'local://agent-$agentId',
      command: 'echo', // Minimal fallback command
      args: ['MCP server not configured'],
      enabled: true,
      timeout: 30,
      autoReconnect: false,
    );
  }

  /// Start MCP server for agent with specific configuration
  Future<void> startMCPServer({
    required String agentId,
    required MCPServerConfig config,
  }) async {
    try {
      AppLogger.info(
        'Starting MCP server for agent $agentId: ${config.name}',
        component: 'DirectMCP',
      );

      final session = await _mcpManager.startServer(config);
      _agentSessions[agentId] = session;

      AppLogger.info(
        'MCP server started successfully for agent $agentId',
        component: 'DirectMCP',
      );

    } catch (e) {
      AppLogger.error(
        'Failed to start MCP server for agent $agentId',
        component: 'DirectMCP',
        error: e,
      );
      rethrow;
    }
  }

  /// Stop MCP server for agent
  Future<void> stopMCPServer(String agentId) async {
    try {
      final session = _agentSessions[agentId];
      if (session != null) {
        await _mcpManager.stopServer(session.sessionId);
        _agentSessions.remove(agentId);

        AppLogger.info(
          'MCP server stopped for agent $agentId',
          component: 'DirectMCP',
        );
      }
    } catch (e) {
      AppLogger.warning(
        'Failed to stop MCP server for agent $agentId',
        component: 'DirectMCP',
        error: e,
      );
    }
  }

  /// Get health status of agent's MCP server
  bool isAgentMCPHealthy(String agentId) {
    final session = _agentSessions[agentId];
    return session?.isHealthy ?? false;
  }

  /// Get all active agent MCP sessions
  Map<String, bool> getAllAgentMCPStatus() {
    return _agentSessions.map((agentId, session) =>
        MapEntry(agentId, session.isHealthy));
  }

  /// Shutdown all MCP servers
  Future<void> shutdownAll() async {
    AppLogger.info('Shutting down all agent MCP servers', component: 'DirectMCP');

    for (final agentId in _agentSessions.keys.toList()) {
      await stopMCPServer(agentId);
    }

    AppLogger.info('All agent MCP servers shut down', component: 'DirectMCP');
  }

  /// Dispose resources
  Future<void> dispose() async {
    await shutdownAll();
  }
}

/// Result of an MCP tool execution
class MCPExecutionResult {
  final bool success;
  final Map<String, dynamic>? result;
  final String? error;
  final Duration executionTime;
  final DateTime timestamp;

  const MCPExecutionResult({
    required this.success,
    this.result,
    this.error,
    required this.executionTime,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'MCPExecutionResult(success: $success, time: ${executionTime.inMilliseconds}ms, error: $error)';
  }
}

/// Definition of an MCP tool
class MCPToolDefinition {
  final String name;
  final String description;
  final Map<String, dynamic> parameters;

  const MCPToolDefinition({
    required this.name,
    required this.description,
    required this.parameters,
  });

  @override
  String toString() => 'MCPToolDefinition($name - $description)';
}

/// Exception for direct MCP operations
class DirectMCPException implements Exception {
  final String message;
  const DirectMCPException(this.message);

  @override
  String toString() => 'DirectMCPException: $message';
}