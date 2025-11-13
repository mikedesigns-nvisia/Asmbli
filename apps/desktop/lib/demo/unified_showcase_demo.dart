import 'package:flutter/material.dart';
import 'dart:async';
import '../core/design_system/design_system.dart';
import '../core/widgets/excalidraw_canvas.dart';
import 'components/enhanced_ai_reasoning_simulator.dart';
import 'components/confidence_indicator.dart';
import 'components/demo_container.dart';
import 'components/asmbli_demo_chat.dart';
import 'components/demo_completion_celebration.dart';
import 'components/task_completion_review.dart';
import 'components/demo_code_editor.dart';
import 'models/demo_models.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/routes.dart';

/// Unified showcase demo combining all key Asmbli features
/// 
/// Features demonstrated:
/// - Multi-agent orchestration (sales, support, analytics, design)
/// - Real-time confidence monitoring and intervention
/// - Canvas integration for visual outputs
/// - MCP tool integration
/// - Conversational UI with context awareness
class UnifiedShowcaseDemo extends StatefulWidget {
  final int? selectedAgentType;
  
  const UnifiedShowcaseDemo({
    super.key,
    this.selectedAgentType,
  });

  @override
  State<UnifiedShowcaseDemo> createState() => _UnifiedShowcaseDemoState();
}

