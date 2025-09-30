import 'dart:async';
import 'app_logger.dart';

/// Circuit breaker pattern to prevent cascading failures
class CircuitBreaker {
  final String name;
  final int failureThreshold;
  final Duration timeout;
  final Duration resetTimeout;

  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  Timer? _resetTimer;

  CircuitBreaker({
    required this.name,
    this.failureThreshold = 5,
    this.timeout = const Duration(seconds: 30),
    this.resetTimeout = const Duration(minutes: 1),
  });

  /// Execute an operation with circuit breaker protection
  Future<T> execute<T>(
    Future<T> Function() operation,
    T fallback, {
    String? operationName,
  }) async {
    final opName = operationName ?? 'operation';

    // If circuit is open, return fallback immediately
    if (_state == CircuitBreakerState.open) {
      AppLogger.warning(
        'Circuit breaker $name is OPEN, returning fallback for $opName',
        component: 'CircuitBreaker',
      );
      return fallback;
    }

    try {
      // Execute with timeout
      final result = await operation().timeout(timeout);

      // Success - reset failure count and potentially close circuit
      _onSuccess();

      AppLogger.debug(
        'Circuit breaker $name: $opName succeeded',
        component: 'CircuitBreaker',
      );

      return result;
    } on TimeoutException catch (e) {
      _onFailure();
      AppLogger.error(
        'Circuit breaker $name: $opName timed out after ${timeout.inSeconds}s',
        component: 'CircuitBreaker',
        error: e,
      );
      return fallback;
    } catch (e, stackTrace) {
      _onFailure();
      AppLogger.error(
        'Circuit breaker $name: $opName failed',
        component: 'CircuitBreaker',
        error: e,
        stackTrace: stackTrace,
      );
      return fallback;
    }
  }

  /// Execute operation that returns bool success/failure
  Future<bool> executeBool(
    Future<bool> Function() operation, {
    String? operationName,
  }) async {
    return await execute(operation, false, operationName: operationName);
  }

  /// Execute operation that may return null on failure
  Future<T?> executeNullable<T>(
    Future<T?> Function() operation, {
    String? operationName,
  }) async {
    return await execute(operation, null, operationName: operationName);
  }

  void _onSuccess() {
    _failureCount = 0;
    if (_state == CircuitBreakerState.halfOpen) {
      _state = CircuitBreakerState.closed;
      AppLogger.info(
        'Circuit breaker $name: CLOSED (recovered from half-open)',
        component: 'CircuitBreaker',
      );
    }
  }

  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_state == CircuitBreakerState.halfOpen) {
      // Failed while half-open, go back to open
      _openCircuit();
    } else if (_failureCount >= failureThreshold) {
      // Threshold reached, open the circuit
      _openCircuit();
    }
  }

  void _openCircuit() {
    _state = CircuitBreakerState.open;
    AppLogger.warning(
      'Circuit breaker $name: OPENED (failure count: $_failureCount)',
      component: 'CircuitBreaker',
    );

    // Set timer to attempt reset
    _resetTimer?.cancel();
    _resetTimer = Timer(resetTimeout, _attemptReset);
  }

  void _attemptReset() {
    if (_state == CircuitBreakerState.open) {
      _state = CircuitBreakerState.halfOpen;
      AppLogger.info(
        'Circuit breaker $name: HALF-OPEN (attempting reset)',
        component: 'CircuitBreaker',
      );
    }
  }

  /// Get current circuit breaker status
  CircuitBreakerStatus get status => CircuitBreakerStatus(
    name: name,
    state: _state,
    failureCount: _failureCount,
    lastFailureTime: _lastFailureTime,
  );

  /// Reset the circuit breaker manually
  void reset() {
    _state = CircuitBreakerState.closed;
    _failureCount = 0;
    _lastFailureTime = null;
    _resetTimer?.cancel();
    _resetTimer = null;

    AppLogger.info(
      'Circuit breaker $name: RESET manually',
      component: 'CircuitBreaker',
    );
  }

  /// Dispose resources
  void dispose() {
    _resetTimer?.cancel();
    _resetTimer = null;
  }
}

enum CircuitBreakerState {
  closed,   // Normal operation
  open,     // Failing, rejecting calls
  halfOpen, // Testing if service recovered
}

class CircuitBreakerStatus {
  final String name;
  final CircuitBreakerState state;
  final int failureCount;
  final DateTime? lastFailureTime;

  const CircuitBreakerStatus({
    required this.name,
    required this.state,
    required this.failureCount,
    this.lastFailureTime,
  });

  bool get isHealthy => state == CircuitBreakerState.closed;
  bool get isOpen => state == CircuitBreakerState.open;
  bool get isHalfOpen => state == CircuitBreakerState.halfOpen;
}