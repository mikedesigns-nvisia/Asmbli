import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_logger.dart';

/// Global error boundary for production-ready error handling
class GlobalErrorHandler {
  static bool _isInitialized = false;
  static StreamSubscription<IsolateError>? _isolateErrorSubscription;

  /// Initialize global error handling
  static void initialize() {
    if (_isInitialized) return;

    // Handle Flutter framework errors
    FlutterError.onError = _handleFlutterError;

    // Handle platform dispatch errors
    PlatformDispatcher.instance.onError = _handlePlatformError;

    // Handle isolate errors
    _isolateErrorSubscription = Isolate.current.errors.listen(_handleIsolateError);

    _isInitialized = true;
    AppLogger.info('Global error handler initialized', component: 'ErrorHandler');
  }

  /// Handle Flutter framework errors
  static void _handleFlutterError(FlutterErrorDetails details) {
    AppLogger.critical(
      'Flutter framework error: ${details.exception}',
      component: 'ErrorHandler',
      error: details.exception,
      stackTrace: details.stack,
    );

    // In debug mode, still show the red screen
    if (kDebugMode) {
      FlutterError.presentError(details);
    } else {
      // In production, log but don't crash
      _logProductionError('Flutter Error', details.exception, details.stack);
    }
  }

  /// Handle platform errors
  static bool _handlePlatformError(Object error, StackTrace stack) {
    AppLogger.critical(
      'Platform error: $error',
      component: 'ErrorHandler',
      error: error,
      stackTrace: stack,
    );

    _logProductionError('Platform Error', error, stack);
    return true; // Handled
  }

  /// Handle isolate errors
  static void _handleIsolateError(IsolateError error) {
    AppLogger.critical(
      'Isolate error: ${error.message}',
      component: 'ErrorHandler',
      error: error,
    );

    _logProductionError('Isolate Error', error, null);
  }

  /// Log errors for production monitoring
  static void _logProductionError(String type, Object error, StackTrace? stack) {
    // In a real app, this would send to crash reporting service
    // For now, we'll just log to system
    AppLogger.critical(
      '$type in production: $error',
      component: 'ErrorHandler',
      error: error,
      stackTrace: stack,
    );
  }

  /// Wrap dangerous operations with error handling
  static Future<T> wrapAsync<T>(
    Future<T> Function() operation, {
    required T fallback,
    String? operationName,
    bool logError = true,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      if (logError) {
        AppLogger.error(
          'Error in ${operationName ?? 'operation'}: $error',
          component: 'ErrorHandler',
          error: error,
          stackTrace: stackTrace,
        );
      }
      return fallback;
    }
  }

  /// Wrap synchronous operations with error handling
  static T wrapSync<T>(
    T Function() operation, {
    required T fallback,
    String? operationName,
    bool logError = true,
  }) {
    try {
      return operation();
    } catch (error, stackTrace) {
      if (logError) {
        AppLogger.error(
          'Error in ${operationName ?? 'operation'}: $error',
          component: 'ErrorHandler',
          error: error,
          stackTrace: stackTrace,
        );
      }
      return fallback;
    }
  }

  /// Create an error boundary widget
  static Widget createErrorBoundary({
    required Widget child,
    Widget? fallback,
    String? boundaryName,
  }) {
    return ErrorBoundary(
      child: child,
      fallback: fallback,
      boundaryName: boundaryName,
    );
  }

  /// Dispose resources
  static void dispose() {
    _isolateErrorSubscription?.cancel();
    _isolateErrorSubscription = null;
    _isInitialized = false;
  }
}

/// Error boundary widget for catching widget tree errors
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? fallback;
  final String? boundaryName;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
    this.boundaryName,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.fallback ?? _buildErrorWidget(context);
    }

    try {
      return widget.child;
    } catch (error, stackTrace) {
      _error = error;
      _stackTrace = stackTrace;

      AppLogger.error(
        'Error boundary caught error in ${widget.boundaryName ?? 'widget tree'}: $error',
        component: 'ErrorBoundary',
        error: error,
        stackTrace: stackTrace,
      );

      return widget.fallback ?? _buildErrorWidget(context);
    }
  }

  Widget _buildErrorWidget(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'An unexpected error occurred. Please try restarting the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Reset error state
                    setState(() {
                      _error = null;
                      _stackTrace = null;
                    });
                  },
                  child: const Text('Try Again'),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: const Text('Error Details (Debug)'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: SelectableText(
                          _error?.toString() ?? 'No error details',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Safe operation wrapper with automatic error handling
class SafeOperation {
  /// Run an operation safely with automatic error handling and fallback
  static Future<T> run<T>({
    required Future<T> Function() operation,
    required T fallback,
    String? operationName,
    Duration? timeout,
    int retries = 0,
  }) async {
    var attempt = 0;
    while (attempt <= retries) {
      try {
        final future = operation();
        if (timeout != null) {
          return await future.timeout(timeout);
        }
        return await future;
      } catch (error, stackTrace) {
        attempt++;

        AppLogger.error(
          'SafeOperation failed: ${operationName ?? 'operation'} (attempt $attempt/${retries + 1}): $error',
          component: 'SafeOperation',
          error: error,
          stackTrace: stackTrace,
        );

        if (attempt > retries) {
          AppLogger.warning(
            'SafeOperation exhausted retries for ${operationName ?? 'operation'}, returning fallback',
            component: 'SafeOperation',
          );
          return fallback;
        }

        // Brief delay before retry
        await Future.delayed(Duration(milliseconds: 100 * attempt));
      }
    }

    return fallback;
  }
}