import 'dart:async';

import '../models/reasoning_workflow.dart';
import '../models/logic_block.dart';
import '../models/canvas_state.dart';
import 'reasoning_llm_service.dart';
import '../../human_verification/services/human_verification_service.dart';

/// Execution engine for reasoning workflows
/// Orchestrates the execution of visual reasoning flows
class WorkflowExecutionEngine {
  final ReasoningLLMService _reasoningService;
  final HumanVerificationService _verificationService;
  final StreamController<ExecutionEvent> _eventController = StreamController.broadcast();
  
  WorkflowExecutionEngine(this._reasoningService, this._verificationService);
  
  /// Stream of execution events for real-time monitoring
  Stream<ExecutionEvent> get executionEvents => _eventController.stream;
  
  // Removed submitHumanVerification as it is now handled by HumanVerificationService
  
  /// Execute a complete reasoning workflow
  Future<WorkflowExecutionResult> executeWorkflow(
    ReasoningWorkflow workflow,
    String modelId, {
    Map<String, dynamic>? initialContext,
    ExecutionOptions? options,
  }) async {
    final executionId = 'exec_${DateTime.now().millisecondsSinceEpoch}';
    final startTime = DateTime.now();
    
    _emitEvent(ExecutionEvent.started(executionId, workflow.id));
    
    try {
      // Validate workflow before execution
      final validation = workflow.validate();
      if (!validation.isValid) {
        throw WorkflowExecutionException(
          'Workflow validation failed: ${validation.errors.join(', ')}',
        );
      }
      
      // Get execution order
      final executionOrder = workflow.getExecutionOrder();
      if (executionOrder.isEmpty) {
        throw WorkflowExecutionException('No blocks to execute');
      }
      
      // Initialize execution state
      var executionState = WorkflowExecutionState(
        workflowId: workflow.id,
        executionId: executionId,
        currentContext: initialContext ?? {},
        blockStates: {},
        completedBlocks: {},
        errors: [],
      );
      
      // Execute blocks in order
      for (final block in executionOrder) {
        if (executionState.shouldStopExecution) break;
        
        try {
          _emitEvent(ExecutionEvent.blockStarted(executionId, block.id, block.type));
          
          final result = await _executeBlock(
            block,
            workflow,
            modelId,
            executionState,
            options,
          );
          
          executionState = executionState.withBlockResult(block.id, result);
          
          _emitEvent(ExecutionEvent.blockCompleted(
            executionId,
            block.id,
            result.isSuccessful,
            result.confidence,
          ));
          
          // Check for early termination conditions
          if (_shouldTerminateEarly(block, result, options)) {
            _emitEvent(ExecutionEvent.earlyTermination(executionId, block.id, 'Confidence threshold met'));
            break;
          }
          
        } catch (e) {
          final error = BlockExecutionError(
            blockId: block.id,
            blockType: block.type,
            error: e.toString(),
            timestamp: DateTime.now(),
          );
          
          executionState = executionState.withError(error);
          
          _emitEvent(ExecutionEvent.blockError(executionId, block.id, e.toString()));
          
          // Decide whether to continue based on error handling strategy
          if (!_shouldContinueAfterError(block, error, options)) {
            break;
          }
        }
      }
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      final result = WorkflowExecutionResult(
        executionId: executionId,
        workflowId: workflow.id,
        state: executionState,
        isSuccessful: executionState.isSuccessful,
        duration: duration,
        startTime: startTime,
        endTime: endTime,
      );
      
      _emitEvent(ExecutionEvent.completed(executionId, result.isSuccessful));
      
      return result;
      
    } catch (e) {
      _emitEvent(ExecutionEvent.failed(executionId, e.toString()));
      rethrow;
    }
  }
  
  /// Execute a single block within a workflow
  Future<BlockExecutionResult> _executeBlock(
    LogicBlock block,
    ReasoningWorkflow workflow,
    String modelId,
    WorkflowExecutionState state,
    ExecutionOptions? options,
  ) async {
    switch (block.type) {
      case LogicBlockType.goal:
        return _executeGoalBlock(block, state);
        
      case LogicBlockType.context:
        return _executeContextBlock(block, state);
        
      case LogicBlockType.reasoning:
      case LogicBlockType.gateway:
        return _executeLLMBlock(block, modelId, state);
        
      case LogicBlockType.fallback:
        return _executeFallbackBlock(block, state);
        
      case LogicBlockType.trace:
        return _executeTraceBlock(block, state);
        
      case LogicBlockType.exit:
        return _executeExitBlock(block, state);

      case LogicBlockType.humanVerification:
        return _executeHumanVerificationBlock(block, state);
        
      default:
        throw UnsupportedError('Block type ${block.type} not supported');
    }
  }
  
