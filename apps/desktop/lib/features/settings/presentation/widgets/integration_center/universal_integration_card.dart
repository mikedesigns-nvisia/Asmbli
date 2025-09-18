import 'package:flutter/material.dart';
import '../../../../../core/design_system/design_system.dart';

/// Universal Integration Card - Handles all integration states in one component
/// States: Available, Configured, Active, Installing, Error, Needs Attention
class UniversalIntegrationCard extends StatefulWidget {
  final IntegrationCardData integration;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;

  const UniversalIntegrationCard({
    super.key,
    required this.integration,
    this.onPrimaryAction,
    this.onSecondaryAction,
  });

  @override
  State<UniversalIntegrationCard> createState() => _UniversalIntegrationCardState();
}

class _UniversalIntegrationCardState extends State<UniversalIntegrationCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final statusConfig = _getStatusConfig(widget.integration.status, colors);

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 280,
              height: 200,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
                border: Border.all(
                  color: _isHovered 
                    ? statusConfig.borderColor.withOpacity( 0.5)
                    : colors.border,
                  width: _isHovered ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isHovered
                      ? statusConfig.shadowColor.withOpacity( 0.15)
                      : colors.onSurface.withOpacity( 0.05),
                    blurRadius: _isHovered ? 16 : 8,
                    offset: Offset(0, _isHovered ? 4 : 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onPrimaryAction,
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
                  child: Padding(
                    padding: const EdgeInsets.all(SpacingTokens.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(colors, statusConfig),
                        const SizedBox(height: SpacingTokens.componentSpacing),
                        _buildDescription(colors),
                        const Spacer(),
                        _buildMetrics(colors),
                        const SizedBox(height: SpacingTokens.componentSpacing),
                        _buildActions(colors, statusConfig),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors, IntegrationStatusConfig statusConfig) {
    return Row(
      children: [
        // Integration Icon
        Container(
          padding: const EdgeInsets.all(SpacingTokens.iconSpacing),
          decoration: BoxDecoration(
            color: widget.integration.brandColor.withOpacity( 0.1),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          ),
          child: Icon(
            widget.integration.icon,
            color: widget.integration.brandColor,
            size: 24,
          ),
        ),
        
        const SizedBox(width: SpacingTokens.componentSpacing),
        
        // Name and Status
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.integration.name,
                style: TextStyles.cardTitle.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: SpacingTokens.xs_precise),
              _buildStatusChip(statusConfig, colors),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(IntegrationStatusConfig statusConfig, ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.iconSpacing,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: statusConfig.backgroundColor,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.pill),
        border: Border.all(color: statusConfig.borderColor.withOpacity( 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (statusConfig.icon != null) ...[
            Icon(
              statusConfig.icon,
              size: 12,
              color: statusConfig.textColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            statusConfig.label,
            style: TextStyles.caption.copyWith(
              color: statusConfig.textColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(ThemeColors colors) {
    return Text(
      widget.integration.description,
      style: TextStyles.bodyMedium.copyWith(
        color: colors.onSurfaceVariant,
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMetrics(ThemeColors colors) {
    if (widget.integration.metrics.isEmpty) return const SizedBox.shrink();
    
    return Row(
      children: widget.integration.metrics.take(2).map((metric) {
        return Padding(
          padding: const EdgeInsets.only(right: SpacingTokens.componentSpacing),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                metric.icon,
                size: 14,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                metric.value,
                style: TextStyles.caption.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActions(ThemeColors colors, IntegrationStatusConfig statusConfig) {
    return Row(
      children: [
        Expanded(
          child: AsmblButton.primary(
            text: statusConfig.primaryActionLabel,
            onPressed: widget.onPrimaryAction,
          ),
        ),
        if (statusConfig.hasSecondaryAction) ...[
          const SizedBox(width: SpacingTokens.iconSpacing),
          IconButton(
            onPressed: widget.onSecondaryAction,
            icon: Icon(
              statusConfig.secondaryActionIcon,
              color: colors.onSurfaceVariant,
            ),
            tooltip: statusConfig.secondaryActionTooltip,
          ),
        ],
      ],
    );
  }

  IntegrationStatusConfig _getStatusConfig(IntegrationStatus status, ThemeColors colors) {
    switch (status) {
      case IntegrationStatus.available:
        return IntegrationStatusConfig(
          label: 'Available',
          primaryActionLabel: 'Install',
          backgroundColor: colors.success.withOpacity( 0.1),
          borderColor: colors.success,
          shadowColor: colors.success,
          textColor: colors.success,
          icon: Icons.add_circle_outline,
        );
      
      case IntegrationStatus.configured:
        return IntegrationStatusConfig(
          label: 'Configured',
          primaryActionLabel: 'Configure',
          backgroundColor: colors.primary.withOpacity( 0.1),
          borderColor: colors.primary,
          shadowColor: colors.primary,
          textColor: colors.primary,
          icon: Icons.settings,
          hasSecondaryAction: true,
          secondaryActionIcon: Icons.more_vert,
          secondaryActionTooltip: 'More actions',
        );
      
      case IntegrationStatus.active:
        return IntegrationStatusConfig(
          label: 'Active',
          primaryActionLabel: 'Manage',
          backgroundColor: colors.success.withOpacity( 0.1),
          borderColor: colors.success,
          shadowColor: colors.success,
          textColor: colors.success,
          icon: Icons.check_circle,
          hasSecondaryAction: true,
          secondaryActionIcon: Icons.settings,
          secondaryActionTooltip: 'Settings',
        );
      
      case IntegrationStatus.installing:
        return IntegrationStatusConfig(
          label: 'Installing...',
          primaryActionLabel: 'Installing',
          backgroundColor: colors.warning.withOpacity( 0.1),
          borderColor: colors.warning,
          shadowColor: colors.warning,
          textColor: colors.warning,
          icon: Icons.download,
        );
      
      case IntegrationStatus.error:
        return IntegrationStatusConfig(
          label: 'Error',
          primaryActionLabel: 'Fix Issues',
          backgroundColor: colors.error.withOpacity( 0.1),
          borderColor: colors.error,
          shadowColor: colors.error,
          textColor: colors.error,
          icon: Icons.error_outline,
          hasSecondaryAction: true,
          secondaryActionIcon: Icons.refresh,
          secondaryActionTooltip: 'Retry',
        );
      
      case IntegrationStatus.needsAttention:
        return IntegrationStatusConfig(
          label: 'Needs Setup',
          primaryActionLabel: 'Complete Setup',
          backgroundColor: colors.warning.withOpacity( 0.1),
          borderColor: colors.warning,
          shadowColor: colors.warning,
          textColor: colors.warning,
          icon: Icons.warning_amber,
        );
    }
  }
}

// Data Models
class IntegrationCardData {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color brandColor;
  final IntegrationStatus status;
  final List<IntegrationMetric> metrics;
  final String category;
  final double rating;

  const IntegrationCardData({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.brandColor,
    required this.status,
    this.metrics = const [],
    required this.category,
    this.rating = 0.0,
  });
}

class IntegrationMetric {
  final String label;
  final String value;
  final IconData icon;

  const IntegrationMetric({
    required this.label,
    required this.value,
    required this.icon,
  });
}

enum IntegrationStatus {
  available,
  configured,
  active,
  installing,
  error,
  needsAttention,
}

class IntegrationStatusConfig {
  final String label;
  final String primaryActionLabel;
  final Color backgroundColor;
  final Color borderColor;
  final Color shadowColor;
  final Color textColor;
  final IconData? icon;
  final bool hasSecondaryAction;
  final IconData? secondaryActionIcon;
  final String? secondaryActionTooltip;

  const IntegrationStatusConfig({
    required this.label,
    required this.primaryActionLabel,
    required this.backgroundColor,
    required this.borderColor,
    required this.shadowColor,
    required this.textColor,
    this.icon,
    this.hasSecondaryAction = false,
    this.secondaryActionIcon,
    this.secondaryActionTooltip,
  });
}