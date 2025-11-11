import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../core/design_system/design_system.dart';
import '../models/demo_models.dart';

/// Configuration for AI reasoning simulation
class ReasoningConfig {
  final Duration stepDuration;
  final double baseConfidence;
  final double confidenceVariance;
  final bool allowIntervention;
  final bool showReasoningTree;
  final bool enableRealTimeAdjustment;
  final List<ReasoningStep> customSteps;
  final Map<String, dynamic> modelConfig;

  const ReasoningConfig({
    this.stepDuration = const Duration(seconds: 1),
    this.baseConfidence = 0.85,
    this.confidenceVariance = 0.1,
    this.allowIntervention = true,
    this.showReasoningTree = false,
    this.enableRealTimeAdjustment = false,
    this.customSteps = const [],
    this.modelConfig = const {},
  });
}

/// Individual reasoning step with metadata
class ReasoningStep {
  final String description;
  final double confidenceImpact;
  final List<String> subTasks;
  final bool requiresValidation;
  final Map<String, dynamic> metadata;

  const ReasoningStep({
    required this.description,
    this.confidenceImpact = 0,
    this.subTasks = const [],
    this.requiresValidation = false,
    this.metadata = const {},
  });
}

/// Enhanced AI reasoning simulator with rich configuration
class EnhancedAIReasoningSimulator extends StatefulWidget {
  final String analysisType;
  final Map<String, dynamic> context;
  final ReasoningConfig config;
  final Function(ReasoningUpdate)? onUpdate;
  final Function(InterventionRequest)? onInterventionRequest;
  final Function(ReasoningResult)? onComplete;
  final Widget? customVisualization;

  const EnhancedAIReasoningSimulator({
    super.key,
    required this.analysisType,
    this.context = const {},
    this.config = const ReasoningConfig(),
    this.onUpdate,
    this.onInterventionRequest,
    this.onComplete,
    this.customVisualization,
  });

  @override
  State<EnhancedAIReasoningSimulator> createState() => 
      _EnhancedAIReasoningSimulatorState();
}

