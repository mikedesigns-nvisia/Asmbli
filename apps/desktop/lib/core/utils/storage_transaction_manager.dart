import 'dart:async';
import '../services/desktop/desktop_storage_service.dart';
import 'app_logger.dart';

class StorageTransaction {
  final String _transactionId;
  final List<StorageOperation> _operations = [];
  final List<RollbackOperation> _rollbackOperations = [];
  bool _isCommitted = false;
  bool _isRolledBack = false;
  
  StorageTransaction._(this._transactionId);
  
  String get transactionId => _transactionId;
  bool get isCompleted => _isCommitted || _isRolledBack;
  
  void addOperation(StorageOperation operation) {
    if (isCompleted) {
      throw StateError('Cannot add operations to completed transaction');
    }
    _operations.add(operation);
  }
  
  void _addRollbackOperation(RollbackOperation operation) {
    _rollbackOperations.insert(0, operation); // Insert at beginning for reverse order
  }
  
  Future<TransactionResult> commit() async {
    if (isCompleted) {
      throw StateError('Transaction already completed');
    }
    
    final errors = <String>[];
    
    try {
      // Execute all operations
      for (final operation in _operations) {
        final result = await operation.execute();
        if (!result.success) {
          errors.add('Operation ${operation.type.name} failed: ${result.error}');
          break;
        }
        
        // Store rollback operation
        if (result.rollbackOperation != null) {
          _addRollbackOperation(result.rollbackOperation!);
        }
      }
      
      if (errors.isEmpty) {
        _isCommitted = true;
        return TransactionResult.success(_transactionId);
      } else {
        // Rollback executed operations
        await _executeRollback();
        return TransactionResult.failure(_transactionId, errors);
      }
    } catch (e) {
      errors.add('Transaction execution error: $e');
      
      // Attempt rollback for any executed operations
      try {
        await _executeRollback();
      } catch (rollbackError) {
        errors.add('Rollback failed: $rollbackError');
      }
      
      return TransactionResult.failure(_transactionId, errors);
    }
  }
  
  Future<void> rollback() async {
    if (_isCommitted) {
      throw StateError('Cannot rollback committed transaction');
    }
    if (_isRolledBack) {
      return; // Already rolled back
    }
    
    await _executeRollback();
  }
  
  Future<void> _executeRollback() async {
    final rollbackErrors = <String>[];
    
    for (final rollbackOp in _rollbackOperations) {
      try {
        await rollbackOp.execute();
      } catch (e) {
        rollbackErrors.add('Rollback operation failed: $e');
      }
    }
    
    _isRolledBack = true;
    
    if (rollbackErrors.isNotEmpty) {
      throw Exception('Rollback completed with errors: ${rollbackErrors.join(', ')}');
    }
  }
}

abstract class StorageOperation {
  StorageOperationType get type;
  Future<OperationResult> execute();
}

class SetHiveDataOperation extends StorageOperation {
  final String boxName;
  final String key;
  final dynamic value;
  final StorageType storageType;
  
  SetHiveDataOperation({
    required this.boxName,
    required this.key,
    required this.value,
    this.storageType = StorageType.hive,
  });
  
  @override
  StorageOperationType get type => StorageOperationType.set;
  
