import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/design_system/design_system.dart';
import '../models/demo_models.dart';
import 'enhanced_ai_reasoning_simulator.dart';

/// Different visualization modes for reasoning display
enum VisualizationMode { 
  linear,     // Default linear progress
  circular,   // Circular progress with nodes
  tree,       // Hierarchical tree view
  timeline,   // Timeline with milestones
  network,    // Network graph of reasoning
}

/// Visualization factory for different reasoning display modes
class ReasoningVisualizationFactory {
  static Widget create({
    required VisualizationMode mode,
    required ReasoningUpdate? update,
    required List<CompletedStep> completedSteps,
    required ThemeColors colors,
    VoidCallback? onModeChange,
  }) {
    switch (mode) {
      case VisualizationMode.circular:
        return CircularReasoningView(
          update: update,
          completedSteps: completedSteps,
          colors: colors,
        );
      case VisualizationMode.tree:
        return TreeReasoningView(
          update: update,
          completedSteps: completedSteps,
          colors: colors,
        );
      case VisualizationMode.timeline:
        return TimelineReasoningView(
          update: update,
          completedSteps: completedSteps,
          colors: colors,
        );
      case VisualizationMode.network:
        return NetworkReasoningView(
          update: update,
          completedSteps: completedSteps,
          colors: colors,
        );
      default:
        return LinearReasoningView(
          update: update,
          completedSteps: completedSteps,
          colors: colors,
        );
    }
  }
}

/// Circular progress visualization with confidence rings
class CircularReasoningView extends StatefulWidget {
  final ReasoningUpdate? update;
  final List<CompletedStep> completedSteps;
  final ThemeColors colors;

  const CircularReasoningView({
    super.key,
    this.update,
    required this.completedSteps,
    required this.colors,
  });

  @override
  State<CircularReasoningView> createState() => _CircularReasoningViewState();
}

