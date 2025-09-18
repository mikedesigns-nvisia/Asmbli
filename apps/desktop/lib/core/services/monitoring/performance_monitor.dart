import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'structured_logger.dart';

/// Comprehensive performance monitoring service for terminals and MCP servers
class PerformanceMonitor {
  static PerformanceMonitor? _instance;
  static PerformanceMonitor get instance => _instance ??= PerformanceMonitor._();
  
  PerformanceMonitor._();

  final StructuredLogger _logger = StructuredLogger.instance;
  final Map<String, ComponentMetrics> _componentMetrics = {};
  final Map<String, PerformanceTimer> _activeTimers = {};
  final StreamController<PerformanceEvent> _metricsController = StreamController.broadcast();
  
  Timer? _monitoringTimer;
  Timer? _alertingTimer;
  bool _initialized = false;

  /// Stream of performance events
  Stream<PerformanceEvent> get metricsStream => _metricsController.stream;

  /// Performance thresholds for alerting
  final Map<String, PerformanceThresholds> _thresholds = {
    'terminal': PerformanceThresholds(
      maxMemoryMB: 100,
      maxCpuPercent: 50.0,
      maxResponseTimeMs: 5000,
      maxErrorRate: 5.0,
    ),
    'mcp_server': PerformanceThresholds(
      maxMemoryMB: 50,
      maxCpuPercent: 30.0,
      maxResponseTimeMs: 3000,
      maxErrorRate: 2.0,
    ),
    'system': PerformanceThresholds(
      maxMemoryMB: 500,
      maxCpuPercent: 80.0,
      maxResponseTimeMs: 1000,
      maxErrorRate: 1.0,
    ),
  };

  /// Initialize performance monitoring
  Future<void> initialize() async {
    if (_initialized) return;

    // Start periodic monitoring (every 30 seconds)
    _monitoringTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _collectSystemMetrics(),
    );

