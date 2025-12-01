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
            color: ThemeColors(context).surface.withValues(alpha: 0.95),
            child: const Center(
              child: ThinkingBubbleWidget(),
            ),
          ),
      ],
    );
  }
}

class MessageLoadingIndicator extends StatelessWidget {
  const MessageLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Claude avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: ThemeColors(context).primary,
            child: const Icon(
              Icons.psychology_outlined,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: SpacingTokens.md),
          // Beautiful thinking animation
          const Expanded(
            child: ThinkingBubbleWidget(),
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