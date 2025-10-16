import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../core/design_system/design_system.dart';
import 'confidence_microscopy_widget.dart';

/// Simulates real-time AI reasoning with progressive confidence updates
class SimulatedAIReasoning extends StatefulWidget {
  final String documentType;
  final Function(ConfidenceTree)? onConfidenceUpdate;
  final Function(UncertaintyIntervention)? onInterventionTriggered;
  final Function(ReasoningComplete)? onReasoningComplete;

  const SimulatedAIReasoning({
    super.key,
    required this.documentType,
    this.onConfidenceUpdate,
    this.onInterventionTriggered,
    this.onReasoningComplete,
  });

  @override
  State<SimulatedAIReasoning> createState() => _SimulatedAIReasoningState();
}

class _SimulatedAIReasoningState extends State<SimulatedAIReasoning>
    with TickerProviderStateMixin {

  late AnimationController _thinkingController;
  late AnimationController _confidenceController;
  late AnimationController _alertController;

  ReasoningPhase _currentPhase = ReasoningPhase.initializing;
  List<ReasoningStep> _completedSteps = [];
  ReasoningStep? _currentStep;
  ConfidenceTree? _currentConfidenceTree;
  ModelRouting? _currentRouting;
  bool _interventionTriggered = false;

  @override
  void initState() {
    super.initState();
    _thinkingController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
    
    _confidenceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _alertController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _startReasoning();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReasoningHeader(colors),
          const SizedBox(height: SpacingTokens.lg),
          if (_currentRouting != null) ...[
            _buildModelRouting(colors),
            const SizedBox(height: SpacingTokens.lg),
          ],
          _buildReasoningProgress(colors),
          if (_currentConfidenceTree != null) ...[
            const SizedBox(height: SpacingTokens.lg),
            SizedBox(
              height: 400, // Constrain height to prevent overflow
              child: ConfidenceMicroscopyWidget(
                confidenceTree: _currentConfidenceTree!,
                onNodeTap: (node) {
                  // Handle node selection
                },
                onInterventionTrigger: (intervention) {
                  if (!_interventionTriggered) {
                    setState(() {
                      _interventionTriggered = true;
                    });
                    _alertController.forward();
                    widget.onInterventionTriggered?.call(intervention);
                  }
                },
              ),
            ),
          ],
          if (_interventionTriggered) ...[
            const SizedBox(height: SpacingTokens.lg),
            _buildInterventionAlert(colors),
          ],
        ],
      ),
    );
  }

  Widget _buildReasoningHeader(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _thinkingController,
            builder: (context, child) {
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(
                    0.1 + 0.2 * _thinkingController.value,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.psychology,
                  color: colors.primary,
                  size: 24,
                ),
              );
            },
          ),
          const SizedBox(width: SpacingTokens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getPhaseTitle(),
                  style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
                ),
                Text(
                  _getPhaseDescription(),
                  style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          _buildPhaseIndicator(colors),
        ],
      ),
    );
  }

  Widget _buildModelRouting(ThemeColors colors) {
    if (_currentRouting == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route, color: colors.primary, size: 20),
              const SizedBox(width: SpacingTokens.sm),
              Text(
                'Smart Model Routing',
                style: TextStyles.bodyLarge.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.md),
          ..._currentRouting!.options.map((option) => _buildRoutingOption(option, colors)),
          const SizedBox(height: SpacingTokens.md),
          Container(
            padding: const EdgeInsets.all(SpacingTokens.sm),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: colors.primary, size: 16),
                const SizedBox(width: SpacingTokens.sm),
                Text(
                  'Selected: ${_currentRouting!.selectedModel} (${_currentRouting!.reason})',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutingOption(RoutingOption option, ThemeColors colors) {
    final isSelected = option.isSelected;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: SpacingTokens.xs),
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: isSelected ? colors.primary.withOpacity(0.1) : colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(
          color: isSelected ? colors.primary : colors.border,
        ),
      ),
      child: Row(
        children: [
          if (isSelected) ...[
            Icon(Icons.check, color: colors.primary, size: 16),
            const SizedBox(width: SpacingTokens.sm),
          ],
          Expanded(
            child: Text(
              option.modelName,
              style: TextStyles.bodyMedium.copyWith(
                color: colors.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            option.cost,
            style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(width: SpacingTokens.md),
          Text(
            option.speed,
            style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(width: SpacingTokens.md),
          Text(
            '${(option.accuracy * 100).toInt()}%',
            style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildReasoningProgress(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reasoning Progress',
            style: TextStyles.bodyLarge.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),
          ..._completedSteps.map((step) => _buildReasoningStep(step, colors, true)),
          if (_currentStep != null)
            _buildReasoningStep(_currentStep!, colors, false),
        ],
      ),
    );
  }

  Widget _buildReasoningStep(ReasoningStep step, ThemeColors colors, bool isComplete) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: isComplete 
                  ? _getConfidenceColor(step.confidence, colors)
                  : colors.primary,
              shape: BoxShape.circle,
            ),
            child: isComplete
                ? Icon(Icons.check, color: Colors.white, size: 14)
                : AnimatedBuilder(
                    animation: _thinkingController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _thinkingController.value * 2 * 3.14159,
                        child: Icon(Icons.more_horiz, color: Colors.white, size: 14),
                      );
                    },
                  ),
          ),
          const SizedBox(width: SpacingTokens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        step.description,
                        style: TextStyles.bodyMedium.copyWith(
                          color: colors.onSurface,
                          fontWeight: isComplete ? FontWeight.normal : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isComplete) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SpacingTokens.sm,
                          vertical: SpacingTokens.xs,
                        ),
                        decoration: BoxDecoration(
                          color: _getConfidenceColor(step.confidence, colors).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                        ),
                        child: Text(
                          '${(step.confidence * 100).toInt()}%',
                          style: TextStyles.bodySmall.copyWith(
                            color: _getConfidenceColor(step.confidence, colors),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (step.details != null) ...[
                  const SizedBox(height: SpacingTokens.xs),
                  Text(
                    step.details!,
                    style: TextStyles.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (isComplete && step.duration != null) ...[
                  const SizedBox(height: SpacingTokens.xs),
                  Text(
                    'Completed in ${step.duration!.toStringAsFixed(1)}s',
                    style: TextStyles.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                      fontFamily: 'Courier',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterventionAlert(ThemeColors colors) {
    return AnimatedBuilder(
      animation: _alertController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.95 + 0.05 * _alertController.value,
          child: Container(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              border: Border.all(color: Colors.red, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 28),
                    const SizedBox(width: SpacingTokens.md),
                    Expanded(
                      child: Text(
                        'UNCERTAINTY INTERVENTION TRIGGERED',
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
                  'Market sizing analysis has critically low confidence (23%). Conflicting data sources detected:',
                  style: TextStyles.bodyMedium.copyWith(color: Colors.red.shade700),
                ),
                const SizedBox(height: SpacingTokens.sm),
                Container(
                  padding: const EdgeInsets.all(SpacingTokens.md),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• Company claims: \$47B TAM (Gartner 2024)',
                        style: TextStyles.bodyMedium.copyWith(color: Colors.red.shade800),
                      ),
                      Text(
                        '• Industry report: \$12B TAM (McKinsey 2024)',
                        style: TextStyles.bodyMedium.copyWith(color: Colors.red.shade800),
                      ),
                      Text(
                        '• Variance: 292% - requires human judgment',
                        style: TextStyles.bodyMedium.copyWith(
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: SpacingTokens.lg),
                Row(
                  children: [
                    Icon(Icons.psychology, color: colors.primary, size: 20),
                    const SizedBox(width: SpacingTokens.sm),
                    Text(
                      'Auto-spawning human consultation workflow...',
                      style: TextStyles.bodyMedium.copyWith(
                        color: colors.primary,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhaseIndicator(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm,
      ),
      decoration: BoxDecoration(
        color: _getPhaseColor(colors).withOpacity(0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
      ),
      child: Text(
        _currentPhase.name.toUpperCase(),
        style: TextStyles.bodySmall.copyWith(
          color: _getPhaseColor(colors),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _startReasoning() async {
    // Initialize model routing
    setState(() {
      _currentRouting = _createModelRouting();
    });

    await Future.delayed(const Duration(milliseconds: 3000)); // Slower start

    // Start reasoning steps
    final steps = _getReasoningSteps();
    
    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      
      setState(() {
        _currentStep = step;
        _currentPhase = _getPhaseForStep(i);
      });

      // Simulate realistic thinking time (slowed down for demo control)
      final duration = 3.0 + Random().nextDouble() * 4.0; // Slower timing
      await Future.delayed(Duration(milliseconds: (duration * 1000).toInt()));

      // Complete the step with confidence
      final confidence = _calculateStepConfidence(step);
      final completedStep = step.copyWith(
        confidence: confidence,
        duration: duration,
      );

      setState(() {
        _completedSteps.add(completedStep);
        _currentStep = null;
      });

      // Update confidence tree
      _updateConfidenceTree(i + 1, completedStep);

      // Check for intervention trigger
      if (confidence < 0.3 && !_interventionTriggered) {
        await Future.delayed(const Duration(milliseconds: 500));
        // Intervention will be triggered by confidence widget
      }
    }

    // Complete reasoning
    setState(() {
      _currentPhase = ReasoningPhase.complete;
    });

    widget.onReasoningComplete?.call(ReasoningComplete(
      totalSteps: steps.length,
      averageConfidence: _completedSteps.map((s) => s.confidence).reduce((a, b) => a + b) / _completedSteps.length,
      interventionsTriggered: _interventionTriggered ? 1 : 0,
      processingTime: _completedSteps.map((s) => s.duration ?? 0).reduce((a, b) => a + b),
    ));
  }

  ModelRouting _createModelRouting() {
    return ModelRouting(
      selectedModel: 'Claude-3.5-Sonnet',
      reason: 'High-stakes investment analysis',
      options: [
        RoutingOption(
          modelName: 'Ollama llama2:7b (Local)',
          cost: 'FREE',
          speed: '3.2s',
          accuracy: 0.67,
          isSelected: false,
        ),
        RoutingOption(
          modelName: 'Claude-3-Haiku',
          cost: '\$0.25',
          speed: '1.1s',
          accuracy: 0.89,
          isSelected: false,
        ),
        RoutingOption(
          modelName: 'Claude-3.5-Sonnet',
          cost: '\$1.20',
          speed: '0.8s',
          accuracy: 0.94,
          isSelected: true,
        ),
        RoutingOption(
          modelName: 'GPT-4',
          cost: '\$0.67',
          speed: '1.2s',
          accuracy: 0.91,
          isSelected: false,
        ),
      ],
    );
  }

  List<ReasoningStep> _getReasoningSteps() {
    switch (widget.documentType) {
      case 'pitch_deck':
        return [
          ReasoningStep('Analyzing business model section', details: 'Revenue streams and value proposition'),
          ReasoningStep('Evaluating market opportunity', details: 'TAM, SAM, and competitive landscape'),
          ReasoningStep('Assessing financial projections', details: 'Revenue forecasts and unit economics'),
          ReasoningStep('Reviewing team capabilities', details: 'Leadership experience and track record'),
          ReasoningStep('Analyzing competitive positioning', details: 'Differentiation and market fit'),
          ReasoningStep('Generating investment thesis', details: 'Risk assessment and recommendation'),
        ];
      default:
        return [
          ReasoningStep('Document structure analysis'),
          ReasoningStep('Content extraction and parsing'),
          ReasoningStep('Key information identification'),
          ReasoningStep('Uncertainty assessment'),
          ReasoningStep('Recommendation generation'),
        ];
    }
  }

  double _calculateStepConfidence(ReasoningStep step) {
    // Simulate realistic confidence based on step type
    if (step.description.toLowerCase().contains('market')) {
      return 0.23; // Trigger intervention
    } else if (step.description.toLowerCase().contains('financial')) {
      return 0.42; // Low confidence
    } else if (step.description.toLowerCase().contains('business model')) {
      return 0.94; // High confidence
    } else {
      return 0.70 + Random().nextDouble() * 0.25; // Random high confidence
    }
  }

  void _updateConfidenceTree(int completedSteps, ReasoningStep lastStep) {
    // Build progressive confidence tree
    final nodes = <ConfidenceNode>[];
    
    for (int i = 0; i < completedSteps && i < _completedSteps.length; i++) {
      final step = _completedSteps[i];
      nodes.add(ConfidenceNode(
        taskName: step.description,
        taskType: 'reasoning',
        confidence: step.confidence,
        uncertaintyReason: _getUncertaintyReason(step),
        requiredExpertise: step.confidence < 0.5 ? 'Domain Expert' : null,
        requiresIntervention: step.confidence < 0.3,
      ));
    }

    final tree = ConfidenceTree(
      root: ConfidenceNode(
        taskName: 'Investment Analysis',
        taskType: 'goal',
        confidence: nodes.isEmpty ? 0.5 : nodes.map((n) => n.confidence).reduce((a, b) => a + b) / nodes.length,
        uncertaintyReason: 'Overall analysis confidence',
        children: nodes,
      ),
    );

    setState(() {
      _currentConfidenceTree = tree;
    });

    widget.onConfidenceUpdate?.call(tree);
  }

  String _getUncertaintyReason(ReasoningStep step) {
    if (step.description.toLowerCase().contains('market')) {
      return 'Conflicting market size data sources detected';
    } else if (step.description.toLowerCase().contains('financial')) {
      return 'Limited historical data for projections';
    } else if (step.confidence < 0.6) {
      return 'Insufficient context for high confidence';
    } else {
      return 'Standard reasoning confidence';
    }
  }

  ReasoningPhase _getPhaseForStep(int stepIndex) {
    if (stepIndex < 2) return ReasoningPhase.analyzing;
    if (stepIndex < 4) return ReasoningPhase.evaluating;
    return ReasoningPhase.synthesizing;
  }

  String _getPhaseTitle() {
    switch (_currentPhase) {
      case ReasoningPhase.initializing:
        return 'Initializing AI Reasoning';
      case ReasoningPhase.analyzing:
        return 'Analyzing Document Content';
      case ReasoningPhase.evaluating:
        return 'Evaluating Key Factors';
      case ReasoningPhase.synthesizing:
        return 'Synthesizing Insights';
      case ReasoningPhase.complete:
        return 'Reasoning Complete';
    }
  }

  String _getPhaseDescription() {
    switch (_currentPhase) {
      case ReasoningPhase.initializing:
        return 'Setting up reasoning workflow and model selection';
      case ReasoningPhase.analyzing:
        return 'Deep analysis of document structure and content';
      case ReasoningPhase.evaluating:
        return 'Assessing key business and financial factors';
      case ReasoningPhase.synthesizing:
        return 'Generating final recommendations and insights';
      case ReasoningPhase.complete:
        return 'Analysis ready for review';
    }
  }

  Color _getPhaseColor(ThemeColors colors) {
    switch (_currentPhase) {
      case ReasoningPhase.initializing:
        return colors.primary;
      case ReasoningPhase.analyzing:
        return Colors.blue;
      case ReasoningPhase.evaluating:
        return Colors.orange;
      case ReasoningPhase.synthesizing:
        return Colors.purple;
      case ReasoningPhase.complete:
        return Colors.green;
    }
  }

  Color _getConfidenceColor(double confidence, ThemeColors colors) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _thinkingController.dispose();
    _confidenceController.dispose();
    _alertController.dispose();
    super.dispose();
  }
}

enum ReasoningPhase {
  initializing,
  analyzing,
  evaluating,
  synthesizing,
  complete,
}

class ReasoningStep {
  final String description;
  final String? details;
  final double confidence;
  final double? duration;

  ReasoningStep(
    this.description, {
    this.details,
    this.confidence = 0.0,
    this.duration,
  });

  ReasoningStep copyWith({
    String? description,
    String? details,
    double? confidence,
    double? duration,
  }) {
    return ReasoningStep(
      description ?? this.description,
      details: details ?? this.details,
      confidence: confidence ?? this.confidence,
      duration: duration ?? this.duration,
    );
  }
}

class ModelRouting {
  final String selectedModel;
  final String reason;
  final List<RoutingOption> options;

  ModelRouting({
    required this.selectedModel,
    required this.reason,
    required this.options,
  });
}

class RoutingOption {
  final String modelName;
  final String cost;
  final String speed;
  final double accuracy;
  final bool isSelected;

  RoutingOption({
    required this.modelName,
    required this.cost,
    required this.speed,
    required this.accuracy,
    required this.isSelected,
  });
}

class ReasoningComplete {
  final int totalSteps;
  final double averageConfidence;
  final int interventionsTriggered;
  final double processingTime;

  ReasoningComplete({
    required this.totalSteps,
    required this.averageConfidence,
    required this.interventionsTriggered,
    required this.processingTime,
  });
}