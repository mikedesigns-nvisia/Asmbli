import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:agent_engine_core/models/conversation.dart' as core;
import '../../core/design_system/design_system.dart';
import '../../features/chat/presentation/widgets/rich_text_message_widget.dart';
import '../../features/chat/presentation/widgets/enhanced_message_input.dart';
import '../models/demo_models.dart';

/// Asmbli demo chat using the actual chat interface with human verification modals
class AsmblDemoChat extends ConsumerStatefulWidget {
  final String scenario;
  final Function(HumanIntervention)? onInterventionNeeded;
  final Function(String, {String? actionContext})? onCanvasUpdate;
  final VoidCallback? onDemoComplete;
  final Function(VerificationRequest)? onVerificationNeeded;
  final Function(EnhancedVerificationRequest)? onEnhancedVerificationNeeded;

  const AsmblDemoChat({
    super.key,
    required this.scenario,
    this.onInterventionNeeded,
    this.onCanvasUpdate,
    this.onDemoComplete,
    this.onVerificationNeeded,
    this.onEnhancedVerificationNeeded,
  });

  @override
  ConsumerState<AsmblDemoChat> createState() => _AsmblDemoChatState();
}

class _AsmblDemoChatState extends ConsumerState<AsmblDemoChat>
    with TickerProviderStateMixin {
  final List<DemoMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  int _currentStep = 0;
  bool _isInteractiveMode = false;
  List<String> _currentChatOptions = [];
  bool _waitingForUserInput = false;
  
  // Track selected actions for canvas updates
  String? _selectedFirstAction;
  String? _selectedSecondAction;
  String? _selectedThirdAction;

  @override
  void initState() {
    super.initState();
    _startDemo();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _startDemo() {
    // Initial AI message
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _addMessage(DemoMessage(
          id: '1',
          role: 'assistant',
          content: _getInitialMessage(),
          timestamp: DateTime.now(),
          confidence: 0.95,
        ));
        
        // Show user options after AI message loads, but don't auto-progress
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _showUserChatOptions();
          }
        });
      }
    });
  }

  String _getInitialMessage() {
    switch (widget.scenario) {
      case 'operations-manager':
        return 'Hello! I am your Operations Manager AI. I can help optimize scheduling, automate notifications, and streamline workflows. What operational challenge would you like me to help with?';
      case 'business-analyst':
        return 'Hi! I am your Business Analyst AI. I can analyze data, generate insights, and create comprehensive reports. What business question should we explore together?';
      case 'design-assistant':
        return 'Welcome! I am your Design Assistant AI. I can create interfaces, generate components, and build visual designs. What would you like to design today?';
      case 'coding-agent':
        return 'Hey there! I am your AI Coding Assistant. I can help you write code, manage git workflows, debug issues, and create full applications. What would you like to build today?';
      default:
        return 'Hello! How can I assist you today?';
    }
  }

  String _getUserMessage() {
    switch (widget.scenario) {
      case 'operations-manager':
        return 'I need to optimize our team schedules for next week and set up automated notifications for project deadlines. Can you help?';
      case 'business-analyst':
        return 'Can you analyze our Q4 sales performance and identify the key trends affecting our revenue growth?';
      case 'design-assistant':
        return 'I need to create a modern dashboard interface for our project management system. It should be clean and user-friendly.';
      default:
        return 'Can you help me with my task?';
    }
  }

  String _getFirstAction() {
    switch (widget.scenario) {
      case 'operations-manager':
        return 'Analyze Current Schedules';
      case 'business-analyst':
        return 'Access Sales Database';
      case 'design-assistant':
        return 'Create Initial Mockup';
      case 'coding-agent':
        return 'Analyze Codebase';
      default:
        return 'Start Analysis';
    }
  }

  String _getFirstActionDetails() {
    switch (widget.scenario) {
      case 'operations-manager':
        return 'I will analyze your current team schedules, identify conflicts, and propose optimizations. This will involve accessing calendar data and resource allocation systems.';
      case 'business-analyst':
        return 'I will connect to your sales database to retrieve Q4 performance data, including revenue, customer metrics, and product performance.';
      case 'design-assistant':
        return 'I will create an initial dashboard mockup based on modern design principles and your project management requirements.';
      case 'coding-agent':
        return 'I will analyze your current codebase structure, identify areas for improvement, and prepare to implement the requested changes using best practices.';
      default:
        return 'I will begin the analysis process.';
    }
  }

  void _executeFirstAction() {
    _addMessage(DemoMessage(
      id: '3',
      role: 'assistant',
      content: _getExecutionMessage(),
      timestamp: DateTime.now(),
      confidence: 0.88,
      mcpSteps: _getMcpSteps(),
    ));

    // Trigger canvas/editor progression
    if (widget.scenario == 'design-assistant') {
      widget.onCanvasUpdate?.call('wireframe');
    } else if (widget.scenario == 'coding-agent') {
      widget.onCanvasUpdate?.call('show_editor');
    }

    // Wait for user to continue instead of auto-progressing
    setState(() {
      _currentStep = 1;
      _waitingForUserInput = true;
    });
    
    // Show continue button after AI "finishes" work
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _showContinueToNextStep();
      }
    });
  }

  String _getExecutionMessage() {
    switch (widget.scenario) {
      case 'operations-manager':
        return 'Analysis complete! I have identified 3 scheduling conflicts and found optimization opportunities:\n\nCurrent Status:\n- 12 team members across 4 projects\n- 3 resource conflicts detected\n- Average utilization: 78%\n\nOptimization Recommendations:\n- Redistribute tasks from overloaded members\n- Implement buffer time for critical deliverables\n- Automate daily standup scheduling\n\nNext Step: Should I implement these schedule changes?';
      case 'business-analyst':
        return 'Q4 Sales Analysis Complete\n\nKey Insights:\n- Total Revenue: \$3.2M (+15% vs Q3)\n- Customer Acquisition: +22%\n- Average Deal Size: \$45K (+8%)\n- Top Product: Enterprise Suite (40% of revenue)\n\nTrends Identified:\n- Strong growth in enterprise segment\n- Geographic expansion showing results\n- Seasonal uptick in December\n\nNext Step: Generate detailed competitive analysis?';
      case 'design-assistant':
        return 'Initial Mockup Created\n\nI have designed a modern dashboard with:\n- Clean navigation sidebar\n- Real-time project status cards\n- Interactive data visualizations\n- Responsive layout for all devices\n\nDesign Principles Applied:\n- Minimal cognitive load\n- Consistent spacing and typography\n- Accessible color scheme\n- Intuitive user flow\n\nNext Step: Should I create the interactive prototype?';
      case 'coding-agent':
        return 'Codebase Analysis Complete\n\nFindings:\n- Current API client lacks error handling\n- No retry mechanism for failed requests\n- TypeScript types could be improved\n- Found 3 potential optimization points\n\nProposed Changes:\n- Wrap API calls in try-catch blocks\n- Implement exponential backoff retry\n- Add proper error types and handling\n- Include loading states\n\nI\'ve opened the code editor with your files.\n\nNext Step: Should I implement the error handling improvements?';
      default:
        return 'Analysis completed successfully.';
    }
  }

  List<MCPStep> _getMcpSteps() {
    switch (widget.scenario) {
      case 'operations-manager':
        return [
          MCPStep(
            type: 'calendar_integration',
            title: 'Calendar Analysis',
            description: 'Analyzing team schedules and availability',
            status: 'completed',
            icon: Icons.calendar_today,
          ),
          MCPStep(
            type: 'resource_optimization',
            title: 'Resource Optimization',
            description: 'Computing optimal task allocation',
            status: 'completed',
            icon: Icons.trending_up,
          ),
        ];
      case 'business-analyst':
        return [
          MCPStep(
            type: 'database_query',
            title: 'Sales Database',
            description: 'Retrieving Q4 sales data',
            status: 'completed',
            icon: Icons.storage,
          ),
          MCPStep(
            type: 'data_analysis',
            title: 'Trend Analysis',
            description: 'Computing growth metrics and trends',
            status: 'completed',
            icon: Icons.analytics,
          ),
        ];
      case 'design-assistant':
        return [
          MCPStep(
            type: 'design_system',
            title: 'Design System',
            description: 'Applying design tokens and components',
            status: 'completed',
            icon: Icons.palette,
          ),
          MCPStep(
            type: 'mockup_generation',
            title: 'Mockup Creation',
            description: 'Generating dashboard layout',
            status: 'completed',
            icon: Icons.design_services,
          ),
        ];
      case 'coding-agent':
        return [
          MCPStep(
            type: 'code_analysis',
            title: 'Code Analysis',
            description: 'Scanning codebase for improvements',
            status: 'completed',
            icon: Icons.code,
          ),
          MCPStep(
            type: 'git_integration',
            title: 'Git Status',
            description: 'Checking current branch and changes',
            status: 'completed',
            icon: Icons.source,
          ),
        ];
      default:
        return [];
    }
  }

  void _requestSecondVerification() {
    _requestEnhancedVerification(
      title: 'Ready to Implement Changes?',
      situation: _getSecondActionDetails(),
      actions: _getSecondVerificationActions(),
    );
  }

  void _requestThirdVerification() {
    _requestEnhancedVerification(
      title: 'Deploy to Production?',
      situation: _getThirdActionDetails(),
      actions: _getThirdVerificationActions(),
    );
  }

  String _getSecondAction() {
    switch (widget.scenario) {
      case 'operations-manager':
        return 'Implement Schedule Changes';
      case 'business-analyst':
        return 'Generate Executive Summary';
      case 'design-assistant':
        return 'Build Interactive Prototype';
      case 'coding-agent':
        return 'Implement Code Changes';
      default:
        return 'Continue Process';
    }
  }

  String _getSecondActionDetails() {
    switch (widget.scenario) {
      case 'operations-manager':
        return 'Apply the optimized schedule changes and set up automated notifications for the identified deadlines.';
      case 'business-analyst':
        return 'Create an executive summary with actionable recommendations based on the Q4 analysis.';
      case 'design-assistant':
        return 'Convert the static mockup into an interactive prototype with working navigation and components.';
      case 'coding-agent':
        return 'I will implement the error handling improvements, add retry logic with exponential backoff, and ensure proper TypeScript types.';
      default:
        return 'Proceed with the next step.';
    }
  }

  String _getThirdAction() {
    switch (widget.scenario) {
      case 'operations-manager':
        return 'Deploy Monitoring System';
      case 'business-analyst':
        return 'Schedule Reporting Automation';
      case 'design-assistant':
        return 'Deploy to Production';
      case 'coding-agent':
        return 'Commit and Push Changes';
      default:
        return 'Finalize Implementation';
    }
  }

  String _getThirdActionDetails() {
    switch (widget.scenario) {
      case 'operations-manager':
        return 'Set up continuous monitoring of team performance, automated weekly reports, and alert system for resource bottlenecks.';
      case 'business-analyst':
        return 'Implement automated quarterly report generation, set up real-time dashboards, and configure trend alerts for key metrics.';
      case 'design-assistant':
        return 'Deploy the finalized design system to production, set up design token updates, and implement component usage tracking.';
      case 'coding-agent':
        return 'Commit all changes with descriptive message, push to feature branch, and create a pull request for code review.';
      default:
        return 'Complete the final implementation and deployment steps.';
    }
  }

  void _executeSecondAction() {
    _addMessage(DemoMessage(
      id: '4',
      role: 'assistant',
      content: _getFinalMessage(),
      timestamp: DateTime.now(),
      confidence: 0.94,
    ));

    // Trigger canvas/editor progression
    if (widget.scenario == 'design-assistant') {
      widget.onCanvasUpdate?.call('styled');
    } else if (widget.scenario == 'coding-agent') {
      widget.onCanvasUpdate?.call('code_updated');
    }
    
    // Wait for user to continue
    setState(() {
      _currentStep = 2;
      _waitingForUserInput = true;
    });
    
    // Show follow-up question button
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _showFollowUpPrompt();
      }
    });
  }
  
  void _addUserFollowUpQuestion() {
    _addMessage(DemoMessage(
      id: '5',
      role: 'user',
      content: _getUserFollowUpQuestion(),
      timestamp: DateTime.now(),
    ));
    
    // AI responds to user question
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _addAIFollowUpResponse();
      }
    });
  }
  
  void _addAIFollowUpResponse() {
    _addMessage(DemoMessage(
      id: '6',
      role: 'assistant',
      content: _getAIFollowUpResponse(),
      timestamp: DateTime.now(),
      confidence: 0.96,
      mcpSteps: _getFollowUpMcpSteps(),
    ));
    
    // Wait for user to proceed to final step
    setState(() {
      _currentStep = 3;
      _waitingForUserInput = true;
    });
    
    // Show final action button after brief delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _showFinalActionPrompt();
      }
    });
  }

  void _executeThirdAction() {
    _addMessage(DemoMessage(
      id: '7',
      role: 'assistant',
      content: _getCompletionMessage(),
      timestamp: DateTime.now(),
      confidence: 0.98,
      mcpSteps: _getCompletionMcpSteps(),
    ));

    // Trigger final canvas/editor progression
    if (widget.scenario == 'design-assistant') {
      widget.onCanvasUpdate?.call('interactive');
    } else if (widget.scenario == 'coding-agent') {
      widget.onCanvasUpdate?.call('git_commit');
    }

    // TODO: Demo completion should be triggered by user interaction, not automatically
    // Future.delayed(const Duration(seconds: 3), () {
    //   widget.onDemoComplete?.call();
    // });
  }

  void _showUserChatOptions() {
    setState(() {
      _isInteractiveMode = true;
      _waitingForUserInput = true;
      _currentChatOptions = _getUserChatOptions();
    });
  }

  List<String> _getUserChatOptions() {
    switch (widget.scenario) {
      case 'operations-manager':
        return [
          'I need to optimize our team schedules for next week and set up automated notifications for project deadlines. Can you help?',
          'Can you analyze our current operational bottlenecks and suggest improvements?',
          'Help me create a workflow automation system for our team processes.',
        ];
      case 'business-analyst':
        return [
          'Can you analyze our Q4 sales performance and identify the key trends affecting our revenue growth?',
          'I need insights into our customer acquisition costs and retention rates.',
          'Help me create a competitive analysis report for our market segment.',
        ];
      case 'design-assistant':
        return [
          'I need to create a modern dashboard interface for our project management system. It should be clean and user-friendly.',
          'Can you help me design a mobile-first landing page for our new product?',
          'I want to redesign our user onboarding flow to improve conversion rates.',
        ];
      case 'coding-agent':
        return [
          'I need to add error handling to our API client and implement retry logic for failed requests.',
          'Can you help me create a new React component for displaying real-time analytics with proper TypeScript types?',
          'I want to refactor our authentication flow to use JWT tokens and add refresh token support.',
        ];
      default:
        return ['Can you help me with my task?'];
    }
  }

  void _selectChatOption(String selectedMessage) {
    setState(() {
      _isInteractiveMode = false;
      _waitingForUserInput = false;
      _currentChatOptions = [];
    });

    // Add the selected user message
    _addMessage(DemoMessage(
      id: '2',
      role: 'user',
      content: selectedMessage,
      timestamp: DateTime.now(),
    ));

    // Handle different progression options
    if (selectedMessage == 'Continue to next step') {
      _requestSecondVerification();
    } else if (selectedMessage == 'Ask follow-up question') {
      _showFollowUpOptions();
    } else if (selectedMessage == 'Proceed to deployment') {
      _requestThirdVerification();
    } else {
      // Default behavior for initial user responses
      // Trigger canvas update for design assistant
      if (widget.scenario == 'design-assistant') {
        widget.onCanvasUpdate?.call('start_design');
      }

      // Continue with the demo flow
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _requestEnhancedVerification(
            title: 'Ready to Begin Analysis?',
            situation: _getFirstActionDetails(),
            actions: _getFirstVerificationActions(),
          );
        }
      });
    }
  }

  void _showFollowUpOptions() {
    setState(() {
      _isInteractiveMode = true;
      _waitingForUserInput = true;
      _currentChatOptions = _getFollowUpChatOptions();
    });
  }

  List<String> _getFollowUpChatOptions() {
    switch (widget.scenario) {
      case 'operations-manager':
        return [
          'This looks great! Can you also set up automated reminders for our weekly team reviews and sync this with our project management system?',
          'Can you create alerts for when team members exceed their capacity limits?',
          'Help me set up performance metrics tracking for the optimized schedules.',
        ];
      case 'business-analyst':
        return [
          'Excellent analysis! Can you also break down the customer retention rates by segment and predict next quarter\'s performance?',
          'Can you analyze the competitive landscape impact on these trends?',
          'Help me identify which marketing channels are driving the highest quality leads.',
        ];
      case 'design-assistant':
        return [
          'Love the design! Can you create variations for mobile and tablet, plus add a dark mode option?',
          'Can you design a comprehensive component library based on this style?',
          'Help me create user testing scenarios to validate this design approach.',
        ];
      case 'coding-agent':
        return [
          'Great work! Can you also add unit tests for the new error handling code?',
          'Can you implement caching to reduce API calls and improve performance?',
          'Help me set up a CI/CD pipeline to automatically run tests on pull requests.',
        ];
      default:
        return ['This is helpful! Can you provide more details on the implementation?'];
    }
  }

  void _selectFollowUpOption(String selectedMessage) {
    setState(() {
      _isInteractiveMode = false;
      _waitingForUserInput = false;
      _currentChatOptions = [];
    });

    // Add the selected follow-up message
    _addMessage(DemoMessage(
      id: '5',
      role: 'user',
      content: selectedMessage,
      timestamp: DateTime.now(),
    ));
    
    // AI responds to user question automatically (this is expected for follow-up responses)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _addAIFollowUpResponse();
      }
    });
  }

  String _getFinalMessage() {
    switch (widget.scenario) {
      case 'operations-manager':
        return 'Implementation Complete!\n\n- Schedule optimization applied\n- Automated notifications configured\n- Team members notified of changes\n\nYour operational efficiency should improve by an estimated 23%. I will monitor the changes and suggest further optimizations as needed.';
      case 'business-analyst':
        return 'Executive Summary Generated\n\nKey Recommendations:\n1. Expand enterprise sales team (+30%)\n2. Increase investment in geographic expansion\n3. Develop specialized seasonal campaigns\n4. Launch customer retention program\n\nProjected Impact: +25% revenue growth in Q1\n\nFull analysis report has been saved to your dashboard.';
      case 'design-assistant':
        return 'Prototype Complete!\n\nYour interactive dashboard prototype is ready with:\n- Fully functional navigation\n- Real-time data connections\n- Mobile-responsive design\n- Accessibility compliance\n\nThe prototype is now available for team review and user testing. Ready to move to development?';
      case 'coding-agent':
        return 'Code Implementation Complete!\n\nChanges Made:\n- Added comprehensive error handling to API client\n- Implemented retry logic with exponential backoff\n- Created proper TypeScript error types\n- Added loading and error states\n\nCode Quality:\n- All tests passing ✓\n- Type coverage: 100%\n- No linting errors\n\nThe changes are staged and ready for commit. Should I proceed with git commit and push?';
      default:
        return 'Process completed successfully.';
    }
  }

  void _requestVerification({
    required String action,
    required String details,
    required VoidCallback onApprove,
  }) {
    // Pass verification request to parent instead of showing local modal
    widget.onVerificationNeeded?.call(VerificationRequest(
      action: action,
      details: details,
      onApprove: onApprove,
      onReject: () => _rejectAction(),
    ));
  }

  void _requestEnhancedVerification({
    required String title,
    required String situation,
    required List<ProposedAction> actions,
  }) {
    debugPrint('🔍 Requesting enhanced verification: $title');
    debugPrint('🔍 Actions count: ${actions.length}');
    debugPrint('🔍 First action title: ${actions.isNotEmpty ? actions.first.title : "none"}');
    debugPrint('🔍 Enhanced verification callback available: ${widget.onEnhancedVerificationNeeded != null}');
    
    widget.onEnhancedVerificationNeeded?.call(EnhancedVerificationRequest(
      title: title,
      situation: situation,
      proposedActions: actions,
      onChat: () => print('Opening chat for discussion'),
    ));
  }

  void _selectAction(String actionTitle, int verificationStep) {
    switch (verificationStep) {
      case 1:
        _selectedFirstAction = actionTitle;
        break;
      case 2:
        _selectedSecondAction = actionTitle;
        break;
      case 3:
        _selectedThirdAction = actionTitle;
        break;
    }
  }

  List<ProposedAction> _getFirstVerificationActions() {
    debugPrint('🔍 Building first verification actions for scenario: ${widget.scenario}');
    switch (widget.scenario) {
      case 'operations-manager':
        return [
          ProposedAction(
            title: 'Proceed with Analysis',
            description: 'Analyze team schedules and identify optimization opportunities',
            icon: Icons.analytics,
            isRecommended: true,
            onSelect: () => _executeFirstActionWithContext('Proceed with Analysis'),
          ),
          ProposedAction(
            title: 'Adjust Parameters',
            description: 'Customize the analysis scope and team selection',
            icon: Icons.tune,
            onSelect: () => _executeFirstActionWithContext('Adjust Parameters'),
          ),
          ProposedAction(
            title: 'Skip for Now',
            description: 'Continue without this analysis step',
            icon: Icons.skip_next,
            onSelect: () => _executeFirstActionWithContext('Skip for Now'),
          ),
        ];
      case 'business-analyst':
        return [
          ProposedAction(
            title: 'Access Sales Data',
            description: 'Connect to database and retrieve Q4 performance metrics',
            icon: Icons.storage,
            isRecommended: true,
            onSelect: () => _executeFirstActionWithContext('Access Sales Data'),
          ),
          ProposedAction(
            title: 'Use Sample Data',
            description: 'Demonstrate with anonymized sample dataset',
            icon: Icons.science,
            onSelect: () => _executeFirstActionWithContext('Use Sample Data'),
          ),
          ProposedAction(
            title: 'Configure Filters',
            description: 'Select specific date ranges and metrics to analyze',
            icon: Icons.filter_alt,
            onSelect: () => _executeFirstActionWithContext('Configure Filters'),
          ),
        ];
      case 'design-assistant':
        return [
          ProposedAction(
            title: 'Create Mockup',
            description: 'Generate initial dashboard design based on requirements',
            icon: Icons.design_services,
            isRecommended: true,
            onSelect: () {
              debugPrint('🎯 Create Mockup button clicked!');
              _executeFirstActionWithContext('Create Mockup');
            },
          ),
          ProposedAction(
            title: 'Review Examples',
            description: 'Show design inspiration and style references first',
            icon: Icons.collections,
            onSelect: () => _executeFirstActionWithContext('Review Examples'),
          ),
          ProposedAction(
            title: 'Gather More Context',
            description: 'Ask additional questions about design preferences',
            icon: Icons.quiz,
            onSelect: () => _executeFirstActionWithContext('Gather More Context'),
          ),
        ];
      case 'coding-agent':
        return [
          ProposedAction(
            title: 'Analyze Codebase',
            description: 'Scan code for improvements and optimization opportunities',
            icon: Icons.code,
            isRecommended: true,
            onSelect: () => _executeFirstActionWithContext('Analyze Codebase'),
          ),
          ProposedAction(
            title: 'Run Tests First',
            description: 'Execute existing tests to understand current state',
            icon: Icons.check_circle_outline,
            onSelect: () => _executeFirstActionWithContext('Run Tests First'),
          ),
          ProposedAction(
            title: 'Review Architecture',
            description: 'Examine project structure and dependencies',
            icon: Icons.account_tree,
            onSelect: () => _executeFirstActionWithContext('Review Architecture'),
          ),
        ];
      default:
        return [
          ProposedAction(
            title: 'Proceed',
            description: 'Continue with the recommended action',
            icon: Icons.play_arrow,
            isRecommended: true,
            onSelect: () => _executeFirstActionWithContext('Proceed'),
          ),
        ];
    }
  }

  List<ProposedAction> _getSecondVerificationActions() {
    switch (widget.scenario) {
      case 'operations-manager':
        return [
          ProposedAction(
            title: 'Apply Changes',
            description: 'Implement schedule optimizations and setup notifications',
            icon: Icons.update,
            isRecommended: true,
            onSelect: () => _executeSecondActionWithContext('Apply Changes'),
          ),
          ProposedAction(
            title: 'Review First',
            description: 'Let team leads review proposed changes before applying',
            icon: Icons.groups,
            onSelect: () => _executeSecondActionWithContext('Review First'),
          ),
          ProposedAction(
            title: 'Gradual Rollout',
            description: 'Apply changes to one team first as a pilot',
            icon: Icons.trending_up,
            onSelect: () => _executeSecondActionWithContext('Gradual Rollout'),
          ),
        ];
      case 'business-analyst':
        return [
          ProposedAction(
            title: 'Generate Report',
            description: 'Create executive summary with actionable recommendations',
            icon: Icons.description,
            isRecommended: true,
            onSelect: () => _executeSecondActionWithContext('Generate Report'),
          ),
          ProposedAction(
            title: 'Deep Dive Analysis',
            description: 'Perform additional segmentation and trend analysis',
            icon: Icons.analytics,
            onSelect: () => _executeSecondActionWithContext('Deep Dive Analysis'),
          ),
          ProposedAction(
            title: 'Schedule Presentation',
            description: 'Prepare stakeholder presentation with key insights',
            icon: Icons.present_to_all,
            onSelect: () => _executeSecondActionWithContext('Schedule Presentation'),
          ),
        ];
      case 'design-assistant':
        return [
          ProposedAction(
            title: 'Build Prototype',
            description: 'Convert mockup into interactive, clickable prototype',
            icon: Icons.touch_app,
            isRecommended: true,
            onSelect: () => _executeSecondActionWithContext('Build Prototype'),
          ),
          ProposedAction(
            title: 'Create Variations',
            description: 'Generate alternative layouts and color schemes',
            icon: Icons.palette,
            onSelect: () => _executeSecondActionWithContext('Create Variations'),
          ),
          ProposedAction(
            title: 'User Testing',
            description: 'Prepare design for user testing and feedback collection',
            icon: Icons.people,
            onSelect: () => _executeSecondActionWithContext('User Testing'),
          ),
        ];
      case 'coding-agent':
        return [
          ProposedAction(
            title: 'Implement Changes',
            description: 'Add error handling, retry logic, and improved TypeScript types',
            icon: Icons.build,
            isRecommended: true,
            onSelect: () => _executeSecondActionWithContext('Implement Changes'),
          ),
          ProposedAction(
            title: 'Write Tests First',
            description: 'Create comprehensive test suite before implementing changes',
            icon: Icons.check_circle_outline,
            onSelect: () => _executeSecondActionWithContext('Write Tests First'),
          ),
          ProposedAction(
            title: 'Incremental Changes',
            description: 'Implement one improvement at a time with testing',
            icon: Icons.linear_scale,
            onSelect: () => _executeSecondActionWithContext('Incremental Changes'),
          ),
        ];
      default:
        return [
          ProposedAction(
            title: 'Continue',
            description: 'Proceed with the next step',
            icon: Icons.arrow_forward,
            isRecommended: true,
            onSelect: () => _executeSecondActionWithContext('Continue'),
          ),
        ];
    }
  }

  List<ProposedAction> _getThirdVerificationActions() {
    switch (widget.scenario) {
      case 'operations-manager':
        return [
          ProposedAction(
            title: 'Deploy Monitoring',
            description: 'Set up real-time performance tracking and automated reports',
            icon: Icons.monitor_heart,
            isRecommended: true,
            onSelect: () => _executeThirdActionWithContext('Deploy Monitoring'),
          ),
          ProposedAction(
            title: 'Staged Deployment',
            description: 'Deploy monitoring to pilot team first, then expand',
            icon: Icons.layers,
            onSelect: () => _executeThirdActionWithContext('Staged Deployment'),
          ),
          ProposedAction(
            title: 'Manual Monitoring',
            description: 'Set up manual check-ins before full automation',
            icon: Icons.schedule,
            onSelect: () => _executeThirdActionWithContext('Manual Monitoring'),
          ),
        ];
      case 'business-analyst':
        return [
          ProposedAction(
            title: 'Setup Automation',
            description: 'Deploy automated reporting and real-time dashboards',
            icon: Icons.auto_awesome,
            isRecommended: true,
            onSelect: () => _executeThirdActionWithContext('Setup Automation'),
          ),
          ProposedAction(
            title: 'Weekly Reports',
            description: 'Start with weekly automated reports before daily',
            icon: Icons.schedule,
            onSelect: () => _executeThirdActionWithContext('Weekly Reports'),
          ),
          ProposedAction(
            title: 'Dashboard Only',
            description: 'Deploy real-time dashboard without automated reports',
            icon: Icons.dashboard,
            onSelect: () => _executeThirdActionWithContext('Dashboard Only'),
          ),
        ];
      case 'design-assistant':
        return [
          ProposedAction(
            title: 'Deploy Design System',
            description: 'Release production design tokens and component library',
            icon: Icons.rocket_launch,
            isRecommended: true,
            onSelect: () => _executeThirdActionWithContext('Deploy Design System'),
          ),
          ProposedAction(
            title: 'Beta Release',
            description: 'Deploy to limited audience for feedback first',
            icon: Icons.bug_report,
            onSelect: () => _executeThirdActionWithContext('Beta Release'),
          ),
          ProposedAction(
            title: 'Development Only',
            description: 'Share with developers for implementation planning',
            icon: Icons.developer_mode,
            onSelect: () => _executeThirdActionWithContext('Development Only'),
          ),
        ];
      case 'coding-agent':
        return [
          ProposedAction(
            title: 'Commit & Push',
            description: 'Commit changes with proper message and create pull request',
            icon: Icons.upload,
            isRecommended: true,
            onSelect: () => _executeThirdActionWithContext('Commit & Push'),
          ),
          ProposedAction(
            title: 'Create Draft PR',
            description: 'Push as draft for team review before final merge',
            icon: Icons.drafts,
            onSelect: () => _executeThirdActionWithContext('Create Draft PR'),
          ),
          ProposedAction(
            title: 'Local Testing',
            description: 'Run more comprehensive tests locally first',
            icon: Icons.computer,
            onSelect: () => _executeThirdActionWithContext('Local Testing'),
          ),
        ];
      default:
        return [
          ProposedAction(
            title: 'Finalize',
            description: 'Complete the implementation and deployment',
            icon: Icons.done,
            isRecommended: true,
            onSelect: () => _executeThirdActionWithContext('Finalize'),
          ),
        ];
    }
  }

  // Action execution with context tracking
  void _executeFirstActionWithContext(String actionTitle) {
    debugPrint('🎬 _executeFirstActionWithContext called with: $actionTitle');
    debugPrint('🎬 Widget scenario: ${widget.scenario}');
    debugPrint('🎬 Canvas update callback available: ${widget.onCanvasUpdate != null}');
    
    _selectAction(actionTitle, 1);
    _executeFirstAction();
    
    // Update canvas with action context
    if (widget.scenario == 'design-assistant') {
      debugPrint('🎬 Calling canvas update for wireframe with context: $actionTitle');
      widget.onCanvasUpdate?.call('wireframe', actionContext: actionTitle);
    } else if (widget.scenario == 'coding-agent') {
      widget.onCanvasUpdate?.call('show_editor', actionContext: actionTitle);
    }
  }

  void _executeSecondActionWithContext(String actionTitle) {
    _selectAction(actionTitle, 2);
    _executeSecondAction();
    
    // Update canvas with action context
    if (widget.scenario == 'design-assistant') {
      widget.onCanvasUpdate?.call('styled', actionContext: actionTitle);
    } else if (widget.scenario == 'coding-agent') {
      widget.onCanvasUpdate?.call('code_updated', actionContext: actionTitle);
    }
  }

  void _executeThirdActionWithContext(String actionTitle) {
    _selectAction(actionTitle, 3);
    _executeThirdAction();
    
    // Update canvas with action context
    if (widget.scenario == 'design-assistant') {
      widget.onCanvasUpdate?.call('interactive', actionContext: actionTitle);
    } else if (widget.scenario == 'coding-agent') {
      widget.onCanvasUpdate?.call('git_commit', actionContext: actionTitle);
    }
  }

  // Alternative action handlers
  void _customizeAndExecuteFirst() => _executeFirstAction();
  void _skipFirstAction() => _executeSecondAction();
  void _useSampleDataFirst() => _executeFirstAction();
  void _configureAndExecuteFirst() => _executeFirstAction();
  void _showDesignExamples() => _executeFirstAction();
  void _gatherMoreContext() => _executeFirstAction();
  void _runTestsFirst() => _executeFirstAction();
  void _reviewArchitecture() => _executeFirstAction();
  
  void _scheduleTeamReview() => _executeSecondAction();
  void _gradualRollout() => _executeSecondAction();
  void _performDeepDive() => _executeSecondAction();
  void _schedulePresentation() => _executeSecondAction();
  void _createVariations() => _executeSecondAction();
  void _prepareUserTesting() => _executeSecondAction();
  void _writeTestsFirst() => _executeSecondAction();
  void _incrementalImplementation() => _executeSecondAction();
  
  void _stagedMonitoringDeploy() => _executeThirdAction();
  void _manualMonitoring() => _executeThirdAction();
  void _weeklyReporting() => _executeThirdAction();
  void _dashboardOnly() => _executeThirdAction();
  void _betaRelease() => _executeThirdAction();
  void _developmentOnlyRelease() => _executeThirdAction();
  void _createDraftPR() => _executeThirdAction();
  void _extendedLocalTesting() => _executeThirdAction();

  void _rejectAction() {
    // Add rejection message
    _addMessage(DemoMessage(
      id: 'reject-${_currentStep}',
      role: 'assistant',
      content: 'Understood. Let me know how you would like to proceed differently, or if you would like me to suggest alternative approaches.',
      timestamp: DateTime.now(),
      confidence: 0.85,
    ));
  }

  void _addMessage(DemoMessage message) {
    if (mounted) {
      setState(() {
        _messages.add(message);
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          // Chat header
          Container(
            padding: const EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            child: Row(
              children: [
                Icon(
                  _getScenarioIcon(),
                  color: colors.primary,
                  size: 20,
                ),
                const SizedBox(width: SpacingTokens.sm),
                Text(
                  _getScenarioTitle(),
                  style: TextStyles.bodyLarge.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingTokens.sm,
                    vertical: SpacingTokens.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  ),
                  child: Text(
                    'DEMO',
                    style: TextStyles.bodySmall.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(SpacingTokens.md),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index], colors);
              },
            ),
          ),

          // Interactive message input
          _buildMessageInput(colors),
        ],
      ),
    );
  }

  IconData _getScenarioIcon() {
    switch (widget.scenario) {
      case 'operations-manager':
        return Icons.schedule;
      case 'business-analyst':
        return Icons.analytics;
      case 'design-assistant':
        return Icons.palette;
      case 'coding-agent':
        return Icons.code;
      default:
        return Icons.chat;
    }
  }

  String _getScenarioTitle() {
    switch (widget.scenario) {
      case 'operations-manager':
        return 'Operations Manager AI';
      case 'business-analyst':
        return 'Business Analyst AI';
      case 'design-assistant':
        return 'Design Assistant AI';
      case 'coding-agent':
        return 'AI Coding Assistant';
      default:
        return 'AI Assistant';
    }
  }
  
  String _getUserFollowUpQuestion() {
    switch (widget.scenario) {
      case 'operations-manager':
        return 'This looks great! Can you also set up automated reminders for our weekly team reviews and sync this with our project management system?';
      case 'business-analyst':
        return 'Excellent analysis! Can you also break down the customer retention rates by segment and predict next quarter\'s performance?';
      case 'design-assistant':
        return 'Love the design! Can you create variations for mobile and tablet, plus add a dark mode option?';
      default:
        return 'This is helpful! Can you provide more details on the implementation?';
    }
  }
  
  String _getAIFollowUpResponse() {
    switch (widget.scenario) {
      case 'operations-manager':
        return 'Absolutely! I\'ll set up the automated reminders and integrate with your PM system.\\n\\n**Weekly Team Review Setup:**\\n- Automated calendar invites every Monday at 9 AM\\n- Agenda auto-generated from completed tasks\\n- Action items tracked and followed up\\n\\n**PM System Integration:**\\n- Connected to Jira/Asana for real-time updates\\n- Automated status reports to stakeholders\\n- Smart deadline adjustments based on progress\\n\\nAll systems are now synchronized and running smoothly!';
      case 'business-analyst':
        return 'Perfect! Let me dive deeper into customer retention and forecasting.\\n\\n**Customer Retention Analysis:**\\n- Enterprise: 94% retention (+2% vs Q3)\\n- Mid-market: 87% retention (stable)\\n- SMB: 78% retention (+5% improvement)\\n\\n**Q1 Performance Prediction:**\\n- Expected Revenue: \$4.1M (+28% growth)\\n- New Customer Acquisition: 340 customers\\n- Upsell Opportunities: \$650K potential\\n\\n**Risk Factors:** Economic uncertainty (15% impact), competitive pressure (8% impact)\\n\\nHigh confidence in positive trajectory with these optimizations!';
      case 'design-assistant':
        return 'Fantastic idea! I\'ve created responsive variations and dark mode.\\n\\n**Mobile Design (375px):**\\n- Condensed navigation with hamburger menu\\n- Touch-optimized button sizes (44px minimum)\\n- Simplified card layouts for better thumb reach\\n\\n**Tablet Design (768px):**\\n- Two-column layout for optimal space usage\\n- Enhanced sidebar with quick actions\\n- Adaptive grid system\\n\\n**Dark Mode Theme:**\\n- Carefully selected contrast ratios (WCAG AAA)\\n- Blue accent colors for better night viewing\\n- Smooth theme transition animations\\n\\nAll designs maintain brand consistency and accessibility standards!';
      case 'coding-agent':
        return 'Excellent suggestion! I\'ll add comprehensive unit tests.\\n\\n**Test Implementation:**\\n- Created test suite for error handling logic\\n- Added tests for retry mechanism with mocked failures\\n- Implemented edge case testing\\n- Coverage increased to 98%\\n\\n**Test Results:**\\n```\\n✓ handles network errors correctly\\n✓ retries with exponential backoff\\n✓ respects max retry limit\\n✓ properly types error responses\\n```\\n\\nAll tests are passing! The code is now production-ready with comprehensive test coverage.';
      default:
        return 'I\'ve gathered additional implementation details based on your requirements. The system is now fully configured and ready for deployment.';
    }
  }
  
  List<MCPStep> _getFollowUpMcpSteps() {
    switch (widget.scenario) {
      case 'operations-manager':
        return [
          MCPStep(
            type: 'calendar_integration',
            title: 'Calendar Setup',
            description: 'Automated weekly review scheduling',
            status: 'completed',
            icon: Icons.event_repeat,
          ),
          MCPStep(
            type: 'pm_integration',
            title: 'PM System Sync',
            description: 'Connected to project management tools',
            status: 'completed',
            icon: Icons.sync,
          ),
        ];
      case 'business-analyst':
        return [
          MCPStep(
            type: 'retention_analysis',
            title: 'Retention Analysis',
            description: 'Customer segment breakdown completed',
            status: 'completed',
            icon: Icons.people,
          ),
          MCPStep(
            type: 'forecasting_model',
            title: 'Predictive Model',
            description: 'Q1 performance forecasting',
            status: 'completed',
            icon: Icons.trending_up,
          ),
        ];
      case 'design-assistant':
        return [
          MCPStep(
            type: 'responsive_design',
            title: 'Responsive Variants',
            description: 'Mobile and tablet layouts created',
            status: 'completed',
            icon: Icons.devices,
          ),
          MCPStep(
            type: 'dark_mode',
            title: 'Dark Mode Theme',
            description: 'Accessibility-compliant dark theme',
            status: 'completed',
            icon: Icons.dark_mode,
          ),
        ];
      case 'coding-agent':
        return [
          MCPStep(
            type: 'test_suite',
            title: 'Test Suite Created',
            description: 'Unit and integration tests added',
            status: 'completed',
            icon: Icons.check_circle_outline,
          ),
          MCPStep(
            type: 'ci_pipeline',
            title: 'CI/CD Pipeline',
            description: 'GitHub Actions workflow configured',
            status: 'completed',
            icon: Icons.account_tree,
          ),
        ];
      default:
        return [];
    }
  }

  String _getCompletionMessage() {
    switch (widget.scenario) {
      case 'operations-manager':
        return 'System Deployment Complete! 🚀\n\n**Monitoring Dashboard Live:**\n- Real-time team performance tracking\n- Automated weekly efficiency reports\n- Smart alert system for resource conflicts\n\n**Next Steps:**\n- Review weekly performance reports\n- Adjust optimization parameters based on results\n- Scale successful patterns to other teams\n\nYour operations are now fully optimized and self-monitoring!';
      case 'business-analyst':
        return 'Analytics Platform Deployed! 📊\n\n**Automated Systems Active:**\n- Quarterly report generation (next: Q1 2024)\n- Real-time revenue dashboard\n- Trend alerts for key metrics\n\n**Business Intelligence Features:**\n- Predictive analytics for revenue forecasting\n- Customer behavior pattern detection\n- Competitive analysis automation\n\nYour data-driven insights are now automated and actionable!';
      case 'design-assistant':
        return 'Design System Deployed! 🎨\n\n**Production Ready:**\n- Design tokens integrated across platforms\n- Component library live in production\n- Usage tracking and analytics enabled\n\n**Developer Experience:**\n- Auto-updating design documentation\n- Component usage metrics dashboard\n- Design-to-code synchronization\n\nYour design system is now scaling beautifully across your entire product!';
      case 'coding-agent':
        return 'Development Pipeline Complete! 🚀\n\n**Code Infrastructure:**\n- Automated testing suite with 95% coverage\n- CI/CD pipeline running on every commit\n- Performance monitoring integrated\n\n**Development Experience:**\n- AI-powered code reviews active\n- Automated dependency updates configured\n- Real-time collaboration enabled\n\nYour development workflow is now supercharged with AI automation!';
      default:
        return 'Implementation completed successfully!';
    }
  }

  List<MCPStep> _getCompletionMcpSteps() {
    switch (widget.scenario) {
      case 'operations-manager':
        return [
          MCPStep(
            type: 'monitoring_deployment',
            title: 'Monitoring System',
            description: 'Real-time performance tracking deployed',
            status: 'completed',
            icon: Icons.monitor_heart,
          ),
          MCPStep(
            type: 'automation_setup',
            title: 'Report Automation',
            description: 'Weekly reports and alerts configured',
            status: 'completed',
            icon: Icons.auto_awesome,
          ),
        ];
      case 'business-analyst':
        return [
          MCPStep(
            type: 'dashboard_deployment',
            title: 'Analytics Dashboard',
            description: 'Real-time business intelligence deployed',
            status: 'completed',
            icon: Icons.dashboard,
          ),
          MCPStep(
            type: 'reporting_automation',
            title: 'Report Generation',
            description: 'Automated quarterly reporting system',
            status: 'completed',
            icon: Icons.auto_awesome,
          ),
        ];
      case 'design-assistant':
        return [
          MCPStep(
            type: 'design_system_deployment',
            title: 'Design System',
            description: 'Production design system deployed',
            status: 'completed',
            icon: Icons.palette,
          ),
          MCPStep(
            type: 'component_tracking',
            title: 'Usage Analytics',
            description: 'Component usage tracking enabled',
            status: 'completed',
            icon: Icons.analytics,
          ),
        ];
      case 'coding-agent':
        return [
          MCPStep(
            type: 'deployment_pipeline',
            title: 'CI/CD Pipeline',
            description: 'Automated deployment system active',
            status: 'completed',
            icon: Icons.rocket_launch,
          ),
          MCPStep(
            type: 'monitoring_setup',
            title: 'Performance Monitoring',
            description: 'Real-time metrics and error tracking',
            status: 'completed',
            icon: Icons.monitor_heart,
          ),
        ];
      default:
        return [];
    }
  }

  Widget _buildMessageInput(ThemeColors colors) {
    if (_waitingForUserInput && _currentChatOptions.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(SpacingTokens.md),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.primary.withOpacity(0.3), width: 2)),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(seconds: 1),
                    tween: Tween(begin: 0.0, end: 1.0),
                    onEnd: () {
                      // Restart animation
                      if (mounted) setState(() {});
                    },
                    builder: (context, value, child) {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withOpacity(0.6 * value),
                              blurRadius: 12 * value,
                              spreadRadius: 4 * value,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: SpacingTokens.sm),
                Text(
                  'Choose your response:',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.sm),
            ..._currentChatOptions.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
                child: TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 800 + (index * 200)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.95 + (0.05 * value),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _currentStep > 1 ? _selectFollowUpOption(option) : _selectChatOption(option),
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(SpacingTokens.md),
                        decoration: BoxDecoration(
                          color: colors.background,
                          borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                          border: Border.all(
                            color: index == 0 ? colors.primary.withOpacity(0.4) : colors.border,
                            width: index == 0 ? 2 : 1,
                          ),
                          boxShadow: index == 0 ? [
                            BoxShadow(
                              color: colors.primary.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ] : [],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: index == 0 ? colors.primary : colors.primary.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyles.bodySmall.copyWith(
                                    color: colors.surface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: SpacingTokens.md),
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyles.bodyMedium.copyWith(
                                  color: colors.onSurface,
                                  fontWeight: index == 0 ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 1500),
                              tween: Tween(begin: 0.0, end: 1.0),
                              onEnd: () {
                                if (mounted) setState(() {});
                              },
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(4 * value, 0),
                                  child: child,
                                );
                              },
                              child: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: index == 0 ? colors.primary : colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      );
    } else {
      // Default demo mode message
      return Container(
        padding: const EdgeInsets.all(SpacingTokens.md),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.md,
                  vertical: SpacingTokens.sm,
                ),
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  _waitingForUserInput 
                      ? 'Choose a response option above...'
                      : 'Demo mode - AI is handling this conversation...',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
            const SizedBox(width: SpacingTokens.sm),
            Container(
              padding: const EdgeInsets.all(SpacingTokens.sm),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              ),
              child: Icon(
                Icons.send,
                color: colors.primary.withOpacity(0.5),
                size: 20,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildMessage(DemoMessage message, ThemeColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.role == 'assistant') ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: colors.primary,
              child: Icon(
                Icons.smart_toy,
                size: 16,
                color: colors.surface,
              ),
            ),
            const SizedBox(width: SpacingTokens.sm),
          ],
          
          Expanded(
            child: Column(
              crossAxisAlignment: message.role == 'user' 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(SpacingTokens.md),
                  decoration: BoxDecoration(
                    color: message.role == 'user' 
                        ? colors.primary 
                        : colors.surface,
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                    border: message.role == 'assistant' 
                        ? Border.all(color: colors.border) 
                        : null,
                  ),
                  child: Text(
                    message.content,
                    style: TextStyles.bodyMedium.copyWith(
                      color: message.role == 'user' 
                          ? colors.surface 
                          : colors.onSurface,
                    ),
                  ),
                ),
                
                // MCP Steps
                if (message.mcpSteps != null && message.mcpSteps!.isNotEmpty) ...[
                  const SizedBox(height: SpacingTokens.sm),
                  ...message.mcpSteps!.map((step) => _buildMcpStep(step, colors)),
                ],
                
                // Confidence indicator
                if (message.confidence != null) ...[
                  const SizedBox(height: SpacingTokens.xs),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.psychology,
                        size: 12,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: SpacingTokens.xs),
                      Text(
                        'Confidence: ${(message.confidence! * 100).toStringAsFixed(0)}%',
                        style: TextStyles.bodySmall.copyWith(
                          color: colors.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          if (message.role == 'user') ...[
            const SizedBox(width: SpacingTokens.sm),
            CircleAvatar(
              radius: 16,
              backgroundColor: colors.accent,
              child: Icon(
                Icons.person,
                size: 16,
                color: colors.surface,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMcpStep(MCPStep step, ThemeColors colors) {
    return Container(
      margin: const EdgeInsets.only(top: SpacingTokens.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.sm,
        vertical: SpacingTokens.xs,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            step.icon,
            size: 14,
            color: colors.success,
          ),
          const SizedBox(width: SpacingTokens.xs),
          Text(
            step.title,
            style: TextStyles.bodySmall.copyWith(
              color: colors.onSurface,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // New methods for user-controlled progression
  void _showContinueToNextStep() {
    setState(() {
      _isInteractiveMode = true;
      _currentChatOptions = ['Continue to next step'];
      _waitingForUserInput = false;
    });
  }

  void _showFollowUpPrompt() {
    setState(() {
      _isInteractiveMode = true;
      _currentChatOptions = ['Ask follow-up question'];
      _waitingForUserInput = false;
    });
  }

  void _showFinalActionPrompt() {
    setState(() {
      _isInteractiveMode = true;
      _currentChatOptions = ['Proceed to deployment'];
      _waitingForUserInput = false;
    });
  }

  void _addUserMessage(String content) {
    _addMessage(DemoMessage(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: content,
      timestamp: DateTime.now(),
    ));
  }

}

class DemoMessage {
  final String id;
  final String role;
  final String content;
  final DateTime timestamp;
  final double? confidence;
  final List<MCPStep>? mcpSteps;

  DemoMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.confidence,
    this.mcpSteps,
  });
}

class MCPStep {
  final String type;
  final String title;
  final String description;
  final String status;
  final IconData icon;

  MCPStep({
    required this.type,
    required this.title,
    required this.description,
    required this.status,
    required this.icon,
  });
}