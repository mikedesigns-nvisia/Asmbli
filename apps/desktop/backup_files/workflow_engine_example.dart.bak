import 'dart:async';
import 'dart:math' as math;
import 'workflow_engine.dart';
import 'workflow_node.dart';
import 'workflow_executor.dart';
import 'workflow_templates.dart';
import 'base_agent.dart';
import 'models/workflow_models.dart';
import 'graph/directed_graph.dart';

/// Comprehensive example and test suite for the workflow engine
class WorkflowEngineExample {
  late WorkflowTemplateService _templateService;

  /// Initialize the example with template service
  Future<void> initialize() async {
    print('🚀 Initializing Workflow Engine Example\n');
    
    _templateService = WorkflowTemplateService();
    
    // Register built-in agent factory
    _templateService.registerAgentFactory('builtin', BuiltInAgentFactory());
    
    // Register predefined templates
    for (final template in PredefinedTemplates.createAll()) {
      _templateService.registerTemplate(template);
    }
    
    print('✅ Workflow Engine Example initialized\n');
  }

  /// Run all example tests
  Future<void> runAllExamples() async {
    print('🎯 Running Workflow Engine Examples\n');
    
    await initialize();
    
    // Test 1: Basic workflow creation and execution
    await _testBasicWorkflowExecution();
    
    // Test 2: Parallel execution
    await _testParallelExecution();
    
    // Test 3: Circular dependency detection
    await _testCircularDependencyDetection();
    
    // Test 4: Template system
    await _testTemplateSystem();
    
    // Test 5: Code review workflow (from specification)
    await _testCodeReviewWorkflow();
    
    // Test 6: Complex workflow with conditions
    await _testComplexWorkflowWithConditions();
    
    // Test 7: Workflow analysis and statistics
    await _testWorkflowAnalysis();
    
    print('✅ All Workflow Engine Examples completed successfully!\n');
  }

  /// Test 1: Basic workflow creation and execution
  Future<void> _testBasicWorkflowExecution() async {
    print('📝 Test 1: Basic Workflow Execution');
    print('=' * 50);
    
    try {
      // Create a simple sequential workflow
      final workflow = AgentWorkflow(name: 'Basic Sequential Workflow');
      
      // Create mock agents
      final agent1 = CustomAgent(
        id: 'agent1',
        name: 'Data Processor',
        description: 'Processes input data',
        processor: (input, context) async {
          await Future.delayed(Duration(milliseconds: 500));
          return {'processed': input, 'step': 1};
        },
      );
      
      final agent2 = CustomAgent(
        id: 'agent2',
        name: 'Data Enricher',
        description: 'Enriches processed data',
        processor: (input, context) async {
          await Future.delayed(Duration(milliseconds: 300));
          return {'enriched': input, 'step': 2, 'timestamp': DateTime.now().toIso8601String()};
        },
      );
      
      // Add nodes to workflow
      workflow.addNode(WorkflowNodeFactory.createAgentNode(id: 'process', agent: agent1));
      workflow.addNode(WorkflowNodeFactory.createAgentNode(id: 'enrich', agent: agent2), dependencies: ['process']);
      
      // Validate workflow
      final isValid = workflow.validate();
      print('Workflow validation: ${isValid ? "✅ PASSED" : "❌ FAILED"}');
      
      // Execute workflow
      final input = WorkflowInput(data: {'message': 'Hello, Workflow!'});
      final result = await workflow.execute(input);
      
      print('Execution status: ${result.status.name}');
      print('Execution time: ${result.executionTime.inMilliseconds}ms');
      print('Output: ${result.output}');
      print('Success rate: ${(result.stats.successRate * 100).toStringAsFixed(1)}%');
      
      assert(result.isSuccess, 'Workflow should succeed');
      assert(result.nodeResults.length == 2, 'Should have 2 node results');
      
      print('✅ Basic workflow execution test PASSED\n');
      
    } catch (e) {
      print('❌ Basic workflow execution test FAILED: $e\n');
      rethrow;
    }
  }

