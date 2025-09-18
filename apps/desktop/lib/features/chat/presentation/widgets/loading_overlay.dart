import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';
import 'thinking_animation_widget.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? loadingText;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.loadingText,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: ThemeColors(context).surface.withOpacity( 0.95),
            child: const Center(
              child: ThinkingBubbleWidget(),
            ),
          ),
      ],
    );
  }
}

class MessageLoadingIndicator extends StatefulWidget {
  const MessageLoadingIndicator({super.key});

  @override
  State<MessageLoadingIndicator> createState() => _MessageLoadingIndicatorState();
}

class _MessageLoadingIndicatorState extends State<MessageLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.lg, vertical: SpacingTokens.md),
      child: Row(
        children: [
          // Assistant avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: colors.primary.withOpacity(0.1),
            child: Icon(
              Icons.psychology_outlined,
              size: 18,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: SpacingTokens.md),
          // Pulsing circle indicator
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primary.withOpacity(0.8),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ErrorMessage extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorMessage({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AsmblCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: ThemeColors(context).error,
                size: 20,
              ),
              const SizedBox(width: SpacingTokens.sm),
              Text(
                'Error',
                style: TextStyles.cardTitle.copyWith(
                  color: ThemeColors(context).error,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            message,
            style: TextStyles.bodyMedium.copyWith(
              color: ThemeColors(context).onSurface,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: SpacingTokens.lg),
            AsmblButton.secondary(
              text: 'Retry',
              icon: Icons.refresh,
              onPressed: onRetry!,
            ),
          ],
        ],
      ),
    );
  }
}