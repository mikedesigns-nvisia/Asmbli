import 'package:equatable/equatable.dart';

/// Transaction status enumeration
enum MCPTransactionStatus {
  active('Active', 'Transaction is currently being built'),
  executing('Executing', 'Transaction is being executed'),
  completed('Completed', 'Transaction completed successfully'),
  rolledBack('Rolled Back', 'Transaction was rolled back due to error'),
  failed('Failed', 'Transaction failed and could not be rolled back');

  const MCPTransactionStatus(this.displayName, this.description);

  final String displayName;
  final String description;

  bool get isActive => this == MCPTransactionStatus.active;
  bool get isExecuting => this == MCPTransactionStatus.executing;
  bool get isCompleted => this == MCPTransactionStatus.completed;
  bool get isFailed => this == MCPTransactionStatus.failed || this == MCPTransactionStatus.rolledBack;
}

/// MCP operation types
enum MCPOperationType {
  serverEnable('Server Enable', 'Enable MCP server for agent'),
  serverDisable('Server Disable', 'Disable MCP server for agent'),
  credentialStore('Credential Store', 'Store encrypted credential'),
  credentialDelete('Credential Delete', 'Delete stored credential'),
  configUpdate('Config Update', 'Update configuration data');

  const MCPOperationType(this.displayName, this.description);

  final String displayName;
  final String description;
}

/// Individual operation within a transaction
class MCPOperation extends Equatable {
  final String id;
  final MCPOperationType type;
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  final Map<String, dynamic>? rollbackData;
  final String? description;

  const MCPOperation({
    required this.id,
    required this.type,
    required this.payload,
    required this.timestamp,
    this.rollbackData,
    this.description,
  });

  /// Create a copy with updated values
  MCPOperation copyWith({
    String? id,
    MCPOperationType? type,
    Map<String, dynamic>? payload,
    DateTime? timestamp,
    Map<String, dynamic>? rollbackData,
    String? description,
  }) {
    return MCPOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      timestamp: timestamp ?? this.timestamp,
      rollbackData: rollbackData ?? this.rollbackData,
      description: description ?? this.description,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
      'rollbackData': rollbackData,
      'description': description,
    };
  }

  /// Create from JSON
  factory MCPOperation.fromJson(Map<String, dynamic> json) {
    return MCPOperation(
      id: json['id'],
      type: MCPOperationType.values.firstWhere(
        (t) => t.name == json['type'],
      ),
      payload: Map<String, dynamic>.from(json['payload']),
      timestamp: DateTime.parse(json['timestamp']),
      rollbackData: json['rollbackData'] != null 
          ? Map<String, dynamic>.from(json['rollbackData'])
          : null,
      description: json['description'],
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    payload,
    timestamp,
    rollbackData,
    description,
  ];
}

/// Transaction containing multiple operations
class MCPTransaction extends Equatable {
  final String id;
  final String description;
  final DateTime startedAt;
  final DateTime? completedAt;
  final MCPTransactionStatus status;
  final List<MCPOperation> operations;
  final Map<String, dynamic> metadata;
  final Map<String, dynamic>? result;
  final String? error;

  const MCPTransaction({
    required this.id,
    required this.description,
    required this.startedAt,
    this.completedAt,
    required this.status,
    required this.operations,
    required this.metadata,
    this.result,
    this.error,
  });

  /// Create a copy with updated values
  MCPTransaction copyWith({
    String? id,
    String? description,
    DateTime? startedAt,
    DateTime? completedAt,
    MCPTransactionStatus? status,
    List<MCPOperation>? operations,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? result,
    String? error,
  }) {
    return MCPTransaction(
      id: id ?? this.id,
      description: description ?? this.description,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      operations: operations ?? this.operations,
      metadata: metadata ?? this.metadata,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }

  /// Get transaction duration
  Duration get duration {
    final endTime = completedAt ?? DateTime.now();
    return endTime.difference(startedAt);
  }

  /// Check if transaction has operations
  bool get hasOperations => operations.isNotEmpty;

  /// Get operation count by type
  Map<MCPOperationType, int> get operationCountsByType {
    final counts = <MCPOperationType, int>{};
    for (final operation in operations) {
      counts[operation.type] = (counts[operation.type] ?? 0) + 1;
    }
    return counts;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'status': status.name,
      'operations': operations.map((op) => op.toJson()).toList(),
      'metadata': metadata,
      'result': result,
      'error': error,
    };
  }

  /// Create from JSON
  factory MCPTransaction.fromJson(Map<String, dynamic> json) {
    return MCPTransaction(
      id: json['id'],
      description: json['description'],
      startedAt: DateTime.parse(json['startedAt']),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'])
          : null,
      status: MCPTransactionStatus.values.firstWhere(
        (s) => s.name == json['status'],
      ),
      operations: (json['operations'] as List)
          .map((op) => MCPOperation.fromJson(op))
          .toList(),
      metadata: Map<String, dynamic>.from(json['metadata']),
      result: json['result'] != null 
          ? Map<String, dynamic>.from(json['result'])
          : null,
      error: json['error'],
    );
  }

  @override
  List<Object?> get props => [
    id,
    description,
    startedAt,
    completedAt,
    status,
    operations,
    metadata,
    result,
    error,
  ];
}

/// Transaction event types
enum MCPTransactionEventType {
  started('Transaction Started'),
  operationAdded('Operation Added'),
  executing('Transaction Executing'),
  operationCompleted('Operation Completed'),
  completed('Transaction Completed'),
  rolledBack('Transaction Rolled Back'),
  failed('Transaction Failed');

  const MCPTransactionEventType(this.displayName);

  final String displayName;
}

/// Transaction event for monitoring
class MCPTransactionEvent extends Equatable {
  final MCPTransactionEventType type;
  final MCPTransaction transaction;
  final MCPOperation? operation;
  final DateTime timestamp;

  MCPTransactionEvent({
    required this.type,
    required this.transaction,
    this.operation,
  }) : timestamp = DateTime.now();

  @override
  List<Object?> get props => [
    type,
    transaction,
    operation,
    timestamp,
  ];
}