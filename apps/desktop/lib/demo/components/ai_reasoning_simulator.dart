import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../core/design_system/design_system.dart';

/// Unified AI reasoning simulator for various demo scenarios
class AIReasoningSimulator extends StatefulWidget {
  final String analysisType;
  final Map<String, dynamic> context;
  final Function(Map<String, dynamic>)? onAnalysisUpdate;
  final Function(double confidence)? onConfidenceChange;
  final VoidCallback? onInterventionNeeded;
  final VoidCallback? onComplete;

  const AIReasoningSimulator({
    super.key,
    required this.analysisType,
    this.context = const {},
    this.onAnalysisUpdate,
    this.onConfidenceChange,
    this.onInterventionNeeded,
    this.onComplete,
  });

  @override
  State<AIReasoningSimulator> createState() => _AIReasoningSimulatorState();
}

class _AIReasoningSimulatorState extends State<AIReasoningSimulator> 
    with TickerProviderStateMixin {
  
  late AnimationController _progressController;
  late AnimationController _pulseController;
  
  double _confidence = 0.85;
  String _currentStep = 'Initializing...';
  List<String> _completedSteps = [];
  bool _isComplete = false;
  Timer? _simulationTimer;
  
  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _startSimulation();
  }
  
  void _startSimulation() {
    _progressController.forward();
    
    // Simulate progressive analysis
    int step = 0;
    final steps = _getStepsForAnalysis();
    
    _simulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (step >= steps.length) {
        timer.cancel();
        _completeAnalysis();
        return;
      }
      
      setState(() {
        if (step > 0) {
          _completedSteps.add(_currentStep);
        }
        _currentStep = steps[step];
        
        // Simulate confidence changes
        _confidence = 0.85 + (Random().nextDouble() * 0.1) - 0.05;
        
        // Trigger intervention if confidence drops
        if (_confidence < 0.65 && widget.onInterventionNeeded != null) {
          widget.onInterventionNeeded!();
        }
      });
      
      widget.onConfidenceChange?.call(_confidence);
      widget.onAnalysisUpdate?.call({
        'step': _currentStep,
        'confidence': _confidence,
        'progress': (step + 1) / steps.length,
      });
      
      step++;
    });
  }
  
  List<String> _getStepsForAnalysis() {
    switch (widget.analysisType) {
      case 'document':
        return [
          'Parsing document structure',
          'Extracting requirements',
          'Analyzing dependencies',
          'Validating completeness',
          'Generating insights',
        ];
      case 'alert':
        return [
          'Analyzing alert patterns',
          'Correlating metrics',
          'Identifying root cause',
          'Evaluating impact',
          'Planning remediation',
        ];
      case 'design':
        return [
          'Understanding requirements',
          'Generating components',
          'Creating layout',
          'Applying styling',
          'Optimizing code',
        ];
      default:
        return [
          'Initializing analysis',
          'Processing data',
          'Running validation',
          'Generating results',
        ];
    }
  }
  
  void _completeAnalysis() {
    setState(() {
      _completedSteps.add(_currentStep);
      _currentStep = 'Analysis complete';
      _isComplete = true;
    });
    
    widget.onComplete?.call();
  }
  
  @override
  void dispose() {
    _simulationTimer?.cancel();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) => Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isComplete 
                      ? colors.success 
                      : colors.primary.withOpacity(_pulseController.value),
                  ),
                ),
              ),
              const SizedBox(width: SpacingTokens.sm),
              Text(
                'AI Analysis: ${widget.analysisType}',
                style: TextStyles.bodyLarge.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Confidence indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.sm,
                  vertical: SpacingTokens.xs,
                ),
                decoration: BoxDecoration(
                  color: _getConfidenceColor(colors).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                ),
                child: Text(
                  'Confidence: ${(_confidence * 100).toStringAsFixed(0)}%',
                  style: TextStyles.bodySmall.copyWith(
                    color: _getConfidenceColor(colors),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: SpacingTokens.lg),
          
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) => LinearProgressIndicator(
                value: _progressController.value,
                minHeight: 4,
                backgroundColor: colors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _isComplete ? colors.success : colors.primary,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: SpacingTokens.lg),
          
          // Current step
          Container(
            padding: const EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            ),
            child: Row(
              children: [
                Icon(
                  _isComplete ? Icons.check_circle : Icons.analytics,
                  size: 20,
                  color: _isComplete ? colors.success : colors.primary,
                ),
                const SizedBox(width: SpacingTokens.sm),
                Expanded(
                  child: Text(
                    _currentStep,
                    style: TextStyles.bodyMedium.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Completed steps
          if (_completedSteps.isNotEmpty) ...[
            const SizedBox(height: SpacingTokens.md),
            Text(
              'Completed:',
              style: TextStyles.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: SpacingTokens.sm),
            ..._completedSteps.map((step) => Padding(
              padding: const EdgeInsets.only(bottom: SpacingTokens.xs),
              child: Row(
                children: [
                  Icon(
                    Icons.check,
                    size: 16,
                    color: colors.success,
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  Text(
                    step,
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
    );
  }
  
  Color _getConfidenceColor(ThemeColors colors) {
    if (_confidence >= 0.85) return colors.success;
    if (_confidence >= 0.65) return colors.warning;
    return colors.error;
  }
}