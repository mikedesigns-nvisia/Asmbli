import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mcp_connection.dart';
import 'json_rpc_communication_service.dart';
import 'production_logger.dart';

/// Comprehensive debugging and monitoring service for JSON-RPC communications
/// Provides detailed logging, performance metrics, and troubleshooting tools
class JsonRpcDebugService {
  final JsonRpcCommunicationService _communicationService;
  final ProductionLogger _logger;
  
  // Debug configuration
  bool _debugEnabled = false;
  bool _verboseLogging = false;
  final Set<String> _debugConnections = {};
  
  // Performance tracking
  final Map<String, List<JsonRpcPerformanceMetric>> _performanceMetrics = {};
  final Map<String, JsonRpcConnectionHealth> _connectionHealth = {};
  
  // Error tracking
  final Map<String, List<JsonRpcErrorRecord>> _errorHistory = {};
  
  // Stream controllers for real-time monitoring
  final StreamController<JsonRpcDebugEvent> _debugEventController = StreamController<JsonRpcDebugEvent>.broadcast();
  final StreamController<JsonRpcPerformanceMetric> _performanceController = StreamController<JsonRpcPerformanceMetric>.broadcast();
  
  late final StreamSubscription _logSubscription;

  JsonRpcDebugService(this._communicationService, this._logger) {
    _setupLogMonitoring();
  }

  /// Stream of debug events for real-time monitoring
  Stream<JsonRpcDebugEvent> get debugEvents => _debugEventController.stream;
  
  /// Stream of performance metrics
  Stream<JsonRpcPerformanceMetric> get performanceMetrics => _performanceController.stream;

  /// Enable debug mode for all connections
  void enableDebug({bool verbose = false}) {
    _debugEnabled = true;
    _verboseLogging = verbose;
    _logger.info('JSON-RPC debug mode enabled (verbose: $verbose)');
  }

  /// Disable debug mode
  void disableDebug() {
    _debugEnabled = false;
    _verboseLogging = false;
    _debugConnections.clear();
    _logger.info('JSON-RPC debug mode disabled');
  }

  /// Enable debug for specific connection
  void enableConnectionDebug(String agentId, String serverId) {
    final connectionId = '$agentId:$serverId';
    _debugConnections.add(connectionId);
    _logger.info('Debug enabled for connection: $connectionId');
  }

  /// Disable debug for specific connection
  void disableConnectionDebug(String agentId, String serverId) {
    final connectionId = '$agentId:$serverId';
    _debugConnections.remove(connectionId);
    _logger.info('Debug disabled for connection: $connectionId');
  }

  /// Get detailed connection diagnostics
  JsonRpcConnectionDiagnostics getConnectionDiagnostics(String agentId, String serverId) {
    final connectionId = '$agentId:$serverId';
    final stats = _communicationService.getConnectionStats(agentId, serverId);
    final logs = _communicationService.getCommunicationLogs(agentId, serverId);
    final health = _connectionHealth[connectionId];
    final errors = _errorHistory[connectionId] ?? [];
    final performance = _performanceMetrics[connectionId] ?? [];
    
    return JsonRpcConnectionDiagnostics(
      connectionId: connectionId,
      stats: stats,
      health: health,
      recentLogs: logs.take(50).toList(),
      recentErrors: errors.take(20).toList(),
      performanceMetrics: performance.take(100).toList(),
      debugEnabled: _debugConnections.contains(connectionId) || _debugEnabled,
    );
  }

  /// Get system-wide JSON-RPC diagnostics
  JsonRpcSystemDiagnostics getSystemDiagnostics() {
    final allConnections = <String, JsonRpcConnectionStats>{};
    final allHealth = <String, JsonRpcConnectionHealth>{};
    final totalErrors = _errorHistory.values.fold<int>(0, (sum, errors) => sum + errors.length);
    final totalPerformanceMetrics = _performanceMetrics.values.fold<int>(0, (sum, metrics) => sum + metrics.length);
    
    // This would need to be enhanced to get all active connections
    // For now, we'll use the connections we have health data for
    for (final connectionId in _connectionHealth.keys) {
      final parts = connectionId.split(':');
      if (parts.length == 2) {
        final stats = _communicationService.getConnectionStats(parts[0], parts[1]);
        allConnections[connectionId] = stats;
        allHealth[connectionId] = _connectionHealth[connectionId]!;
      }
    }
    
    return JsonRpcSystemDiagnostics(
      totalConnections: allConnections.length,
      activeConnections: allConnections.values.where((s) => s.status == MCPConnectionStatus.connected).length,
      totalErrors: totalErrors,
      totalPerformanceMetrics: totalPerformanceMetrics,
      debugEnabled: _debugEnabled,
      verboseLogging: _verboseLogging,
      connectionStats: allConnections,
      connectionHealth: allHealth,
    );
  }