  @override
  Future<OperationResult> execute() async {
    try {
      // Store backup of existing data for rollback
      dynamic existingData;
      try {
        switch (storageType) {
          case StorageType.hive:
            existingData = DesktopStorageService.instance.getHiveData(boxName, key);
            break;
          case StorageType.preferences:
            existingData = DesktopStorageService.instance.getPreference(key);
            break;
          case StorageType.file:
            // File storage fallback to preferences for now
            AppLogger.warning('File storage not implemented, falling back to preferences', component: 'Storage');
            existingData = DesktopStorageService.instance.getPreference(key);
            break;
          case StorageType.secure:
            // Secure storage fallback to preferences for now
            AppLogger.warning('Secure storage not implemented, falling back to preferences', component: 'Storage');
            existingData = DesktopStorageService.instance.getPreference(key);
            break;
        }
      } catch (e) {
        // If getting existing data fails, continue with null (new key)
        existingData = null;
      }
      
      // Execute the operation
      switch (storageType) {
        case StorageType.hive:
          await DesktopStorageService.instance.setHiveData(boxName, key, value);
          break;
        case StorageType.preferences:
          await DesktopStorageService.instance.setPreference(key, value);
          break;
        case StorageType.file:
          // File storage fallback to preferences for now
          AppLogger.warning('File storage not implemented, storing in preferences instead', component: 'Storage');
          await DesktopStorageService.instance.setPreference(key, value);
          break;
        case StorageType.secure:
          // Secure storage fallback to preferences for now
          AppLogger.warning('Secure storage not implemented, storing in preferences instead', component: 'Storage');
          await DesktopStorageService.instance.setPreference(key, value);
          break;
      }
      
      // Create rollback operation
      final rollbackOp = existingData != null
        ? RestoreDataRollbackOperation(
            boxName: boxName,
            key: key,
            previousValue: existingData,
            storageType: storageType,
          )
        : RemoveDataRollbackOperation(
            boxName: boxName,
            key: key,
            storageType: storageType,
          );
      
      return OperationResult.success(rollbackOperation: rollbackOp);
    } catch (e) {
      return OperationResult.failure('Set operation failed: $e');
    }
  }
}

class RemoveHiveDataOperation extends StorageOperation {
  final String boxName;
  final String key;
  final StorageType storageType;
  
  RemoveHiveDataOperation({
    required this.boxName,
    required this.key,
    this.storageType = StorageType.hive,
  });
  
  @override
  StorageOperationType get type => StorageOperationType.remove;
  
  @override
  Future<OperationResult> execute() async {
    try {
      // Store backup of existing data for rollback
      dynamic existingData;
      try {
        switch (storageType) {
          case StorageType.hive:
            existingData = DesktopStorageService.instance.getHiveData(boxName, key);
            break;
          case StorageType.preferences:
            existingData = DesktopStorageService.instance.getPreference(key);
            break;
          case StorageType.file:
            // File storage fallback to preferences for now
            AppLogger.warning('File storage not implemented, falling back to preferences', component: 'Storage');
            existingData = DesktopStorageService.instance.getPreference(key);
            break;
          case StorageType.secure:
            // Secure storage fallback to preferences for now
            AppLogger.warning('Secure storage not implemented, falling back to preferences', component: 'Storage');
            existingData = DesktopStorageService.instance.getPreference(key);
            break;
        }
      } catch (e) {
        return OperationResult.failure('Failed to backup data before removal: $e');
      }
      
      if (existingData == null) {
        // Nothing to remove, but operation succeeds
        return OperationResult.success();
      }
      
      // Execute removal
      switch (storageType) {
        case StorageType.hive:
          await DesktopStorageService.instance.removeHiveData(boxName, key);
          break;
        case StorageType.preferences:
          await DesktopStorageService.instance.removePreference(key);
          break;
        case StorageType.file:
          // File storage fallback to preferences for now
          AppLogger.warning('File storage not implemented, removing from preferences instead', component: 'Storage');
          await DesktopStorageService.instance.removePreference(key);
          break;
        case StorageType.secure:
          // Secure storage fallback to preferences for now
          AppLogger.warning('Secure storage not implemented, removing from preferences instead', component: 'Storage');
          await DesktopStorageService.instance.removePreference(key);
          break;
      }
      
      // Create rollback operation to restore data
      final rollbackOp = RestoreDataRollbackOperation(
        boxName: boxName,
        key: key,
        previousValue: existingData,
        storageType: storageType,
      );
      
      return OperationResult.success(rollbackOperation: rollbackOp);
    } catch (e) {
      return OperationResult.failure('Remove operation failed: $e');
    }
  }
}

class ClearHiveBoxOperation extends StorageOperation {
  final String boxName;
  final StorageType storageType;
  
  ClearHiveBoxOperation({
    required this.boxName,
    this.storageType = StorageType.hive,
  });
  
  @override
  StorageOperationType get type => StorageOperationType.clear;
  
