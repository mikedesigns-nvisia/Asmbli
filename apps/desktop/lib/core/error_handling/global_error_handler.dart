import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/desktop/desktop_storage_service.dart';

enum ErrorLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

enum ErrorCategory {
  ui,
  network,
  storage,
  security,
  performance,
  business,
  system,
  unknown,
}

class ErrorReport {
  final String id;
  final DateTime timestamp;
  final Object error;
  final StackTrace? stackTrace;
  final ErrorLevel level;
  final ErrorCategory category;
  final String? context;
  final Map<String, dynamic> metadata;
  final String? userId;
  final String deviceInfo;
  
  ErrorReport({
    required this.id,
    required this.timestamp,
    required this.error,
    this.stackTrace,
    required this.level,
    required this.category,
    this.context,
    this.metadata = const {},
    this.userId,
    required this.deviceInfo,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'error': error.toString(),
      'stackTrace': stackTrace?.toString(),
      'level': level.name,
      'category': category.name,
      'context': context,
      'metadata': metadata,
      'userId': userId,
      'deviceInfo': deviceInfo,
    };
  }
  
  factory ErrorReport.fromJson(Map<String, dynamic> json) {
    return ErrorReport(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      error: json['error'],
      stackTrace: json['stackTrace'] != null 
        ? StackTrace.fromString(json['stackTrace'])
        : null,
      level: ErrorLevel.values.firstWhere((e) => e.name == json['level']),
      category: ErrorCategory.values.firstWhere((c) => c.name == json['category']),
      context: json['context'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      userId: json['userId'],
      deviceInfo: json['deviceInfo'],
    );
  }
  
  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('[${level.name.toUpperCase()}] ${category.name} Error');
    if (context != null) {
      buffer.writeln('Context: $context');
    }
    buffer.writeln('Message: $error');
    if (metadata.isNotEmpty) {
      buffer.writeln('Metadata: ${jsonEncode(metadata)}');
    }
    if (stackTrace != null && kDebugMode) {
      buffer.writeln('Stack Trace:');
      buffer.writeln(stackTrace.toString());
    }
    return buffer.toString();
  }
}

class GlobalErrorHandler extends StateNotifier<List<ErrorReport>> {
  static const int _maxStoredErrors = 1000;
  static const int _maxReportsPerSession = 100;
  
  final DesktopStorageService _storage;
  final StreamController<ErrorReport> _errorStreamController = StreamController.broadcast();
  
  int _reportCount = 0;
  Timer? _cleanupTimer;
  
  GlobalErrorHandler(this._storage) : super([]) {
    _initializeErrorHandling();
    _startCleanupTimer();
  }
  
  Stream<ErrorReport> get errorStream => _errorStreamController.stream;
  
