import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../production_logger.dart';

/// Enhanced structured logger specifically for terminal and MCP operations
class StructuredLogger {
  static StructuredLogger? _instance;
  static StructuredLogger get instance => _instance ??= StructuredLogger._();
  
  StructuredLogger._();

  final ProductionLogger _baseLogger = ProductionLogger.instance;
  final Map<String, List<LogEntry>> _categorizedLogs = {};
  final StreamController<LogEntry> _logStreamController = StreamController.broadcast();
  
  /// Stream of all log entries for real-time monitoring
  Stream<LogEntry> get logStream => _logStreamController.stream;

  /// Log terminal operation with structured data
  void logTerminalOperation({
    required String agentId,
    required String operation,
    required bool success,
    String? command,
    int? exitCode,
    String? output,
    String? error,
    Duration? duration,
    Map<String, dynamic>? metadata,
  }) {
    final data = <String, dynamic>{
      'agent_id': agentId,
      'operation': operation,
      'success': success,
      if (command != null) 'command': command,
      if (exitCode != null) 'exit_code': exitCode,
      if (output != null) 'output': _truncateOutput(output),
      if (error != null) 'error': _truncateOutput(error),
      if (duration != null) 'duration_ms': duration.inMilliseconds,
      'timestamp': DateTime.now().toIso8601String(),
      ...?metadata,
    };

    final level = success ? LogLevel.info : LogLevel.error;
    final message = 'Terminal $operation: $agentId${command != null ? ' - $command' : ''}';
    
    _logWithCategory('terminal', level, message, data);
  }

  /// Log MCP server operation with structured data
  void logMCPOperation({
    required String agentId,
    required String serverId,
    required String operation,
    required bool success,
    String? method,
    Map<String, dynamic>? request,
    Map<String, dynamic>? response,
    String? error,
    Duration? duration,
    Map<String, dynamic>? metadata,
  }) {
    final data = <String, dynamic>{
      'agent_id': agentId,
      'server_id': serverId,
      'operation': operation,
      'success': success,
      if (method != null) 'method': method,
      if (request != null) 'request': _sanitizeData(request),
      if (response != null) 'response': _sanitizeData(response),
      if (error != null) 'error': error,
      if (duration != null) 'duration_ms': duration.inMilliseconds,
      'timestamp': DateTime.now().toIso8601String(),
      ...?metadata,
    };

    final level = success ? LogLevel.info : LogLevel.error;
    final message = 'MCP $operation: $serverId${method != null ? ' - $method' : ''}';
    
    _logWithCategory('mcp', level, message, data);
  }

  /// Log security event with structured data
  void logSecurityEvent({
    required String agentId,
    required String event,
    required String severity,
    String? command,
    String? resource,
    String? reason,
    bool blocked = false,
    Map<String, dynamic>? metadata,
  }) {
    final data = <String, dynamic>{
      'agent_id': agentId,
      'event': event,
      'severity': severity,
      'blocked': blocked,
      if (command != null) 'command': command,
      if (resource != null) 'resource': resource,
      if (reason != null) 'reason': reason,
      'timestamp': DateTime.now().toIso8601String(),
      ...?metadata,
    };

    final level = _parseSecurityLevel(severity);
    final message = 'Security $event: $agentId${blocked ? ' (BLOCKED)' : ''}';
    
    _logWithCategory('security', level, message, data);
  }

  /// Log performance metrics with structured data
  void logPerformanceMetrics({
    required String component,
    required String operation,
    required Duration duration,
    String? agentId,
    String? serverId,
    int? memoryUsageMB,
    double? cpuUsagePercent,
    int? processCount,
    Map<String, dynamic>? metrics,
  }) {
    final data = <String, dynamic>{
      'component': component,
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      if (agentId != null) 'agent_id': agentId,
      if (serverId != null) 'server_id': serverId,
      if (memoryUsageMB != null) 'memory_usage_mb': memoryUsageMB,
      if (cpuUsagePercent != null) 'cpu_usage_percent': cpuUsagePercent,
      if (processCount != null) 'process_count': processCount,
      'timestamp': DateTime.now().toIso8601String(),
      ...?metrics,
    };

    final message = 'Performance $component.$operation: ${duration.inMilliseconds}ms';
    
    _logWithCategory('performance', LogLevel.info, message, data);
  }

  /// Log system resource usage
  void logResourceUsage({
    required String component,
    required int memoryUsageMB,
    required double cpuUsagePercent,
    int? processCount,
    int? threadCount,
    int? fileHandleCount,
    String? agentId,
    Map<String, dynamic>? metadata,
  }) {
    final data = <String, dynamic>{
      'component': component,
      'memory_usage_mb': memoryUsageMB,
      'cpu_usage_percent': cpuUsagePercent,
      if (processCount != null) 'process_count': processCount,
      if (threadCount != null) 'thread_count': threadCount,
      if (fileHandleCount != null) 'file_handle_count': fileHandleCount,
      if (agentId != null) 'agent_id': agentId,
      'timestamp': DateTime.now().toIso8601String(),
      ...?metadata,
    };

    final message = 'Resource Usage $component: ${memoryUsageMB}MB, ${cpuUsagePercent.toStringAsFixed(1)}%';
    
    _logWithCategory('resource', LogLevel.info, message, data);
  }