    // Start alerting checks (every 60 seconds)
    _alertingTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _checkPerformanceAlerts(),
    );

    _initialized = true;

    _logger.logPerformanceMetrics(
      component: 'performance_monitor',
      operation: 'initialize',
      duration: Duration.zero,
      metrics: {
        'monitoring_interval': 30,
        'alerting_interval': 60,
        'thresholds': _thresholds.keys.toList(),
      },
    );
  }

  /// Start timing an operation
  PerformanceTimer startTimer(String operationId, {
    String? component,
    String? agentId,
    String? serverId,
    Map<String, dynamic>? context,
  }) {
    final timer = PerformanceTimer(
      operationId: operationId,
      component: component ?? 'unknown',
      agentId: agentId,
      serverId: serverId,
      context: context ?? {},
      startTime: DateTime.now(),
    );

    _activeTimers[operationId] = timer;
    return timer;
  }

  /// Stop timing an operation and record metrics
  void stopTimer(String operationId, {
    bool success = true,
    String? error,
    Map<String, dynamic>? additionalMetrics,
  }) {
    final timer = _activeTimers.remove(operationId);
    if (timer == null) return;

    final duration = DateTime.now().difference(timer.startTime);
    
    // Record performance metrics
    _recordOperationMetrics(
      timer.component,
      timer.operationId,
      duration,
      success: success,
      error: error,
      agentId: timer.agentId,
      serverId: timer.serverId,
      context: {...timer.context, ...?additionalMetrics},
    );

    // Emit performance event
    _metricsController.add(PerformanceEvent(
      type: PerformanceEventType.operationCompleted,
      component: timer.component,
      operation: timer.operationId,
      duration: duration,
      success: success,
      agentId: timer.agentId,
      serverId: timer.serverId,
      timestamp: DateTime.now(),
      metrics: additionalMetrics ?? {},
    ));
  }

  /// Record resource usage for a component
  void recordResourceUsage({
    required String component,
    required int memoryUsageMB,
    required double cpuUsagePercent,
    String? agentId,
    String? serverId,
    int? processCount,
    int? threadCount,
    int? fileHandleCount,
    Map<String, dynamic>? additionalMetrics,
  }) {
    final metrics = ComponentMetrics(
      component: component,
      memoryUsageMB: memoryUsageMB,
      cpuUsagePercent: cpuUsagePercent,
      processCount: processCount ?? 0,
      threadCount: threadCount ?? 0,
      fileHandleCount: fileHandleCount ?? 0,
      timestamp: DateTime.now(),
      agentId: agentId,
      serverId: serverId,
      additionalMetrics: additionalMetrics ?? {},
    );

    _componentMetrics[_getMetricsKey(component, agentId, serverId)] = metrics;

    // Log resource usage
    _logger.logResourceUsage(
      component: component,
      memoryUsageMB: memoryUsageMB,
      cpuUsagePercent: cpuUsagePercent,
      processCount: processCount,
      threadCount: threadCount,
      fileHandleCount: fileHandleCount,
      agentId: agentId,
      metadata: additionalMetrics,
    );

    // Emit performance event
    _metricsController.add(PerformanceEvent(
      type: PerformanceEventType.resourceUsage,
      component: component,
      operation: 'resource_usage',
      duration: Duration.zero,
      success: true,
      agentId: agentId,
      serverId: serverId,
      timestamp: DateTime.now(),
      metrics: {
        'memory_mb': memoryUsageMB,
        'cpu_percent': cpuUsagePercent,
        'process_count': processCount,
        'thread_count': threadCount,
        'file_handle_count': fileHandleCount,
        ...?additionalMetrics,
      },
    ));
  }

  /// Record terminal operation metrics
  void recordTerminalMetrics({
    required String agentId,
    required String operation,
    required Duration duration,
    required bool success,
    String? command,
    int? exitCode,
    int? outputSizeBytes,
    String? error,
  }) {
    _recordOperationMetrics(
      'terminal',
      operation,
      duration,
      success: success,
      error: error,
      agentId: agentId,
      context: {
        'command': command,
        'exit_code': exitCode,
        'output_size_bytes': outputSizeBytes,
      },
    );
  }

  /// Record MCP server operation metrics
  void recordMCPMetrics({
    required String agentId,
    required String serverId,
    required String operation,
    required Duration duration,
    required bool success,
    String? method,
    int? requestSizeBytes,
    int? responseSizeBytes,
    String? error,
  }) {
    _recordOperationMetrics(
      'mcp_server',
      operation,
      duration,
      success: success,
      error: error,
      agentId: agentId,
      serverId: serverId,
      context: {
        'method': method,
        'request_size_bytes': requestSizeBytes,
        'response_size_bytes': responseSizeBytes,
      },
    );
  }

  /// Get performance statistics for a component
  PerformanceStats? getComponentStats(String component, {
    String? agentId,
    String? serverId,
    Duration? timeWindow,
  }) {
    final key = _getMetricsKey(component, agentId, serverId);
    final metrics = _componentMetrics[key];
    
    if (metrics == null) return null;

    // Calculate statistics from historical data
    final now = DateTime.now();
    final windowStart = timeWindow != null ? now.subtract(timeWindow) : null;

    // For now, return current metrics (would be enhanced with historical data)
    return PerformanceStats(
      component: component,
      agentId: agentId,
      serverId: serverId,
      currentMemoryMB: metrics.memoryUsageMB,
      currentCpuPercent: metrics.cpuUsagePercent,
      currentProcessCount: metrics.processCount,
      averageResponseTimeMs: 0, // Would calculate from historical data
      errorRate: 0.0, // Would calculate from historical data
      throughputPerSecond: 0.0, // Would calculate from historical data
      lastUpdated: metrics.timestamp,
      timeWindow: timeWindow,
    );
  }

  /// Get system-wide performance overview
  SystemPerformanceOverview getSystemOverview() {
    final terminalMetrics = _componentMetrics.entries
        .where((e) => e.value.component == 'terminal')
        .map((e) => e.value)
        .toList();

    final mcpMetrics = _componentMetrics.entries
        .where((e) => e.value.component == 'mcp_server')
        .map((e) => e.value)
        .toList();

    return SystemPerformanceOverview(
      totalAgents: terminalMetrics.length,
      totalMCPServers: mcpMetrics.length,
      totalMemoryUsageMB: _componentMetrics.values
          .map((m) => m.memoryUsageMB)
          .fold(0, (a, b) => a + b),
      averageCpuUsage: _componentMetrics.values.isNotEmpty
          ? _componentMetrics.values
              .map((m) => m.cpuUsagePercent)
              .reduce((a, b) => a + b) / _componentMetrics.values.length
          : 0.0,
      totalProcesses: _componentMetrics.values
          .map((m) => m.processCount)
          .fold(0, (a, b) => a + b),
      activeTimers: _activeTimers.length,
      timestamp: DateTime.now(),
    );
  }

  /// Set performance thresholds for alerting
  void setPerformanceThresholds(String component, PerformanceThresholds thresholds) {
    _thresholds[component] = thresholds;
    
    _logger.logTerminalOperation(
      agentId: 'system',
      operation: 'set_performance_thresholds',
      success: true,
      metadata: {
        'component': component,
        'max_memory_mb': thresholds.maxMemoryMB,
        'max_cpu_percent': thresholds.maxCpuPercent,
        'max_response_time_ms': thresholds.maxResponseTimeMs,
        'max_error_rate': thresholds.maxErrorRate,
      },
    );
  }

  /// Export performance data
  Future<Map<String, dynamic>> exportPerformanceData({
    DateTime? fromDate,
    DateTime? toDate,
    List<String>? components,
  }) async {
    final exportData = <String, dynamic>{
      'export_info': {
        'timestamp': DateTime.now().toIso8601String(),
        'from_date': fromDate?.toIso8601String(),
        'to_date': toDate?.toIso8601String(),
        'components': components,
      },
      'system_overview': getSystemOverview().toJson(),
      'component_metrics': {},
      'thresholds': {},
    };

    // Export component metrics
    for (final entry in _componentMetrics.entries) {
      final metrics = entry.value;
      if (components != null && !components.contains(metrics.component)) continue;
      
      if (fromDate != null && metrics.timestamp.isBefore(fromDate)) continue;
      if (toDate != null && metrics.timestamp.isAfter(toDate)) continue;

      exportData['component_metrics'][entry.key] = metrics.toJson();
    }

    // Export thresholds
    for (final entry in _thresholds.entries) {
      if (components != null && !components.contains(entry.key)) continue;
      exportData['thresholds'][entry.key] = entry.value.toJson();
    }

    return exportData;
  }

  /// Private methods
  void _recordOperationMetrics(
    String component,
    String operation,
    Duration duration, {
    required bool success,
    String? error,
    String? agentId,
    String? serverId,
    Map<String, dynamic>? context,
  }) {
    _logger.logPerformanceMetrics(
      component: component,
      operation: operation,
      duration: duration,
      agentId: agentId,
      serverId: serverId,
      metrics: {
        'success': success,
        if (error != null) 'error': error,
        ...?context,
      },
    );
  }

  String _getMetricsKey(String component, String? agentId, String? serverId) {
    final parts = [component];
    if (agentId != null) parts.add(agentId);
    if (serverId != null) parts.add(serverId);
    return parts.join(':');
  }

  /// Collect system-wide metrics
  Future<void> _collectSystemMetrics() async {
    try {
      // Get system memory info
      final memoryInfo = await _getSystemMemoryInfo();
      final cpuInfo = await _getSystemCpuInfo();

      recordResourceUsage(
        component: 'system',
        memoryUsageMB: memoryInfo['used_mb'] ?? 0,
        cpuUsagePercent: cpuInfo['usage_percent'] ?? 0.0,
        additionalMetrics: {
          'total_memory_mb': memoryInfo['total_mb'],
          'available_memory_mb': memoryInfo['available_mb'],
          'cpu_cores': cpuInfo['cores'],
        },
      );
    } catch (e) {
      _logger.logError(
        component: 'performance_monitor',
        error: 'Failed to collect system metrics',
        operation: 'collect_system_metrics',
        context: {'error': e.toString()},
      );
    }
  }

  /// Check for performance alerts
  Future<void> _checkPerformanceAlerts() async {
    for (final entry in _componentMetrics.entries) {
      final metrics = entry.value;
      final thresholds = _thresholds[metrics.component];
      
      if (thresholds == null) continue;

      final alerts = <String>[];

      // Check memory threshold
      if (metrics.memoryUsageMB > thresholds.maxMemoryMB) {
        alerts.add('Memory usage (${metrics.memoryUsageMB}MB) exceeds threshold (${thresholds.maxMemoryMB}MB)');
      }

      // Check CPU threshold
      if (metrics.cpuUsagePercent > thresholds.maxCpuPercent) {
        alerts.add('CPU usage (${metrics.cpuUsagePercent.toStringAsFixed(1)}%) exceeds threshold (${thresholds.maxCpuPercent}%)');
      }

      // Emit alerts
      for (final alert in alerts) {
        _metricsController.add(PerformanceEvent(
          type: PerformanceEventType.alert,
          component: metrics.component,
          operation: 'threshold_exceeded',
          duration: Duration.zero,
          success: false,
          agentId: metrics.agentId,
          serverId: metrics.serverId,
          timestamp: DateTime.now(),
          metrics: {
            'alert': alert,
            'memory_mb': metrics.memoryUsageMB,
            'cpu_percent': metrics.cpuUsagePercent,
          },
        ));

        _logger.logError(
          component: 'performance_monitor',
          error: alert,
          operation: 'performance_alert',
          agentId: metrics.agentId,
          serverId: metrics.serverId,
          context: {
            'component': metrics.component,
            'threshold_type': alert.contains('Memory') ? 'memory' : 'cpu',
          },
        );
      }
    }
  }

  /// Get system memory information
  Future<Map<String, dynamic>> _getSystemMemoryInfo() async {
    if (Platform.isLinux || Platform.isMacOS) {
      try {
        final result = await Process.run('free', ['-m']);
        final lines = result.stdout.toString().split('\n');
        if (lines.length > 1) {
          final memLine = lines[1].split(RegExp(r'\s+'));
          return {
            'total_mb': int.tryParse(memLine[1]) ?? 0,
            'used_mb': int.tryParse(memLine[2]) ?? 0,
            'available_mb': int.tryParse(memLine[6]) ?? 0,
          };
        }
      } catch (e) {
        // Fallback to basic info
      }
    }

    // Fallback values
    return {
      'total_mb': 8192,
      'used_mb': 4096,
      'available_mb': 4096,
    };
  }

  /// Get system CPU information
  Future<Map<String, dynamic>> _getCpuInfo() async {
    // This would be platform-specific implementation
    // For now, return mock data
    return {
      'cores': Platform.numberOfProcessors,
      'usage_percent': 25.0, // Would calculate actual usage
    };
  }

  Future<Map<String, dynamic>> _getSystemCpuInfo() async {
    return await _getCpuInfo();
  }

  /// Dispose resources
  void dispose() {
    _monitoringTimer?.cancel();
    _alertingTimer?.cancel();
    _metricsController.close();
    _componentMetrics.clear();
    _activeTimers.clear();
    _initialized = false;
  }
}