  void _initializeErrorHandling() {
    // Set up Flutter error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      reportError(
        details.exception,
        details.stack,
        context: details.context?.toString(),
        level: ErrorLevel.error,
        category: _categorizeError(details.exception),
        metadata: {
          'library': details.library,
          'silent': details.silent,
        },
      );
    };
    
    // Set up platform error handling (only available in newer Flutter versions)
    try {
      PlatformDispatcher.instance.onError = (error, stackTrace) {
        reportError(
          error,
          stackTrace,
          level: ErrorLevel.critical,
          category: _categorizeError(error),
        );
        return true;
      };
    } catch (e) {
      // Platform error handling not available, continue without it
    }
    
    // Set up isolate error handling
    try {
      Isolate.current.addErrorListener(RawReceivePort((pair) async {
        final List<dynamic> errorAndStacktrace = pair;
        await reportError(
          errorAndStacktrace.first,
          errorAndStacktrace.length > 1 ? errorAndStacktrace[1] : null,
          level: ErrorLevel.critical,
          category: ErrorCategory.system,
          context: 'Isolate',
        );
      }).sendPort);
    } catch (e) {
      // Isolate error handling not available, continue without it
    }
    
    // Load existing error reports
    _loadStoredErrors();
  }
  
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _cleanupOldErrors();
    });
  }
  
  Future<void> reportError(
    Object error,
    StackTrace? stackTrace, {
    String? context,
    ErrorLevel level = ErrorLevel.error,
    ErrorCategory? category,
    Map<String, dynamic> metadata = const {},
    String? userId,
  }) async {
    // Rate limiting
    if (_reportCount >= _maxReportsPerSession) {
      if (kDebugMode) {
        print('Error reporting rate limit exceeded');
      }
      return;
    }
    
    _reportCount++;
    
    final report = ErrorReport(
      id: _generateErrorId(),
      timestamp: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
      level: level,
      category: category ?? _categorizeError(error),
      context: context,
      metadata: {
        ...metadata,
        'sessionReportCount': _reportCount,
        'appVersion': await _getAppVersion(),
        'platform': _getPlatformInfo(),
      },
      userId: userId,
      deviceInfo: await _getDeviceInfo(),
    );
    
    // Add to state
    state = [...state, report];
    
    // Emit to stream
    _errorStreamController.add(report);
    
    // Store persistently
    await _storeError(report);
    
    // Console logging in debug mode
    if (kDebugMode) {
      print('🚨 ${report.toString()}');
    }
    
    // Handle critical errors
    if (level == ErrorLevel.critical) {
      await _handleCriticalError(report);
    }
  }
  
  ErrorCategory _categorizeError(Object error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || 
        errorString.contains('http') ||
        errorString.contains('connection')) {
      return ErrorCategory.network;
    } else if (errorString.contains('storage') ||
               errorString.contains('database') ||
               errorString.contains('hive') ||
               errorString.contains('disk')) {
      return ErrorCategory.storage;
    } else if (errorString.contains('permission') ||
               errorString.contains('security') ||
               errorString.contains('auth')) {
      return ErrorCategory.security;
    } else if (errorString.contains('memory') ||
               errorString.contains('performance') ||
               errorString.contains('timeout')) {
      return ErrorCategory.performance;
    } else if (errorString.contains('render') ||
               errorString.contains('widget') ||
               errorString.contains('ui')) {
      return ErrorCategory.ui;
    } else if (errorString.contains('isolate') ||
               errorString.contains('platform') ||
               errorString.contains('system')) {
      return ErrorCategory.system;
    } else if (errorString.contains('business') ||
               errorString.contains('validation') ||
               errorString.contains('logic')) {
      return ErrorCategory.business;
    }
    
    return ErrorCategory.unknown;
  }
  
  String _generateErrorId() {
    return 'err_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
  
  Future<String> _getAppVersion() async {
    try {
      // This would typically come from package_info
      return '1.0.0';
    } catch (e) {
      return 'unknown';
    }
  }
  
  String _getPlatformInfo() {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }
  
  Future<String> _getDeviceInfo() async {
    final buffer = StringBuffer();
    buffer.write('Platform: ${_getPlatformInfo()}');
    buffer.write(', Debug: ${kDebugMode}');
    buffer.write(', Profile: ${kProfileMode}');
    buffer.write(', Release: ${kReleaseMode}');
    return buffer.toString();
  }
  
  Future<void> _storeError(ErrorReport report) async {
    try {
      final reportData = report.toJson();
      await _storage.setHiveData('error_reports', report.id, reportData);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to store error report: $e');
      }
    }
  }
  
  Future<void> _loadStoredErrors() async {
    try {
      final errorIds = _storage.getHiveKeys('error_reports');
      final reports = <ErrorReport>[];
      
      for (final id in errorIds) {
        try {
          final reportData = _storage.getHiveData<Map<String, dynamic>>('error_reports', id);
          if (reportData != null) {
            reports.add(ErrorReport.fromJson(reportData));
          }
        } catch (e) {
          // Skip corrupted error reports
        }
      }
      
      // Sort by timestamp (newest first)
      reports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // Limit to max stored errors
      if (reports.length > _maxStoredErrors) {
        reports.removeRange(_maxStoredErrors, reports.length);
      }
      
      state = reports;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load stored errors: $e');
      }
    }
  }
  
  Future<void> _handleCriticalError(ErrorReport report) async {
    // For critical errors, we might want to:
    // 1. Force a crash report
    // 2. Save application state
    // 3. Attempt recovery
    
    try {
      // Save current application state
      await _saveApplicationState(report);
      
      // Attempt automatic recovery for known critical errors
      await _attemptRecovery(report);
      
    } catch (e) {
      if (kDebugMode) {
        print('Critical error handling failed: $e');
      }
    }
  }
  
  Future<void> _saveApplicationState(ErrorReport report) async {
    try {
      final appState = {
        'timestamp': DateTime.now().toIso8601String(),
        'errorId': report.id,
        'errorType': report.error.toString(),
        'context': report.context,
        // Add more application state as needed
      };
      
      await _storage.setHiveData('app_state', 'last_critical_error', appState);
    } catch (e) {
      // Ignore state save failures
    }
  }
  
  Future<void> _attemptRecovery(ErrorReport report) async {
    switch (report.category) {
      case ErrorCategory.storage:
        await _recoverFromStorageError();
        break;
      case ErrorCategory.network:
        await _recoverFromNetworkError();
        break;
      case ErrorCategory.ui:
        await _recoverFromUIError();
        break;
      default:
        // No automatic recovery for other error types
        break;
    }
  }
  
  Future<void> _recoverFromStorageError() async {
    try {
      // Attempt to reinitialize storage
      await _storage.initialize();
    } catch (e) {
      // Recovery failed
    }
  }
  
  Future<void> _recoverFromNetworkError() async {
    // Network recovery strategies could be implemented here
  }
  
  Future<void> _recoverFromUIError() async {
    // UI error recovery (like rebuilding widget trees) could be implemented here
  }
  
  void _cleanupOldErrors() {
    final now = DateTime.now();
    final cutoffDate = now.subtract(const Duration(days: 7)); // Keep errors for 7 days
    
    final filteredReports = state
        .where((report) => report.timestamp.isAfter(cutoffDate))
        .toList();
    
    if (filteredReports.length != state.length) {
      state = filteredReports;
      
      // Also clean up stored errors
      _cleanupStoredErrors(cutoffDate);
    }
  }
  
  Future<void> _cleanupStoredErrors(DateTime cutoffDate) async {
    try {
      final errorIds = _storage.getHiveKeys('error_reports');
      
      for (final id in errorIds) {
        try {
          final reportData = _storage.getHiveData<Map<String, dynamic>>('error_reports', id);
          if (reportData != null) {
            final timestamp = DateTime.parse(reportData['timestamp']);
            if (timestamp.isBefore(cutoffDate)) {
              await _storage.removeHiveData('error_reports', id);
            }
          }
        } catch (e) {
          // Remove corrupted entries
          await _storage.removeHiveData('error_reports', id);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cleanup failed: $e');
      }
    }
  }
  
  // Public methods for error reporting
  void reportInfo(String message, {String? context, Map<String, dynamic>? metadata}) {
    reportError(
      message,
      null,
      context: context,
      level: ErrorLevel.info,
      metadata: metadata ?? {},
    );
  }
  
  void reportWarning(String message, {String? context, Map<String, dynamic>? metadata}) {
    reportError(
      message,
      null,
      context: context,
      level: ErrorLevel.warning,
      metadata: metadata ?? {},
    );
  }
  
  void reportDebug(String message, {String? context, Map<String, dynamic>? metadata}) {
    if (kDebugMode) {
      reportError(
        message,
        null,
        context: context,
        level: ErrorLevel.debug,
        metadata: metadata ?? {},
      );
    }
  }
  
  // Error analytics
  Map<String, int> getErrorSummary() {
    final summary = <String, int>{};
    
    for (final report in state) {
      final key = '${report.category.name}_${report.level.name}';
      summary[key] = (summary[key] ?? 0) + 1;
    }
    
    return summary;
  }
  
  List<ErrorReport> getRecentErrors({int limit = 50}) {
    return state.take(limit).toList();
  }
  
  List<ErrorReport> getErrorsByCategory(ErrorCategory category) {
    return state.where((report) => report.category == category).toList();
  }
  
  List<ErrorReport> getErrorsByLevel(ErrorLevel level) {
    return state.where((report) => report.level == level).toList();
  }
  
  Future<void> clearAllErrors() async {
    state = [];
    
    try {
      await _storage.clearHiveBox('error_reports');
    } catch (e) {
      if (kDebugMode) {
        print('Failed to clear stored errors: $e');
      }
    }
  }
  
  Future<Map<String, dynamic>> exportErrorReports() async {
    return {
      'exported_at': DateTime.now().toIso8601String(),
      'total_errors': state.length,
      'summary': getErrorSummary(),
      'errors': state.map((report) => report.toJson()).toList(),
    };
  }
  
  @override
  void dispose() {
    _cleanupTimer?.cancel();
    _errorStreamController.close();
    super.dispose();
  }
}

// Provider for global error handler
final globalErrorHandlerProvider = StateNotifierProvider<GlobalErrorHandler, List<ErrorReport>>((ref) {
  final storage = DesktopStorageService.instance;
  return GlobalErrorHandler(storage);
});

// Error monitoring widget
class ErrorMonitoringWidget extends ConsumerWidget {
  final Widget child;
  
  const ErrorMonitoringWidget({super.key, required this.child});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for errors to show notifications
    ref.listen<List<ErrorReport>>(globalErrorHandlerProvider, (previous, current) {
      if (current.isNotEmpty && (previous == null || current.length > previous.length)) {
        final latestError = current.first;
        
        // Show error notification for critical errors
        if (latestError.level == ErrorLevel.critical) {
          _showErrorNotification(context, latestError);
        }
      }
    });
    
    return child;
  }
  
  void _showErrorNotification(BuildContext context, ErrorReport error) {
    if (kDebugMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Critical Error: ${error.error.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Details',
            onPressed: () => _showErrorDetails(context, error),
          ),
        ),
      );
    }
  }
  
  void _showErrorDetails(BuildContext context, ErrorReport error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error Details - ${error.id}'),
        content: SingleChildScrollView(
          child: Text(error.toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}