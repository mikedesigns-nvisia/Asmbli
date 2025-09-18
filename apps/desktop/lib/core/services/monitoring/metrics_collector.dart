import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'structured_logger.dart';
import 'performance_monitor.dart';

/// Service for collecting detailed metrics from system components
class MetricsCollector {
  static MetricsCollector? _instance;
  static MetricsCollector get instance => _instance ??= MetricsCollector._();
  
  MetricsCollector._();

  final StructuredLogger _logger = StructuredLogger.instance;
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor.instance;
  final Map<String, MetricsSeries> _metricsHistory = {};
  final StreamController<MetricsSnapshot> _snapshotController = StreamController.broadcast();
  
  Timer? _collectionTimer;
  bool _initialized = false;

  /// Stream of metrics snapshots
  Stream<MetricsSnapshot> get snapshotStream => _snapshotController.stream;

  /// Initialize metrics collection
  Future<void> initialize() async {
    if (_initialized) return;

    // Start periodic metrics collection (every 15 seconds)
    _collectionTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _collectAllMetrics(),
    );

    _initialized = true;

    _logger.logTerminalOperation(
      agentId: 'system',
      operation: 'metrics_collector_init',
      success: true,
      metadata: {'collection_interval': 15},
    );
  }

  /// Collect metrics for a specific agent terminal
  Future<AgentTerminalMetrics> collectAgentTerminalMetrics(String agentId) async {
    final stopwatch = Stopwatch()..start();

    try {
      final processMetrics = await _getProcessMetrics(agentId);
      final terminalMetrics = await _getTerminalSpecificMetrics(agentId);
      final resourceMetrics = await _getResourceMetrics(agentId);

      final metrics = AgentTerminalMetrics(
        agentId: agentId,
        timestamp: DateTime.now(),
        processId: processMetrics['pid'] as int?,
        memoryUsageMB: processMetrics['memory_mb'] as int? ?? 0,
        cpuUsagePercent: processMetrics['cpu_percent'] as double? ?? 0.0,
        commandsExecuted: terminalMetrics['commands_executed'] as int? ?? 0,
        activeProcesses: terminalMetrics['active_processes'] as int? ?? 0,
        outputSizeBytes: terminalMetrics['output_size_bytes'] as int? ?? 0,
        errorCount: terminalMetrics['error_count'] as int? ?? 0,
        averageResponseTimeMs: terminalMetrics['avg_response_time_ms'] as double? ?? 0.0,
        fileHandleCount: resourceMetrics['file_handles'] as int? ?? 0,
        networkConnections: resourceMetrics['network_connections'] as int? ?? 0,
        diskUsageMB: resourceMetrics['disk_usage_mb'] as int? ?? 0,
      );

      // Record in performance monitor
      _performanceMonitor.recordResourceUsage(
        component: 'terminal',
        memoryUsageMB: metrics.memoryUsageMB,
        cpuUsagePercent: metrics.cpuUsagePercent,
        agentId: agentId,
        processCount: metrics.activeProcesses,
        fileHandleCount: metrics.fileHandleCount,
        additionalMetrics: {
          'commands_executed': metrics.commandsExecuted,
          'output_size_bytes': metrics.outputSizeBytes,
          'error_count': metrics.errorCount,
          'avg_response_time_ms': metrics.averageResponseTimeMs,
        },
      );

      stopwatch.stop();
      return metrics;
    } catch (e, stackTrace) {
      _logger.logError(
        component: 'metrics_collector',
        error: e.toString(),
        operation: 'collect_agent_metrics',
        stackTrace: stackTrace,
        agentId: agentId,
      );
      rethrow;
    }
  }

  /// Collect metrics for a specific MCP server
  Future<MCPServerMetrics> collectMCPServerMetrics(String agentId, String serverId) async {
    final stopwatch = Stopwatch()..start();

    try {
      final processMetrics = await _getMCPProcessMetrics(serverId);
      final communicationMetrics = await _getMCPCommunicationMetrics(serverId);
      final performanceMetrics = await _getMCPPerformanceMetrics(serverId);

      final metrics = MCPServerMetrics(
        serverId: serverId,
        agentId: agentId,
        timestamp: DateTime.now(),
        processId: processMetrics['pid'] as int?,
        memoryUsageMB: processMetrics['memory_mb'] as int? ?? 0,
        cpuUsagePercent: processMetrics['cpu_percent'] as double? ?? 0.0,
        requestsHandled: communicationMetrics['requests_handled'] as int? ?? 0,
        responsesGenerated: communicationMetrics['responses_generated'] as int? ?? 0,
        errorCount: communicationMetrics['error_count'] as int? ?? 0,
        averageRequestSizeBytes: communicationMetrics['avg_request_size_bytes'] as double? ?? 0.0,
        averageResponseSizeBytes: communicationMetrics['avg_response_size_bytes'] as double? ?? 0.0,
        averageProcessingTimeMs: performanceMetrics['avg_processing_time_ms'] as double? ?? 0.0,
        connectionCount: communicationMetrics['connection_count'] as int? ?? 0,
        uptime: performanceMetrics['uptime_seconds'] as int? ?? 0,
        restartCount: performanceMetrics['restart_count'] as int? ?? 0,
      );

      // Record in performance monitor
      _performanceMonitor.recordResourceUsage(
        component: 'mcp_server',
        memoryUsageMB: metrics.memoryUsageMB,
        cpuUsagePercent: metrics.cpuUsagePercent,
        agentId: agentId,
        serverId: serverId,
        additionalMetrics: {
          'requests_handled': metrics.requestsHandled,
          'responses_generated': metrics.responsesGenerated,
          'error_count': metrics.errorCount,
          'avg_processing_time_ms': metrics.averageProcessingTimeMs,
          'uptime_seconds': metrics.uptime,
          'restart_count': metrics.restartCount,
        },
      );

      stopwatch.stop();
      return metrics;
    } catch (e, stackTrace) {
      _logger.logError(
        component: 'metrics_collector',
        error: e.toString(),
        operation: 'collect_mcp_metrics',
        stackTrace: stackTrace,
        agentId: agentId,
        serverId: serverId,
      );
      rethrow;
    }
  }

  /// Collect system-wide metrics
  Future<SystemMetrics> collectSystemMetrics() async {
    final stopwatch = Stopwatch()..start();

    try {
      final memoryInfo = await _getSystemMemoryInfo();
      final cpuInfo = await _getSystemCpuInfo();
      final diskInfo = await _getSystemDiskInfo();
      final networkInfo = await _getSystemNetworkInfo();
      final processInfo = await _getSystemProcessInfo();

      final metrics = SystemMetrics(
        timestamp: DateTime.now(),
        totalMemoryMB: memoryInfo['total_mb'] as int? ?? 0,
        usedMemoryMB: memoryInfo['used_mb'] as int? ?? 0,
        availableMemoryMB: memoryInfo['available_mb'] as int? ?? 0,
        cpuUsagePercent: cpuInfo['usage_percent'] as double? ?? 0.0,
        cpuCores: cpuInfo['cores'] as int? ?? 1,
        diskTotalGB: diskInfo['total_gb'] as int? ?? 0,
        diskUsedGB: diskInfo['used_gb'] as int? ?? 0,
        diskAvailableGB: diskInfo['available_gb'] as int? ?? 0,
        networkBytesReceived: networkInfo['bytes_received'] as int? ?? 0,
        networkBytesSent: networkInfo['bytes_sent'] as int? ?? 0,
        totalProcesses: processInfo['total_processes'] as int? ?? 0,
        activeAgents: processInfo['active_agents'] as int? ?? 0,
        activeMCPServers: processInfo['active_mcp_servers'] as int? ?? 0,
        systemLoadAverage: cpuInfo['load_average'] as double? ?? 0.0,
      );

      // Record in performance monitor
      _performanceMonitor.recordResourceUsage(
        component: 'system',
        memoryUsageMB: metrics.usedMemoryMB,
        cpuUsagePercent: metrics.cpuUsagePercent,
        processCount: metrics.totalProcesses,
        additionalMetrics: {
          'total_memory_mb': metrics.totalMemoryMB,
          'available_memory_mb': metrics.availableMemoryMB,
          'cpu_cores': metrics.cpuCores,
          'disk_total_gb': metrics.diskTotalGB,
          'disk_used_gb': metrics.diskUsedGB,
          'active_agents': metrics.activeAgents,
          'active_mcp_servers': metrics.activeMCPServers,
          'load_average': metrics.systemLoadAverage,
        },
      );

      stopwatch.stop();
      return metrics;
    } catch (e, stackTrace) {
      _logger.logError(
        component: 'metrics_collector',
        error: e.toString(),
        operation: 'collect_system_metrics',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get metrics history for a component
  List<MetricsDataPoint> getMetricsHistory(
    String component, {
    String? agentId,
    String? serverId,
    Duration? timeWindow,
    String metricName = 'memory_usage_mb',
  }) {
    final key = _getMetricsKey(component, agentId, serverId);
    final series = _metricsHistory[key];
    
    if (series == null) return [];

    final now = DateTime.now();
    final windowStart = timeWindow != null ? now.subtract(timeWindow) : null;

    return series.dataPoints
        .where((point) => windowStart == null || point.timestamp.isAfter(windowStart))
        .where((point) => point.metrics.containsKey(metricName))
        .toList();
  }

  /// Get aggregated metrics for multiple components
  Future<AggregatedMetrics> getAggregatedMetrics({
    List<String>? agentIds,
    List<String>? serverIds,
    Duration? timeWindow,
  }) async {
    final systemMetrics = await collectSystemMetrics();
    final agentMetricsList = <AgentTerminalMetrics>[];
    final mcpMetricsList = <MCPServerMetrics>[];

    // Collect agent metrics
    if (agentIds != null) {
      for (final agentId in agentIds) {
        try {
          final metrics = await collectAgentTerminalMetrics(agentId);
          agentMetricsList.add(metrics);
        } catch (e) {
          // Continue with other agents
        }
      }
    }

    // Collect MCP server metrics
    if (serverIds != null) {
      for (final serverId in serverIds) {
        // Would need agent ID mapping for this
        // For now, skip MCP metrics in aggregation
      }
    }

    return AggregatedMetrics(
      timestamp: DateTime.now(),
      systemMetrics: systemMetrics,
      agentMetrics: agentMetricsList,
      mcpMetrics: mcpMetricsList,
      totalMemoryUsageMB: systemMetrics.usedMemoryMB,
      averageCpuUsage: systemMetrics.cpuUsagePercent,
      totalProcesses: systemMetrics.totalProcesses,
      errorRate: _calculateErrorRate(agentMetricsList, mcpMetricsList),
      throughputPerSecond: _calculateThroughput(agentMetricsList, mcpMetricsList),
    );
  }

  /// Export metrics data
  Future<Map<String, dynamic>> exportMetrics({
    DateTime? fromDate,
    DateTime? toDate,
    List<String>? components,
    String format = 'json',
  }) async {
    final exportData = <String, dynamic>{
      'export_info': {
        'timestamp': DateTime.now().toIso8601String(),
        'from_date': fromDate?.toIso8601String(),
        'to_date': toDate?.toIso8601String(),
        'components': components,
        'format': format,
      },
      'metrics_history': {},
    };

    for (final entry in _metricsHistory.entries) {
      final series = entry.value;
      if (components != null && !components.contains(series.component)) continue;

      final filteredPoints = series.dataPoints.where((point) {
        if (fromDate != null && point.timestamp.isBefore(fromDate)) return false;
        if (toDate != null && point.timestamp.isAfter(toDate)) return false;
        return true;
      }).toList();

      exportData['metrics_history'][entry.key] = {
        'component': series.component,
        'agent_id': series.agentId,
        'server_id': series.serverId,
        'data_points': filteredPoints.map((point) => point.toJson()).toList(),
      };
    }

    return exportData;
  }

  /// Private methods for collecting specific metrics
  Future<Map<String, dynamic>> _getProcessMetrics(String agentId) async {
    // This would integrate with actual process monitoring
    // For now, return mock data
    return {
      'pid': 12345,
      'memory_mb': 45,
      'cpu_percent': 12.5,
    };
  }

  Future<Map<String, dynamic>> _getTerminalSpecificMetrics(String agentId) async {
    // This would integrate with terminal session tracking
    return {
      'commands_executed': 25,
      'active_processes': 3,
      'output_size_bytes': 1024000,
      'error_count': 2,
      'avg_response_time_ms': 150.0,
    };
  }

  Future<Map<String, dynamic>> _getResourceMetrics(String agentId) async {
    // This would integrate with system resource monitoring
    return {
      'file_handles': 15,
      'network_connections': 2,
      'disk_usage_mb': 100,
    };
  }

  Future<Map<String, dynamic>> _getMCPProcessMetrics(String serverId) async {
    // This would integrate with MCP process monitoring
    return {
      'pid': 23456,
      'memory_mb': 25,
      'cpu_percent': 8.0,
    };
  }

  Future<Map<String, dynamic>> _getMCPCommunicationMetrics(String serverId) async {
    // This would integrate with MCP communication tracking
    return {
      'requests_handled': 150,
      'responses_generated': 148,
      'error_count': 2,
      'avg_request_size_bytes': 512.0,
      'avg_response_size_bytes': 1024.0,
      'connection_count': 1,
    };
  }

  Future<Map<String, dynamic>> _getMCPPerformanceMetrics(String serverId) async {
    // This would integrate with MCP performance tracking
    return {
      'avg_processing_time_ms': 75.0,
      'uptime_seconds': 3600,
      'restart_count': 0,
    };
  }

  Future<Map<String, dynamic>> _getSystemMemoryInfo() async {
    if (Platform.isLinux || Platform.isMacOS) {
      try {
        final result = await Process.run('free', ['-m']);
        final lines = result.stdout.toString().split('\n');
        if (lines.length > 1) {
          final memLine = lines[1].split(RegExp(r'\s+'));
          return {
            'total_mb': int.tryParse(memLine[1]) ?? 8192,
            'used_mb': int.tryParse(memLine[2]) ?? 4096,
            'available_mb': int.tryParse(memLine[6]) ?? 4096,
          };
        }
      } catch (e) {
        // Fallback
      }
    }

    return {
      'total_mb': 8192,
      'used_mb': 4096,
      'available_mb': 4096,
    };
  }

  Future<Map<String, dynamic>> _getSystemCpuInfo() async {
    return {
      'cores': Platform.numberOfProcessors,
      'usage_percent': 25.0,
      'load_average': 1.5,
    };
  }

  Future<Map<String, dynamic>> _getSystemDiskInfo() async {
    if (Platform.isLinux || Platform.isMacOS) {
      try {
        final result = await Process.run('df', ['-h', '/']);
        final lines = result.stdout.toString().split('\n');
        if (lines.length > 1) {
          final diskLine = lines[1].split(RegExp(r'\s+'));
          return {
            'total_gb': _parseSize(diskLine[1]),
            'used_gb': _parseSize(diskLine[2]),
            'available_gb': _parseSize(diskLine[3]),
          };
        }
      } catch (e) {
        // Fallback
      }
    }

    return {
      'total_gb': 500,
      'used_gb': 250,
      'available_gb': 250,
    };
  }

  Future<Map<String, dynamic>> _getSystemNetworkInfo() async {
    // This would integrate with network monitoring
    return {
      'bytes_received': 1024000,
      'bytes_sent': 512000,
    };
  }

  Future<Map<String, dynamic>> _getSystemProcessInfo() async {
    // This would integrate with process monitoring
    return {
      'total_processes': 150,
      'active_agents': 5,
      'active_mcp_servers': 8,
    };
  }

  int _parseSize(String sizeStr) {
    final match = RegExp(r'(\d+(?:\.\d+)?)([KMGT]?)').firstMatch(sizeStr);
    if (match == null) return 0;

    final value = double.tryParse(match.group(1) ?? '0') ?? 0;
    final unit = match.group(2) ?? '';

    switch (unit) {
      case 'K':
        return (value / 1024).round();
      case 'M':
        return value.round();
      case 'G':
        return (value * 1024).round();
      case 'T':
        return (value * 1024 * 1024).round();
      default:
        return (value / (1024 * 1024)).round();
    }
  }

  /// Collect all metrics periodically
  Future<void> _collectAllMetrics() async {
    try {
      // Collect system metrics
      final systemMetrics = await collectSystemMetrics();
      _recordMetricsDataPoint('system', null, null, systemMetrics.toJson());

      // Emit snapshot
      _snapshotController.add(MetricsSnapshot(
        timestamp: DateTime.now(),
        systemMetrics: systemMetrics,
        agentMetrics: [],
        mcpMetrics: [],
      ));
    } catch (e) {
      _logger.logError(
        component: 'metrics_collector',
        error: 'Failed to collect periodic metrics',
        operation: 'collect_all_metrics',
        context: {'error': e.toString()},
      );
    }
  }

  void _recordMetricsDataPoint(
    String component,
    String? agentId,
    String? serverId,
    Map<String, dynamic> metrics,
  ) {
    final key = _getMetricsKey(component, agentId, serverId);
    final series = _metricsHistory.putIfAbsent(
      key,
      () => MetricsSeries(
        component: component,
        agentId: agentId,
        serverId: serverId,
        dataPoints: [],
      ),
    );

    series.dataPoints.add(MetricsDataPoint(
      timestamp: DateTime.now(),
      metrics: metrics,
    ));

    // Keep only last 1000 data points per series
    if (series.dataPoints.length > 1000) {
      series.dataPoints.removeRange(0, series.dataPoints.length - 1000);
    }
  }

  String _getMetricsKey(String component, String? agentId, String? serverId) {
    final parts = [component];
    if (agentId != null) parts.add(agentId);
    if (serverId != null) parts.add(serverId);
    return parts.join(':');
  }

  double _calculateErrorRate(
    List<AgentTerminalMetrics> agentMetrics,
    List<MCPServerMetrics> mcpMetrics,
  ) {
    int totalOperations = 0;
    int totalErrors = 0;

    for (final metrics in agentMetrics) {
      totalOperations += metrics.commandsExecuted;
      totalErrors += metrics.errorCount;
    }

    for (final metrics in mcpMetrics) {
      totalOperations += metrics.requestsHandled;
      totalErrors += metrics.errorCount;
    }

    return totalOperations > 0 ? (totalErrors / totalOperations) * 100 : 0.0;
  }

  double _calculateThroughput(
    List<AgentTerminalMetrics> agentMetrics,
    List<MCPServerMetrics> mcpMetrics,
  ) {
    int totalOperations = 0;

    for (final metrics in agentMetrics) {
      totalOperations += metrics.commandsExecuted;
    }

    for (final metrics in mcpMetrics) {
      totalOperations += metrics.requestsHandled;
    }

    // Assuming metrics are collected over 15-second intervals
    return totalOperations / 15.0;
  }

  /// Dispose resources
  void dispose() {
    _collectionTimer?.cancel();
    _snapshotController.close();
    _metricsHistory.clear();
    _initialized = false;
  }
}

/// Data models
class AgentTerminalMetrics {
  final String agentId;
  final DateTime timestamp;
  final int? processId;
  final int memoryUsageMB;
  final double cpuUsagePercent;
  final int commandsExecuted;
  final int activeProcesses;
  final int outputSizeBytes;
  final int errorCount;
  final double averageResponseTimeMs;
  final int fileHandleCount;
  final int networkConnections;
  final int diskUsageMB;

  AgentTerminalMetrics({
    required this.agentId,
    required this.timestamp,
    this.processId,
    required this.memoryUsageMB,
    required this.cpuUsagePercent,
    required this.commandsExecuted,
    required this.activeProcesses,
    required this.outputSizeBytes,
    required this.errorCount,
    required this.averageResponseTimeMs,
    required this.fileHandleCount,
    required this.networkConnections,
    required this.diskUsageMB,
  });

  Map<String, dynamic> toJson() {
    return {
      'agent_id': agentId,
      'timestamp': timestamp.toIso8601String(),
      'process_id': processId,
      'memory_usage_mb': memoryUsageMB,
      'cpu_usage_percent': cpuUsagePercent,
      'commands_executed': commandsExecuted,
      'active_processes': activeProcesses,
      'output_size_bytes': outputSizeBytes,
      'error_count': errorCount,
      'average_response_time_ms': averageResponseTimeMs,
      'file_handle_count': fileHandleCount,
      'network_connections': networkConnections,
      'disk_usage_mb': diskUsageMB,
    };
  }
}

class MCPServerMetrics {
  final String serverId;
  final String agentId;
  final DateTime timestamp;
  final int? processId;
  final int memoryUsageMB;
  final double cpuUsagePercent;
  final int requestsHandled;
  final int responsesGenerated;
  final int errorCount;
  final double averageRequestSizeBytes;
  final double averageResponseSizeBytes;
  final double averageProcessingTimeMs;
  final int connectionCount;
  final int uptime;
  final int restartCount;

  MCPServerMetrics({
    required this.serverId,
    required this.agentId,
    required this.timestamp,
    this.processId,
    required this.memoryUsageMB,
    required this.cpuUsagePercent,
    required this.requestsHandled,
    required this.responsesGenerated,
    required this.errorCount,
    required this.averageRequestSizeBytes,
    required this.averageResponseSizeBytes,
    required this.averageProcessingTimeMs,
    required this.connectionCount,
    required this.uptime,
    required this.restartCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'server_id': serverId,
      'agent_id': agentId,
      'timestamp': timestamp.toIso8601String(),
      'process_id': processId,
      'memory_usage_mb': memoryUsageMB,
      'cpu_usage_percent': cpuUsagePercent,
      'requests_handled': requestsHandled,
      'responses_generated': responsesGenerated,
      'error_count': errorCount,
      'average_request_size_bytes': averageRequestSizeBytes,
      'average_response_size_bytes': averageResponseSizeBytes,
      'average_processing_time_ms': averageProcessingTimeMs,
      'connection_count': connectionCount,
      'uptime': uptime,
      'restart_count': restartCount,
    };
  }
}

class SystemMetrics {
  final DateTime timestamp;
  final int totalMemoryMB;
  final int usedMemoryMB;
  final int availableMemoryMB;
  final double cpuUsagePercent;
  final int cpuCores;
  final int diskTotalGB;
  final int diskUsedGB;
  final int diskAvailableGB;
  final int networkBytesReceived;
  final int networkBytesSent;
  final int totalProcesses;
  final int activeAgents;
  final int activeMCPServers;
  final double systemLoadAverage;

  SystemMetrics({
    required this.timestamp,
    required this.totalMemoryMB,
    required this.usedMemoryMB,
    required this.availableMemoryMB,
    required this.cpuUsagePercent,
    required this.cpuCores,
    required this.diskTotalGB,
    required this.diskUsedGB,
    required this.diskAvailableGB,
    required this.networkBytesReceived,
    required this.networkBytesSent,
    required this.totalProcesses,
    required this.activeAgents,
    required this.activeMCPServers,
    required this.systemLoadAverage,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'total_memory_mb': totalMemoryMB,
      'used_memory_mb': usedMemoryMB,
      'available_memory_mb': availableMemoryMB,
      'cpu_usage_percent': cpuUsagePercent,
      'cpu_cores': cpuCores,
      'disk_total_gb': diskTotalGB,
      'disk_used_gb': diskUsedGB,
      'disk_available_gb': diskAvailableGB,
      'network_bytes_received': networkBytesReceived,
      'network_bytes_sent': networkBytesSent,
      'total_processes': totalProcesses,
      'active_agents': activeAgents,
      'active_mcp_servers': activeMCPServers,
      'system_load_average': systemLoadAverage,
    };
  }
}

class MetricsSeries {
  final String component;
  final String? agentId;
  final String? serverId;
  final List<MetricsDataPoint> dataPoints;

  MetricsSeries({
    required this.component,
    this.agentId,
    this.serverId,
    required this.dataPoints,
  });
}

class MetricsDataPoint {
  final DateTime timestamp;
  final Map<String, dynamic> metrics;

  MetricsDataPoint({
    required this.timestamp,
    required this.metrics,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'metrics': metrics,
    };
  }
}

class MetricsSnapshot {
  final DateTime timestamp;
  final SystemMetrics systemMetrics;
  final List<AgentTerminalMetrics> agentMetrics;
  final List<MCPServerMetrics> mcpMetrics;

  MetricsSnapshot({
    required this.timestamp,
    required this.systemMetrics,
    required this.agentMetrics,
    required this.mcpMetrics,
  });
}

class AggregatedMetrics {
  final DateTime timestamp;
  final SystemMetrics systemMetrics;
  final List<AgentTerminalMetrics> agentMetrics;
  final List<MCPServerMetrics> mcpMetrics;
  final int totalMemoryUsageMB;
  final double averageCpuUsage;
  final int totalProcesses;
  final double errorRate;
  final double throughputPerSecond;

  AggregatedMetrics({
    required this.timestamp,
    required this.systemMetrics,
    required this.agentMetrics,
    required this.mcpMetrics,
    required this.totalMemoryUsageMB,
    required this.averageCpuUsage,
    required this.totalProcesses,
    required this.errorRate,
    required this.throughputPerSecond,
  });
}

// ==================== Riverpod Provider ====================

final metricsCollectorProvider = Provider<MetricsCollector>((ref) {
  return MetricsCollector.instance;
});