  @override
  Future<OperationResult> execute() async {
    try {
      // Backup all existing data for rollback
      Map<String, dynamic> existingData;
      
      switch (storageType) {
        case StorageType.hive:
          existingData = DesktopStorageService.instance.getAllHiveData(boxName);
          await DesktopStorageService.instance.clearHiveBox(boxName);
          break;
        case StorageType.preferences:
          // For preferences, we need to backup all keys - for now, just warn and skip
          AppLogger.warning('Clear all preferences not implemented - operation skipped', component: 'Storage');
          existingData = <String, dynamic>{}; // Empty backup
          break;
        case StorageType.file:
          // File storage fallback - just warn and skip for now
          AppLogger.warning('File storage clear not implemented - operation skipped', component: 'Storage');
          existingData = <String, dynamic>{}; // Empty backup
          break;
        case StorageType.secure:
          // Secure storage fallback - just warn and skip for now
          AppLogger.warning('Secure storage clear not implemented - operation skipped', component: 'Storage');
          existingData = <String, dynamic>{}; // Empty backup
          break;
      }
      
      // Create rollback operation to restore all data
      final rollbackOp = RestoreAllDataRollbackOperation(
        boxName: boxName,
        allData: existingData,
        storageType: storageType,
      );
      
      return OperationResult.success(rollbackOperation: rollbackOp);
    } catch (e) {
      return OperationResult.failure('Clear operation failed: $e');
    }
  }
}

abstract class RollbackOperation {
  Future<void> execute();
}

class RestoreDataRollbackOperation extends RollbackOperation {
  final String boxName;
  final String key;
  final dynamic previousValue;
  final StorageType storageType;
  
  RestoreDataRollbackOperation({
    required this.boxName,
    required this.key,
    required this.previousValue,
    required this.storageType,
  });
  
  @override
  Future<void> execute() async {
    switch (storageType) {
      case StorageType.hive:
        await DesktopStorageService.instance.setHiveData(boxName, key, previousValue);
        break;
      case StorageType.preferences:
        await DesktopStorageService.instance.setPreference(key, previousValue);
        break;
      case StorageType.file:
        // File storage fallback to preferences for rollback
        AppLogger.warning('File storage rollback not implemented, using preferences fallback', component: 'Storage');
        await DesktopStorageService.instance.setPreference(key, previousValue);
        break;
      case StorageType.secure:
        // Secure storage fallback to preferences for rollback
        AppLogger.warning('Secure storage rollback not implemented, using preferences fallback', component: 'Storage');
        await DesktopStorageService.instance.setPreference(key, previousValue);
        break;
    }
  }
}

class RemoveDataRollbackOperation extends RollbackOperation {
  final String boxName;
  final String key;
  final StorageType storageType;
  
  RemoveDataRollbackOperation({
    required this.boxName,
    required this.key,
    required this.storageType,
  });
  
  @override
  Future<void> execute() async {
    switch (storageType) {
      case StorageType.hive:
        await DesktopStorageService.instance.removeHiveData(boxName, key);
        break;
      case StorageType.preferences:
        await DesktopStorageService.instance.removePreference(key);
        break;
      case StorageType.file:
        // File storage fallback to preferences for removal rollback
        AppLogger.warning('File storage removal rollback not implemented, using preferences fallback', component: 'Storage');
        await DesktopStorageService.instance.removePreference(key);
        break;
      case StorageType.secure:
        // Secure storage fallback to preferences for removal rollback
        AppLogger.warning('Secure storage removal rollback not implemented, using preferences fallback', component: 'Storage');
        await DesktopStorageService.instance.removePreference(key);
        break;
    }
  }
}

class RestoreAllDataRollbackOperation extends RollbackOperation {
  final String boxName;
  final Map<String, dynamic> allData;
  final StorageType storageType;
  
  RestoreAllDataRollbackOperation({
    required this.boxName,
    required this.allData,
    required this.storageType,
  });
  
  @override
  Future<void> execute() async {
    switch (storageType) {
      case StorageType.hive:
        // Clear box first, then restore all data
        await DesktopStorageService.instance.clearHiveBox(boxName);
        for (final entry in allData.entries) {
          await DesktopStorageService.instance.setHiveData(boxName, entry.key, entry.value);
        }
        break;
      case StorageType.preferences:
        // For preferences, restore all data (limited fallback)
        AppLogger.warning('Preferences restore all not fully implemented - restoring what we can', component: 'Storage');
        for (final entry in allData.entries) {
          await DesktopStorageService.instance.setPreference(entry.key, entry.value);
        }
        break;
      case StorageType.file:
        // File storage fallback - just warn and skip restore
        AppLogger.warning('File storage restore all not implemented - operation skipped', component: 'Storage');
        break;
      case StorageType.secure:
        // Secure storage fallback - just warn and skip restore
        AppLogger.warning('Secure storage restore all not implemented - operation skipped', component: 'Storage');
        break;
    }
  }
}

