import 'package:flutter/material.dart';
import 'package:agent_engine_core/agent_engine_core.dart';
import '../../../../../core/design_system/design_system.dart';
import '../../../../../core/services/integration_service.dart';

/// Integration Card - Smart card component that renders different UI based on integration state
/// Supports progressive disclosure and contextual actions
class IntegrationCard extends StatelessWidget {
  final IntegrationStatus integrationStatus;
  final bool isExpertMode;
  final Function(String)? onTap;
  final Function(String, String)? onAction;

  const IntegrationCard({
    super.key,
    required this.integrationStatus,
    this.isExpertMode = false,
    this.onTap,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final definition = integrationStatus.definition;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap?.call(definition.id),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            border: Border.all(
              color: _getBorderColor(colors),
              width: _getBorderWidth(),
            ),
            boxShadow: [
              if (_shouldShowElevation())
                BoxShadow(
                  color: colors.primary.withOpacity( 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon, title, and status
                _buildHeader(colors, definition),
                
                const SizedBox(height: SpacingTokens.componentSpacing),
                
                // Status indicator and description
                _buildStatusSection(colors, definition),
                
                const SizedBox(height: SpacingTokens.componentSpacing),
                
                // Progressive content based on state and mode
                _buildContent(colors, definition),
                
                const SizedBox(height: SpacingTokens.componentSpacing),
                
                // Actions section
                _buildActions(colors, definition),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors, IntegrationDefinition definition) {
    return Row(
      children: [
        // Integration icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getIconBackgroundColor(colors),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
          ),
          child: Icon(
            _getIntegrationIcon(definition),
            size: 20,
            color: _getIconColor(colors),
          ),
        ),
        
        const SizedBox(width: SpacingTokens.componentSpacing),
        
        // Title and category
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                definition.name,
                style: TextStyles.cardTitle.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: SpacingTokens.xs_precise),
              Text(
                _getCategoryDisplayName(definition.category),
                style: TextStyles.caption.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        
        // State badge
        _buildStateBadge(colors),
      ],
    );
  }

  Widget _buildStatusSection(ThemeColors colors, IntegrationDefinition definition) {
    final statusInfo = _getStatusInfo(colors);
    
    return Row(
      children: [
        // Status indicator dot
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: statusInfo.color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        
        const SizedBox(width: SpacingTokens.iconSpacing),
        
        // Status text
        Expanded(
          child: Text(
            statusInfo.message,
            style: TextStyles.bodyMedium.copyWith(
              color: statusInfo.color,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        // Additional status info for expert mode
        if (isExpertMode && integrationStatus.isEnabled)
          _buildExpertStatusInfo(colors),
      ],
    );
  }

  Widget _buildContent(ThemeColors colors, IntegrationDefinition definition) {
    switch (_getIntegrationState()) {
      case IntegrationState.active:
        return _buildActiveContent(colors, definition);
      case IntegrationState.configured:
        return _buildConfiguredContent(colors, definition);
      case IntegrationState.suggested:
        return _buildSuggestedContent(colors, definition);
      case IntegrationState.available:
        return _buildAvailableContent(colors, definition);
    }
  }

  Widget _buildActiveContent(ThemeColors colors, IntegrationDefinition definition) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Usage metrics (mock data for now)
        Row(
          children: [
            Icon(
              Icons.trending_up,
              size: 16,
              color: colors.success ?? colors.primary,
            ),
            const SizedBox(width: SpacingTokens.xs_precise),
            Text(
              '47 requests today',
              style: TextStyles.caption.copyWith(
                color: colors.success ?? colors.primary,
              ),
            ),
          ],
        ),
        
        if (isExpertMode) ...[
          const SizedBox(height: SpacingTokens.iconSpacing),
          // Expert mode additional info
          Row(
            children: [
              _InfoChip(
                label: 'Latency: 120ms',
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: SpacingTokens.iconSpacing),
              _InfoChip(
                label: 'Uptime: 99.9%',
                color: colors.success ?? colors.primary,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildConfiguredContent(ThemeColors colors, IntegrationDefinition definition) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.warning_amber,
              size: 16,
              color: colors.warning ?? colors.primary,
            ),
            const SizedBox(width: SpacingTokens.xs_precise),
            Text(
              'Connection issue detected',
              style: TextStyles.caption.copyWith(
                color: colors.warning ?? colors.primary,
              ),
            ),
          ],
        ),
        
        if (isExpertMode) ...[
          const SizedBox(height: SpacingTokens.iconSpacing),
          Text(
            'Last successful connection: 2 hours ago',
            style: TextStyles.caption.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSuggestedContent(ThemeColors colors, IntegrationDefinition definition) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_fix_high,
              size: 16,
              color: colors.primary,
            ),
            const SizedBox(width: SpacingTokens.xs_precise),
            Text(
              'Detected on your system',
              style: TextStyles.caption.copyWith(color: colors.primary),
            ),
          ],
        ),
        
        const SizedBox(height: SpacingTokens.iconSpacing),
        
        // Benefits preview
        Text(
          '→ ${_getSuggestedBenefit(definition)}',
          style: TextStyles.caption.copyWith(
            color: colors.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableContent(ThemeColors colors, IntegrationDefinition definition) {
    return Text(
      definition.description,
      style: TextStyles.bodyMedium.copyWith(
        color: colors.onSurfaceVariant,
      ),
      maxLines: isExpertMode ? 3 : 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildActions(ThemeColors colors, IntegrationDefinition definition) {
    switch (_getIntegrationState()) {
      case IntegrationState.active:
        return _buildActiveActions(colors);
      case IntegrationState.configured:
        return _buildConfiguredActions(colors);
      case IntegrationState.suggested:
        return _buildSuggestedActions(colors);
      case IntegrationState.available:
        return _buildAvailableActions(colors);
    }
  }

  Widget _buildActiveActions(ThemeColors colors) {
    return Row(
      children: [
        _ActionButton(
          icon: Icons.settings,
          label: 'Settings',
          onPressed: () => onAction?.call(integrationStatus.definition.id, 'settings'),
        ),
        
        const SizedBox(width: SpacingTokens.iconSpacing),
        
        _ActionButton(
          icon: Icons.bar_chart,
          label: 'Stats',
          onPressed: () => onAction?.call(integrationStatus.definition.id, 'stats'),
        ),
        
        if (isExpertMode) ...[
          const SizedBox(width: SpacingTokens.iconSpacing),
          _ActionButton(
            icon: Icons.bug_report,
            label: 'Debug',
            onPressed: () => onAction?.call(integrationStatus.definition.id, 'debug'),
          ),
        ],
      ],
    );
  }

  Widget _buildConfiguredActions(ThemeColors colors) {
    return Row(
      children: [
        _ActionButton(
          icon: Icons.refresh,
          label: 'Reconnect',
          isPrimary: true,
          onPressed: () => onAction?.call(integrationStatus.definition.id, 'reconnect'),
        ),
        
        const SizedBox(width: SpacingTokens.iconSpacing),
        
        _ActionButton(
          icon: Icons.edit,
          label: 'Edit',
          onPressed: () => onAction?.call(integrationStatus.definition.id, 'edit'),
        ),
      ],
    );
  }

  Widget _buildSuggestedActions(ThemeColors colors) {
    return Row(
      children: [
        Expanded(
          child: AsmblButton.primary(
            text: 'Quick Setup',
            onPressed: () => onAction?.call(integrationStatus.definition.id, 'quick_setup'),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableActions(ThemeColors colors) {
    return Row(
      children: [
        _ActionButton(
          icon: Icons.add,
          label: 'Add',
          isPrimary: true,
          onPressed: () => onAction?.call(integrationStatus.definition.id, 'add'),
        ),
        
        const SizedBox(width: SpacingTokens.iconSpacing),
        
        _ActionButton(
          icon: Icons.info_outline,
          label: 'Learn More',
          onPressed: () => onAction?.call(integrationStatus.definition.id, 'info'),
        ),
      ],
    );
  }

  Widget _buildStateBadge(ThemeColors colors) {
    final state = _getIntegrationState();
    IconData icon;
    Color color;

    switch (state) {
      case IntegrationState.active:
        icon = Icons.check_circle;
        color = colors.success ?? colors.primary;
        break;
      case IntegrationState.configured:
        icon = Icons.settings;
        color = colors.warning ?? colors.primary;
        break;
      case IntegrationState.suggested:
        icon = Icons.lightbulb;
        color = colors.primary;
        break;
      case IntegrationState.available:
        icon = Icons.add_circle_outline;
        color = colors.onSurfaceVariant;
        break;
    }

    return Icon(icon, size: 20, color: color);
  }

  Widget _buildExpertStatusInfo(ThemeColors colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.memory,
          size: 12,
          color: colors.onSurfaceVariant,
        ),
        const SizedBox(width: SpacingTokens.xs_precise),
        Text(
          '120ms',
          style: TextStyles.caption.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // Helper methods
  IntegrationState _getIntegrationState() {
    if (integrationStatus.isConfigured && integrationStatus.isEnabled) {
      return IntegrationState.active;
    } else if (integrationStatus.isConfigured) {
      return IntegrationState.configured;
    } else if (_isSuggested()) {
      return IntegrationState.suggested;
    } else {
      return IntegrationState.available;
    }
  }

  bool _isSuggested() {
    // TODO: Implement suggestion logic based on detection results
    return false;
  }

  Color _getBorderColor(ThemeColors colors) {
    switch (_getIntegrationState()) {
      case IntegrationState.active:
        return colors.success ?? colors.primary;
      case IntegrationState.configured:
        return colors.warning ?? colors.primary;
      case IntegrationState.suggested:
        return colors.primary;
      case IntegrationState.available:
        return colors.border;
    }
  }

  double _getBorderWidth() {
    switch (_getIntegrationState()) {
      case IntegrationState.active:
      case IntegrationState.suggested:
        return 2;
      case IntegrationState.configured:
      case IntegrationState.available:
        return 1;
    }
  }

  bool _shouldShowElevation() {
    return _getIntegrationState() == IntegrationState.active ||
           _getIntegrationState() == IntegrationState.suggested;
  }

  Color _getIconBackgroundColor(ThemeColors colors) {
    switch (_getIntegrationState()) {
      case IntegrationState.active:
        return (colors.success ?? colors.primary).withOpacity( 0.1);
      case IntegrationState.configured:
        return (colors.warning ?? colors.primary).withOpacity( 0.1);
      case IntegrationState.suggested:
        return colors.primary.withOpacity( 0.1);
      case IntegrationState.available:
        return colors.surfaceVariant;
    }
  }

  Color _getIconColor(ThemeColors colors) {
    switch (_getIntegrationState()) {
      case IntegrationState.active:
        return colors.success ?? colors.primary;
      case IntegrationState.configured:
        return colors.warning ?? colors.primary;
      case IntegrationState.suggested:
        return colors.primary;
      case IntegrationState.available:
        return colors.onSurfaceVariant;
    }
  }

  IconData _getIntegrationIcon(IntegrationDefinition definition) {
    // Map integration categories to icons
    switch (definition.category) {
      case IntegrationCategory.local:
        return Icons.code;
      case IntegrationCategory.cloudAPIs:
        return Icons.cloud;
      case IntegrationCategory.databases:
        return Icons.storage;
      case IntegrationCategory.aiML:
        return Icons.psychology;
      default:
        return Icons.extension;
    }
  }

  String _getCategoryDisplayName(IntegrationCategory category) {
    switch (category) {
      case IntegrationCategory.local:
        return 'Development';
      case IntegrationCategory.cloudAPIs:
        return 'Cloud APIs';
      case IntegrationCategory.databases:
        return 'Data Storage';
      case IntegrationCategory.aiML:
        return 'AI & ML';
      default:
        return 'Integration';
    }
  }

  StatusInfo _getStatusInfo(ThemeColors colors) {
    switch (_getIntegrationState()) {
      case IntegrationState.active:
        return StatusInfo(
          message: 'Connected & Working',
          color: colors.success ?? colors.primary,
        );
      case IntegrationState.configured:
        return StatusInfo(
          message: 'Configured - Not Active',
          color: colors.warning ?? colors.primary,
        );
      case IntegrationState.suggested:
        return StatusInfo(
          message: 'Detected on system',
          color: colors.primary,
        );
      case IntegrationState.available:
        return StatusInfo(
          message: 'Not installed',
          color: colors.onSurfaceVariant,
        );
    }
  }

  String _getSuggestedBenefit(IntegrationDefinition definition) {
    // TODO: Return context-specific benefits based on integration type
    // Return default benefit since specific categories are not available
    return 'Enhance your workflow';
  }
}

/// Action button for integration cards
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.isPrimary = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    if (isPrimary) {
      return AsmblButton.primary(
        text: label,
        onPressed: () {
          print('🔘 Primary button pressed: $label');
          onPressed?.call();
        },
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          print('🔘 Secondary button pressed: $label');
          onPressed?.call();
        },
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.iconSpacing,
            vertical: SpacingTokens.xs_precise,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: colors.primary,
              ),
              const SizedBox(width: SpacingTokens.xs_precise),
              Text(
                label,
                style: TextStyles.caption.copyWith(
                  color: colors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Info chip for displaying small pieces of status information
class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.iconSpacing,
        vertical: SpacingTokens.xs_precise,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity( 0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
      ),
      child: Text(
        label,
        style: TextStyles.caption.copyWith(color: color),
      ),
    );
  }
}

/// Integration state enumeration
enum IntegrationState {
  active,     // ✅ Connected and working
  configured, // ⚙️ Configured but not active
  suggested,  // 💡 Detected on system
  available,  // ➕ Available to install
}

/// Status information helper class
class StatusInfo {
  final String message;
  final Color color;

  const StatusInfo({
    required this.message,
    required this.color,
  });
}