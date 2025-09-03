import 'dart:async';
import 'dart:math' as math;
import 'package:uuid/uuid.dart';
import 'graph/directed_graph.dart';
import 'workflow_node.dart';
import 'workflow_executor.dart';
import 'base_agent.dart';
import 'models/workflow_models.dart';

/// Main workflow engine that orchestrates agent execution using DAGs
class AgentWorkflow {
  final String id;
  final String name;
  final String description;
  final String version;
  final DirectedGraph<WorkflowNode> graph;
  final Map<String, dynamic> metadata;
  
  static const _uuid = Uuid();

  AgentWorkflow({
    String? id,
    required this.name,
    this.description = '',
    this.version = '1.0.0',
    this.metadata = const {},
  }) : id = id ?? _uuid.v4(),
       graph = DirectedGraph<WorkflowNode>();

  /// Add a node to the workflow with optional dependencies
  void addNode(WorkflowNode node, {List<String>? dependencies}) {
    print('➕ Adding node: ${node.id} (type: ${node.type.name})');
    
    graph.addNode(node.id, node);
    
    if (dependencies != null) {
      for (final dep in dependencies) {
        if (!graph.nodeIds.contains(dep)) {
          throw ArgumentError('Dependency node does not exist: $dep');
        }
        graph.addEdge(dep, node.id);
        print('🔗 Added dependency: $dep -> ${node.id}');
      }
    }
  }

  /// Remove a node and all its connections
  void removeNode(String nodeId) {
    print('➖ Removing node: $nodeId');
    graph.removeNode(nodeId);
  }

  /// Add a dependency between two existing nodes
  void addDependency(String fromNodeId, String toNodeId) {
    if (!graph.nodeIds.contains(fromNodeId) || !graph.nodeIds.contains(toNodeId)) {
      throw ArgumentError('Both nodes must exist before adding dependency');
    }
    
    graph.addEdge(fromNodeId, toNodeId);
    print('🔗 Added dependency: $fromNodeId -> $toNodeId');
    
    // Check for cycles after adding the edge
    if (graph.hasCycles()) {
      graph.removeEdge(fromNodeId, toNodeId);
      throw ArgumentError('Adding this dependency would create a circular dependency');
    }
  }

  /// Remove a dependency between two nodes
  void removeDependency(String fromNodeId, String toNodeId) {
    graph.removeEdge(fromNodeId, toNodeId);
    print('🔗 Removed dependency: $fromNodeId -> $toNodeId');
  }

  /// Execute the workflow with the given input
  Future<WorkflowResult> execute(
    WorkflowInput input, {
    WorkflowExecutorConfig? config,
  }) async {
    print('🚀 Executing workflow: $name (id: $id)');
    
    final executor = WorkflowExecutor(
      graph,
      config: config ?? const WorkflowExecutorConfig(),
    );
    
    return await executor.execute(input);
  }

  /// Validate the workflow structure
  bool validate({bool throwOnError = false}) {
    try {
      if (graph.isEmpty) {
        throw WorkflowValidationException('Workflow is empty');
      }

      // Check for circular dependencies
      if (graph.hasCycles()) {
        final cycles = graph.findCycles();
        throw WorkflowValidationException(
          'Workflow contains circular dependencies: ${cycles.map((cycle) => cycle.join(' -> ')).join(', ')}'
        );
      }

      // Validate all nodes
      for (final nodeId in graph.nodeIds) {
        final node = graph.getNode(nodeId);
        if (node == null) {
          throw WorkflowValidationException('Node not found: $nodeId');
        }

        // Validate node configuration
        _validateNode(node);
      }

      print('✅ Workflow validation passed');
      return true;

    } catch (e) {
      if (throwOnError) {
        rethrow;
      }
      print('❌ Workflow validation failed: $e');
      return false;
    }
  }

