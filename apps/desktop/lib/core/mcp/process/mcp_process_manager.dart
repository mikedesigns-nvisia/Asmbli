import 'dart:async';
import '../../utils/app_logger.dart';
import '../../models/mcp_server_config.dart';
import '../adapters/mcp_adapter_registry.dart';

/// Production-ready MCP server process manager
/// Handles lifecycle, health monitoring, and communication with MCP servers
class MCPProcessManager {
  final Map<String, MCPServerSession> _sessions = {};
  final Map<String, Timer> _healthCheckTimers = {};
  static MCPProcessManager? _instance;
  static MCPProcessManager get instance => _instance ??= MCPProcessManager._();

  MCPProcessManager._();

  /// Start and connect to an MCP server
  Future<MCPServerSession> startServer(MCPServerConfig config) async {
    final sessionId = _generateSessionId(config);

    // Check if already running
    final existingSession = _sessions[sessionId];
    if (existingSession != null && existingSession.isHealthy) {
      AppLogger.info('MCP server ${config.name} already running', component: 'MCP.Process');
      return existingSession;
    }

    AppLogger.info('Starting MCP server: ${config.name}', component: 'MCP.Process');

    try {
      // Create new session
      final session = MCPServerSession(
        config: config,
        sessionId: sessionId,
      );

      // Initialize the session
      await session.initialize();

      // Store session
      _sessions[sessionId] = session;

      // Start health monitoring
      _startHealthMonitoring(session);

      AppLogger.info('Successfully started MCP server: ${config.name}', component: 'MCP.Process');
      return session;

    } catch (e) {
      AppLogger.error('Failed to start MCP server: ${config.name}', component: 'MCP.Process', error: e);
      rethrow;
    }
  }

  /// Stop an MCP server
  Future<void> stopServer(String sessionId) async {
    final session = _sessions[sessionId];
    if (session == null) {
      AppLogger.warning('Attempted to stop non-existent MCP server session: $sessionId', component: 'MCP.Process');
      return;
    }

    AppLogger.info('Stopping MCP server: ${session.config.name}', component: 'MCP.Process');

    // Stop health monitoring
    _healthCheckTimers[sessionId]?.cancel();
    _healthCheckTimers.remove(sessionId);

    // Shutdown session
    await session.shutdown();

    // Remove from active sessions
    _sessions.remove(sessionId);

    AppLogger.info('Successfully stopped MCP server: ${session.config.name}', component: 'MCP.Process');
  }

  /// Get active session by ID
  MCPServerSession? getSession(String sessionId) {
    return _sessions[sessionId];
  }

  /// Get session by config ID
  MCPServerSession? getSessionByConfigId(String configId) {
    for (final session in _sessions.values) {
      if (session.config.id == configId) {
        return session;
      }
    }
    return null;
  }

  /// Get all active sessions
  List<MCPServerSession> getAllSessions() {
    return List.unmodifiable(_sessions.values);
  }

  /// Send request to MCP server
  Future<Map<String, dynamic>> sendRequest(
    String sessionId,
    String method,
    Map<String, dynamic> params,
  ) async {
    final session = _sessions[sessionId];
    if (session == null) {
      throw Exception('MCP server session not found: $sessionId');
    }

    return await session.sendRequest(method, params);
  }

  /// Call tool on MCP server
  Future<Map<String, dynamic>> callTool(
    String sessionId,
    String toolName,
    Map<String, dynamic> arguments,
  ) async {
    final session = _sessions[sessionId];
    if (session == null) {
      throw Exception('MCP server session not found: $sessionId');
    }

    return await session.callTool(toolName, arguments);
  }

  /// Get tools from MCP server
  Future<List<Map<String, dynamic>>> getTools(String sessionId) async {
    final session = _sessions[sessionId];
    if (session == null) {
      throw Exception('MCP server session not found: $sessionId');
    }

    return await session.getTools();
  }

