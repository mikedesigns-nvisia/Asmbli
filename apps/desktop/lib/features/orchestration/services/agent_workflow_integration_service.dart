import 'dart:async';
import 'package:agent_engine_core/models/agent.dart';
import 'package:agent_engine_core/services/agent_service.dart';

import '../models/reasoning_workflow.dart';
import '../models/logic_block.dart';
import 'workflow_persistence_service.dart';
import 'workflow_execution_service.dart';
import '../../../core/di/service_locator.dart';

/// Integration service connecting agents with their reasoning workflows
class AgentWorkflowIntegrationService {
  static AgentWorkflowIntegrationService? _instance;
  static AgentWorkflowIntegrationService get instance => _instance ??= AgentWorkflowIntegrationService._();
  AgentWorkflowIntegrationService._();

  /// Execute an agent's reasoning workflow for a given message
  Future<AgentWorkflowResponse> processAgentMessage({
    required String agentId,
    required String userId,
    required String message,
    Map<String, dynamic>? additionalContext,
  }) async {
    print('🤖 Processing agent message with workflow integration');
    print('   Agent: $agentId');
    print('   User: $userId');
    print('   Message: $message');

    try {
      // Get agent details
      final agentService = ServiceLocator.instance.get<AgentService>();
      final agent = await agentService.getAgent(agentId);
      
      if (agent == null) {
        throw Exception('Agent not found: $agentId');
      }

      // Check if agent has reasoning workflows enabled
      final hasReasoningFlows = agent.configuration['enableReasoningFlows'] == true;
      final workflowIds = agent.configuration['reasoningWorkflowIds'] as List<dynamic>? ?? [];
      final defaultWorkflowId = agent.configuration['defaultReasoningWorkflowId'] as String?;

      if (!hasReasoningFlows || workflowIds.isEmpty) {
        // Fallback to basic agent processing without workflows
        return _processBasicAgentResponse(agent, message, userId);
      }

      // Get the workflow to execute
      final workflowId = defaultWorkflowId ?? workflowIds.first.toString();
      final workflow = await _getAgentWorkflow(workflowId);
      
      if (workflow == null) {
        print('⚠️ Workflow not found, falling back to basic processing: $workflowId');
        return _processBasicAgentResponse(agent, message, userId);
      }

      // Execute the workflow
      return await _executeAgentWorkflow(
        agent: agent,
        workflow: workflow,
        message: message,
        userId: userId,
        additionalContext: additionalContext ?? {},
      );

    } catch (e) {
      print('❌ Error processing agent message: $e');
      
      // Fallback to basic response on error
      final agentService = ServiceLocator.instance.get<AgentService>();
      final agent = await agentService.getAgent(agentId);
      
      if (agent != null) {
        return _processBasicAgentResponse(agent, message, userId);
      }
      
      throw e;
    }
  }

  /// Execute agent workflow and return structured response
  Future<AgentWorkflowResponse> _executeAgentWorkflow({
    required Agent agent,
    required ReasoningWorkflow workflow,
    required String message,
    required String userId,
    required Map<String, dynamic> additionalContext,
  }) async {
    print('⚡ Executing workflow: ${workflow.name} for agent: ${agent.name}');

    final executionService = ServiceLocator.instance.get<WorkflowExecutionService>();
    
    // Prepare execution inputs
    final inputs = {
      'message': message,
      'agent_context': {
        'agent_id': agent.id,
        'agent_name': agent.name,
        'agent_description': agent.description,
        'agent_capabilities': agent.capabilities,
      },
      'user_context': {
        'user_id': userId,
      },
      ...additionalContext,
    };

    // Execute the workflow
    final executionContext = await executionService.executeWorkflow(
      workflow: workflow,
      agentId: agent.id,
      userId: userId,
      inputs: inputs,
    );

    // Convert execution result to agent response
    return _buildAgentResponseFromExecution(agent, workflow, executionContext);
  }

