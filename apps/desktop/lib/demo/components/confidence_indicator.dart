import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/design_system/design_system.dart';

/// Unified confidence indicator for demo scenarios
class ConfidenceIndicator extends StatelessWidget {
  final double confidence;
  final bool showLabel;
  final bool inline;
  final VoidCallback? onTap;

  const ConfidenceIndicator({
    super.key,
    required this.confidence,
    this.showLabel = true,
    this.inline = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    if (inline) {
      return _buildInlineIndicator(colors);
    }
    
    return _buildFullIndicator(colors);
  }

  Widget _buildInlineIndicator(ThemeColors colors) {
    final color = _getConfidenceColor(colors);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.sm,
          vertical: SpacingTokens.xs,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCircularIndicator(colors, size: 16),
            if (showLabel) ...[
              const SizedBox(width: SpacingTokens.xs),
              Text(
                '${(confidence * 100).toStringAsFixed(0)}%',
                style: TextStyles.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFullIndicator(ThemeColors colors) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCircularIndicator(colors),
            if (showLabel) ...[
              const SizedBox(height: SpacingTokens.sm),
              Text(
                'Confidence',
                style: TextStyles.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              Text(
                '${(confidence * 100).toStringAsFixed(0)}%',
                style: TextStyles.sectionTitle.copyWith(
                  color: _getConfidenceColor(colors),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCircularIndicator(ThemeColors colors, {double size = 48}) {
    final color = _getConfidenceColor(colors);
    
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Background circle
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.border,
                width: 2,
              ),
            ),
          ),
          // Progress arc
          CustomPaint(
            size: Size(size, size),
            painter: _ConfidenceArcPainter(
              progress: confidence,
              color: color,
              strokeWidth: 2,
            ),
          ),
          // Center icon
          Center(
            child: Icon(
              _getConfidenceIcon(),
              size: size * 0.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getConfidenceIcon() {
    if (confidence >= 0.85) return Icons.check_circle_outline;
    if (confidence >= 0.65) return Icons.info_outline;
    return Icons.warning_amber_outlined;
  }

  Color _getConfidenceColor(ThemeColors colors) {
    if (confidence >= 0.85) return colors.success;
    if (confidence >= 0.65) return colors.warning;
    return colors.error;
  }
}

class _ConfidenceArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _ConfidenceArcPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Extension for animated confidence changes
class AnimatedConfidenceIndicator extends StatefulWidget {
  final double confidence;
  final bool showLabel;
  final bool inline;
  final VoidCallback? onTap;

  const AnimatedConfidenceIndicator({
    super.key,
    required this.confidence,
    this.showLabel = true,
    this.inline = false,
    this.onTap,
  });

  @override
  State<AnimatedConfidenceIndicator> createState() => _AnimatedConfidenceIndicatorState();
}

class _AnimatedConfidenceIndicatorState extends State<AnimatedConfidenceIndicator> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousConfidence = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _previousConfidence = widget.confidence;
    _animation = Tween<double>(
      begin: _previousConfidence,
      end: widget.confidence,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(AnimatedConfidenceIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.confidence != widget.confidence) {
      _previousConfidence = _animation.value;
      _animation = Tween<double>(
        begin: _previousConfidence,
        end: widget.confidence,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => ConfidenceIndicator(
        confidence: _animation.value,
        showLabel: widget.showLabel,
        inline: widget.inline,
        onTap: widget.onTap,
      ),
    );
  }
}