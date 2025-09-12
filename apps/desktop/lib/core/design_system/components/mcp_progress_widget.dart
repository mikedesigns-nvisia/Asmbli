import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design_system.dart';
import '../../models/mcp_capability.dart';
import '../../services/mcp_user_interface_service.dart';

/// Beautiful MCP Progress Widget
/// 
/// Following Anthropic PM approach:
/// - Friendly, non-technical language
/// - Clear visual progress indicators
/// - Helpful context and next steps
/// - Consistent with design system
class MCPProgressWidget extends ConsumerWidget {
  final MCPProgressState progress;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;

  const MCPProgressWidget({
    super.key,
    required this.progress,
    this.onDismiss,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ThemeColors(context);
    
    return AsmblCard(
      child: Padding(
        padding: SpacingTokens.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(colors),
            SizedBox(height: SpacingTokens.md.vertical),
            _buildProgressContent(colors),
            if (_showActions) ...[
              SizedBox(height: SpacingTokens.lg.vertical),
              _buildActions(colors),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getStatusColor(colors).withOpacity(0.1),
            borderRadius: BorderRadiusTokens.md,
          ),
          child: Center(
            child: _buildStatusIcon(colors),
          ),
        ),
        SizedBox(width: SpacingTokens.md.horizontal),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                progress.capability.displayName,
                style: TextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              Text(
                _getStatusText(),
                style: TextStyles.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (_showDismiss) _buildDismissButton(colors),
      ],
    );
  }

  Widget _buildProgressContent(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          progress.message,
          style: TextStyles.bodyMedium.copyWith(
            color: colors.onSurface,
          ),
        ),
        if (progress.status == MCPProgressStatus.inProgress) ...[
          SizedBox(height: SpacingTokens.md.vertical),
          _buildProgressBar(colors),
        ],
        if (progress.recoverySuggestions.isNotEmpty) ...[
          SizedBox(height: SpacingTokens.md.vertical),
          _buildRecoverySuggestions(colors),
        ],
      ],
    );
  }

  Widget _buildStatusIcon(ThemeColors colors) {
    switch (progress.status) {
      case MCPProgressStatus.inProgress:
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(colors.primary),
          ),
        );
      case MCPProgressStatus.completed:
        return Icon(
          Icons.check_circle,
          color: colors.primary,
          size: 20,
        );
      case MCPProgressStatus.partialSuccess:
        return Icon(
          Icons.warning_amber_rounded,
          color: Colors.orange,
          size: 20,
        );
      case MCPProgressStatus.failed:
        return Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 20,
        );
    }
  }

  Widget _buildProgressBar(ThemeColors colors) {
    return Column(
      children: [
        LinearProgressIndicator(
          backgroundColor: colors.border.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation(colors.primary),
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
              'Setting up...',
              style: TextStyles.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecoverySuggestions(ThemeColors colors) {
    return Container(
      padding: SpacingTokens.md,
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadiusTokens.md,
        border: Border.all(
          color: Colors.orange.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.orange,
                size: 16,
              ),
              SizedBox(width: SpacingTokens.sm.horizontal),
              Text(
                'Suggestions:',
                style: TextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: SpacingTokens.sm.vertical),
          ...progress.recoverySuggestions.map((suggestion) => Padding(
            padding: EdgeInsets.only(bottom: SpacingTokens.xs.vertical),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyles.bodySmall.copyWith(color: Colors.orange.shade800)),
                Expanded(
                  child: Text(
                    suggestion,
                    style: TextStyles.bodySmall.copyWith(
                      color: Colors.orange.shade800,
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

  Widget _buildActions(ThemeColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (progress.status == MCPProgressStatus.failed && onRetry != null)
          AsmblButton.secondary(
            text: 'Try Again',
            onPressed: onRetry,
            size: ButtonSize.small,
          ),
        if (_showDismiss && onDismiss != null) ...[
          SizedBox(width: SpacingTokens.sm.horizontal),
          AsmblButton.tertiary(
            text: progress.isCompleted ? 'Done' : 'Cancel',
            onPressed: onDismiss,
            size: ButtonSize.small,
          ),
        ],
      ],
    );
  }

  Widget _buildDismissButton(ThemeColors colors) {
    return IconButton(
      onPressed: onDismiss,
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
    switch (progress.status) {
      case MCPProgressStatus.inProgress:
        return colors.primary;
      case MCPProgressStatus.completed:
        return colors.primary;
      case MCPProgressStatus.partialSuccess:
        return Colors.orange;
      case MCPProgressStatus.failed:
        return Colors.red;
    }
  }

  String _getStatusText() {
    switch (progress.status) {
      case MCPProgressStatus.inProgress:
        return 'Setting up...';
      case MCPProgressStatus.completed:
        return 'Ready to use';
      case MCPProgressStatus.partialSuccess:
        return 'Partially ready';
      case MCPProgressStatus.failed:
        return 'Setup failed';
    }
  }

  String _getDurationText() {
    final duration = progress.duration;
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
    return '${duration.inSeconds}s';
  }

  bool get _showDismiss => progress.isCompleted || progress.status == MCPProgressStatus.failed;
  bool get _showActions => _showDismiss || progress.status == MCPProgressStatus.failed;
}

/// Progress List Widget - Shows all active MCP progress
class MCPProgressListWidget extends ConsumerWidget {
  const MCPProgressListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiService = ref.watch(mcpUserInterfaceServiceProvider);
    final activeProgress = uiService.getAllProgress();

    if (activeProgress.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: activeProgress.map((progress) => Padding(
        padding: EdgeInsets.only(bottom: SpacingTokens.md.vertical),
        child: MCPProgressWidget(
          progress: progress,
          onDismiss: () => _dismissProgress(ref, progress.id),
          onRetry: progress.status == MCPProgressStatus.failed 
            ? () => _retryCapability(ref, progress.capability)
            : null,
        ),
      )).toList(),
    );
  }

  void _dismissProgress(WidgetRef ref, String progressId) {
    // This would be handled by the UI service
    // For now, we'll just emit an event
  }

  void _retryCapability(WidgetRef ref, AgentCapability capability) {
    // This would trigger the orchestrator to retry
    // For now, we'll just emit an event
  }
}

/// Capability Permission Dialog
class CapabilityPermissionDialog extends StatelessWidget {
  final AgentCapability capability;
  final String explanation;
  final List<String> benefits;
  final List<String> risks;
  final VoidCallback onApprove;
  final VoidCallback onDeny;

  const CapabilityPermissionDialog({
    super.key,
    required this.capability,
    required this.explanation,
    required this.benefits,
    required this.risks,
    required this.onApprove,
    required this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusTokens.xl,
      ),
      title: Row(
        children: [
          Text(
            capability.iconEmoji,
            style: const TextStyle(fontSize: 24),
          ),
          SizedBox(width: SpacingTokens.md.horizontal),
          Expanded(
            child: Text(
              'Enable ${capability.displayName}?',
              style: TextStyles.pageTitle.copyWith(
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              explanation,
              style: TextStyles.bodyMedium.copyWith(
                color: colors.onSurface,
              ),
            ),
            if (benefits.isNotEmpty) ...[
              SizedBox(height: SpacingTokens.lg.vertical),
              _buildSection(
                'Benefits',
                benefits,
                Colors.green,
                Icons.check_circle_outline,
              ),
            ],
            if (risks.isNotEmpty) ...[
              SizedBox(height: SpacingTokens.lg.vertical),
              _buildSection(
                'Important to know',
                risks,
                Colors.orange,
                Icons.info_outline,
              ),
            ],
          ],
        ),
      ),
      actions: [
        AsmblButton.secondary(
          text: 'Not Now',
          onPressed: onDeny,
          size: ButtonSize.small,
        ),
        SizedBox(width: SpacingTokens.md.horizontal),
        AsmblButton.primary(
          text: 'Enable',
          onPressed: onApprove,
          size: ButtonSize.small,
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<String> items, Color color, IconData icon) {
    return Container(
      padding: SpacingTokens.md,
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadiusTokens.md,
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 16,
              ),
              SizedBox(width: SpacingTokens.sm.horizontal),
              Text(
                title,
                style: TextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: SpacingTokens.sm.vertical),
          ...items.map((item) => Padding(
            padding: EdgeInsets.only(bottom: SpacingTokens.xs.vertical),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyles.bodySmall.copyWith(color: color.shade800)),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyles.bodySmall.copyWith(
                      color: color.shade800,
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
}