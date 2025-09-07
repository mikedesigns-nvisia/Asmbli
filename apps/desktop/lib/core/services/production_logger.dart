import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:stack_trace/stack_trace.dart';
import '../config/environment_config.dart';

/// Production-grade logging service with file rotation, structured logging, and performance monitoring
class ProductionLogger {
  static ProductionLogger? _instance;
  static ProductionLogger get instance => _instance ??= ProductionLogger._();
  
  ProductionLogger._();

  late final LogLevel _currentLevel;
  late final bool _fileLoggingEnabled;
  late final bool _consoleLoggingEnabled;
  late final String? _logDirectory;
  late final int _maxFileSizeMB;
  late final int _maxFiles;
  
  File? _currentLogFile;
  IOSink? _logSink;
  final List<LogEntry> _logBuffer = [];
  Timer? _flushTimer;
  bool _initialized = false;
  
  static const int _bufferSize = 100;
  static const Duration _flushInterval = Duration(seconds: 5);

  /// Initialize logger with environment configuration
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final env = EnvironmentConfig.instance;
      final config = env.loggingConfig;
      
      // Parse configuration
      _currentLevel = _parseLogLevel(config['level'] as String? ?? 'info');
      _fileLoggingEnabled = config['file_enabled'] as bool? ?? true;
      _consoleLoggingEnabled = config['console_enabled'] as bool? ?? kDebugMode;
      _maxFileSizeMB = config['max_file_size_mb'] as int? ?? 10;
      _maxFiles = config['max_files'] as int? ?? 5;
      
      // Setup log directory
      if (_fileLoggingEnabled) {
        _logDirectory = config['file_path'] as String? ?? await _getDefaultLogDirectory();
        await _initializeFileLogging();
      }
      
      // Setup flush timer
      _flushTimer = Timer.periodic(_flushInterval, (_) => _flushLogs());
      
      _initialized = true;
      
