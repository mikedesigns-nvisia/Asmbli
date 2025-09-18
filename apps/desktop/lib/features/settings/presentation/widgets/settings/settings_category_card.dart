import 'package:flutter/material.dart';
import '../../../../../core/design_system/design_system.dart';
import '../../screens/modern_settings_screen.dart';

/// Modern settings category card with hover effects and expansion
class SettingsCategoryCard extends StatefulWidget {
  final SettingsCategory category;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onExpand;

  const SettingsCategoryCard({
    super.key,
    required this.category,
    required this.isExpanded,
    required this.onTap,
    required this.onExpand,
  });

  @override
  State<SettingsCategoryCard> createState() => _SettingsCategoryCardState();
}

class _SettingsCategoryCardState extends State<SettingsCategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SettingsCategoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
          border: Border.all(
            color: _isHovered ? colors.primary.withOpacity( 0.3) : colors.border,
            width: _isHovered ? 2 : 1,
          ),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: colors.primary.withOpacity( 0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: colors.onSurface.withOpacity( 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
            child: Padding(
              padding: const EdgeInsets.all(SpacingTokens.lg),
              child: Column(
                children: [
                  // Main Card Content
                  _buildCardHeader(colors),
                  
                  // Expandable Content
                  SizeTransition(
                    sizeFactor: _expandAnimation,
                    child: _buildExpandedContent(colors),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(ThemeColors colors) {
    return Row(
      children: [
        // Category Icon
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(SpacingTokens.componentSpacing),
          decoration: BoxDecoration(
            color: widget.category.color.withOpacity( _isHovered ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          ),
          child: Icon(
            widget.category.icon,
            size: 24,
            color: widget.category.color,
          ),
        ),
        
        const SizedBox(width: SpacingTokens.componentSpacing),
        
        // Category Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.category.title,
                    style: TextStyles.cardTitle.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  if (widget.category.badge != null) ...[
                    const SizedBox(width: SpacingTokens.iconSpacing),
                    _buildBadge(colors),
                  ],
                  
                  if (widget.category.isAdvanced) ...[
                    const SizedBox(width: SpacingTokens.iconSpacing),
                    _buildAdvancedBadge(colors),
                  ],
                ],
              ),
              
              const SizedBox(height: SpacingTokens.xs_precise),
              
              Text(
                widget.category.description,
                style: TextStyles.bodyMedium.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        
        // Action Buttons
        _buildActions(colors),
      ],
    );
  }

  Widget _buildBadge(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.iconSpacing,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: widget.category.color.withOpacity( 0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.pill),
        border: Border.all(
          color: widget.category.color.withOpacity( 0.3),
        ),
      ),
      child: Text(
        widget.category.badge!,
        style: TextStyles.caption.copyWith(
          color: widget.category.color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildAdvancedBadge(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.iconSpacing,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colors.warning.withOpacity( 0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.pill),
        border: Border.all(
          color: colors.warning.withOpacity( 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.engineering,
            size: 10,
            color: colors.warning,
          ),
          const SizedBox(width: 2),
          Text(
            'ADVANCED',
            style: TextStyles.caption.copyWith(
              color: colors.warning,
              fontWeight: FontWeight.w700,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(ThemeColors colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Quick Settings Button
        IconButton(
          onPressed: widget.onExpand,
          icon: AnimatedRotation(
            turns: widget.isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.expand_more,
              color: colors.onSurfaceVariant,
            ),
          ),
          tooltip: 'Quick Settings',
        ),
        
        // Navigate Button
        IconButton(
          onPressed: widget.onTap,
          icon: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: colors.primary,
          ),
          tooltip: 'Open ${widget.category.title}',
        ),
      ],
    );
  }

  Widget _buildExpandedContent(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.only(top: SpacingTokens.componentSpacing),
      child: Column(
        children: [
          Divider(color: colors.border),
          const SizedBox(height: SpacingTokens.componentSpacing),
          
          // Quick Settings Based on Category
          _buildQuickSettings(colors),
        ],
      ),
    );
  }

  Widget _buildQuickSettings(ThemeColors colors) {
    switch (widget.category.id) {
      case 'appearance':
        return _buildAppearanceQuickSettings(colors);
      case 'notifications':
        return _buildNotificationQuickSettings(colors);
      case 'privacy':
        return _buildPrivacyQuickSettings(colors);
      default:
        return _buildDefaultQuickSettings(colors);
    }
  }

  Widget _buildAppearanceQuickSettings(ThemeColors colors) {
    return Column(
      children: [
        _buildQuickToggle(
          'Dark Mode',
          'Switch between light and dark themes',
          Icons.dark_mode,
          false, // TODO: Get actual value
          (value) => {}, // TODO: Implement
          colors,
        ),
        const SizedBox(height: SpacingTokens.componentSpacing),
        _buildQuickAction(
          'Change Theme',
          'Browse available themes',
          Icons.palette,
          () => {}, // TODO: Implement
          colors,
        ),
      ],
    );
  }

  Widget _buildNotificationQuickSettings(ThemeColors colors) {
    return Column(
      children: [
        _buildQuickToggle(
          'Desktop Notifications',
          'Show system notifications',
          Icons.notifications,
          true, // TODO: Get actual value
          (value) => {}, // TODO: Implement
          colors,
        ),
        const SizedBox(height: SpacingTokens.componentSpacing),
        _buildQuickToggle(
          'Sound Alerts',
          'Play sounds for notifications',
          Icons.volume_up,
          false, // TODO: Get actual value
          (value) => {}, // TODO: Implement
          colors,
        ),
      ],
    );
  }

  Widget _buildPrivacyQuickSettings(ThemeColors colors) {
    return Column(
      children: [
        _buildQuickToggle(
          'Analytics',
          'Help improve the app with usage data',
          Icons.analytics,
          true, // TODO: Get actual value
          (value) => {}, // TODO: Implement
          colors,
        ),
        const SizedBox(height: SpacingTokens.componentSpacing),
        _buildQuickAction(
          'Clear Data',
          'Remove stored conversations and cache',
          Icons.delete_sweep,
          () => {}, // TODO: Implement
          colors,
        ),
      ],
    );
  }

  Widget _buildDefaultQuickSettings(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.componentSpacing),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withOpacity( 0.5),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
      ),
      child: Row(
        children: [
          Icon(
            Icons.settings,
            color: colors.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: SpacingTokens.componentSpacing),
          Text(
            'Click the arrow to access all ${widget.category.title.toLowerCase()} settings',
            style: TextStyles.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickToggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
    ThemeColors colors,
  ) {
    return Row(
      children: [
        Icon(icon, color: colors.onSurfaceVariant, size: 20),
        const SizedBox(width: SpacingTokens.componentSpacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyles.bodyMedium.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: TextStyles.caption.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildQuickAction(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onPressed,
    ThemeColors colors,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.iconSpacing),
        child: Row(
          children: [
            Icon(icon, color: colors.primary, size: 20),
            const SizedBox(width: SpacingTokens.componentSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyles.bodyMedium.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyles.caption.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}