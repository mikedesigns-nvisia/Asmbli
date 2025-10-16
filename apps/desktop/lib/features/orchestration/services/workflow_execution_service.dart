import 'dart:async';
import 'package:uuid/uuid.dart';

import '../models/logic_block.dart';
import '../models/reasoning_workflow.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/llm/unified_llm_service.dart';
import '../../../core/services/business/agent_business_service.dart';

/// Execution state for a single workflow run
enum WorkflowExecutionState {
  pending,    // Not started
  running,    // Currently executing
  completed,  // Finished successfully
  failed,     // Failed with error
  cancelled,  // Cancelled by user
}

/// Execution state for individual blocks
enum BlockExecutionState {
  pending,    // Waiting to execute
  active,     // Currently executing
  completed,  // Finished successfully
  failed,     // Failed with error
  skipped,    // Skipped due to conditions
}

/// Result of executing a single logic block
class BlockExecutionResult {
  final String blockId;
  final BlockExecutionState state;
  final Map<String, dynamic> outputs;
  final String? error;
  final Duration executionTime;
  final DateTime timestamp;

  const BlockExecutionResult({
    required this.blockId,
    required this.state,
    required this.outputs,
    this.error,
    required this.executionTime,
    required this.timestamp,
  });

  factory BlockExecutionResult.success({
    required String blockId,
    required Map<String, dynamic> outputs,
    required Duration executionTime,
  }) {
    return BlockExecutionResult(
      blockId: blockId,
      state: BlockExecutionState.completed,
      outputs: outputs,
      executionTime: executionTime,
      timestamp: DateTime.now(),
    );
  }

  factory BlockExecutionResult.failure({
    required String blockId,
    required String error,
    required Duration executionTime,
  }) {
    return BlockExecutionResult(
      blockId: blockId,
      state: BlockExecutionState.failed,
      outputs: {},
      error: error,
      executionTime: executionTime,
      timestamp: DateTime.now(),
    );
  }
}

/// Complete execution context for a workflow run
class WorkflowExecutionContext {
  final String executionId;
  final String workflowId;
  final String agentId;
  final String userId;
  final Map<String, dynamic> inputs;
  final DateTime startTime;
  DateTime? endTime;
  WorkflowExecutionState state;
  final List<BlockExecutionResult> blockResults;
  final Map<String, dynamic> globalVariables;
  String? error;

  WorkflowExecutionContext({
    required this.executionId,
    required this.workflowId,
    required this.agentId,
    required this.userId,
    required this.inputs,
    required this.startTime,
    this.endTime,
    this.state = WorkflowExecutionState.pending,
    this.blockResults = const [],
    this.globalVariables = const {},
    this.error,
  });

  Duration? get totalExecutionTime {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  Map<String, dynamic> get outputs {
    // Extract outputs from final blocks
    final exitBlocks = blockResults.where((r) => 
      r.state == BlockExecutionState.completed &&
      r.outputs.containsKey('final_output')
    ).toList();
    
    if (exitBlocks.isNotEmpty) {
      return exitBlocks.last.outputs;
    }
    
    return {};
  }
}

/// Service for executing visual reasoning workflows
class WorkflowExecutionService {
  static WorkflowExecutionService? _instance;
  static WorkflowExecutionService get instance => _instance ??= WorkflowExecutionService._();
  WorkflowExecutionService._();

  final _uuid = const Uuid();
  final Map<String, WorkflowExecutionContext> _activeExecutions = {};
  final StreamController<WorkflowExecutionContext> _executionStream = StreamController.broadcast();

  /// Stream of workflow execution updates
  Stream<WorkflowExecutionContext> get executionUpdates => _executionStream.stream;

  /// Execute a complete reasoning workflow
  Future<WorkflowExecutionContext> executeWorkflow({
    required ReasoningWorkflow workflow,
    required String agentId,
    required String userId,
    required Map<String, dynamic> inputs,
  }) async {
    final executionId = _uuid.v4();
    
    print('🚀 Starting workflow execution: ${workflow.name} (ID: $executionId)');
    
    final context = WorkflowExecutionContext(
      executionId: executionId,
      workflowId: workflow.id,
      agentId: agentId,
      userId: userId,
      inputs: inputs,
      startTime: DateTime.now(),
    );

    _activeExecutions[executionId] = context;
    context.state = WorkflowExecutionState.running;
    _executionStream.add(context);

    try {
      // Validate workflow before execution
      _validateWorkflow(workflow);
      
      // Execute blocks in dependency order
      await _executeBlocks(workflow, context);
      
      context.state = WorkflowExecutionState.completed;
      context.endTime = DateTime.now();
      
      print('✅ Workflow execution completed: $executionId in ${context.totalExecutionTime}');
      
    } catch (e) {
      context.state = WorkflowExecutionState.failed;
      context.error = e.toString();
      context.endTime = DateTime.now();
      
      print('❌ Workflow execution failed: $executionId - $e');
    } finally {
      _executionStream.add(context);
      _activeExecutions.remove(executionId);
    }

    return context;
  }

