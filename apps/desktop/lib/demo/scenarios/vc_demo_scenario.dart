import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';
import '../../features/orchestration/models/reasoning_workflow.dart';
import '../../features/orchestration/models/logic_block.dart';
import '../components/confidence_microscopy_widget.dart';
import '../data/sample_documents.dart';

/// VC Demo: "Holy Shit" moment showcasing AI reasoning transparency
class VCDemoScenario extends StatefulWidget {
  const VCDemoScenario({super.key});

  @override
  State<VCDemoScenario> createState() => _VCDemoScenarioState();
}

class _VCDemoScenarioState extends State<VCDemoScenario> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _uncertaintyController;
  
  DemoPhase _currentPhase = DemoPhase.intro;
  ConfidenceTree? _currentConfidenceTree;
  bool _interventionTriggered = false;
  String? _humanInputResult;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _uncertaintyController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              colors.backgroundGradientStart,
              colors.backgroundGradientMiddle,
              colors.backgroundGradientEnd,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildDemoHeader(colors),
              Expanded(
                child: _buildCurrentPhase(colors),
              ),
              _buildDemoControls(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoHeader(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Row(
        children: [
          Icon(
            Icons.psychology,
            color: colors.primary,
            size: 28,
          ),
          const SizedBox(width: SpacingTokens.md),
          Text(
            'Asmbli Demo: The First AI Reasoning Debugger',
            style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.md,
              vertical: SpacingTokens.sm,
            ),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              border: Border.all(color: colors.primary),
            ),
            child: Text(
              'LIVE DEMO',
              style: TextStyles.bodyMedium.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPhase(ThemeColors colors) {
    switch (_currentPhase) {
      case DemoPhase.intro:
        return _buildIntroPhase(colors);
      case DemoPhase.problemSetup:
        return _buildProblemSetup(colors);
      case DemoPhase.workflowExecution:
        return _buildWorkflowExecution(colors);
      case DemoPhase.uncertaintyDetected:
        return _buildUncertaintyDetection(colors);
      case DemoPhase.humanIntervention:
        return _buildHumanIntervention(colors);
      case DemoPhase.resolution:
        return _buildResolution(colors);
      case DemoPhase.micDrop:
        return _buildMicDrop(colors);
    }
  }

  Widget _buildIntroPhase(ThemeColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.visibility_off,
            size: 80,
            color: colors.error,
          ),
          const SizedBox(height: SpacingTokens.xl),
          Text(
            'The Problem with AI Today',
            style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: SpacingTokens.lg),
          Container(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            margin: const EdgeInsets.symmetric(horizontal: SpacingTokens.xxl),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$ python my_ai_script.py',
                  style: TextStyle(
                    fontFamily: 'Courier',
                    color: Colors.green,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: SpacingTokens.sm),
                Text(
                  'Processing...',
                  style: TextStyle(
                    fontFamily: 'Courier',
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: SpacingTokens.sm),
                Text(
                  'Error: Failed to complete task',
                  style: TextStyle(
                    fontFamily: 'Courier',
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: SpacingTokens.sm),
                Text(
                  '\$ # Where did it fail? Why? How confident was it? No idea.',
                  style: TextStyle(
                    fontFamily: 'Courier',
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SpacingTokens.xl),
          Text(
            'AI development today is a black box.\nWhen it fails, you have no idea why.',
            style: TextStyles.bodyLarge.copyWith(
              color: colors.onSurface,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProblemSetup(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Demo Task: Analyze Startup Pitch Deck',
            style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: SpacingTokens.lg),
          Text(
            'Let\'s watch an AI agent analyze this pitch deck and create an investment recommendation.',
            style: TextStyles.bodyLarge.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: SpacingTokens.lg),
          
          // Show the workflow that will execute
          AsmblCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reasoning Workflow',
                  style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
                ),
                const SizedBox(height: SpacingTokens.md),
                _buildWorkflowVisualization(colors),
              ],
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),
          
          // Preview document content
          Expanded(
            child: AsmblCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pitch Deck Content',
                    style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
                  ),
                  const SizedBox(height: SpacingTokens.md),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        DemoDocuments.getDocument(DocumentType.pitchDeck),
                        style: TextStyles.bodyMedium.copyWith(
                          color: colors.onSurfaceVariant,
                          fontFamily: 'Courier',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowExecution(ThemeColors colors) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(SpacingTokens.lg),
          child: Text(
            'Executing Workflow: Investment Analysis',
            style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
          ),
        ),
        
        // Real-time execution progress
        Expanded(
          child: _currentConfidenceTree != null
              ? ConfidenceMicroscopyWidget(
                  confidenceTree: _currentConfidenceTree!,
                  onNodeTap: (node) {
                    // Handle node selection
                  },
                  onInterventionTrigger: (intervention) {
                    setState(() {
                      _interventionTriggered = true;
                      _currentPhase = DemoPhase.uncertaintyDetected;
                    });
                    _uncertaintyController.forward();
                  },
                )
              : _buildLoadingExecution(colors),
        ),
      ],
    );
  }

  Widget _buildLoadingExecution(ThemeColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              return CircularProgressIndicator(
                value: _progressController.value,
                color: colors.primary,
                strokeWidth: 4,
              );
            },
          ),
          const SizedBox(height: SpacingTokens.lg),
          Text(
            'Analyzing pitch deck...',
            style: TextStyles.bodyLarge.copyWith(color: colors.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildUncertaintyDetection(ThemeColors colors) {
    return AnimatedBuilder(
      animation: _uncertaintyController,
      builder: (context, child) {
        return Column(
          children: [
            // Show the workflow with highlighted uncertainty
            if (_currentConfidenceTree != null)
              Expanded(
                flex: 2,
                child: ConfidenceMicroscopyWidget(
                  confidenceTree: _currentConfidenceTree!,
                ),
              ),
            
            // Uncertainty alert panel
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(_uncertaintyController),
              child: Container(
                margin: const EdgeInsets.all(SpacingTokens.lg),
                padding: const EdgeInsets.all(SpacingTokens.lg),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red, size: 28),
                        const SizedBox(width: SpacingTokens.md),
                        Expanded(
                          child: Text(
                            'UNCERTAINTY DETECTED',
                            style: TextStyles.cardTitle.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: SpacingTokens.md),
                    Text(
                      'Market sizing analysis has low confidence (42%). Found conflicting data sources: \$50M (Company claims) vs \$12M (Industry report). Which should I trust?',
                      style: TextStyles.bodyMedium.copyWith(color: Colors.red.shade700),
                    ),
                    const SizedBox(height: SpacingTokens.lg),
                    Text(
                      'Auto-spawning human consultation workflow...',
                      style: TextStyles.bodyMedium.copyWith(
                        color: colors.primary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHumanIntervention(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        children: [
          Text(
            'Human Consultation Spawned',
            style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: SpacingTokens.lg),
          
          Expanded(
            child: AsmblCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: colors.primary,
                        child: Icon(Icons.psychology, color: Colors.white),
                      ),
                      const SizedBox(width: SpacingTokens.md),
                      Text(
                        'AI Agent',
                        style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
                      ),
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.md),
                  Container(
                    padding: const EdgeInsets.all(SpacingTokens.md),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                    ),
                    child: Text(
                      'I\'m uncertain about market sizing because I found conflicting data:\n\n• Company claims: \$50M TAM\n• Industry report: \$12M TAM\n\nFor investment analysis, which source should I trust? The industry report is more conservative but the company might have newer data.',
                      style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.lg),
                  
                  // Human response options
                  Text(
                    'Your Response:',
                    style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
                  ),
                  const SizedBox(height: SpacingTokens.md),
                  
                  Row(
                    children: [
                      Expanded(
                        child: AsmblButton.primary(
                          text: 'Use Industry Report',
                          onPressed: () => _provideHumanInput('Use the \$12M industry report figure - more conservative for investment analysis'),
                        ),
                      ),
                      const SizedBox(width: SpacingTokens.md),
                      Expanded(
                        child: AsmblButton.secondary(
                          text: 'Use Company Data',
                          onPressed: () => _provideHumanInput('Use the \$50M company figure - they may have more recent market data'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.md),
                  AsmblButton.outline(
                    text: 'Request Both Analyses',
                    onPressed: () => _provideHumanInput('Run analysis with both figures and show the range'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolution(ThemeColors colors) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(SpacingTokens.lg),
          child: Text(
            'Workflow Resumed with Human Input',
            style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
          ),
        ),
        
        // Show updated confidence tree
        Expanded(
          child: ConfidenceMicroscopyWidget(
            confidenceTree: _buildResolvedConfidenceTree(),
          ),
        ),
        
        // Show the final result
        Container(
          margin: const EdgeInsets.all(SpacingTokens.lg),
          padding: const EdgeInsets.all(SpacingTokens.lg),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            border: Border.all(color: Colors.green),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  const SizedBox(width: SpacingTokens.md),
                  Text(
                    'ANALYSIS COMPLETE',
                    style: TextStyles.cardTitle.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SpacingTokens.md),
              Text(
                'Investment memo generated with 91% confidence using conservative market sizing. Human input resolved the uncertainty.',
                style: TextStyles.bodyMedium.copyWith(color: Colors.green.shade700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMicDrop(ThemeColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.visibility,
            size: 80,
            color: colors.primary,
          ),
          const SizedBox(height: SpacingTokens.xl),
          Text(
            'This is the First Time Anyone Has:',
            style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SpacingTokens.lg),
          
          ..._buildBulletPoints([
            'Seen an AI\'s reasoning process in real-time',
            'Watched confidence levels at granular detail',
            'Witnessed automatic human intervention when needed',
            'Debugged AI reasoning like code execution',
          ], colors),
          
          const SizedBox(height: SpacingTokens.xl),
          Container(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            margin: const EdgeInsets.symmetric(horizontal: SpacingTokens.xxl),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              border: Border.all(color: colors.primary, width: 2),
            ),
            child: Text(
              'This is not just a chat interface.\nIt\'s a debugging system for AI reasoning.',
              style: TextStyles.bodyLarge.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBulletPoints(List<String> points, ThemeColors colors) {
    return points.map((point) => Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
      child: Row(
        children: [
          const SizedBox(width: SpacingTokens.xxl),
          Icon(Icons.check, color: colors.primary, size: 20),
          const SizedBox(width: SpacingTokens.md),
          Expanded(
            child: Text(
              point,
              style: TextStyles.bodyLarge.copyWith(color: colors.onSurface),
            ),
          ),
          const SizedBox(width: SpacingTokens.xxl),
        ],
      ),
    )).toList();
  }

  Widget _buildWorkflowVisualization(ThemeColors colors) {
    return Row(
      children: [
        _buildWorkflowBlock('Goal', colors.primary),
        _buildArrow(colors),
        _buildWorkflowBlock('Context', colors.primary),
        _buildArrow(colors),
        _buildWorkflowBlock('Reasoning', Colors.orange),
        _buildArrow(colors),
        _buildWorkflowBlock('Gateway', Colors.red),
        _buildArrow(colors),
        _buildWorkflowBlock('Exit', colors.primary),
      ],
    );
  }

  Widget _buildWorkflowBlock(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
      ),
      child: Text(
        label,
        style: TextStyles.bodyMedium.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildArrow(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.sm),
      child: Icon(
        Icons.arrow_forward,
        color: colors.onSurfaceVariant,
        size: 16,
      ),
    );
  }

  Widget _buildDemoControls(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPhase != DemoPhase.intro)
            AsmblButton.secondary(
              text: 'Previous',
              onPressed: _previousPhase,
            )
          else
            const SizedBox.shrink(),
          
          Text(
            'Phase ${_currentPhase.index + 1} of ${DemoPhase.values.length}',
            style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
          ),
          
          if (_currentPhase != DemoPhase.micDrop)
            AsmblButton.primary(
              text: _getNextButtonText(),
              onPressed: _nextPhase,
            )
          else
            AsmblButton.primary(
              text: 'Restart Demo',
              onPressed: _restartDemo,
            ),
        ],
      ),
    );
  }

  String _getNextButtonText() {
    switch (_currentPhase) {
      case DemoPhase.intro: return 'Show Solution';
      case DemoPhase.problemSetup: return 'Start Execution';
      case DemoPhase.workflowExecution: return 'Trigger Uncertainty';
      case DemoPhase.uncertaintyDetected: return 'Show Intervention';
      case DemoPhase.humanIntervention: return 'Skip to Resolution';
      case DemoPhase.resolution: return 'The Mic Drop';
      case DemoPhase.micDrop: return 'Restart';
    }
  }

  void _nextPhase() {
    setState(() {
      switch (_currentPhase) {
        case DemoPhase.intro:
          _currentPhase = DemoPhase.problemSetup;
          break;
        case DemoPhase.problemSetup:
          _currentPhase = DemoPhase.workflowExecution;
          _startWorkflowExecution();
          break;
        case DemoPhase.workflowExecution:
          _currentPhase = DemoPhase.uncertaintyDetected;
          _triggerUncertainty();
          break;
        case DemoPhase.uncertaintyDetected:
          _currentPhase = DemoPhase.humanIntervention;
          break;
        case DemoPhase.humanIntervention:
          if (_humanInputResult != null) {
            _currentPhase = DemoPhase.resolution;
          }
          break;
        case DemoPhase.resolution:
          _currentPhase = DemoPhase.micDrop;
          break;
        case DemoPhase.micDrop:
          _restartDemo();
          break;
      }
    });
  }

  void _previousPhase() {
    if (_currentPhase.index > 0) {
      setState(() {
        _currentPhase = DemoPhase.values[_currentPhase.index - 1];
      });
    }
  }

  void _restartDemo() {
    setState(() {
      _currentPhase = DemoPhase.intro;
      _currentConfidenceTree = null;
      _interventionTriggered = false;
      _humanInputResult = null;
    });
    _progressController.reset();
    _uncertaintyController.reset();
  }

  void _startWorkflowExecution() {
    // Build initial confidence tree
    _currentConfidenceTree = _buildInitialConfidenceTree();
    _progressController.forward();
  }

  void _triggerUncertainty() {
    // Update confidence tree with uncertainty
    _currentConfidenceTree = _buildUncertainConfidenceTree();
    _uncertaintyController.forward();
  }

  void _provideHumanInput(String input) {
    setState(() {
      _humanInputResult = input;
      _currentPhase = DemoPhase.resolution;
    });
  }

  ConfidenceTree _buildInitialConfidenceTree() {
    return ConfidenceTree(
      root: ConfidenceNode(
        taskName: 'Create Investment Memo',
        taskType: 'goal',
        confidence: 0.85,
        uncertaintyReason: 'Overall task confidence',
        children: [
          ConfidenceNode(
            taskName: 'Analyze company overview',
            taskType: 'context',
            confidence: 0.94,
            uncertaintyReason: 'Clear company description provided',
          ),
          ConfidenceNode(
            taskName: 'Evaluate market opportunity',
            taskType: 'reasoning',
            confidence: 0.67,
            uncertaintyReason: 'Market size data quality concerns',
            children: [
              ConfidenceNode(
                taskName: 'Market sizing analysis',
                taskType: 'reasoning',
                confidence: 0.42,
                uncertaintyReason: 'Conflicting data sources detected',
                requiredExpertise: 'Market Research',
                requiresIntervention: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  ConfidenceTree _buildUncertainConfidenceTree() {
    return ConfidenceTree(
      root: ConfidenceNode(
        taskName: 'Create Investment Memo',
        taskType: 'goal',
        confidence: 0.67,
        uncertaintyReason: 'Blocked by market analysis uncertainty',
        children: [
          ConfidenceNode(
            taskName: 'Analyze company overview',
            taskType: 'context',
            confidence: 0.94,
            uncertaintyReason: 'Clear company description provided',
          ),
          ConfidenceNode(
            taskName: 'Evaluate market opportunity',
            taskType: 'reasoning',
            confidence: 0.42,
            uncertaintyReason: 'Critical uncertainty detected',
            requiresIntervention: true,
            children: [
              ConfidenceNode(
                taskName: 'Market sizing analysis',
                taskType: 'reasoning',
                confidence: 0.23,
                uncertaintyReason: 'Conflicting sources: \$50M vs \$12M',
                requiredExpertise: 'Market Research',
                requiresIntervention: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  ConfidenceTree _buildResolvedConfidenceTree() {
    return ConfidenceTree(
      root: ConfidenceNode(
        taskName: 'Create Investment Memo',
        taskType: 'goal',
        confidence: 0.91,
        uncertaintyReason: 'Resolved with human input',
        children: [
          ConfidenceNode(
            taskName: 'Analyze company overview',
            taskType: 'context',
            confidence: 0.94,
            uncertaintyReason: 'Clear company description provided',
          ),
          ConfidenceNode(
            taskName: 'Evaluate market opportunity',
            taskType: 'reasoning',
            confidence: 0.89,
            uncertaintyReason: 'Resolved with conservative estimate',
            children: [
              ConfidenceNode(
                taskName: 'Market sizing analysis',
                taskType: 'reasoning',
                confidence: 0.91,
                uncertaintyReason: 'Using industry report (\$12M) per human guidance',
                requiredExpertise: 'Market Research',
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _uncertaintyController.dispose();
    super.dispose();
  }
}

enum DemoPhase {
  intro,
  problemSetup,
  workflowExecution,
  uncertaintyDetected,
  humanIntervention,
  resolution,
  micDrop,
}