  Future<BlockExecutionResult> _executeHumanVerificationBlock(
    LogicBlock block,
    WorkflowExecutionState state,
  ) async {
    final description = block.properties['description'] as String? ?? 'Verification required';
    final timeoutSeconds = block.properties['timeout'] as int? ?? 300; // 5 minutes default
    
    _emitEvent(ExecutionEvent.humanVerificationRequired(
      state.executionId, 
      block.id, 
      description,
      state.currentContext,
    ));
    
    try {
      final result = await _verificationService.requestVerification(
        source: 'Workflow: ${state.workflowId}',
        title: block.label,
        description: description,
        data: state.currentContext,
        timeout: Duration(seconds: timeoutSeconds),
      );
      
      return BlockExecutionResult(
        blockId: block.id,
        blockType: block.type,
        output: result.approved ? 'Approved' : 'Rejected',
        confidence: 1.0,
        reasoning: result.feedback ?? (result.approved ? 'User approved verification' : 'User rejected verification'),
        isSuccessful: result.approved,
        contextUpdates: {
          'verification_approved': result.approved,
          'verification_feedback': result.feedback,
          'verification_timestamp': result.timestamp.toIso8601String(),
        },
      );
    } catch (e) {
      return BlockExecutionResult(
        blockId: block.id,
        blockType: block.type,
        output: 'Error',
        confidence: 0.0,
        reasoning: 'Verification failed: $e',
        isSuccessful: false,
      );
    }
  }
  
  Future<BlockExecutionResult> _executeGoalBlock(
    LogicBlock block,
    WorkflowExecutionState state,
  ) async {
    final description = block.properties['description'] as String? ?? '';
    final successCriteria = block.properties['successCriteria'] as String? ?? '';
    
    // Goal blocks set up the execution context
    final updatedContext = Map<String, dynamic>.from(state.currentContext);
    updatedContext['goal'] = description;
    updatedContext['success_criteria'] = successCriteria;
    
    return BlockExecutionResult(
      blockId: block.id,
      blockType: block.type,
      output: description,
      confidence: 1.0,
      reasoning: 'Goal established: $description',
      isSuccessful: true,
      contextUpdates: updatedContext,
      metadata: {
        'success_criteria': successCriteria,
      },
    );
  }
  
  Future<BlockExecutionResult> _executeContextBlock(
    LogicBlock block,
    WorkflowExecutionState state,
  ) async {
    final maxResults = block.properties['maxResults'] as int? ?? 10;
    
    // For Phase 2, we'll use the existing context
    // Phase 3 will add vector store integration
    final contextData = state.currentContext['context_data'] as String? ?? 'No context available';
    
    return BlockExecutionResult(
      blockId: block.id,
      blockType: block.type,
      output: contextData,
      confidence: 0.8,
      reasoning: 'Context retrieved and filtered',
      isSuccessful: true,
      contextUpdates: {
        'filtered_context': contextData,
        'context_size': contextData.length,
      },
      metadata: {
        'max_results': maxResults,
        'results_found': 1,
      },
    );
  }
  
  Future<BlockExecutionResult> _executeLLMBlock(
    LogicBlock block,
    String modelId,
    WorkflowExecutionState state,
  ) async {
    final goal = state.currentContext['goal'] as String? ?? 'No goal defined';
    final contextData = state.currentContext['filtered_context'] as String? ?? 
                       state.currentContext['context_data'] as String? ?? 'No context';
    
    final reasoningContext = ReasoningContext(
      goal: goal,
      contextData: contextData,
      conversationHistory: [],
      currentState: state.currentContext,
    );
    
    final result = await _reasoningService.executeReasoningBlock(
      block,
      modelId,
      reasoningContext,
    );
    
    // Convert ReasoningResult to BlockExecutionResult
    final contextUpdates = Map<String, dynamic>.from(state.currentContext);
    contextUpdates['last_reasoning'] = result.reasoning;
    contextUpdates['last_output'] = result.output;
    
    if (block.type == LogicBlockType.gateway) {
      contextUpdates['gateway_decision'] = result.output;
      contextUpdates['gateway_confidence'] = result.confidence;
    }
    
    return BlockExecutionResult(
      blockId: block.id,
      blockType: block.type,
      output: result.output,
      confidence: result.confidence,
      reasoning: result.reasoning,
      isSuccessful: result.isSuccessful,
      contextUpdates: contextUpdates,
      metadata: result.metadata,
    );
  }
  
