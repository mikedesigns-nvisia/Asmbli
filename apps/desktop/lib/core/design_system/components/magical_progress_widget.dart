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
        _progressController.forward(to: 0.7);
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
                padding: SpacingTokens.lg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMagicalHeader(colors),
                    SizedBox(height: SpacingTokens.md.vertical),
                    _buildProgressContent(colors),
                    if (_shouldShowActions()) ...[
                      SizedBox(height: SpacingTokens.lg.vertical),
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
          borderRadius: BorderRadiusTokens.xl,
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
          borderRadius: BorderRadiusTokens.xl,
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
            width: 1,
          ),
        );
      default:
        return BoxDecoration(
          borderRadius: BorderRadiusTokens.xl,
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
        SizedBox(width: SpacingTokens.md.horizontal),
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
                  SizedBox(width: SpacingTokens.sm.horizontal),
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
        if (_shouldShowDismiss()) _buildDismissButton(colors),
      ],
    );
  }

  Widget _buildMagicalIcon(ThemeColors colors) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: _getStatusColor(colors).withOpacity(0.1),
        borderRadius: BorderRadiusTokens.full,
        border: Border.all(
          color: _getStatusColor(colors).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: _buildStatusIcon(colors),
      ),
    );
  }

  Widget _buildStatusIcon(ThemeColors colors) {
    switch (widget.progress.status) {
      case MCPProgressStatus.inProgress:
        return SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(_colorAnimation.value ?? colors.primary),
          ),
        );
      case MCPProgressStatus.completed:
        return Icon(
          Icons.celebration,
          color: Colors.green,
          size: 26,
        );
      case MCPProgressStatus.partialSuccess:
        return Icon(
          Icons.warning_amber_rounded,
          color: Colors.orange,
          size: 26,
        );
      case MCPProgressStatus.failed:
        return Icon(
          Icons.refresh,
          color: Colors.red,
          size: 26,
        );
    }
  }

  Widget _buildProgressContent(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.progress.message,
          style: TextStyles.bodyMedium.copyWith(
            color: colors.onSurface,
            height: 1.4,
          ),
        ),
        if (widget.progress.status == MCPProgressStatus.inProgress) ...[
          SizedBox(height: SpacingTokens.md.vertical),
          _buildMagicalProgressBar(colors),
        ],
        if (widget.progress.status == MCPProgressStatus.completed) ...[
          SizedBox(height: SpacingTokens.sm.vertical),
          _buildSuccessCelebration(colors),
        ],
        if (widget.progress.recoverySuggestions.isNotEmpty) ...[
          SizedBox(height: SpacingTokens.md.vertical),
          _buildHelpfulSuggestions(colors),
        ],
      ],
    );
  }

  Widget _buildMagicalProgressBar(ThemeColors colors) {
    return Column(
      children: [
        Container(
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadiusTokens.full,
            color: colors.border.withOpacity(0.3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadiusTokens.full,
            child: LinearProgressIndicator(
              value: null, // Indeterminate for magical effect
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(_colorAnimation.value ?? colors.primary),
            ),
          ),
        ),
        SizedBox(height: SpacingTokens.sm.vertical),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getDurationText(),
              style: TextStyles.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            Text(
              '✨ Working magic...',
              style: TextStyles.bodySmall.copyWith(
                color: colors.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccessCelebration(ThemeColors colors) {
    return Container(
      padding: SpacingTokens.sm,
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadiusTokens.md,
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.party_mode,
            color: Colors.green,
            size: 16,
          ),
          SizedBox(width: SpacingTokens.sm.horizontal),
          Expanded(
            child: Text(
              'Ready to supercharge your workflow! 🚀',
              style: TextStyles.bodySmall.copyWith(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpfulSuggestions(ThemeColors colors) {
    return Container(
      padding: SpacingTokens.md,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadiusTokens.md,
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.blue,
                size: 16,
              ),
              SizedBox(width: SpacingTokens.sm.horizontal),
              Text(
                'Here\'s how to fix this:',
                style: TextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: SpacingTokens.sm.vertical),
          ...widget.progress.recoverySuggestions.take(2).map((suggestion) => Padding(
            padding: EdgeInsets.only(bottom: SpacingTokens.xs.vertical),
            child: Text(
              suggestion,
              style: TextStyles.bodySmall.copyWith(
                color: Colors.blue.shade700,
                height: 1.3,
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildActions(ThemeColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.progress.status == MCPProgressStatus.failed && widget.onRetry != null)
          AsmblButton.secondary(
            text: '🔄 Try Again',
            onPressed: widget.onRetry,
            size: ButtonSize.small,
          ),
        if (_shouldShowDismiss() && widget.onDismiss != null) ...[
          if (widget.onRetry != null) SizedBox(width: SpacingTokens.sm.horizontal),
          AsmblButton.tertiary(
            text: widget.progress.isCompleted ? '✨ Awesome!' : 'Maybe Later',
            onPressed: widget.onDismiss,
            size: ButtonSize.small,
          ),
        ],
      ],
    );
  }

  Widget _buildDismissButton(ThemeColors colors) {
    return IconButton(
      onPressed: widget.onDismiss,
      icon: Icon(
        Icons.close,
        size: 18,
        color: colors.onSurfaceVariant,
      ),
      constraints: const BoxConstraints(
        minWidth: 32,
        minHeight: 32,
      ),
    );
  }

  Color _getStatusColor(ThemeColors colors) {
    switch (widget.progress.status) {
      case MCPProgressStatus.inProgress:
        return _colorAnimation.value ?? colors.primary;
      case MCPProgressStatus.completed:
        return Colors.green;
      case MCPProgressStatus.partialSuccess:
        return Colors.orange;
      case MCPProgressStatus.failed:
        return Colors.red;
    }
  }

  String _getStatusMessage() {
    switch (widget.progress.status) {
      case MCPProgressStatus.inProgress:
        return 'Setting up your superpowers...';
      case MCPProgressStatus.completed:
        return 'Ready to rock! 🎉';
      case MCPProgressStatus.partialSuccess:
        return 'Mostly ready (some parts need attention)';
      case MCPProgressStatus.failed:
        return 'Oops, hit a snag - but we can fix this!';
    }
  }

  String _getDurationText() {
    final duration = widget.progress.duration;
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
    return '${duration.inSeconds}s';
  }

  bool _shouldShowDismiss() => widget.progress.isCompleted || widget.progress.status == MCPProgressStatus.failed;
  bool _shouldShowActions() => _shouldShowDismiss() || widget.progress.status == MCPProgressStatus.failed;

  @override
  void dispose() {
    _progressController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }
}

/// 🎨 Enhanced Capability Permission Dialog - Makes Security Feel Empowering
class MagicalCapabilityPermissionDialog extends StatefulWidget {
  final AgentCapability capability;
  final String explanation;
  final List<String> benefits;
  final List<String> risks;
  final VoidCallback onApprove;
  final VoidCallback onDeny;

  const MagicalCapabilityPermissionDialog({
    super.key,
    required this.capability,
    required this.explanation,
    required this.benefits,
    required this.risks,
    required this.onApprove,
    required this.onDeny,
  });

  @override
  State<MagicalCapabilityPermissionDialog> createState() => _MagicalCapabilityPermissionDialogState();
}

class _MagicalCapabilityPermissionDialogState extends State<MagicalCapabilityPermissionDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusTokens.xl,
              ),
              backgroundColor: colors.surface,
              title: _buildMagicalTitle(),
              content: _buildMagicalContent(colors),
              actions: _buildMagicalActions(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMagicalTitle() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ThemeColors(context).primary.withOpacity(0.1),
            borderRadius: BorderRadiusTokens.full,
          ),
          child: Text(
            widget.capability.iconEmoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
        SizedBox(width: SpacingTokens.md.horizontal),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enable ${widget.capability.displayName}?',
                style: TextStyles.pageTitle.copyWith(fontSize: 20),
              ),
              Text(
                'This will supercharge your AI assistant!',
                style: TextStyles.bodySmall.copyWith(
                  color: ThemeColors(context).onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMagicalContent(ThemeColors colors) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: SpacingTokens.md,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.05),
              borderRadius: BorderRadiusTokens.md,
            ),
            child: Text(
              widget.explanation,
              style: TextStyles.bodyMedium.copyWith(
                color: colors.onSurface,
                height: 1.4,
              ),
            ),
          ),
          SizedBox(height: SpacingTokens.lg.vertical),
          _buildBenefitsSection(colors),
          if (widget.risks.isNotEmpty) ...[
            SizedBox(height: SpacingTokens.lg.vertical),
            _buildPrivacySection(colors),
          ],
        ],
      ),
    );
  }

  Widget _buildBenefitsSection(ThemeColors colors) {
    return Container(
      padding: SpacingTokens.md,
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadiusTokens.md,
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.green, size: 18),
              SizedBox(width: SpacingTokens.sm.horizontal),
              Text(
                'What you\'ll get:',
                style: TextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: SpacingTokens.sm.vertical),
          ...widget.benefits.map((benefit) => Padding(
            padding: EdgeInsets.only(bottom: SpacingTokens.xs.vertical),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✨ ', style: TextStyle(color: Colors.green.shade600)),
                Expanded(
                  child: Text(
                    benefit,
                    style: TextStyles.bodySmall.copyWith(
                      color: Colors.green.shade700,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPrivacySection(ThemeColors colors) {
    return Container(
      padding: SpacingTokens.md,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadiusTokens.md,
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.privacy_tip_outlined, color: Colors.blue, size: 18),
              SizedBox(width: SpacingTokens.sm.horizontal),
              Text(
                'Privacy & Security:',
                style: TextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: SpacingTokens.sm.vertical),
          ...widget.risks.map((risk) => Padding(
            padding: EdgeInsets.only(bottom: SpacingTokens.xs.vertical),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🛡️ ', style: TextStyle(color: Colors.blue.shade600)),
                Expanded(
                  child: Text(
                    risk,
                    style: TextStyles.bodySmall.copyWith(
                      color: Colors.blue.shade700,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  List<Widget> _buildMagicalActions() {
    return [
      AsmblButton.secondary(
        text: 'Maybe Later',
        onPressed: widget.onDeny,
        size: ButtonSize.small,
      ),
      SizedBox(width: SpacingTokens.md.horizontal),
      AsmblButton.primary(
        text: '✨ Enable Magic!',
        onPressed: widget.onApprove,
        size: ButtonSize.small,
      ),
    ];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}