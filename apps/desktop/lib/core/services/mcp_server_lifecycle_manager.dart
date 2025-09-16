import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mcp_server_process.dart';
import '../models/mcp_catalog_entry.dart';
import 'mcp_process_manager.dart';
import 'production_logger.dart';

/// Enhanced MCP server lifecycle manager with comprehensive health monitoring,
/// automatic restart capabilities, and clean shutdown procedures
class MCPServerLifecycleManager {
  final MCPProcessManager _processManager;
  final ProductionLogger _logger;
  
  // Health monitoring configuration
  static const Duration _healthCheckInterval = Duration(seconds: 15);
  static const Duration _healthCheckTimeout = Duration(seconds: 5);
  static const int _maxConsecutiveFailures = 3;
  static const int _maxRestartAttempts = 5;
  static const Duration _restartBackoffBase = Duration(seconds: 2);
  static const Duration _maxRestartBackoff = Duration(minutes: 5);
  
  // Server lifecycle tracking
  final Map<String, Timer> _healthCheckTimers = {};
  final Map<String, int> _consecutiveHealthFailures = {};
  final Map<String, int> _restartAttempts = {};
  final Map<String, DateTime> _lastRestartTime = {};
  final Map<String, StreamController<MCPServerHealthStatus>> _healthStatusStreams = {};
  final Map<String, Completer<void>> _shutdownCompleters = {};
  
  MCPServerLifecycleManager(this._processManager, this._logger);

  /// Start comprehensive server lifecycle management
  Future<MCPServerProcess> startServerWithLifecycleManagement({
    required String serverId,
    required String agentId,
    required Map<String, String> credentials,
    Map<String, String>? environment,
  }) async {
    final processId = '$agentId:$serverId';
    
    _logger.info('Starting server lifecycle management for $processId');
    
    try {
      // Start the server using the process manager
      final serverProcess = await _processManager.startServer(
        serverId: serverId,
        agentId: agentId,
        credentials: credentials,
        environment: environment,
      );
      
      // Initialize lifecycle tracking
      _initializeLifecycleTracking(processId);
      
      // Start health monitoring
      await _startHealthMonitoring(processId);
      
      _logger.info('Server lifecycle management started successfully for $processId');
      return serverProcess;
      
    } catch (e) {
      _logger.error('Failed to start server lifecycle management for $processId: $e');
      await _cleanupLifecycleTracking(processId);
      rethrow;
    }
  }

  /// Initialize lifecycle tracking for a server
  void _initializeLifecycleTracking(String processId) {
    _consecutiveHealthFailures[processId] = 0;
    _restartAttempts[processId] = 0;
    _healthStatusStreams[processId] = StreamController<MCPServerHealthStatus>.broadcast();
  }

  /// Start comprehensive health monitoring
  Future<void> _startHealthMonitoring(String processId) async {
    _logger.debug('Starting health monitoring for $processId');
    
    // Cancel any existing health check timer
    _healthCheckTimers[processId]?.cancel();
    
    // Start periodic health checks
    _healthCheckTimers[processId] = Timer.periodic(_healthCheckInterval, (timer) {
      _performComprehensiveHealthCheck(processId);
    });
    
    // Perform initial health check
    await _performComprehensiveHealthCheck(processId);
  }

  /// Perform comprehensive health check on server
  Future<void> _performComprehensiveHealthCheck(String processId) async {
    final serverProcess = _processManager.getRunningServer(processId);
    if (serverProcess == null) {
      _logger.warning('Server process not found during health check: $processId');
      await _handleServerNotFound(processId);
      return;
    }

    _logger.debug('Performing health check for $processId');
    
    try {
      final healthStatus = await _checkServerHealth(serverProcess);
      
      if (healthStatus.isHealthy) {
        await _handleHealthyServer(processId, healthStatus);
      } else {
        await _handleUnhealthyServer(processId, healthStatus);
      }
      
      // Broadcast health status
      _healthStatusStreams[processId]?.add(healthStatus);
      
    } catch (e) {
      _logger.error('Health check failed for $processId: $e');
      await _handleHealthCheckError(processId, e);
    }
  }

