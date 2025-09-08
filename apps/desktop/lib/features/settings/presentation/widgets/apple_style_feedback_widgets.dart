import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/design_system/design_system.dart';

/// Apple-style haptic feedback and visual animations
class AppleStyleFeedback {
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }
  
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }
  
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }
  
  static void selectionClick() {
    HapticFeedback.selectionClick();
  }
}

/// Apple-style animated button with haptic feedback
class AppleStyleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? pressedColor;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final bool hapticEnabled;

  const AppleStyleButton({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.pressedColor,
    this.borderRadius,
    this.padding,
    this.hapticEnabled = true,
  });

  @override
  State<AppleStyleButton> createState() => _AppleStyleButtonState();
}

class _AppleStyleButtonState extends State<AppleStyleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = true);
      _controller.forward();
      if (widget.hapticEnabled) {
        AppleStyleFeedback.lightImpact();
      }
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _handleTapEnd();
  }

  void _handleTapCancel() {
    _handleTapEnd();
  }

  void _handleTapEnd() {
    if (mounted) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: widget.padding ?? EdgeInsets.symmetric(
                horizontal: SpacingTokens.lg,
                vertical: SpacingTokens.md,
              ),
              decoration: BoxDecoration(
                color: _isPressed 
                    ? (widget.pressedColor ?? colors.primary.withOpacity(0.8))
                    : (widget.backgroundColor ?? colors.primary),
                borderRadius: widget.borderRadius ?? BorderRadius.circular(BorderRadiusTokens.lg),
                boxShadow: _isPressed ? [] : [
                  BoxShadow(
                    color: colors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// Apple-style loading indicator with smooth animations
class AppleStyleLoadingIndicator extends StatefulWidget {
  final Color? color;
  final double size;

  const AppleStyleLoadingIndicator({
    super.key,
    this.color,
    this.size = 24,
  });

  @override
  State<AppleStyleLoadingIndicator> createState() => _AppleStyleLoadingIndicatorState();
}

class _AppleStyleLoadingIndicatorState extends State<AppleStyleLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _LoadingPainter(
              color: widget.color ?? colors.primary,
              progress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _LoadingPainter extends CustomPainter {
  final Color color;
  final double progress;

  _LoadingPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Draw the animated arc
    const startAngle = -1.57; // -90 degrees
    final sweepAngle = 2 * 3.14159 * progress; // Full circle over animation

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_LoadingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// Apple-style success animation
class AppleStyleSuccessAnimation extends StatefulWidget {
  final VoidCallback? onComplete;
  final Color? color;
  final double size;

  const AppleStyleSuccessAnimation({
    super.key,
    this.onComplete,
    this.color,
    this.size = 64,
  });

  @override
  State<AppleStyleSuccessAnimation> createState() => _AppleStyleSuccessAnimationState();
}

class _AppleStyleSuccessAnimationState extends State<AppleStyleSuccessAnimation>
    with TickerProviderStateMixin {
  late AnimationController _circleController;
  late AnimationController _checkController;
  late Animation<double> _circleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    
    _circleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _circleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _circleController,
      curve: Curves.easeInOut,
    ));
    
    _checkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeInOut,
    ));
    
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await _circleController.forward();
    await _checkController.forward();
    if (widget.onComplete != null) {
      widget.onComplete!();
    }
  }

  @override
  void dispose() {
    _circleController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_circleController, _checkController]),
        builder: (context, child) {
          return CustomPaint(
            painter: _SuccessPainter(
              circleProgress: _circleAnimation.value,
              checkProgress: _checkAnimation.value,
              color: widget.color ?? Colors.green,
            ),
          );
        },
      ),
    );
  }
}

class _SuccessPainter extends CustomPainter {
  final double circleProgress;
  final double checkProgress;
  final Color color;

  _SuccessPainter({
    required this.circleProgress,
    required this.checkProgress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Draw circle
    if (circleProgress > 0) {
      final circlePaint = Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * 3.14159 * circleProgress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -1.57, // Start from top
        sweepAngle,
        false,
        circlePaint,
      );
    }

    // Draw checkmark
    if (checkProgress > 0 && circleProgress >= 1.0) {
      final checkPaint = Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final checkPath = Path();
      final checkSize = size.width * 0.3;
      final checkLeft = center.dx - checkSize * 0.5;
      final checkTop = center.dy - checkSize * 0.2;

      checkPath.moveTo(checkLeft, checkTop);
      checkPath.lineTo(checkLeft + checkSize * 0.4, checkTop + checkSize * 0.4);
      checkPath.lineTo(checkLeft + checkSize, checkTop - checkSize * 0.2);

      final pathMetrics = checkPath.computeMetrics();
      for (final pathMetric in pathMetrics) {
        final extractedPath = pathMetric.extractPath(
          0,
          pathMetric.length * checkProgress,
        );
        canvas.drawPath(extractedPath, checkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_SuccessPainter oldDelegate) {
    return oldDelegate.circleProgress != circleProgress ||
           oldDelegate.checkProgress != checkProgress ||
           oldDelegate.color != color;
  }
}

/// Apple-style slide transition
class AppleStyleSlideTransition extends StatefulWidget {
  final Widget child;
  final bool show;
  final Duration duration;
  final Offset beginOffset;

  const AppleStyleSlideTransition({
    super.key,
    required this.child,
    required this.show,
    this.duration = const Duration(milliseconds: 300),
    this.beginOffset = const Offset(0, 1),
  });

  @override
  State<AppleStyleSlideTransition> createState() => _AppleStyleSlideTransitionState();
}

class _AppleStyleSlideTransitionState extends State<AppleStyleSlideTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    if (widget.show) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AppleStyleSlideTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show != oldWidget.show) {
      if (widget.show) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
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
      animation: _controller,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Apple-style spring animation for cards
class AppleStyleCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final bool enableSpringAnimation;

  const AppleStyleCard({
    super.key,
    required this.child,
    this.onTap,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.margin,
    this.enableSpringAnimation = true,
  });

  @override
  State<AppleStyleCard> createState() => _AppleStyleCardState();
}

class _AppleStyleCardState extends State<AppleStyleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null && widget.enableSpringAnimation) {
      setState(() => _isPressed = true);
      _controller.forward();
      AppleStyleFeedback.selectionClick();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _handleTapEnd();
  }

  void _handleTapCancel() {
    _handleTapEnd();
  }

  void _handleTapEnd() {
    if (mounted && widget.enableSpringAnimation) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return Container(
      margin: widget.margin,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.enableSpringAnimation ? _scaleAnimation.value : 1.0,
              child: Container(
                padding: widget.padding ?? EdgeInsets.all(SpacingTokens.lg),
                decoration: BoxDecoration(
                  color: widget.backgroundColor ?? colors.surface.withOpacity(0.6),
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(BorderRadiusTokens.lg),
                  border: Border.all(
                    color: colors.border.withOpacity(0.3),
                    width: 0.5,
                  ),
                  boxShadow: _isPressed ? [] : [
                    BoxShadow(
                      color: colors.onSurface.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: widget.child,
              ),
            );
          },
        ),
      ),
    );
  }
}