  /// Execute blocks in the correct dependency order
  Future<void> _executeBlocks(ReasoningWorkflow workflow, WorkflowExecutionContext context) async {
    final executionOrder = _calculateExecutionOrder(workflow);
    
    print('📋 Execution order: ${executionOrder.map((b) => b.label).join(' → ')}');
    
    for (final block in executionOrder) {
      if (context.state != WorkflowExecutionState.running) {
        break; // Execution was cancelled
      }

      await _executeBlock(block, workflow, context);
    }
  }

  /// Execute a single logic block
  Future<void> _executeBlock(
    LogicBlock block, 
    ReasoningWorkflow workflow, 
    WorkflowExecutionContext context
  ) async {
    final startTime = DateTime.now();
    print('⚡ Executing block: ${block.label} (${block.type})');
    
    try {
      final inputs = _getBlockInputs(block, workflow, context);
      final outputs = await _processBlock(block, inputs, context);
      
      final result = BlockExecutionResult.success(
        blockId: block.id,
        outputs: outputs,
        executionTime: DateTime.now().difference(startTime),
      );
      
      context.blockResults.add(result);
      _executionStream.add(context);
      
      print('✅ Block completed: ${block.label}');
      
    } catch (e) {
      final result = BlockExecutionResult.failure(
        blockId: block.id,
        error: e.toString(),
        executionTime: DateTime.now().difference(startTime),
      );
      
      context.blockResults.add(result);
      _executionStream.add(context);
      
      print('❌ Block failed: ${block.label} - $e');
      throw e; // Propagate error to fail entire workflow
    }
  }

  /// Process a specific block type with appropriate logic
  Future<Map<String, dynamic>> _processBlock(
    LogicBlock block,
    Map<String, dynamic> inputs,
    WorkflowExecutionContext context,
  ) async {
    switch (block.type) {
      case LogicBlockType.goal:
        return _processGoalBlock(block, inputs, context);
      case LogicBlockType.context:
        return _processContextBlock(block, inputs, context);
      case LogicBlockType.gateway:
        return _processGatewayBlock(block, inputs, context);
      case LogicBlockType.reasoning:
        return _processReasoningBlock(block, inputs, context);
      case LogicBlockType.fallback:
        return _processFallbackBlock(block, inputs, context);
      case LogicBlockType.trace:
        return _processTraceBlock(block, inputs, context);
      case LogicBlockType.exit:
        return _processExitBlock(block, inputs, context);
    }
  }

  /// Goal Declaration: Define objectives and success criteria
  Future<Map<String, dynamic>> _processGoalBlock(
    LogicBlock block,
    Map<String, dynamic> inputs,
    WorkflowExecutionContext context,
  ) async {
    final goal = block.properties['goal'] as String? ?? block.label;
    final criteria = block.properties['success_criteria'] as List<String>? ?? [];
    
    return {
      'goal_defined': goal,
      'success_criteria': criteria,
      'goal_context': inputs,
    };
  }

  /// Context Filter: Retrieve and filter relevant information
  Future<Map<String, dynamic>> _processContextBlock(
    LogicBlock block,
    Map<String, dynamic> inputs,
    WorkflowExecutionContext context,
  ) async {
    // TODO: Integrate with vector database and context services
    final query = inputs['query'] as String? ?? context.inputs['message'] as String? ?? '';
    final filters = block.properties['filters'] as Map<String, dynamic>? ?? {};
    
    return {
      'filtered_context': 'Mock context for: $query',
      'relevance_score': 0.85,
      'context_sources': ['knowledge_base', 'conversation_history'],
    };
  }