  /// Check server health using multiple indicators
  Future<MCPServerHealthStatus> _checkServerHealth(MCPServerProcess serverProcess) async {
    final healthChecks = <String, bool>{};
    final errors = <String>[];
    
    try {
      // 1. Process existence check
      healthChecks['process_exists'] = await _checkProcessExists(serverProcess);
      if (!healthChecks['process_exists']!) {
        errors.add('Process no longer exists');
      }
      
      // 2. Response time check
      final responseTime = await _checkResponseTime(serverProcess);
      healthChecks['response_time'] = responseTime != null && responseTime.inMilliseconds < 5000;
      if (!healthChecks['response_time']!) {
        errors.add('Response time too slow or no response');
      }
      
      // 3. Memory usage check
      healthChecks['memory_usage'] = await _checkMemoryUsage(serverProcess);
      if (!healthChecks['memory_usage']!) {
        errors.add('Memory usage too high');
      }
      
      // 4. Error rate check
      healthChecks['error_rate'] = await _checkErrorRate(serverProcess);
      if (!healthChecks['error_rate']!) {
        errors.add('Error rate too high');
      }
      
      // 5. MCP protocol health check
      healthChecks['mcp_protocol'] = await _checkMCPProtocolHealth(serverProcess);
      if (!healthChecks['mcp_protocol']!) {
        errors.add('MCP protocol not responding');
      }
      
    } catch (e) {
      errors.add('Health check exception: $e');
    }
    
    final isHealthy = healthChecks.values.every((check) => check);
    
    return MCPServerHealthStatus(
      processId: serverProcess.id,
      isHealthy: isHealthy,
      healthChecks: healthChecks,
      errors: errors,
      timestamp: DateTime.now(),
      responseTime: await _checkResponseTime(serverProcess),
    );
  }

  /// Check if process still exists
  Future<bool> _checkProcessExists(MCPServerProcess serverProcess) async {
    if (serverProcess.pid == null) return false;
    
    try {
      // On Windows, use tasklist to check if process exists
      if (Platform.isWindows) {
        final result = await Process.run('tasklist', ['/FI', 'PID eq ${serverProcess.pid}']);
        return result.stdout.toString().contains('${serverProcess.pid}');
      } else {
        // On Unix-like systems, use kill -0
        final result = await Process.run('kill', ['-0', '${serverProcess.pid}']);
        return result.exitCode == 0;
      }
    } catch (e) {
      _logger.warning('Failed to check process existence for ${serverProcess.id}: $e');
      return false;
    }
  }

  /// Check server response time
  Future<Duration?> _checkResponseTime(MCPServerProcess serverProcess) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Send a simple ping request to the MCP server
      await _processManager.sendMCPRequest(serverProcess.id, {
        'jsonrpc': '2.0',
        'id': 'health_check_${DateTime.now().millisecondsSinceEpoch}',
        'method': 'ping',
        'params': {},
      }).timeout(_healthCheckTimeout);
      
