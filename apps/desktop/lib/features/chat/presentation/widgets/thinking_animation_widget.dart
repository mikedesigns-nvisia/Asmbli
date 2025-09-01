import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';

class ThinkingAnimationWidget extends StatefulWidget {
  const ThinkingAnimationWidget({super.key});

  @override
  State<ThinkingAnimationWidget> createState() => _ThinkingAnimationWidgetState();
}

class _ThinkingAnimationWidgetState extends State<ThinkingAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _dotsController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Dots animation (pulsing dots)
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Fade in animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    // Start animations
    _dotsController.repeat();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _dotsController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.only(left: 0, right: 48, top: 8, bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Claude logo or icon
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: ThemeColors(context).primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.psychology_outlined,
                size: 14,
                color: ThemeColors(context).primary,
              ),
            ),
            const SizedBox(width: 12),
            
            // Thinking text with animated dots
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Thinking',
                  style: TextStyle(
                    
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 2),
                AnimatedBuilder(
                  animation: _dotsController,
                  builder: (context, child) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (index) {
                        // Calculate staggered animation for each dot
                        double delay = index * 0.2;
                        double animationValue = (_dotsController.value + delay) % 1.0;
                        
                        // Create a pulsing effect
                        double opacity = 0.3;
                        if (animationValue > 0.0 && animationValue < 0.5) {
                          opacity = 0.3 + (animationValue * 2 * 0.7); // Fade in
                        } else if (animationValue >= 0.5 && animationValue < 1.0) {
                          opacity = 1.0 - ((animationValue - 0.5) * 2 * 0.7); // Fade out
                        }
                        
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          child: Text(
                            '•',
                            style: TextStyle(
                              
                              fontSize: 14,
                              color: ThemeColors(context).primary.withValues(alpha: opacity),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ThinkingBubbleWidget extends StatefulWidget {
  const ThinkingBubbleWidget({super.key});

  @override
  State<ThinkingBubbleWidget> createState() => _ThinkingBubbleWidgetState();
}

class _ThinkingBubbleWidgetState extends State<ThinkingBubbleWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Slide in animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animations
    _pulseController.repeat(reverse: true);
    _slideController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SlideTransition(
      position: _slideAnimation,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(left: 0, right: 48, top: 8, bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ThemeColors(context).surface.withValues(alpha: 0.9),
                    ThemeColors(context).surface.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ThemeColors(context).primary.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ThemeColors(context).primary.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated thinking icon
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1000),
                    builder: (context, value, child) {
                      return Transform.rotate(
                        angle: value * 0.1, // Subtle rotation
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                ThemeColors(context).primary,
                                ThemeColors(context).primary.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: ThemeColors(context).primary.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.psychology_outlined,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  
                  // Enhanced thinking text with dots
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Claude is thinking',
                            style: TextStyle(
                              
                              fontSize: 15,
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(3, (index) {
                                  double stagger = index * 0.3;
                                  double animationValue = (_pulseController.value + stagger) % 1.0;
                                  
                                  double scale = 0.8;
                                  double opacity = 0.4;
                                  
                                  if (animationValue > 0.0 && animationValue < 0.5) {
                                    scale = 0.8 + (animationValue * 2 * 0.4);
                                    opacity = 0.4 + (animationValue * 2 * 0.6);
                                  } else if (animationValue >= 0.5) {
                                    scale = 1.2 - ((animationValue - 0.5) * 2 * 0.4);
                                    opacity = 1.0 - ((animationValue - 0.5) * 2 * 0.6);
                                  }
                                  
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                    child: Transform.scale(
                                      scale: scale,
                                      child: Text(
                                        '•',
                                        style: TextStyle(
                                          
                                          fontSize: 16,
                                          color: ThemeColors(context).primary.withValues(alpha: opacity),
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Processing your request',
                        style: TextStyle(
                          
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}