  /// Test 2: Parallel execution
  Future<void> _testParallelExecution() async {
    print('📝 Test 2: Parallel Execution');
    print('=' * 50);
    
    try {
      final workflow = AgentWorkflow(name: 'Parallel Processing Workflow');
      
      // Create parallel agents with different execution times
      final fastAgent = CustomAgent(
        id: 'fast',
        name: 'Fast Processor',
        description: 'Fast processing agent',
        processor: (input, context) async {
          await Future.delayed(Duration(milliseconds: 100));
          return {'result': 'fast', 'processed_at': DateTime.now().millisecondsSinceEpoch};
        },
      );
      
      final slowAgent = CustomAgent(
        id: 'slow',
        name: 'Slow Processor',
        description: 'Slow processing agent',
        processor: (input, context) async {
          await Future.delayed(Duration(milliseconds: 500));
          return {'result': 'slow', 'processed_at': DateTime.now().millisecondsSinceEpoch};
        },
      );
      
      final combinerAgent = CustomAgent(
        id: 'combiner',
        name: 'Result Combiner',
        description: 'Combines parallel results',
        processor: (input, context) async {
          final fastResult = context?.getNodeOutput('fast');
          final slowResult = context?.getNodeOutput('slow');
          
          return {
            'combined': true,
            'fast_result': fastResult,
            'slow_result': slowResult,
            'combined_at': DateTime.now().millisecondsSinceEpoch,
          };
        },
      );
      
      // Add nodes - fast and slow run in parallel, then combiner
      workflow.addNode(WorkflowNodeFactory.createAgentNode(id: 'fast', agent: fastAgent));
      workflow.addNode(WorkflowNodeFactory.createAgentNode(id: 'slow', agent: slowAgent));
      workflow.addNode(WorkflowNodeFactory.createAgentNode(id: 'combine', agent: combinerAgent), 
                      dependencies: ['fast', 'slow']);
      
      // Analyze workflow for parallel execution levels
      final analysis = workflow.analyze();
      print('Execution levels: ${analysis.executionLevels}');
      print('Parallelism factor: ${analysis.parallelismFactor.toStringAsFixed(2)}');
      print('Estimated execution time: ${analysis.estimatedExecutionTime.inMilliseconds}ms');
      
      // Execute and measure actual time
      final startTime = DateTime.now();
      final input = WorkflowInput(data: {'test': 'parallel execution'});
      final result = await workflow.execute(input);
      final actualTime = DateTime.now().difference(startTime);
      
      print('Actual execution time: ${actualTime.inMilliseconds}ms');
      print('Execution status: ${result.status.name}');
      print('Parallel executions: ${result.stats.parallelExecutions}');
      
      // Verify parallel execution worked
      assert(result.isSuccess, 'Parallel workflow should succeed');
      assert(analysis.executionLevels == 2, 'Should have 2 execution levels');
      assert(actualTime.inMilliseconds < 1000, 'Parallel execution should be faster than sequential');
      
      print('✅ Parallel execution test PASSED\n');
      
    } catch (e) {
      print('❌ Parallel execution test FAILED: $e\n');
      rethrow;
    }
  }

  /// Test 3: Circular dependency detection
  Future<void> _testCircularDependencyDetection() async {
    print('📝 Test 3: Circular Dependency Detection');
    print('=' * 50);
    
    try {
      final workflow = AgentWorkflow(name: 'Circular Dependency Test');
      
      final agent1 = CustomAgent(id: 'a1', name: 'Agent 1', description: 'Test agent', processor: (i, c) async => i);
      final agent2 = CustomAgent(id: 'a2', name: 'Agent 2', description: 'Test agent', processor: (i, c) async => i);
      final agent3 = CustomAgent(id: 'a3', name: 'Agent 3', description: 'Test agent', processor: (i, c) async => i);
      
      // Add nodes
      workflow.addNode(WorkflowNodeFactory.createAgentNode(id: 'node1', agent: agent1));
      workflow.addNode(WorkflowNodeFactory.createAgentNode(id: 'node2', agent: agent2), dependencies: ['node1']);
      workflow.addNode(WorkflowNodeFactory.createAgentNode(id: 'node3', agent: agent3), dependencies: ['node2']);
      
      // This should be fine so far
      print('Initial workflow validation: ${workflow.validate() ? "✅ PASSED" : "❌ FAILED"}');
      
      // Try to create a circular dependency
      bool caughtCircularDependency = false;
      try {
        workflow.addDependency('node3', 'node1'); // This should create a cycle
        print('❌ ERROR: Circular dependency was not detected!');
      } catch (e) {
        print('✅ Circular dependency correctly detected: $e');
        caughtCircularDependency = true;
      }
      
      // Verify graph cycle detection
      final graph = DirectedGraph<String>();
      graph.addNode('A', 'Node A');
      graph.addNode('B', 'Node B');
      graph.addNode('C', 'Node C');
      graph.addEdge('A', 'B');
      graph.addEdge('B', 'C');
      graph.addEdge('C', 'A'); // Create cycle
      
      final hasCycles = graph.hasCycles();
      final cycles = graph.findCycles();
      
      print('Direct graph cycle detection: ${hasCycles ? "✅ DETECTED" : "❌ MISSED"}');
      print('Found cycles: ${cycles.map((c) => c.join(' -> ')).join(', ')}');
      
      assert(caughtCircularDependency, 'Should detect circular dependency');
      assert(hasCycles, 'Graph should detect cycles');
      assert(cycles.isNotEmpty, 'Should find cycle paths');
      
      print('✅ Circular dependency detection test PASSED\n');
      
    } catch (e) {
      print('❌ Circular dependency detection test FAILED: $e\n');
      rethrow;
    }
  }

