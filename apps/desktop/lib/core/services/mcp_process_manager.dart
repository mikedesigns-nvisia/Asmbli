import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mcp_server_process.dart';
import '../models/mcp_catalog_entry.dart';
import '../models/mcp_connection.dart';
import '../interfaces/mcp_server_manager_interface.dart';
import 'mcp_catalog_service.dart';
import 'mcp_protocol_handler.dart';
import '../../features/agents/presentation/widgets/mcp_server_logs_widget.dart';

@Deprecated('Will be consolidated into MCPProcessService. See docs/SERVICE_CONSOLIDATION_PLAN.md')
/// Installation progress tracking
class InstallationProgress {
  final String serverId;
  final InstallationPhase phase;
  final String message;
  final double progress; // 0.0 to 1.0
  final bool isComplete;
  final String? errorMessage;
  final List<String> logOutput;

  const InstallationProgress({
    required this.serverId,
    required this.phase,
    required this.message,
    required this.progress,
    this.isComplete = false,
    this.errorMessage,
    this.logOutput = const [],
  });

  InstallationProgress copyWith({
    InstallationPhase? phase,
    String? message,
    double? progress,
    bool? isComplete,
    String? errorMessage,
    List<String>? logOutput,
  }) {
    return InstallationProgress(
      serverId: serverId,
      phase: phase ?? this.phase,
      message: message ?? this.message,
      progress: progress ?? this.progress,
      isComplete: isComplete ?? this.isComplete,
      errorMessage: errorMessage ?? this.errorMessage,
      logOutput: logOutput ?? this.logOutput,
    );
  }
}

/// Installation phases
enum InstallationPhase {
  preparing,
  downloading,
  installing,
  configuring,
  starting,
  completed,
  failed,
}

/// Production-grade process manager for MCP servers with proper cleanup and resource management
class MCPProcessManager implements MCPServerManagerInterface {
  final MCPCatalogService _catalogService;
  final MCPProtocolHandler _protocolHandler;
  final Map<String, MCPServerProcess> _runningProcesses = {};
  final Map<String, MCPConnection> _connections = {};
  final Map<String, Process> _systemProcesses = {};
  final Map<String, StreamSubscription> _outputSubscriptions = {};
  final Map<String, StreamSubscription> _errorSubscriptions = {};
  final Map<String, Timer> _healthCheckTimers = {};
  final Map<String, Completer<bool>> _startupCompleters = {};

  // Logging infrastructure
  final Map<String, List<MCPLogEntry>> _serverLogs = {};
  final Map<String, StreamController<MCPLogEntry>> _logStreamControllers = {};
  static const int _maxLogsPerServer = 1000;

  // Installation progress tracking
  final Map<String, StreamController<InstallationProgress>> _installationProgressControllers = {};
  final Map<String, InstallationProgress> _currentInstallationProgress = {};
  
  // Resource limits and timeouts
  static const Duration _startupTimeout = Duration(seconds: 30);
  static const Duration _shutdownTimeout = Duration(seconds: 10);
  static const Duration _healthCheckInterval = Duration(seconds: 30);
  static const int _maxRestartAttempts = 3;
  static const Duration _restartCooldown = Duration(seconds: 5);

  MCPProcessManager(this._catalogService, this._protocolHandler);