  /// Analyze connection performance and identify issues
  JsonRpcPerformanceAnalysis analyzePerformance(String agentId, String serverId) {
    final connectionId = '$agentId:$serverId';
    final metrics = _performanceMetrics[connectionId] ?? [];
    
    if (metrics.isEmpty) {
      return JsonRpcPerformanceAnalysis(
        connectionId: connectionId,
        hasData: false,
        issues: ['No performance data available'],
      );
    }
    
    // Calculate statistics
    final requestTimes = metrics.where((m) => m.type == JsonRpcMetricType.requestDuration).map((m) => m.value).toList();
    final avgRequestTime = requestTimes.isEmpty ? 0.0 : requestTimes.reduce((a, b) => a + b) / requestTimes.length;
    final maxRequestTime = requestTimes.isEmpty ? 0.0 : requestTimes.reduce((a, b) => a > b ? a : b);
    final minRequestTime = requestTimes.isEmpty ? 0.0 : requestTimes.reduce((a, b) => a < b ? a : b);
    
    // Identify issues
    final issues = <String>[];
    if (avgRequestTime > 5000) { // 5 seconds
      issues.add('High average request time: ${avgRequestTime.toStringAsFixed(2)}ms');
    }
    if (maxRequestTime > 30000) { // 30 seconds
      issues.add('Very slow requests detected: ${maxRequestTime.toStringAsFixed(2)}ms');
    }
    
    final errors = _errorHistory[connectionId] ?? [];
    final recentErrors = errors.where((e) => DateTime.now().difference(e.timestamp).inMinutes < 10).length;
    if (recentErrors > 5) {
      issues.add('High error rate: $recentErrors errors in last 10 minutes');
    }
    
    return JsonRpcPerformanceAnalysis(
      connectionId: connectionId,
      hasData: true,
      totalRequests: requestTimes.length,
      averageRequestTime: avgRequestTime,
      maxRequestTime: maxRequestTime,
      minRequestTime: minRequestTime,
      recentErrors: recentErrors,
      issues: issues,
    );
  }

  /// Export debug logs for external analysis
  Map<String, dynamic> exportDebugLogs({
    String? agentId,
    String? serverId,
    DateTime? since,
    int? maxEntries,
  }) {
    final export = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'debugEnabled': _debugEnabled,
      'verboseLogging': _verboseLogging,
      'connections': <String, dynamic>{},
    };
    
    // Filter connections
    final connectionsToExport = <String>[];
    if (agentId != null && serverId != null) {
      connectionsToExport.add('$agentId:$serverId');
    } else {
      connectionsToExport.addAll(_connectionHealth.keys);
    }
    
    for (final connectionId in connectionsToExport) {
      final parts = connectionId.split(':');
      if (parts.length != 2) continue;
      
      final logs = _communicationService.getCommunicationLogs(parts[0], parts[1]);
      final filteredLogs = logs.where((log) {
        if (since != null && log.timestamp.isBefore(since)) return false;
        return true;
      }).toList();
      
      if (maxEntries != null && filteredLogs.length > maxEntries) {
        filteredLogs.removeRange(0, filteredLogs.length - maxEntries);
      }
      
      export['connections'][connectionId] = {
        'logs': filteredLogs.map((log) => {
          'timestamp': log.timestamp.toIso8601String(),
          'type': log.type.name,
          'direction': log.direction.name,
          'message': log.message?.toJson(),
          'error': log.error,
        }).toList(),
        'stats': _communicationService.getConnectionStats(parts[0], parts[1]).toJson(),
        'health': _connectionHealth[connectionId]?.toJson(),
        'errors': (_errorHistory[connectionId] ?? []).map((e) => e.toJson()).toList(),
        'performance': (_performanceMetrics[connectionId] ?? []).map((m) => m.toJson()).toList(),
      };
    }
    