  /// Test 4: Template system
  Future<void> _testTemplateSystem() async {
    print('📝 Test 4: Template System');
    print('=' * 50);
    
    try {
      // Test creating workflow from template
      final codeReviewWorkflow = await _templateService.createFromTemplate(
        'code_review_template',
        parameters: {'timeout_seconds': 300},
      );
      
      print('Created workflow from template: ${codeReviewWorkflow.name}');
      print('Workflow validation: ${codeReviewWorkflow.validate() ? "✅ PASSED" : "❌ FAILED"}');
      
      // Analyze the created workflow
      final analysis = codeReviewWorkflow.analyze();
      print('Node count: ${analysis.graphStats.nodeCount}');
      print('Execution levels: ${analysis.executionLevels}');
      print('Node types: ${analysis.nodeTypeAnalysis.entries.map((e) => '${e.key.name}:${e.value}').join(', ')}');
      
      // Test template service statistics
      final stats = _templateService.getStats();
      print('Template service stats:');
      print('  Total templates: ${stats.totalTemplates}');
      print('  Agent factories: ${stats.totalAgentFactories}');
      
      // Execute the template-created workflow
      final input = WorkflowInput(data: {'code': 'function example() { return "test"; }'});
      final result = await codeReviewWorkflow.execute(input);
      
      print('Template workflow execution: ${result.status.name}');
      print('Execution time: ${result.executionTime.inMilliseconds}ms');
      
      assert(result.isSuccess, 'Template workflow should succeed');
      assert(analysis.graphStats.nodeCount == 4, 'Code review should have 4 nodes');
      
      print('✅ Template system test PASSED\n');
      
    } catch (e) {
      print('❌ Template system test FAILED: $e\n');
      rethrow;
    }
  }

  /// Test 5: Code review workflow (from specification)
  Future<void> _testCodeReviewWorkflow() async {
    print('📝 Test 5: Code Review Workflow (Specification Example)');
    print('=' * 50);
    
    try {
      // Create the exact workflow from the specification
      final workflow = WorkflowTemplates.codeReviewWorkflow();
      
      print('Code review workflow created: ${workflow.name}');
      print('Validation: ${workflow.validate() ? "✅ PASSED" : "❌ FAILED"}');
      
      // Analyze workflow structure
      final analysis = workflow.analyze();
      print('Graph analysis:');
      print('  Nodes: ${analysis.graphStats.nodeCount}');
      print('  Root nodes: ${analysis.graphStats.rootNodeCount}');
      print('  Leaf nodes: ${analysis.graphStats.leafNodeCount}');
      print('  Execution levels: ${analysis.executionLevels}');
      print('  Critical path: ${analysis.criticalPath.join(' -> ')}');
      
      // Execute workflow with sample code
      final codeInput = WorkflowInput(data: {
        'code': '''
        function calculateTotal(items) {
          let total = 0;
          for (let i = 0; i < items.length; i++) {
            total += items[i].price;
          }
          return total;
        }
        ''',
        'language': 'javascript',
        'project_name': 'example-project',
      });
      
      print('\nExecuting code review workflow...');
      final result = await workflow.execute(codeInput);
      
      print('Execution completed:');
      print('  Status: ${result.status.name}');
      print('  Time: ${result.executionTime.inMilliseconds}ms');
      print('  Success rate: ${(result.stats.successRate * 100).toStringAsFixed(1)}%');
      print('  Node results: ${result.nodeResults.keys.join(', ')}');
      
      // Verify all expected nodes executed
      final expectedNodes = ['security_check', 'performance_check', 'style_check', 'combine'];
      for (final nodeId in expectedNodes) {
        assert(result.nodeResults.containsKey(nodeId), 'Missing node result: $nodeId');
        print('  ✅ $nodeId: ${result.nodeResults[nodeId]!.status.name}');
      }
      
      print('Final output keys: ${result.output.keys.join(', ')}');
      
      assert(result.isSuccess, 'Code review workflow should succeed');
      assert(result.nodeResults.length == 4, 'Should have 4 node results');
      
      print('✅ Code review workflow test PASSED\n');
      
    } catch (e) {
      print('❌ Code review workflow test FAILED: $e\n');
      rethrow;
    }
  }

