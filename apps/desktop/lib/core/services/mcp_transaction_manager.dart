import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'desktop/desktop_storage_service.dart';
import 'desktop/desktop_service_provider.dart';
import '../models/mcp_transaction.dart';
import '../models/mcp_catalog_entry.dart';
import 'mcp_catalog_service.dart';
import 'secure_auth_service.dart';
import 'mcp_process_manager.dart';

/// Production-grade transactional state manager for MCP operations
/// Ensures atomic operations, rollback capability, and data consistency
class MCPTransactionManager {
  final DesktopStorageService _storageService;
  final MCPCatalogService _catalogService;
  final SecureAuthService _authService;
  final MCPProcessManager _processManager;
  final Map<String, MCPTransaction> _activeTransactions = {};
  final Map<String, List<MCPOperation>> _operationHistory = {};
  final _transactionController = StreamController<MCPTransactionEvent>.broadcast();
  
  static const String _transactionLogKey = 'mcp_transaction_log';
  static const int _maxRetryAttempts = 3;
  static const Duration _operationTimeout = Duration(seconds: 30);

  MCPTransactionManager(
    this._storageService,
    this._catalogService,
    this._authService,
    this._processManager,
  );

  /// Stream of transaction events for monitoring
  Stream<MCPTransactionEvent> get transactionEvents => _transactionController.stream;

