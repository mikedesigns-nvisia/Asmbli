import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/design_system.dart';
import '../../../core/models/settings_models.dart';
import '../providers/settings_provider.dart';

/// Reusable settings category card following design system patterns
class SettingsCategoryCard extends ConsumerStatefulWidget {
  final SettingsCategory category;
  final String title;
  final String description;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;
  final bool showStatus;

  const SettingsCategoryCard({
    super.key,
    required this.category,
    required this.title,
    required this.description,
    required this.icon,
    this.color,
    this.onTap,
    this.showStatus = true,
  });

  @override
  ConsumerState<SettingsCategoryCard> createState() => _SettingsCategoryCardState();
}

class _SettingsCategoryCardState extends ConsumerState<SettingsCategoryCard>
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
      curve: Curves.easeOutCubic,
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
    final attention = ref.watch(settingsAttentionProvider)
        .where((item) => item.category == widget.category)
        .toList();

    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AsmblCard(
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.all(SpacingTokens.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with icon and status
                    Row(
                      children: [
                        // Category icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: (widget.color ?? colors.primary).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                          ),
                          child: Icon(
                            widget.icon,
                            size: 24,
                            color: widget.color ?? colors.primary,
                          ),
                        ),
                        
                        const SizedBox(width: SpacingTokens.md),
                        
                        // Title and status
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: TextStyles.headingSmall.copyWith(
                                  color: colors.onSurface,
                                ),
                              ),
                              if (widget.showStatus && attention.isNotEmpty) ...[
                                const SizedBox(height: SpacingTokens.xs),
                                _buildStatusIndicator(attention, colors),
                              ],
                            ],
                          ),
                        ),
                        
                        // Arrow icon
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: colors.onSurfaceVariant.withOpacity(
                            _isHovered ? 1.0 : 0.6,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: SpacingTokens.md),
                    
                    // Description
                    Text(
                      widget.description,
                      style: TextStyles.bodyMedium.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Attention messages
                    if (attention.isNotEmpty) ...[
                      const SizedBox(height: SpacingTokens.sm),
                      _buildAttentionMessages(attention, colors),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build status indicator for the category
  Widget _buildStatusIndicator(List<SettingsAttentionItem> attention, ThemeColors colors) {
    final mostSevere = attention.fold<SettingsAttentionSeverity>(
      SettingsAttentionSeverity.info,
      (current, item) => item.severity.index > current.index ? item.severity : current,
    );

    Color statusColor;
    IconData statusIcon;
    
    switch (mostSevere) {
      case SettingsAttentionSeverity.error:
        statusColor = colors.error;
        statusIcon = Icons.error_outline;
        break;
      case SettingsAttentionSeverity.warning:
        statusColor = colors.warning;
        statusIcon = Icons.warning_amber_outlined;
        break;
      case SettingsAttentionSeverity.info:
        statusColor = colors.info;
        statusIcon = Icons.info_outline;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          statusIcon,
          size: 14,
          color: statusColor,
        ),
        const SizedBox(width: SpacingTokens.xs),
        Text(
          '${attention.length} ${attention.length == 1 ? 'item' : 'items'} need attention',
          style: TextStyles.captionMedium.copyWith(
            color: statusColor,
          ),
        ),
      ],
    );
  }

  /// Build attention messages list
  Widget _buildAttentionMessages(List<SettingsAttentionItem> attention, ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: attention.take(2).map((item) {
        Color messageColor;
        switch (item.severity) {
          case SettingsAttentionSeverity.error:
            messageColor = colors.error;
            break;
          case SettingsAttentionSeverity.warning:
            messageColor = colors.warning;
            break;
          case SettingsAttentionSeverity.info:
            messageColor = colors.info;
            break;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: SpacingTokens.xs),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: messageColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: SpacingTokens.xs),
              Expanded(
                child: Text(
                  item.message,
                  style: TextStyles.captionMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Handle hover animations
  void _handleHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    
    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }
}