  /// Start MCP server process with proper resource management
  @override
  Future<MCPServerProcess> startServer({
    required String serverId,
    required String agentId,
    required Map<String, String> credentials,
    Map<String, String>? environment,
  }) async {
    final catalogEntry = await _catalogService.getCatalogEntry(serverId);
    if (catalogEntry == null) {
      throw MCPProcessException('Server $serverId not found in catalog');
    }

    final processId = '$agentId:$serverId';
    
    // Check if already running
    if (_runningProcesses.containsKey(processId)) {
      final existing = _runningProcesses[processId]!;
      if (existing.status == MCPServerStatus.running) {
        return existing;
      }
    }

    // Create startup completer
    final startupCompleter = Completer<bool>();
    _startupCompleters[processId] = startupCompleter;

    // Initialize installation progress tracking
    _initializeInstallationProgress(serverId);

    try {
      // Update progress: Preparing
      _updateInstallationProgress(serverId, InstallationPhase.preparing,
        'Preparing server installation...', 0.1);

      // Prepare environment variables
      final processEnv = <String, String>{
        ...Platform.environment,
        ...credentials,
        ...(environment ?? {}),
      };

      // Update progress: Starting installation
      _updateInstallationProgress(serverId, InstallationPhase.installing,
        'Starting ${catalogEntry.name}...', 0.3);

      // Start the process based on transport type
      final process = await _startProcessForTransportWithProgress(
        catalogEntry,
        processEnv,
        serverId,
      );

      if (process == null) {
        throw MCPProcessException('Failed to start process for $serverId');
      }

      // Create server configuration
      final serverConfig = MCPServerConfig(
        id: serverId,
        name: catalogEntry.name,
        url: 'stdio://localhost', // Default URL for stdio transport
        command: catalogEntry.command,
        args: catalogEntry.args,
        transportType: catalogEntry.transport,
        environment: processEnv,
        credentials: credentials,
      );

      // Create process tracking object
      final serverProcess = MCPServerProcess(
        id: processId,
        serverId: serverId,
        agentId: agentId,
        config: serverConfig,
        pid: process.pid,
        startTime: DateTime.now(),
        status: MCPServerStatus.starting,
      );

      _runningProcesses[processId] = serverProcess;
      _systemProcesses[processId] = process;

      // Log server startup
      _addLogEntry(serverId, LogLevel.info, 'Starting MCP server process', {
        'processId': processId,
        'pid': process.pid,
        'command': catalogEntry.command,
        'args': catalogEntry.args,
      });

      // Setup process monitoring
      await _setupProcessMonitoring(processId, process);

      // Wait for startup with timeout
      final startupSuccess = await startupCompleter.future
          .timeout(_startupTimeout, onTimeout: () => false);

      if (!startupSuccess) {
        _addLogEntry(serverId, LogLevel.error, 'Server startup timeout', {
          'processId': processId,
          'timeout': _startupTimeout.inSeconds,
        });
        await _cleanupProcess(processId);
        throw MCPProcessException('Server startup timeout for $serverId');
      }

      // Establish MCP protocol connection
      final connection = await _protocolHandler.establishConnection(serverProcess);
      _connections[processId] = connection;

      // Mark as running
      final runningProcess = serverProcess.copyWith(
        status: MCPServerStatus.running,
        lastHealthCheck: DateTime.now(),
      );
      _runningProcesses[processId] = runningProcess;

      // Log successful startup
      _addLogEntry(serverId, LogLevel.info, 'MCP server started successfully', {
        'processId': processId,
        'pid': process.pid,
        'status': 'running',
        'startupTime': DateTime.now().difference(serverProcess.startTime).inMilliseconds,
      });

      // Start health check monitoring
      _startHealthCheck(processId);

      return runningProcess;
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
        return await _startHttpServer(catalogEntry, environment);
    }
  }

  /// Start stdio-based MCP server
  Future<Process> _startStdioProcess(
    MCPCatalogEntry catalogEntry,
    Map<String, String> environment,
  ) async {
    final command = catalogEntry.command.isNotEmpty ? catalogEntry.command : 'uvx';
    final args = catalogEntry.args;

    return await Process.start(
      command,
      args,
      environment: environment,
      mode: ProcessStartMode.normal,
      runInShell: true, // Important for uvx/npx commands
    );
  }

