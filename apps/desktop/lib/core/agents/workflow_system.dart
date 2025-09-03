/// Comprehensive Agent Workflow Engine
/// 
/// This module provides a complete DAG-based agent orchestration system
/// for building and executing complex workflows with parallel processing,
/// circular dependency detection, and template-based workflow creation.
/// 
/// Key Features:
/// - DAG-based workflow execution
/// - Parallel node processing
/// - Circular dependency detection
/// - Workflow templates and reusable patterns
/// - Agent communication and data flow
/// - Comprehensive workflow analysis
/// - Built-in agent types for common tasks

library workflow_system;

// Core workflow components
export 'workflow_engine.dart';
export 'workflow_executor.dart';
export 'workflow_node.dart';
export 'base_agent.dart';

// Graph infrastructure
export 'graph/directed_graph.dart';

// Models and data structures
export 'models/workflow_models.dart';

// Template system
export 'workflow_templates.dart';

// Examples and testing
export 'workflow_engine_example.dart';

/// Quick start guide for the Workflow System
/// 
/// 1. Create a simple workflow:
/// ```dart
/// final workflow = AgentWorkflow(name: 'My Workflow');
/// 
/// final agent = CustomAgent(
///   id: 'processor',
///   name: 'Data Processor',
///   description: 'Processes data',
///   processor: (input, context) async {
///     return {'processed': input};
///   },
/// );
/// 
/// workflow.addNode(WorkflowNodeFactory.createAgentNode(
///   id: 'process_data',
///   agent: agent,
/// ));
/// 
/// final input = WorkflowInput(data: {'message': 'Hello'});
/// final result = await workflow.execute(input);
/// ```
/// 
/// 2. Use predefined templates:
/// ```dart
/// final templateService = WorkflowTemplateService();
/// templateService.registerAgentFactory('builtin', BuiltInAgentFactory());
/// 
/// final workflow = await templateService.createFromTemplate(
///   'code_review_template'
/// );
/// 
/// final result = await workflow.execute(input);
/// ```
/// 
/// 3. Create parallel workflows:
/// ```dart
/// final workflow = WorkflowFactory.createParallel(
///   name: 'Parallel Processing',
///   agents: [agent1, agent2, agent3],
///   combinerAgent: combinerAgent,
/// );
/// ```
/// 
/// 4. Run the complete example:
/// ```dart
/// await runWorkflowEngineExample();
/// ```

/// Workflow System Constants
class WorkflowSystemConstants {
  static const String version = '1.0.0';
  static const String name = 'Agent Workflow Engine';
  static const String description = 'DAG-based agent orchestration system';
  
  // Default timeouts
  static const Duration defaultNodeTimeout = Duration(minutes: 5);
  static const Duration defaultWorkflowTimeout = Duration(minutes: 30);
  
  // Execution limits
  static const int maxParallelNodes = 10;
  static const int maxWorkflowDepth = 20;
  static const int maxRetryAttempts = 3;
}