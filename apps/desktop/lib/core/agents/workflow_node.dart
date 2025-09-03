import 'dart:async';
import 'dart:math' as math;
import 'base_agent.dart';
import 'models/workflow_models.dart';

/// A node in the workflow DAG that can execute different types of operations
class WorkflowNode {
  final String id;
  final WorkflowNodeType type;
  final Agent? agent;
  final Function? customLogic;
  final NodeConfig config;
  final Map<String, dynamic> metadata;

  WorkflowNode({
    required this.id,
    required this.type,
    this.agent,
    this.customLogic,
    this.config = const NodeConfig(),
    this.metadata = const {},
  }) {
    // Validate node configuration
    _validateConfiguration();
  }

  /// Validate that the node is properly configured
  void _validateConfiguration() {
    switch (type) {
      case WorkflowNodeType.agent:
        if (agent == null) {
          throw ArgumentError('Agent node requires an agent instance');
        }
        break;
      case WorkflowNodeType.custom:
        if (customLogic == null) {
          throw ArgumentError('Custom node requires custom logic function');
        }
        break;
      default:
        break;
    }
  }

  /// Execute this node with the given input and context
  Future<NodeResult> execute(
    dynamic input,
    ExecutionContext context,
  ) async {
    final startTime = DateTime.now();
    
    try {
      print('🔄 Executing node: $id (type: ${type.name})');
      
      // Validate required inputs
      if (!_validateInputs(input)) {
        throw Exception('Required inputs not provided');
      }

      // Apply default values
      final processedInput = _applyDefaults(input);
      
      // Execute with timeout and retries
      dynamic output;
      for (int attempt = 0; attempt <= config.retryAttempts; attempt++) {
        try {
          output = await _executeWithTimeout(processedInput, context);
          break; // Success, exit retry loop
        } catch (e) {
          if (attempt == config.retryAttempts) {
            rethrow; // Last attempt failed
          }
          
          print('⚠️ Node $id attempt ${attempt + 1} failed, retrying: $e');
          await Future.delayed(config.retryDelay);
        }
      }

      final endTime = DateTime.now();
      
      print('✅ Node $id completed successfully');
      
      return NodeResult(
        nodeId: id,
        output: output,
        status: NodeStatus.completed,
        startTime: startTime,
        endTime: endTime,
        metadata: {
          'type': type.name,
          'attempts': config.retryAttempts + 1,
          ...metadata,
        },
      );

    } catch (e) {
      final endTime = DateTime.now();
      
      print('❌ Node $id failed: $e');
      
      return NodeResult(
        nodeId: id,
        output: null,
        status: NodeStatus.failed,
        error: e.toString(),
        startTime: startTime,
        endTime: endTime,
        metadata: {
          'type': type.name,
          'error_details': e.toString(),
          ...metadata,
        },
      );
    }
  }

  /// Execute the core logic with timeout
  Future<dynamic> _executeWithTimeout(
    dynamic input,
    ExecutionContext context,
  ) async {
    return await Future.timeout(
      _executeCoreLogic(input, context),
      config.timeout,
      onTimeout: () {
        throw TimeoutException(
          'Node $id timed out after ${config.timeout.inSeconds} seconds',
        );
      },
    );
  }

  /// Execute the core node logic based on type
  Future<dynamic> _executeCoreLogic(
    dynamic input,
    ExecutionContext context,
  ) async {
    switch (type) {
      case WorkflowNodeType.agent:
        return await agent!.process(input, context);
        
      case WorkflowNodeType.condition:
        return await _evaluateCondition(input, context);
        
      case WorkflowNodeType.parallel:
        return await _executeParallel(input, context);
        
      case WorkflowNodeType.sequential:
        return await _executeSequential(input, context);
        
      case WorkflowNodeType.custom:
        return await customLogic!(input, context);
        
      case WorkflowNodeType.input:
        return await _processInput(input, context);
        
      case WorkflowNodeType.output:
        return await _processOutput(input, context);
        
      case WorkflowNodeType.transform:
        return await _transformData(input, context);
        
      case WorkflowNodeType.gate:
        return await _evaluateGate(input, context);
        
      default:
        throw Exception('Unknown node type: $type');
    }
  }