  /// Validate a single node
  void _validateNode(WorkflowNode node) {
    switch (node.type) {
      case WorkflowNodeType.agent:
        if (node.agent == null) {
          throw WorkflowValidationException('Agent node ${node.id} requires an agent');
        }
        break;
      case WorkflowNodeType.custom:
        if (node.customLogic == null) {
          throw WorkflowValidationException('Custom node ${node.id} requires custom logic');
        }
        break;
      case WorkflowNodeType.condition:
        if (!node.config.parameters.containsKey('condition')) {
          throw WorkflowValidationException('Condition node ${node.id} requires a condition parameter');
        }
        break;
      default:
        break;
    }
  }

  /// Get workflow statistics and analysis
  WorkflowAnalysis analyze() {
    final stats = graph.getStats();
    final executionLevels = graph.hasCycles() ? [] : graph.getParallelExecutionLevels();
    
    // Calculate estimated execution time
    Duration estimatedTime = Duration.zero;
    for (final level in executionLevels) {
      Duration maxLevelTime = Duration.zero;
      for (final nodeId in level) {
        final node = graph.getNode(nodeId);
        if (node != null) {
          final nodeTime = node.getEstimatedExecutionTime();
          if (nodeTime > maxLevelTime) {
            maxLevelTime = nodeTime;
          }
        }
      }
      estimatedTime += maxLevelTime;
    }

    // Analyze node types
    final nodeTypeAnalysis = <WorkflowNodeType, int>{};
    for (final nodeId in graph.nodeIds) {
      final node = graph.getNode(nodeId);
      if (node != null) {
        nodeTypeAnalysis[node.type] = (nodeTypeAnalysis[node.type] ?? 0) + 1;
      }
    }

    return WorkflowAnalysis(
      workflowId: id,
      graphStats: stats,
      executionLevels: executionLevels.length,
      estimatedExecutionTime: estimatedTime,
      nodeTypeAnalysis: nodeTypeAnalysis,
      parallelismFactor: executionLevels.isEmpty ? 0.0 : 
        graph.nodeIds.length / executionLevels.length,
      criticalPath: _findCriticalPath(),
    );
  }

  /// Find the critical path (longest path) through the workflow
  List<String> _findCriticalPath() {
    if (graph.hasCycles()) return [];
    
    try {
      // Simple implementation - find the longest path from any root to any leaf
      final rootNodes = graph.getRootNodes();
      List<String> longestPath = [];
      
      for (final root in rootNodes) {
        final path = _findLongestPathFrom(root, <String>{});
        if (path.length > longestPath.length) {
          longestPath = path;
        }
      }
      
      return longestPath;
    } catch (e) {
      return [];
    }
  }

  /// Find the longest path from a given node
  List<String> _findLongestPathFrom(String nodeId, Set<String> visited) {
    if (visited.contains(nodeId)) return [];
    
    visited.add(nodeId);
    
    final children = graph.getChildren(nodeId);
    if (children.isEmpty) {
      return [nodeId];
    }
    
    List<String> longestChildPath = [];
    for (final child in children) {
      final childPath = _findLongestPathFrom(child, Set.from(visited));
      if (childPath.length > longestChildPath.length) {
        longestChildPath = childPath;
      }
    }
    
    return [nodeId, ...longestChildPath];
  }

  /// Get all agents used in this workflow
  List<Agent> getAgents() {
    final agents = <Agent>[];
    for (final nodeId in graph.nodeIds) {
      final node = graph.getNode(nodeId);
      if (node?.agent != null) {
        agents.add(node!.agent!);
      }
    }
    return agents;
  }

  /// Clone the workflow with a new ID
  AgentWorkflow clone({String? newName}) {
    final cloned = AgentWorkflow(
      name: newName ?? '$name (Copy)',
      description: description,
      version: version,
      metadata: Map.from(metadata),
    );

    // Copy all nodes
    for (final nodeId in graph.nodeIds) {
      final node = graph.getNode(nodeId)!;
      cloned.graph.addNode(nodeId, node);
    }

    // Copy all edges
    for (final nodeId in graph.nodeIds) {
      final children = graph.getChildren(nodeId);
      for (final child in children) {
        cloned.graph.addEdge(nodeId, child);
      }
    }

    return cloned;
  }

