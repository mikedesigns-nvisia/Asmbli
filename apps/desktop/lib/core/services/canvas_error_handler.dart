import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Error handling and resource management for Canvas operations
/// Provides comprehensive error handling, logging, and resource cleanup
class CanvasErrorHandler {
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  static const Duration requestTimeout = Duration(seconds: 30);
  
  final List<CanvasError> _errorHistory = [];
  final Map<String, Timer> _activeTimers = {};
  final Map<String, StreamSubscription> _activeSubscriptions = {};
  
  /// Handle and categorize errors
  static CanvasError handleError(dynamic error, String context, {StackTrace? stackTrace}) {
    final canvasError = _categorizeError(error, context, stackTrace);
    
    // Log error with appropriate level
    _logError(canvasError);
    
    // Report critical errors
    if (canvasError.severity == ErrorSeverity.critical) {
      _reportCriticalError(canvasError);
    }
    
    return canvasError;
  }

  /// Retry operation with exponential backoff
  static Future<T> retryOperation<T>(
    Future<T> Function() operation,
    String operationName, {
    int maxRetries = maxRetries,
    Duration initialDelay = retryDelay,
  }) async {
    int attempts = 0;
    Duration delay = initialDelay;
    
    while (attempts < maxRetries) {
      try {
        return await operation().timeout(requestTimeout);
      } catch (e, stackTrace) {
        attempts++;
        
        final error = handleError(e, 'Retry operation: $operationName (attempt $attempts)', stackTrace: stackTrace);
        
        if (attempts >= maxRetries || !_isRetryableError(error)) {
          print('❌ Operation failed after $attempts attempts: $operationName');
          rethrow;
        }
        
        print('⚠️ Retrying $operationName in ${delay.inSeconds}s (attempt $attempts/$maxRetries)');
        await Future.delayed(delay);
        delay = Duration(milliseconds: (delay.inMilliseconds * 1.5).round()); // Exponential backoff
      }
    }
    
    throw Exception('Operation failed after $maxRetries attempts: $operationName');
  }

  /// Safe resource cleanup with error handling
  static Future<void> safeCleanup(String resourceName, Future<void> Function() cleanup) async {
    try {
      await cleanup().timeout(const Duration(seconds: 5));
      print('✅ Cleaned up resource: $resourceName');
    } catch (e) {
      print('⚠️ Failed to cleanup resource $resourceName: $e');
      // Don't rethrow - cleanup failures shouldn't break the app
    }
  }

  /// Register a timer for automatic cleanup
  void registerTimer(String id, Timer timer) {
    // Cancel existing timer if any
    _activeTimers[id]?.cancel();
    _activeTimers[id] = timer;
  }

  /// Register a stream subscription for automatic cleanup
  void registerSubscription(String id, StreamSubscription subscription) {
    // Cancel existing subscription if any
    _activeSubscriptions[id]?.cancel();
    _activeSubscriptions[id] = subscription;
  }

  /// Cleanup all managed resources
  Future<void> cleanup() async {
    print('🧹 Cleaning up Canvas error handler resources...');
    
    // Cancel all timers
    for (final entry in _activeTimers.entries) {
      await safeCleanup('Timer ${entry.key}', () async {
        entry.value.cancel();
      });
    }
    _activeTimers.clear();
    
    // Cancel all subscriptions
    for (final entry in _activeSubscriptions.entries) {
      await safeCleanup('Subscription ${entry.key}', () async {
        await entry.value.cancel();
      });
    }
    _activeSubscriptions.clear();
    
    print('✅ Canvas error handler cleanup complete');
  }

