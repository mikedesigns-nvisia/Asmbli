import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mcp_server_process.dart';
import '../models/mcp_connection.dart';
import 'json_rpc_communication_service.dart';
import 'json_rpc_debug_service.dart';
import 'mcp_protocol_handler.dart';
import 'production_logger.dart';

/// Integration service that provides a unified interface for JSON-RPC communication
/// Combines communication, debugging, and protocol handling for MCP servers
class JsonRpcIntegrationService {
  final JsonRpcCommunicationService _communicationService;
  final JsonRpcDebugService _debugService;
  final MCPProtocolHandler _protocolHandler;
  final ProductionLogger _logger;

  JsonRpcIntegrationService(
    this._communicationService,
    this._debugService,
    this._protocolHandler,
    this._logger,
  );

  /// Establish secure connection with comprehensive logging and debugging
  Future<JsonRpcConnectionResult> establishConnection({
    required String agentId,
    required String serverId,
    required MCPServerProcess serverProcess,
    Map<String, String>? credentials,
    bool enableDebug = false,
  }) async {
    _logger.info('Establishing JSON-RPC connection with integration service: $agentId:$serverId');
    
    try {
      // Enable debug if requested
      if (enableDebug) {
        _debugService.enableConnectionDebug(agentId, serverId);
      }
      
      // Establish connection using communication service
      final result = await _communicationService.establishConnection(
        agentId: agentId,
        serverId: serverId,
        serverProcess: serverProcess,
        credentials: credentials,
      );
      
      if (result.success) {
        _logger.info('JSON-RPC connection established successfully: $agentId:$serverId');
      } else {
        _logger.error('Failed to establish JSON-RPC connection: $agentId:$serverId - ${result.error}');
      }
      
      return result;
      
    } catch (e, stackTrace) {
      _logger.error('Error in JSON-RPC connection establishment: $agentId:$serverId - $e', stackTrace);
      return JsonRpcConnectionResult.failure(e.toString());
    }
  }

