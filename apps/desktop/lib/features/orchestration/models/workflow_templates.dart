import 'logic_block.dart';
import 'reasoning_workflow.dart';

/// Pre-built workflow templates for common reasoning patterns
class WorkflowTemplates {
  WorkflowTemplates._();

  /// Get all available workflow templates
  static List<WorkflowTemplate> getAllTemplates() {
    return [
      simpleReasoningFlow(),
      decisionGatewayFlow(),
      researchAndAnalysisFlow(),
      problemSolvingFlow(),
      conversationDesignFlow(),
    ];
  }

  /// Simple reasoning flow: Goal → Context → Reasoning → Exit
  static WorkflowTemplate simpleReasoningFlow() {
    final workflow = ReasoningWorkflow.empty().copyWith(
      name: 'Simple Reasoning Flow',
      description: 'Basic reasoning workflow with goal setting, context gathering, and reasoning.',
    );

    final blocks = [
      LogicBlock(
        id: 'goal_1',
        type: LogicBlockType.goal,
        label: 'Define Goal',
        position: const Position(x: 100, y: 100),
        properties: {
          'description': 'Define the objective and desired outcome',
          'constraints': <String>[],
          'successCriteria': 'Clear, actionable goal is established',
        },
      ),
      LogicBlock(
        id: 'context_1',
        type: LogicBlockType.context,
        label: 'Gather Context',
        position: const Position(x: 300, y: 100),
        properties: {
          'sources': <String>['user_input', 'knowledge_base'],
          'filters': <String>['relevant', 'recent'],
          'maxResults': 10,
        },
      ),
      LogicBlock(
        id: 'reasoning_1',
        type: LogicBlockType.reasoning,
        label: 'Analyze & Reason',
        position: const Position(x: 500, y: 100),
        properties: {
          'pattern': 'react',
          'maxIterations': 3,
        },
      ),
      LogicBlock(
        id: 'exit_1',
        type: LogicBlockType.exit,
        label: 'Deliver Result',
        position: const Position(x: 700, y: 100),
        properties: {
          'validationChecks': <String>['completeness', 'accuracy'],
          'partialResults': true,
        },
      ),
    ];

    final connections = [
      BlockConnection(
        id: 'conn_1',
        sourceBlockId: 'goal_1',
        targetBlockId: 'context_1',
        sourcePin: 'output',
        targetPin: 'input',
        type: ConnectionType.execution,
      ),
      BlockConnection(
        id: 'conn_2',
        sourceBlockId: 'context_1',
        targetBlockId: 'reasoning_1',
        sourcePin: 'output',
        targetPin: 'input',
        type: ConnectionType.execution,
      ),
      BlockConnection(
        id: 'conn_3',
        sourceBlockId: 'reasoning_1',
        targetBlockId: 'exit_1',
        sourcePin: 'output',
        targetPin: 'input',
        type: ConnectionType.execution,
      ),
    ];

    return WorkflowTemplate(
      id: 'simple_reasoning',
      name: 'Simple Reasoning Flow',
      description: 'A straightforward reasoning workflow for basic problem-solving',
      category: WorkflowCategory.basic,
      workflow: workflow.copyWith(
        blocks: blocks,
        connections: connections,
        tags: ['basic', 'reasoning', 'analysis'],
        isTemplate: true,
      ),
      tags: ['basic', 'reasoning', 'analysis'],
    );
  }