  /// Get error statistics
  Map<String, dynamic> getErrorStats() {
    final stats = <String, dynamic>{
      'totalErrors': _errorHistory.length,
      'criticalErrors': _errorHistory.where((e) => e.severity == ErrorSeverity.critical).length,
      'warningErrors': _errorHistory.where((e) => e.severity == ErrorSeverity.warning).length,
      'infoErrors': _errorHistory.where((e) => e.severity == ErrorSeverity.info).length,
      'activeTimers': _activeTimers.length,
      'activeSubscriptions': _activeSubscriptions.length,
    };
    
    // Group by error type
    final byType = <String, int>{};
    for (final error in _errorHistory) {
      byType[error.type.toString()] = (byType[error.type.toString()] ?? 0) + 1;
    }
    stats['errorsByType'] = byType;
    
    return stats;
  }

  /// Clear error history
  void clearErrorHistory() {
    _errorHistory.clear();
    print('🗑️ Canvas error history cleared');
  }

  /// Categorize error based on type and context
  static CanvasError _categorizeError(dynamic error, String context, StackTrace? stackTrace) {
    ErrorType type;
    ErrorSeverity severity;
    String message;
    Map<String, dynamic> metadata = {};

    if (error is SocketException) {
      type = ErrorType.network;
      severity = ErrorSeverity.warning;
      message = 'Network error: ${error.message}';
      metadata = {'host': error.address?.host, 'port': error.port};
    } else if (error is TimeoutException) {
      type = ErrorType.timeout;
      severity = ErrorSeverity.warning;
      message = 'Operation timed out: ${error.message}';
      metadata = {'duration': error.duration?.inMilliseconds};
    } else if (error is HttpException) {
      type = ErrorType.http;
      severity = ErrorSeverity.warning;
      message = 'HTTP error: ${error.message}';
      metadata = {'uri': error.uri?.toString()};
    } else if (error is FileSystemException) {
      type = ErrorType.storage;
      severity = ErrorSeverity.warning;
      message = 'File system error: ${error.message}';
      metadata = {'path': error.path, 'osError': error.osError?.message};
    } else if (error is FormatException) {
      type = ErrorType.parsing;
      severity = ErrorSeverity.warning;
      message = 'Format error: ${error.message}';
      metadata = {'source': error.source?.toString()};
    } else if (error is ArgumentError) {
      type = ErrorType.validation;
      severity = ErrorSeverity.info;
      message = 'Validation error: ${error.message}';
      metadata = {'invalidValue': error.invalidValue?.toString()};
    } else if (error is StateError) {
      type = ErrorType.state;
      severity = ErrorSeverity.warning;
      message = 'State error: ${error.message}';
    } else if (error is AssertionError) {
      type = ErrorType.assertion;
      severity = ErrorSeverity.critical;
      message = 'Assertion failed: ${error.message}';
    } else if (error is OutOfMemoryError) {
      type = ErrorType.memory;
      severity = ErrorSeverity.critical;
      message = 'Out of memory error';
    } else {
      type = ErrorType.unknown;
      severity = ErrorSeverity.warning;
      message = error.toString();
    }

    return CanvasError(
      type: type,
      severity: severity,
      message: message,
      context: context,
      timestamp: DateTime.now(),
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  /// Log error with appropriate level
  static void _logError(CanvasError error) {
    final timestamp = error.timestamp.toIso8601String();
    final severity = error.severity.toString().toUpperCase();
    final type = error.type.toString().toUpperCase();
    
    final logMessage = '[$timestamp] $severity [$type] ${error.context}: ${error.message}';
    
    switch (error.severity) {
      case ErrorSeverity.critical:
        print('🚨 $logMessage');
        if (kDebugMode && error.stackTrace != null) {
          print('Stack trace: ${error.stackTrace}');
        }
        break;
      case ErrorSeverity.warning:
        print('⚠️ $logMessage');
        break;
      case ErrorSeverity.info:
        if (kDebugMode) {
          print('ℹ️ $logMessage');
        }
        break;
    }
    
    // Add metadata if available
    if (error.metadata.isNotEmpty && kDebugMode) {
      print('   Metadata: ${error.metadata}');
    }
  }

  /// Report critical errors for monitoring
  static void _reportCriticalError(CanvasError error) {
    // In a production app, this would send to error tracking service
    // like Sentry, Crashlytics, etc.
    if (kDebugMode) {
      print('🚨 CRITICAL ERROR REPORTED: ${error.message}');
      print('   Context: ${error.context}');
      print('   Timestamp: ${error.timestamp}');
      if (error.stackTrace != null) {
        print('   Stack trace: ${error.stackTrace}');
      }
    }
  }

  /// Check if error is retryable
  static bool _isRetryableError(CanvasError error) {
    switch (error.type) {
      case ErrorType.network:
      case ErrorType.timeout:
      case ErrorType.http:
        return true;
      case ErrorType.storage:
        // Only retry if it's not a permission error
        return !error.message.toLowerCase().contains('permission');
      case ErrorType.parsing:
      case ErrorType.validation:
      case ErrorType.assertion:
      case ErrorType.memory:
        return false;
      case ErrorType.state:
      case ErrorType.unknown:
        return true; // Be conservative and allow retry
    }
  }
}

/// Canvas error representation
class CanvasError {
  final ErrorType type;
  final ErrorSeverity severity;
  final String message;
  final String context;
  final DateTime timestamp;
  final StackTrace? stackTrace;
  final Map<String, dynamic> metadata;

  CanvasError({
    required this.type,
    required this.severity,
    required this.message,
    required this.context,
    required this.timestamp,
    this.stackTrace,
    this.metadata = const {},
  });

  @override
  String toString() {
    return 'CanvasError{type: $type, severity: $severity, message: $message, context: $context}';
  }

  /// Convert to JSON for logging/reporting
  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'severity': severity.toString(),
      'message': message,
      'context': context,
      'timestamp': timestamp.toIso8601String(),
      'stackTrace': stackTrace?.toString(),
      'metadata': metadata,
    };
  }
}