  /// Build agent response from workflow execution results
  AgentWorkflowResponse _buildAgentResponseFromExecution(
    Agent agent,
    ReasoningWorkflow workflow,
    WorkflowExecutionContext executionContext,
  ) {
    final outputs = executionContext.outputs;
    final finalOutput = outputs['final_output'] as String? ?? 
                      outputs['reasoning_output'] as String? ??
                      'I apologize, but I encountered an issue processing your request.';

    final executionSteps = executionContext.blockResults
        .where((r) => r.state == BlockExecutionState.completed)
        .map((r) => AgentWorkflowStep(
          blockId: r.blockId,
          blockType: _getBlockTypeFromResult(r, workflow),
          outputs: r.outputs,
          executionTime: r.executionTime,
          timestamp: r.timestamp,
        ))
        .toList();

    return AgentWorkflowResponse(
      agentId: agent.id,
      workflowId: workflow.id,
      executionId: executionContext.executionId,
      response: finalOutput,
      executionState: executionContext.state,
      executionSteps: executionSteps,
      totalExecutionTime: executionContext.totalExecutionTime,
      metadata: {
        'workflow_name': workflow.name,
        'blocks_executed': executionContext.blockResults.length,
        'agent_name': agent.name,
        'execution_timestamp': executionContext.startTime.toIso8601String(),
      },
    );
  }

  /// Get block type from execution result
  String _getBlockTypeFromResult(BlockExecutionResult result, ReasoningWorkflow workflow) {
    final block = workflow.blocks.firstWhere(
      (b) => b.id == result.blockId,
      orElse: () => LogicBlock(
        id: result.blockId,
        type: LogicBlockType.trace,
        label: 'Unknown',
        position: const Position(x: 0, y: 0),
      ),
    );
    
    return block.type.toString().split('.').last;
  }