  /// Evaluate a condition node
  Future<ConditionResult> _evaluateCondition(
    dynamic input,
    ExecutionContext context,
  ) async {
    final condition = config.parameters['condition'] as String?;
    if (condition == null) {
      throw Exception('Condition node requires a condition parameter');
    }

    // Simple condition evaluation (in practice, this might use a more sophisticated expression evaluator)
    final result = _evaluateSimpleCondition(condition, input, context);
    
    return ConditionResult(
      passed: result,
      reason: 'Condition "$condition" evaluated to $result',
      metadata: {'condition': condition, 'input': input},
    );
  }

  /// Simple condition evaluation logic
  bool _evaluateSimpleCondition(String condition, dynamic input, ExecutionContext context) {
    // This is a simplified implementation. In practice, you might want to use
    // a proper expression evaluator library or implement more sophisticated logic
    
    if (input is Map<String, dynamic>) {
      // Check for simple field comparisons
      final parts = condition.split(' ');
      if (parts.length >= 3) {
        final field = parts[0];
        final operator = parts[1];
        final value = parts[2];
        
        final fieldValue = input[field];
        
        switch (operator) {
          case '==':
            return fieldValue.toString() == value;
          case '!=':
            return fieldValue.toString() != value;
          case '>':
            return (fieldValue as num?) != null && (fieldValue as num) > num.parse(value);
          case '<':
            return (fieldValue as num?) != null && (fieldValue as num) < num.parse(value);
          case '>=':
            return (fieldValue as num?) != null && (fieldValue as num) >= num.parse(value);
          case '<=':
            return (fieldValue as num?) != null && (fieldValue as num) <= num.parse(value);
        }
      }
    }
    
    // Default to true if condition can't be evaluated
    return true;
  }

  /// Execute parallel operations
  Future<Map<String, dynamic>> _executeParallel(
    dynamic input,
    ExecutionContext context,
  ) async {
    final operations = config.parameters['operations'] as List<Function>?;
    if (operations == null || operations.isEmpty) {
      throw Exception('Parallel node requires operations parameter');
    }

    final futures = operations.map((op) => op(input)).cast<Future<dynamic>>();
    final results = await Future.wait(futures);
    
    final output = <String, dynamic>{};
    for (int i = 0; i < results.length; i++) {
      output['result_$i'] = results[i];
    }
    
    return output;
  }

  /// Execute sequential operations
  Future<dynamic> _executeSequential(
    dynamic input,
    ExecutionContext context,
  ) async {
    final operations = config.parameters['operations'] as List<Function>?;
    if (operations == null || operations.isEmpty) {
      throw Exception('Sequential node requires operations parameter');
    }

    dynamic result = input;
    for (final operation in operations) {
      result = await operation(result);
    }
    
    return result;
  }

  /// Process input node
  Future<dynamic> _processInput(
    dynamic input,
    ExecutionContext context,
  ) async {
    final inputMapping = config.parameters['inputMapping'] as Map<String, String>?;
    
    if (inputMapping != null && input is Map<String, dynamic>) {
      final mappedInput = <String, dynamic>{};
      for (final entry in inputMapping.entries) {
        mappedInput[entry.key] = input[entry.value];
      }
      return mappedInput;
    }
    
    return input;
  }

  /// Process output node
  Future<dynamic> _processOutput(
    dynamic input,
    ExecutionContext context,
  ) async {
    final outputMapping = config.parameters['outputMapping'] as Map<String, String>?;
    
    if (outputMapping != null && input is Map<String, dynamic>) {
      final mappedOutput = <String, dynamic>{};
      for (final entry in outputMapping.entries) {
        mappedOutput[entry.key] = input[entry.value];
      }
      return mappedOutput;
    }
    
    return input;
  }

