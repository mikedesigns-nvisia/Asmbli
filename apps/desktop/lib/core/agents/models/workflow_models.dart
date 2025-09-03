
/// Input data for workflow execution
class WorkflowInput {
  final Map<String, dynamic> data;
  final Map<String, dynamic> context;
  final DateTime timestamp;

  WorkflowInput({
    required this.data,
    this.context = const {},
  }) : timestamp = DateTime.now();

  WorkflowInput copyWith({
    Map<String, dynamic>? data,
    Map<String, dynamic>? context,
  }) {
    return WorkflowInput(
      data: data ?? Map.from(this.data),
      context: context ?? Map.from(this.context),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'context': context,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory WorkflowInput.fromJson(Map<String, dynamic> json) {
    return WorkflowInput(
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      context: Map<String, dynamic>.from(json['context'] ?? {}),
    );
  }
}

/// Output data from workflow execution
class WorkflowResult {
  final String workflowId;
  final Map<String, dynamic> output;
  final Map<String, NodeResult> nodeResults;
  final WorkflowStatus status;
  final String? error;
  final DateTime startTime;
  final DateTime endTime;
  final Duration executionTime;
  final WorkflowStats stats;

  WorkflowResult({
    required this.workflowId,
    required this.output,
    required this.nodeResults,
    required this.status,
    this.error,
    required this.startTime,
    required this.endTime,
    required this.stats,
  }) : executionTime = endTime.difference(startTime);

  bool get isSuccess => status == WorkflowStatus.completed;
  bool get isError => status == WorkflowStatus.failed;

  Map<String, dynamic> toJson() {
    return {
      'workflowId': workflowId,
      'output': output,
      'nodeResults': nodeResults.map((k, v) => MapEntry(k, v.toJson())),
      'status': status.name,
      'error': error,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'executionTime': executionTime.inMilliseconds,
      'stats': stats.toJson(),
    };
  }
}

/// Result from individual node execution
class NodeResult {
  final String nodeId;
  final dynamic output;
  final NodeStatus status;
  final String? error;
  final DateTime startTime;
  final DateTime endTime;
  final Duration executionTime;
  final Map<String, dynamic> metadata;

  NodeResult({
    required this.nodeId,
    required this.output,
    required this.status,
    this.error,
    required this.startTime,
    required this.endTime,
    this.metadata = const {},
  }) : executionTime = endTime.difference(startTime);

  bool get isSuccess => status == NodeStatus.completed;
  bool get isError => status == NodeStatus.failed;

  Map<String, dynamic> toJson() {
    return {
      'nodeId': nodeId,
      'output': output,
      'status': status.name,
      'error': error,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'executionTime': executionTime.inMilliseconds,
      'metadata': metadata,
    };
  }

  factory NodeResult.fromJson(Map<String, dynamic> json) {
    return NodeResult(
      nodeId: json['nodeId'],
      output: json['output'],
      status: NodeStatus.values.byName(json['status']),
      error: json['error'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

/// Workflow execution statistics
class WorkflowStats {
  final int totalNodes;
  final int completedNodes;
  final int failedNodes;
  final int parallelExecutions;
  final Map<String, Duration> nodeExecutionTimes;
  final Duration totalExecutionTime;

  WorkflowStats({
    required this.totalNodes,
    required this.completedNodes,
    required this.failedNodes,
    required this.parallelExecutions,
    required this.nodeExecutionTimes,
    required this.totalExecutionTime,
  });

  double get successRate => 
      totalNodes > 0 ? completedNodes / totalNodes : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'totalNodes': totalNodes,
      'completedNodes': completedNodes,
      'failedNodes': failedNodes,
      'parallelExecutions': parallelExecutions,
      'nodeExecutionTimes': nodeExecutionTimes.map(
        (k, v) => MapEntry(k, v.inMilliseconds),
      ),
      'totalExecutionTime': totalExecutionTime.inMilliseconds,
      'successRate': successRate,
    };
  }
}

/// Workflow execution status
enum WorkflowStatus {
  pending,
  running,
  completed,
  failed,
  cancelled,
}

/// Node execution status
enum NodeStatus {
  pending,
  running,
  completed,
  failed,
  skipped,
}

/// Types of workflow nodes
enum WorkflowNodeType {
  agent,
  condition,
  parallel,
  sequential,
  custom,
  input,
  output,
  transform,
  gate,
}

/// Configuration for workflow node behavior
class NodeConfig {
  final Map<String, dynamic> parameters;
  final Duration timeout;
  final int retryAttempts;
  final Duration retryDelay;
  final bool continueOnError;
  final List<String> requiredInputs;
  final Map<String, dynamic> defaultValues;

  const NodeConfig({
    this.parameters = const {},
    this.timeout = const Duration(minutes: 5),
    this.retryAttempts = 0,
    this.retryDelay = const Duration(seconds: 1),
    this.continueOnError = false,
    this.requiredInputs = const [],
    this.defaultValues = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'parameters': parameters,
      'timeout': timeout.inMilliseconds,
      'retryAttempts': retryAttempts,
      'retryDelay': retryDelay.inMilliseconds,
      'continueOnError': continueOnError,
      'requiredInputs': requiredInputs,
      'defaultValues': defaultValues,
    };
  }

  factory NodeConfig.fromJson(Map<String, dynamic> json) {
    return NodeConfig(
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
      timeout: Duration(milliseconds: json['timeout'] ?? 300000),
      retryAttempts: json['retryAttempts'] ?? 0,
      retryDelay: Duration(milliseconds: json['retryDelay'] ?? 1000),
      continueOnError: json['continueOnError'] ?? false,
      requiredInputs: List<String>.from(json['requiredInputs'] ?? []),
      defaultValues: Map<String, dynamic>.from(json['defaultValues'] ?? {}),
    );
  }
}

/// Condition evaluation result
class ConditionResult {
  final bool passed;
  final String reason;
  final Map<String, dynamic> metadata;

  const ConditionResult({
    required this.passed,
    this.reason = '',
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'passed': passed,
      'reason': reason,
      'metadata': metadata,
    };
  }
}

/// Workflow execution context that gets passed between nodes
class ExecutionContext {
  final String workflowId;
  final String executionId;
  final WorkflowInput originalInput;
  final Map<String, dynamic> globalContext;
  final Map<String, NodeResult> completedNodes;
  final DateTime startTime;

  ExecutionContext({
    required this.workflowId,
    required this.executionId,
    required this.originalInput,
    required this.globalContext,
    required this.completedNodes,
    required this.startTime,
  });

  ExecutionContext copyWith({
    Map<String, dynamic>? globalContext,
    Map<String, NodeResult>? completedNodes,
  }) {
    return ExecutionContext(
      workflowId: workflowId,
      executionId: executionId,
      originalInput: originalInput,
      globalContext: globalContext ?? Map.from(this.globalContext),
      completedNodes: completedNodes ?? Map.from(this.completedNodes),
      startTime: startTime,
    );
  }

  /// Get output from a completed node
  T? getNodeOutput<T>(String nodeId) {
    final result = completedNodes[nodeId];
    return result?.output as T?;
  }

  /// Check if all required nodes are completed
  bool areNodesCompleted(List<String> nodeIds) {
    return nodeIds.every((id) => completedNodes.containsKey(id));
  }

  /// Get combined outputs from multiple nodes
  Map<String, dynamic> getMultipleNodeOutputs(List<String> nodeIds) {
    final outputs = <String, dynamic>{};
    for (final nodeId in nodeIds) {
      final result = completedNodes[nodeId];
      if (result != null) {
        outputs[nodeId] = result.output;
      }
    }
    return outputs;
  }

  Map<String, dynamic> toJson() {
    return {
      'workflowId': workflowId,
      'executionId': executionId,
      'originalInput': originalInput.toJson(),
      'globalContext': globalContext,
      'completedNodes': completedNodes.map((k, v) => MapEntry(k, v.toJson())),
      'startTime': startTime.toIso8601String(),
    };
  }
}

/// Template for creating reusable workflows
class WorkflowTemplate {
  final String id;
  final String name;
  final String description;
  final String version;
  final List<WorkflowNodeTemplate> nodeTemplates;
  final Map<String, List<String>> dependencies;
  final WorkflowTemplateConfig config;
  final Map<String, dynamic> metadata;

  const WorkflowTemplate({
    required this.id,
    required this.name,
    required this.description,
    this.version = '1.0.0',
    required this.nodeTemplates,
    required this.dependencies,
    required this.config,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'version': version,
      'nodeTemplates': nodeTemplates.map((t) => t.toJson()).toList(),
      'dependencies': dependencies,
      'config': config.toJson(),
      'metadata': metadata,
    };
  }

  factory WorkflowTemplate.fromJson(Map<String, dynamic> json) {
    return WorkflowTemplate(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      version: json['version'] ?? '1.0.0',
      nodeTemplates: (json['nodeTemplates'] as List)
          .map((t) => WorkflowNodeTemplate.fromJson(t))
          .toList(),
      dependencies: Map<String, List<String>>.from(
        (json['dependencies'] as Map).map(
          (k, v) => MapEntry(k.toString(), List<String>.from(v)),
        ),
      ),
      config: WorkflowTemplateConfig.fromJson(json['config']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

/// Template for workflow nodes
class WorkflowNodeTemplate {
  final String id;
  final WorkflowNodeType type;
  final String? agentType;
  final NodeConfig config;
  final Map<String, dynamic> metadata;

  const WorkflowNodeTemplate({
    required this.id,
    required this.type,
    this.agentType,
    required this.config,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'agentType': agentType,
      'config': config.toJson(),
      'metadata': metadata,
    };
  }

  factory WorkflowNodeTemplate.fromJson(Map<String, dynamic> json) {
    return WorkflowNodeTemplate(
      id: json['id'],
      type: WorkflowNodeType.values.byName(json['type']),
      agentType: json['agentType'],
      config: NodeConfig.fromJson(json['config']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

/// Configuration for workflow templates
class WorkflowTemplateConfig {
  final Duration defaultTimeout;
  final bool allowParallelExecution;
  final bool stopOnFirstError;
  final int maxRetries;
  final Map<String, dynamic> globalDefaults;

  const WorkflowTemplateConfig({
    this.defaultTimeout = const Duration(minutes: 30),
    this.allowParallelExecution = true,
    this.stopOnFirstError = false,
    this.maxRetries = 3,
    this.globalDefaults = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'defaultTimeout': defaultTimeout.inMilliseconds,
      'allowParallelExecution': allowParallelExecution,
      'stopOnFirstError': stopOnFirstError,
      'maxRetries': maxRetries,
      'globalDefaults': globalDefaults,
    };
  }

  factory WorkflowTemplateConfig.fromJson(Map<String, dynamic> json) {
    return WorkflowTemplateConfig(
      defaultTimeout: Duration(milliseconds: json['defaultTimeout'] ?? 1800000),
      allowParallelExecution: json['allowParallelExecution'] ?? true,
      stopOnFirstError: json['stopOnFirstError'] ?? false,
      maxRetries: json['maxRetries'] ?? 3,
      globalDefaults: Map<String, dynamic>.from(json['globalDefaults'] ?? {}),
    );
  }
}