  Future<BlockExecutionResult> _executeFallbackBlock(
    LogicBlock block,
    WorkflowExecutionState state,
  ) async {
    final retryCount = block.properties['retryCount'] as int? ?? 2;
    final escalationPath = block.properties['escalationPath'] as String? ?? 'human';
    
    // Check if we need to activate fallback
    final lastError = state.errors.lastOrNull;
    final hasErrors = state.errors.isNotEmpty;
    
    if (!hasErrors) {
      return BlockExecutionResult(
        blockId: block.id,
        blockType: block.type,
        output: 'No fallback needed',
        confidence: 1.0,
        reasoning: 'No errors detected, fallback not triggered',
        isSuccessful: true,
        contextUpdates: {'fallback_triggered': false},
      );
    }
    
    // Determine fallback action
    String action;
    String reasoning;
    
    if (escalationPath == 'human') {
      action = 'escalate_to_human';
      reasoning = 'Error detected, escalating to human for review';
    } else if (escalationPath == 'retry') {
      action = 'retry_with_changes';
      reasoning = 'Error detected, preparing retry with modified parameters';
    } else {
      action = 'abort_workflow';
      reasoning = 'Error detected, aborting workflow execution';
    }
    
    return BlockExecutionResult(
      blockId: block.id,
      blockType: block.type,
      output: action,
      confidence: 0.8,
      reasoning: reasoning,
      isSuccessful: action != 'abort_workflow',
      contextUpdates: {
        'fallback_triggered': true,
        'fallback_action': action,
        'retry_count': retryCount,
      },
      metadata: {
        'escalation_path': escalationPath,
        'last_error': lastError?.error,
      },
    );
  }
  
  Future<BlockExecutionResult> _executeTraceBlock(
    LogicBlock block,
    WorkflowExecutionState state,
  ) async {
    final level = block.properties['level'] as String? ?? 'info';
    final includeState = block.properties['includeState'] as bool? ?? true;
    
    final traceData = {
      'timestamp': DateTime.now().toIso8601String(),
      'level': level,
      'execution_id': state.executionId,
      'workflow_id': state.workflowId,
      'completed_blocks': state.completedBlocks.length,
      'errors': state.errors.length,
    };
    
    if (includeState) {
      traceData['current_context'] = state.currentContext;
    }
    
    // In a real implementation, this would write to logging service
    print('TRACE [$level]: ${traceData}');
    
    return BlockExecutionResult(
      blockId: block.id,
      blockType: block.type,
      output: 'Trace logged',
      confidence: 1.0,
      reasoning: 'Execution trace logged at $level level',
      isSuccessful: true,
      contextUpdates: {'last_trace': DateTime.now().toIso8601String()},
      metadata: traceData,
    );
  }
  
  Future<BlockExecutionResult> _executeExitBlock(
    LogicBlock block,
    WorkflowExecutionState state,
  ) async {
    final partialResults = block.properties['partialResults'] as bool? ?? true;
    final validationChecks = block.properties['validationChecks'] as List<String>? ?? [];
    
    // Evaluate completion
    final hasGoal = state.currentContext.containsKey('goal');
    final hasOutput = state.completedBlocks.isNotEmpty;
    final hasErrors = state.errors.isNotEmpty;
    
    String status;
    double confidence;
    String reasoning;
    
    if (hasGoal && hasOutput && !hasErrors) {
      status = 'complete_success';
      confidence = 1.0;
      reasoning = 'Workflow completed successfully with all objectives met';
    } else if (hasOutput && partialResults) {
      status = 'partial_success';
      confidence = 0.7;
      reasoning = 'Workflow completed with partial results';
    } else if (hasErrors) {
      status = 'failed_with_errors';
      confidence = 0.3;
      reasoning = 'Workflow failed due to errors';
    } else {
      status = 'incomplete';
      confidence = 0.4;
      reasoning = 'Workflow terminated without clear completion';
    }
    
    return BlockExecutionResult(
      blockId: block.id,
      blockType: block.type,
      output: status,
      confidence: confidence,
      reasoning: reasoning,
      isSuccessful: confidence > 0.5,
      contextUpdates: {
        'final_status': status,
        'completion_time': DateTime.now().toIso8601String(),
      },
      metadata: {
        'validation_checks': validationChecks,
        'partial_results_allowed': partialResults,
        'total_blocks_executed': state.completedBlocks.length,
        'total_errors': state.errors.length,
      },
    );
  }
  