  /// Transform data
  Future<dynamic> _transformData(
    dynamic input,
    ExecutionContext context,
  ) async {
    final transformer = config.parameters['transformer'] as Function?;
    if (transformer != null) {
      return await transformer(input);
    }
    
    // Default transformation - pass through
    return input;
  }

  /// Evaluate gate conditions
  Future<dynamic> _evaluateGate(
    dynamic input,
    ExecutionContext context,
  ) async {
    final gateType = config.parameters['gateType'] as String? ?? 'and';
    final conditions = config.parameters['conditions'] as List<String>? ?? [];
    
    bool result = true;
    
    if (gateType == 'and') {
      for (final condition in conditions) {
        if (!_evaluateSimpleCondition(condition, input, context)) {
          result = false;
          break;
        }
      }
    } else if (gateType == 'or') {
      result = false;
      for (final condition in conditions) {
        if (_evaluateSimpleCondition(condition, input, context)) {
          result = true;
          break;
        }
      }
    }
    
    return ConditionResult(
      passed: result,
      reason: 'Gate ($gateType) evaluation: $result',
      metadata: {'gateType': gateType, 'conditions': conditions},
    );
  }

  /// Validate required inputs
  bool _validateInputs(dynamic input) {
    if (config.requiredInputs.isEmpty) return true;
    
    if (input is! Map<String, dynamic>) return false;
    
    for (final requiredInput in config.requiredInputs) {
      if (!input.containsKey(requiredInput) || input[requiredInput] == null) {
        return false;
      }
    }
    
    return true;
  }

  /// Apply default values to input
  dynamic _applyDefaults(dynamic input) {
    if (config.defaultValues.isEmpty) return input;
    
    if (input is Map<String, dynamic>) {
      final processedInput = Map<String, dynamic>.from(input);
      for (final entry in config.defaultValues.entries) {
        if (!processedInput.containsKey(entry.key) || processedInput[entry.key] == null) {
          processedInput[entry.key] = entry.value;
        }
      }
      return processedInput;
    }
    
    return input;
  }

  /// Check if this node can be executed (all dependencies are met)
  bool canExecute(ExecutionContext context, List<String> dependencies) {
    return context.areNodesCompleted(dependencies);
  }

  /// Get the estimated execution time for this node
  Duration getEstimatedExecutionTime() {
    // This could be based on historical data, node type, or configuration
    switch (type) {
      case WorkflowNodeType.agent:
        return Duration(seconds: 30); // Agents typically take longer
      case WorkflowNodeType.condition:
      case WorkflowNodeType.gate:
        return Duration(milliseconds: 100); // Conditions are fast
      case WorkflowNodeType.transform:
        return Duration(seconds: 5); // Transformations are medium
      case WorkflowNodeType.parallel:
        return Duration(seconds: 60); // Parallel operations take longer
      default:
        return Duration(seconds: 10); // Default estimate
    }
  }