    return export;
  }

  /// Clear debug data for a connection
  void clearConnectionDebugData(String agentId, String serverId) {
    final connectionId = '$agentId:$serverId';
    _performanceMetrics.remove(connectionId);
    _connectionHealth.remove(connectionId);
    _errorHistory.remove(connectionId);
    _logger.info('Cleared debug data for connection: $connectionId');
  }

  /// Clear all debug data
  void clearAllDebugData() {
    _performanceMetrics.clear();
    _connectionHealth.clear();
    _errorHistory.clear();
    _logger.info('Cleared all JSON-RPC debug data');
  }

  /// Dispose service and cleanup resources
  Future<void> dispose() async {
    await _logSubscription.cancel();
    await _debugEventController.close();
    await _performanceController.close();
  }

  // Private methods

  void _setupLogMonitoring() {
    _logSubscription = _communicationService.logStream.listen(_handleLogEntry);
  }

  void _handleLogEntry(JsonRpcLogEntry entry) {
    final shouldDebug = _debugEnabled || _debugConnections.contains(entry.connectionId);
    
    if (shouldDebug) {
      _emitDebugEvent(JsonRpcDebugEvent(
        connectionId: entry.connectionId,
        type: JsonRpcDebugEventType.logEntry,
        data: entry,
        timestamp: entry.timestamp,
      ));
      
      if (_verboseLogging) {
        _logger.debug('JSON-RPC ${entry.direction.name} ${entry.type.name}: ${entry.connectionId}');
      }
    }
    
    // Track performance metrics
    _trackPerformanceMetric(entry);
    
    // Track errors
    if (entry.type == JsonRpcLogType.error) {
      _trackError(entry);
    }
    
    // Update connection health
    _updateConnectionHealth(entry);
  }

  void _trackPerformanceMetric(JsonRpcLogEntry entry) {
    final metrics = _performanceMetrics[entry.connectionId] ??= [];
    
    // Add metric based on entry type
    JsonRpcPerformanceMetric? metric;
    
    switch (entry.type) {
      case JsonRpcLogType.request:
        if (entry.direction == JsonRpcDirection.outgoing) {
          metric = JsonRpcPerformanceMetric(
            connectionId: entry.connectionId,
            type: JsonRpcMetricType.requestSent,
            value: 1,
            timestamp: entry.timestamp,
            metadata: {'method': entry.message?.method},
          );
        }
        break;
      case JsonRpcLogType.response:
        if (entry.direction == JsonRpcDirection.incoming) {
          metric = JsonRpcPerformanceMetric(
            connectionId: entry.connectionId,
            type: JsonRpcMetricType.responseReceived,
            value: 1,
            timestamp: entry.timestamp,
            metadata: {'id': entry.message?.id},
          );
        }
        break;
      case JsonRpcLogType.error:
        metric = JsonRpcPerformanceMetric(
          connectionId: entry.connectionId,
          type: JsonRpcMetricType.errorCount,
          value: 1,
          timestamp: entry.timestamp,
          metadata: {'error': entry.error},
        );
        break;
      default:
        break;
    }
    
    if (metric != null) {
      metrics.add(metric);
      
      // Trim old metrics
      if (metrics.length > 1000) {
        metrics.removeRange(0, metrics.length - 1000);
      }
      
      _performanceController.add(metric);
    }
  }

  void _trackError(JsonRpcLogEntry entry) {
    final errors = _errorHistory[entry.connectionId] ??= [];
    
    final errorRecord = JsonRpcErrorRecord(
      connectionId: entry.connectionId,
      error: entry.error ?? 'Unknown error',
      message: entry.message,
      timestamp: entry.timestamp,
    );
    
    errors.add(errorRecord);
    
    // Trim old errors
    if (errors.length > 100) {
      errors.removeRange(0, errors.length - 100);
    }
    
    _emitDebugEvent(JsonRpcDebugEvent(
      connectionId: entry.connectionId,
      type: JsonRpcDebugEventType.error,
      data: errorRecord,
      timestamp: entry.timestamp,
    ));
  }

  void _updateConnectionHealth(JsonRpcLogEntry entry) {
    final health = _connectionHealth[entry.connectionId] ??= JsonRpcConnectionHealth(
      connectionId: entry.connectionId,
      lastActivity: entry.timestamp,
      totalMessages: 0,
      errorCount: 0,
      isHealthy: true,
    );
    
    final updatedHealth = health.copyWith(
      lastActivity: entry.timestamp,
      totalMessages: health.totalMessages + 1,
      errorCount: entry.type == JsonRpcLogType.error ? health.errorCount + 1 : health.errorCount,
      isHealthy: entry.type != JsonRpcLogType.error,
    );
    
    _connectionHealth[entry.connectionId] = updatedHealth;
  }

  void _emitDebugEvent(JsonRpcDebugEvent event) {
    _debugEventController.add(event);
  }
}

// Supporting classes

/// Connection diagnostics information
class JsonRpcConnectionDiagnostics {
  final String connectionId;
  final JsonRpcConnectionStats stats;
  final JsonRpcConnectionHealth? health;
  final List<JsonRpcLogEntry> recentLogs;
  final List<JsonRpcErrorRecord> recentErrors;
  final List<JsonRpcPerformanceMetric> performanceMetrics;
  final bool debugEnabled;