  bool _shouldTerminateEarly(
    LogicBlock block,
    BlockExecutionResult result,
    ExecutionOptions? options,
  ) {
    if (options?.stopOnHighConfidence == true && 
        result.confidence > (options?.confidenceThreshold ?? 0.95)) {
      return true;
    }
    
    if (block.type == LogicBlockType.exit) {
      return true;
    }
    
    return false;
  }
  
  bool _shouldContinueAfterError(
    LogicBlock block,
    BlockExecutionError error,
    ExecutionOptions? options,
  ) {
    if (options?.stopOnFirstError == true) {
      return false;
    }
    
    // Always stop on critical block errors
    if (block.type == LogicBlockType.goal || block.type == LogicBlockType.exit) {
      return false;
    }
    
    return true;
  }
  
  void _emitEvent(ExecutionEvent event) {
    _eventController.add(event);
  }
  
  void dispose() {
    _eventController.close();
  }
}

/// Configuration options for workflow execution
class ExecutionOptions {
  final bool stopOnFirstError;
  final bool stopOnHighConfidence;
  final double confidenceThreshold;
  final Duration timeout;
  final Map<String, dynamic> customSettings;
  
  const ExecutionOptions({
    this.stopOnFirstError = false,
    this.stopOnHighConfidence = false,
    this.confidenceThreshold = 0.95,
    this.timeout = const Duration(minutes: 10),
    this.customSettings = const {},
  });
}

/// Current state of workflow execution
class WorkflowExecutionState {
  final String workflowId;
  final String executionId;
  final Map<String, dynamic> currentContext;
  final Map<String, String> blockStates;
  final Map<String, BlockExecutionResult> completedBlocks;
  final List<BlockExecutionError> errors;
  
  const WorkflowExecutionState({
    required this.workflowId,
    required this.executionId,
    required this.currentContext,
    required this.blockStates,
    required this.completedBlocks,
    required this.errors,
  });
  
  bool get isSuccessful => errors.isEmpty && completedBlocks.isNotEmpty;
  bool get shouldStopExecution => errors.any((e) => e.isCritical);
  
  WorkflowExecutionState withBlockResult(String blockId, BlockExecutionResult result) {
    final newCompletedBlocks = Map<String, BlockExecutionResult>.from(completedBlocks);
    newCompletedBlocks[blockId] = result;
    
    final newContext = Map<String, dynamic>.from(currentContext);
    newContext.addAll(result.contextUpdates);
    
    return WorkflowExecutionState(
      workflowId: workflowId,
      executionId: executionId,
      currentContext: newContext,
      blockStates: blockStates,
      completedBlocks: newCompletedBlocks,
      errors: errors,
    );
  }
  
  WorkflowExecutionState withError(BlockExecutionError error) {
    return WorkflowExecutionState(
      workflowId: workflowId,
      executionId: executionId,
      currentContext: currentContext,
      blockStates: blockStates,
      completedBlocks: completedBlocks,
      errors: [...errors, error],
    );
  }
}