  /// Fallback to basic agent processing without workflows
  Future<AgentWorkflowResponse> _processBasicAgentResponse(
    Agent agent,
    String message,
    String userId,
  ) async {
    print('🔄 Processing basic agent response (no workflow)');
    
    // Simulate basic agent processing
    final response = '''Hello! I'm ${agent.name}. ${agent.description}

I received your message: "$message"

I'm currently operating in basic mode. For enhanced reasoning capabilities, please configure visual reasoning workflows for this agent.

My capabilities include:
${agent.capabilities.map((cap) => '• ${cap.replaceAll('-', ' ')}').join('\n')}
    '''.trim();

    return AgentWorkflowResponse(
      agentId: agent.id,
      workflowId: null,
      executionId: null,
      response: response,
      executionState: WorkflowExecutionState.completed,
      executionSteps: [],
      totalExecutionTime: const Duration(milliseconds: 100),
      metadata: {
        'agent_name': agent.name,
        'processing_mode': 'basic',
        'execution_timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Get workflow associated with an agent
  Future<ReasoningWorkflow?> _getAgentWorkflow(String workflowId) async {
    try {
      final persistenceService = ServiceLocator.instance.get<WorkflowPersistenceService>();
      return await persistenceService.loadWorkflow(workflowId);
    } catch (e) {
      print('⚠️ Failed to load workflow $workflowId: $e');
      return null;
    }
  }

  /// Associate a workflow with an agent
  Future<void> associateWorkflowWithAgent({
    required String agentId,
    required String workflowId,
    bool setAsDefault = false,
  }) async {
    print('🔗 Associating workflow $workflowId with agent $agentId');
    
    final agentService = ServiceLocator.instance.get<AgentService>();
    final agent = await agentService.getAgent(agentId);
    
    if (agent == null) {
      throw Exception('Agent not found: $agentId');
    }

    // Update agent configuration
    final updatedConfig = Map<String, dynamic>.from(agent.configuration);
    
    // Enable reasoning flows
    updatedConfig['enableReasoningFlows'] = true;
    
    // Add workflow to list
    final workflowIds = List<String>.from(updatedConfig['reasoningWorkflowIds'] as List? ?? []);
    if (!workflowIds.contains(workflowId)) {
      workflowIds.add(workflowId);
    }
    updatedConfig['reasoningWorkflowIds'] = workflowIds;
    
    // Set as default if requested or if it's the first workflow
    if (setAsDefault || workflowIds.length == 1) {
      updatedConfig['defaultReasoningWorkflowId'] = workflowId;
    }

    // Update agent
    final updatedAgent = agent.copyWith(configuration: updatedConfig);
    await agentService.updateAgent(updatedAgent);
    
    print('✅ Workflow associated successfully');
  }

  /// Remove workflow association from agent
  Future<void> dissociateWorkflowFromAgent({
    required String agentId,
    required String workflowId,
  }) async {
    print('🔌 Dissociating workflow $workflowId from agent $agentId');
    
    final agentService = ServiceLocator.instance.get<AgentService>();
    final agent = await agentService.getAgent(agentId);
    
    if (agent == null) {
      throw Exception('Agent not found: $agentId');
    }

    // Update agent configuration
    final updatedConfig = Map<String, dynamic>.from(agent.configuration);
    
    // Remove workflow from list
    final workflowIds = List<String>.from(updatedConfig['reasoningWorkflowIds'] as List? ?? []);
    workflowIds.remove(workflowId);
    updatedConfig['reasoningWorkflowIds'] = workflowIds;
    
    // Clear default if it was the default workflow
    if (updatedConfig['defaultReasoningWorkflowId'] == workflowId) {
      if (workflowIds.isNotEmpty) {
        updatedConfig['defaultReasoningWorkflowId'] = workflowIds.first;
      } else {
        updatedConfig.remove('defaultReasoningWorkflowId');
        updatedConfig['enableReasoningFlows'] = false;
      }
    }

    // Update agent
    final updatedAgent = agent.copyWith(configuration: updatedConfig);
    await agentService.updateAgent(updatedAgent);
    
    print('✅ Workflow dissociated successfully');
  }

  /// Get all workflows associated with an agent
  Future<List<ReasoningWorkflow>> getAgentWorkflows(String agentId) async {
    final agentService = ServiceLocator.instance.get<AgentService>();
    final agent = await agentService.getAgent(agentId);
    
    if (agent == null) {
      return [];
    }

    final workflowIds = agent.configuration['reasoningWorkflowIds'] as List<dynamic>? ?? [];
    final workflows = <ReasoningWorkflow>[];
    
    for (final workflowId in workflowIds) {
      final workflow = await _getAgentWorkflow(workflowId.toString());
      if (workflow != null) {
        workflows.add(workflow);
      }
    }
    
    return workflows;
  }

  /// Check if an agent has reasoning workflows enabled
  Future<bool> hasReasoningWorkflows(String agentId) async {
    final agentService = ServiceLocator.instance.get<AgentService>();
    final agent = await agentService.getAgent(agentId);
    
    if (agent == null) {
      return false;
    }

    final hasReasoningFlows = agent.configuration['enableReasoningFlows'] == true;
    final workflowIds = agent.configuration['reasoningWorkflowIds'] as List<dynamic>? ?? [];
    
    return hasReasoningFlows && workflowIds.isNotEmpty;
  }
}

/// Response from agent workflow execution
class AgentWorkflowResponse {
  final String agentId;
  final String? workflowId;
  final String? executionId;
  final String response;
  final WorkflowExecutionState executionState;
  final List<AgentWorkflowStep> executionSteps;
  final Duration? totalExecutionTime;
  final Map<String, dynamic> metadata;

  const AgentWorkflowResponse({
    required this.agentId,
    this.workflowId,
    this.executionId,
    required this.response,
    required this.executionState,
    required this.executionSteps,
    this.totalExecutionTime,
    required this.metadata,
  });

  bool get isSuccessful => executionState == WorkflowExecutionState.completed;
  bool get usedWorkflow => workflowId != null;
  int get stepsExecuted => executionSteps.length;
}

/// Individual step in workflow execution
class AgentWorkflowStep {
  final String blockId;
  final String blockType;
  final Map<String, dynamic> outputs;
  final Duration executionTime;
  final DateTime timestamp;

  const AgentWorkflowStep({
    required this.blockId,
    required this.blockType,
    required this.outputs,
    required this.executionTime,
    required this.timestamp,
  });
}