class _UnifiedShowcaseDemoState extends State<UnifiedShowcaseDemo> 
    with TickerProviderStateMixin {
  // Demo scenario stages
  int _currentStage = 0;
  final List<DemoStage> _stages = [
    DemoStage(
      title: 'Multi-Agent Task Delegation',
      description: 'Watch AI agents collaborate on a complex project',
      icon: Icons.hub,
      duration: const Duration(seconds: 30),
    ),
    DemoStage(
      title: 'Confidence Monitoring & Intervention',
      description: 'See how Asmbli handles uncertainty and requests human input',
      icon: Icons.psychology,
      duration: const Duration(seconds: 25),
    ),
    DemoStage(
      title: 'Visual Design Generation',
      description: 'From conversation to live UI in seconds',
      icon: Icons.palette,
      duration: const Duration(seconds: 35),
    ),
    DemoStage(
      title: 'MCP Tool Integration',
      description: 'External tools working seamlessly with agents',
      icon: Icons.extension,
      duration: const Duration(seconds: 20),
    ),
  ];

  // Demo control
  bool _isPlaying = true;
  Timer? _stageTimer;

  // Active agents in the demo
  final Map<String, AgentInfo> _activeAgents = {
    'operations-manager': AgentInfo(
      name: 'Operations Manager AI',
      icon: Icons.schedule,
      color: const Color(0xFF4ECDC4),
      confidence: 0.94,
    ),
    'designer': AgentInfo(
      name: 'Design Agent',
      icon: Icons.palette,
      color: const Color(0xFFFF6B6B),
      confidence: 0.88,
    ),
    'analyst': AgentInfo(
      name: 'Analytics Agent',
      icon: Icons.analytics,
      color: const Color(0xFFFFE66D),
      confidence: 0.95,
    ),
  };

  bool _showCanvas = false;
  bool _interventionActive = false;
  int _canvasStage = 0; // 0: empty, 1: wireframe, 2: styled, 3: interactive
  bool _showCompletionScreen = false;
  bool _demoCompleted = false;
  
  // Action context tracking
  String? _currentActionContext;
  List<String> _actionHistory = [];
  
  // Excalidraw canvas state
  final GlobalKey _excalidrawKey = GlobalKey();
  bool _canvasHasContent = false;
  String? _currentDrawingData;
  
  // Verification modal state
  VerificationRequest? _currentVerification;
  EnhancedVerificationRequest? _currentEnhancedVerification;
  bool _showVerificationModal = false;
  bool _showChatInModal = false;
  late AnimationController _modalController;
  late Animation<double> _modalAnimation;
  
  // Code editor state
  bool _showCodeEditor = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _customizeForAgentType();
    _startDemo();
  }
  
  void _initializeAnimations() {
    _modalController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _modalAnimation = CurvedAnimation(
      parent: _modalController,
      curve: Curves.easeOutCubic,
    );
  }
  
  @override
  void dispose() {
    _stageTimer?.cancel();
    _modalController.dispose();
    super.dispose();
  }
  
  void _customizeForAgentType() {
    // Reset all canvas and editor states to initial state
    _canvasStage = 0;
    _showCanvas = false;
    _showCodeEditor = false;
    _currentActionContext = null;
    _actionHistory.clear();
    
    // Customize demo based on selected agent type
    switch (widget.selectedAgentType) {
      case 0: // Business Analyst
        _activeAgents['analyst']!.confidence = 0.98;
        _stages[0] = DemoStage(
          title: 'Data Analysis & Insights',
          description: 'Watch AI transform raw data into actionable insights',
          icon: Icons.analytics,
          duration: const Duration(seconds: 30),
        );
        break;
      case 1: // Design Assistant
        _showCanvas = false; // Will be shown when user starts design
        _canvasStage = 0; // Start at empty canvas
        _activeAgents['designer']!.confidence = 0.95;
        _stages[2] = DemoStage(
          title: 'Live Design Generation',
          description: 'Your ideas become visual reality instantly',
          icon: Icons.palette,
          duration: const Duration(seconds: 40),
        );
        break;
      case 2: // Operations Manager
        _activeAgents['operations-manager']!.confidence = 0.94;
        _stages[0] = DemoStage(
          title: 'Smart Operations Automation',
          description: 'Intelligent scheduling, notifications, and resource optimization',
          icon: Icons.schedule,
          duration: const Duration(seconds: 35),
        );
        break;
      case 3: // Coding Agent
        _showCodeEditor = false; // Will be shown when user starts coding
        _activeAgents['coder'] = AgentInfo(
          name: 'Coding Agent',
          icon: Icons.code,
          color: const Color(0xFF9B59B6),
          confidence: 0.92,
        );
        _stages[0] = DemoStage(
          title: 'AI-Powered Development',
          description: 'Intelligent code generation with git integration',
          icon: Icons.code,
          duration: const Duration(seconds: 35),
        );
        break;
    }
  }

  void _startDemo() {
    // Start with a gentle delay, then begin smooth progression
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _progressToNextStage();
    });
  }

  void _progressToNextStage() {
    if (_currentStage < _stages.length - 1) {
      setState(() {
        _currentStage++;
        
        // Customize transitions based on selected agent
        switch (_currentStage) {
          case 1: // Confidence monitoring stage
            _triggerConfidenceDemo();
            // Canvas progression now handled by user interaction
            break;
          case 2: // Visual/canvas stage (design agent) or analysis stage
            if (widget.selectedAgentType == 1) {
              _showCanvas = true;
              // Canvas stage progression now handled by user interaction
            }
            break;
          case 3: // Final stage
            // Canvas stage progression now handled by user interaction
            break;
        }
      });
      
      // Adaptive timing based on stage and agent type
      if (_isPlaying) {
        final nextDelay = _getStageDelay(_currentStage);
        _stageTimer?.cancel();
        _stageTimer = Timer(nextDelay, () {
          if (mounted && _isPlaying) _progressToNextStage();
        });
      }
    }
  }

  void _handleCanvasUpdate(String stage, {String? actionContext}) {
    debugPrint('🔄 _handleCanvasUpdate called with stage: $stage, actionContext: $actionContext');
    debugPrint('🔄 Current agent type: ${widget.selectedAgentType}');
    
    if (mounted) {
      setState(() {
        // Track action context
        if (actionContext != null) {
          _currentActionContext = actionContext;
          _actionHistory.add(actionContext);
        }
        
        if (widget.selectedAgentType == 1) { // Design Assistant
          debugPrint('🎨 Design Assistant stage update: $stage');
          switch (stage) {
            case 'start_design':
              _showCanvas = true;
              _canvasStage = 0; // Empty canvas ready
              debugPrint('🎨 Canvas stage set to 0 (empty)');
              break;
            case 'wireframe':
              _canvasStage = 1; // Show wireframe
              debugPrint('🎨 Canvas stage set to 1 (wireframe)');
              // Trigger wireframe generation in Excalidraw
              Future.delayed(const Duration(milliseconds: 500), () {
                debugPrint('🎨 Delayed wireframe generation trigger executing...');
                _triggerWireframeGeneration();
              });
              break;
            case 'styled':
              _canvasStage = 2; // Show styled version
              debugPrint('🎨 Canvas stage set to 2 (styled)');
              // Future: Could add styled elements here
              Future.delayed(const Duration(milliseconds: 500), () {
                _triggerWireframeGeneration();
              });
              break;
            case 'interactive':
              _canvasStage = 3; // Show interactive version
              debugPrint('🎨 Canvas stage set to 3 (interactive)');
              // Future: Could add interactive elements here
              Future.delayed(const Duration(milliseconds: 500), () {
                _triggerWireframeGeneration();
              });
              break;
          }
        } else if (widget.selectedAgentType == 3) { // Coding Agent
          switch (stage) {
            case 'show_editor':
              _showCodeEditor = true;
              break;
            case 'git_commit':
              // Code editor will handle git commit animation
              break;
          }
        }
      });
    }
  }

  void _showDemoCompletion() {
    if (mounted && !_demoCompleted) {
      setState(() {
        _demoCompleted = true;
        _showCompletionScreen = true;
      });
    }
  }
  
  void _handleVerificationRequest(VerificationRequest request) {
    setState(() {
      _currentVerification = request;
      _showVerificationModal = true;
    });
    _modalController.forward();
  }

  void _handleEnhancedVerificationRequest(EnhancedVerificationRequest request) {
    setState(() {
      _currentEnhancedVerification = request;
      _showVerificationModal = true;
      _showChatInModal = false;
    });
    _modalController.forward();
  }

  void _toggleModalChat() {
    setState(() {
      _showChatInModal = !_showChatInModal;
    });
  }
  
  void _approveVerification() {
    _modalController.reverse().then((_) {
      setState(() {
        _showVerificationModal = false;
        _showChatInModal = false;
      });
      _currentVerification?.onApprove();
      _currentVerification = null;
      _currentEnhancedVerification = null;
    });
  }
  
  void _rejectVerification() {
    _modalController.reverse().then((_) {
      setState(() {
        _showVerificationModal = false;
        _showChatInModal = false;
      });
      _currentVerification?.onReject();
      _currentVerification = null;
      _currentEnhancedVerification = null;
    });
  }

  void _selectAction(ProposedAction action) {
    _modalController.reverse().then((_) {
      setState(() {
        _showVerificationModal = false;
        _showChatInModal = false;
      });
      action.onSelect();
      _currentEnhancedVerification = null;
    });
  }

  void _handleDemoRestart() {
    setState(() {
      _showCompletionScreen = false;
      _demoCompleted = false;
      _currentStage = 0;
      _canvasStage = 0;
      _showCanvas = false;
      _interventionActive = false;
      _isPlaying = true;
      
      // Reset agent confidences
      _activeAgents.forEach((key, agent) {
        agent.confidence = _getInitialConfidence(key);
      });
    });
    
    // Restart the demo
    _startDemo();
  }

  double _getInitialConfidence(String agentKey) {
    switch (agentKey) {
      case 'operations-manager': return 0.94;
      case 'designer': return 0.88;
      case 'analyst': return 0.95;
      default: return 0.90;
    }
  }

  List<CompletionMetric> _getCompletionMetrics() {
    switch (widget.selectedAgentType) {
      case 0: // Business Analyst
        return [
          CompletionMetric(
            label: 'Data Analyzed',
            value: '3.2M',
            icon: Icons.analytics,
            isHighlight: true,
          ),
          CompletionMetric(
            label: 'Insights Generated',
            value: '12',
            icon: Icons.lightbulb,
          ),
          CompletionMetric(
            label: 'Time Saved',
            value: '4.5 hrs',
            icon: Icons.timer,
          ),
          CompletionMetric(
            label: 'Accuracy',
            value: '98%',
            icon: Icons.verified,
            isHighlight: true,
          ),
        ];
      case 1: // Design Assistant
        return [
          CompletionMetric(
            label: 'Designs Created',
            value: '4',
            icon: Icons.palette,
            isHighlight: true,
          ),
          CompletionMetric(
            label: 'Components',
            value: '24',
            icon: Icons.widgets,
          ),
          CompletionMetric(
            label: 'Iterations',
            value: '3',
            icon: Icons.refresh,
          ),
          CompletionMetric(
            label: 'User Satisfaction',
            value: '100%',
            icon: Icons.sentiment_very_satisfied,
            isHighlight: true,
          ),
        ];
      case 2: // Operations Manager
        return [
          CompletionMetric(
            label: 'Tasks Optimized',
            value: '24',
            icon: Icons.task_alt,
            isHighlight: true,
          ),
          CompletionMetric(
            label: 'Efficiency Gain',
            value: '+23%',
            icon: Icons.trending_up,
          ),
          CompletionMetric(
            label: 'Conflicts Resolved',
            value: '3',
            icon: Icons.check_circle,
          ),
          CompletionMetric(
            label: 'Time Saved',
            value: '6.2 hrs',
            icon: Icons.access_time,
            isHighlight: true,
          ),
        ];
      case 3: // Coding Agent
        return [
          CompletionMetric(
            label: 'Code Generated',
            value: '1.2k lines',
            icon: Icons.code,
            isHighlight: true,
          ),
          CompletionMetric(
            label: 'Test Coverage',
            value: '95%',
            icon: Icons.check_circle_outline,
          ),
          CompletionMetric(
            label: 'Build Time',
            value: '45s',
            icon: Icons.speed,
          ),
          CompletionMetric(
            label: 'Git Commits',
            value: '12',
            icon: Icons.history,
            isHighlight: true,
          ),
        ];
      default:
        return [];
    }
  }
  
  void _triggerConfidenceDemo() {
    // Realistic confidence scenario based on agent type
    final targetAgent = _getTargetAgentForDemo();
    if (targetAgent != null) {
      // Start with good confidence, then simulate a challenge
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _activeAgents[targetAgent]!.confidence = 0.65; // Moderate concern
            _interventionActive = false; // Keep it optional, not forced
          });
        }
      });
      
      // Recovery after showing the confidence monitoring
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted) {
          setState(() {
            _activeAgents[targetAgent]!.confidence = 0.92; // Recovered confidence
            _interventionActive = false;
          });
        }
      });
    }
  }
  
  Duration _getStageDelay(int stage) {
    // Shorter, more engaging timings
    switch (stage) {
      case 1: return const Duration(seconds: 12); // Confidence demo
      case 2: return const Duration(seconds: 15); // Feature showcase
      case 3: return const Duration(seconds: 10); // Final wrap-up
      default: return const Duration(seconds: 8);
    }
  }
  
  String? _getTargetAgentForDemo() {
    switch (widget.selectedAgentType) {
      case 0: return 'analyst'; // Business analyst confidence scenarios
      case 1: return 'designer'; // Design validation scenarios  
      case 2: return 'operations-manager'; // Operations optimization scenarios
      case 3: return 'coder'; // Code generation and testing scenarios
      default: return 'designer';
    }
  }

  AgentInfo _getAgentInfoForType() {
    switch (widget.selectedAgentType) {
      case 0:
        return AgentInfo(
          name: 'Business Analyst AI',
          icon: Icons.analytics,
          color: const Color(0xFFFFE66D),
          confidence: 0.95,
        );
      case 1:
        return AgentInfo(
          name: 'Design Assistant',
          icon: Icons.palette,
          color: const Color(0xFFFF6B6B),
          confidence: 0.88,
        );
      case 2:
        return AgentInfo(
          name: 'Operations Manager AI',
          icon: Icons.schedule,
          color: const Color(0xFF4ECDC4),
          confidence: 0.94,
        );
      case 3:
        return AgentInfo(
          name: 'Coding Agent',
          icon: Icons.code,
          color: const Color(0xFF9B59B6),
          confidence: 0.92,
        );
      default:
        return _activeAgents.values.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    // Show completion screen when demo is done
    if (_showCompletionScreen) {
      final agentInfo = _getAgentInfoForType();
      return DemoContainer(
        scenario: 'unified-showcase',
        title: 'Asmbli Demo',
        icon: Icons.auto_awesome,
        customContent: DemoCompletionCelebration(
          agentName: agentInfo.name,
          agentIcon: agentInfo.icon,
          agentColor: agentInfo.color,
          metrics: _getCompletionMetrics(),
          onRestart: _handleDemoRestart,
          onExploreMore: () {
            context.go(AppRoutes.agents);
          },
        ),
      );
    }

    return DemoContainer(
      scenario: 'unified-showcase',
      title: 'Asmbli Demo',
      icon: Icons.auto_awesome,
      customContent: Column(
        children: [
          // Stage indicator
          _buildStageIndicator(colors),
          
          // Main content area
          Expanded(
            child: Row(
              children: [
                // Chat sidebar (left side)
                Container(
                  width: 400,
                  margin: const EdgeInsets.only(
                    left: SpacingTokens.md,
                    top: SpacingTokens.md,
                    bottom: SpacingTokens.md,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    children: [
                      _buildAgentBar(colors),
                      Expanded(
                        child: AsmblDemoChat(
                          scenario: _getScenarioForSelectedAgent(),
                          onInterventionNeeded: (_) {
                            setState(() => _interventionActive = true);
                          },
                          onCanvasUpdate: (stage, {String? actionContext}) {
                            _handleCanvasUpdate(stage, actionContext: actionContext);
                          },
                          onDemoComplete: _showDemoCompletion,
                          onVerificationNeeded: _handleVerificationRequest,
                          onEnhancedVerificationNeeded: _handleEnhancedVerificationRequest,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Main content area (right side)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(SpacingTokens.md),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                      border: Border.all(color: colors.border),
                    ),
                    child: Stack(
                      children: [
                        // Canvas or workspace
                        if (!_showCodeEditor)
                          _showCanvas 
                              ? _buildCanvasArea(colors)
                              : _buildMainWorkspace(colors),
                        
                        // Code editor overlay
                        if (_showCodeEditor)
                          DemoCodeEditor(
                            onClose: () {
                              setState(() => _showCodeEditor = false);
                            },
                            actionContext: _currentActionContext,
                          ),
                        
                        // Verification modal overlay
                        if (_showVerificationModal)
                          _buildVerificationModal(colors),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // AI analysis status bar (bottom)
          if (_currentStage > 0)
            _buildAnalysisStatusBar(colors),
        ],
      ),
    );
  }

  Widget _buildStageIndicator(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        children: [
          // Progress bar
          Row(
            children: List.generate(_stages.length, (index) {
              final isActive = index == _currentStage;
              final isPast = index < _currentStage;
              
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    right: index < _stages.length - 1 ? SpacingTokens.xs : 0,
                  ),
                  decoration: BoxDecoration(
                    color: isActive || isPast
                        ? colors.primary
                        : colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          
          const SizedBox(height: SpacingTokens.md),
          
          // Current stage info
          Row(
            children: [
              Icon(
                _stages[_currentStage].icon,
                color: colors.primary,
                size: 24,
              ),
              const SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _stages[_currentStage].title,
                      style: TextStyles.bodyLarge.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _stages[_currentStage].description,
                      style: TextStyles.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Demo controls
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Play/Pause button
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isPlaying = !_isPlaying;
                        if (_isPlaying) {
                          _progressToNextStage();
                        } else {
                          _stageTimer?.cancel();
                        }
                      });
                    },
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: colors.onSurface,
                      size: 20,
                    ),
                    tooltip: _isPlaying ? 'Pause demo' : 'Resume demo',
                  ),
                  
                  const SizedBox(width: SpacingTokens.sm),
                  
                  // Manual next button
                  if (!_isPlaying && _currentStage < _stages.length - 1)
                    IconButton(
                      onPressed: () {
                        _stageTimer?.cancel();
                        _progressToNextStage();
                      },
                      icon: Icon(
                        Icons.skip_next,
                        color: colors.primary,
                        size: 20,
                      ),
                      tooltip: 'Next stage',
                    ),
                ],
              ),
              
              const SizedBox(width: SpacingTokens.md),
              
              // Intervention indicator (less prominent)
              if (_interventionActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingTokens.sm,
                    vertical: SpacingTokens.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    border: Border.all(color: colors.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, size: 14, color: colors.warning),
                      const SizedBox(width: SpacingTokens.xs),
                      Text(
                        'Review',
                        style: TextStyles.bodySmall.copyWith(
                          color: colors.warning,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgentBar(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Text(
            'Active Agents',
            style: TextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: SpacingTokens.md),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _activeAgents.entries.map((entry) {
                  final agent = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(right: SpacingTokens.sm),
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.sm,
                      vertical: SpacingTokens.xs,
                    ),
                    decoration: BoxDecoration(
                      color: agent.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                      border: Border.all(
                        color: agent.confidence < 0.7
                            ? colors.warning
                            : agent.color.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(agent.icon, size: 16, color: agent.color),
                        const SizedBox(width: SpacingTokens.xs),
                        Text(
                          agent.name,
                          style: TextStyles.bodySmall.copyWith(
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(width: SpacingTokens.sm),
                        AnimatedConfidenceIndicator(
                          confidence: agent.confidence,
                          inline: true,
                          showLabel: false,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasArea(ThemeColors colors) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(SpacingTokens.md),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.border)),
          ),
          child: Row(
            children: [
              Icon(Icons.design_services, size: 20, color: colors.primary),
              const SizedBox(width: SpacingTokens.sm),
              Text(
                'Live Design Canvas',
                style: TextStyles.bodyLarge.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_currentActionContext != null) ...[
                const SizedBox(width: SpacingTokens.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingTokens.sm,
                    vertical: SpacingTokens.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    border: Border.all(color: colors.accent, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: 14,
                        color: colors.accent,
                      ),
                      const SizedBox(width: SpacingTokens.xs),
                      Text(
                        'Selected: $_currentActionContext',
                        style: TextStyles.bodySmall.copyWith(
                          color: colors.accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.sm,
                  vertical: SpacingTokens.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.success,
                      ),
                    ),
                    const SizedBox(width: SpacingTokens.xs),
                    Text(
                      'Live Preview',
                      style: TextStyles.bodySmall.copyWith(
                        color: colors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: _buildExcalidrawCanvas(colors),
        ),
      ],
    );
  }

  Widget _buildMockDesign(ThemeColors colors) {
    switch (_canvasStage) {
      case 0:
        return _buildEmptyCanvas(colors);
      case 1:
        return _buildWireframeStage(colors);
      case 2:
        return _buildStyledStage(colors);
      case 3:
        return _buildInteractiveStage(colors);
      default:
        return _buildEmptyCanvas(colors);
    }
  }

  Widget _buildEmptyCanvas(ThemeColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.design_services,
            size: 64,
            color: colors.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: SpacingTokens.lg),
          Text(
            'Canvas Ready',
            style: TextStyles.bodyLarge.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          Text(
            'AI will generate designs here',
            style: TextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWireframeStage(ThemeColors colors) {
    return Container(
      margin: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        children: [
          // Wireframe header
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: colors.onSurfaceVariant, width: 2),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            ),
            child: Center(
              child: Text(
                'Header (Wireframe)',
                style: TextStyles.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: SpacingTokens.md),
          
          // Wireframe content
          Expanded(
            child: Column(
              children: [
                // Navigation wireframe
                Container(
                  width: double.infinity,
                  height: 30,
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.onSurfaceVariant, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  ),
                  child: Row(
                    children: List.generate(3, (index) => 
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(color: colors.onSurfaceVariant),
                          ),
                          child: Center(
                            child: Text(
                              'Nav ${index + 1}',
                              style: TextStyles.bodySmall.copyWith(
                                color: colors.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: SpacingTokens.md),
                
                // Content wireframes
                ...List.generate(2, (index) => Container(
                  width: double.infinity,
                  height: 60,
                  margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.onSurfaceVariant, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  ),
                  child: Center(
                    child: Text(
                      'Content Block ${index + 1}',
                      style: TextStyles.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyledStage(ThemeColors colors) {
    return Container(
      margin: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        children: [
          // Styled header
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary, colors.accent],
              ),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            ),
            child: Center(
              child: Text(
                'Project Dashboard',
                style: TextStyles.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: SpacingTokens.md),
          
          // Styled navigation
          Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                _buildNavItem('Overview', true, colors),
                _buildNavItem('Tasks', false, colors),
                _buildNavItem('Team', false, colors),
              ],
            ),
          ),
          
          const SizedBox(height: SpacingTokens.md),
          
          // Styled content cards
          Expanded(
            child: Column(
              children: [
                // Stats card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(SpacingTokens.lg),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                    border: Border.all(color: colors.border),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.trending_up, color: colors.success, size: 24),
                      const SizedBox(width: SpacingTokens.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Project Progress',
                            style: TextStyles.bodyMedium.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '78% Complete',
                            style: TextStyles.bodySmall.copyWith(
                              color: colors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: SpacingTokens.md),
                
                // Task list card
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(SpacingTokens.lg),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Tasks',
                          style: TextStyles.bodyMedium.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: SpacingTokens.sm),
                        ...List.generate(3, (index) => Container(
                          padding: const EdgeInsets.symmetric(vertical: SpacingTokens.xs),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: index == 0 ? colors.success : colors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: index == 0 
                                    ? Icon(Icons.check, size: 12, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: SpacingTokens.sm),
                              Text(
                                'Task ${index + 1}',
                                style: TextStyles.bodySmall.copyWith(
                                  color: colors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveStage(ThemeColors colors) {
    return Container(
      margin: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        children: [
          // Interactive header with button
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary, colors.accent],
              ),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
              child: Row(
                children: [
                  Text(
                    'Project Dashboard',
                    style: TextStyles.bodyLarge.copyWith(
                      color: Colors.white,
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
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    ),
                    child: Text(
                      '+ Add Task',
                      style: TextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: SpacingTokens.md),
          
          // Interactive content
          Expanded(
            child: Column(
              children: [
                // Interactive stats row
                Row(
                  children: [
                    Expanded(child: _buildInteractiveStatCard('Active', '12', colors.primary, colors)),
                    const SizedBox(width: SpacingTokens.sm),
                    Expanded(child: _buildInteractiveStatCard('Completed', '24', colors.success, colors)),
                    const SizedBox(width: SpacingTokens.sm),
                    Expanded(child: _buildInteractiveStatCard('Overdue', '3', colors.warning, colors)),
                  ],
                ),
                
                const SizedBox(height: SpacingTokens.md),
                
                // Interactive modal demo
                Expanded(
                  child: Stack(
                    children: [
                      // Background content
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(SpacingTokens.lg),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                          border: Border.all(color: colors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Task Management',
                              style: TextStyles.bodyMedium.copyWith(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: SpacingTokens.sm),
                            ...List.generate(3, (index) => Container(
                              margin: const EdgeInsets.only(bottom: SpacingTokens.xs),
                              child: Text(
                                '• Task ${index + 1} details...',
                                style: TextStyles.bodySmall.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            )),
                          ],
                        ),
                      ),
                      
                      // Modal overlay
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: Center(
                          child: Container(
                            width: 200,
                            padding: const EdgeInsets.all(SpacingTokens.lg),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_task,
                                  color: colors.primary,
                                  size: 32,
                                ),
                                const SizedBox(height: SpacingTokens.sm),
                                Text(
                                  'Add New Task',
                                  style: TextStyles.bodyMedium.copyWith(
                                    color: colors.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: SpacingTokens.sm),
                                Text(
                                  'Interactive modal generated by AI',
                                  style: TextStyles.bodySmall.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: SpacingTokens.md),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: SpacingTokens.sm,
                                        vertical: SpacingTokens.xs,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: colors.border),
                                        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                                      ),
                                      child: Text(
                                        'Cancel',
                                        style: TextStyles.bodySmall.copyWith(
                                          color: colors.onSurface,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: SpacingTokens.sm,
                                        vertical: SpacingTokens.xs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.primary,
                                        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                                      ),
                                      child: Text(
                                        'Add',
                                        style: TextStyles.bodySmall.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(String label, bool isActive, ThemeColors colors) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.xs),
        decoration: BoxDecoration(
          color: isActive ? colors.primary.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyles.bodySmall.copyWith(
              color: isActive ? colors.primary : colors.onSurfaceVariant,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveStatCard(String label, String value, Color accentColor, ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyles.sectionTitle.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            label,
            style: TextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _getAnalysisType() {
    // Adapt analysis type based on selected agent and current stage
    if (widget.selectedAgentType != null) {
      switch (widget.selectedAgentType!) {
        case 0: return 'document'; // Business Analyst
        case 1: return 'design';   // Design Assistant
        case 2: return 'operations'; // Operations Manager
      }
    }
    
    switch (_currentStage) {
      case 0: return 'orchestration';
      case 1: return 'confidence';
      case 2: return 'design';
      case 3: return 'integration';
      default: return 'general';
    }
  }
  
  double _getBaseConfidence() {
    // Agent-specific base confidence levels
    switch (widget.selectedAgentType) {
      case 0: return 0.92; // Business Analyst - high confidence with data
      case 1: return 0.85; // Design Assistant - moderate, needs validation
      case 2: return 0.94; // Operations Manager - high operational efficiency
      default: return 0.80;
    }
  }
  
  String _getActiveModelName() {
    switch (_currentStage) {
      case 0: return 'Claude 4.5 Sonnet';
      case 1: return 'Multi-model consensus';
      case 2: return 'GPT-4 Vision';
      case 3: return 'Specialized MCP Agent';
      default: return 'Claude 4.5 Sonnet';
    }
  }
  
  String _getScenarioForSelectedAgent() {
    if (widget.selectedAgentType != null) {
      switch (widget.selectedAgentType!) {
        case 0: return 'business-analyst';
        case 1: return 'design-assistant'; 
        case 2: return 'operations-manager';
        case 3: return 'coding-agent';
      }
    }
    return 'unified-demo';
  }

  Widget _buildMainWorkspace(ThemeColors colors) {
    return Column(
      children: [
        // Workspace header
        Container(
          padding: const EdgeInsets.all(SpacingTokens.lg),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.border)),
          ),
          child: Row(
            children: [
              Icon(_getWorkspaceIcon(), color: colors.primary, size: 24),
              const SizedBox(width: SpacingTokens.sm),
              Text(
                _getWorkspaceTitle(),
                style: TextStyles.sectionTitle.copyWith(
                  color: colors.onSurface,
                ),
              ),
              const Spacer(),
              // Code editor button
              IconButton(
                onPressed: () {
                  setState(() => _showCodeEditor = !_showCodeEditor);
                },
                icon: Icon(
                  Icons.code,
                  color: _showCodeEditor ? colors.primary : colors.onSurfaceVariant,
                  size: 20,
                ),
                tooltip: 'Toggle Code Editor',
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.sm,
                  vertical: SpacingTokens.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                ),
                child: Text(
                  'Live Demo',
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Main workspace content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(SpacingTokens.xl),
            child: _buildWorkspaceContent(colors),
          ),
        ),
      ],
    );
  }

  IconData _getWorkspaceIcon() {
    switch (widget.selectedAgentType) {
      case 0: return Icons.analytics; // Business Analyst
      case 1: return Icons.palette; // Design Assistant
      case 2: return Icons.dashboard; // Operations Manager
      default: return Icons.dashboard;
    }
  }

  String _getWorkspaceTitle() {
    switch (widget.selectedAgentType) {
      case 0: return 'Analytics Dashboard';
      case 1: return 'Design Workspace';
      case 2: return 'Operations Dashboard';
      default: return 'AI Workspace';
    }
  }

  Widget _buildWorkspaceContent(ThemeColors colors) {
    return Row(
      children: [
        // Main workspace content
        Expanded(
          flex: 3,
          child: _buildAgentWorkspace(colors),
        ),
        
        // Action history sidebar
        if (_actionHistory.isNotEmpty) ...[
          const SizedBox(width: SpacingTokens.lg),
          Container(
            width: 280,
            child: _buildActionHistoryPanel(colors),
          ),
        ],
      ],
    );
  }

  Widget _buildAgentWorkspace(ThemeColors colors) {
    switch (widget.selectedAgentType) {
      case 0: // Business Analyst
        return _buildAnalyticsWorkspace(colors);
      case 1: // Design Assistant
        return _buildDesignWorkspace(colors);
      case 2: // Operations Manager
        return _buildOperationsWorkspace(colors);
      default:
        return _buildDefaultWorkspace(colors);
    }
  }

  Widget _buildActionHistoryPanel(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                size: 16,
                color: colors.accent,
              ),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                'Decision History',
                style: TextStyles.bodyMedium.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.md),
          Expanded(
            child: ListView.builder(
              itemCount: _actionHistory.length,
              itemBuilder: (context, index) {
                final action = _actionHistory[index];
                final isLatest = index == _actionHistory.length - 1;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isLatest ? colors.accent : colors.onSurfaceVariant,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: SpacingTokens.sm),
                      Expanded(
                        child: Text(
                          action,
                          style: TextStyles.bodySmall.copyWith(
                            color: isLatest ? colors.accent : colors.onSurfaceVariant,
                            fontWeight: isLatest ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsWorkspace(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metrics cards row
        Row(
          children: [
            Expanded(child: _buildMetricCard('Revenue', '\$3.2M', '+15%', colors.success, colors)),
            const SizedBox(width: SpacingTokens.md),
            Expanded(child: _buildMetricCard('Customers', '2,847', '+22%', colors.primary, colors)),
            const SizedBox(width: SpacingTokens.md),
            Expanded(child: _buildMetricCard('Avg Deal', '\$45K', '+8%', colors.accent, colors)),
          ],
        ),
        
        const SizedBox(height: SpacingTokens.xl),
        
        // Chart placeholder
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
              border: Border.all(color: colors.border),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 64, color: colors.primary.withOpacity(0.5)),
                  const SizedBox(height: SpacingTokens.md),
                  Text(
                    'Q4 Sales Performance Chart',
                    style: TextStyles.bodyLarge.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesignWorkspace(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Design tools header
        Row(
          children: [
            _buildToolButton('Components', Icons.widgets, colors),
            const SizedBox(width: SpacingTokens.sm),
            _buildToolButton('Colors', Icons.palette, colors),
            const SizedBox(width: SpacingTokens.sm),
            _buildToolButton('Typography', Icons.text_fields, colors),
            const SizedBox(width: SpacingTokens.sm),
            _buildToolButton('Layouts', Icons.dashboard, colors),
          ],
        ),
        
        const SizedBox(height: SpacingTokens.xl),
        
        // Design canvas placeholder
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
              border: Border.all(color: colors.border, style: BorderStyle.solid, width: 2),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.design_services, size: 64, color: colors.primary.withOpacity(0.5)),
                  const SizedBox(height: SpacingTokens.md),
                  Text(
                    'Design Canvas',
                    style: TextStyles.bodyLarge.copyWith(color: colors.onSurfaceVariant),
                  ),
                  Text(
                    'AI-generated designs will appear here',
                    style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOperationsWorkspace(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status indicators
        Row(
          children: [
            Expanded(child: _buildStatusCard('Active Tasks', '24', Icons.task_alt, colors.primary, colors)),
            const SizedBox(width: SpacingTokens.md),
            Expanded(child: _buildStatusCard('Team Load', '78%', Icons.group, colors.warning, colors)),
            const SizedBox(width: SpacingTokens.md),
            Expanded(child: _buildStatusCard('Efficiency', '+23%', Icons.trending_up, colors.success, colors)),
          ],
        ),
        
        const SizedBox(height: SpacingTokens.xl),
        
        // Operations timeline
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Optimized Schedule',
                  style: TextStyles.bodyLarge.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: SpacingTokens.md),
                Expanded(
                  child: ListView(
                    children: [
                      _buildTimelineItem('9:00 AM', 'Team Standup', 'All hands', colors),
                      _buildTimelineItem('10:30 AM', 'Design Review', 'Product Team', colors),
                      _buildTimelineItem('2:00 PM', 'Sprint Planning', 'Dev Team', colors),
                      _buildTimelineItem('4:00 PM', 'Client Presentation', 'Sales Team', colors),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultWorkspace(ThemeColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 64, color: colors.primary.withOpacity(0.5)),
          const SizedBox(height: SpacingTokens.md),
          Text(
            'AI Workspace',
            style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
          ),
          Text(
            'Your AI assistant is ready to help',
            style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, String change, Color accentColor, ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            value,
            style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            change,
            style: TextStyles.bodySmall.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(String label, IconData icon, ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: SpacingTokens.xs),
          Text(
            label,
            style: TextStyles.bodySmall.copyWith(color: colors.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String label, String value, IconData icon, Color accentColor, ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: accentColor, size: 24),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            value,
            style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
          ),
          Text(
            label,
            style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String time, String title, String team, ThemeColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.md),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: SpacingTokens.md),
          Expanded(
            child: Row(
              children: [
                Text(
                  time,
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: SpacingTokens.md),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
                  ),
                ),
                Text(
                  team,
                  style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationModal(ThemeColors colors) {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: ScaleTransition(
          scale: _modalAnimation,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(seconds: 2),
            tween: Tween(begin: 0.0, end: 1.0),
            onEnd: () {
              // Restart glow animation
              if (mounted) setState(() {});
            },
            builder: (context, glowValue, child) {
              return Container(
                margin: const EdgeInsets.all(SpacingTokens.xxl),
                constraints: BoxConstraints(
                  maxWidth: _showChatInModal ? 800 : 600,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
                  border: Border.all(
                    color: colors.primary.withOpacity(0.6),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    // Pulsing glow effect
                    BoxShadow(
                      color: colors.primary.withOpacity(0.4 * glowValue),
                      blurRadius: 30 * glowValue,
                      spreadRadius: 5 * glowValue,
                    ),
                    BoxShadow(
                      color: colors.primary.withOpacity(0.2 * glowValue),
                      blurRadius: 50 * glowValue,
                      spreadRadius: 10 * glowValue,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: _currentEnhancedVerification != null
                ? _buildEnhancedVerificationContent(colors)
                : _buildSimpleVerificationContent(colors),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleVerificationContent(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1000),
                tween: Tween(begin: 0.8, end: 1.2),
                onEnd: () {
                  // Restart icon pulse animation
                  if (mounted) setState(() {});
                },
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withOpacity(0.3),
                            blurRadius: 8 * scale,
                            spreadRadius: 2 * scale,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.verified_user_outlined,
                        color: colors.primary,
                        size: 24,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Human Verification Required',
                      style: TextStyles.sectionTitle.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Container(
                      width: 40,
                      height: 3,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        tween: Tween(begin: 0.0, end: 1.0),
                        onEnd: () {
                          if (mounted) setState(() {});
                        },
                        builder: (context, progress, child) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                stops: [0.0, progress, 1.0],
                                colors: [
                                  colors.primary.withOpacity(0.3),
                                  colors.primary,
                                  colors.primary.withOpacity(0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: SpacingTokens.lg),
          
          Container(
            padding: const EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              border: Border.all(color: colors.primary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Proposed Action: ${_currentVerification?.action ?? ""}',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: SpacingTokens.sm),
                Text(
                  _currentVerification?.details ?? '',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: SpacingTokens.xl),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: AsmblButton.secondary(
                  text: 'Reject',
                  onPressed: _rejectVerification,
                  icon: Icons.close,
                ),
              ),
              const SizedBox(width: SpacingTokens.md),
              Flexible(
                child: AsmblButton.primary(
                  text: 'Approve',
                  onPressed: _approveVerification,
                  icon: Icons.check,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedVerificationContent(ThemeColors colors) {
    if (_showChatInModal) {
      return _buildChatInterface(colors);
    }

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: colors.primary,
                size: 24,
              ),
              const SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: Text(
                  _currentEnhancedVerification?.title ?? 'AI Decision Required',
                  style: TextStyles.sectionTitle.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
              IconButton(
                onPressed: _toggleModalChat,
                icon: Icon(
                  Icons.chat,
                  color: colors.onSurfaceVariant,
                  size: 20,
                ),
                tooltip: 'Chat with AI',
              ),
            ],
          ),
          
          const SizedBox(height: SpacingTokens.lg),
          
          // Situation description
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              _currentEnhancedVerification?.situation ?? '',
              style: TextStyles.bodyMedium.copyWith(
                color: colors.onSurface,
              ),
            ),
          ),
          
          const SizedBox(height: SpacingTokens.lg),
          
          // Proposed actions
          Text(
            'Proposed Actions',
            style: TextStyles.bodyLarge.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: SpacingTokens.md),
          
          ...(_currentEnhancedVerification?.proposedActions ?? []).map((action) =>
            Container(
              margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
              child: _buildActionCard(action, colors),
            ),
          ),
          
          const SizedBox(height: SpacingTokens.lg),
          
          // Chat button
          AsmblButton.outline(
            text: 'Discuss with AI',
            onPressed: _toggleModalChat,
            icon: Icons.chat,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(ProposedAction action, ThemeColors colors) {
    return GestureDetector(
      onTap: () => _selectAction(action),
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.md),
        decoration: BoxDecoration(
          color: action.isRecommended ? colors.primary.withOpacity(0.05) : colors.surface,
          borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          border: Border.all(
            color: action.isRecommended ? colors.primary : colors.border,
            width: action.isRecommended ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              action.icon,
              color: action.color ?? (action.isRecommended ? colors.primary : colors.onSurfaceVariant),
              size: 24,
            ),
            const SizedBox(width: SpacingTokens.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        action.title,
                        style: TextStyles.bodyMedium.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (action.isRecommended) ...[
                        const SizedBox(width: SpacingTokens.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: SpacingTokens.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
                          ),
                          child: Text(
                            'RECOMMENDED',
                            style: TextStyles.bodySmall.copyWith(
                              color: colors.surface,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.xs),
                  Text(
                    action.description,
                    style: TextStyles.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInterface(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        children: [
          // Chat header
          Row(
            children: [
              IconButton(
                onPressed: _toggleModalChat,
                icon: Icon(
                  Icons.arrow_back,
                  color: colors.onSurfaceVariant,
                ),
              ),
              Icon(
                Icons.chat,
                color: colors.primary,
                size: 24,
              ),
              const SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: Text(
                  'Discuss Decision',
                  style: TextStyles.sectionTitle.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: SpacingTokens.lg),
          
          // Chat messages area
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(SpacingTokens.md),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildChatMessage(
                    'AI Assistant',
                    'I\'ve analyzed the situation. Here\'s what I found: The current approach has some risks but also potential benefits. What specific concerns do you have?',
                    true,
                    colors,
                  ),
                  const SizedBox(height: SpacingTokens.md),
                  _buildChatMessage(
                    'You',
                    'What are the main risks with option 2?',
                    false,
                    colors,
                  ),
                  const SizedBox(height: SpacingTokens.md),
                  _buildChatMessage(
                    'AI Assistant',
                    'The main risks include potential data inconsistency during the migration phase and temporary performance degradation. However, the long-term benefits outweigh these short-term challenges.',
                    true,
                    colors,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: SpacingTokens.md),
          
          // Chat input
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingTokens.md,
                    vertical: SpacingTokens.sm,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(
                    'Type your question...',
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
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                ),
                child: Icon(
                  Icons.send,
                  color: colors.surface,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(String sender, String message, bool isAI, ThemeColors colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: isAI ? colors.primary : colors.accent,
          child: Icon(
            isAI ? Icons.smart_toy : Icons.person,
            size: 16,
            color: colors.surface,
          ),
        ),
        const SizedBox(width: SpacingTokens.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sender,
                style: TextStyles.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: SpacingTokens.xs),
              Text(
                message,
                style: TextStyles.bodyMedium.copyWith(
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExcalidrawCanvas(ThemeColors colors) {
    return Container(
      margin: const EdgeInsets.all(SpacingTokens.md),
      child: ExcalidrawCanvas(
        key: _excalidrawKey,
        darkMode: Theme.of(context).brightness == Brightness.dark,
        sessionId: 'design_assistant_${widget.selectedAgentType}_${DateTime.now().millisecondsSinceEpoch}',
        onDrawingChanged: (drawingData) {
          setState(() {
            _canvasHasContent = true;
            _currentDrawingData = drawingData;
          });
        },
        onDrawingSaved: (drawingData) {
          debugPrint('🎨 Drawing saved: ${drawingData.length} characters');
          // Could integrate with MCP or local storage here
        },
        onPNGExported: (base64PNG) {
          debugPrint('📸 PNG exported: ${base64PNG.length} characters');
          // Could save PNG or send to chat
        },
        onError: (error) {
          debugPrint('❌ Excalidraw error: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Canvas error: $error'),
              backgroundColor: colors.error,
            ),
          );
        },
      ),
    );
  }

  void _triggerWireframeGeneration() {
    debugPrint('🎯 _triggerWireframeGeneration called, _canvasStage: $_canvasStage');
    debugPrint('🎯 _excalidrawKey.currentState: ${_excalidrawKey.currentState}');
    
    // Add wireframe elements based on canvas stage
    if (_excalidrawKey.currentState != null) {
      debugPrint('🎯 Canvas state exists, calling addWireframeTemplate for stage $_canvasStage');
      switch (_canvasStage) {
        case 1: // Wireframe stage
          (_excalidrawKey.currentState as dynamic).addWireframeTemplate();
          break;
        case 2: // Styled stage - could add more elements
          // Future: Add styled elements programmatically
          (_excalidrawKey.currentState as dynamic).addWireframeTemplate();
          break;
        case 3: // Interactive stage - could add interactive elements
          // Future: Add interactive annotations
          (_excalidrawKey.currentState as dynamic).addWireframeTemplate();
          break;
      }
    } else {
      debugPrint('❌ Cannot trigger wireframe generation - canvas state is null');
    }
  }

  Widget _buildAnalysisStatusBar(ThemeColors colors) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
        child: Row(
          children: [
            // Analysis type indicator
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.sm,
                vertical: SpacingTokens.xs,
              ),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.psychology,
                    size: 16,
                    color: colors.primary,
                  ),
                  const SizedBox(width: SpacingTokens.xs),
                  Text(
                    'AI Analysis: ${_getAnalysisType()}',
                    style: TextStyles.bodySmall.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: SpacingTokens.md),
            
            // Current step
            Text(
              'Stage ${_currentStage + 1}/${_stages.length}',
              style: TextStyles.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            
            const Spacer(),
            
            // Model info
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.memory,
                  size: 14,
                  color: colors.accent,
                ),
                const SizedBox(width: SpacingTokens.xs),
                Text(
                  _getActiveModelName(),
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            
            const SizedBox(width: SpacingTokens.md),
            
            // Confidence indicator
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.sm,
                vertical: SpacingTokens.xs,
              ),
              decoration: BoxDecoration(
                color: _getBaseConfidence() > 0.9
                    ? colors.success.withOpacity(0.1)
                    : colors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getBaseConfidence() > 0.9
                          ? colors.success
                          : colors.warning,
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.xs),
                  Text(
                    '${(_getBaseConfidence() * 100).toStringAsFixed(0)}%',
                    style: TextStyles.bodySmall.copyWith(
                      color: _getBaseConfidence() > 0.9
                          ? colors.success
                          : colors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DemoStage {
  final String title;
  final String description;
  final IconData icon;
  final Duration duration;

  const DemoStage({
    required this.title,
    required this.description,
    required this.icon,
    required this.duration,
  });
}

class AgentInfo {
  final String name;
  final IconData icon;
  final Color color;
  double confidence;

  AgentInfo({
    required this.name,
    required this.icon,
    required this.color,
    required this.confidence,
  });
}