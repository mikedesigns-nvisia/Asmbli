import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'structured_logger.dart';

/// Service for aggregating logs from multiple sources and providing search capabilities
class LogAggregationService {
  static LogAggregationService? _instance;
  static LogAggregationService get instance => _instance ??= LogAggregationService._();
  
  LogAggregationService._();

  final StructuredLogger _logger = StructuredLogger.instance;
  final Map<String, LogSource> _logSources = {};
  final StreamController<AggregatedLogEntry> _aggregatedLogController = StreamController.broadcast();
  final List<AggregatedLogEntry> _aggregatedLogs = [];
  
  Timer? _aggregationTimer;
  bool _initialized = false;

  /// Stream of aggregated log entries
  Stream<AggregatedLogEntry> get aggregatedLogStream => _aggregatedLogController.stream;

  /// Initialize the log aggregation service
  Future<void> initialize() async {
    if (_initialized) return;

    // Register default log sources
    await _registerDefaultLogSources();
    
    // Start periodic aggregation
    _aggregationTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _aggregateLogs(),
    );
    
    _initialized = true;
    _logger.logTerminalOperation(
      agentId: 'system',
      operation: 'log_aggregation_init',
      success: true,
      metadata: {'sources': _logSources.keys.toList()},
    );
  }

  /// Register a log source for aggregation
  void registerLogSource(LogSource source) {
    _logSources[source.id] = source;
    _logger.logTerminalOperation(
      agentId: 'system',
      operation: 'register_log_source',
      success: true,
      metadata: {'source_id': source.id, 'source_type': source.type},
    );
  }

  /// Unregister a log source
  void unregisterLogSource(String sourceId) {
    _logSources.remove(sourceId);
    _logger.logTerminalOperation(
      agentId: 'system',
      operation: 'unregister_log_source',
      success: true,
      metadata: {'source_id': sourceId},
    );
  }

  /// Search aggregated logs with advanced filtering
  Future<LogSearchResult> searchLogs({
    String? query,
    List<String>? categories,
    List<LogLevel>? levels,
    List<String>? agentIds,
    List<String>? serverIds,
    DateTime? fromDate,
    DateTime? toDate,
    int offset = 0,
    int limit = 100,
    String sortBy = 'timestamp',
    bool sortDescending = true,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Ensure logs are aggregated
      await _aggregateLogs();

      // Apply filters
      var filteredLogs = _aggregatedLogs.where((entry) {
        // Text query filter
        if (query != null && query.isNotEmpty) {
          final queryLower = query.toLowerCase();
          final messageMatch = entry.message.toLowerCase().contains(queryLower);
          final dataMatch = entry.data.toString().toLowerCase().contains(queryLower);
          if (!messageMatch && !dataMatch) return false;
        }

        // Category filter
        if (categories != null && categories.isNotEmpty) {
          if (!categories.contains(entry.category)) return false;
        }

        // Level filter
        if (levels != null && levels.isNotEmpty) {
          if (!levels.contains(entry.level)) return false;
        }

        // Agent ID filter
        if (agentIds != null && agentIds.isNotEmpty) {
          final entryAgentId = entry.data['agent_id'] as String?;
          if (entryAgentId == null || !agentIds.contains(entryAgentId)) return false;
        }

        // Server ID filter
        if (serverIds != null && serverIds.isNotEmpty) {
          final entryServerId = entry.data['server_id'] as String?;
          if (entryServerId == null || !serverIds.contains(entryServerId)) return false;
        }

        // Date range filter
        if (fromDate != null && entry.timestamp.isBefore(fromDate)) return false;
        if (toDate != null && entry.timestamp.isAfter(toDate)) return false;

        return true;
      }).toList();

      // Sort results
      filteredLogs.sort((a, b) {
        int comparison;
        switch (sortBy) {
          case 'level':
            comparison = a.level.index.compareTo(b.level.index);
            break;
          case 'category':
            comparison = (a.category ?? '').compareTo(b.category ?? '');
            break;
          case 'source':
            comparison = a.sourceId.compareTo(b.sourceId);
            break;
          case 'timestamp':
          default:
            comparison = a.timestamp.compareTo(b.timestamp);
            break;
        }
        return sortDescending ? -comparison : comparison;
      });

      // Apply pagination
      final totalCount = filteredLogs.length;
      final paginatedLogs = filteredLogs.skip(offset).take(limit).toList();

      stopwatch.stop();

      final result = LogSearchResult(
        logs: paginatedLogs,
        totalCount: totalCount,
        offset: offset,
        limit: limit,
        searchDuration: stopwatch.elapsed,
        query: query,
        filters: {
          'categories': categories,
          'levels': levels?.map((l) => l.name).toList(),
          'agent_ids': agentIds,
          'server_ids': serverIds,
          'from_date': fromDate?.toIso8601String(),
          'to_date': toDate?.toIso8601String(),
        },
      );

      _logger.logPerformanceMetrics(
        component: 'log_aggregation',
        operation: 'search',
        duration: stopwatch.elapsed,
        metrics: {
          'total_logs': _aggregatedLogs.length,
          'filtered_logs': totalCount,
          'returned_logs': paginatedLogs.length,
          'query': query,
        },
      );

      return result;
    } catch (e, stackTrace) {
      _logger.logError(
        component: 'log_aggregation',
        error: e.toString(),
        operation: 'search',
        stackTrace: stackTrace,
        context: {
          'query': query,
          'filters': {
            'categories': categories,
            'levels': levels?.map((l) => l.name).toList(),
          },
        },
      );
      rethrow;
    }
  }

  /// Get log analytics and statistics
  Future<LogAnalytics> getLogAnalytics({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    await _aggregateLogs();

    final relevantLogs = _aggregatedLogs.where((entry) {
      if (fromDate != null && entry.timestamp.isBefore(fromDate)) return false;
      if (toDate != null && entry.timestamp.isAfter(toDate)) return false;
      return true;
    }).toList();

    final analytics = LogAnalytics(
      totalLogs: relevantLogs.length,
      timeRange: LogTimeRange(
        from: fromDate ?? (relevantLogs.isNotEmpty ? relevantLogs.map((e) => e.timestamp).reduce((a, b) => a.isBefore(b) ? a : b) : DateTime.now()),
        to: toDate ?? (relevantLogs.isNotEmpty ? relevantLogs.map((e) => e.timestamp).reduce((a, b) => a.isAfter(b) ? a : b) : DateTime.now()),
      ),
      levelDistribution: _calculateLevelDistribution(relevantLogs),
      categoryDistribution: _calculateCategoryDistribution(relevantLogs),
      sourceDistribution: _calculateSourceDistribution(relevantLogs),
      agentDistribution: _calculateAgentDistribution(relevantLogs),
      errorRate: _calculateErrorRate(relevantLogs),
      topErrors: _getTopErrors(relevantLogs),
      performanceMetrics: _calculatePerformanceMetrics(relevantLogs),
    );

    return analytics;
  }

  /// Export aggregated logs to various formats
  Future<File> exportLogs({
    String format = 'json',
    String? query,
    List<String>? categories,
    List<LogLevel>? levels,
    DateTime? fromDate,
    DateTime? toDate,
    int maxEntries = 10000,
  }) async {
    final searchResult = await searchLogs(
      query: query,
      categories: categories,
      levels: levels,
      fromDate: fromDate,
      toDate: toDate,
      limit: maxEntries,
    );

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = 'aggregated_logs_$timestamp.$format';
    final exportFile = File(path.join(await _getExportDirectory(), filename));

    switch (format.toLowerCase()) {
      case 'json':
        await _exportToJson(exportFile, searchResult);
        break;
      case 'csv':
        await _exportToCsv(exportFile, searchResult);
        break;
      case 'txt':
        await _exportToText(exportFile, searchResult);
        break;
      default:
        throw ArgumentError('Unsupported export format: $format');
    }

    _logger.logTerminalOperation(
      agentId: 'system',
      operation: 'export_logs',
      success: true,
      metadata: {
        'format': format,
        'entries': searchResult.logs.length,
        'file': exportFile.path,
      },
    );

    return exportFile;
  }

  /// Clean up old aggregated logs
  Future<void> cleanupOldLogs({
    Duration retentionPeriod = const Duration(days: 30),
    int maxEntries = 100000,
  }) async {
    final cutoffDate = DateTime.now().subtract(retentionPeriod);
    final initialCount = _aggregatedLogs.length;

    // Remove old logs
    _aggregatedLogs.removeWhere((entry) => entry.timestamp.isBefore(cutoffDate));

    // Limit total entries
    if (_aggregatedLogs.length > maxEntries) {
      _aggregatedLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _aggregatedLogs.removeRange(maxEntries, _aggregatedLogs.length);
    }

    final removedCount = initialCount - _aggregatedLogs.length;

    _logger.logTerminalOperation(
      agentId: 'system',
      operation: 'cleanup_logs',
      success: true,
      metadata: {
        'initial_count': initialCount,
        'removed_count': removedCount,
        'remaining_count': _aggregatedLogs.length,
        'retention_days': retentionPeriod.inDays,
      },
    );
  }

  /// Register default log sources
  Future<void> _registerDefaultLogSources() async {
    // Terminal logs source
    registerLogSource(LogSource(
      id: 'terminal_logs',
      type: 'file',
      name: 'Terminal Logs',
      path: await _getTerminalLogsPath(),
      parser: _parseTerminalLog,
    ));

    // MCP logs source
    registerLogSource(LogSource(
      id: 'mcp_logs',
      type: 'file',
      name: 'MCP Server Logs',
      path: await _getMcpLogsPath(),
      parser: _parseMcpLog,
    ));

    // Application logs source
    registerLogSource(LogSource(
      id: 'app_logs',
      type: 'file',
      name: 'Application Logs',
      path: await _getAppLogsPath(),
      parser: _parseAppLog,
    ));

    // Security logs source
    registerLogSource(LogSource(
      id: 'security_logs',
      type: 'file',
      name: 'Security Logs',
      path: await _getSecurityLogsPath(),
      parser: _parseSecurityLog,
    ));
  }

  /// Aggregate logs from all sources
  Future<void> _aggregateLogs() async {
    for (final source in _logSources.values) {
      try {
        final newLogs = await _collectLogsFromSource(source);
        for (final log in newLogs) {
          _aggregatedLogs.add(log);
          _aggregatedLogController.add(log);
        }
      } catch (e) {
        _logger.logError(
          component: 'log_aggregation',
          error: e.toString(),
          operation: 'collect_from_source',
          context: {'source_id': source.id},
        );
      }
    }

    // Sort by timestamp
    _aggregatedLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Collect logs from a specific source
  Future<List<AggregatedLogEntry>> _collectLogsFromSource(LogSource source) async {
    final logs = <AggregatedLogEntry>[];

    if (source.type == 'file' && source.path != null) {
      final file = File(source.path!);
      if (await file.exists()) {
        final lines = await file.readAsLines();
        for (final line in lines) {
          try {
            final parsedLog = source.parser(line);
            if (parsedLog != null) {
              logs.add(AggregatedLogEntry(
                sourceId: source.id,
                sourceName: source.name,
                level: parsedLog.level,
                message: parsedLog.message,
                category: parsedLog.category,
                timestamp: parsedLog.timestamp,
                data: parsedLog.data,
              ));
            }
          } catch (e) {
            // Skip malformed log entries
          }
        }
      }
    }

    return logs;
  }

  /// Parse terminal log entry
  ParsedLogEntry? _parseTerminalLog(String line) {
    try {
      final json = jsonDecode(line) as Map<String, dynamic>;
      return ParsedLogEntry(
        level: _parseLogLevel(json['level'] as String),
        message: json['message'] as String,
        category: json['category'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
        data: json['data'] as Map<String, dynamic>? ?? {},
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse MCP log entry
  ParsedLogEntry? _parseMcpLog(String line) {
    try {
      final json = jsonDecode(line) as Map<String, dynamic>;
      return ParsedLogEntry(
        level: _parseLogLevel(json['level'] as String),
        message: json['message'] as String,
        category: 'mcp',
        timestamp: DateTime.parse(json['timestamp'] as String),
        data: json['data'] as Map<String, dynamic>? ?? {},
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse application log entry
  ParsedLogEntry? _parseAppLog(String line) {
    try {
      final json = jsonDecode(line) as Map<String, dynamic>;
      return ParsedLogEntry(
        level: _parseLogLevel(json['level'] as String),
        message: json['message'] as String,
        category: json['category'] as String? ?? 'app',
        timestamp: DateTime.parse(json['timestamp'] as String),
        data: json['data'] as Map<String, dynamic>? ?? {},
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse security log entry
  ParsedLogEntry? _parseSecurityLog(String line) {
    try {
      final json = jsonDecode(line) as Map<String, dynamic>;
      return ParsedLogEntry(
        level: _parseLogLevel(json['level'] as String),
        message: json['message'] as String,
        category: 'security',
        timestamp: DateTime.parse(json['timestamp'] as String),
        data: json['data'] as Map<String, dynamic>? ?? {},
      );
    } catch (e) {
      return null;
    }
  }

  /// Helper methods for analytics
  Map<String, int> _calculateLevelDistribution(List<AggregatedLogEntry> logs) {
    final distribution = <String, int>{};
    for (final log in logs) {
      distribution[log.level.name] = (distribution[log.level.name] ?? 0) + 1;
    }
    return distribution;
  }

  Map<String, int> _calculateCategoryDistribution(List<AggregatedLogEntry> logs) {
    final distribution = <String, int>{};
    for (final log in logs) {
      final category = log.category ?? 'unknown';
      distribution[category] = (distribution[category] ?? 0) + 1;
    }
    return distribution;
  }

  Map<String, int> _calculateSourceDistribution(List<AggregatedLogEntry> logs) {
    final distribution = <String, int>{};
    for (final log in logs) {
      distribution[log.sourceName] = (distribution[log.sourceName] ?? 0) + 1;
    }
    return distribution;
  }

  Map<String, int> _calculateAgentDistribution(List<AggregatedLogEntry> logs) {
    final distribution = <String, int>{};
    for (final log in logs) {
      final agentId = log.data['agent_id'] as String? ?? 'unknown';
      distribution[agentId] = (distribution[agentId] ?? 0) + 1;
    }
    return distribution;
  }

  double _calculateErrorRate(List<AggregatedLogEntry> logs) {
    if (logs.isEmpty) return 0.0;
    final errorCount = logs.where((log) => log.level == LogLevel.error).length;
    return (errorCount / logs.length) * 100;
  }

  List<String> _getTopErrors(List<AggregatedLogEntry> logs, {int limit = 10}) {
    final errorCounts = <String, int>{};
    
    for (final log in logs.where((l) => l.level == LogLevel.error)) {
      errorCounts[log.message] = (errorCounts[log.message] ?? 0) + 1;
    }

    final sortedErrors = errorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedErrors.take(limit).map((e) => '${e.key} (${e.value})').toList();
  }

  Map<String, dynamic> _calculatePerformanceMetrics(List<AggregatedLogEntry> logs) {
    final performanceLogs = logs.where((log) => 
      log.category == 'performance' && log.data['duration_ms'] != null
    ).toList();

    if (performanceLogs.isEmpty) {
      return {'avg_duration_ms': 0, 'max_duration_ms': 0, 'min_duration_ms': 0};
    }

    final durations = performanceLogs
        .map((log) => log.data['duration_ms'] as int)
        .toList();

    return {
      'avg_duration_ms': durations.reduce((a, b) => a + b) / durations.length,
      'max_duration_ms': durations.reduce((a, b) => a > b ? a : b),
      'min_duration_ms': durations.reduce((a, b) => a < b ? a : b),
      'total_operations': durations.length,
    };
  }

  /// Export methods
  Future<void> _exportToJson(File file, LogSearchResult result) async {
    final exportData = {
      'export_info': {
        'timestamp': DateTime.now().toIso8601String(),
        'total_count': result.totalCount,
        'exported_count': result.logs.length,
        'search_duration_ms': result.searchDuration.inMilliseconds,
        'query': result.query,
        'filters': result.filters,
      },
      'logs': result.logs.map((log) => {
        'timestamp': log.timestamp.toIso8601String(),
        'level': log.level.name,
        'category': log.category,
        'source': log.sourceName,
        'message': log.message,
        'data': log.data,
      }).toList(),
    };

    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(exportData));
  }

  Future<void> _exportToCsv(File file, LogSearchResult result) async {
    final buffer = StringBuffer();
    buffer.writeln('timestamp,level,category,source,agent_id,server_id,message');

    for (final log in result.logs) {
      buffer.writeln([
        log.timestamp.toIso8601String(),
        log.level.name,
        log.category ?? '',
        log.sourceName,
        log.data['agent_id'] ?? '',
        log.data['server_id'] ?? '',
        _escapeCsvField(log.message),
      ].join(','));
    }

    await file.writeAsString(buffer.toString());
  }

  Future<void> _exportToText(File file, LogSearchResult result) async {
    final buffer = StringBuffer();
    buffer.writeln('Log Export - ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total entries: ${result.totalCount}');
    buffer.writeln('Exported entries: ${result.logs.length}');
    buffer.writeln('Search duration: ${result.searchDuration.inMilliseconds}ms');
    buffer.writeln('=' * 80);

    for (final log in result.logs) {
      buffer.writeln('[${log.timestamp.toIso8601String()}] ${log.level.name.toUpperCase()} [${log.category ?? 'UNKNOWN'}] ${log.message}');
      if (log.data.isNotEmpty) {
        buffer.writeln('  Data: ${log.data}');
      }
      buffer.writeln();
    }

    await file.writeAsString(buffer.toString());
  }

  /// Helper methods
  LogLevel _parseLogLevel(String level) {
    switch (level.toLowerCase()) {
      case 'debug':
        return LogLevel.debug;
      case 'info':
        return LogLevel.info;
      case 'warning':
      case 'warn':
        return LogLevel.warning;
      case 'error':
        return LogLevel.error;
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

  Future<String> _getTerminalLogsPath() async => path.join(await _getLogsDirectory(), 'terminal');
  Future<String> _getMcpLogsPath() async => path.join(await _getLogsDirectory(), 'mcp');
  Future<String> _getAppLogsPath() async => path.join(await _getLogsDirectory(), 'app');
  Future<String> _getSecurityLogsPath() async => path.join(await _getLogsDirectory(), 'security');

  Future<String> _getLogsDirectory() async {
    if (Platform.isWindows) {
      final appData = Platform.environment['LOCALAPPDATA'] ?? Platform.environment['APPDATA'];
      return path.join(appData!, 'Asmbli', 'logs');
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME']!;
      return path.join(home, 'Library', 'Logs', 'Asmbli');
    } else {
      final home = Platform.environment['HOME']!;
      return path.join(home, '.local', 'share', 'asmbli', 'logs');
    }
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
    _aggregationTimer?.cancel();
    _aggregatedLogController.close();
    _aggregatedLogs.clear();
    _logSources.clear();
    _initialized = false;
  }
}

/// Data models
class LogSource {
  final String id;
  final String type;
  final String name;
  final String? path;
  final ParsedLogEntry? Function(String) parser;

  LogSource({
    required this.id,
    required this.type,
    required this.name,
    this.path,
    required this.parser,
  });
}

class ParsedLogEntry {
  final LogLevel level;
  final String message;
  final String? category;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  ParsedLogEntry({
    required this.level,
    required this.message,
    this.category,
    required this.timestamp,
    required this.data,
  });
}

class AggregatedLogEntry {
  final String sourceId;
  final String sourceName;
  final LogLevel level;
  final String message;
  final String? category;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  AggregatedLogEntry({
    required this.sourceId,
    required this.sourceName,
    required this.level,
    required this.message,
    this.category,
    required this.timestamp,
    required this.data,
  });
}

class LogSearchResult {
  final List<AggregatedLogEntry> logs;
  final int totalCount;
  final int offset;
  final int limit;
  final Duration searchDuration;
  final String? query;
  final Map<String, dynamic> filters;

  LogSearchResult({
    required this.logs,
    required this.totalCount,
    required this.offset,
    required this.limit,
    required this.searchDuration,
    this.query,
    required this.filters,
  });
}

class LogAnalytics {
  final int totalLogs;
  final LogTimeRange timeRange;
  final Map<String, int> levelDistribution;
  final Map<String, int> categoryDistribution;
  final Map<String, int> sourceDistribution;
  final Map<String, int> agentDistribution;
  final double errorRate;
  final List<String> topErrors;
  final Map<String, dynamic> performanceMetrics;

  LogAnalytics({
    required this.totalLogs,
    required this.timeRange,
    required this.levelDistribution,
    required this.categoryDistribution,
    required this.sourceDistribution,
    required this.agentDistribution,
    required this.errorRate,
    required this.topErrors,
    required this.performanceMetrics,
  });
}

class LogTimeRange {
  final DateTime from;
  final DateTime to;

  LogTimeRange({required this.from, required this.to});
}

// ==================== Riverpod Provider ====================

final logAggregationServiceProvider = Provider<LogAggregationService>((ref) {
  return LogAggregationService.instance;
});