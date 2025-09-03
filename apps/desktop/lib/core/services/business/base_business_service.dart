import 'package:flutter/foundation.dart';

/// Base interface for all business services
/// Provides common functionality and error handling patterns
abstract class BaseBusinessService {
  /// Service initialization - called when service is registered
  Future<void> initialize() async {}
  
  /// Service cleanup - called when service is disposed
  Future<void> dispose() async {}
  
  /// Common error handling for business operations
  @protected
  Future<T> handleBusinessOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    try {
      final result = await operation();
      debugPrint('✅ Business operation completed: $operationName');
      return result;
    } catch (error) {
      debugPrint('❌ Business operation failed: $operationName - $error');
      rethrow;
    }
  }
  
  /// Validates input parameters for business operations
  @protected
  void validateRequired(Map<String, dynamic> params) {
    for (final entry in params.entries) {
      if (entry.value == null) {
        throw ArgumentError('Required parameter "${entry.key}" is null');
      }
      
      if (entry.value is String && (entry.value as String).trim().isEmpty) {
        throw ArgumentError('Required parameter "${entry.key}" is empty');
      }
      
      if (entry.value is List && (entry.value as List).isEmpty) {
        throw ArgumentError('Required parameter "${entry.key}" is empty');
      }
    }
  }
}

/// Result wrapper for business operations
class BusinessResult<T> {
  final bool isSuccess;
  final T? data;
  final String? error;
  final Exception? exception;
  
  const BusinessResult._({
    required this.isSuccess,
    this.data,
    this.error,
    this.exception,
  });
  
  /// Creates a successful result
  factory BusinessResult.success(T data) {
    return BusinessResult._(
      isSuccess: true,
      data: data,
    );
  }
  
  /// Creates a failure result
  factory BusinessResult.failure(String error, [Exception? exception]) {
    return BusinessResult._(
      isSuccess: false,
      error: error,
      exception: exception,
    );
  }
  
  /// Creates a failure result from an exception
  factory BusinessResult.fromException(Exception exception) {
    return BusinessResult._(
      isSuccess: false,
      error: exception.toString(),
      exception: exception,
    );
  }
  
  /// Maps the result data to another type
  BusinessResult<U> map<U>(U Function(T data) mapper) {
    if (isSuccess && data != null) {
      try {
        return BusinessResult.success(mapper(data as T));
      } catch (e) {
        return BusinessResult.failure('Mapping failed: $e');
      }
    } else {
      return BusinessResult._(
        isSuccess: false,
        error: error,
        exception: exception,
      );
    }
  }
  
  /// Returns data if successful, otherwise throws
  T unwrap() {
    if (isSuccess && data != null) {
      return data as T;
    }
    throw exception ?? Exception(error ?? 'Operation failed');
  }
  
  /// Returns data if successful, otherwise returns fallback
  T unwrapOr(T fallback) {
    return isSuccess && data != null ? data as T : fallback;
  }
}

/// Base repository interface for data access
abstract class BaseRepository<T, ID> {
  Future<List<T>> findAll();
  Future<T?> findById(ID id);
  Future<T> create(T entity);
  Future<T> update(T entity);
  Future<void> delete(ID id);
  Future<bool> exists(ID id);
}

/// Business service events for reactive updates
abstract class BusinessServiceEvent {
  final DateTime timestamp = DateTime.now();
}

class EntityCreatedEvent<T> extends BusinessServiceEvent {
  final T entity;
  EntityCreatedEvent(this.entity);
}

class EntityUpdatedEvent<T> extends BusinessServiceEvent {
  final T entity;
  EntityUpdatedEvent(this.entity);
}

class EntityDeletedEvent<T> extends BusinessServiceEvent {
  final String id;
  EntityDeletedEvent(this.id);
}

/// Event bus for business service communications
class BusinessEventBus {
  static final _instance = BusinessEventBus._internal();
  factory BusinessEventBus() => _instance;
  BusinessEventBus._internal();
  
  final Map<Type, List<Function(BusinessServiceEvent)>> _listeners = {};
  
  /// Subscribe to events of a specific type
  void subscribe<T extends BusinessServiceEvent>(void Function(T) listener) {
    _listeners.putIfAbsent(T, () => []);
    _listeners[T]!.add((event) => listener(event as T));
  }
  
  /// Publish an event to all listeners
  void publish(BusinessServiceEvent event) {
    final listeners = _listeners[event.runtimeType];
    if (listeners != null) {
      for (final listener in listeners) {
        try {
          listener(event);
        } catch (e) {
          debugPrint('❌ Event listener error: $e');
        }
      }
    }
  }
  
  /// Clear all listeners (mainly for testing)
  void clear() {
    _listeners.clear();
  }
}