  void _startHealthMonitoring(MCPServerSession session) {
    _healthCheckTimers[session.sessionId] = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _performHealthCheck(session),
    );
  }

  Future<void> _performHealthCheck(MCPServerSession session) async {
    try {
      final isHealthy = await session.checkHealth();
      if (!isHealthy) {
        AppLogger.warning('MCP server health check failed: ${session.config.name}', component: 'MCP.Process');

        // Attempt restart if configured
        if (session.config.autoReconnect) {
          AppLogger.info('Attempting to restart unhealthy MCP server: ${session.config.name}', component: 'MCP.Process');
          await _restartSession(session);
        }
      }
    } catch (e) {
      AppLogger.error('Health check error for MCP server: ${session.config.name}', component: 'MCP.Process', error: e);
    }
  }

  Future<void> _restartSession(MCPServerSession session) async {
    try {
      await session.restart();
      AppLogger.info('Successfully restarted MCP server: ${session.config.name}', component: 'MCP.Process');
    } catch (e) {
      AppLogger.error('Failed to restart MCP server: ${session.config.name}', component: 'MCP.Process', error: e);
    }
  }

  String _generateSessionId(MCPServerConfig config) {
    return 'mcp-${config.id}-${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Shutdown all MCP servers
  Future<void> shutdownAll() async {
    AppLogger.info('Shutting down all MCP servers', component: 'MCP.Process');

    final shutdownFutures = _sessions.keys.map((sessionId) => stopServer(sessionId));
    await Future.wait(shutdownFutures);

    AppLogger.info('All MCP servers shut down', component: 'MCP.Process');
  }

  /// Get health status of all servers
  Map<String, bool> getHealthStatus() {
    final status = <String, bool>{};
    for (final session in _sessions.values) {
      status[session.config.name] = session.isHealthy;
    }
    return status;
  }
}

/// Represents an active MCP server session
class MCPServerSession {
  final MCPServerConfig config;
  final String sessionId;
  StdioMCPAdapter? _adapter;
  DateTime? _lastHealthCheck;
  bool _isInitialized = false;

  MCPServerSession({
    required this.config,
    required this.sessionId,
  });

  /// Initialize the MCP server session
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.debug('MCP session already initialized: ${config.name}', component: 'MCP.Session');
      return;
    }

    // Create adapter based on transport type
    if (config.transport == 'stdio' || config.protocol == 'stdio') {
      _adapter = StdioMCPAdapter();
    } else {
      throw Exception('Unsupported MCP transport: ${config.transport ?? config.protocol}');
    }

    // Connect to server
    await _adapter!.connect(config);

    _isInitialized = true;
    _lastHealthCheck = DateTime.now();

    AppLogger.info('MCP session initialized: ${config.name}', component: 'MCP.Session');
  }

  /// Send request to MCP server
  Future<Map<String, dynamic>> sendRequest(String method, Map<String, dynamic> params) async {
    if (!_isInitialized || _adapter == null) {
      throw Exception('MCP session not initialized: ${config.name}');
    }

    return await _adapter!.sendRequest(method, params);
  }

  /// Call tool on MCP server
  Future<Map<String, dynamic>> callTool(String toolName, Map<String, dynamic> arguments) async {
    if (!_isInitialized || _adapter == null) {
      throw Exception('MCP session not initialized: ${config.name}');
    }

    if (_adapter is StdioMCPAdapter) {
      return await (_adapter as StdioMCPAdapter).callTool(toolName, arguments);
    }

    throw Exception('Tool calling not supported by adapter type');
  }

  /// Get available tools
  Future<List<Map<String, dynamic>>> getTools() async {
    if (!_isInitialized || _adapter == null) {
      throw Exception('MCP session not initialized: ${config.name}');
    }

    if (_adapter is StdioMCPAdapter) {
      return await (_adapter as StdioMCPAdapter).getTools();
    }

    return [];
  }

  /// Check health of MCP server
  Future<bool> checkHealth() async {
    if (!_isInitialized || _adapter == null) {
      return false;
    }

    try {
      // Try to get tools list as a health check
      await sendRequest('tools/list', {});
      _lastHealthCheck = DateTime.now();
      return true;
    } catch (e) {
      AppLogger.debug('Health check failed for ${config.name}: $e', component: 'MCP.Session');
      return false;
    }
  }

  /// Restart the MCP server session
  Future<void> restart() async {
    AppLogger.info('Restarting MCP session: ${config.name}', component: 'MCP.Session');

    // Shutdown current connection
    await shutdown();

    // Wait a moment
    await Future.delayed(const Duration(seconds: 2));

    // Reinitialize
    await initialize();
  }

  /// Shutdown the MCP server session
  Future<void> shutdown() async {
    if (_adapter != null) {
      await _adapter!.disconnect();
      _adapter = null;
    }

    _isInitialized = false;
    AppLogger.info('MCP session shutdown: ${config.name}', component: 'MCP.Session');
  }

  /// Check if session is healthy
  bool get isHealthy {
    return _isInitialized &&
           _adapter != null &&
           _adapter!.isConnected &&
           (_lastHealthCheck?.isAfter(DateTime.now().subtract(const Duration(minutes: 5))) ?? false);
  }

  /// Get last health check time
  DateTime? get lastHealthCheck => _lastHealthCheck;
}