/// Data models
class PerformanceTimer {
  final String operationId;
  final String component;
  final String? agentId;
  final String? serverId;
  final Map<String, dynamic> context;
  final DateTime startTime;

  PerformanceTimer({
    required this.operationId,
    required this.component,
    this.agentId,
    this.serverId,
    required this.context,
    required this.startTime,
  });
}

class ComponentMetrics {
  final String component;
  final int memoryUsageMB;
  final double cpuUsagePercent;
  final int processCount;
  final int threadCount;
  final int fileHandleCount;
  final DateTime timestamp;
  final String? agentId;
  final String? serverId;
  final Map<String, dynamic> additionalMetrics;

  ComponentMetrics({
    required this.component,
    required this.memoryUsageMB,
    required this.cpuUsagePercent,
    required this.processCount,
    required this.threadCount,
    required this.fileHandleCount,
    required this.timestamp,
    this.agentId,
    this.serverId,
    required this.additionalMetrics,
  });

  Map<String, dynamic> toJson() {
    return {
      'component': component,
      'memory_usage_mb': memoryUsageMB,
      'cpu_usage_percent': cpuUsagePercent,
      'process_count': processCount,
      'thread_count': threadCount,
      'file_handle_count': fileHandleCount,
      'timestamp': timestamp.toIso8601String(),
      'agent_id': agentId,
      'server_id': serverId,
      'additional_metrics': additionalMetrics,
    };
  }
}

