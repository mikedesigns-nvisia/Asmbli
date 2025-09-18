import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design_system.dart';
import '../../models/mcp_capability.dart';
import '../../services/mcp_user_interface_service.dart';

/// ✨ Magical Progress Widget - Makes Installation Feel Like Magic
///
/// This widget turns boring technical progress into delightful moments:
/// - Animated progress with personality
/// - Encouraging messages that build excitement
/// - Beautiful success celebrations
/// - Friendly error recovery
class MagicalProgressWidget extends ConsumerStatefulWidget {
  final MCPProgressState progress;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;

  const MagicalProgressWidget({
    super.key,
    required this.progress,
    this.onDismiss,
    this.onRetry,
  });

  @override
  ConsumerState<MagicalProgressWidget> createState() => _MagicalProgressWidgetState();
}

class _MagicalProgressWidgetState extends ConsumerState<MagicalProgressWidget>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _celebrationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );

    _colorAnimation = ColorTween(
      begin: Colors.blue,
      end: Colors.green,
    ).animate(_progressController);

    _startAnimations();
  }

  void _startAnimations() {
    switch (widget.progress.status) {
      case MCPProgressStatus.inProgress:
        _progressController.repeat(reverse: true);
        break;
      case MCPProgressStatus.completed:
        _progressController.forward();
        _celebrationController.forward();
        break;
      case MCPProgressStatus.failed:
        _progressController.stop();
        break;
      case MCPProgressStatus.partialSuccess:
        _progressController.forward();
        break;
    }
  }

  @override
  void didUpdateWidget(MagicalProgressWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.progress.status != widget.progress.status) {
      _startAnimations();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return AnimatedBuilder(
      animation: Listenable.merge([_progressController, _celebrationController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: AsmblCard(
            child: Container(
              decoration: _getCardDecoration(colors),
              child: Padding(
                padding: const EdgeInsets.all(SpacingTokens.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMagicalHeader(colors),
                    const SizedBox(height: SpacingTokens.md),
                    _buildProgressContent(colors),
                    if (_shouldShowActions()) ...[
                      const SizedBox(height: SpacingTokens.lg),
                      _buildActions(colors),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _getCardDecoration(ThemeColors colors) {
    switch (widget.progress.status) {
      case MCPProgressStatus.completed:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
          gradient: LinearGradient(
            colors: [
              Colors.green.withOpacity(0.1),
              colors.primary.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Colors.green.withOpacity(0.3),
            width: 2,
          ),
        );
      case MCPProgressStatus.failed:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
            width: 1,
          ),
        );
      default:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
          gradient: LinearGradient(
            colors: [
              colors.primary.withOpacity(0.05),
              colors.accent.withOpacity(0.05),
            ],
          ),
        );
    }
  }

  Widget _buildMagicalHeader(ThemeColors colors) {
    return Row(
      children: [
        _buildMagicalIcon(colors),
        const SizedBox(width: SpacingTokens.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.progress.capability.iconEmoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  Expanded(
                    child: Text(
                      widget.progress.capability.displayName,
                      style: TextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                _getStatusMessage(),
                style: TextStyles.bodySmall.copyWith(
                  color: _getStatusColor(colors),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (widget.onDismiss != null && _canDismiss())
          IconButton(
            onPressed: widget.onDismiss,
            icon: Icon(
              Icons.close,
              color: colors.onSurfaceVariant,
              size: 20,
            ),
          ),
      ],
    );
  }

  Widget _buildProgressContent(ThemeColors colors) {
    switch (widget.progress.status) {
      case MCPProgressStatus.inProgress:
        return _buildInProgressContent(colors);
      case MCPProgressStatus.completed:
        return _buildCompletedContent(colors);
      case MCPProgressStatus.failed:
        return _buildFailedContent(colors);
      case MCPProgressStatus.partialSuccess:
        return _buildPartialSuccessContent(colors);
    }
  }

  Widget _buildInProgressContent(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnimatedProgressBar(colors),
        const SizedBox(height: SpacingTokens.md),
        Text(
          widget.progress.message,
          style: TextStyles.bodySmall.copyWith(
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: SpacingTokens.md),
        _buildInstallationSteps(colors),
      ],
    );
  }

  Widget _buildAnimatedProgressBar(ThemeColors colors) {
    final progress = _progressAnimation.value;

    return Container(
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BorderRadiusTokens.pill),
        color: colors.border,
      ),
      child: Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * progress,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(BorderRadiusTokens.pill),
              gradient: LinearGradient(
                colors: [colors.primary, colors.accent],
              ),
            ),
          ),
          if (widget.progress.status == MCPProgressStatus.inProgress)
            AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.pill),
                    gradient: LinearGradient(
                      colors: [
                        colors.primary.withOpacity(0.3),
                        Colors.transparent,
                      ],
                      stops: [_progressAnimation.value, _progressAnimation.value + 0.1],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildInstallationSteps(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: SpacingTokens.sm),
        Text(
          '✨ Making magic happen...',
          style: TextStyles.bodySmall.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: SpacingTokens.sm),
      ],
    );
  }

  Widget _buildCompletedContent(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(SpacingTokens.md),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
            border: Border.all(
              color: Colors.green.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.celebration,
                color: Colors.green,
                size: 24,
              ),
              const SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: Text(
                  '${widget.progress.capability.displayName} is ready!',
                  style: TextStyles.bodyMedium.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: SpacingTokens.lg),
        Text(
          _getCompletionMessage(),
          style: TextStyles.bodySmall.copyWith(
            color: colors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildFailedContent(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(SpacingTokens.md),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
            border: Border.all(
              color: Colors.red.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 24,
              ),
              const SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: Text(
                  'Installation failed',
                  style: TextStyles.bodyMedium.copyWith(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: SpacingTokens.sm),
        if (widget.progress.recoverySuggestions.isNotEmpty)
          Text(
            widget.progress.recoverySuggestions.first,
            style: TextStyles.bodySmall.copyWith(
              color: colors.onSurface,
            ),
          ),
      ],
    );
  }

  Widget _buildPartialSuccessContent(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(SpacingTokens.md),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
            border: Border.all(
              color: Colors.orange.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: Text(
                  'Partially installed',
                  style: TextStyles.bodyMedium.copyWith(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: SpacingTokens.sm),
        Text(
          'Some features may not work correctly. You can retry the installation.',
          style: TextStyles.bodySmall.copyWith(
            color: colors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildMagicalIcon(ThemeColors colors) {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [colors.primary, colors.accent],
              transform: GradientRotation(_progressAnimation.value * 2 * 3.14159),
            ),
          ),
          child: Center(
            child: Text(
              widget.progress.capability.iconEmoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActions(ThemeColors colors) {
    switch (widget.progress.status) {
      case MCPProgressStatus.failed:
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (widget.onDismiss != null)
              AsmblButton.secondary(
                text: 'Dismiss',
                onPressed: widget.onDismiss!,
              ),
            if (widget.onRetry != null) const SizedBox(width: SpacingTokens.sm),
            if (widget.onRetry != null)
              AsmblButton.primary(
                text: 'Retry',
                onPressed: widget.onRetry!,
              ),
          ],
        );
      case MCPProgressStatus.partialSuccess:
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (widget.onDismiss != null)
              AsmblButton.secondary(
                text: 'Continue',
                onPressed: widget.onDismiss!,
              ),
            const SizedBox(width: SpacingTokens.md),
            if (widget.onRetry != null)
              AsmblButton.primary(
                text: 'Retry',
                onPressed: widget.onRetry!,
              ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _getStatusMessage() {
    switch (widget.progress.status) {
      case MCPProgressStatus.inProgress:
        return widget.progress.message;
      case MCPProgressStatus.completed:
        return 'Ready to use!';
      case MCPProgressStatus.failed:
        return 'Installation failed';
      case MCPProgressStatus.partialSuccess:
        return 'Partially installed';
    }
  }

  Color _getStatusColor(ThemeColors colors) {
    switch (widget.progress.status) {
      case MCPProgressStatus.inProgress:
        return colors.primary;
      case MCPProgressStatus.completed:
        return Colors.green;
      case MCPProgressStatus.failed:
        return Colors.red;
      case MCPProgressStatus.partialSuccess:
        return Colors.orange;
    }
  }

  String _getCompletionMessage() {
    return '${widget.progress.capability.displayName} is now available for use in AI conversations.';
  }

  bool _shouldShowActions() {
    return widget.progress.status == MCPProgressStatus.failed ||
           widget.progress.status == MCPProgressStatus.partialSuccess;
  }

  bool _canDismiss() {
    return widget.progress.status == MCPProgressStatus.completed ||
           widget.progress.status == MCPProgressStatus.failed ||
           widget.progress.status == MCPProgressStatus.partialSuccess;
  }

  @override
  void dispose() {
    _progressController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }
}