/// Error type classification
enum ErrorType {
  network,
  timeout,
  http,
  storage,
  parsing,
  validation,
  state,
  assertion,
  memory,
  unknown,
}

/// Error severity levels
enum ErrorSeverity {
  info,
  warning,
  critical,
}

/// Resource management helper
class ResourceManager {
  final Map<String, Completer<void>> _pendingOperations = {};
  final Map<String, DateTime> _operationStartTimes = {};
  
  /// Track operation start
  void startOperation(String operationId) {
    _operationStartTimes[operationId] = DateTime.now();
    _pendingOperations[operationId] = Completer<void>();
  }
  
  /// Complete operation
  void completeOperation(String operationId) {
    final completer = _pendingOperations.remove(operationId);
    final startTime = _operationStartTimes.remove(operationId);
    
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      if (kDebugMode && duration.inSeconds > 5) {
        print('⏰ Long operation completed: $operationId (${duration.inSeconds}s)');
      }
    }
  }
  
  /// Fail operation
  void failOperation(String operationId, dynamic error) {
    final completer = _pendingOperations.remove(operationId);
    _operationStartTimes.remove(operationId);
    
    if (completer != null && !completer.isCompleted) {
      completer.completeError(error);
    }
  }
  
  /// Wait for operation completion
  Future<void> waitForOperation(String operationId, {Duration? timeout}) async {
    final completer = _pendingOperations[operationId];
    if (completer == null) return;
    
    if (timeout != null) {
      await completer.future.timeout(timeout);
    } else {
      await completer.future;
    }
  }
  
  /// Cancel all pending operations
  Future<void> cancelAllOperations() async {
    for (final entry in _pendingOperations.entries) {
      if (!entry.value.isCompleted) {
        entry.value.completeError(Exception('Operation cancelled: ${entry.key}'));
      }
    }
    
    _pendingOperations.clear();
    _operationStartTimes.clear();
    
    print('🛑 All pending operations cancelled');
  }
  
  /// Get operation statistics
  Map<String, dynamic> getStats() {
    return {
      'pendingOperations': _pendingOperations.length,
      'oldestOperation': _operationStartTimes.values.isEmpty 
          ? null 
          : _operationStartTimes.values.reduce((a, b) => a.isBefore(b) ? a : b).toIso8601String(),
    };
  }
}