class PerformanceThresholds {
  final int maxMemoryMB;
  final double maxCpuPercent;
  final int maxResponseTimeMs;
  final double maxErrorRate;

  PerformanceThresholds({
    required this.maxMemoryMB,
    required this.maxCpuPercent,
    required this.maxResponseTimeMs,
    required this.maxErrorRate,
  });

  Map<String, dynamic> toJson() {
    return {
      'max_memory_mb': maxMemoryMB,
      'max_cpu_percent': maxCpuPercent,
      'max_response_time_ms': maxResponseTimeMs,
      'max_error_rate': maxErrorRate,
    };
  }
}

class PerformanceStats {
  final String component;
  final String? agentId;
  final String? serverId;
  final int currentMemoryMB;
  final double currentCpuPercent;
  final int currentProcessCount;
  final double averageResponseTimeMs;
  final double errorRate;
  final double throughputPerSecond;
  final DateTime lastUpdated;
  final Duration? timeWindow;

  PerformanceStats({
    required this.component,
    this.agentId,
    this.serverId,
    required this.currentMemoryMB,
    required this.currentCpuPercent,
    required this.currentProcessCount,
    required this.averageResponseTimeMs,
    required this.errorRate,
    required this.throughputPerSecond,
    required this.lastUpdated,
    this.timeWindow,
  });
}

