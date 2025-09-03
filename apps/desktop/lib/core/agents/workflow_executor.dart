import 'dart:async';
import 'dart:math' as math;
import 'graph/directed_graph.dart';
import 'workflow_node.dart';
import 'models/workflow_models.dart';

/// Executes workflows using DAG traversal with support for parallel execution
class WorkflowExecutor {
  final DirectedGraph<WorkflowNode> workflow;
  final WorkflowExecutorConfig config;
  
  // Internal state for execution tracking
  final Map<String, NodeResult> _nodeResults = {};
  final Map<String, Completer<NodeResult>> _nodeCompleters = {};
  final Set<String> _runningNodes = {};
  late ExecutionContext _executionContext;
  
  WorkflowExecutor(
    this.workflow, {
    this.config = const WorkflowExecutorConfig(),
  });

  /// Execute the workflow with the given input
  Future<WorkflowResult> execute(WorkflowInput input) async {
    print('🚀 Starting workflow execution');
    final startTime = DateTime.now();
    
    try {
      // Validate workflow before execution
      _validateWorkflow();
      
      // Initialize execution context
      _initializeExecutionContext(input, startTime);
      
      // Execute the workflow using parallel DAG traversal
      await _executeWorkflowDAG();
      
      // Build final result
      final endTime = DateTime.now();
      final result = _buildWorkflowResult(startTime, endTime, WorkflowStatus.completed);
      
      print('✅ Workflow execution completed successfully');
      return result;
      
    } catch (e) {
      final endTime = DateTime.now();
      print('❌ Workflow execution failed: $e');
      
      return _buildWorkflowResult(
        startTime, 
        endTime, 
        WorkflowStatus.failed,
        error: e.toString(),
      );
    } finally {
      _cleanup();
    }
  }

  /// Validate that the workflow is properly formed
  void _validateWorkflow() {
    if (workflow.isEmpty) {
      throw const WorkflowExecutionException('Workflow is empty');
    }

    // Check for circular dependencies
    if (workflow.hasCycles()) {
      final cycles = workflow.findCycles();
      throw WorkflowExecutionException(
        'Workflow contains circular dependencies: ${cycles.map((cycle) => cycle.join(' -> ')).join(', ')}'
      );
    }

    // Validate all nodes
    for (final nodeId in workflow.nodeIds) {
      final node = workflow.getNode(nodeId);
      if (node == null) {
        throw WorkflowExecutionException('Node not found: $nodeId');
      }
    }

    print('✅ Workflow validation passed');
  }

  /// Initialize execution context
  void _initializeExecutionContext(WorkflowInput input, DateTime startTime) {
    _executionContext = ExecutionContext(
      workflowId: 'workflow_${DateTime.now().millisecondsSinceEpoch}',
      executionId: 'exec_${math.Random().nextInt(999999)}',
      originalInput: input,
      globalContext: Map.from(input.context),
      completedNodes: {},
      startTime: startTime,
    );
    
    // Initialize node completers
    for (final nodeId in workflow.nodeIds) {
      _nodeCompleters[nodeId] = Completer<NodeResult>();
    }
  }

  /// Execute workflow using DAG traversal with parallel execution
  Future<void> _executeWorkflowDAG() async {
    print('📊 Executing workflow DAG with ${workflow.nodeIds.length} nodes');
    
    // Get execution levels for parallel processing
    final executionLevels = workflow.getParallelExecutionLevels();
    print('🔄 Execution levels: ${executionLevels.length}');
    
    for (int levelIndex = 0; levelIndex < executionLevels.length; levelIndex++) {
      final level = executionLevels[levelIndex];
      print('⏳ Executing level ${levelIndex + 1}: ${level.join(', ')}');
      
      // Execute all nodes at this level in parallel
      await _executeNodesInParallel(level);
      
      // Check if we should stop on error
      if (config.stopOnFirstError && _hasFailedNodes()) {
        throw const WorkflowExecutionException('Stopping execution due to failed nodes');
      }
    }
  }

  /// Execute multiple nodes in parallel
  Future<void> _executeNodesInParallel(List<String> nodeIds) async {
    final futures = <Future<void>>[];
    
    for (final nodeId in nodeIds) {
      futures.add(_executeNode(nodeId));
    }
    
    // Wait for all nodes in this level to complete
    await Future.wait(futures);
  }