  /// Decision gateway flow with fallback handling
  static WorkflowTemplate decisionGatewayFlow() {
    final workflow = ReasoningWorkflow.empty().copyWith(
      name: 'Decision Gateway Flow',
      description: 'Workflow with confidence-based routing and fallback handling.',
    );

    final blocks = [
      LogicBlock(
        id: 'goal_2',
        type: LogicBlockType.goal,
        label: 'Set Decision Goal',
        position: const Position(x: 100, y: 150),
        properties: {
          'description': 'Define the decision to be made',
          'constraints': <String>['data_driven', 'confident'],
          'successCriteria': 'Clear decision with high confidence',
        },
      ),
      LogicBlock(
        id: 'context_2',
        type: LogicBlockType.context,
        label: 'Collect Information',
        position: const Position(x: 300, y: 150),
        properties: {
          'sources': <String>['database', 'external_api', 'user_input'],
          'filters': <String>['verified', 'relevant'],
          'maxResults': 15,
        },
      ),
      LogicBlock(
        id: 'reasoning_2',
        type: LogicBlockType.reasoning,
        label: 'Initial Analysis',
        position: const Position(x: 500, y: 150),
        properties: {
          'pattern': 'cot',
          'maxIterations': 2,
        },
      ),
      LogicBlock(
        id: 'gateway_1',
        type: LogicBlockType.gateway,
        label: 'Confidence Check',
        position: const Position(x: 700, y: 150),
        properties: {
          'confidence': 0.8,
          'strategy': 'llm_decision',
        },
      ),
      LogicBlock(
        id: 'reasoning_3',
        type: LogicBlockType.reasoning,
        label: 'Deep Analysis',
        position: const Position(x: 900, y: 100),
        properties: {
          'pattern': 'tot',
          'maxIterations': 5,
        },
      ),
      LogicBlock(
        id: 'fallback_1',
        type: LogicBlockType.fallback,
        label: 'Handle Uncertainty',
        position: const Position(x: 900, y: 200),
        properties: {
          'retryCount': 1,
          'escalationPath': 'human',
        },
      ),
      LogicBlock(
        id: 'exit_2',
        type: LogicBlockType.exit,
        label: 'Final Decision',
        position: const Position(x: 1100, y: 150),
        properties: {
          'validationChecks': <String>['confidence_level', 'reasoning_quality'],
          'partialResults': false,
        },
      ),
    ];

    final connections = [
      BlockConnection(
        id: 'conn_4',
        sourceBlockId: 'goal_2',
        targetBlockId: 'context_2',
        sourcePin: 'output',
        targetPin: 'input',
        type: ConnectionType.execution,
      ),
      BlockConnection(
        id: 'conn_5',
        sourceBlockId: 'context_2',
        targetBlockId: 'reasoning_2',
        sourcePin: 'output',
        targetPin: 'input',
        type: ConnectionType.execution,
      ),
      BlockConnection(
        id: 'conn_6',
        sourceBlockId: 'reasoning_2',
        targetBlockId: 'gateway_1',
        sourcePin: 'output',
        targetPin: 'input',
        type: ConnectionType.execution,
      ),
      BlockConnection(
        id: 'conn_7',
        sourceBlockId: 'gateway_1',
        targetBlockId: 'reasoning_3',
        sourcePin: 'high_confidence',
        targetPin: 'input',
        type: ConnectionType.execution,
      ),
      BlockConnection(
        id: 'conn_8',
        sourceBlockId: 'gateway_1',
        targetBlockId: 'fallback_1',
        sourcePin: 'low_confidence',
        targetPin: 'input',
        type: ConnectionType.execution,
      ),
      BlockConnection(
        id: 'conn_9',
        sourceBlockId: 'reasoning_3',
        targetBlockId: 'exit_2',
        sourcePin: 'output',
        targetPin: 'input',
        type: ConnectionType.execution,
      ),
      BlockConnection(
        id: 'conn_10',
        sourceBlockId: 'fallback_1',
        targetBlockId: 'exit_2',
        sourcePin: 'output',
        targetPin: 'input',
        type: ConnectionType.execution,
      ),
    ];

    return WorkflowTemplate(
      id: 'decision_gateway',
      name: 'Decision Gateway Flow',
      description: 'Confidence-based routing with fallback for uncertain decisions',
      category: WorkflowCategory.advanced,
      workflow: workflow.copyWith(
        blocks: blocks,
        connections: connections,
        tags: ['decision', 'gateway', 'fallback', 'confidence'],
        isTemplate: true,
      ),
      tags: ['decision', 'gateway', 'fallback', 'confidence'],
    );
  }

