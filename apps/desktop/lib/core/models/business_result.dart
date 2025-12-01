/// Generic result wrapper for business layer operations
/// Provides consistent error handling and success/failure states
class BusinessResult<T> {
  final bool success;
  final T? data;
  final String? error;
  final String? message;
  final Map<String, dynamic>? metadata;

  const BusinessResult({
    required this.success,
    this.data,
    this.error,
    this.message,
    this.metadata,
  });

  /// Create a successful result with data
  factory BusinessResult.successResult({
    required T data,
    String? message,
    Map<String, dynamic>? metadata,
  }) {
    return BusinessResult<T>(
      success: true,
      data: data,
      message: message,
      metadata: metadata,
    );
  }

  /// Create a failure result with error
  factory BusinessResult.failure({
    required String error,
    String? message,
    Map<String, dynamic>? metadata,
  }) {
    return BusinessResult<T>(
      success: false,
      error: error,
      message: message,
      metadata: metadata,
    );
  }

  /// Check if the result has data
  bool get hasData => data != null;

  /// Get the data or throw if not available
  T get dataOrThrow {
    if (data == null) {
      throw StateError('BusinessResult does not contain data. Error: ${error ?? "Unknown"}');
    }
    return data as T;
  }

  /// Transform the data if successful
  BusinessResult<R> map<R>(R Function(T data) transform) {
    if (success && data != null) {
      try {
        return BusinessResult.successResult(
          data: transform(data as T),
          message: message,
          metadata: metadata,
        );
      } catch (e) {
        return BusinessResult.failure(
          error: 'Transform failed: $e',
          metadata: metadata,
        );
      }
    }
    return BusinessResult<R>(
      success: false,
      error: error,
      message: message,
      metadata: metadata,
    );
  }

  @override
  String toString() {
    if (success) {
      return 'BusinessResult.success(data: $data, message: $message)';
    } else {
      return 'BusinessResult.failure(error: $error)';
    }
  }
}