  JsonRpcConnectionDiagnostics({
    required this.connectionId,
    required this.stats,
    this.health,
    required this.recentLogs,
    required this.recentErrors,
    required this.performanceMetrics,
    required this.debugEnabled,
  });
}

/// System-wide diagnostics
class JsonRpcSystemDiagnostics {
  final int totalConnections;
  final int activeConnections;
  final int totalErrors;
  final int totalPerformanceMetrics;
  final bool debugEnabled;
  final bool verboseLogging;
  final Map<String, JsonRpcConnectionStats> connectionStats;
  final Map<String, JsonRpcConnectionHealth> connectionHealth;

  JsonRpcSystemDiagnostics({
    required this.totalConnections,
    required this.activeConnections,
    required this.totalErrors,
    required this.totalPerformanceMetrics,
    required this.debugEnabled,
    required this.verboseLogging,
    required this.connectionStats,
    required this.connectionHealth,
  });
}

/// Performance analysis results
class JsonRpcPerformanceAnalysis {
  final String connectionId;
  final bool hasData;
  final int totalRequests;
  final double averageRequestTime;
  final double maxRequestTime;
  final double minRequestTime;
  final int recentErrors;
  final List<String> issues;

  JsonRpcPerformanceAnalysis({
    required this.connectionId,
    required this.hasData,
    this.totalRequests = 0,
    this.averageRequestTime = 0.0,
    this.maxRequestTime = 0.0,
    this.minRequestTime = 0.0,
    this.recentErrors = 0,
    required this.issues,
  });
}

/// Connection health tracking
class JsonRpcConnectionHealth {
  final String connectionId;
  final DateTime lastActivity;
  final int totalMessages;
  final int errorCount;
  final bool isHealthy;

  JsonRpcConnectionHealth({
    required this.connectionId,
    required this.lastActivity,
    required this.totalMessages,
    required this.errorCount,
    required this.isHealthy,
  });

  JsonRpcConnectionHealth copyWith({
    DateTime? lastActivity,
    int? totalMessages,
    int? errorCount,
    bool? isHealthy,
  }) {
    return JsonRpcConnectionHealth(
      connectionId: connectionId,
      lastActivity: lastActivity ?? this.lastActivity,
      totalMessages: totalMessages ?? this.totalMessages,
      errorCount: errorCount ?? this.errorCount,
      isHealthy: isHealthy ?? this.isHealthy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'connectionId': connectionId,
      'lastActivity': lastActivity.toIso8601String(),
      'totalMessages': totalMessages,
      'errorCount': errorCount,
      'isHealthy': isHealthy,
    };
  }
}

/// Performance metric tracking
class JsonRpcPerformanceMetric {
  final String connectionId;
  final JsonRpcMetricType type;
  final double value;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  JsonRpcPerformanceMetric({
    required this.connectionId,
    required this.type,
    required this.value,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'connectionId': connectionId,
      'type': type.name,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Types of performance metrics
enum JsonRpcMetricType {
  requestSent,
  responseReceived,
  requestDuration,
  errorCount,
  connectionLatency,
}

/// Error record for tracking
class JsonRpcErrorRecord {
  final String connectionId;
  final String error;
  final MCPMessage? message;
  final DateTime timestamp;

  JsonRpcErrorRecord({
    required this.connectionId,
    required this.error,
    this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'connectionId': connectionId,
      'error': error,
      'message': message?.toJson(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Debug event for real-time monitoring
class JsonRpcDebugEvent {
  final String connectionId;
  final JsonRpcDebugEventType type;
  final dynamic data;
  final DateTime timestamp;

  JsonRpcDebugEvent({
    required this.connectionId,
    required this.type,
    required this.data,
    required this.timestamp,
  });
}

/// Types of debug events
enum JsonRpcDebugEventType {
  logEntry,
  error,
  performanceMetric,
  connectionStatusChange,
}

// Extension to add toJson to JsonRpcConnectionStats
extension JsonRpcConnectionStatsExtension on JsonRpcConnectionStats {
  Map<String, dynamic> toJson() {
    return {
      'connectionId': connectionId,
      'status': status.name,
      'totalMessages': totalMessages,
      'pendingRequests': pendingRequests,
      'requestsSent': requestsSent,
      'responsesReceived': responsesReceived,
      'notificationsSent': notificationsSent,
      'notificationsReceived': notificationsReceived,
      'errors': errors,
    };
  }
}

// ==================== Riverpod Provider ====================

final jsonRpcDebugServiceProvider = Provider<JsonRpcDebugService>((ref) {
  final communicationService = ref.read(jsonRpcCommunicationServiceProvider);
  final logger = ref.read(productionLoggerProvider);
  return JsonRpcDebugService(communicationService, logger);
});