  /// Research and analysis workflow with tracing
  static WorkflowTemplate researchAndAnalysisFlow() {
    final workflow = ReasoningWorkflow.empty().copyWith(
      name: 'Research & Analysis Flow',
      description: 'Comprehensive research workflow with detailed tracing and analysis.',
    );

    final blocks = [
      LogicBlock(
        id: 'goal_3',
        type: LogicBlockType.goal,
        label: 'Research Objective',
        position: const Position(x: 100, y: 200),
        properties: {
          'description': 'Define research question and scope',
          'constraints': <String>['comprehensive', 'evidence_based'],
          'successCriteria': 'Thorough analysis with supporting evidence',
        },
      ),
      LogicBlock(
        id: 'trace_1',
        type: LogicBlockType.trace,
        label: 'Start Trace',
        position: const Position(x: 100, y: 300),
        properties: {
          'level': 'info',
          'includeState': true,
        },
      ),
      LogicBlock(
        id: 'context_3',
        type: LogicBlockType.context,
        label: 'Gather Sources',
        position: const Position(x: 300, y: 200),
        properties: {
          'sources': <String>['research_db', 'web_search', 'documents'],
          'filters': <String>['peer_reviewed', 'recent', 'authoritative'],
          'maxResults': 25,
        },
      ),
      LogicBlock(
        id: 'reasoning_4',
        type: LogicBlockType.reasoning,
        label: 'Analyze Evidence',
        position: const Position(x: 500, y: 200),
        properties: {
          'pattern': 'self_consistency',
          'maxIterations': 4,
        },
      ),
      LogicBlock(
        id: 'trace_2',
        type: LogicBlockType.trace,
        label: 'Analysis Trace',
        position: const Position(x: 500, y: 300),
        properties: {
          'level': 'debug',
          'includeState': true,
        },
      ),
      LogicBlock(
        id: 'reasoning_5',
        type: LogicBlockType.reasoning,
        label: 'Synthesize Findings',
        position: const Position(x: 700, y: 200),
        properties: {
          'pattern': 'cot',
          'maxIterations': 3,
        },
      ),
      LogicBlock(
        id: 'exit_3',
        type: LogicBlockType.exit,
        label: 'Research Report',
        position: const Position(x: 900, y: 200),
        properties: {
          'validationChecks': <String>['evidence_quality', 'logical_coherence', 'completeness'],
          'partialResults': true,
        },
      ),
    ];

    final connections = [
      BlockConnection(
        id: 'conn_11',
        sourceBlockId: 'goal_3',
        targetBlockId: 'context_3',
        sourcePin: 'output',
        targetPin: 'input',
        type: ConnectionType.execution,
      ),
      BlockConnection(
        id: 'conn_12',
        sourceBlockId: 'goal_3',
        targetBlockId: 'trace_1',
        sourcePin: 'output',
        targetPin: 'input',
        type: ConnectionType.data,
      ),
      BlockConnection(
        id: 'conn_13',
        sourceBlockId: 'context_3',
        targetBlockId: 'reasoning_4',
        sourcePin: 'output',
        targetPin: 'input',
        type: ConnectionType.execution,
      ),
      BlockConnection(
        id: 'conn_14',
        sourceBlockId: 'reasoning_4',
        targetBlockId: 'trace_2',
        sourcePin: 'output',
        targetPin: 'input',
        type: ConnectionType.data,
      ),
      BlockConnection(
        id: 'conn_15',
        sourceBlockId: 'reasoning_4',
        targetBlockId: 'reasoning_5',
        sourcePin: 'output',
        targetPin: 'input',
        type: ConnectionType.execution,
      ),
      BlockConnection(
        id: 'conn_16',
        sourceBlockId: 'reasoning_5',
        targetBlockId: 'exit_3',
        sourcePin: 'output',
        targetPin: 'input',
        type: ConnectionType.execution,
      ),
    ];

    return WorkflowTemplate(
      id: 'research_analysis',
      name: 'Research & Analysis Flow',
      description: 'Comprehensive research workflow with detailed logging and evidence analysis',
      category: WorkflowCategory.research,
      workflow: workflow.copyWith(
        blocks: blocks,
        connections: connections,
        tags: ['research', 'analysis', 'evidence', 'tracing'],
        isTemplate: true,
      ),
      tags: ['research', 'analysis', 'evidence', 'tracing'],
    );
  }