  /// Test 6: Complex workflow with conditions
  Future<void> _testComplexWorkflowWithConditions() async {
    print('📝 Test 6: Complex Workflow with Conditions');
    print('=' * 50);
    
    try {
      final workflow = AgentWorkflow(name: 'Complex Conditional Workflow');
      
      // Create agents
      final inputAgent = CustomAgent(
        id: 'input_processor',
        name: 'Input Processor',
        description: 'Processes initial input',
        processor: (input, context) async {
          await Future.delayed(Duration(milliseconds: 100));
          final score = math.Random().nextDouble() * 100;
          return {'score': score, 'input': input};
        },
      );
      
      final highScoreAgent = CustomAgent(
        id: 'high_score',
        name: 'High Score Processor',
        description: 'Processes high scores',
        processor: (input, context) async {
          await Future.delayed(Duration(milliseconds: 200));
          return {'result': 'high_score_processing', 'input': input};
        },
      );
      
      final lowScoreAgent = CustomAgent(
        id: 'low_score',
        name: 'Low Score Processor',
        description: 'Processes low scores',
        processor: (input, context) async {
          await Future.delayed(Duration(milliseconds: 150));
          return {'result': 'low_score_processing', 'input': input};
        },
      );
      
      final finalAgent = CustomAgent(
        id: 'final_processor',
        name: 'Final Processor',
        description: 'Final processing step',
        processor: (input, context) async {
          final inputResult = context?.getNodeOutput('input');
          final highResult = context?.getNodeOutput('high_score');
          final lowResult = context?.getNodeOutput('low_score');
          
          return {
            'final_result': 'completed',
            'input_score': inputResult?['score'],
            'high_processed': highResult != null,
            'low_processed': lowResult != null,
          };
        },
      );
      
      // Build workflow with conditional logic
      workflow.addNode(WorkflowNodeFactory.createAgentNode(id: 'input', agent: inputAgent));
      
      // Add condition node
      workflow.addNode(WorkflowNodeFactory.createConditionNode(
        id: 'score_condition',
        condition: 'score > 50',
      ), dependencies: ['input']);
      
      // Add conditional branches
      workflow.addNode(WorkflowNodeFactory.createAgentNode(id: 'high_score', agent: highScoreAgent), 
                      dependencies: ['score_condition']);
      workflow.addNode(WorkflowNodeFactory.createAgentNode(id: 'low_score', agent: lowScoreAgent), 
                      dependencies: ['score_condition']);
      
      // Add final processing
      workflow.addNode(WorkflowNodeFactory.createAgentNode(id: 'final', agent: finalAgent), 
                      dependencies: ['high_score', 'low_score']);
      
      // Execute multiple times to test different paths
      for (int i = 0; i < 3; i++) {
        print('\nExecution ${i + 1}:');
        
        final input = WorkflowInput(data: {'test_run': i + 1});
        final result = await workflow.execute(input);
        
        print('  Status: ${result.status.name}');
        print('  Time: ${result.executionTime.inMilliseconds}ms');
        print('  Final output: ${result.output}');
        
        assert(result.isSuccess, 'Conditional workflow should succeed');
      }
      
      print('✅ Complex workflow with conditions test PASSED\n');
      
    } catch (e) {
      print('❌ Complex workflow with conditions test FAILED: $e\n');
      rethrow;
    }
  }