class _EnhancedAIReasoningSimulatorState 
    extends State<EnhancedAIReasoningSimulator> 
    with TickerProviderStateMixin {
  
  // Animation controllers
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late AnimationController _confidenceController;
  
  // State
  double _currentConfidence = 0.85;
  int _currentStepIndex = 0;
  List<ReasoningStep> _steps = [];
  List<CompletedStep> _completedSteps = [];
  bool _isPaused = false;
  bool _requiresIntervention = false;
  
  // Reasoning tree
  ConfidenceTree? _confidenceTree;
  
  // Timers
  Timer? _simulationTimer;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeSteps();
    _currentConfidence = widget.config.baseConfidence;
    _startSimulation();
  }
  
  void _initializeAnimations() {
    _progressController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    
    _confidenceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }
  
  void _initializeSteps() {
    if (widget.config.customSteps.isNotEmpty) {
      _steps = widget.config.customSteps;
    } else {
      _steps = _generateStepsForAnalysis();
    }
    
    // Adjust progress controller duration based on total steps
    final totalDuration = widget.config.stepDuration * _steps.length;
    _progressController.duration = totalDuration;
  }
  
  List<ReasoningStep> _generateStepsForAnalysis() {
    switch (widget.analysisType) {
      case 'document':
        return [
          ReasoningStep(
            description: 'Parsing document structure',
            subTasks: ['Identify sections', 'Extract metadata', 'Analyze formatting'],
            confidenceImpact: 0.02,
          ),
          ReasoningStep(
            description: 'Extracting requirements',
            subTasks: ['Find key phrases', 'Identify constraints', 'Map dependencies'],
            requiresValidation: true,
            confidenceImpact: -0.05,
          ),
          ReasoningStep(
            description: 'Validating completeness',
            requiresValidation: true,
            confidenceImpact: -0.08,
          ),
        ];
      
      case 'design':
        return [
          ReasoningStep(
            description: 'Understanding design intent',
            subTasks: ['Parse requirements', 'Identify patterns', 'Check constraints'],
          ),
          ReasoningStep(
            description: 'Generating component hierarchy',
            subTasks: ['Create structure', 'Define relationships', 'Apply patterns'],
            confidenceImpact: -0.03,
          ),
          ReasoningStep(
            description: 'Applying design system',
            subTasks: ['Map to components', 'Apply themes', 'Ensure consistency'],
            requiresValidation: true,
          ),
        ];
      
      case 'operations':
        return [
          ReasoningStep(
            description: 'Analyzing operational requirements',
            subTasks: ['Review current schedule', 'Identify bottlenecks', 'Check resource availability'],
          ),
          ReasoningStep(
            description: 'Optimizing scheduling algorithms',
            subTasks: ['Calculate optimal time slots', 'Balance workload distribution', 'Minimize conflicts'],
            confidenceImpact: 0.03,
          ),
          ReasoningStep(
            description: 'Setting up smart notifications',
            subTasks: ['Configure alert thresholds', 'Personalize notification timing', 'Route to appropriate stakeholders'],
            requiresValidation: true,
            confidenceImpact: -0.04,
          ),
          ReasoningStep(
            description: 'Monitoring operational metrics',
            subTasks: ['Track KPIs', 'Detect anomalies', 'Generate performance insights'],
            confidenceImpact: 0.02,
          ),
        ];
      
      case 'orchestration':
        return [
          ReasoningStep(
            description: 'Analyzing task requirements',
            subTasks: ['Decompose tasks', 'Identify skills needed', 'Set priorities'],
          ),
          ReasoningStep(
            description: 'Selecting optimal agents',
            subTasks: ['Match capabilities', 'Check availability', 'Estimate time'],
            confidenceImpact: 0.05,
          ),
          ReasoningStep(
            description: 'Coordinating execution',
            subTasks: ['Delegate tasks', 'Monitor progress', 'Handle dependencies'],
            requiresValidation: true,
            confidenceImpact: -0.06,
          ),
        ];
      
      default:
        return [
          ReasoningStep(description: 'Initializing analysis'),
          ReasoningStep(description: 'Processing data'),
          ReasoningStep(description: 'Generating insights'),
        ];
    }
  }
  
  void _startSimulation() {
    _progressController.forward();
    _runNextStep();
  }
  
  void _runNextStep() {
    if (_currentStepIndex >= _steps.length || _isPaused) {
      if (_currentStepIndex >= _steps.length) {
        _completeAnalysis();
      }
      return;
    }
    
    final currentStep = _steps[_currentStepIndex];
    
    // Update confidence based on step
    _updateConfidence(currentStep.confidenceImpact);
    
    // Build confidence tree if enabled
    if (widget.config.showReasoningTree) {
      _buildConfidenceTree(currentStep);
    }
    
    // Check for intervention
    if (currentStep.requiresValidation && 
        widget.config.allowIntervention &&
        _currentConfidence < 0.7) {
      _requestIntervention(currentStep);
      return;
    }
    
    // Notify update
    widget.onUpdate?.call(ReasoningUpdate(
      step: currentStep,
      confidence: _currentConfidence,
      progress: (_currentStepIndex + 1) / _steps.length,
      tree: _confidenceTree,
    ));
    
    setState(() {});
    
    // Schedule next step
    _simulationTimer = Timer(widget.config.stepDuration, () {
      setState(() {
        _completedSteps.add(CompletedStep(
          step: currentStep,
          confidence: _currentConfidence,
          timestamp: DateTime.now(),
        ));
        _currentStepIndex++;
      });
      _runNextStep();
    });
  }
  
  void _updateConfidence(double impact) {
    final variance = (Random().nextDouble() - 0.5) * widget.config.confidenceVariance;
    _currentConfidence = (_currentConfidence + impact + variance).clamp(0.0, 1.0);
    
    // Animate confidence change
    _confidenceController.forward(from: 0);
  }
  
  void _buildConfidenceTree(ReasoningStep step) {
    final nodes = step.subTasks.map((task) => ConfidenceNode(
      reasoning: task,
      confidence: _currentConfidence + (Random().nextDouble() - 0.5) * 0.1,
    )).toList();
    
    _confidenceTree = ConfidenceTree(
      root: ConfidenceNode(
        reasoning: step.description,
        confidence: _currentConfidence,
        children: nodes,
      ),
      averageConfidence: _currentConfidence,
    );
  }
  
  void _requestIntervention(ReasoningStep step) {
    setState(() {
      _isPaused = true;
      _requiresIntervention = true;
    });
    
    widget.onInterventionRequest?.call(InterventionRequest(
      step: step,
      reason: 'Low confidence on critical step',
      confidence: _currentConfidence,
      options: [
        'Continue with current approach',
        'Adjust parameters',
        'Switch to alternative method',
        'Request human validation',
      ],
    ));
  }
  
  void _handleInterventionResponse(String response) {
    setState(() {
      _isPaused = false;
      _requiresIntervention = false;
      
      // Adjust based on response
      if (response == 'Adjust parameters') {
        _currentConfidence += 0.15;
      } else if (response == 'Switch to alternative method') {
        _currentConfidence = widget.config.baseConfidence;
      }
    });
    
    _runNextStep();
  }
  
  void _completeAnalysis() {
    widget.onComplete?.call(ReasoningResult(
      totalSteps: _steps.length,
      completedSteps: _completedSteps,
      finalConfidence: _currentConfidence,
      analysisType: widget.analysisType,
      metadata: {
        'duration': DateTime.now().difference(_completedSteps.first.timestamp),
        'interventions': _requiresIntervention ? 1 : 0,
      },
    ));
  }
  
  @override
  void dispose() {
    _simulationTimer?.cancel();
    _progressController.dispose();
    _pulseController.dispose();
    _confidenceController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final currentStep = _currentStepIndex < _steps.length 
        ? _steps[_currentStepIndex] 
        : null;
    
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(
          color: _requiresIntervention ? colors.warning : colors.border,
          width: _requiresIntervention ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with controls
          _buildHeader(colors),
          
          // Custom visualization or default view
          if (widget.customVisualization != null)
            widget.customVisualization!
          else
            _buildDefaultView(colors, currentStep),
          
          // Intervention controls
          if (_requiresIntervention)
            _buildInterventionControls(colors),
        ],
      ),
    );
  }
  
  Widget _buildHeader(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          // Status indicator
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) => Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _requiresIntervention
                    ? colors.warning
                    : _currentStepIndex >= _steps.length
                        ? colors.success
                        : colors.primary.withOpacity(_pulseController.value),
              ),
            ),
          ),
          
          const SizedBox(width: SpacingTokens.sm),
          
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI ${widget.analysisType.toUpperCase()} Analysis',
                  style: TextStyles.bodyLarge.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.config.modelConfig.isNotEmpty)
                  Text(
                    'Model: ${widget.config.modelConfig['name'] ?? 'Default'}',
                    style: TextStyles.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          
          // Confidence with animation
          AnimatedBuilder(
            animation: _confidenceController,
            builder: (context, child) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.md,
                vertical: SpacingTokens.sm,
              ),
              decoration: BoxDecoration(
                color: _getConfidenceColor(colors).withOpacity(0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                border: Border.all(
                  color: _getConfidenceColor(colors).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getConfidenceIcon(),
                    size: 16,
                    color: _getConfidenceColor(colors),
                  ),
                  const SizedBox(width: SpacingTokens.xs),
                  Text(
                    '${(_currentConfidence * 100).toStringAsFixed(0)}%',
                    style: TextStyles.bodySmall.copyWith(
                      color: _getConfidenceColor(colors),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Pause/Play button if enabled
          if (widget.config.enableRealTimeAdjustment) ...[
            const SizedBox(width: SpacingTokens.sm),
            IconButton(
              onPressed: () {
                setState(() {
                  _isPaused = !_isPaused;
                  if (!_isPaused && !_requiresIntervention) {
                    _runNextStep();
                  }
                });
              },
              icon: Icon(
                _isPaused ? Icons.play_arrow : Icons.pause,
                color: colors.onSurface,
              ),
              tooltip: _isPaused ? 'Resume' : 'Pause',
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildDefaultView(ThemeColors colors, ReasoningStep? currentStep) {
    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) => LinearProgressIndicator(
                value: (_currentStepIndex / _steps.length),
                minHeight: 6,
                backgroundColor: colors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _requiresIntervention 
                      ? colors.warning 
                      : _currentStepIndex >= _steps.length
                          ? colors.success
                          : colors.primary,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: SpacingTokens.lg),
          
          // Current step with sub-tasks
          if (currentStep != null) ...[
            Container(
              padding: const EdgeInsets.all(SpacingTokens.md),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                border: Border.all(
                  color: colors.primary.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.psychology,
                        size: 20,
                        color: colors.primary,
                      ),
                      const SizedBox(width: SpacingTokens.sm),
                      Expanded(
                        child: Text(
                          currentStep.description,
                          style: TextStyles.bodyMedium.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Sub-tasks if any
                  if (currentStep.subTasks.isNotEmpty) ...[
                    const SizedBox(height: SpacingTokens.sm),
                    ...currentStep.subTasks.map((task) => Padding(
                      padding: const EdgeInsets.only(
                        left: SpacingTokens.xl + SpacingTokens.sm,
                        top: SpacingTokens.xs,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.primary.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(width: SpacingTokens.sm),
                          Text(
                            task,
                            style: TextStyles.bodySmall.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: SpacingTokens.md),
          ],
          
          // Completed steps
          if (_completedSteps.isNotEmpty) ...[
            Text(
              'Completed (${_completedSteps.length}/${_steps.length})',
              style: TextStyles.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: SpacingTokens.sm),
            ..._completedSteps.take(3).map((completed) => Padding(
              padding: const EdgeInsets.only(bottom: SpacingTokens.xs),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: colors.success,
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  Expanded(
                    child: Text(
                      completed.step.description,
                      style: TextStyles.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    '${(completed.confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyles.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )),
            if (_completedSteps.length > 3)
              Text(
                '... and ${_completedSteps.length - 3} more',
                style: TextStyles.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
          
          // Confidence tree visualization if enabled
          if (widget.config.showReasoningTree && _confidenceTree != null)
            _buildConfidenceTreeView(colors),
        ],
      ),
    );
  }
  
  Widget _buildInterventionControls(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: colors.warning.withOpacity(0.05),
        border: Border(top: BorderSide(color: colors.warning)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: colors.warning, size: 20),
              const SizedBox(width: SpacingTokens.sm),
              Text(
                'Human Intervention Required',
                style: TextStyles.bodyMedium.copyWith(
                  color: colors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.md),
          Wrap(
            spacing: SpacingTokens.sm,
            runSpacing: SpacingTokens.sm,
            children: [
              'Continue',
              'Adjust parameters',
              'Alternative method',
            ].map((option) => OutlinedButton(
              onPressed: () => _handleInterventionResponse(option),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.warning,
                side: BorderSide(color: colors.warning),
              ),
              child: Text(option),
            )).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildConfidenceTreeView(ThemeColors colors) {
    return Container(
      margin: const EdgeInsets.only(top: SpacingTokens.md),
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Reasoning Tree',
            style: TextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          // Simplified tree visualization
          if (_confidenceTree != null)
            _buildTreeNode(_confidenceTree!.root, colors, 0),
        ],
      ),
    );
  }
  
  Widget _buildTreeNode(ConfidenceNode node, ThemeColors colors, int depth) {
    return Padding(
      padding: EdgeInsets.only(left: depth * SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getColorForConfidence(node.confidence, colors),
                ),
              ),
              const SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: Text(
                  node.reasoning,
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
              Text(
                '${(node.confidence * 100).toStringAsFixed(0)}%',
                style: TextStyles.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          ...node.children.map((child) => 
            _buildTreeNode(child, colors, depth + 1)
          ),
        ],
      ),
    );
  }
  
  Color _getConfidenceColor(ThemeColors colors) {
    return _getColorForConfidence(_currentConfidence, colors);
  }
  
  Color _getColorForConfidence(double confidence, ThemeColors colors) {
    if (confidence >= 0.85) return colors.success;
    if (confidence >= 0.65) return colors.warning;
    return colors.error;
  }
  
  IconData _getConfidenceIcon() {
    if (_currentConfidence >= 0.85) return Icons.check_circle_outline;
    if (_currentConfidence >= 0.65) return Icons.info_outline;
    return Icons.warning_amber_outlined;
  }
}

// Data classes for structured communication

class ReasoningUpdate {
  final ReasoningStep step;
  final double confidence;
  final double progress;
  final ConfidenceTree? tree;

  const ReasoningUpdate({
    required this.step,
    required this.confidence,
    required this.progress,
    this.tree,
  });
}

class InterventionRequest {
  final ReasoningStep step;
  final String reason;
  final double confidence;
  final List<String> options;

  const InterventionRequest({
    required this.step,
    required this.reason,
    required this.confidence,
    required this.options,
  });
}

class ReasoningResult {
  final int totalSteps;
  final List<CompletedStep> completedSteps;
  final double finalConfidence;
  final String analysisType;
  final Map<String, dynamic> metadata;

  const ReasoningResult({
    required this.totalSteps,
    required this.completedSteps,
    required this.finalConfidence,
    required this.analysisType,
    required this.metadata,
  });
}

class CompletedStep {
  final ReasoningStep step;
  final double confidence;
  final DateTime timestamp;

  const CompletedStep({
    required this.step,
    required this.confidence,
    required this.timestamp,
  });
}