/// Result from executing a single block
class BlockExecutionResult {
  final String blockId;
  final LogicBlockType blockType;
  final String output;
  final double confidence;
  final String reasoning;
  final bool isSuccessful;
  final Map<String, dynamic> contextUpdates;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  
  BlockExecutionResult({
    required this.blockId,
    required this.blockType,
    required this.output,
    required this.confidence,
    required this.reasoning,
    required this.isSuccessful,
    this.contextUpdates = const {},
    this.metadata = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Error that occurred during block execution
class BlockExecutionError {
  final String blockId;
  final LogicBlockType blockType;
  final String error;
  final DateTime timestamp;
  final bool isCritical;
  
  BlockExecutionError({
    required this.blockId,
    required this.blockType,
    required this.error,
    required this.timestamp,
    this.isCritical = false,
  });
}

/// Complete workflow execution result
class WorkflowExecutionResult {
  final String executionId;
  final String workflowId;
  final WorkflowExecutionState state;
  final bool isSuccessful;
  final Duration duration;
  final DateTime startTime;
  final DateTime endTime;
  
  const WorkflowExecutionResult({
    required this.executionId,
    required this.workflowId,
    required this.state,
    required this.isSuccessful,
    required this.duration,
    required this.startTime,
    required this.endTime,
  });
  
  double get successRate {
    if (state.completedBlocks.isEmpty) return 0.0;
    final successful = state.completedBlocks.values.where((r) => r.isSuccessful).length;
    return successful / state.completedBlocks.length;
  }
  
  List<BlockExecutionResult> get allResults => state.completedBlocks.values.toList();
}

/// Events emitted during workflow execution
abstract class ExecutionEvent {
  final String executionId;
  final DateTime timestamp;
  
  const ExecutionEvent(this.executionId, this.timestamp);
  
  factory ExecutionEvent.started(String executionId, String workflowId) = _ExecutionStarted;
  factory ExecutionEvent.completed(String executionId, bool successful) = _ExecutionCompleted;
  factory ExecutionEvent.failed(String executionId, String error) = _ExecutionFailed;
  factory ExecutionEvent.blockStarted(String executionId, String blockId, LogicBlockType type) = _BlockStarted;
  factory ExecutionEvent.blockCompleted(String executionId, String blockId, bool successful, double confidence) = _BlockCompleted;
  factory ExecutionEvent.blockError(String executionId, String blockId, String error) = _BlockError;
  factory ExecutionEvent.earlyTermination(String executionId, String blockId, String reason) = _EarlyTermination;
  factory ExecutionEvent.humanVerificationRequired(String executionId, String blockId, String description, Map<String, dynamic> context) = _HumanVerificationRequired;
}

/// Execution started event
class ExecutionStarted extends ExecutionEvent {
  final String workflowId;
  ExecutionStarted(String executionId, this.workflowId) : super(executionId, DateTime.now());
}

/// Execution completed event
class ExecutionCompleted extends ExecutionEvent {
  final bool successful;
  ExecutionCompleted(String executionId, this.successful) : super(executionId, DateTime.now());
}

/// Execution failed event
class ExecutionFailed extends ExecutionEvent {
  final String error;
  ExecutionFailed(String executionId, this.error) : super(executionId, DateTime.now());
}

/// Block started event
class BlockStarted extends ExecutionEvent {
  final String blockId;
  final LogicBlockType type;
  BlockStarted(String executionId, this.blockId, this.type) : super(executionId, DateTime.now());
}

/// Block completed event
class BlockCompleted extends ExecutionEvent {
  final String blockId;
  final bool successful;
  final double confidence;
  BlockCompleted(String executionId, this.blockId, this.successful, this.confidence) : super(executionId, DateTime.now());
}

/// Block error event
class BlockError extends ExecutionEvent {
  final String blockId;
  final String error;
  BlockError(String executionId, this.blockId, this.error) : super(executionId, DateTime.now());
}

/// Early termination event
class EarlyTermination extends ExecutionEvent {
  final String blockId;
  final String reason;
  EarlyTermination(String executionId, this.blockId, this.reason) : super(executionId, DateTime.now());
}

// Private implementation classes for factory methods
class _ExecutionStarted extends ExecutionEvent {
  final String workflowId;
  _ExecutionStarted(String executionId, this.workflowId) : super(executionId, DateTime.now());
}

class _ExecutionCompleted extends ExecutionEvent {
  final bool successful;
  _ExecutionCompleted(String executionId, this.successful) : super(executionId, DateTime.now());
}

class _ExecutionFailed extends ExecutionEvent {
  final String error;
  _ExecutionFailed(String executionId, this.error) : super(executionId, DateTime.now());
}

class _BlockStarted extends ExecutionEvent {
  final String blockId;
  final LogicBlockType type;
  _BlockStarted(String executionId, this.blockId, this.type) : super(executionId, DateTime.now());
}

class _BlockCompleted extends ExecutionEvent {
  final String blockId;
  final bool successful;
  final double confidence;
  _BlockCompleted(String executionId, this.blockId, this.successful, this.confidence) : super(executionId, DateTime.now());
}

class _BlockError extends ExecutionEvent {
  final String blockId;
  final String error;
  _BlockError(String executionId, this.blockId, this.error) : super(executionId, DateTime.now());
}

class _EarlyTermination extends ExecutionEvent {
  final String blockId;
  final String reason;
  _EarlyTermination(String executionId, this.blockId, this.reason) : super(executionId, DateTime.now());
}

class _HumanVerificationRequired extends ExecutionEvent {
  final String blockId;
  final String description;
  final Map<String, dynamic> context;
  _HumanVerificationRequired(String executionId, this.blockId, this.description, this.context) : super(executionId, DateTime.now());
}

/// Exception thrown during workflow execution
class WorkflowExecutionException implements Exception {
  final String message;
  final String? workflowId;
  final String? blockId;
  
  const WorkflowExecutionException(
    this.message, {
    this.workflowId,
    this.blockId,
  });
  
  @override
  String toString() => 'WorkflowExecutionException: $message';
}

/// Extension to get last element or null
extension ListExtensions<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}