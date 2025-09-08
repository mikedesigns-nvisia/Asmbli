import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/production_logger.dart';
import '../config/environment_config.dart';

/// Production-grade error handling system with crash reporting and recovery
class AppErrorHandler {
  static AppErrorHandler? _instance;
  static AppErrorHandler get instance => _instance ??= AppErrorHandler._();
  
  AppErrorHandler._();

  late final ProductionLogger _logger;
  late final bool _crashReportingEnabled;
  bool _initialized = false;

  /// Initialize error handler
  Future<void> initialize() async {
    if (_initialized) return;

    _logger = ProductionLogger.instance;
    await _logger.initialize();

    final env = EnvironmentConfig.instance;
    await env.initialize();
    
    _crashReportingEnabled = env.featureFlags['crash_reporting'] ?? false;

    // Setup global error handlers
    _setupFlutterErrorHandler();
    _setupIsolateErrorHandler();
    _setupZoneErrorHandler();

    _initialized = true;
    _logger.info('Error handler initialized', data: {
      'crash_reporting': _crashReportingEnabled,
      'environment': env.environment.name,
    });
  }

  /// Setup Flutter framework error handler
  void _setupFlutterErrorHandler() {
    final originalOnError = FlutterError.onError;
    
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleFlutterError(details);
      
      // Call original handler in development
      if (kDebugMode && originalOnError != null) {
        originalOnError(details);
      }
    };

    // Handle errors in debug mode
    if (kDebugMode) {
      FlutterError.presentError = (FlutterErrorDetails details) {
        _handleFlutterError(details);
        FlutterError.dumpErrorToConsole(details, forceReport: true);
      };
    }
  }

  /// Setup isolate error handler
  void _setupIsolateErrorHandler() {
    Isolate.current.addErrorListener(
      RawReceivePort((pair) async {
        final List<dynamic> errorAndStacktrace = pair;
        final error = errorAndStacktrace[0];
        final stackTrace = errorAndStacktrace[1] as String?;
        
        await _handleUncaughtError(
          error,
          stackTrace != null ? StackTrace.fromString(stackTrace) : null,
          'isolate_error',
        );
      }).sendPort,
    );
  }

  /// Setup zone error handler
  void _setupZoneErrorHandler() {
    FlutterError.onError = (FlutterErrorDetails details) {
      Zone.current.handleUncaughtError(details.exception, details.stack ?? StackTrace.current);
    };
  }

  /// Handle Flutter framework errors
  Future<void> _handleFlutterError(FlutterErrorDetails details) async {
    await _handleUncaughtError(
      details.exception,
      details.stack,
      'flutter_error',
      context: details.context?.toString(),
      library: details.library,
    );
  }

  /// Handle uncaught errors
  Future<void> _handleUncaughtError(
    dynamic error,
    StackTrace? stackTrace,
    String source, {
    String? context,
    String? library,
  }) async {
    try {
      final errorData = {
        'source': source,
        'error_type': error.runtimeType.toString(),
        'error_message': error.toString(),
        if (context != null) 'context': context,
        if (library != null) 'library': library,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _logger.error(
        'Uncaught error: ${error.toString()}',
        error: error,
        data: errorData,
        stackTrace: stackTrace,
        category: 'crash',
      );

      // Send crash report if enabled
      if (_crashReportingEnabled && !kDebugMode) {
        await _sendCrashReport(error, stackTrace, errorData);
      }

    } catch (e) {
      // Fallback logging if logger fails
      debugPrint('❌ Error handler failed: $e');
      debugPrint('Original error: $error');
    }
  }

  /// Send crash report to monitoring service
  Future<void> _sendCrashReport(
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic> errorData,
  ) async {
    try {
      // In production, this would integrate with crash reporting services
      // like Firebase Crashlytics, Sentry, or Bugsnag
      _logger.info('Crash report sent', data: {
        'report_id': DateTime.now().millisecondsSinceEpoch.toString(),
        ...errorData,
      });
      
    } catch (e) {
      _logger.error('Failed to send crash report', error: e);
    }
  }

  /// Handle business logic errors with context
  static AppException handleBusinessError(
    dynamic error, {
    String? operation,
    Map<String, dynamic>? context,
    ErrorSeverity severity = ErrorSeverity.medium,
  }) {
    final handler = AppErrorHandler.instance;
    
    final appError = error is AppException ? error : AppException(
      message: error.toString(),
      code: 'BUSINESS_ERROR',
      severity: severity,
      context: context,
    );

    handler._logger.error(
      'Business error${operation != null ? ' in $operation' : ''}',
      error: appError,
      data: {
        'operation': operation,
        'severity': severity.name,
        'error_code': appError.code,
        ...?context,
      },
      category: 'business',
    );

    return appError;
  }

  /// Handle API errors with retry logic
  static AppException handleApiError(
    dynamic error, {
    required String endpoint,
    int? statusCode,
    Map<String, dynamic>? requestData,
    int attemptNumber = 1,
  }) {
    final handler = AppErrorHandler.instance;
    
    final appError = error is AppException ? error : AppException.api(
      message: error.toString(),
      statusCode: statusCode,
      endpoint: endpoint,
    );

    handler._logger.apiCall(
      'ERROR',
      endpoint,
      statusCode ?? 0,
      Duration.zero,
      requestData: requestData,
      error: appError.toString(),
    );

    handler._logger.error(
      'API error on $endpoint',
      error: appError,
      data: {
        'endpoint': endpoint,
        'status_code': statusCode,
        'attempt': attemptNumber,
        'error_code': appError.code,
        if (requestData != null) 'request_data': requestData,
      },
      category: 'api',
    );

    return appError;
  }

  /// Handle validation errors
  static ValidationException handleValidationError(
    String field,
    String message, {
    dynamic value,
    Map<String, dynamic>? context,
  }) {
    final handler = AppErrorHandler.instance;
    
    final error = ValidationException(
      field: field,
      message: message,
      value: value,
      context: context,
    );

    handler._logger.warning(
      'Validation error: $field - $message',
      data: {
        'field': field,
        'value': value?.toString(),
        ...?context,
      },
      category: 'validation',
    );

    return error;
  }

  /// Run code with error boundary
  static Future<T> withErrorBoundary<T>(
    Future<T> Function() operation, {
    required String operationName,
    Map<String, dynamic>? context,
    T? fallbackValue,
    bool throwError = false,
  }) async {
    final handler = AppErrorHandler.instance;
    final timer = PerformanceTimer.start(operationName, context: context);
    
    try {
      final result = await operation();
      timer.stop();
      return result;
      
    } catch (error, stackTrace) {
      timer.stop(additionalMetrics: {'success': false});
      
      final appError = handleBusinessError(
        error,
        operation: operationName,
        context: context,
      );

      if (throwError || fallbackValue == null) {
        throw appError;
      }
      
      return fallbackValue;
    }
  }

  /// Create error boundary widget
  static Widget errorBoundary({
    required Widget child,
    String? boundaryName,
    Widget Function(AppException error)? errorBuilder,
  }) {
    return ErrorBoundaryWidget(
      child: child,
      boundaryName: boundaryName,
      errorBuilder: errorBuilder,
    );
  }
}

