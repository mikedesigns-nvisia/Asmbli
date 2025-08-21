import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';

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
            color: SemanticColors.surface.withOpacity(0.8),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: SemanticColors.primary,
                    strokeWidth: 2,
                  ),
                  if (loadingText != null) ...[
                    const SizedBox(height: SpacingTokens.lg),
                    Text(
                      loadingText!,
                      style: TextStyles.bodyMedium.copyWith(
                        color: SemanticColors.onSurface,
                      ),
                    ),
                  ],
                ],
              ),
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
      margin: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: SemanticColors.primary,
            child: const Icon(
              Icons.smart_toy,
              size: 20,
              color: SemanticColors.surface,
            ),
          ),
          const SizedBox(width: SpacingTokens.md),
          Container(
            padding: const EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              color: SemanticColors.surface,
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
              border: Border.all(
                color: SemanticColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: SemanticColors.primary,
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: SpacingTokens.sm),
                Text(
                  'AI is typing...',
                  style: TextStyles.bodySmall.copyWith(
                    color: SemanticColors.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
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
                color: SemanticColors.error,
                size: 20,
              ),
              const SizedBox(width: SpacingTokens.sm),
              Text(
                'Error',
                style: TextStyles.cardTitle.copyWith(
                  color: SemanticColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            message,
            style: TextStyles.bodyMedium.copyWith(
              color: SemanticColors.onSurface,
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