  /// Decision Gateway: Route execution based on conditions
  Future<Map<String, dynamic>> _processGatewayBlock(
    LogicBlock block,
    Map<String, dynamic> inputs,
    WorkflowExecutionContext context,
  ) async {
    final condition = block.properties['condition'] as String? ?? 'default';
    final threshold = block.properties['confidence_threshold'] as double? ?? 0.7;
    
    // Mock decision logic - replace with actual LLM-based routing
    final confidence = (inputs['confidence'] as double?) ?? 0.8;
    final shouldProceed = confidence >= threshold;
    
    return {
      'decision': shouldProceed ? 'proceed' : 'fallback',
      'confidence': confidence,
      'condition_met': shouldProceed,
      'routing_path': shouldProceed ? 'main' : 'alternative',
    };
  }

  /// Reasoning Layer: Multi-step thinking and analysis
  Future<Map<String, dynamic>> _processReasoningBlock(
    LogicBlock block,
    Map<String, dynamic> inputs,
    WorkflowExecutionContext context,
  ) async {
    final llmService = ServiceLocator.instance.get<UnifiedLLMService>();
    final reasoningType = block.properties['reasoning_type'] as String? ?? 'chain_of_thought';
    
    final prompt = _buildReasoningPrompt(block, inputs, context);
    
    try {
      // Get model ID from context inputs if available
      final modelId = context.inputs['model_id'] as String?;
      
      final response = await llmService.generate(
        prompt: prompt,
        modelId: modelId,
      );
      
      return {
        'reasoning_output': response.content,
        'reasoning_type': reasoningType,
        'thinking_steps': _extractThinkingSteps(response.content),
      };
      
    } catch (e) {
      throw Exception('Reasoning failed: $e');
    }
  }

  /// Fallback Strategy: Handle errors and edge cases
  Future<Map<String, dynamic>> _processFallbackBlock(
    LogicBlock block,
    Map<String, dynamic> inputs,
    WorkflowExecutionContext context,
  ) async {
    final fallbackType = block.properties['fallback_type'] as String? ?? 'default_response';
    final fallbackMessage = block.properties['message'] as String? ?? 'I apologize, but I encountered an issue processing your request.';
    
    return {
      'fallback_triggered': true,
      'fallback_type': fallbackType,
      'fallback_response': fallbackMessage,
      'original_error': inputs['error'] ?? 'Unknown error',
    };
  }

  /// Trace Events: Log execution for debugging
  Future<Map<String, dynamic>> _processTraceBlock(
    LogicBlock block,
    Map<String, dynamic> inputs,
    WorkflowExecutionContext context,
  ) async {
    final traceData = {
      'execution_id': context.executionId,
      'block_id': block.id,
      'timestamp': DateTime.now().toIso8601String(),
      'inputs': inputs,
      'context_state': {
        'variables': context.globalVariables,
        'execution_time': DateTime.now().difference(context.startTime).inMilliseconds,
      },
    };
    
    print('📊 Trace: ${block.label} - ${traceData['timestamp']}');
    
    return {
      'trace_logged': true,
      'trace_data': traceData,
    };
  }

  /// Exit Condition: Evaluate completion and quality
  Future<Map<String, dynamic>> _processExitBlock(
    LogicBlock block,
    Map<String, dynamic> inputs,
    WorkflowExecutionContext context,
  ) async {
    final qualityThreshold = block.properties['quality_threshold'] as double? ?? 0.8;
    final outputQuality = inputs['quality_score'] as double? ?? 0.9;
    
    final isComplete = outputQuality >= qualityThreshold;
    final finalOutput = inputs['final_result'] ?? inputs['reasoning_output'] ?? 'Task completed';
    
    return {
      'workflow_complete': isComplete,
      'quality_score': outputQuality,
      'quality_threshold': qualityThreshold,
      'final_output': finalOutput,
      'execution_summary': {
        'total_blocks': context.blockResults.length,
        'execution_time': DateTime.now().difference(context.startTime).inMilliseconds,
      },
    };
  }

