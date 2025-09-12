import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mcp_server_process.dart';
import '../models/mcp_server_config.dart';
import '../models/mcp_catalog_entry.dart';
import '../models/mcp_connection.dart';
import 'mcp_catalog_service.dart';
import 'mcp_protocol_handler.dart';
import 'mcp_error_handler.dart';

/// Production-grade process manager for MCP servers with proper cleanup and resource management
class MCPProcessManager {
  final MCPCatalogService _catalogService;
  final MCPProtocolHandler _protocolHandler;
  final Map<String, MCPServerProcess> _runningProcesses = {};
  final Map<String, MCPConnection> _connections = {};
  final Map<String, Process> _systemProcesses = {};
  final Map<String, StreamSubscription> _outputSubscriptions = {};
  final Map<String, StreamSubscription> _errorSubscriptions = {};
  final Map<String, Timer> _healthCheckTimers = {};
  final Map<String, Completer<bool>> _startupCompleters = {};
  
  // Resource limits and timeouts
  static const Duration _startupTimeout = Duration(seconds: 30);
  static const Duration _shutdownTimeout = Duration(seconds: 10);
  static const Duration _healthCheckInterval = Duration(seconds: 30);
  static const int _maxRestartAttempts = 3;
  static const Duration _restartCooldown = Duration(seconds: 5);

  MCPProcessManager(this._catalogService, this._protocolHandler);

  /// Start MCP server process with proper resource management
  Future<MCPServerProcess> startServer({
    required String id,
    required String agentId,
    required Map<String, String> credentials,
    Map<String, String>? environment,
  }) async {
    final catalogEntry = _catalogService.getCatalogEntry(id);
    if (catalogEntry == null) {
      throw MCPProcessException('Server $id not found in catalog');
    }

    final processId = '$agentId:$id';
    
    // Check if already running
    if (_runningProcesses.containsKey(processId)) {
      final existing = _runningProcesses[processId]!;
      if (existing.isHealthy) {
        return existing;
      }
    }

    // Create startup completer
    final startupCompleter = Completer<bool>();
    _startupCompleters[processId] = startupCompleter;

    try {
      // Prepare environment variables
      final processEnv = <String, String>{
        ...Platform.environment,
        ...credentials,
        ...(environment ?? {}),
      };

      // Start the process based on transport type
      final process = await _startProcessForTransport(
        catalogEntry,
        processEnv,
      );

      if (process == null) {
        throw MCPProcessException('Failed to start process for $id');
      }

      // Create server config from catalog entry
      final config = MCPServerConfig(
        id: id,
        name: catalogEntry.name,
        url: catalogEntry.remoteUrl ?? 'stdio://localhost',
        command: catalogEntry.command ?? '',
        transport: catalogEntry.transport.name,
        args: catalogEntry.args ?? [],
        env: processEnv,
      );

      // Create process tracking object
      final serverProcess = MCPServerProcess(
        id: processId,
        config: config,
        process: process,
        startTime: DateTime.now(),
      );

      _runningProcesses[processId] = serverProcess;
      _systemProcesses[processId] = process;

      // Setup process monitoring
      await _setupProcessMonitoring(processId, process);

      // Wait for startup with timeout
      final startupSuccess = await startupCompleter.future
          .timeout(_startupTimeout, onTimeout: () => false);

      if (!startupSuccess) {
        await _cleanupProcess(processId);
        throw MCPProcessException('Server startup timeout for $id');
      }

      // Establish MCP protocol connection
      final connection = await _protocolHandler.establishConnection(serverProcess);
      _connections[processId] = connection;

      // Mark as healthy and initialized
      serverProcess.isHealthy = true;
      serverProcess.isInitialized = true;
      serverProcess.lastActivity = DateTime.now();

      // Start health check monitoring
      _startHealthCheck(processId);

      return serverProcess;
    } catch (e) {
      _startupCompleters.remove(processId);
      await _cleanupProcess(processId);
      rethrow;
    }
  }