  @override
  String toString() {
    return 'WorkflowNode(id: $id, type: ${type.name}, agent: ${agent?.name})';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'agentId': agent?.id,
      'agentName': agent?.name,
      'config': config.toJson(),
      'metadata': metadata,
      'estimatedExecutionTime': getEstimatedExecutionTime().inMilliseconds,
    };
  }

  factory WorkflowNode.fromJson(Map<String, dynamic> json, {Agent? agent}) {
    return WorkflowNode(
      id: json['id'],
      type: WorkflowNodeType.values.byName(json['type']),
      agent: agent,
      config: NodeConfig.fromJson(json['config']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

/// Factory for creating common workflow node types
class WorkflowNodeFactory {
  /// Create an agent node
  static WorkflowNode createAgentNode({
    required String id,
    required Agent agent,
    NodeConfig? config,
    Map<String, dynamic>? metadata,
  }) {
    return WorkflowNode(
      id: id,
      type: WorkflowNodeType.agent,
      agent: agent,
      config: config ?? const NodeConfig(),
      metadata: metadata ?? {},
    );
  }

  /// Create a condition node
  static WorkflowNode createConditionNode({
    required String id,
    required String condition,
    NodeConfig? config,
    Map<String, dynamic>? metadata,
  }) {
    final nodeConfig = config ?? const NodeConfig();
    return WorkflowNode(
      id: id,
      type: WorkflowNodeType.condition,
      config: NodeConfig(
        parameters: {
          'condition': condition,
          ...nodeConfig.parameters,
        },
        timeout: nodeConfig.timeout,
        retryAttempts: nodeConfig.retryAttempts,
        retryDelay: nodeConfig.retryDelay,
        continueOnError: nodeConfig.continueOnError,
        requiredInputs: nodeConfig.requiredInputs,
        defaultValues: nodeConfig.defaultValues,
      ),
      metadata: metadata ?? {},
    );
  }

  /// Create a transform node
  static WorkflowNode createTransformNode({
    required String id,
    required Function transformer,
    NodeConfig? config,
    Map<String, dynamic>? metadata,
  }) {
    final nodeConfig = config ?? const NodeConfig();
    return WorkflowNode(
      id: id,
      type: WorkflowNodeType.transform,
      config: NodeConfig(
        parameters: {
          'transformer': transformer,
          ...nodeConfig.parameters,
        },
        timeout: nodeConfig.timeout,
        retryAttempts: nodeConfig.retryAttempts,
        retryDelay: nodeConfig.retryDelay,
        continueOnError: nodeConfig.continueOnError,
        requiredInputs: nodeConfig.requiredInputs,
        defaultValues: nodeConfig.defaultValues,
      ),
      metadata: metadata ?? {},
    );
  }

  /// Create a parallel execution node
  static WorkflowNode createParallelNode({
    required String id,
    required List<Function> operations,
    NodeConfig? config,
    Map<String, dynamic>? metadata,
  }) {
    final nodeConfig = config ?? const NodeConfig();
    return WorkflowNode(
      id: id,
      type: WorkflowNodeType.parallel,
      config: NodeConfig(
        parameters: {
          'operations': operations,
          ...nodeConfig.parameters,
        },
        timeout: nodeConfig.timeout,
        retryAttempts: nodeConfig.retryAttempts,
        retryDelay: nodeConfig.retryDelay,
        continueOnError: nodeConfig.continueOnError,
        requiredInputs: nodeConfig.requiredInputs,
        defaultValues: nodeConfig.defaultValues,
      ),
      metadata: metadata ?? {},
    );
  }

  /// Create a gate node
  static WorkflowNode createGateNode({
    required String id,
    required String gateType, // 'and' or 'or'
    required List<String> conditions,
    NodeConfig? config,
    Map<String, dynamic>? metadata,
  }) {
    final nodeConfig = config ?? const NodeConfig();
    return WorkflowNode(
      id: id,
      type: WorkflowNodeType.gate,
      config: NodeConfig(
        parameters: {
          'gateType': gateType,
          'conditions': conditions,
          ...nodeConfig.parameters,
        },
        timeout: nodeConfig.timeout,
        retryAttempts: nodeConfig.retryAttempts,
        retryDelay: nodeConfig.retryDelay,
        continueOnError: nodeConfig.continueOnError,
        requiredInputs: nodeConfig.requiredInputs,
        defaultValues: nodeConfig.defaultValues,
      ),
      metadata: metadata ?? {},
    );
  }

  /// Create a custom logic node
  static WorkflowNode createCustomNode({
    required String id,
    required Function customLogic,
    NodeConfig? config,
    Map<String, dynamic>? metadata,
  }) {
    return WorkflowNode(
      id: id,
      type: WorkflowNodeType.custom,
      customLogic: customLogic,
      config: config ?? const NodeConfig(),
      metadata: metadata ?? {},
    );
  }
}