  /// Start a new transaction
  Future<String> beginTransaction({
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    final transactionId = const Uuid().v4();
    final transaction = MCPTransaction(
      id: transactionId,
      description: description,
      startedAt: DateTime.now(),
      status: MCPTransactionStatus.active,
      metadata: metadata ?? {},
      operations: [],
    );

    _activeTransactions[transactionId] = transaction;
    _operationHistory[transactionId] = [];
    
    await _logTransaction(transaction);
    
    _transactionController.add(MCPTransactionEvent(
      type: MCPTransactionEventType.started,
      transaction: transaction,
    ));

    return transactionId;
  }

  /// Add operation to transaction
  Future<void> addOperation(
    String transactionId,
    MCPOperation operation,
  ) async {
    final transaction = _activeTransactions[transactionId];
    if (transaction == null) {
      throw MCPTransactionException('Transaction $transactionId not found');
    }

    if (transaction.status != MCPTransactionStatus.active) {
      throw MCPTransactionException(
        'Cannot add operation to ${transaction.status.name} transaction',
      );
    }

    // Add operation with timestamp
    final timestampedOperation = operation.copyWith(
      timestamp: DateTime.now(),
    );

    _operationHistory[transactionId]!.add(timestampedOperation);
    
    final updatedTransaction = transaction.copyWith(
      operations: List.from(transaction.operations)..add(timestampedOperation),
    );
    
    _activeTransactions[transactionId] = updatedTransaction;
    await _logTransaction(updatedTransaction);

    _transactionController.add(MCPTransactionEvent(
      type: MCPTransactionEventType.operationAdded,
      transaction: updatedTransaction,
      operation: timestampedOperation,
    ));
  }

  /// Execute transaction with atomic guarantee
  Future<MCPTransactionResult> executeTransaction(String transactionId) async {
    final transaction = _activeTransactions[transactionId];
    if (transaction == null) {
      return MCPTransactionResult.error('Transaction $transactionId not found');
    }

    if (transaction.status != MCPTransactionStatus.active) {
      return MCPTransactionResult.error(
        'Transaction is ${transaction.status.name}, cannot execute',
      );
    }

    // Mark transaction as executing
    final executingTransaction = transaction.copyWith(
      status: MCPTransactionStatus.executing,
    );
    _activeTransactions[transactionId] = executingTransaction;
    
    _transactionController.add(MCPTransactionEvent(
      type: MCPTransactionEventType.executing,
      transaction: executingTransaction,
    ));

    try {
      // Execute all operations with rollback capability
      final results = await _executeOperationsWithRollback(
        transactionId,
        transaction.operations,
      );

      // Mark transaction as completed
      final completedTransaction = executingTransaction.copyWith(
        status: MCPTransactionStatus.completed,
        completedAt: DateTime.now(),
        result: {'operations_executed': results.length},
      );
      
      _activeTransactions[transactionId] = completedTransaction;
      await _logTransaction(completedTransaction);
      
      _transactionController.add(MCPTransactionEvent(
        type: MCPTransactionEventType.completed,
        transaction: completedTransaction,
      ));

      return MCPTransactionResult.success(completedTransaction.result);
    } catch (e) {
      // Rollback on error
      await _rollbackTransaction(transactionId, e.toString());
      return MCPTransactionResult.error('Transaction failed: ${e.toString()}');
    }
  }

  /// Execute operations with atomic rollback capability
  Future<List<dynamic>> _executeOperationsWithRollback(
    String transactionId,
    List<MCPOperation> operations,
  ) async {
    final results = <dynamic>[];
    final completedOperations = <MCPOperation>[];

    try {
      for (final operation in operations) {
        final result = await _executeOperation(operation)
            .timeout(_operationTimeout);
        
        results.add(result);
        completedOperations.add(operation);
        
        _transactionController.add(MCPTransactionEvent(
          type: MCPTransactionEventType.operationCompleted,
          transaction: _activeTransactions[transactionId]!,
          operation: operation,
        ));
      }
      
      return results;
    } catch (e) {
      // Rollback completed operations in reverse order
      await _rollbackOperations(completedOperations.reversed.toList());
      rethrow;
    }
  }

  /// Execute individual operation with retry logic
  Future<dynamic> _executeOperation(MCPOperation operation) async {
    for (int attempt = 0; attempt < _maxRetryAttempts; attempt++) {
      try {
        switch (operation.type) {
          case MCPOperationType.serverEnable:
            return await _executeServerEnableOperation(operation);
          case MCPOperationType.serverDisable:
            return await _executeServerDisableOperation(operation);
          case MCPOperationType.credentialStore:
            return await _executeCredentialStoreOperation(operation);
          case MCPOperationType.credentialDelete:
            return await _executeCredentialDeleteOperation(operation);
          case MCPOperationType.configUpdate:
            return await _executeConfigUpdateOperation(operation);
        }
      } catch (e) {
        if (attempt == _maxRetryAttempts - 1) rethrow;
        await Future.delayed(Duration(milliseconds: 100 * (attempt + 1)));
      }
    }
    throw MCPTransactionException('Operation failed after $_maxRetryAttempts attempts');
  }

  /// Rollback transaction
  Future<void> _rollbackTransaction(String transactionId, String error) async {
    final transaction = _activeTransactions[transactionId];
    if (transaction == null) return;

    final operations = _operationHistory[transactionId] ?? [];
    await _rollbackOperations(operations.reversed.toList());

    final rolledBackTransaction = transaction.copyWith(
      status: MCPTransactionStatus.rolledBack,
      completedAt: DateTime.now(),
      error: error,
    );
    
    _activeTransactions[transactionId] = rolledBackTransaction;
    await _logTransaction(rolledBackTransaction);
    
    _transactionController.add(MCPTransactionEvent(
      type: MCPTransactionEventType.rolledBack,
      transaction: rolledBackTransaction,
    ));
  }

  /// Rollback operations in reverse order
  Future<void> _rollbackOperations(List<MCPOperation> operations) async {
    for (final operation in operations) {
      try {
        await _rollbackOperation(operation);
      } catch (e) {
        // Log rollback failure but continue with other operations
        print('Failed to rollback operation ${operation.id}: $e');
      }
    }
  }

  /// Rollback individual operation
  Future<void> _rollbackOperation(MCPOperation operation) async {
    switch (operation.type) {
      case MCPOperationType.serverEnable:
        // Disable the server
        if (operation.payload['agentId'] != null && operation.payload['serverId'] != null) {
          await _executeServerDisableOperation(MCPOperation(
            id: '${operation.id}_rollback',
            type: MCPOperationType.serverDisable,
            payload: {
              'agentId': operation.payload['agentId'],
              'serverId': operation.payload['serverId'],
            },
            timestamp: DateTime.now(),
          ));
        }
        break;
        
      case MCPOperationType.serverDisable:
        // Re-enable the server if we have the config
        if (operation.rollbackData != null) {
          await _executeServerEnableOperation(MCPOperation(
            id: '${operation.id}_rollback',
            type: MCPOperationType.serverEnable,
            payload: operation.rollbackData!,
            timestamp: DateTime.now(),
          ));
        }
        break;
        
      case MCPOperationType.credentialStore:
        // Delete the credential
        if (operation.payload['key'] != null) {
          await _executeCredentialDeleteOperation(MCPOperation(
            id: '${operation.id}_rollback',
            type: MCPOperationType.credentialDelete,
            payload: {'key': operation.payload['key']},
            timestamp: DateTime.now(),
          ));
        }
        break;
        
      case MCPOperationType.credentialDelete:
        // Restore the credential if we have backup
        if (operation.rollbackData != null) {
          await _executeCredentialStoreOperation(MCPOperation(
            id: '${operation.id}_rollback',
            type: MCPOperationType.credentialStore,
            payload: operation.rollbackData!,
            timestamp: DateTime.now(),
          ));
        }
        break;
        
      case MCPOperationType.configUpdate:
        // Restore previous config
        if (operation.rollbackData != null) {
          await _executeConfigUpdateOperation(MCPOperation(
            id: '${operation.id}_rollback',
            type: MCPOperationType.configUpdate,
            payload: operation.rollbackData!,
            timestamp: DateTime.now(),
          ));
        }
        break;
    }
  }

  // ==================== Operation Implementations ====================

  Future<dynamic> _executeServerEnableOperation(MCPOperation operation) async {
    try {
      final agentId = operation.payload['agentId'] as String;
      final serverId = operation.payload['serverId'] as String;
      final authConfig = operation.payload['authConfig'] as Map<String, String>? ?? {};
      
      // Enable server in catalog service
      await _catalogService.enableServerForAgent(agentId, serverId, authConfig);
      
      // Start the server process
      final serverProcess = await _processManager.startServer(
        id: serverId,
        agentId: agentId,
        credentials: authConfig,
      );
      
      return {
        'success': true,
        'serverId': serverId,
        'agentId': agentId,
        'processId': serverProcess.id,
        'status': serverProcess.isHealthy ? 'healthy' : 'unhealthy',
      };
    } catch (e) {
      throw Exception('Failed to enable server: $e');
    }
  }

  Future<dynamic> _executeServerDisableOperation(MCPOperation operation) async {
    try {
      final agentId = operation.payload['agentId'] as String;
      final serverId = operation.payload['serverId'] as String;
      final processId = '$agentId:$serverId';
      
      // Stop the server process
      final stopped = await _processManager.stopServer(processId);
      
      // Disable server in catalog service
      await _catalogService.disableServerForAgent(agentId, serverId);
      
      return {
        'success': true,
        'serverId': serverId,
        'agentId': agentId,
        'stopped': stopped,
      };
    } catch (e) {
      throw Exception('Failed to disable server: $e');
    }
  }

  Future<dynamic> _executeCredentialStoreOperation(MCPOperation operation) async {
    try {
      final key = operation.payload['key'] as String;
      final value = operation.payload['value'] as String;
      final ttl = operation.payload['ttl'] != null 
          ? Duration(seconds: operation.payload['ttl'] as int)
          : null;
      
      await _authService.storeCredential(key, value, ttl: ttl);
      
      return {
        'success': true,
        'key': key,
        'stored_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to store credential: $e');
    }
  }

  Future<dynamic> _executeCredentialDeleteOperation(MCPOperation operation) async {
    try {
      final key = operation.payload['key'] as String;
      
      await _authService.deleteCredential(key);
      
      return {
        'success': true,
        'key': key,
        'deleted_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to delete credential: $e');
    }
  }

  Future<dynamic> _executeConfigUpdateOperation(MCPOperation operation) async {
    try {
      final agentId = operation.payload['agentId'] as String;
      final serverId = operation.payload['serverId'] as String;
      final config = operation.payload['config'] as Map<String, dynamic>;
      
      // Update server configuration
      await _catalogService.updateAgentServerConfig(
        agentId,
        serverId,
        AgentMCPServerConfig.fromJson(config),
      );
      
      return {
        'success': true,
        'agentId': agentId,
        'serverId': serverId,
        'updated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to update config: $e');
    }
  }

  // ==================== Transaction Logging ====================

  Future<void> _logTransaction(MCPTransaction transaction) async {
    try {
      final existingLog = _storageService.getPreference<String>(_transactionLogKey) ?? '{}';
      final Map<String, dynamic> log = json.decode(existingLog);
      
      log[transaction.id] = transaction.toJson();
      
      await _storageService.setPreference(_transactionLogKey, json.encode(log));
    } catch (e) {
      print('Failed to log transaction: $e');
    }
  }

  /// Get transaction by ID
  MCPTransaction? getTransaction(String transactionId) {
    return _activeTransactions[transactionId];
  }

  /// Get all active transactions
  List<MCPTransaction> getActiveTransactions() {
    return _activeTransactions.values
        .where((t) => t.status == MCPTransactionStatus.active)
        .toList();
  }

  /// Clean up completed transactions older than specified duration
  Future<void> cleanupCompletedTransactions({
    Duration maxAge = const Duration(hours: 24),
  }) async {
    final cutoff = DateTime.now().subtract(maxAge);
    final toRemove = <String>[];

    for (final entry in _activeTransactions.entries) {
      final transaction = entry.value;
      if (transaction.status != MCPTransactionStatus.active &&
          transaction.completedAt != null &&
          transaction.completedAt!.isBefore(cutoff)) {
        toRemove.add(entry.key);
      }
    }

    for (final id in toRemove) {
      _activeTransactions.remove(id);
      _operationHistory.remove(id);
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _transactionController.close();
    _activeTransactions.clear();
    _operationHistory.clear();
  }
}

/// Transaction exception
class MCPTransactionException implements Exception {
  final String message;
  MCPTransactionException(this.message);

  @override
  String toString() => 'MCPTransactionException: $message';
}

/// Transaction result
class MCPTransactionResult {
  final bool isSuccess;
  final Map<String, dynamic>? data;
  final String? error;

  const MCPTransactionResult({
    required this.isSuccess,
    this.data,
    this.error,
  });

  factory MCPTransactionResult.success(Map<String, dynamic>? data) {
    return MCPTransactionResult(
      isSuccess: true,
      data: data,
    );
  }

  factory MCPTransactionResult.error(String error) {
    return MCPTransactionResult(
      isSuccess: false,
      error: error,
    );
  }
}

// ==================== Riverpod Provider ====================

final mcpTransactionManagerProvider = Provider<MCPTransactionManager>((ref) {
  final storageService = ref.read(desktopStorageServiceProvider);
  final catalogService = ref.read(mcpCatalogServiceProvider);
  final authService = ref.read(secureAuthServiceProvider);
  final processManager = ref.read(mcpProcessManagerProvider);
  return MCPTransactionManager(storageService, catalogService, authService, processManager);
});