  /// Problem-solving workflow with multiple reasoning approaches
  static WorkflowTemplate problemSolvingFlow() {
    final workflow = ReasoningWorkflow.empty().copyWith(
      name: 'Problem Solving Flow',
      description: 'Multi-approach problem solving with parallel reasoning paths.',
    );

    final blocks = [
      LogicBlock(
        id: 'goal_4',
        type: LogicBlockType.goal,
        label: 'Problem Definition',
        position: const Position(x: 100, y: 250),
        properties: {
          'description': 'Clearly define the problem to solve',
          'constraints': <String>['specific', 'measurable', 'actionable'],
          'successCriteria': 'Effective solution with clear implementation path',
        },
      ),
      LogicBlock(
        id: 'context_4',
        type: LogicBlockType.context,
        label: 'Problem Context',
        position: const Position(x: 300, y: 250),
        properties: {
          'sources': <String>['problem_space', 'constraints', 'resources'],
          'filters': <String>['relevant', 'actionable'],
          'maxResults': 20,
        },
      ),
      LogicBlock(
        id: 'reasoning_6',
        type: LogicBlockType.reasoning,
        label: 'Analytical Approach',
        position: const Position(x: 500, y: 150),
        properties: {
          'pattern': 'cot',
          'maxIterations': 3,
        },
      ),
      LogicBlock(
        id: 'reasoning_7',
        type: LogicBlockType.reasoning,
        label: 'Creative Approach',
        position: const Position(x: 500, y: 350),
        properties: {
          'pattern': 'tot',
          'maxIterations': 4,
        },
      ),
      LogicBlock(
        id: 'gateway_2',
        type: LogicBlockType.gateway,
        label: 'Solution Quality',
        position: const Position(x: 700, y: 250),
        properties: {
          'confidence': 0.75,
          'strategy': 'hybrid',
        },
      ),
      LogicBlock(
        id: 'reasoning_8',
        type: LogicBlockType.reasoning,
        label: 'Solution Refinement',
        position: const Position(x: 900, y: 250),
        properties: {
          'pattern': 'react',
          'maxIterations': 2,
        },
      ),
      LogicBlock(
        id: 'exit_4',
        type: LogicBlockType.exit,
        label: 'Solution Package',
        position: const Position(x: 1100, y: 250),
        properties: {
          'validationChecks': <String>['feasibility', 'effectiveness', 'implementation'],
          'partialResults': true,
        },
      ),
    ];

    final connections = [
      BlockConnection(
        id: 'conn_17',
        sourceBlockId: 'goal_4',
        targetBlockId: 'context_4',
        sourcePin: 'output',
        targetPin: 'input',
        type: ConnectionType.execution,
      ),
      BlockConnection(
        id: 'conn_18',
        sourceBlockId: 'context_4',
        targetBlockId: 'reasoning_6',
        sourcePin: 'output',
        targetPin: 'input',
        type: ConnectionType.execution,
      ),
      BlockConnection(
        id: 'conn_19',
        sourceBlockId: 'context_4',
        targetBlockId: 'reasoning_7',
        sourcePin: 'output',
        targetPin: 'input',
        type: ConnectionType.execution,
      ),
      BlockConnection(
        id: 'conn_20',
        sourceBlockId: 'reasoning_6',
        targetBlockId: 'gateway_2',
        sourcePin: 'output',
        targetPin: 'input',
        type: ConnectionType.data,
      ),
      BlockConnection(
        id: 'conn_21',
        sourceBlockId: 'reasoning_7',
        targetBlockId: 'gateway_2',
        sourcePin: 'output',
        targetPin: 'input',
        type: ConnectionType.data,
      ),
      BlockConnection(
        id: 'conn_22',
        sourceBlockId: 'gateway_2',
        targetBlockId: 'reasoning_8',
        sourcePin: 'output',
        targetPin: 'input',
        type: ConnectionType.execution,
      ),
      BlockConnection(
        id: 'conn_23',
        sourceBlockId: 'reasoning_8',
        targetBlockId: 'exit_4',
        sourcePin: 'output',
        targetPin: 'input',
        type: ConnectionType.execution,
      ),
    ];

    return WorkflowTemplate(
      id: 'problem_solving',
      name: 'Problem Solving Flow',
      description: 'Multi-approach problem solving with parallel reasoning and solution refinement',
      category: WorkflowCategory.problemSolving,
      workflow: workflow.copyWith(
        blocks: blocks,
        connections: connections,
        tags: ['problem_solving', 'creative', 'analytical', 'parallel'],
        isTemplate: true,
      ),
      tags: ['problem_solving', 'creative', 'analytical', 'parallel'],
    );
  }