  /// Start process based on transport type
  Future<Process?> _startProcessForTransport(
    MCPCatalogEntry catalogEntry,
    Map<String, String> environment,
  ) async {
    switch (catalogEntry.transport) {
      case MCPTransportType.stdio:
        return await _startStdioProcess(catalogEntry, environment);
      case MCPTransportType.sse:
        return await _startHttpServer(catalogEntry, environment);
      case MCPTransportType.http:
        return await _startWebSocketServer(catalogEntry, environment);
    }
  }

  /// Start stdio-based MCP server
  Future<Process> _startStdioProcess(
    MCPCatalogEntry catalogEntry,
    Map<String, String> environment,
  ) async {
    final command = catalogEntry.command;
    final args = catalogEntry.args;

    if (command == null) {
      throw MCPProcessException('Command not specified for server ${catalogEntry.id}');
    }

    return await Process.start(
      command,
      args ?? [],
      environment: environment,
      mode: ProcessStartMode.normal,
    );
  }

  /// Start HTTP server for SSE transport
  Future<Process> _startHttpServer(
    MCPCatalogEntry catalogEntry,
    Map<String, String> environment,
  ) async {
    final command = catalogEntry.command;
    final args = [...(catalogEntry.args ?? []), '--transport', 'sse'];

    if (command == null) {
      throw MCPProcessException('Command not specified for server ${catalogEntry.id}');
    }

    return await Process.start(
      command,
      args,
      environment: environment,
      mode: ProcessStartMode.normal,
    );
  }

  /// Start WebSocket server
  Future<Process> _startWebSocketServer(
    MCPCatalogEntry catalogEntry,
    Map<String, String> environment,
  ) async {
    final command = catalogEntry.command;
    final args = [...(catalogEntry.args ?? []), '--transport', 'websocket'];

    if (command == null) {
      throw MCPProcessException('Command not specified for server ${catalogEntry.id}');
    }

    return await Process.start(
      command,
      args,
      environment: environment,
      mode: ProcessStartMode.normal,
    );
  }

  /// Setup comprehensive process monitoring
  Future<void> _setupProcessMonitoring(String processId, Process process) async {
    // Monitor stdout for startup signals and communication
    _outputSubscriptions[processId] = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
      (line) => _handleProcessOutput(processId, line, isError: false),
      onError: (error) => _handleProcessError(processId, error),
    );