class _CircularReasoningViewState extends State<CircularReasoningView>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _rotationController;
  
  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(SpacingTokens.xl),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating background
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) => Transform.rotate(
              angle: _rotationController.value * 2 * math.pi,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.colors.border.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          
          // Confidence rings
          CustomPaint(
            size: const Size(200, 200),
            painter: ConfidenceRingsPainter(
              progress: widget.update?.progress ?? 0,
              confidence: widget.update?.confidence ?? 0.8,
              colors: widget.colors,
            ),
          ),
          
          // Center content
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: widget.colors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: widget.colors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.psychology,
                  color: widget.colors.primary,
                  size: 32,
                ),
                const SizedBox(height: SpacingTokens.xs),
                Text(
                  '${((widget.update?.confidence ?? 0.8) * 100).toStringAsFixed(0)}%',
                  style: TextStyles.sectionTitle.copyWith(
                    color: widget.colors.onSurface,
                  ),
                ),
                Text(
                  'Confidence',
                  style: TextStyles.bodySmall.copyWith(
                    color: widget.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          // Step indicators around the circle
          ...List.generate(5, (index) {
            final angle = (index * 2 * math.pi / 5) - (math.pi / 2);
            final isCompleted = index < widget.completedSteps.length;
            final isCurrent = index == widget.completedSteps.length;
            
            return Positioned(
              left: 150 + 100 * math.cos(angle) - 12,
              top: 150 + 100 * math.sin(angle) - 12,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted 
                    ? widget.colors.success
                    : isCurrent 
                      ? widget.colors.primary
                      : widget.colors.border,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted ? Icons.check : Icons.circle,
                  size: 12,
                  color: widget.colors.surface,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Timeline visualization with milestones
class TimelineReasoningView extends StatelessWidget {
  final ReasoningUpdate? update;
  final List<CompletedStep> completedSteps;
  final ThemeColors colors;

  const TimelineReasoningView({
    super.key,
    this.update,
    required this.completedSteps,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        children: [
          // Timeline header
          Row(
            children: [
              Icon(Icons.timeline, color: colors.primary),
              const SizedBox(width: SpacingTokens.sm),
              Text(
                'Reasoning Timeline',
                style: TextStyles.bodyLarge.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: SpacingTokens.lg),
          
          // Timeline
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: completedSteps.length + 1,
              itemBuilder: (context, index) {
                final isCompleted = index < completedSteps.length;
                final isCurrent = index == completedSteps.length;
                
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: SpacingTokens.md),
                  child: Column(
                    children: [
                      // Timeline node
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isCompleted 
                            ? colors.success
                            : isCurrent 
                              ? colors.primary
                              : colors.border,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCompleted 
                            ? Icons.check 
                            : isCurrent 
                              ? Icons.play_arrow 
                              : Icons.circle_outlined,
                          color: colors.surface,
                        ),
                      ),
                      
                      // Connecting line
                      if (index < completedSteps.length)
                        Container(
                          height: 2,
                          width: 80,
                          color: colors.success,
                          margin: const EdgeInsets.symmetric(
                            vertical: SpacingTokens.sm,
                          ),
                        ),
                      
                      // Step details
                      if (isCompleted)
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                completedSteps[index].step.description,
                                style: TextStyles.bodySmall.copyWith(
                                  color: colors.onSurface,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: SpacingTokens.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: SpacingTokens.sm,
                                  vertical: SpacingTokens.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                                ),
                                child: Text(
                                  '${(completedSteps[index].confidence * 100).toStringAsFixed(0)}%',
                                  style: TextStyles.bodySmall.copyWith(
                                    color: colors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
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
}

/// Tree structure visualization
class TreeReasoningView extends StatelessWidget {
  final ReasoningUpdate? update;
  final List<CompletedStep> completedSteps;
  final ThemeColors colors;

  const TreeReasoningView({
    super.key,
    this.update,
    required this.completedSteps,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: update?.tree != null 
        ? _buildTreeVisualization(update!.tree!, colors)
        : Center(
            child: Text(
              'Tree visualization available during analysis',
              style: TextStyles.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
    );
  }

  Widget _buildTreeVisualization(ConfidenceTree tree, ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reasoning Tree',
          style: TextStyles.bodyLarge.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingTokens.md),
        Expanded(
          child: SingleChildScrollView(
            child: _buildTreeNode(tree.root, colors, 0),
          ),
        ),
      ],
    );
  }

  Widget _buildTreeNode(ConfidenceNode node, ThemeColors colors, int depth) {
    return Container(
      margin: EdgeInsets.only(
        left: depth * SpacingTokens.xl,
        bottom: SpacingTokens.sm,
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
                  shape: BoxShape.circle,
                  color: _getConfidenceColor(node.confidence, colors),
                ),
              ),
              const SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: Text(
                  node.reasoning,
                  style: TextStyles.bodyMedium.copyWith(
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
                  color: _getConfidenceColor(node.confidence, colors).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                ),
                child: Text(
                  '${(node.confidence * 100).toStringAsFixed(0)}%',
                  style: TextStyles.bodySmall.copyWith(
                    color: _getConfidenceColor(node.confidence, colors),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          ...node.children.map((child) => _buildTreeNode(child, colors, depth + 1)),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence, ThemeColors colors) {
    if (confidence >= 0.85) return colors.success;
    if (confidence >= 0.65) return colors.warning;
    return colors.error;
  }
}

/// Network graph visualization (simplified)
class NetworkReasoningView extends StatelessWidget {
  final ReasoningUpdate? update;
  final List<CompletedStep> completedSteps;
  final ThemeColors colors;

  const NetworkReasoningView({
    super.key,
    this.update,
    required this.completedSteps,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: CustomPaint(
        size: const Size(double.infinity, 200),
        painter: NetworkReasoningPainter(
          steps: completedSteps,
          colors: colors,
        ),
      ),
    );
  }
}

/// Linear progress (default) visualization
class LinearReasoningView extends StatelessWidget {
  final ReasoningUpdate? update;
  final List<CompletedStep> completedSteps;
  final ThemeColors colors;

  const LinearReasoningView({
    super.key,
    this.update,
    required this.completedSteps,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            child: LinearProgressIndicator(
              value: update?.progress ?? 0,
              minHeight: 6,
              backgroundColor: colors.border,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
          
          const SizedBox(height: SpacingTokens.lg),
          
          // Current step
          if (update != null)
            Container(
              padding: const EdgeInsets.all(SpacingTokens.md),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              ),
              child: Text(
                update!.step.description,
                style: TextStyles.bodyMedium.copyWith(
                  color: colors.onSurface,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Custom painters

class ConfidenceRingsPainter extends CustomPainter {
  final double progress;
  final double confidence;
  final ThemeColors colors;

  ConfidenceRingsPainter({
    required this.progress,
    required this.confidence,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    
    // Confidence ring
    final confidencePaint = Paint()
      ..color = _getConfidenceColor()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    
    canvas.drawCircle(center, radius * confidence, confidencePaint);
    
    // Progress arc
    final progressPaint = Paint()
      ..color = colors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 20),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  Color _getConfidenceColor() {
    if (confidence >= 0.85) return colors.success;
    if (confidence >= 0.65) return colors.warning;
    return colors.error;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class NetworkReasoningPainter extends CustomPainter {
  final List<CompletedStep> steps;
  final ThemeColors colors;

  NetworkReasoningPainter({
    required this.steps,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (steps.isEmpty) return;
    
    final paint = Paint()
      ..color = colors.border
      ..strokeWidth = 2;
    
    final nodePaint = Paint()
      ..color = colors.primary
      ..style = PaintingStyle.fill;
    
    // Draw simple network with nodes and connections
    for (int i = 0; i < math.min(steps.length, 5); i++) {
      final x = (i + 1) * (size.width / 6);
      final y = size.height / 2 + math.sin(i) * 30;
      
      // Draw node
      canvas.drawCircle(Offset(x, y), 8, nodePaint);
      
      // Draw connection to next node
      if (i < steps.length - 1 && i < 4) {
        final nextX = ((i + 1) + 1) * (size.width / 6);
        final nextY = size.height / 2 + math.sin(i + 1) * 30;
        canvas.drawLine(
          Offset(x + 8, y),
          Offset(nextX - 8, nextY),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}