class StorageTransactionManager {
  static const int _maxConcurrentTransactions = 10;
  static const Duration _defaultTimeout = Duration(minutes: 5);
  
  final Map<String, StorageTransaction> _activeTransactions = {};
  int _transactionCounter = 0;
  
  static final StorageTransactionManager _instance = StorageTransactionManager._();
  static StorageTransactionManager get instance => _instance;
  
  StorageTransactionManager._();
  
  StorageTransaction beginTransaction({Duration? timeout}) {
    if (_activeTransactions.length >= _maxConcurrentTransactions) {
      throw StateError('Maximum number of concurrent transactions exceeded');
    }
    
    final transactionId = 'txn_${++_transactionCounter}_${DateTime.now().millisecondsSinceEpoch}';
    final transaction = StorageTransaction._(transactionId);
    
    _activeTransactions[transactionId] = transaction;
    
    // Set up timeout
    final timeoutDuration = timeout ?? _defaultTimeout;
    Timer(timeoutDuration, () {
      if (!transaction.isCompleted && _activeTransactions.containsKey(transactionId)) {
        _handleTimeout(transaction);
      }
    });
    
    return transaction;
  }
  
  Future<void> _handleTimeout(StorageTransaction transaction) async {
    try {
      await transaction.rollback();
    } catch (e) {
      print('⚠️ Transaction timeout rollback failed: $e');
    }
    
    _activeTransactions.remove(transaction.transactionId);
    print('⏰ Transaction ${transaction.transactionId} timed out and was rolled back');
  }
  
  void _completeTransaction(String transactionId) {
    _activeTransactions.remove(transactionId);
  }
  
  Future<TransactionResult> executeTransaction(List<StorageOperation> operations, {Duration? timeout}) async {
    final transaction = beginTransaction(timeout: timeout);
    
    try {
      // Add all operations to transaction
      for (final operation in operations) {
        transaction.addOperation(operation);
      }
      
      // Commit transaction
      final result = await transaction.commit();
      _completeTransaction(transaction.transactionId);
      
      return result;
    } catch (e) {
      // Ensure rollback on any error
      try {
        await transaction.rollback();
      } catch (rollbackError) {
        print('⚠️ Transaction rollback failed: $rollbackError');
      }
      
      _completeTransaction(transaction.transactionId);
      return TransactionResult.failure(transaction.transactionId, ['Transaction failed: $e']);
    }
  }
  
  List<String> getActiveTransactionIds() {
    return _activeTransactions.keys.toList();
  }
  
  int get activeTransactionCount => _activeTransactions.length;
  
  Future<void> rollbackAllTransactions() async {
    final transactions = List<StorageTransaction>.from(_activeTransactions.values);
    
    for (final transaction in transactions) {
      try {
        await transaction.rollback();
      } catch (e) {
        print('⚠️ Failed to rollback transaction ${transaction.transactionId}: $e');
      }
    }
    
    _activeTransactions.clear();
  }
}

enum StorageOperationType {
  set,
  remove,
  clear,
}

class OperationResult {
  final bool success;
  final String? error;
  final RollbackOperation? rollbackOperation;
  
  const OperationResult._({
    required this.success,
    this.error,
    this.rollbackOperation,
  });
  
  factory OperationResult.success({RollbackOperation? rollbackOperation}) {
    return OperationResult._(success: true, rollbackOperation: rollbackOperation);
  }
  
  factory OperationResult.failure(String error) {
    return OperationResult._(success: false, error: error);
  }
}

class TransactionResult {
  final bool success;
  final String transactionId;
  final List<String> errors;
  
  const TransactionResult._({
    required this.success,
    required this.transactionId,
    required this.errors,
  });
  
  factory TransactionResult.success(String transactionId) {
    return TransactionResult._(success: true, transactionId: transactionId, errors: const []);
  }
  
  factory TransactionResult.failure(String transactionId, List<String> errors) {
    return TransactionResult._(success: false, transactionId: transactionId, errors: errors);
  }
}