  /// Execute a single node
  Future<void> _executeNode(String nodeId) async {
    final node = workflow.getNode(nodeId);
    if (node == null) {
      throw WorkflowExecutionException('Node not found: $nodeId');
    }

    try {
      _runningNodes.add(nodeId);
      
      // Prepare input for this node
      final nodeInput = _prepareNodeInput(nodeId);
      
      // Execute the node
      final result = await node.execute(nodeInput, _executionContext);
      
      // Store result and update context
      _nodeResults[nodeId] = result;
      _executionContext = _executionContext.copyWith(
        completedNodes: Map.from(_executionContext.completedNodes)
          ..[nodeId] = result,
      );
      
      // Complete the node
      _nodeCompleters[nodeId]?.complete(result);
      
      print('✅ Node $nodeId completed with status: ${result.status.name}');
      
    } catch (e) {
      final errorResult = NodeResult(
        nodeId: nodeId,
        output: null,
        status: NodeStatus.failed,
        error: e.toString(),
        startTime: DateTime.now(),
        endTime: DateTime.now(),
      );
      
      _nodeResults[nodeId] = errorResult;
      _nodeCompleters[nodeId]?.complete(errorResult);
      
      print('❌ Node $nodeId failed: $e');
      
      if (!config.continueOnNodeFailure) {
        rethrow;
      }
    } finally {
      _runningNodes.remove(nodeId);
    }
  }

  /// Prepare input for a specific node
  dynamic _prepareNodeInput(String nodeId) {
    final node = workflow.getNode(nodeId);
    final dependencies = workflow.getParents(nodeId);
    
    if (dependencies.isEmpty) {
      // Root node - use original workflow input
      return _executionContext.originalInput.data;
    }
    
    // Combine outputs from dependency nodes
    final combinedInput = <String, dynamic>{};
    
    for (final depId in dependencies) {
      final depResult = _nodeResults[depId];
      if (depResult != null && depResult.isSuccess) {
        if (depResult.output is Map<String, dynamic>) {
          combinedInput.addAll(depResult.output as Map<String, dynamic>);
        } else {
          combinedInput[depId] = depResult.output;
        }
      }
    }
    
    // If no dependencies provided useful output, use original input
    if (combinedInput.isEmpty) {
      return _executionContext.originalInput.data;
    }
    
    return combinedInput;
  }

  /// Check if any nodes have failed
  bool _hasFailedNodes() {
    return _nodeResults.values.any((result) => result.status == NodeStatus.failed);
  }

  /// Build the final workflow result
  WorkflowResult _buildWorkflowResult(
    DateTime startTime,
    DateTime endTime,
    WorkflowStatus status, {
    String? error,
  }) {
    // Combine outputs from all leaf nodes
    final leafNodes = workflow.getLeafNodes();
    final finalOutput = <String, dynamic>{};
    
    for (final leafId in leafNodes) {
      final result = _nodeResults[leafId];
      if (result != null && result.isSuccess) {
        if (result.output is Map<String, dynamic>) {
          finalOutput.addAll(result.output as Map<String, dynamic>);
        } else {
          finalOutput[leafId] = result.output;
        }
      }
    }
    
    // Build statistics
    final stats = _buildWorkflowStats(startTime, endTime);
    
    return WorkflowResult(
      workflowId: _executionContext.workflowId,
      output: finalOutput,
      nodeResults: Map.from(_nodeResults),
      status: status,
      error: error,
      startTime: startTime,
      endTime: endTime,
      stats: stats,
    );
  }

  /// Build workflow execution statistics
  WorkflowStats _buildWorkflowStats(DateTime startTime, DateTime endTime) {
    final completedNodes = _nodeResults.values
        .where((result) => result.status == NodeStatus.completed)
        .length;
    
    final failedNodes = _nodeResults.values
        .where((result) => result.status == NodeStatus.failed)
        .length;
    
    final nodeExecutionTimes = <String, Duration>{};
    for (final entry in _nodeResults.entries) {
      nodeExecutionTimes[entry.key] = entry.value.executionTime;
    }
    
    return WorkflowStats(
      totalNodes: workflow.nodeIds.length,
      completedNodes: completedNodes,
      failedNodes: failedNodes,
      parallelExecutions: _countParallelExecutions(),
      nodeExecutionTimes: nodeExecutionTimes,
      totalExecutionTime: endTime.difference(startTime),
    );
  }

  /// Count the number of parallel executions
  int _countParallelExecutions() {
    try {
      return workflow.getParallelExecutionLevels().length;
    } catch (e) {
      return 0;
    }
  }

  /// Clean up execution state
  void _cleanup() {
    _nodeResults.clear();
    _nodeCompleters.clear();
    _runningNodes.clear();
  }

  /// Cancel workflow execution
  Future<void> cancel() async {
    print('🛑 Cancelling workflow execution');
    
    // Mark all running nodes as cancelled
    for (final nodeId in _runningNodes.toList()) {
      final cancelResult = NodeResult(
        nodeId: nodeId,
        output: null,
        status: NodeStatus.skipped,
        error: 'Execution cancelled',
        startTime: DateTime.now(),
        endTime: DateTime.now(),
      );
      
      _nodeResults[nodeId] = cancelResult;
      _nodeCompleters[nodeId]?.complete(cancelResult);
    }
    
    _runningNodes.clear();
  }

