import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/design_system/design_system.dart';

/// Visual celebration screen shown when demo completes successfully
class DemoCompletionCelebration extends StatefulWidget {
  final String agentName;
  final IconData agentIcon;
  final Color agentColor;
  final List<CompletionMetric> metrics;
  final VoidCallback? onRestart;
  final VoidCallback? onExploreMore;

  const DemoCompletionCelebration({
    super.key,
    required this.agentName,
    required this.agentIcon,
    required this.agentColor,
    required this.metrics,
    this.onRestart,
    this.onExploreMore,
  });

  @override
  State<DemoCompletionCelebration> createState() => _DemoCompletionCelebrationState();
}

class _DemoCompletionCelebrationState extends State<DemoCompletionCelebration>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _particleController;
  late AnimationController _staggerController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _particleAnimation;
  
  final List<Animation<double>> _metricAnimations = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _staggerController = AnimationController(
      duration: Duration(milliseconds: 300 * widget.metrics.length),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    
    _rotationAnimation = CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    );
    
    _particleAnimation = CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeOut,
    );

    // Create staggered animations for metrics
    for (int i = 0; i < widget.metrics.length; i++) {
      final startTime = i * 0.2;
      final endTime = startTime + 0.4;
      _metricAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _staggerController,
            curve: Interval(
              startTime / widget.metrics.length,
              endTime / widget.metrics.length > 1.0 ? 1.0 : endTime / widget.metrics.length,
              curve: Curves.easeOutCubic,
            ),
          ),
        ),
      );
    }
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _scaleController.forward();
    _rotationController.repeat();
    await Future.delayed(const Duration(milliseconds: 400));
    _particleController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    _staggerController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    _particleController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              widget.agentColor.withOpacity(0.05),
              colors.background,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated particles
            ..._buildParticles(),
            
            // Main content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(SpacingTokens.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success icon with animation
                    _buildSuccessIcon(colors),
                    
                    const SizedBox(height: SpacingTokens.xxl),
                    
                    // Success message
                    _buildSuccessMessage(colors),
                    
                    const SizedBox(height: SpacingTokens.xl * 2),
                    
                    // Metrics cards
                    _buildMetricsSection(colors),
                    
                    const SizedBox(height: SpacingTokens.xl * 2),
                    
                    // Action buttons
                    _buildActionButtons(colors),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessIcon(ThemeColors colors) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.agentColor,
              widget.agentColor.withOpacity(0.7),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: widget.agentColor.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Rotating background
            AnimatedBuilder(
              animation: _rotationAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationAnimation.value * 2 * math.pi,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            ),
            
            // Check icon
            Icon(
              Icons.check_rounded,
              size: 60,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessMessage(ThemeColors colors) {
    return Column(
      children: [
        Text(
          'Mission Accomplished!',
          style: TextStyles.pageTitle.copyWith(
            color: colors.onSurface,
            fontSize: 36,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: SpacingTokens.md),
        Text(
          'Your ${widget.agentName} has successfully completed all tasks',
          style: TextStyles.bodyLarge.copyWith(
            color: colors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMetricsSection(ThemeColors colors) {
    return Wrap(
      spacing: SpacingTokens.lg,
      runSpacing: SpacingTokens.lg,
      alignment: WrapAlignment.center,
      children: widget.metrics.asMap().entries.map((entry) {
        final index = entry.key;
        final metric = entry.value;
        
        return AnimatedBuilder(
          animation: _metricAnimations[index],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - _metricAnimations[index].value)),
              child: Opacity(
                opacity: _metricAnimations[index].value,
                child: _buildMetricCard(metric, colors),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildMetricCard(CompletionMetric metric, ThemeColors colors) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
        border: Border.all(
          color: metric.isHighlight ? widget.agentColor : colors.border,
          width: metric.isHighlight ? 2 : 1,
        ),
        boxShadow: [
          if (metric.isHighlight)
            BoxShadow(
              color: widget.agentColor.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            metric.icon,
            color: metric.isHighlight ? widget.agentColor : colors.onSurfaceVariant,
            size: 32,
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            metric.value,
            style: TextStyles.sectionTitle.copyWith(
              color: colors.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            metric.label,
            style: TextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.onRestart != null) ...[
          AsmblButton.secondary(
            text: 'Run Again',
            icon: Icons.refresh,
            onPressed: widget.onRestart,
          ),
          const SizedBox(width: SpacingTokens.md),
        ],
        if (widget.onExploreMore != null)
          AsmblButton.primary(
            text: 'Explore More',
            icon: Icons.arrow_forward,
            onPressed: widget.onExploreMore,
          ),
      ],
    );
  }

  List<Widget> _buildParticles() {
    return List.generate(20, (index) {
      final random = math.Random(index);
      final startX = random.nextDouble() * 2 - 1;
      final startY = random.nextDouble() * 2 - 1;
      final endX = startX + (random.nextDouble() - 0.5);
      final endY = startY - random.nextDouble();
      
      return AnimatedBuilder(
        animation: _particleAnimation,
        builder: (context, child) {
          return Positioned.fill(
            child: Align(
              alignment: Alignment(
                startX + (endX - startX) * _particleAnimation.value,
                startY + (endY - startY) * _particleAnimation.value,
              ),
              child: Opacity(
                opacity: (1 - _particleAnimation.value) * 0.7,
                child: Container(
                  width: 8 + random.nextDouble() * 8,
                  height: 8 + random.nextDouble() * 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.agentColor.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

class CompletionMetric {
  final String label;
  final String value;
  final IconData icon;
  final bool isHighlight;

  const CompletionMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.isHighlight = false,
  });
}