      info('Logger initialized', data: {
        'level': _currentLevel.name,
        'file_logging': _fileLoggingEnabled,
        'console_logging': _consoleLoggingEnabled,
        'log_directory': _logDirectory,
      });
      
    } catch (e, stackTrace) {
      print('❌ Logger initialization failed: $e');
      print(stackTrace);
      // Continue with console-only logging
      _currentLevel = LogLevel.debug;
      _fileLoggingEnabled = false;
      _consoleLoggingEnabled = true;
      _initialized = true;
    }
  }

  /// Log debug message
  void debug(String message, {
    Map<String, dynamic>? data,
    String? category,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.debug, message, data, category, stackTrace);
  }

  /// Log info message
  void info(String message, {
    Map<String, dynamic>? data,
    String? category,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.info, message, data, category, stackTrace);
  }

  /// Log warning message
  void warning(String message, {
    Map<String, dynamic>? data,
    String? category,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.warning, message, data, category, stackTrace);
  }

  /// Log error message
  void error(String message, {
    dynamic error,
    Map<String, dynamic>? data,
    String? category,
    StackTrace? stackTrace,
  }) {
    final errorData = <String, dynamic>{
      ...?data,
      if (error != null) 'error': error.toString(),
    };
    _log(LogLevel.error, message, errorData, category, stackTrace);
  }

  /// Log performance metrics
  void performance(String operation, Duration duration, {
    Map<String, dynamic>? metrics,
    String? category,
  }) {
    final perfData = <String, dynamic>{
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      'duration_readable': _formatDuration(duration),
      ...?metrics,
    };
    
    _log(LogLevel.info, 'Performance: $operation', perfData, category ?? 'performance', null);
  }

  /// Log user action for analytics
  void userAction(String action, {
    Map<String, dynamic>? context,
    String? userId,
    String? sessionId,
  }) {
    final actionData = <String, dynamic>{
      'action': action,
      if (userId != null) 'user_id': userId,
      if (sessionId != null) 'session_id': sessionId,
      'timestamp': DateTime.now().toIso8601String(),
      ...?context,
    };
    
    _log(LogLevel.info, 'User Action: $action', actionData, 'user_action', null);
  }

  /// Log API request/response
  void apiCall(String method, String url, int statusCode, Duration duration, {
    Map<String, dynamic>? requestData,
    Map<String, dynamic>? responseData,
    String? error,
  }) {
    final apiData = <String, dynamic>{
      'method': method,
      'url': url,
      'status_code': statusCode,
      'duration_ms': duration.inMilliseconds,
      if (requestData != null) 'request': requestData,
      if (responseData != null) 'response': responseData,
      if (error != null) 'error': error,
    };
    
    final level = statusCode >= 400 ? LogLevel.error : LogLevel.info;
    _log(level, 'API Call: $method $url', apiData, 'api', null);
  }

  /// Log MCP server operation
  void mcpOperation(String serverId, String operation, {
    bool success = true,
    Duration? duration,
    Map<String, dynamic>? data,
    String? error,
  }) {
    final mcpData = <String, dynamic>{
      'server_id': serverId,
      'operation': operation,
      'success': success,
      if (duration != null) 'duration_ms': duration.inMilliseconds,
      if (error != null) 'error': error,
      ...?data,
    };
    
    final level = success ? LogLevel.info : LogLevel.error;
    _log(level, 'MCP $operation: $serverId', mcpData, 'mcp', null);
  }

  /// Core logging method
  void _log(LogLevel level, String message, Map<String, dynamic>? data, String? category, StackTrace? stackTrace) {
    if (!_initialized || !_shouldLog(level)) return;

    final entry = LogEntry(
      level: level,
      message: message,
      data: data,
      category: category,
      timestamp: DateTime.now(),
      stackTrace: stackTrace != null ? Trace.from(stackTrace) : null,
    );

    // Console logging
    if (_consoleLoggingEnabled) {
      _printToConsole(entry);
    }

    // File logging
    if (_fileLoggingEnabled) {
      _logBuffer.add(entry);
      
      // Immediate flush for errors
      if (level == LogLevel.error) {
        _flushLogs();
      }
    }
  }

  /// Check if message should be logged based on level
  bool _shouldLog(LogLevel level) {
    return level.index >= _currentLevel.index;
  }

  /// Print log entry to console with formatting
  void _printToConsole(LogEntry entry) {
    final levelIcon = _getLevelIcon(entry.level);
    final timestamp = entry.timestamp.toIso8601String().substring(11, 19);
    final category = entry.category != null ? '[${entry.category}] ' : '';
    
    print('$levelIcon $timestamp $category${entry.message}');
    
    if (entry.data != null && entry.data!.isNotEmpty) {
      final dataStr = const JsonEncoder.withIndent('  ').convert(entry.data);
      print('  Data: $dataStr');
    }
    
    if (entry.stackTrace != null) {
      print('  Stack: ${entry.stackTrace!.terse}');
    }
  }

  /// Get emoji icon for log level
  String _getLevelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🐛';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }

  /// Initialize file logging
  Future<void> _initializeFileLogging() async {
    if (_logDirectory == null) return;

    try {
      final logDir = Directory(_logDirectory!);
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      await _rotateLogFiles();
      await _openCurrentLogFile();
      
    } catch (e) {
      print('❌ File logging initialization failed: $e');
      _fileLoggingEnabled = false;
    }
  }

  /// Open current log file for writing
  Future<void> _openCurrentLogFile() async {
    try {
      final filename = 'asmbli_${DateTime.now().toIso8601String().substring(0, 10)}.log';
      _currentLogFile = File(path.join(_logDirectory!, filename));
      
      _logSink = _currentLogFile!.openWrite(mode: FileMode.append);
      
    } catch (e) {
      print('❌ Failed to open log file: $e');
      _fileLoggingEnabled = false;
    }
  }

  /// Rotate log files when they exceed size limit
  Future<void> _rotateLogFiles() async {
    try {
      final logDir = Directory(_logDirectory!);
      final logFiles = await logDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.log'))
          .cast<File>()
          .toList();

      // Sort by modification time (newest first)
      logFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      // Check current file size
      if (logFiles.isNotEmpty) {
        final currentFile = logFiles.first;
        final sizeBytes = await currentFile.length();
        final sizeMB = sizeBytes / (1024 * 1024);

        if (sizeMB > _maxFileSizeMB) {
          await _logSink?.close();
          _logSink = null;
        }
      }

      // Remove excess files
      if (logFiles.length > _maxFiles) {
        for (final file in logFiles.skip(_maxFiles)) {
          await file.delete();
        }
      }
      
    } catch (e) {
      print('❌ Log rotation failed: $e');
    }
  }

  /// Flush buffered logs to file
  void _flushLogs() {
    if (!_fileLoggingEnabled || _logSink == null || _logBuffer.isEmpty) return;

    try {
      for (final entry in _logBuffer) {
        final logLine = _formatLogEntry(entry);
        _logSink!.writeln(logLine);
      }
      
      _logBuffer.clear();
      
    } catch (e) {
      print('❌ Log flush failed: $e');
    }
  }

  /// Format log entry for file output
  String _formatLogEntry(LogEntry entry) {
    final jsonData = <String, dynamic>{
      'timestamp': entry.timestamp.toIso8601String(),
      'level': entry.level.name.toUpperCase(),
      'message': entry.message,
      if (entry.category != null) 'category': entry.category,
      if (entry.data != null) 'data': entry.data,
      if (entry.stackTrace != null) 'stack_trace': entry.stackTrace!.toString(),
    };

    return json.encode(jsonData);
  }

  /// Get default log directory
  Future<String> _getDefaultLogDirectory() async {
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

  /// Parse log level from string
  LogLevel _parseLogLevel(String levelStr) {
    switch (levelStr.toLowerCase()) {
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

  /// Format duration for human readability
  String _formatDuration(Duration duration) {
    if (duration.inMilliseconds < 1000) {
      return '${duration.inMilliseconds}ms';
    } else if (duration.inSeconds < 60) {
      return '${(duration.inMilliseconds / 1000).toStringAsFixed(2)}s';
    } else {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
  }

  /// Get recent log entries
  List<LogEntry> getRecentLogs({int limit = 100, LogLevel? minLevel}) {
    var logs = _logBuffer.toList();
    
    if (minLevel != null) {
      logs = logs.where((log) => log.level.index >= minLevel.index).toList();
    }
    
    return logs.reversed.take(limit).toList();
  }

  /// Export logs to file
  Future<File> exportLogs({
    DateTime? fromDate,
    DateTime? toDate,
    LogLevel? minLevel,
  }) async {
    final exportFile = File(path.join(await _getDefaultLogDirectory(), 'export_${DateTime.now().millisecondsSinceEpoch}.json'));
    
    // This would read from log files and filter based on criteria
    // For now, just export recent logs
    final logs = getRecentLogs(limit: 1000, minLevel: minLevel);
    
    final exportData = {
      'export_timestamp': DateTime.now().toIso8601String(),
      'filters': {
        'from_date': fromDate?.toIso8601String(),
        'to_date': toDate?.toIso8601String(),
        'min_level': minLevel?.name,
      },
      'logs': logs.map((log) => {
        'timestamp': log.timestamp.toIso8601String(),
        'level': log.level.name,
        'message': log.message,
        'category': log.category,
        'data': log.data,
      }).toList(),
    };
    
    await exportFile.writeAsString(const JsonEncoder.withIndent('  ').convert(exportData));
    return exportFile;
  }

  /// Dispose logger resources
  Future<void> dispose() async {
    _flushLogs();
    await _logSink?.flush();
    await _logSink?.close();
    _flushTimer?.cancel();
    _logBuffer.clear();
    _initialized = false;
  }
}

/// Log entry data structure
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

/// Performance measurement utility
class PerformanceTimer {
  final String _operation;
  final DateTime _startTime;
  final Map<String, dynamic>? _context;

  PerformanceTimer._(this._operation, this._startTime, this._context);

  /// Start performance measurement
  static PerformanceTimer start(String operation, {Map<String, dynamic>? context}) {
    return PerformanceTimer._(operation, DateTime.now(), context);
  }

  /// Stop measurement and log result
  void stop({Map<String, dynamic>? additionalMetrics}) {
    final duration = DateTime.now().difference(_startTime);
    final metrics = <String, dynamic>{
      ...?_context,
      ...?additionalMetrics,
    };
    
    ProductionLogger.instance.performance(_operation, duration, metrics: metrics);
  }
}

// ==================== Riverpod Provider ====================

final productionLoggerProvider = Provider<ProductionLogger>((ref) {
  return ProductionLogger.instance;
});