  /// Calculate the correct execution order based on dependencies
  List<LogicBlock> _calculateExecutionOrder(ReasoningWorkflow workflow) {
    // Simple topological sort based on connections
    final blocks = workflow.blocks.toList();
    final connections = workflow.connections;
    
    // Find entry point (Goal blocks or blocks with no incoming connections)
    final hasIncoming = connections.map((c) => c.targetBlockId).toSet();
    final entryBlocks = blocks.where((b) => !hasIncoming.contains(b.id) || b.type == LogicBlockType.goal).toList();
    
    if (entryBlocks.isEmpty) {
      // Fallback: return blocks in order added
      return blocks;
    }
    
    // TODO: Implement proper topological sort for complex workflows
    // For now, return simple linear order starting from entry points
    final ordered = <LogicBlock>[];
    final visited = <String>{};
    
    void visitBlock(LogicBlock block) {
      if (visited.contains(block.id)) return;
      visited.add(block.id);
      ordered.add(block);
      
      // Add connected blocks
      final outgoing = connections.where((c) => c.sourceBlockId == block.id);
      for (final connection in outgoing) {
        final nextBlock = blocks.firstWhere((b) => b.id == connection.targetBlockId);
        visitBlock(nextBlock);
      }
    }
    
    for (final entryBlock in entryBlocks) {
      visitBlock(entryBlock);
    }
    
    return ordered;
  }

  /// Get inputs for a specific block from previous block outputs
  Map<String, dynamic> _getBlockInputs(
    LogicBlock block,
    ReasoningWorkflow workflow,
    WorkflowExecutionContext context,
  ) {
    final inputs = <String, dynamic>{};
    
    // Add global context
    inputs.addAll(context.inputs);
    inputs.addAll(context.globalVariables);
    
    // Add outputs from connected blocks
    final incomingConnections = workflow.connections.where((c) => c.targetBlockId == block.id);
    for (final connection in incomingConnections) {
      final sourceResult = context.blockResults.firstWhere(
        (r) => r.blockId == connection.sourceBlockId,
        orElse: () => BlockExecutionResult(
          blockId: connection.sourceBlockId,
          state: BlockExecutionState.pending,
          outputs: {},
          executionTime: Duration.zero,
          timestamp: DateTime.now(),
        ),
      );
      
      if (sourceResult.state == BlockExecutionState.completed) {
        inputs.addAll(sourceResult.outputs);
      }
    }
    
    return inputs;
  }

  /// Build reasoning prompt for LLM processing
  String _buildReasoningPrompt(
    LogicBlock block,
    Map<String, dynamic> inputs,
    WorkflowExecutionContext context,
  ) {
    final goal = inputs['goal_defined'] ?? 'Complete the requested task';
    final contextInfo = inputs['filtered_context'] ?? '';
    final userMessage = context.inputs['message'] ?? '';
    
    return '''
Goal: $goal

Context: $contextInfo

User Request: $userMessage

Please provide step-by-step reasoning to address this request. Consider:
1. What are the key aspects of this request?
2. What information is most relevant?
3. What would be the best approach?
4. What potential issues should be considered?

Provide your reasoning in a clear, structured format.
    '''.trim();
  }

  /// Extract thinking steps from reasoning output
  List<String> _extractThinkingSteps(String reasoningOutput) {
    // Simple extraction - could be enhanced with better parsing
    final lines = reasoningOutput.split('\n').where((line) => line.trim().isNotEmpty).toList();
    return lines.where((line) => 
      line.contains(RegExp(r'^\d+\.')) || 
      line.startsWith('- ') ||
      line.startsWith('• ')
    ).toList();
  }

  /// Validate workflow before execution
  void _validateWorkflow(ReasoningWorkflow workflow) {
    if (workflow.blocks.isEmpty) {
      throw Exception('Workflow has no blocks to execute');
    }
    
    // Check for required block types
    final hasGoal = workflow.blocks.any((b) => b.type == LogicBlockType.goal);
    final hasExit = workflow.blocks.any((b) => b.type == LogicBlockType.exit);
    
    if (!hasGoal) {
      print('⚠️ Warning: Workflow has no Goal block - execution may be unpredictable');
    }
    
    if (!hasExit) {
      print('⚠️ Warning: Workflow has no Exit block - execution may not complete properly');
    }
  }

  /// Cancel a running workflow execution
  Future<void> cancelExecution(String executionId) async {
    final context = _activeExecutions[executionId];
    if (context != null) {
      context.state = WorkflowExecutionState.cancelled;
      context.endTime = DateTime.now();
      _executionStream.add(context);
      _activeExecutions.remove(executionId);
      
      print('🛑 Workflow execution cancelled: $executionId');
    }
  }

  /// Get active execution context
  WorkflowExecutionContext? getActiveExecution(String executionId) {
    return _activeExecutions[executionId];
  }

  /// Get all active executions
  List<WorkflowExecutionContext> getActiveExecutions() {
    return _activeExecutions.values.toList();
  }

  void dispose() {
    _executionStream.close();
    _activeExecutions.clear();
  }
}