  /// Convert workflow to JSON
  Map<String, dynamic> toJson() {
    final nodes = <Map<String, dynamic>>[];
    final edges = <Map<String, dynamic>>[];

    // Serialize nodes
    for (final nodeId in graph.nodeIds) {
      final node = graph.getNode(nodeId)!;
      nodes.add(node.toJson());
    }

    // Serialize edges
    for (final nodeId in graph.nodeIds) {
      final children = graph.getChildren(nodeId);
      for (final child in children) {
        edges.add({
          'from': nodeId,
          'to': child,
        });
      }
    }

    return {
      'id': id,
      'name': name,
      'description': description,
      'version': version,
      'metadata': metadata,
      'nodes': nodes,
      'edges': edges,
      'stats': graph.getStats().toJson(),
    };
  }

  @override
  String toString() {
    final stats = graph.getStats();
    return 'AgentWorkflow(id: $id, name: $name, nodes: ${stats.nodeCount}, edges: ${stats.edgeCount})';
  }
}

/// Analysis results for a workflow
class WorkflowAnalysis {
  final String workflowId;
  final GraphStats graphStats;
  final int executionLevels;
  final Duration estimatedExecutionTime;
  final Map<WorkflowNodeType, int> nodeTypeAnalysis;
  final double parallelismFactor;
  final List<String> criticalPath;

  const WorkflowAnalysis({
    required this.workflowId,
    required this.graphStats,
    required this.executionLevels,
    required this.estimatedExecutionTime,
    required this.nodeTypeAnalysis,
    required this.parallelismFactor,
    required this.criticalPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'workflowId': workflowId,
      'graphStats': graphStats.toJson(),
      'executionLevels': executionLevels,
      'estimatedExecutionTime': estimatedExecutionTime.inMilliseconds,
      'nodeTypeAnalysis': nodeTypeAnalysis.map((k, v) => MapEntry(k.name, v)),
      'parallelismFactor': parallelismFactor,
      'criticalPath': criticalPath,
    };
  }

  @override
  String toString() {
    return '''WorkflowAnalysis:
  Nodes: ${graphStats.nodeCount}
  Execution Levels: $executionLevels
  Estimated Time: ${estimatedExecutionTime.inSeconds}s
  Parallelism Factor: ${parallelismFactor.toStringAsFixed(2)}
  Critical Path Length: ${criticalPath.length}
  Node Types: ${nodeTypeAnalysis.entries.map((e) => '${e.key.name}:${e.value}').join(', ')}''';
  }
}

/// Exception thrown during workflow validation
class WorkflowValidationException implements Exception {
  final String message;
  final String? workflowId;
  final String? nodeId;

  const WorkflowValidationException(
    this.message, {
    this.workflowId,
    this.nodeId,
  });

  @override
  String toString() {
    final buffer = StringBuffer('WorkflowValidationException: $message');
    if (workflowId != null) {
      buffer.write(' (workflow: $workflowId)');
    }
    if (nodeId != null) {
      buffer.write(' (node: $nodeId)');
    }
    return buffer.toString();
  }
}

/// Factory for creating common workflow patterns
class WorkflowFactory {
  /// Create a simple sequential workflow
  static AgentWorkflow createSequential({
    required String name,
    required List<Agent> agents,
  }) {
    final workflow = AgentWorkflow(name: name);
    
    String? previousNodeId;
    for (int i = 0; i < agents.length; i++) {
      final agent = agents[i];
      final nodeId = 'node_$i';
      
      final node = WorkflowNodeFactory.createAgentNode(
        id: nodeId,
        agent: agent,
      );
      
      workflow.addNode(node, dependencies: previousNodeId != null ? [previousNodeId] : null);
      previousNodeId = nodeId;
    }
    
    return workflow;
  }

