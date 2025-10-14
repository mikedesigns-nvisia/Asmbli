import 'package:json_annotation/json_annotation.dart';
import 'logic_block.dart';

part 'reasoning_workflow.g.dart';

/// Complete visual reasoning workflow that can be compiled to LangGraph
@JsonSerializable()
class ReasoningWorkflow {
  final String id;
  final String name;
  final String? description;
  final List<LogicBlock> blocks;
  final List<BlockConnection> connections;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const ReasoningWorkflow({
    required this.id,
    required this.name,
    this.description,
    required this.blocks,
    required this.connections,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory ReasoningWorkflow.fromJson(Map<String, dynamic> json) => _$ReasoningWorkflowFromJson(json);
  Map<String, dynamic> toJson() => _$ReasoningWorkflowToJson(this);
  
  ReasoningWorkflow copyWith({
    String? id,
    String? name,
    String? description,
    List<LogicBlock>? blocks,
    List<BlockConnection>? connections,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReasoningWorkflow(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      blocks: blocks ?? this.blocks,
      connections: connections ?? this.connections,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  /// Create empty workflow
  factory ReasoningWorkflow.empty() {
    final now = DateTime.now();
    return ReasoningWorkflow(
      id: 'workflow_${now.millisecondsSinceEpoch}',
      name: 'New Reasoning Flow',
      blocks: [],
      connections: [],
      createdAt: now,
      updatedAt: now,
    );
  }
  
  /// Get all blocks of a specific type
  List<LogicBlock> getBlocksByType(LogicBlockType type) {
    return blocks.where((block) => block.type == type).toList();
  }
  
  /// Get connections from a specific block
  List<BlockConnection> getConnectionsFrom(String blockId) {
    return connections.where((conn) => conn.sourceBlockId == blockId).toList();
  }
  
  /// Get connections to a specific block
  List<BlockConnection> getConnectionsTo(String blockId) {
    return connections.where((conn) => conn.targetBlockId == blockId).toList();
  }
  
  /// Check if workflow has required blocks for basic reasoning
  bool get isValid {
    final goalBlocks = getBlocksByType(LogicBlockType.goal);
    final exitBlocks = getBlocksByType(LogicBlockType.exit);
    
    // Must have at least one goal and one exit
    return goalBlocks.isNotEmpty && exitBlocks.isNotEmpty;
  }
  
  /// Get workflow complexity score (for UI hints)
  int get complexityScore {
    return blocks.length + connections.length;
  }
  
  /// Check if workflow can compile to executable format
  ValidationResult validate() {
    final errors = <String>[];
    final warnings = <String>[];
    
    // Check required blocks
    if (getBlocksByType(LogicBlockType.goal).isEmpty) {
      errors.add('Workflow must have at least one Goal block');
    }
    
    if (getBlocksByType(LogicBlockType.exit).isEmpty) {
      errors.add('Workflow must have at least one Exit block');
    }
    
    // Check for orphaned blocks
    for (final block in blocks) {
      final hasIncoming = getConnectionsTo(block.id).isNotEmpty;
      final hasOutgoing = getConnectionsFrom(block.id).isNotEmpty;
      
      if (!hasIncoming && !hasOutgoing && blocks.length > 1) {
        warnings.add('Block "${block.label}" is not connected to the workflow');
      }
    }
    
    // Check for circular dependencies in data flow
    if (_hasCircularDataFlow()) {
      errors.add('Workflow contains circular data dependencies');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
  
  /// Check for circular dependencies in data flow (execution flow can have cycles)
  bool _hasCircularDataFlow() {
    final dataConnections = connections.where((c) => c.type == ConnectionType.data);
    final visited = <String>{};
    final recursionStack = <String>{};
    
    bool hasCycle(String blockId) {
      if (recursionStack.contains(blockId)) return true;
      if (visited.contains(blockId)) return false;
      
      visited.add(blockId);
      recursionStack.add(blockId);
      
      for (final connection in dataConnections) {
        if (connection.sourceBlockId == blockId) {
          if (hasCycle(connection.targetBlockId)) return true;
        }
      }
      
      recursionStack.remove(blockId);
      return false;
    }
    
    for (final block in blocks) {
      if (hasCycle(block.id)) return true;
    }
    
    return false;
  }
  
  /// Convert to simple execution order (for Phase 1 - no LangGraph compilation yet)
  List<LogicBlock> getExecutionOrder() {
    final ordered = <LogicBlock>[];
    final processed = <String>{};
    
    // Start with goal blocks
    final goalBlocks = getBlocksByType(LogicBlockType.goal);
    for (final goal in goalBlocks) {
      _addBlockAndDependencies(goal, ordered, processed);
    }
    
    return ordered;
  }
  
  void _addBlockAndDependencies(LogicBlock block, List<LogicBlock> ordered, Set<String> processed) {
    if (processed.contains(block.id)) return;
    
    // Add dependencies first (blocks that feed into this one)
    final incomingConnections = getConnectionsTo(block.id);
    for (final connection in incomingConnections) {
      final sourceBlock = blocks.firstWhere((b) => b.id == connection.sourceBlockId);
      _addBlockAndDependencies(sourceBlock, ordered, processed);
    }
    
    // Add this block
    ordered.add(block);
    processed.add(block.id);
  }
}

/// Workflow validation result
@JsonSerializable()
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  
  const ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });
  
  factory ValidationResult.fromJson(Map<String, dynamic> json) => _$ValidationResultFromJson(json);
  Map<String, dynamic> toJson() => _$ValidationResultToJson(this);
}