  /// Log error with context and stack trace
  void logError({
    required String component,
    required String error,
    String? agentId,
    String? serverId,
    String? operation,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    final data = <String, dynamic>{
      'component': component,
      'error': error,
      if (agentId != null) 'agent_id': agentId,
      if (serverId != null) 'server_id': serverId,
      if (operation != null) 'operation': operation,
      'timestamp': DateTime.now().toIso8601String(),
      ...?context,
    };

    final message = 'Error in $component${operation != null ? '.$operation' : ''}: $error';
    
    _logWithCategory('error', LogLevel.error, message, data, stackTrace);
  }

  /// Core logging method with categorization
  void _logWithCategory(
    String category,
    LogLevel level,
    String message,
    Map<String, dynamic> data, [
    StackTrace? stackTrace,
  ]) {
    final entry = LogEntry(
      level: level,
      message: message,
      data: data,
      category: category,
      timestamp: DateTime.now(),
      stackTrace: stackTrace != null ? Trace.from(stackTrace) : null,
    );

    // Store in categorized logs for search
    _categorizedLogs.putIfAbsent(category, () => []).add(entry);
    
    // Emit to stream for real-time monitoring
    _logStreamController.add(entry);

    // Log using base logger
    _baseLogger._log(level, message, data, category, stackTrace);
  }

  /// Search logs by criteria
  List<LogEntry> searchLogs({
    String? category,
    LogLevel? minLevel,
    String? agentId,
    String? serverId,
    String? textQuery,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 100,
  }) {
    List<LogEntry> results = [];

    // Get logs from specified category or all categories
    if (category != null) {
      results = _categorizedLogs[category] ?? [];
    } else {
      results = _categorizedLogs.values.expand((logs) => logs).toList();
    }

    // Apply filters
    results = results.where((entry) {
      // Level filter
      if (minLevel != null && entry.level.index < minLevel.index) {
        return false;
      }

      // Date range filter
      if (fromDate != null && entry.timestamp.isBefore(fromDate)) {
        return false;
      }
      if (toDate != null && entry.timestamp.isAfter(toDate)) {
        return false;
      }

      // Agent ID filter
      if (agentId != null && entry.data?['agent_id'] != agentId) {
        return false;
      }

      // Server ID filter
      if (serverId != null && entry.data?['server_id'] != serverId) {
        return false;
      }

      // Text query filter
      if (textQuery != null) {
        final query = textQuery.toLowerCase();
        final messageMatch = entry.message.toLowerCase().contains(query);
        final dataMatch = entry.data?.toString().toLowerCase().contains(query) ?? false;
        if (!messageMatch && !dataMatch) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort by timestamp (newest first) and limit
    results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return results.take(limit).toList();
  }

  /// Get log statistics
  Map<String, dynamic> getLogStatistics({
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    final stats = <String, dynamic>{
      'total_logs': 0,
      'by_category': <String, int>{},
      'by_level': <String, int>{},
      'error_rate': 0.0,
      'time_range': {
        'from': fromDate?.toIso8601String(),
        'to': toDate?.toIso8601String(),
      },
    };

    int totalLogs = 0;
    int errorLogs = 0;

    for (final category in _categorizedLogs.keys) {
      final categoryLogs = _categorizedLogs[category]!.where((entry) {
        if (fromDate != null && entry.timestamp.isBefore(fromDate)) return false;
        if (toDate != null && entry.timestamp.isAfter(toDate)) return false;
        return true;
      }).toList();

      stats['by_category'][category] = categoryLogs.length;
      totalLogs += categoryLogs.length;

      for (final entry in categoryLogs) {
        final levelName = entry.level.name;
        stats['by_level'][levelName] = (stats['by_level'][levelName] ?? 0) + 1;
        
        if (entry.level == LogLevel.error) {
          errorLogs++;
        }
      }
    }

    stats['total_logs'] = totalLogs;
    stats['error_rate'] = totalLogs > 0 ? (errorLogs / totalLogs) * 100 : 0.0;

    return stats;
  }

  /// Export logs to structured format
  Future<File> exportStructuredLogs({
    String? category,
    LogLevel? minLevel,
    DateTime? fromDate,
    DateTime? toDate,
    String format = 'json',
  }) async {
    final logs = searchLogs(
      category: category,
      minLevel: minLevel,
      fromDate: fromDate,
      toDate: toDate,
      limit: 10000,
    );

    final exportData = {
      'export_info': {
        'timestamp': DateTime.now().toIso8601String(),
        'format': format,
        'filters': {
          'category': category,
          'min_level': minLevel?.name,
          'from_date': fromDate?.toIso8601String(),
          'to_date': toDate?.toIso8601String(),
        },
        'total_entries': logs.length,
      },
      'logs': logs.map((entry) => {
        'timestamp': entry.timestamp.toIso8601String(),
        'level': entry.level.name,
        'category': entry.category,
        'message': entry.message,
        'data': entry.data,
        if (entry.stackTrace != null) 'stack_trace': entry.stackTrace.toString(),
      }).toList(),
    };

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = 'structured_logs_${category ?? 'all'}_$timestamp.$format';
    final exportFile = File(path.join(await _getExportDirectory(), filename));

    if (format == 'json') {
      await exportFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(exportData),
      );
    } else if (format == 'csv') {
      await _exportToCsv(exportFile, logs);
    }

    return exportFile;
  }

  /// Export logs to CSV format
  Future<void> _exportToCsv(File file, List<LogEntry> logs) async {
    final buffer = StringBuffer();
    
    // CSV header
    buffer.writeln('timestamp,level,category,message,agent_id,server_id,operation,success,duration_ms');
    
    // CSV rows
    for (final entry in logs) {
      final data = entry.data ?? {};
      buffer.writeln([
        entry.timestamp.toIso8601String(),
        entry.level.name,
        entry.category ?? '',
        _escapeCsvField(entry.message),
        data['agent_id'] ?? '',
        data['server_id'] ?? '',
        data['operation'] ?? '',
        data['success'] ?? '',
        data['duration_ms'] ?? '',
      ].join(','));
    }
    
    await file.writeAsString(buffer.toString());
  }

  /// Clean up old logs based on retention policy
  Future<void> cleanupOldLogs({
    Duration retentionPeriod = const Duration(days: 30),
    int maxEntriesPerCategory = 10000,
  }) async {
    final cutoffDate = DateTime.now().subtract(retentionPeriod);
    
    for (final category in _categorizedLogs.keys) {
      final logs = _categorizedLogs[category]!;
      
      // Remove logs older than retention period
      logs.removeWhere((entry) => entry.timestamp.isBefore(cutoffDate));
      
      // Limit entries per category
      if (logs.length > maxEntriesPerCategory) {
        logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _categorizedLogs[category] = logs.take(maxEntriesPerCategory).toList();
      }
    }
  }

  /// Helper methods
  String _truncateOutput(String output, {int maxLength = 1000}) {
    if (output.length <= maxLength) return output;
    return '${output.substring(0, maxLength)}... [truncated]';
  }

  Map<String, dynamic> _sanitizeData(Map<String, dynamic> data) {
    // Remove sensitive information from logged data
    final sanitized = Map<String, dynamic>.from(data);
    const sensitiveKeys = ['password', 'token', 'key', 'secret', 'credential'];
    
    for (final key in sanitized.keys.toList()) {
      if (sensitiveKeys.any((sensitive) => key.toLowerCase().contains(sensitive))) {
        sanitized[key] = '[REDACTED]';
      }
    }
    
    return sanitized;
  }

  LogLevel _parseSecurityLevel(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
      case 'high':
        return LogLevel.error;
      case 'medium':
        return LogLevel.warning;
      case 'low':
      case 'info':
        return LogLevel.info;
      default:
        return LogLevel.info;
    }
  }

  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  Future<String> _getExportDirectory() async {
    if (Platform.isWindows) {
      final appData = Platform.environment['LOCALAPPDATA'] ?? Platform.environment['APPDATA'];
      return path.join(appData!, 'Asmbli', 'exports');
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME']!;
      return path.join(home, 'Library', 'Application Support', 'Asmbli', 'exports');
    } else {
      final home = Platform.environment['HOME']!;
      return path.join(home, '.local', 'share', 'asmbli', 'exports');
    }
  }

  /// Dispose resources
  void dispose() {
    _logStreamController.close();
    _categorizedLogs.clear();
  }
}

/// Log level enumeration
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Log entry with structured data
class LogEntry {
  final LogLevel level;
  final String message;
  final Map<String, dynamic>? data;
  final String? category;
  final DateTime timestamp;
  final Trace? stackTrace;

  const LogEntry({
    required this.level,
    required this.message,
    this.data,
    this.category,
    required this.timestamp,
    this.stackTrace,
  });
}

/// Trace class placeholder (would use stack_trace package)
class Trace {
  final StackTrace _stackTrace;
  
  Trace._(this._stackTrace);
  
  static Trace from(StackTrace stackTrace) => Trace._(stackTrace);
  
  @override
  String toString() => _stackTrace.toString();
  
  String get terse => _stackTrace.toString().split('\n').take(5).join('\n');
}

// ==================== Riverpod Provider ====================

final structuredLoggerProvider = Provider<StructuredLogger>((ref) {
  return StructuredLogger.instance;
});