  /// Get current execution status
  WorkflowExecutionStatus getStatus() {
    final totalNodes = workflow.nodeIds.length;
    final completedNodes = _nodeResults.length;
    final runningNodes = _runningNodes.length;
    final failedNodes = _nodeResults.values
        .where((result) => result.status == NodeStatus.failed)
        .length;
    
    return WorkflowExecutionStatus(
      totalNodes: totalNodes,
      completedNodes: completedNodes,
      runningNodes: runningNodes,
      failedNodes: failedNodes,
      isComplete: completedNodes == totalNodes,
      isRunning: runningNodes > 0,
    );
  }

  /// Wait for a specific node to complete
  Future<NodeResult> waitForNode(String nodeId) async {
    final completer = _nodeCompleters[nodeId];
    if (completer == null) {
      throw ArgumentError('Node not found: $nodeId');
    }
    
    return await completer.future;
  }

  /// Wait for multiple nodes to complete
  Future<Map<String, NodeResult>> waitForNodes(List<String> nodeIds) async {
    final futures = <String, Future<NodeResult>>{};
    
    for (final nodeId in nodeIds) {
      final completer = _nodeCompleters[nodeId];
      if (completer != null) {
        futures[nodeId] = completer.future;
      }
    }
    
    final results = <String, NodeResult>{};
    for (final entry in futures.entries) {
      results[entry.key] = await entry.value;
    }
    
    return results;
  }
}

/// Configuration for workflow execution
class WorkflowExecutorConfig {
  final bool continueOnNodeFailure;
  final bool stopOnFirstError;
  final Duration nodeTimeout;
  final int maxParallelNodes;
  final Map<String, dynamic> globalDefaults;

  const WorkflowExecutorConfig({
    this.continueOnNodeFailure = false,
    this.stopOnFirstError = false,
    this.nodeTimeout = const Duration(minutes: 5),
    this.maxParallelNodes = 10,
    this.globalDefaults = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'continueOnNodeFailure': continueOnNodeFailure,
      'stopOnFirstError': stopOnFirstError,
      'nodeTimeout': nodeTimeout.inMilliseconds,
      'maxParallelNodes': maxParallelNodes,
      'globalDefaults': globalDefaults,
    };
  }

  factory WorkflowExecutorConfig.fromJson(Map<String, dynamic> json) {
    return WorkflowExecutorConfig(
      continueOnNodeFailure: json['continueOnNodeFailure'] ?? false,
      stopOnFirstError: json['stopOnFirstError'] ?? false,
      nodeTimeout: Duration(milliseconds: json['nodeTimeout'] ?? 300000),
      maxParallelNodes: json['maxParallelNodes'] ?? 10,
      globalDefaults: Map<String, dynamic>.from(json['globalDefaults'] ?? {}),
    );
  }
}

/// Current execution status of a workflow
class WorkflowExecutionStatus {
  final int totalNodes;
  final int completedNodes;
  final int runningNodes;
  final int failedNodes;
  final bool isComplete;
  final bool isRunning;

  const WorkflowExecutionStatus({
    required this.totalNodes,
    required this.completedNodes,
    required this.runningNodes,
    required this.failedNodes,
    required this.isComplete,
    required this.isRunning,
  });

  double get progress => totalNodes > 0 ? completedNodes / totalNodes : 0.0;
  int get pendingNodes => totalNodes - completedNodes - runningNodes;

  Map<String, dynamic> toJson() {
    return {
      'totalNodes': totalNodes,
      'completedNodes': completedNodes,
      'runningNodes': runningNodes,
      'failedNodes': failedNodes,
      'pendingNodes': pendingNodes,
      'isComplete': isComplete,
      'isRunning': isRunning,
      'progress': progress,
    };
  }

  @override
  String toString() {
    return 'WorkflowExecutionStatus(progress: ${(progress * 100).toStringAsFixed(1)}%, '
           'completed: $completedNodes/$totalNodes, running: $runningNodes, failed: $failedNodes)';
  }
}

/// Exception thrown during workflow execution
class WorkflowExecutionException implements Exception {
  final String message;
  final String? nodeId;
  final dynamic originalError;

  const WorkflowExecutionException(
    this.message, {
    this.nodeId,
    this.originalError,
  });

  @override
  String toString() {
    final buffer = StringBuffer('WorkflowExecutionException: $message');
    if (nodeId != null) {
      buffer.write(' (node: $nodeId)');
    }
    if (originalError != null) {
      buffer.write(' (caused by: $originalError)');
    }
    return buffer.toString();
  }
}