      stopwatch.stop();
      return stopwatch.elapsed;
      
    } catch (e) {
      _logger.debug('Response time check failed for ${serverProcess.id}: $e');
      return null;
    }
  }

  /// Check memory usage
  Future<bool> _checkMemoryUsage(MCPServerProcess serverProcess) async {
    if (serverProcess.pid == null) return false;
    
    try {
      // Get memory usage based on platform
      if (Platform.isWindows) {
        final result = await Process.run('tasklist', [
          '/FI', 'PID eq ${serverProcess.pid}',
          '/FO', 'CSV'
        ]);
        
        final lines = result.stdout.toString().split('\n');
        if (lines.length > 1) {
          final parts = lines[1].split(',');
          if (parts.length > 4) {
            final memoryStr = parts[4].replaceAll('"', '').replaceAll(',', '').replaceAll(' K', '');
            final memoryKB = int.tryParse(memoryStr) ?? 0;
            // Consider unhealthy if using more than 500MB
            return memoryKB < 500000;
          }
        }
      } else {
        final result = await Process.run('ps', ['-p', '${serverProcess.pid}', '-o', 'rss=']);
        final memoryKB = int.tryParse(result.stdout.toString().trim()) ?? 0;
        // Consider unhealthy if using more than 500MB
        return memoryKB < 500000;
      }
      
      return true; // Default to healthy if we can't determine memory usage
    } catch (e) {
      _logger.debug('Memory usage check failed for ${serverProcess.id}: $e');
      return true; // Default to healthy on error
    }
  }

  /// Check error rate
  Future<bool> _checkErrorRate(MCPServerProcess serverProcess) async {
    // Check recent logs for error patterns
    final recentLogs = serverProcess.logs.length > 50 
        ? serverProcess.logs.sublist(serverProcess.logs.length - 50)
        : serverProcess.logs;
    
    final errorCount = recentLogs.where((log) => 
        log.toLowerCase().contains('error') || 
        log.toLowerCase().contains('exception') ||
        log.toLowerCase().contains('failed')
    ).length;
    
    // Consider unhealthy if more than 20% of recent logs are errors
    return errorCount < (recentLogs.length * 0.2);
  }

  /// Check MCP protocol health
  Future<bool> _checkMCPProtocolHealth(MCPServerProcess serverProcess) async {
    try {
      // Try to get server capabilities
      final response = await _processManager.sendMCPRequest(serverProcess.id, {
        'jsonrpc': '2.0',
        'id': 'capabilities_check_${DateTime.now().millisecondsSinceEpoch}',
        'method': 'initialize',
        'params': {
          'protocolVersion': '2024-11-05',
          'capabilities': {},
          'clientInfo': {
            'name': 'AgentEngine',
            'version': '1.0.0',
          },
        },
      }).timeout(_healthCheckTimeout);
      
      return response != null && response['result'] != null;
    } catch (e) {
      _logger.debug('MCP protocol health check failed for ${serverProcess.id}: $e');
      return false;
    }
  }

  /// Handle healthy server
  Future<void> _handleHealthyServer(String processId, MCPServerHealthStatus healthStatus) async {
    // Reset consecutive failure count
    _consecutiveHealthFailures[processId] = 0;
    
    _logger.debug('Server $processId is healthy');
  }

  /// Handle unhealthy server
  Future<void> _handleUnhealthyServer(String processId, MCPServerHealthStatus healthStatus) async {
    final failures = (_consecutiveHealthFailures[processId] ?? 0) + 1;
    _consecutiveHealthFailures[processId] = failures;
    
    _logger.warning('Server $processId is unhealthy (failure $failures/$_maxConsecutiveFailures): ${healthStatus.errors.join(', ')}');
    
    if (failures >= _maxConsecutiveFailures) {
      _logger.error('Server $processId has failed $failures consecutive health checks, attempting restart');
      await _attemptServerRestart(processId);
    }
  }

  /// Handle server not found during health check
  Future<void> _handleServerNotFound(String processId) async {
    _logger.warning('Server $processId not found during health check, attempting restart');
    await _attemptServerRestart(processId);
  }

  /// Handle health check error
  Future<void> _handleHealthCheckError(String processId, dynamic error) async {
    final failures = (_consecutiveHealthFailures[processId] ?? 0) + 1;
    _consecutiveHealthFailures[processId] = failures;
    
    _logger.error('Health check error for $processId (failure $failures/$_maxConsecutiveFailures): $error');
    
    if (failures >= _maxConsecutiveFailures) {
      await _attemptServerRestart(processId);
    }
  }

  /// Attempt to restart a failed server with exponential backoff
  Future<void> _attemptServerRestart(String processId) async {
    final attempts = _restartAttempts[processId] ?? 0;
    
    if (attempts >= _maxRestartAttempts) {
      _logger.error('Server $processId has exceeded maximum restart attempts ($attempts/$_maxRestartAttempts), marking as failed');
      await _markServerAsFailed(processId);
      return;
    }
    
    // Calculate backoff delay
    final backoffDelay = Duration(
      milliseconds: (_restartBackoffBase.inMilliseconds * (1 << attempts))
          .clamp(0, _maxRestartBackoff.inMilliseconds)
    );
    
    _logger.info('Restarting server $processId (attempt ${attempts + 1}/$_maxRestartAttempts) after ${backoffDelay.inSeconds}s delay');
    
    // Wait for backoff delay
    await Future.delayed(backoffDelay);
    
    try {
      // Get server info for restart
      final serverProcess = _processManager.getRunningServer(processId);
      if (serverProcess == null) {
        _logger.error('Cannot restart server $processId: server process not found');
        return;
      }
      
      // Stop the current server
      await _processManager.stopServer(processId);
      
      // Wait a moment for cleanup
      await Future.delayed(const Duration(seconds: 2));
      
      // Restart the server
      final restartedProcess = await _processManager.startServer(
        serverId: serverProcess.serverId,
        agentId: serverProcess.agentId,
        credentials: serverProcess.config.credentials,
        environment: serverProcess.config.environment,
      );
      
      // Update restart tracking
      _restartAttempts[processId] = attempts + 1;
      _lastRestartTime[processId] = DateTime.now();
      _consecutiveHealthFailures[processId] = 0;
      
      _logger.info('Server $processId restarted successfully');
      
      // Restart health monitoring
      await _startHealthMonitoring(processId);
      
    } catch (e) {
      _logger.error('Failed to restart server $processId: $e');
      _restartAttempts[processId] = attempts + 1;
      
      // Schedule another restart attempt if we haven't exceeded the limit
      if (_restartAttempts[processId]! < _maxRestartAttempts) {
        Timer(const Duration(seconds: 5), () => _attemptServerRestart(processId));
      } else {
        await _markServerAsFailed(processId);
      }
    }
  }

  /// Mark server as permanently failed
  Future<void> _markServerAsFailed(String processId) async {
    _logger.error('Marking server $processId as permanently failed');
    
    // Stop health monitoring
    _healthCheckTimers[processId]?.cancel();
    
    // Broadcast final health status
    _healthStatusStreams[processId]?.add(MCPServerHealthStatus(
      processId: processId,
      isHealthy: false,
      healthChecks: {'permanently_failed': false},
      errors: ['Server permanently failed after maximum restart attempts'],
      timestamp: DateTime.now(),
    ));
  }

  /// Perform clean server shutdown with proper resource cleanup
  Future<bool> cleanShutdownServer(String processId) async {
    _logger.info('Performing clean shutdown for server $processId');
    
    try {
      // Create shutdown completer
      final shutdownCompleter = Completer<void>();
      _shutdownCompleters[processId] = shutdownCompleter;
      
      // Stop health monitoring
      _healthCheckTimers[processId]?.cancel();
      
      // Send graceful shutdown signal to MCP server
      await _sendGracefulShutdownSignal(processId);
      
      // Wait for graceful shutdown or timeout
      final shutdownSuccess = await shutdownCompleter.future
          .timeout(const Duration(seconds: 10), onTimeout: () => null) != null;
      
      if (!shutdownSuccess) {
        _logger.warning('Graceful shutdown timeout for $processId, forcing termination');
      }
      
      // Stop the server process
      final stopSuccess = await _processManager.stopServer(processId);
      
      // Clean up lifecycle tracking
      await _cleanupLifecycleTracking(processId);
      
      _logger.info('Clean shutdown completed for $processId (success: $stopSuccess)');
      return stopSuccess;
      
    } catch (e) {
      _logger.error('Error during clean shutdown of $processId: $e');
      await _cleanupLifecycleTracking(processId);
      return false;
    }
  }

  /// Send graceful shutdown signal to MCP server
  Future<void> _sendGracefulShutdownSignal(String processId) async {
    try {
      await _processManager.sendMCPRequest(processId, {
        'jsonrpc': '2.0',
        'id': 'shutdown_${DateTime.now().millisecondsSinceEpoch}',
        'method': 'shutdown',
        'params': {},
      });
      
      // Complete shutdown after sending signal
      _shutdownCompleters[processId]?.complete();
      
    } catch (e) {
      _logger.debug('Failed to send graceful shutdown signal to $processId: $e');
    }
  }

  /// Clean up lifecycle tracking for a server
  Future<void> _cleanupLifecycleTracking(String processId) async {
    _healthCheckTimers[processId]?.cancel();
    _healthStatusStreams[processId]?.close();
    _shutdownCompleters[processId]?.complete();
    
    _healthCheckTimers.remove(processId);
    _consecutiveHealthFailures.remove(processId);
    _restartAttempts.remove(processId);
    _lastRestartTime.remove(processId);
    _healthStatusStreams.remove(processId);
    _shutdownCompleters.remove(processId);
  }

  /// Get health status stream for a server
  Stream<MCPServerHealthStatus> getHealthStatusStream(String processId) {
    return _healthStatusStreams[processId]?.stream ?? const Stream.empty();
  }

  /// Get current health status for a server
  MCPServerHealthStatus? getCurrentHealthStatus(String processId) {
    // This would typically return the last known health status
    // For now, return null to indicate no status available
    return null;
  }

  /// Get lifecycle statistics for all servers
  Map<String, dynamic> getLifecycleStatistics() {
    return {
      'monitored_servers': _healthCheckTimers.length,
      'servers_with_failures': _consecutiveHealthFailures.values.where((f) => f > 0).length,
      'total_restart_attempts': _restartAttempts.values.fold(0, (sum, attempts) => sum + attempts),
      'servers_restarted': _lastRestartTime.length,
    };
  }

  /// Shutdown all server lifecycle management
  Future<void> shutdownAllServers() async {
    _logger.info('Shutting down all server lifecycle management');
    
    final shutdownFutures = _healthCheckTimers.keys
        .map((processId) => cleanShutdownServer(processId))
        .toList();
    
    await Future.wait(shutdownFutures);
    
    _logger.info('All server lifecycle management shut down');
  }

  /// Dispose all resources
  Future<void> dispose() async {
    await shutdownAllServers();
  }
}

/// Health status for an MCP server
class MCPServerHealthStatus {
  final String processId;
  final bool isHealthy;
  final Map<String, bool> healthChecks;
  final List<String> errors;
  final DateTime timestamp;
  final Duration? responseTime;

  MCPServerHealthStatus({
    required this.processId,
    required this.isHealthy,
    required this.healthChecks,
    required this.errors,
    required this.timestamp,
    this.responseTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'processId': processId,
      'isHealthy': isHealthy,
      'healthChecks': healthChecks,
      'errors': errors,
      'timestamp': timestamp.toIso8601String(),
      'responseTimeMs': responseTime?.inMilliseconds,
    };
  }
}

// ==================== Riverpod Provider ====================

final mcpServerLifecycleManagerProvider = Provider<MCPServerLifecycleManager>((ref) {
  final processManager = ref.read(mcpProcessManagerProvider);
  final logger = ref.read(productionLoggerProvider);
  return MCPServerLifecycleManager(processManager, logger);
});