  /// Create a parallel workflow where all agents run simultaneously
  static AgentWorkflow createParallel({
    required String name,
    required List<Agent> agents,
    Agent? combinerAgent,
  }) {
    final workflow = AgentWorkflow(name: name);
    final nodeIds = <String>[];
    
    // Add parallel agent nodes
    for (int i = 0; i < agents.length; i++) {
      final agent = agents[i];
      final nodeId = 'parallel_$i';
      
      final node = WorkflowNodeFactory.createAgentNode(
        id: nodeId,
        agent: agent,
      );
      
      workflow.addNode(node);
      nodeIds.add(nodeId);
    }
    
    // Add optional combiner node
    if (combinerAgent != null) {
      final combinerNode = WorkflowNodeFactory.createAgentNode(
        id: 'combiner',
        agent: combinerAgent,
      );
      
      workflow.addNode(combinerNode, dependencies: nodeIds);
    }
    
    return workflow;
  }

  /// Create a conditional workflow with branching logic
  static AgentWorkflow createConditional({
    required String name,
    required String condition,
    required Agent trueAgent,
    required Agent falseAgent,
    Agent? combinerAgent,
  }) {
    final workflow = AgentWorkflow(name: name);
    
    // Add condition node
    final conditionNode = WorkflowNodeFactory.createConditionNode(
      id: 'condition',
      condition: condition,
    );
    workflow.addNode(conditionNode);
    
    // Add true branch
    final trueNode = WorkflowNodeFactory.createAgentNode(
      id: 'true_branch',
      agent: trueAgent,
    );
    workflow.addNode(trueNode, dependencies: ['condition']);
    
    // Add false branch
    final falseNode = WorkflowNodeFactory.createAgentNode(
      id: 'false_branch',
      agent: falseAgent,
    );
    workflow.addNode(falseNode, dependencies: ['condition']);
    
    // Add optional combiner
    if (combinerAgent != null) {
      final combinerNode = WorkflowNodeFactory.createAgentNode(
        id: 'combiner',
        agent: combinerAgent,
      );
      workflow.addNode(combinerNode, dependencies: ['true_branch', 'false_branch']);
    }
    
    return workflow;
  }
}