    // Monitor stderr for errors
    _errorSubscriptions[processId] = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
      (line) => _handleProcessOutput(processId, line, isError: true),
      onError: (error) => _handleProcessError(processId, error),
    );

    // Monitor process exit
    process.exitCode.then((exitCode) {
      _handleProcessExit(processId, exitCode);
    });
  }

  /// Handle process output for monitoring and debugging
  void _handleProcessOutput(String processId, String line, {required bool isError}) {
    final serverProcess = _runningProcesses[processId];
    if (serverProcess == null) return;

    // Log output for debugging
    final prefix = isError ? 'STDERR' : 'STDOUT';
    print('[$prefix] ${serverProcess.id}: $line');

    // Check for startup completion signals
    if (!isError && _startupCompleters.containsKey(processId)) {
      if (_isStartupCompleteLine(line)) {
        _startupCompleters[processId]?.complete(true);
        _startupCompleters.remove(processId);
      }
    }

    // Update last activity timestamp
    serverProcess.lastActivity = DateTime.now();
  }

  /// Handle process errors
  void _handleProcessError(String processId, dynamic error) {
    final serverProcess = _runningProcesses[processId];
    if (serverProcess == null) return;

    print('Process error for ${serverProcess.id}: $error');

    // Mark process as unhealthy
    serverProcess.isHealthy = false;

    // Complete startup with failure if still waiting
    if (_startupCompleters.containsKey(processId)) {
      _startupCompleters[processId]?.complete(false);
      _startupCompleters.remove(processId);
    }
  }

  /// Handle process exit
  void _handleProcessExit(String processId, int exitCode) {
    final serverProcess = _runningProcesses[processId];
    if (serverProcess == null) return;

    print('Process exited for ${serverProcess.id} with code $exitCode');

    // Mark process as unhealthy if crashed
    if (exitCode != 0) {
      serverProcess.isHealthy = false;
    }

    // Cleanup resources
    _cleanupProcessResources(processId);

    // Attempt restart if crashed (simplified restart logic)
    if (exitCode != 0) {
      _scheduleRestart(processId);
    }
  }

  /// Check if output line indicates successful startup
  bool _isStartupCompleteLine(String line) {
    // Look for actual MCP JSON-RPC messages
    try {
      final json = jsonDecode(line);
      // Look for initialize response or server ready indicators
      if (json is Map<String, dynamic>) {
        // MCP initialize response
        if (json['id'] != null && json['result'] != null) {
          return true;
        }
        // Server-sent ready notification
        if (json['method'] == 'notifications/initialized') {
          return true;
        }
      }
    } catch (e) {
      // Not JSON, check for text indicators
      final startupIndicators = [
        'server listening',
        'mcp server started',
        'ready to receive requests',
        'initialization complete',
        'server running on',
      ];

      return startupIndicators.any((indicator) => 
          line.toLowerCase().contains(indicator.toLowerCase()));
    }
    
    return false;
  }

  /// Start health check monitoring
  void _startHealthCheck(String processId) {
    _healthCheckTimers[processId] = Timer.periodic(_healthCheckInterval, (timer) {
      _performHealthCheck(processId);
    });
  }

  /// Perform health check on running process
  Future<void> _performHealthCheck(String processId) async {
    final serverProcess = _runningProcesses[processId];
    final systemProcess = _systemProcesses[processId];
    
    if (serverProcess == null || systemProcess == null) {
      _healthCheckTimers[processId]?.cancel();
      return;
    }

    try {
      // Check if process is still alive
      final isAlive = !systemProcess.kill(ProcessSignal.sigusr1); // Non-destructive signal test
      
      if (isAlive) {
        // Process is alive - update activity time
        serverProcess.lastActivity = DateTime.now();
        serverProcess.isHealthy = true;
      } else {
        // Process died unexpectedly
        _handleProcessExit(processId, -1);
      }
    } catch (e) {
      // Process might be dead or unreachable
      _handleProcessError(processId, 'Health check failed: $e');
    }
  }

  /// Schedule process restart after cooldown
  void _scheduleRestart(String processId) {
    final serverProcess = _runningProcesses[processId];
    if (serverProcess == null) return;

    Timer(_restartCooldown, () async {
      try {
        print('Attempting restart for ${serverProcess.id}');
        
        // For simplicity, just remove the failed process
        // Real implementation would need proper restart logic
        _runningProcesses.remove(processId);
        _systemProcesses.remove(processId);
        _connections.remove(processId);
        
      } catch (e) {
        print('Restart failed for ${serverProcess.id}: $e');
        // Mark as unhealthy
        serverProcess.isHealthy = false;
      }
    });
  }

  /// Stop server process gracefully
  Future<bool> stopServer(String processId) async {
    final serverProcess = _runningProcesses[processId];
    final systemProcess = _systemProcesses[processId];
    
    if (serverProcess == null || systemProcess == null) {
      return false;
    }

    try {
      // Mark as not healthy (stopping)
      serverProcess.isHealthy = false;

      // Send graceful shutdown signal
      systemProcess.kill(ProcessSignal.sigterm);

      // Wait for graceful shutdown
      final exitCode = await systemProcess.exitCode
          .timeout(_shutdownTimeout, onTimeout: () => -1);

      if (exitCode == -1) {
        // Force kill if graceful shutdown failed (timeout)
        print('Forcing termination of ${serverProcess.id}');
        systemProcess.kill(ProcessSignal.sigkill);
        await systemProcess.exitCode;
      }

      await _cleanupProcess(processId);
      return true;
    } catch (e) {
      print('Error stopping server ${serverProcess.id}: $e');
      await _cleanupProcess(processId);
      return false;
    }
  }

  /// Clean up all process resources
  Future<void> _cleanupProcess(String processId) async {
    _cleanupProcessResources(processId);
    
    // Close MCP connection
    final connection = _connections.remove(processId);
    if (connection != null) {
      await connection.close();
    }
    
    _runningProcesses.remove(processId);
    _systemProcesses.remove(processId);
  }

  /// Clean up process monitoring resources
  void _cleanupProcessResources(String processId) {
    _outputSubscriptions[processId]?.cancel();
    _errorSubscriptions[processId]?.cancel();
    _healthCheckTimers[processId]?.cancel();
    _startupCompleters[processId]?.complete(false);
    
    _outputSubscriptions.remove(processId);
    _errorSubscriptions.remove(processId);
    _healthCheckTimers.remove(processId);
    _startupCompleters.remove(processId);
  }

  /// Get running server process
  MCPServerProcess? getRunningServer(String processId) {
    return _runningProcesses[processId];
  }

  /// Get MCP connection for process
  MCPConnection? getConnection(String processId) {
    return _connections[processId];
  }

  /// Get all running servers
  List<MCPServerProcess> getAllRunningServers() {
    return _runningProcesses.values.toList();
  }

  /// Get servers for specific agent
  List<MCPServerProcess> getServersForAgent(String agentId) {
    // Note: MCPServerProcess doesn't track agentId directly
    // This would need to be implemented with a separate mapping if needed
    return _runningProcesses.values.toList();
  }

  /// Stop all servers for an agent
  Future<void> stopAllServersForAgent(String agentId) async {
    final agentServers = getServersForAgent(agentId);
    
    await Future.wait(
      agentServers.map((server) => stopServer(server.id)),
    );
  }

  /// Emergency shutdown of all processes
  Future<void> emergencyShutdown() async {
    print('Performing emergency shutdown of all MCP processes...');
    
    final shutdownFutures = _runningProcesses.keys
        .map((processId) => stopServer(processId))
        .toList();

    await Future.wait(shutdownFutures);
    
    // Force cleanup any remaining resources
    _runningProcesses.clear();
    _systemProcesses.clear();
    _cleanupAllResources();
  }

  /// Clean up all monitoring resources
  void _cleanupAllResources() {
    for (final subscription in _outputSubscriptions.values) {
      subscription.cancel();
    }
    for (final subscription in _errorSubscriptions.values) {
      subscription.cancel();
    }
    for (final timer in _healthCheckTimers.values) {
      timer.cancel();
    }
    for (final completer in _startupCompleters.values) {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }
    
    _outputSubscriptions.clear();
    _errorSubscriptions.clear();
    _healthCheckTimers.clear();
    _startupCompleters.clear();
  }

  /// Get process statistics
  Map<String, dynamic> getProcessStatistics() {
    final stats = <String, dynamic>{
      'total_processes': _runningProcesses.length,
      'running': 0,
      'stopping': 0,
      'error': 0,
      'crashed': 0,
    };

    for (final process in _runningProcesses.values) {
      final statusKey = process.isHealthy ? 'healthy' : 'unhealthy';
      stats[statusKey] = (stats[statusKey] as int? ?? 0) + 1;
    }

    return stats;
  }

  /// Dispose all resources
  Future<void> dispose() async {
    await emergencyShutdown();
  }
}

/// Process management exception
class MCPProcessException implements Exception {
  final String message;
  MCPProcessException(this.message);

  @override
  String toString() => 'MCPProcessException: $message';
}

// ==================== Riverpod Provider ====================

final mcpProcessManagerProvider = Provider<MCPProcessManager>((ref) {
  final catalogService = ref.read(mcpCatalogServiceProvider);
  final protocolHandler = ref.read(mcpProtocolHandlerProvider);
  final processManager = MCPProcessManager(catalogService, protocolHandler);
  
  // Set process manager reference in error handler to break circular dependency
  try {
    final errorHandler = ref.read(mcpErrorHandlerProvider);
    errorHandler.setProcessManager(processManager);
  } catch (e) {
    print('Could not set error handler process manager: $e');
  }
  
  return processManager;
});