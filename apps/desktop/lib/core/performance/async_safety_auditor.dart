import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/desktop/desktop_storage_service.dart';

enum AsyncSafetyViolation {
  unmountedStateAccess,
  unhandledException,
  deadlock,
  resourceLeak,
  infiniteLoop,
  memoryLeak,
  concurrencyIssue,
}

enum SafetyLevel {
  safe,
  warning,
  danger,
  critical,
}

class AsyncOperation {
  final String id;
  final String type;
  final DateTime startTime;
  final String? context;
  final Map<String, dynamic> metadata;
  
  DateTime? endTime;
  Object? error;
  StackTrace? stackTrace;
  bool isCompleted = false;
  bool isCancelled = false;
  
  AsyncOperation({
    required this.id,
    required this.type,
    required this.startTime,
    this.context,
    this.metadata = const {},
  });
  
  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);
  bool get isActive => !isCompleted && !isCancelled;
  bool get hasError => error != null;
  
  void complete([Object? result]) {
    if (!isCompleted && !isCancelled) {
      endTime = DateTime.now();
      isCompleted = true;
    }
  }
  
  void fail(Object error, StackTrace stackTrace) {
    if (!isCompleted && !isCancelled) {
      this.error = error;
      this.stackTrace = stackTrace;
      endTime = DateTime.now();
      isCompleted = true;
    }
  }
  
  void cancel() {
    if (!isCompleted && !isCancelled) {
      isCancelled = true;
      endTime = DateTime.now();
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'context': context,
      'metadata': metadata,
      'duration': duration.inMilliseconds,
      'isCompleted': isCompleted,
      'isCancelled': isCancelled,
      'hasError': hasError,
      'error': error?.toString(),
    };
  }
}

class SafetyViolationReport {
  final String id;
  final DateTime timestamp;
  final AsyncSafetyViolation violation;
  final SafetyLevel level;
  final String message;
  final String? operationId;
  final String? context;
  final Map<String, dynamic> metadata;
  final StackTrace? stackTrace;
  
  SafetyViolationReport({
    required this.id,
    required this.timestamp,
    required this.violation,
    required this.level,
    required this.message,
    this.operationId,
    this.context,
    this.metadata = const {},
    this.stackTrace,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'violation': violation.name,
      'level': level.name,
      'message': message,
      'operationId': operationId,
      'context': context,
      'metadata': metadata,
      'stackTrace': stackTrace?.toString(),
    };
  }
  
  @override
  String toString() {
    return '[${level.name.toUpperCase()}] ${violation.name}: $message';
  }
}

class AsyncSafetyAuditor extends StateNotifier<List<SafetyViolationReport>> {
  static const Duration _maxOperationDuration = Duration(minutes: 5);
  static const Duration _auditInterval = Duration(minutes: 1);
  static const int _maxActiveOperations = 100;
  static const int _maxViolationReports = 500;
  
  final DesktopStorageService _storage;
  final Map<String, AsyncOperation> _activeOperations = {};
  final Queue<AsyncOperation> _completedOperations = Queue<AsyncOperation>();
  
  Timer? _auditTimer;
  Timer? _cleanupTimer;
  int _operationCounter = 0;
  
  AsyncSafetyAuditor(this._storage) : super([]) {
    _startAuditing();
  }
  