/// Template workflow implementations
class WorkflowTemplates {
  /// Create a code review workflow as shown in the specification
  static AgentWorkflow codeReviewWorkflow() {
    final workflow = AgentWorkflow(
      name: 'Code Review Workflow',
      description: 'Parallel analysis workflow for comprehensive code review',
    );

    // Create mock agents for demonstration
    final securityAgent = CustomAgent(
      id: 'security_agent',
      name: 'Security Analyzer',
      description: 'Analyzes code for security vulnerabilities',
      processor: (input, context) async {
        // Mock security analysis
        await Future.delayed(Duration(seconds: 2));
        return SecurityAnalysisResult(
          vulnerabilities: [],
          overallSecurity: SecurityLevel.medium,
          metadata: {'analysis_time': DateTime.now().toIso8601String()},
        );
      },
    );

    final performanceAgent = CustomAgent(
      id: 'performance_agent',
      name: 'Performance Analyzer',
      description: 'Analyzes code for performance issues',
      processor: (input, context) async {
        // Mock performance analysis
        await Future.delayed(Duration(seconds: 3));
        return PerformanceAnalysisResult(
          issues: [],
          optimizations: [],
          metrics: PerformanceMetrics(complexity: 0.7, linesOfCode: 150),
          metadata: {'analysis_time': DateTime.now().toIso8601String()},
        );
      },
    );

    final styleAgent = CustomAgent(
      id: 'style_agent',
      name: 'Style Analyzer',
      description: 'Analyzes code for style and formatting issues',
      processor: (input, context) async {
        // Mock style analysis
        await Future.delayed(Duration(seconds: 1));
        return StyleAnalysisResult(
          issues: [],
          metrics: StyleMetrics(
            totalLines: 150,
            totalIssues: 0,
            styleScore: 0.95,
          ),
          metadata: {'analysis_time': DateTime.now().toIso8601String()},
        );
      },
    );

    // Add parallel analysis nodes
    workflow.addNode(WorkflowNodeFactory.createAgentNode(
      id: 'security_check',
      agent: securityAgent,
    ));

    workflow.addNode(WorkflowNodeFactory.createAgentNode(
      id: 'performance_check',
      agent: performanceAgent,
    ));

    workflow.addNode(WorkflowNodeFactory.createAgentNode(
      id: 'style_check',
      agent: styleAgent,
    ));

    // Add combiner node
    final combinerAgent = CustomAgent(
      id: 'review_combiner',
      name: 'Review Combiner',
      description: 'Combines analysis results into final report',
      processor: (inputs, context) async {
        // Combine all analysis results
        final securityResult = context?.getNodeOutput('security_check');
        final performanceResult = context?.getNodeOutput('performance_check');
        final styleResult = context?.getNodeOutput('style_check');

        return {
          'review_report': {
            'security': securityResult,
            'performance': performanceResult,
            'style': styleResult,
            'overall_score': 0.85,
            'recommendation': 'Code looks good with minor improvements needed',
            'timestamp': DateTime.now().toIso8601String(),
          }
        };
      },
    );

    workflow.addNode(
      WorkflowNodeFactory.createAgentNode(
        id: 'combine',
        agent: combinerAgent,
      ),
      dependencies: ['security_check', 'performance_check', 'style_check'],
    );

    return workflow;
  }

  /// Create a data processing pipeline workflow
  static AgentWorkflow dataProcessingPipeline() {
    final workflow = AgentWorkflow(
      name: 'Data Processing Pipeline',
      description: 'Sequential data processing workflow',
    );

    // Data ingestion
    final ingestAgent = CustomAgent(
      id: 'data_ingest',
      name: 'Data Ingester',
      description: 'Ingests raw data from various sources',
      processor: (input, context) async {
        await Future.delayed(Duration(seconds: 2));
        return {'raw_data': input, 'ingested_at': DateTime.now().toIso8601String()};
      },
    );

    // Data validation
    final validateAgent = CustomAgent(
      id: 'data_validate',
      name: 'Data Validator',
      description: 'Validates ingested data quality',
      processor: (input, context) async {
        await Future.delayed(Duration(seconds: 1));
        return {'validated_data': input, 'validation_score': 0.95};
      },
    );

    // Data transformation
    final transformAgent = CustomAgent(
      id: 'data_transform',
      name: 'Data Transformer',
      description: 'Transforms data into target format',
      processor: (input, context) async {
        await Future.delayed(Duration(seconds: 3));
        return {'transformed_data': input, 'transform_version': '1.0'};
      },
    );

    // Data output
    final outputAgent = CustomAgent(
      id: 'data_output',
      name: 'Data Output',
      description: 'Outputs processed data',
      processor: (input, context) async {
        await Future.delayed(Duration(seconds: 1));
        return {'final_output': input, 'completed_at': DateTime.now().toIso8601String()};
      },
    );

    // Build sequential pipeline
    workflow.addNode(WorkflowNodeFactory.createAgentNode(id: 'ingest', agent: ingestAgent));
    workflow.addNode(WorkflowNodeFactory.createAgentNode(id: 'validate', agent: validateAgent), dependencies: ['ingest']);
    workflow.addNode(WorkflowNodeFactory.createAgentNode(id: 'transform', agent: transformAgent), dependencies: ['validate']);
    workflow.addNode(WorkflowNodeFactory.createAgentNode(id: 'output', agent: outputAgent), dependencies: ['transform']);

    return workflow;
  }
}