class SystemPerformanceOverview {
  final int totalAgents;
  final int totalMCPServers;
  final int totalMemoryUsageMB;
  final double averageCpuUsage;
  final int totalProcesses;
  final int activeTimers;
  final DateTime timestamp;

  SystemPerformanceOverview({
    required this.totalAgents,
    required this.totalMCPServers,
    required this.totalMemoryUsageMB,
    required this.averageCpuUsage,
    required this.totalProcesses,
    required this.activeTimers,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'total_agents': totalAgents,
      'total_mcp_servers': totalMCPServers,
      'total_memory_usage_mb': totalMemoryUsageMB,
      'average_cpu_usage': averageCpuUsage,
      'total_processes': totalProcesses,
      'active_timers': activeTimers,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class PerformanceEvent {
  final PerformanceEventType type;
  final String component;
  final String operation;
  final Duration duration;
  final bool success;
  final String? agentId;
  final String? serverId;
  final DateTime timestamp;
  final Map<String, dynamic> metrics;

  PerformanceEvent({
    required this.type,
    required this.component,
    required this.operation,
    required this.duration,
    required this.success,
    this.agentId,
    this.serverId,
    required this.timestamp,
    required this.metrics,
  });
}

enum PerformanceEventType {
  operationCompleted,
  resourceUsage,
  alert,
  threshold,
}

// ==================== Riverpod Provider ====================

final performanceMonitorProvider = Provider<PerformanceMonitor>((ref) {
  return PerformanceMonitor.instance;
});