  void _startAuditing() {
    _auditTimer = Timer.periodic(_auditInterval, (_) => _performSafetyAudit());
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) => _cleanup());
  }
  
  String trackAsyncOperation(
    String type, {
    String? context,
    Map<String, dynamic>? metadata,
  }) {
    final id = 'async_${++_operationCounter}_${DateTime.now().millisecondsSinceEpoch}';
    
    final operation = AsyncOperation(
      id: id,
      type: type,
      startTime: DateTime.now(),
      context: context,
      metadata: metadata ?? {},
    );
    
    _activeOperations[id] = operation;
    
    // Check for too many active operations
    if (_activeOperations.length > _maxActiveOperations) {
      _reportViolation(
        violation: AsyncSafetyViolation.resourceLeak,
        level: SafetyLevel.warning,
        message: 'Too many active async operations (${_activeOperations.length})',
        operationId: id,
        context: context,
      );
    }
    
    return id;
  }
  
  void completeOperation(String operationId, [Object? result]) {
    final operation = _activeOperations.remove(operationId);
    if (operation != null) {
      operation.complete(result);
      
      // Move to completed operations queue
      _completedOperations.add(operation);
      if (_completedOperations.length > 1000) {
        _completedOperations.removeFirst();
      }
      
      // Check for performance issues
      if (operation.duration > _maxOperationDuration) {
        _reportViolation(
          violation: AsyncSafetyViolation.infiniteLoop,
          level: SafetyLevel.warning,
          message: 'Long-running operation (${operation.duration.inSeconds}s)',
          operationId: operationId,
          context: operation.context,
          metadata: {'duration': operation.duration.inMilliseconds},
        );
      }
    }
  }
  
  void failOperation(String operationId, Object error, StackTrace stackTrace) {
    final operation = _activeOperations.remove(operationId);
    if (operation != null) {
      operation.fail(error, stackTrace);
      _completedOperations.add(operation);
      
      // Report the error as a safety violation
      _reportViolation(
        violation: AsyncSafetyViolation.unhandledException,
        level: _categorizeError(error),
        message: 'Async operation failed: ${error.toString()}',
        operationId: operationId,
        context: operation.context,
        metadata: {'errorType': error.runtimeType.toString()},
        stackTrace: stackTrace,
      );
    }
  }
  
  void cancelOperation(String operationId) {
    final operation = _activeOperations.remove(operationId);
    if (operation != null) {
      operation.cancel();
      _completedOperations.add(operation);
    }
  }
  
  void reportStateAccessAfterDispose(String widgetType, String context) {
    _reportViolation(
      violation: AsyncSafetyViolation.unmountedStateAccess,
      level: SafetyLevel.danger,
      message: 'Attempted to access state after widget disposal in $widgetType',
      context: context,
      metadata: {'widgetType': widgetType},
    );
  }
  
  void reportPotentialDeadlock(List<String> operationIds, String context) {
    _reportViolation(
      violation: AsyncSafetyViolation.deadlock,
      level: SafetyLevel.critical,
      message: 'Potential deadlock detected involving ${operationIds.length} operations',
      context: context,
      metadata: {
        'operationIds': operationIds,
        'operationCount': operationIds.length,
      },
    );
  }
  
  void reportConcurrencyIssue(String type, String message, {String? context}) {
    _reportViolation(
      violation: AsyncSafetyViolation.concurrencyIssue,
      level: SafetyLevel.warning,
      message: '$type: $message',
      context: context,
      metadata: {'concurrencyType': type},
    );
  }
  
  void _performSafetyAudit() {
    try {
      _auditLongRunningOperations();
      _auditForDeadlocks();
      _auditResourceUsage();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Safety audit failed: $e');
        print('Stack trace: $stackTrace');
      }
    }
  }
  
  void _auditLongRunningOperations() {
    final stuckOperations = <AsyncOperation>[];
    
    _activeOperations.forEach((id, operation) {
      if (operation.duration > _maxOperationDuration) {
        stuckOperations.add(operation);
      }
    });
    
    if (stuckOperations.isNotEmpty) {
      for (final operation in stuckOperations) {
        _reportViolation(
          violation: AsyncSafetyViolation.infiniteLoop,
          level: SafetyLevel.danger,
          message: 'Operation stuck for ${operation.duration.inMinutes} minutes',
          operationId: operation.id,
          context: operation.context,
          metadata: {
            'type': operation.type,
            'startTime': operation.startTime.toIso8601String(),
            'duration': operation.duration.inMilliseconds,
          },
        );
      }
    }
  }
  
  void _auditForDeadlocks() {
    // Simple deadlock detection based on operation patterns
    final longRunningOps = _activeOperations.values
        .where((op) => op.duration > const Duration(minutes: 2))
        .toList();
    
    if (longRunningOps.length >= 3) {
      // Potential deadlock if multiple operations are stuck
      final operationIds = longRunningOps.map((op) => op.id).toList();
      
      _reportViolation(
        violation: AsyncSafetyViolation.deadlock,
        level: SafetyLevel.danger,
        message: 'Potential deadlock: ${longRunningOps.length} operations stuck',
        metadata: {
          'operationIds': operationIds,
          'operationTypes': longRunningOps.map((op) => op.type).toList(),
        },
      );
    }
  }
  
  void _auditResourceUsage() {
    final activeCount = _activeOperations.length;
    
    if (activeCount > _maxActiveOperations * 0.8) {
      _reportViolation(
        violation: AsyncSafetyViolation.resourceLeak,
        level: activeCount > _maxActiveOperations ? SafetyLevel.critical : SafetyLevel.warning,
        message: 'High async operation count: $activeCount active operations',
        metadata: {
          'activeOperations': activeCount,
          'maxOperations': _maxActiveOperations,
        },
      );
    }
    
    // Check for operations with excessive metadata (potential memory leak)
    for (final operation in _activeOperations.values) {
      final metadataSize = operation.metadata.toString().length;
      if (metadataSize > 10000) { // 10KB threshold
        _reportViolation(
          violation: AsyncSafetyViolation.memoryLeak,
          level: SafetyLevel.warning,
          message: 'Operation with excessive metadata size: ${metadataSize} bytes',
          operationId: operation.id,
          context: operation.context,
          metadata: {'metadataSize': metadataSize},
        );
      }
    }
  }
  
  void _reportViolation({
    required AsyncSafetyViolation violation,
    required SafetyLevel level,
    required String message,
    String? operationId,
    String? context,
    Map<String, dynamic>? metadata,
    StackTrace? stackTrace,
  }) {
    final report = SafetyViolationReport(
      id: 'violation_${DateTime.now().millisecondsSinceEpoch}_${violation.name}',
      timestamp: DateTime.now(),
      violation: violation,
      level: level,
      message: message,
      operationId: operationId,
      context: context,
      metadata: metadata ?? {},
      stackTrace: stackTrace,
    );
    
    // Add to state
    final updatedReports = [...state, report];
    if (updatedReports.length > _maxViolationReports) {
      updatedReports.removeRange(0, updatedReports.length - _maxViolationReports);
    }
    state = updatedReports;
    
    // Store persistently
    _storeViolationReport(report);
    
    // Log in debug mode
    if (kDebugMode) {
      print('🚨 Async Safety Violation: ${report.toString()}');
      if (level == SafetyLevel.critical) {
        print('❌ CRITICAL SAFETY VIOLATION - Immediate attention required!');
      }
    }
  }
  
  SafetyLevel _categorizeError(Object error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('timeout') || 
        errorString.contains('deadlock') ||
        errorString.contains('memory')) {
      return SafetyLevel.critical;
    } else if (errorString.contains('connection') ||
               errorString.contains('network') ||
               errorString.contains('permission')) {
      return SafetyLevel.danger;
    } else if (errorString.contains('validation') ||
               errorString.contains('format') ||
               errorString.contains('parse')) {
      return SafetyLevel.warning;
    }
    
    return SafetyLevel.warning;
  }
  
  Future<void> _storeViolationReport(SafetyViolationReport report) async {
    try {
      await _storage.setHiveData('safety_violations', report.id, report.toJson());
    } catch (e) {
      // Ignore storage failures
    }
  }
  
  void _cleanup() {
    // Remove old completed operations
    while (_completedOperations.length > 500) {
      _completedOperations.removeFirst();
    }
    
    // Remove old violation reports from storage
    _cleanupOldViolations();
  }
  
  Future<void> _cleanupOldViolations() async {
    try {
      final violationIds = _storage.getHiveKeys('safety_violations');
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
      
      for (final id in violationIds) {
        try {
          final violationData = _storage.getHiveData<Map<String, dynamic>>('safety_violations', id);
          if (violationData != null) {
            final timestamp = DateTime.parse(violationData['timestamp']);
            if (timestamp.isBefore(cutoffDate)) {
              await _storage.removeHiveData('safety_violations', id);
            }
          }
        } catch (e) {
          // Remove corrupted entries
          await _storage.removeHiveData('safety_violations', id);
        }
      }
    } catch (e) {
      // Ignore cleanup failures
    }
  }
  
  // Public API methods
  Map<String, AsyncOperation> get activeOperations => Map.from(_activeOperations);
  List<AsyncOperation> get recentOperations => _completedOperations.toList();
  
  int get activeOperationCount => _activeOperations.length;
  int get totalOperationCount => _operationCounter;
  
  List<SafetyViolationReport> getViolationsByType(AsyncSafetyViolation violation) {
    return state.where((report) => report.violation == violation).toList();
  }
  
  List<SafetyViolationReport> getViolationsByLevel(SafetyLevel level) {
    return state.where((report) => report.level == level).toList();
  }
  
  Map<String, int> getSafetyViolationSummary() {
    final summary = <String, int>{};
    for (final report in state) {
      final key = '${report.violation.name}_${report.level.name}';
      summary[key] = (summary[key] ?? 0) + 1;
    }
    return summary;
  }
  
  bool get hasCriticalViolations => state.any((report) => report.level == SafetyLevel.critical);
  
  Future<void> forceCleanupStuckOperations() async {
    final stuckOperations = _activeOperations.values
        .where((op) => op.duration > _maxOperationDuration)
        .toList();
    
    for (final operation in stuckOperations) {
      cancelOperation(operation.id);
    }
    
    if (kDebugMode) {
      print('🧹 Cleaned up ${stuckOperations.length} stuck operations');
    }
  }
  
  Future<Map<String, dynamic>> exportSafetyReport() async {
    return {
      'exported_at': DateTime.now().toIso8601String(),
      'active_operations': activeOperationCount,
      'total_operations': totalOperationCount,
      'total_violations': state.length,
      'critical_violations': hasCriticalViolations,
      'violation_summary': getSafetyViolationSummary(),
      'violations': state.map((report) => report.toJson()).toList(),
      'active_operations_details': _activeOperations.values
          .map((op) => op.toJson())
          .toList(),
    };
  }
  
  @override
  void dispose() {
    _auditTimer?.cancel();
    _cleanupTimer?.cancel();
    super.dispose();
  }
}