  /// Conversation design workflow
  static WorkflowTemplate conversationDesignFlow() {
    final workflow = ReasoningWorkflow.empty().copyWith(
      name: 'Conversation Design Flow',
      description: 'Design conversational interactions with context awareness and fallback handling.',
    );

    final blocks = [
      LogicBlock(
        id: 'goal_5',
        type: LogicBlockType.goal,
        label: 'Conversation Goal',
        position: const Position(x: 100, y: 300),
        properties: {
          'description': 'Define conversation objectives and user experience goals',
          'constraints': <String>['user_centered', 'natural', 'helpful'],
          'successCriteria': 'Engaging conversation that meets user needs',
        },
      ),
      LogicBlock(
        id: 'context_5',
        type: LogicBlockType.context,
        label: 'User Context',
        position: const Position(x: 300, y: 300),
        properties: {
          'sources': <String>['user_history', 'current_intent', 'preferences'],
          'filters': <String>['recent', 'relevant', 'personal'],
          'maxResults': 15,
        },
      ),
      LogicBlock(
        id: 'reasoning_9',
        type: LogicBlockType.reasoning,
        label: 'Intent Understanding',
        position: const Position(x: 500, y: 300),
        properties: {
          'pattern': 'react',
          'maxIterations': 2,
        },
      ),
      LogicBlock(
        id: 'gateway_3',
        type: LogicBlockType.gateway,
        label: 'Response Strategy',
        position: const Position(x: 700, y: 300),
        properties: {
          'confidence': 0.7,
          'strategy': 'llm_decision',
        },
      ),
      LogicBlock(
        id: 'reasoning_10',
        type: LogicBlockType.reasoning,
        label: 'Response Generation',
        position: const Position(x: 900, y: 250),
        properties: {
          'pattern': 'cot',
          'maxIterations': 2,
        },
      ),
      LogicBlock(
        id: 'fallback_2',
        type: LogicBlockType.fallback,
        label: 'Clarification',
        position: const Position(x: 900, y: 350),
        properties: {
          'retryCount': 1,
          'escalationPath': 'human',
        },
      ),
      LogicBlock(
        id: 'trace_3',
        type: LogicBlockType.trace,
        label: 'Conversation Log',
        position: const Position(x: 1100, y: 300),
        properties: {
          'level': 'info',
          'includeState': false,
        },
      ),
      LogicBlock(
        id: 'exit_5',
        type: LogicBlockType.exit,
        label: 'Deliver Response',
        position: const Position(x: 1300, y: 300),
        properties: {
          'validationChecks': <String>['relevance', 'helpfulness', 'clarity'],
          'partialResults': true,
        },
      ),
    ];

    final connections = [
      BlockConnection(
        id: 'conn_24',
        sourceBlockId: 'goal_5',
        targetBlockId: 'context_5',
        sourcePin: 'output',
        targetPin: 'input',
        type: ConnectionType.execution,
      ),
      BlockConnection(
        id: 'conn_25',
        sourceBlockId: 'context_5',
        targetBlockId: 'reasoning_9',
        sourcePin: 'output',
        targetPin: 'input',
        type: ConnectionType.execution,
      ),
      BlockConnection(
        id: 'conn_26',
        sourceBlockId: 'reasoning_9',
        targetBlockId: 'gateway_3',
        sourcePin: 'output',
        targetPin: 'input',
        type: ConnectionType.execution,
      ),
      BlockConnection(
        id: 'conn_27',
        sourceBlockId: 'gateway_3',
        targetBlockId: 'reasoning_10',
        sourcePin: 'high_confidence',
        targetPin: 'input',
        type: ConnectionType.execution,
      ),
      BlockConnection(
        id: 'conn_28',
        sourceBlockId: 'gateway_3',
        targetBlockId: 'fallback_2',
        sourcePin: 'low_confidence',
        targetPin: 'input',
        type: ConnectionType.execution,
      ),
      BlockConnection(
        id: 'conn_29',
        sourceBlockId: 'reasoning_10',
        targetBlockId: 'trace_3',
        sourcePin: 'output',
        targetPin: 'input',
        type: ConnectionType.data,
      ),
      BlockConnection(
        id: 'conn_30',
        sourceBlockId: 'fallback_2',
        targetBlockId: 'trace_3',
        sourcePin: 'output',
        targetPin: 'input',
        type: ConnectionType.data,
      ),
      BlockConnection(
        id: 'conn_31',
        sourceBlockId: 'trace_3',
        targetBlockId: 'exit_5',
        sourcePin: 'output',
        targetPin: 'input',
        type: ConnectionType.execution,
      ),
    ];

    return WorkflowTemplate(
      id: 'conversation_design',
      name: 'Conversation Design Flow',
      description: 'Context-aware conversation design with intent understanding and fallback handling',
      category: WorkflowCategory.conversation,
      workflow: workflow.copyWith(
        blocks: blocks,
        connections: connections,
        tags: ['conversation', 'intent', 'context', 'user_experience'],
        isTemplate: true,
      ),
      tags: ['conversation', 'intent', 'context', 'user_experience'],
    );
  }
}

/// Template metadata for workflow organization
class WorkflowTemplate {
  final String id;
  final String name;
  final String description;
  final WorkflowCategory category;
  final ReasoningWorkflow workflow;
  final List<String> tags;

  const WorkflowTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.workflow,
    required this.tags,
  });
}

/// Categories for organizing workflow templates
enum WorkflowCategory {
  basic('Basic', 'Simple workflows for getting started'),
  advanced('Advanced', 'Complex workflows with sophisticated logic'),
  research('Research', 'Workflows focused on research and analysis'),
  problemSolving('Problem Solving', 'Structured approaches to problem solving'),
  conversation('Conversation', 'Workflows for conversational AI and dialogue');

  const WorkflowCategory(this.displayName, this.description);

  final String displayName;
  final String description;
}