  /// Start HTTP server for SSE transport
  Future<Process> _startHttpServer(
    MCPCatalogEntry catalogEntry,
    Map<String, String> environment,
  ) async {
    final command = catalogEntry.command.isNotEmpty ? catalogEntry.command : 'uvx';
    final args = [...catalogEntry.args, '--transport', 'sse'];

    return await Process.start(
      command,
      args,
      environment: environment,
      mode: ProcessStartMode.normal,
      runInShell: true,
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

    // Log the output
    _addLogEntry(
      serverProcess.serverId,
      isError ? LogLevel.error : LogLevel.debug,
      line,
      {
        'processId': processId,
        'source': isError ? 'stderr' : 'stdout',
      },
    );

    // Log output for debugging
    final prefix = isError ? 'STDERR' : 'STDOUT';
    print('[$prefix] ${serverProcess.serverId}: $line');

    // Check for startup completion signals
    if (!isError && _startupCompleters.containsKey(processId)) {
      if (_isStartupCompleteLine(line)) {
        _startupCompleters[processId]?.complete(true);
        _startupCompleters.remove(processId);
      }
    }

    // Update process logs
    final updatedLogs = List<String>.from(serverProcess.logs)..add('[$prefix] $line');
    final updatedProcess = serverProcess.copyWith(
      logs: updatedLogs.length > 1000 ? updatedLogs.sublist(500) : updatedLogs, // Keep last 1000 lines
      lastOutput: DateTime.now(),
    );
    _runningProcesses[processId] = updatedProcess;
  }

  /// Handle process errors
  void _handleProcessError(String processId, dynamic error) {
    final serverProcess = _runningProcesses[processId];
    if (serverProcess == null) return;

    print('Process error for ${serverProcess.serverId}: $error');

    final updatedProcess = serverProcess.copyWith(
      status: MCPServerStatus.error,
      error: error.toString(),
      lastError: DateTime.now(),
    );
    _runningProcesses[processId] = updatedProcess;

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

    print('Process exited for ${serverProcess.serverId} with code $exitCode');

    // Update process status
    final updatedProcess = serverProcess.copyWith(
      status: exitCode == 0 ? MCPServerStatus.stopped : MCPServerStatus.crashed,
      exitCode: exitCode,
      stopTime: DateTime.now(),
    );
    _runningProcesses[processId] = updatedProcess;

    // Cleanup resources
    _cleanupProcessResources(processId);

    // Attempt restart if crashed and within limits
    if (exitCode != 0 && serverProcess.restartCount < _maxRestartAttempts) {
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

  /// Perform enhanced health check on running process
  Future<void> _performHealthCheck(String processId) async {
    final serverProcess = _runningProcesses[processId];
    final systemProcess = _systemProcesses[processId];
    
    if (serverProcess == null || systemProcess == null) {
      _healthCheckTimers[processId]?.cancel();
      return;
    }

    try {
      // Enhanced process health check
      bool isAlive = await _checkProcessAlive(systemProcess);
      
      if (isAlive) {
        // Process is alive - perform additional health checks
        final isResponsive = await _checkProcessResponsive(processId);
        
        if (isResponsive) {
          // Process is healthy - update health check time
          final updatedProcess = serverProcess.copyWith(
            lastHealthCheck: DateTime.now(),
            status: MCPServerStatus.running,
          );
          _runningProcesses[processId] = updatedProcess;
        } else {
          // Process is alive but not responsive
          _handleUnresponsiveProcess(processId);
        }
      } else {
        // Process died unexpectedly
        _handleProcessExit(processId, -1);
      }
    } catch (e) {
      // Process might be dead or unreachable
      _handleProcessError(processId, 'Health check failed: $e');
    }
  }

  /// Check if process is still alive (cross-platform)
  Future<bool> _checkProcessAlive(Process process) async {
    try {
      if (Platform.isWindows) {
        // On Windows, use tasklist to check if process exists
        final result = await Process.run('tasklist', ['/FI', 'PID eq ${process.pid}']);
        return result.stdout.toString().contains('${process.pid}');
      } else {
        // On Unix-like systems, use kill -0
        final result = await Process.run('kill', ['-0', '${process.pid}']);
        return result.exitCode == 0;
      }
    } catch (e) {
      return false;
    }
  }

  /// Check if process is responsive to MCP requests
  Future<bool> _checkProcessResponsive(String processId) async {
    try {
      // Send a simple ping request with timeout
      await sendMCPRequest(processId, {
        'jsonrpc': '2.0',
        'id': 'health_ping_${DateTime.now().millisecondsSinceEpoch}',
        'method': 'ping',
        'params': {},
      }).timeout(const Duration(seconds: 3));
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Handle unresponsive process
  void _handleUnresponsiveProcess(String processId) {
    final serverProcess = _runningProcesses[processId];
    if (serverProcess == null) return;

    print('Process $processId is unresponsive, marking as error state');
    
    final updatedProcess = serverProcess.copyWith(
      status: MCPServerStatus.error,
      error: 'Process unresponsive to health checks',
      lastError: DateTime.now(),
    );
    _runningProcesses[processId] = updatedProcess;
    
    // Schedule restart for unresponsive process
    _scheduleRestart(processId);
  }

  /// Schedule process restart with exponential backoff
  void _scheduleRestart(String processId) {
    final serverProcess = _runningProcesses[processId];
    if (serverProcess == null) return;

    final restartCount = serverProcess.restartCount;
    
    // Check if we've exceeded maximum restart attempts
    if (restartCount >= _maxRestartAttempts) {
      print('Maximum restart attempts reached for ${serverProcess.serverId}, marking as failed');
      final failedProcess = serverProcess.copyWith(
        status: MCPServerStatus.failed,
        error: 'Maximum restart attempts exceeded',
      );
      _runningProcesses[processId] = failedProcess;
      return;
    }

    // Calculate exponential backoff delay
    final backoffMultiplier = (1 << restartCount).clamp(1, 32); // 1, 2, 4, 8, 16, 32
    final backoffDelay = Duration(
      milliseconds: (_restartCooldown.inMilliseconds * backoffMultiplier)
          .clamp(_restartCooldown.inMilliseconds, 300000) // Max 5 minutes
    );

    print('Scheduling restart for ${serverProcess.serverId} (attempt ${restartCount + 1}/$_maxRestartAttempts) in ${backoffDelay.inSeconds}s');

    Timer(backoffDelay, () async {
      await _attemptRestart(processId);
    });
  }

  /// Attempt to restart a server process
  Future<void> _attemptRestart(String processId) async {
    final serverProcess = _runningProcesses[processId];
    if (serverProcess == null) return;

    try {
      print('Attempting restart for ${serverProcess.serverId} (attempt ${serverProcess.restartCount + 1})');
      
      // First, ensure the old process is fully cleaned up
      await _forceCleanupProcess(processId);
      
      // Wait a moment for system cleanup
      await Future.delayed(const Duration(seconds: 2));
      
      // Attempt to restart the server
      final restartedProcess = await startServer(
        serverId: serverProcess.serverId,
        agentId: serverProcess.agentId,
        credentials: serverProcess.config.credentials,
        environment: serverProcess.config.environment,
      );

      // Update restart count on the new process
      final updatedProcess = restartedProcess.copyWith(
        restartCount: serverProcess.restartCount + 1,
      );
      _runningProcesses[processId] = updatedProcess;
      
      print('Successfully restarted ${serverProcess.serverId}');
      
    } catch (e) {
      print('Restart failed for ${serverProcess.serverId}: $e');
      
      final failedProcess = serverProcess.copyWith(
        status: MCPServerStatus.crashed,
        error: 'Restart failed: $e',
        restartCount: serverProcess.restartCount + 1,
        lastError: DateTime.now(),
      );
      _runningProcesses[processId] = failedProcess;
      
      // Schedule another restart attempt if we haven't exceeded the limit
      if (failedProcess.restartCount < _maxRestartAttempts) {
        _scheduleRestart(processId);
      } else {
        print('Maximum restart attempts exceeded for ${serverProcess.serverId}');
        final finalFailedProcess = failedProcess.copyWith(
          status: MCPServerStatus.failed,
          error: 'Maximum restart attempts exceeded after ${failedProcess.restartCount} attempts',
        );
        _runningProcesses[processId] = finalFailedProcess;
      }
    }
  }

  /// Force cleanup of a process and its resources
  Future<void> _forceCleanupProcess(String processId) async {
    final systemProcess = _systemProcesses[processId];
    
    if (systemProcess != null) {
      try {
        // Try graceful termination first
        systemProcess.kill(ProcessSignal.sigterm);
        
        // Wait a moment for graceful shutdown
        await Future.delayed(const Duration(seconds: 2));
        
        // Force kill if still running
        if (Platform.isWindows) {
          await Process.run('taskkill', ['/F', '/PID', '${systemProcess.pid}']);
        } else {
          systemProcess.kill(ProcessSignal.sigkill);
        }
      } catch (e) {
        print('Error during force cleanup of process $processId: $e');
      }
    }
    
    // Clean up all tracking resources
    _cleanupProcessResources(processId);
    _systemProcesses.remove(processId);
  }

  /// Stop server process gracefully with enhanced shutdown procedure
  @override
  Future<bool> stopServer(String processId) async {
    final serverProcess = _runningProcesses[processId];
    final systemProcess = _systemProcesses[processId];
    
    if (serverProcess == null || systemProcess == null) {
      // Clean up any remaining tracking data
      await _cleanupProcess(processId);
      return false;
    }

    print('Initiating graceful shutdown for ${serverProcess.serverId}');

    try {
      // Update status to stopping
      final stoppingProcess = serverProcess.copyWith(
        status: MCPServerStatus.stopping,
      );
      _runningProcesses[processId] = stoppingProcess;

      // Step 1: Send MCP shutdown notification
      await _sendMCPShutdownNotification(processId);
      
      // Step 2: Send graceful shutdown signal
      systemProcess.kill(ProcessSignal.sigterm);

      // Step 3: Wait for graceful shutdown with timeout
      final exitCode = await systemProcess.exitCode
          .timeout(_shutdownTimeout, onTimeout: () => -1); // Use -1 to indicate timeout

      if (exitCode != -1) {
        print('Server ${serverProcess.serverId} shut down gracefully with exit code $exitCode');
        await _cleanupProcess(processId);
        return true;
      } else {
        // Step 4: Force termination if graceful shutdown failed
        print('Graceful shutdown timeout for ${serverProcess.serverId}, forcing termination');
        await _forceTerminateProcess(processId);
        await _cleanupProcess(processId);
        return true;
      }
      
    } catch (e) {
      print('Error stopping server ${serverProcess.serverId}: $e');
      await _forceTerminateProcess(processId);
      await _cleanupProcess(processId);
      return false;
    }
  }

  /// Send MCP shutdown notification to server
  Future<void> _sendMCPShutdownNotification(String processId) async {
    try {
      await sendMCPRequest(processId, {
        'jsonrpc': '2.0',
        'id': 'shutdown_${DateTime.now().millisecondsSinceEpoch}',
        'method': 'shutdown',
        'params': {},
      }).timeout(const Duration(seconds: 3));
      
      print('Sent MCP shutdown notification to $processId');
    } catch (e) {
      print('Failed to send MCP shutdown notification to $processId: $e');
    }
  }

  /// Force terminate a process
  Future<void> _forceTerminateProcess(String processId) async {
    final systemProcess = _systemProcesses[processId];
    if (systemProcess == null) return;

    try {
      if (Platform.isWindows) {
        // Use taskkill for force termination on Windows
        await Process.run('taskkill', ['/F', '/PID', '${systemProcess.pid}']);
      } else {
        // Use SIGKILL for force termination on Unix-like systems
        systemProcess.kill(ProcessSignal.sigkill);
      }
      
      print('Force terminated process $processId');
    } catch (e) {
      print('Error force terminating process $processId: $e');
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
  @override
  MCPServerProcess? getRunningServer(String processId) {
    return _runningProcesses[processId];
  }

  /// Get MCP connection for process
  @override
  MCPConnection? getConnection(String processId) {
    return _connections[processId];
  }

  /// Get all running servers
  @override
  List<MCPServerProcess> getAllRunningServers() {
    return _runningProcesses.values.toList();
  }

  /// Get servers for specific agent
  @override
  List<MCPServerProcess> getServersForAgent(String agentId) {
    return _runningProcesses.values
        .where((process) => process.agentId == agentId)
        .toList();
  }

  /// Stop all servers for an agent
  @override
  Future<void> stopAllServersForAgent(String agentId) async {
    final agentServers = getServersForAgent(agentId);
    
    await Future.wait(
      agentServers.map((server) => stopServer(server.id)),
    );
  }

  // ==================== Installation Progress Tracking ====================

  /// Initialize installation progress tracking for a server
  void _initializeInstallationProgress(String serverId) {
    final controller = StreamController<InstallationProgress>.broadcast();
    _installationProgressControllers[serverId] = controller;

    final initialProgress = InstallationProgress(
      serverId: serverId,
      phase: InstallationPhase.preparing,
      message: 'Initializing server installation...',
      progress: 0.0,
    );

    _currentInstallationProgress[serverId] = initialProgress;
    controller.add(initialProgress);
  }

  /// Update installation progress
  void _updateInstallationProgress(String serverId, InstallationPhase phase, String message, double progress) {
    final controller = _installationProgressControllers[serverId];
    if (controller == null || controller.isClosed) return;

    final currentProgress = _currentInstallationProgress[serverId];
    if (currentProgress == null) return;

    final newProgress = currentProgress.copyWith(
      phase: phase,
      message: message,
      progress: progress,
      isComplete: phase == InstallationPhase.completed,
      errorMessage: phase == InstallationPhase.failed ? message : null,
    );

    _currentInstallationProgress[serverId] = newProgress;
    controller.add(newProgress);

    // Auto-close completed/failed installations after a delay
    if (phase == InstallationPhase.completed || phase == InstallationPhase.failed) {
      Timer(const Duration(seconds: 5), () {
        _cleanupInstallationProgress(serverId);
      });
    }
  }

  /// Add log output to installation progress
  void _addInstallationLogOutput(String serverId, String logLine) {
    final currentProgress = _currentInstallationProgress[serverId];
    if (currentProgress == null) return;

    final updatedLogs = [...currentProgress.logOutput, logLine];
    final newProgress = currentProgress.copyWith(logOutput: updatedLogs);

    _currentInstallationProgress[serverId] = newProgress;
    final controller = _installationProgressControllers[serverId];
    if (controller != null && !controller.isClosed) {
      controller.add(newProgress);
    }
  }

  /// Get installation progress stream for a server
  Stream<InstallationProgress>? getInstallationProgressStream(String serverId) {
    return _installationProgressControllers[serverId]?.stream;
  }

  /// Get current installation progress for a server
  InstallationProgress? getCurrentInstallationProgress(String serverId) {
    return _currentInstallationProgress[serverId];
  }

  /// Clean up installation progress tracking
  void _cleanupInstallationProgress(String serverId) {
    final controller = _installationProgressControllers.remove(serverId);
    if (controller != null && !controller.isClosed) {
      controller.close();
    }
    _currentInstallationProgress.remove(serverId);
  }

  /// Enhanced process starting with progress tracking
  Future<Process?> _startProcessForTransportWithProgress(
    MCPCatalogEntry catalogEntry,
    Map<String, String> environment,
    String serverId,
  ) async {
    try {
      switch (catalogEntry.transport) {
        case MCPTransportType.stdio:
          return await _startStdioProcessWithProgress(catalogEntry, environment, serverId);
        case MCPTransportType.sse:
          return await _startHttpServerWithProgress(catalogEntry, environment, serverId);
        case MCPTransportType.http:
          return await _startHttpServerWithProgress(catalogEntry, environment, serverId);
      }
    } catch (e) {
      _updateInstallationProgress(serverId, InstallationPhase.failed,
        'Failed to start process: $e', 1.0);
      rethrow;
    }
  }

  /// Start stdio process with progress tracking
  Future<Process> _startStdioProcessWithProgress(
    MCPCatalogEntry catalogEntry,
    Map<String, String> environment,
    String serverId,
  ) async {
    _updateInstallationProgress(serverId, InstallationPhase.starting,
      'Starting ${catalogEntry.command}...', 0.7);

    final command = catalogEntry.command.isNotEmpty ? catalogEntry.command : 'uvx';
    final args = catalogEntry.args;

    // For uvx/npx commands, we might need to handle installation first
    if (command == 'uvx' || command == 'npx') {
      _updateInstallationProgress(serverId, InstallationPhase.downloading,
        'Installing dependencies...', 0.5);
    }

    final process = await Process.start(
      command,
      args,
      environment: environment,
      mode: ProcessStartMode.normal,
      runInShell: true,
    );

    // Monitor process output for installation feedback
    _monitorProcessForInstallation(process, serverId);

    _updateInstallationProgress(serverId, InstallationPhase.configuring,
      'Configuring server...', 0.9);

    return process;
  }

  /// Start HTTP server with progress tracking
  Future<Process> _startHttpServerWithProgress(
    MCPCatalogEntry catalogEntry,
    Map<String, String> environment,
    String serverId,
  ) async {
    _updateInstallationProgress(serverId, InstallationPhase.starting,
      'Starting HTTP server...', 0.7);

    final command = catalogEntry.command.isNotEmpty ? catalogEntry.command : 'uvx';
    final args = [...catalogEntry.args, '--transport', 'sse'];

    final process = await Process.start(
      command,
      args,
      environment: environment,
      mode: ProcessStartMode.normal,
      runInShell: true,
    );

    // Monitor process output for installation feedback
    _monitorProcessForInstallation(process, serverId);

    return process;
  }

  /// Monitor process output during installation
  void _monitorProcessForInstallation(Process process, String serverId) {
    // Monitor stdout for installation progress
    process.stdout.transform(utf8.decoder).listen((data) {
      final lines = data.split('\n');
      for (final line in lines) {
        if (line.trim().isNotEmpty) {
          _addInstallationLogOutput(serverId, line.trim());

          // Parse common installation messages
          if (line.contains('Installing') || line.contains('Downloading')) {
            _updateInstallationProgress(serverId, InstallationPhase.downloading,
              'Installing: ${line.trim()}', 0.6);
          } else if (line.contains('Starting') || line.contains('Ready')) {
            _updateInstallationProgress(serverId, InstallationPhase.starting,
              'Server starting...', 0.8);
          } else if (line.contains('listening') || line.contains('server started')) {
            _updateInstallationProgress(serverId, InstallationPhase.completed,
              'Server started successfully!', 1.0);
          }
        }
      }
    });

    // Monitor stderr for errors
    process.stderr.transform(utf8.decoder).listen((data) {
      final lines = data.split('\n');
      for (final line in lines) {
        if (line.trim().isNotEmpty) {
          _addInstallationLogOutput(serverId, '[ERROR] ${line.trim()}');

          // Check for common error patterns
          if (line.contains('Error') || line.contains('Failed') || line.contains('not found')) {
            _updateInstallationProgress(serverId, InstallationPhase.failed,
              'Installation failed: ${line.trim()}', 1.0);
          }
        }
      }
    });

    // Set a timeout to mark as completed if no explicit completion signal
    Timer(const Duration(seconds: 10), () {
      final currentProgress = _currentInstallationProgress[serverId];
      if (currentProgress != null && !currentProgress.isComplete && currentProgress.phase != InstallationPhase.failed) {
        _updateInstallationProgress(serverId, InstallationPhase.completed,
          'Server installation completed', 1.0);
      }
    });
  }

  /// Emergency shutdown of all processes
  @override
  Future<void> emergencyShutdown() async {
    print('Performing emergency shutdown of all MCP processes...');

    final shutdownFutures = _runningProcesses.keys
        .map((processId) => stopServer(processId))
        .toList();

    await Future.wait(shutdownFutures);

    // Force cleanup any remaining resources
    _runningProcesses.clear();
    _systemProcesses.clear();

    // Close installation progress controllers
    for (final controller in _installationProgressControllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _installationProgressControllers.clear();
    _currentInstallationProgress.clear();

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
  @override
  Map<String, dynamic> getProcessStatistics() {
    final stats = <String, dynamic>{
      'total_processes': _runningProcesses.length,
      'running': 0,
      'stopping': 0,
      'error': 0,
      'crashed': 0,
    };

    for (final process in _runningProcesses.values) {
      final statusKey = process.status.name;
      stats[statusKey] = (stats[statusKey] as int? ?? 0) + 1;
    }

    return stats;
  }

  /// Install MCP server in agent's terminal
  @override
  Future<MCPInstallResult> installServer(String agentId, String serverId) async {
    // This would typically involve installing the server using uvx/npx
    // For now, return a mock result
    return MCPInstallResult(
      success: true,
      serverId: serverId,
      installationTime: const Duration(seconds: 5),
      installationLogs: const ['Mock installation completed'],
    );
  }
  
  /// Get server status
  @override
  MCPServerStatus getServerStatus(String processId) {
    final process = _runningProcesses[processId];
    return process?.status ?? MCPServerStatus.stopped;
  }
  
  /// Handle JSON-RPC communication
  @override
  Future<dynamic> sendMCPRequest(String processId, Map<String, dynamic> request) async {
    final connection = _connections[processId];
    if (connection == null) {
      throw MCPProcessException('No connection found for process $processId');
    }

    final method = request['method'] as String;
    final params = request['params'] as Map<String, dynamic>?;

    final response = await connection.request(method, params);
    return response.toJson();
  }

  /// Get server logs
  @override
  Future<List<MCPLogEntry>> getServerLogs(String serverId, {int limit = 100}) async {
    final logs = _serverLogs[serverId] ?? [];
    if (logs.length <= limit) {
      return List.from(logs);
    }
    return logs.skip(logs.length - limit).toList();
  }

  /// Stream server logs in real-time
  @override
  Stream<MCPLogEntry> streamServerLogs(String serverId) {
    _logStreamControllers[serverId] ??= StreamController<MCPLogEntry>.broadcast();
    return _logStreamControllers[serverId]!.stream;
  }

  /// Clear server logs
  @override
  Future<void> clearServerLogs(String serverId) async {
    _serverLogs[serverId]?.clear();
  }

  /// Add log entry for a server
  void _addLogEntry(String serverId, LogLevel level, String message, [Map<String, dynamic>? metadata]) {
    final logEntry = MCPLogEntry(
      serverId: serverId,
      timestamp: DateTime.now(),
      level: level,
      message: message,
      metadata: metadata,
    );

    // Add to stored logs
    _serverLogs[serverId] ??= [];
    _serverLogs[serverId]!.add(logEntry);

    // Trim logs to maximum size
    if (_serverLogs[serverId]!.length > _maxLogsPerServer) {
      _serverLogs[serverId]!.removeRange(0, _serverLogs[serverId]!.length - _maxLogsPerServer);
    }

    // Stream to listeners
    _logStreamControllers[serverId]?.add(logEntry);
  }

  /// Dispose all resources
  @override
  Future<void> dispose() async {
    // Close all log stream controllers
    for (final controller in _logStreamControllers.values) {
      await controller.close();
    }
    _logStreamControllers.clear();
    _serverLogs.clear();

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
  return MCPProcessManager(catalogService, protocolHandler);
});

/// Provider for watching running MCP servers
final runningMCPServersProvider = StreamProvider<List<MCPServerProcess>>((ref) {
  final processManager = ref.read(mcpProcessManagerProvider);

  // Create a stream that emits the current running servers every second
  return Stream.periodic(const Duration(seconds: 1), (_) {
    return processManager.getAllRunningServers();
  });
});