// Provider for async safety auditor
final asyncSafetyAuditorProvider = StateNotifierProvider<AsyncSafetyAuditor, List<SafetyViolationReport>>((ref) {
  final storage = DesktopStorageService.instance;
  return AsyncSafetyAuditor(storage);
});

// Helper class for safe async operations in ConsumerWidgets
class SafeAsyncHelper {
  final AsyncSafetyAuditor _auditor;
  final Map<String, String> _trackedOperations = {};
  
  SafeAsyncHelper(this._auditor);
  
  Future<R> safeAsync<R>(
    Future<R> Function() operation, {
    required bool isMounted,
    String? operationType,
    String? context,
    Map<String, dynamic>? metadata,
  }) async {
    if (!isMounted) {
      _auditor.reportStateAccessAfterDispose('Widget', context ?? 'safeAsync');
      throw StateError('Widget is no longer mounted');
    }
    
    final operationId = _auditor.trackAsyncOperation(
      operationType ?? 'Future<$R>',
      context: context ?? 'SafeAsync',
      metadata: metadata,
    );
    
    _trackedOperations[operationType ?? 'async'] = operationId;
    
    try {
      final result = await operation();
      
      if (!isMounted) {
        _auditor.reportStateAccessAfterDispose('Widget', context ?? 'safeAsync_completion');
        throw StateError('Widget was disposed during async operation');
      }
      
      _auditor.completeOperation(operationId, result);
      _trackedOperations.remove(operationType ?? 'async');
      
      return result;
    } catch (error, stackTrace) {
      _auditor.failOperation(operationId, error, stackTrace);
      _trackedOperations.remove(operationType ?? 'async');
      rethrow;
    }
  }
  
  void dispose() {
    // Cancel all tracked operations
    for (final operationId in _trackedOperations.values) {
      _auditor.cancelOperation(operationId);
    }
    _trackedOperations.clear();
  }
}