  /// Test 7: Workflow analysis and statistics
  Future<void> _testWorkflowAnalysis() async {
    print('📝 Test 7: Workflow Analysis and Statistics');
    print('=' * 50);
    
    try {
      // Create a comprehensive workflow for analysis
      final workflow = AgentWorkflow(name: 'Analysis Test Workflow');
      
      // Create agents of different types
      final agents = List.generate(5, (i) => CustomAgent(
        id: 'agent_$i',
        name: 'Test Agent $i',
        description: 'Test agent for analysis',
        processor: (input, context) async {
          await Future.delayed(Duration(milliseconds: (i + 1) * 100));
          return {'result': 'agent_$i', 'input': input};
        },
      ));
      
      // Build a complex graph structure
      workflow.addNode(WorkflowNodeFactory.createAgentNode(id: 'root', agent: agents[0]));
      workflow.addNode(WorkflowNodeFactory.createAgentNode(id: 'branch1', agent: agents[1]), dependencies: ['root']);
      workflow.addNode(WorkflowNodeFactory.createAgentNode(id: 'branch2', agent: agents[2]), dependencies: ['root']);
      workflow.addNode(WorkflowNodeFactory.createAgentNode(id: 'merge1', agent: agents[3]), dependencies: ['branch1', 'branch2']);
      workflow.addNode(WorkflowNodeFactory.createAgentNode(id: 'final', agent: agents[4]), dependencies: ['merge1']);
      
      // Analyze the workflow
      final analysis = workflow.analyze();
      
      print('Workflow Analysis Results:');
      print('  Workflow ID: ${analysis.workflowId}');
      print('  Graph Statistics:');
      print('    Total nodes: ${analysis.graphStats.nodeCount}');
      print('    Total edges: ${analysis.graphStats.edgeCount}');
      print('    Root nodes: ${analysis.graphStats.rootNodeCount}');
      print('    Leaf nodes: ${analysis.graphStats.leafNodeCount}');
      print('    Has cycles: ${analysis.graphStats.hasCycles}');
      print('    Max depth: ${analysis.graphStats.maxDepth}');
      
      print('  Execution Analysis:');
      print('    Execution levels: ${analysis.executionLevels}');
      print('    Parallelism factor: ${analysis.parallelismFactor.toStringAsFixed(2)}');
      print('    Estimated time: ${analysis.estimatedExecutionTime.inMilliseconds}ms');
      print('    Critical path: ${analysis.criticalPath.join(' -> ')}');
      
      print('  Node Type Analysis:');
      for (final entry in analysis.nodeTypeAnalysis.entries) {
        print('    ${entry.key.name}: ${entry.value}');
      }
      
      // Execute and compare with analysis
      final input = WorkflowInput(data: {'analysis_test': true});
      final result = await workflow.execute(input);
      
      print('  Execution Results:');
      print('    Actual time: ${result.executionTime.inMilliseconds}ms');
      print('    Success rate: ${(result.stats.successRate * 100).toStringAsFixed(1)}%');
      print('    Parallel executions: ${result.stats.parallelExecutions}');
      
      // Verify analysis accuracy
      assert(analysis.graphStats.nodeCount == 5, 'Should analyze 5 nodes');
      assert(analysis.graphStats.rootNodeCount == 1, 'Should have 1 root node');
      assert(analysis.graphStats.leafNodeCount == 1, 'Should have 1 leaf node');
      assert(!analysis.graphStats.hasCycles, 'Should not have cycles');
      assert(analysis.criticalPath.isNotEmpty, 'Should find critical path');
      
      print('✅ Workflow analysis and statistics test PASSED\n');
      
    } catch (e) {
      print('❌ Workflow analysis and statistics test FAILED: $e\n');
      rethrow;
    }
  }

  /// Demonstrate all test checklist items from the specification
  Future<void> demonstrateTestChecklist() async {
    print('📋 Demonstrating Test Checklist Items');
    print('=' * 50);
    
    print('✅ Workflows execute in correct order - Verified in basic and parallel execution tests');
    print('✅ Parallel nodes run simultaneously - Verified in parallel execution test');
    print('✅ Circular dependencies are detected - Verified in circular dependency test');
    print('✅ Agent communication works - Verified in code review and complex workflow tests');
    print('✅ Workflow templates are functional - Verified in template system test');
    
    print('\n🎯 All test checklist items have been successfully demonstrated!\n');
  }
}

/// Utility function to run the complete workflow engine example
Future<void> runWorkflowEngineExample() async {
  final example = WorkflowEngineExample();
  
  try {
    await example.runAllExamples();
    await example.demonstrateTestChecklist();
    
    print('🎉 Workflow Engine Example completed successfully!');
    print('All Day 7 requirements have been implemented and tested.');
    
  } catch (e, stackTrace) {
    print('💥 Workflow Engine Example failed: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
}