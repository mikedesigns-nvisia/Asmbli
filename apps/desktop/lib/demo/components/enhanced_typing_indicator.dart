import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';

/// Modern typing indicator with agent-specific animations
class EnhancedTypingIndicator extends StatefulWidget {
  final String agentName;
  final Color agentColor;
  final IconData agentIcon;
  final String? currentThought;
  final double? confidence;
  final bool showProgress;

  const EnhancedTypingIndicator({
    super.key,
    required this.agentName,
    required this.agentColor,
    required this.agentIcon,
    this.currentThought,
    this.confidence,
    this.showProgress = false,
  });

  @override
  State<EnhancedTypingIndicator> createState() => _EnhancedTypingIndicatorState();
}

class _EnhancedTypingIndicatorState extends State<EnhancedTypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _dotsController;
  late AnimationController _breatheController;
  late AnimationController _progressController;
  late Animation<double> _breatheAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _breatheController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _breatheAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _breatheController,
      curve: Curves.easeInOut,
    ));
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    
    _dotsController.repeat();
    _breatheController.repeat(reverse: true);
    
    if (widget.showProgress) {
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _dotsController.dispose();
    _breatheController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return AnimatedBuilder(
      animation: Listenable.merge([_breatheAnimation, _progressAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _breatheAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.agentColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.agentColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // Animated agent icon
                    AnimatedBuilder(
                      animation: _breatheController,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: widget.agentColor.withOpacity(0.1 + (_breatheAnimation.value - 0.8) * 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.agentIcon,
                            color: widget.agentColor,
                            size: 16,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    
                    // Agent name and status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.agentName,
                            style: TextStyles.bodySmall.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              _buildTypingDots(),
                              const SizedBox(width: 8),
                              if (widget.confidence != null)
                                Text(
                                  '${(widget.confidence! * 100).toInt()}% confident',
                                  style: TextStyles.bodySmall.copyWith(
                                    color: widget.agentColor,
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Pulse indicator
                    AnimatedBuilder(
                      animation: _breatheController,
                      builder: (context, child) {
                        return Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: widget.agentColor.withOpacity(_breatheAnimation.value),
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                // Current thought bubble
                if (widget.currentThought != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.surface.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.agentColor.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.psychology_outlined,
                          color: widget.agentColor,
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.currentThought!,
                            style: TextStyles.bodySmall.copyWith(
                              color: colors.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Progress bar for long operations
                if (widget.showProgress) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: widget.agentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progressAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.agentColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypingDots() {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animationValue = (_dotsController.value - delay).clamp(0.0, 1.0);
            final opacity = (1.0 - (animationValue - 0.5).abs() * 2).clamp(0.3, 1.0);
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: widget.agentColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Real-time status indicator for active agents
class AgentStatusIndicator extends StatefulWidget {
  final String agentId;
  final String agentName;
  final Color agentColor;
  final IconData agentIcon;
  final AgentActivityStatus status;
  final String? currentTask;
  final double? progress;

  const AgentStatusIndicator({
    super.key,
    required this.agentId,
    required this.agentName,
    required this.agentColor,
    required this.agentIcon,
    required this.status,
    this.currentTask,
    this.progress,
  });

  @override
  State<AgentStatusIndicator> createState() => _AgentStatusIndicatorState();
}

class _AgentStatusIndicatorState extends State<AgentStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.status == AgentActivityStatus.thinking ||
        widget.status == AgentActivityStatus.working) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AgentStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.status != oldWidget.status) {
      if (widget.status == AgentActivityStatus.thinking ||
          widget.status == AgentActivityStatus.working) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getStatusColor(ThemeColors colors) {
    switch (widget.status) {
      case AgentActivityStatus.idle:
        return colors.onSurfaceVariant;
      case AgentActivityStatus.thinking:
        return colors.warning;
      case AgentActivityStatus.working:
        return widget.agentColor;
      case AgentActivityStatus.completed:
        return colors.success;
      case AgentActivityStatus.error:
        return colors.error;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.status) {
      case AgentActivityStatus.idle:
        return Icons.circle_outlined;
      case AgentActivityStatus.thinking:
        return Icons.psychology_outlined;
      case AgentActivityStatus.working:
        return widget.agentIcon;
      case AgentActivityStatus.completed:
        return Icons.check_circle_outline;
      case AgentActivityStatus.error:
        return Icons.error_outline;
    }
  }

  String _getStatusText() {
    switch (widget.status) {
      case AgentActivityStatus.idle:
        return 'Ready';
      case AgentActivityStatus.thinking:
        return 'Thinking...';
      case AgentActivityStatus.working:
        return widget.currentTask ?? 'Working...';
      case AgentActivityStatus.completed:
        return 'Completed';
      case AgentActivityStatus.error:
        return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final statusColor = _getStatusColor(colors);
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: statusColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: widget.status == AgentActivityStatus.thinking ||
                        widget.status == AgentActivityStatus.working
                    ? _pulseAnimation.value
                    : 1.0,
                child: Icon(
                  _getStatusIcon(),
                  color: statusColor,
                  size: 14,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _getStatusText(),
                style: TextStyles.bodySmall.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
              if (widget.progress != null) ...[
                const SizedBox(width: 6),
                SizedBox(
                  width: 40,
                  height: 2,
                  child: LinearProgressIndicator(
                    value: widget.progress,
                    backgroundColor: statusColor.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation(statusColor),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

enum AgentActivityStatus {
  idle,
  thinking,
  working,
  completed,
  error,
}