  /// Send request with automatic retry and comprehensive logging
  Future<JsonRpcResponse> sendRequest({
    required String agentId,
    required String serverId,
    required String method,
    Map<String, dynamic>? params,
    Duration? timeout,
    int maxRetries = 3,
  }) async {
    _logger.debug('Sending JSON-RPC request: $agentId:$serverId - $method');
    
    Exception? lastException;
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await _communicationService.sendRequest(
          agentId: agentId,
          serverId: serverId,
          method: method,
          params: params,
          timeout: timeout,
        );
        
        _logger.debug('JSON-RPC request successful: $agentId:$serverId - $method (attempt $attempt)');
        return response;
        
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        
        if (attempt < maxRetries) {
          _logger.warning('JSON-RPC request failed, retrying: $agentId:$serverId - $method (attempt $attempt/$maxRetries) - $e');
          
          // Exponential backoff
          await Future.delayed(Duration(milliseconds: 100 * attempt * attempt));
        } else {
          _logger.error('JSON-RPC request failed after $maxRetries attempts: $agentId:$serverId - $method - $e');
        }
      }
    }
    
    throw lastException!;
  }

  /// Send notification with logging
  Future<void> sendNotification({
    required String agentId,
    required String serverId,
    required String method,
    Map<String, dynamic>? params,
  }) async {
    _logger.debug('Sending JSON-RPC notification: $agentId:$serverId - $method');
    
    try {
      await _communicationService.sendNotification(
        agentId: agentId,
        serverId: serverId,
        method: method,
        params: params,
      );
      
      _logger.debug('JSON-RPC notification sent successfully: $agentId:$serverId - $method');
      
    } catch (e, stackTrace) {
      _logger.error('Failed to send JSON-RPC notification: $agentId:$serverId - $method - $e', stackTrace);
      rethrow;
    }
  }

  /// Send multiple requests concurrently with comprehensive error handling
  Future<List<JsonRpcResponse>> sendConcurrentRequests({
    required String agentId,
    required String serverId,
    required List<JsonRpcRequestSpec> requests,
    Duration? timeout,
    bool failFast = false,
  }) async {
    _logger.info('Sending ${requests.length} concurrent JSON-RPC requests: $agentId:$serverId');
    
    try {
      if (failFast) {
        // Fail fast - if any request fails, all fail
        final responses = await _communicationService.sendConcurrentRequests(
          agentId: agentId,
          serverId: serverId,
          requests: requests,
          timeout: timeout,
        );
        
        _logger.info('All concurrent JSON-RPC requests completed successfully: $agentId:$serverId');
        return responses;
        
      } else {
        // Resilient mode - collect all results, including errors
        final futures = requests.map((spec) => 
          sendRequest(
            agentId: agentId,
            serverId: serverId,
            method: spec.method,
            params: spec.params,
            timeout: timeout,
          ).catchError((e) => JsonRpcResponse(
            id: 'error_${spec.method}',
            error: {'message': e.toString()},
            isError: true,
          ))
        );
        
        final responses = await Future.wait(futures);
        
        final successCount = responses.where((r) => !r.isError).length;
        final errorCount = responses.where((r) => r.isError).length;
        
        _logger.info('Concurrent JSON-RPC requests completed: $agentId:$serverId (success: $successCount, errors: $errorCount)');
        
        return responses;
      }
      
    } catch (e, stackTrace) {
      _logger.error('Concurrent JSON-RPC requests failed: $agentId:$serverId - $e', stackTrace);
      rethrow;
    }
  }

  /// Get comprehensive connection diagnostics
  JsonRpcConnectionDiagnostics getConnectionDiagnostics(String agentId, String serverId) {
    return _debugService.getConnectionDiagnostics(agentId, serverId);
  }

  /// Get system-wide diagnostics
  JsonRpcSystemDiagnostics getSystemDiagnostics() {
    return _debugService.getSystemDiagnostics();
  }

  /// Analyze connection performance
  JsonRpcPerformanceAnalysis analyzePerformance(String agentId, String serverId) {
    return _debugService.analyzePerformance(agentId, serverId);
  }

  /// Enable debug mode for all connections
  void enableGlobalDebug({bool verbose = false}) {
    _debugService.enableDebug(verbose: verbose);
    _logger.info('Global JSON-RPC debug mode enabled (verbose: $verbose)');
  }

  /// Disable debug mode
  void disableGlobalDebug() {
    _debugService.disableDebug();
    _logger.info('Global JSON-RPC debug mode disabled');
  }

  /// Enable debug for specific connection
  void enableConnectionDebug(String agentId, String serverId) {
    _debugService.enableConnectionDebug(agentId, serverId);
    _logger.info('Debug enabled for JSON-RPC connection: $agentId:$serverId');
  }

  /// Disable debug for specific connection
  void disableConnectionDebug(String agentId, String serverId) {
    _debugService.disableConnectionDebug(agentId, serverId);
    _logger.info('Debug disabled for JSON-RPC connection: $agentId:$serverId');
  }

  /// Export debug logs for analysis
  Map<String, dynamic> exportDebugLogs({
    String? agentId,
    String? serverId,
    DateTime? since,
    int? maxEntries,
  }) {
    return _debugService.exportDebugLogs(
      agentId: agentId,
      serverId: serverId,
      since: since,
      maxEntries: maxEntries,
    );
  }

  /// Clear debug data
  void clearDebugData({String? agentId, String? serverId}) {
    if (agentId != null && serverId != null) {
      _debugService.clearConnectionDebugData(agentId, serverId);
      _logger.info('Cleared debug data for connection: $agentId:$serverId');
    } else {
      _debugService.clearAllDebugData();
      _logger.info('Cleared all JSON-RPC debug data');
    }
  }

  /// Get connection status
  MCPConnectionStatus? getConnectionStatus(String agentId, String serverId) {
    return _communicationService.getConnectionStatus(agentId, serverId);
  }

  /// Get connection statistics
  JsonRpcConnectionStats getConnectionStats(String agentId, String serverId) {
    return _communicationService.getConnectionStats(agentId, serverId);
  }

  /// Get communication logs
  List<JsonRpcLogEntry> getCommunicationLogs(String agentId, String serverId) {
    return _communicationService.getCommunicationLogs(agentId, serverId);
  }

  /// Stream of debug events for real-time monitoring
  Stream<JsonRpcDebugEvent> get debugEvents => _debugService.debugEvents;

  /// Stream of performance metrics
  Stream<JsonRpcPerformanceMetric> get performanceMetrics => _debugService.performanceMetrics;

  /// Stream of communication logs
  Stream<JsonRpcLogEntry> get logStream => _communicationService.logStream;

  /// Close specific connection
  Future<void> closeConnection(String agentId, String serverId) async {
    _logger.info('Closing JSON-RPC connection: $agentId:$serverId');
    
    try {
      await _communicationService.closeConnection(agentId, serverId);
      _logger.info('JSON-RPC connection closed successfully: $agentId:$serverId');
      
    } catch (e, stackTrace) {
      _logger.error('Error closing JSON-RPC connection: $agentId:$serverId - $e', stackTrace);
    }
  }

  /// Close all connections
  Future<void> closeAllConnections() async {
    _logger.info('Closing all JSON-RPC connections');
    
    try {
      await _communicationService.closeAllConnections();
      _logger.info('All JSON-RPC connections closed successfully');
      
    } catch (e, stackTrace) {
      _logger.error('Error closing all JSON-RPC connections: $e', stackTrace);
    }
  }

  /// Health check for a connection
  Future<JsonRpcHealthCheckResult> performHealthCheck(String agentId, String serverId) async {
    _logger.debug('Performing JSON-RPC health check: $agentId:$serverId');
    
    try {
      final startTime = DateTime.now();
      
      // Send a simple ping request
      final response = await sendRequest(
        agentId: agentId,
        serverId: serverId,
        method: 'ping',
        timeout: Duration(seconds: 5),
        maxRetries: 1,
      );
      
      final endTime = DateTime.now();
      final latency = endTime.difference(startTime);
      
      final isHealthy = !response.isError;
      
      _logger.debug('JSON-RPC health check completed: $agentId:$serverId (healthy: $isHealthy, latency: ${latency.inMilliseconds}ms)');
      
      return JsonRpcHealthCheckResult(
        connectionId: '$agentId:$serverId',
        isHealthy: isHealthy,
        latency: latency,
        timestamp: endTime,
        error: response.isError ? response.error.toString() : null,
      );
      
    } catch (e) {
      _logger.warning('JSON-RPC health check failed: $agentId:$serverId - $e');
      
      return JsonRpcHealthCheckResult(
        connectionId: '$agentId:$serverId',
        isHealthy: false,
        latency: Duration.zero,
        timestamp: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// Dispose all services
  Future<void> dispose() async {
    _logger.info('Disposing JSON-RPC integration service');
    
    try {
      await _communicationService.dispose();
      await _debugService.dispose();
      await _protocolHandler.dispose();
      
      _logger.info('JSON-RPC integration service disposed successfully');
      
    } catch (e, stackTrace) {
      _logger.error('Error disposing JSON-RPC integration service: $e', stackTrace);
    }
  }
}

/// Result of a health check operation
class JsonRpcHealthCheckResult {
  final String connectionId;
  final bool isHealthy;
  final Duration latency;
  final DateTime timestamp;
  final String? error;

  JsonRpcHealthCheckResult({
    required this.connectionId,
    required this.isHealthy,
    required this.latency,
    required this.timestamp,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'connectionId': connectionId,
      'isHealthy': isHealthy,
      'latencyMs': latency.inMilliseconds,
      'timestamp': timestamp.toIso8601String(),
      'error': error,
    };
  }
}

// ==================== Riverpod Provider ====================

final jsonRpcIntegrationServiceProvider = Provider<JsonRpcIntegrationService>((ref) {
  final communicationService = ref.read(jsonRpcCommunicationServiceProvider);
  final debugService = ref.read(jsonRpcDebugServiceProvider);
  final protocolHandler = ref.read(mcpProtocolHandlerProvider);
  final logger = ref.read(productionLoggerProvider);
  
  return JsonRpcIntegrationService(
    communicationService,
    debugService,
    protocolHandler,
    logger,
  );
});