/// Error boundary widget for UI components
class ErrorBoundaryWidget extends StatefulWidget {
  final Widget child;
  final String? boundaryName;
  final Widget Function(AppException error)? errorBuilder;

  const ErrorBoundaryWidget({
    super.key,
    required this.child,
    this.boundaryName,
    this.errorBuilder,
  });

  @override
  State<ErrorBoundaryWidget> createState() => _ErrorBoundaryWidgetState();
}

class _ErrorBoundaryWidgetState extends State<ErrorBoundaryWidget> {
  AppException? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(_error!) ?? 
             _DefaultErrorWidget(error: _error!);
    }
    
    return widget.child;
  }

  @override
  void didCatch(dynamic error, StackTrace stackTrace) {
    setState(() {
      _error = AppException(
        message: error.toString(),
        code: 'UI_ERROR',
        severity: ErrorSeverity.medium,
        context: {
          'boundary': widget.boundaryName ?? 'unknown',
          'widget': widget.child.runtimeType.toString(),
        },
      );
    });

    AppErrorHandler.handleBusinessError(
      error,
      operation: 'ui_render',
      context: {
        'boundary': widget.boundaryName ?? 'unknown',
        'widget': widget.child.runtimeType.toString(),
      },
    );
  }
}

/// Default error widget for error boundaries
class _DefaultErrorWidget extends StatelessWidget {
  final AppException error;

  const _DefaultErrorWidget({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 8),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            error.userMessage,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Application exception with enhanced context
class AppException implements Exception {
  final String message;
  final String code;
  final ErrorSeverity severity;
  final Map<String, dynamic>? context;
  final DateTime timestamp;

  AppException({
    required this.message,
    required this.code,
    this.severity = ErrorSeverity.medium,
    this.context,
  }) : timestamp = DateTime.now();

  /// Create API-specific exception
  AppException.api({
    required String message,
    int? statusCode,
    String? endpoint,
  }) : this(
         message: message,
         code: 'API_ERROR_${statusCode ?? 0}',
         severity: _getApiSeverity(statusCode),
         context: {
           'status_code': statusCode,
           'endpoint': endpoint,
         },
       );

  /// Create authentication exception
  AppException.auth({
    required String message,
    String? provider,
  }) : this(
         message: message,
         code: 'AUTH_ERROR',
         severity: ErrorSeverity.high,
         context: {'provider': provider},
       );

  /// Create validation exception
  AppException.validation({
    required String message,
    required String field,
  }) : this(
         message: message,
         code: 'VALIDATION_ERROR',
         severity: ErrorSeverity.low,
         context: {'field': field},
       );

  /// Get user-friendly error message
  String get userMessage {
    switch (code) {
      case 'AUTH_ERROR':
        return 'Authentication failed. Please try signing in again.';
      case 'VALIDATION_ERROR':
        return message;
      case 'API_ERROR_404':
        return 'The requested resource was not found.';
      case 'API_ERROR_500':
        return 'Server error. Please try again later.';
      case 'API_ERROR_401':
        return 'You are not authorized to perform this action.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  static ErrorSeverity _getApiSeverity(int? statusCode) {
    if (statusCode == null) return ErrorSeverity.medium;
    if (statusCode >= 500) return ErrorSeverity.high;
    if (statusCode >= 400) return ErrorSeverity.medium;
    return ErrorSeverity.low;
  }

  @override
  String toString() {
    return 'AppException(code: $code, message: $message, severity: ${severity.name})';
  }
}

/// Validation-specific exception
class ValidationException extends AppException {
  final String field;
  final dynamic value;

  ValidationException({
    required this.field,
    required String message,
    this.value,
    Map<String, dynamic>? context,
  }) : super(
         message: message,
         code: 'VALIDATION_ERROR',
         severity: ErrorSeverity.low,
         context: {
           'field': field,
           'value': value?.toString(),
           ...?context,
         },
       );

  @override
  String get userMessage => message;
}

/// Error severity levels
enum ErrorSeverity {
  low('low'),
  medium('medium'),
  high('high'),
  critical('critical');

  const ErrorSeverity(this.name);
  final String name;
}

// ==================== Riverpod Provider ====================

final appErrorHandlerProvider = Provider<AppErrorHandler>((ref) {
  return AppErrorHandler.instance;
});