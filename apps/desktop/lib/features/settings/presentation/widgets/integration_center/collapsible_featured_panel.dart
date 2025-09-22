import 'package:flutter/material.dart';
import '../../../../../core/design_system/design_system.dart';

/// Collapsible Featured Panel - Shows featured integrations when expanded
class CollapsibleFeaturedPanel extends StatelessWidget {
  final VoidCallback onCollapse;

  const CollapsibleFeaturedPanel({
    super.key,
    required this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: SpacingTokens.pageHorizontal),
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.onSurface.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with collapse button
          Row(
            children: [
              Icon(Icons.star, color: colors.warning, size: 20),
              const SizedBox(width: SpacingTokens.iconSpacing),
              Text(
                'Featured This Week',
                style: TextStyles.bodyLarge.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onCollapse,
                icon: Icon(Icons.close, color: colors.onSurfaceVariant),
                tooltip: 'Collapse featured panel',
              ),
            ],
          ),
          
          const SizedBox(height: SpacingTokens.componentSpacing),
          
          // Featured Items
          Column(
            children: _getFeaturedIntegrations().map((featured) {
              return Padding(
                padding: const EdgeInsets.only(bottom: SpacingTokens.iconSpacing),
                child: _buildFeaturedItem(featured, colors),
              );
            }).toList(),
          ),
          
          const SizedBox(height: SpacingTokens.componentSpacing),
          
          // View All Button
          AsmblButton.secondary(
            text: 'See all featured',
            icon: Icons.arrow_forward,
            onPressed: _viewAllFeatured,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedItem(FeaturedIntegration featured, ThemeColors colors) {
    return InkWell(
      onTap: () => _viewIntegration(featured.id),
      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.iconSpacing,
          vertical: SpacingTokens.xs_precise,
        ),
        child: Row(
          children: [
            // Integration Icon
            Container(
              padding: const EdgeInsets.all(SpacingTokens.xs_precise),
              decoration: BoxDecoration(
                color: featured.brandColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
              ),
              child: Icon(
                featured.icon,
                color: featured.brandColor,
                size: 16,
              ),
            ),
            
            const SizedBox(width: SpacingTokens.componentSpacing),
            
            // Name and Badge
            Expanded(
              child: Row(
                children: [
                  Text(
                    featured.name,
                    style: TextStyles.bodyMedium.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.iconSpacing),
                  if (featured.badge.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.xs_precise,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(BorderRadiusTokens.pill),
                      ),
                      child: Text(
                        featured.badge,
                        style: TextStyles.caption.copyWith(
                          color: colors.warning,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  List<FeaturedIntegration> _getFeaturedIntegrations() {
    return [
      const FeaturedIntegration(
        id: 'github-copilot',
        name: 'GitHub Copilot',
        icon: Icons.auto_awesome,
        brandColor: Color(0xFF24292F),
        badge: '🔥 Hot',
      ),
      const FeaturedIntegration(
        id: 'notion-database',
        name: 'Notion Database',
        icon: Icons.table_chart,
        brandColor: Color(0xFF000000),
        badge: '⭐ Popular',
      ),
      const FeaturedIntegration(
        id: 'slack-notifications',
        name: 'Slack Notifications',
        icon: Icons.notifications,
        brandColor: Color(0xFF4A154B),
        badge: '✨ New',
      ),
    ];
  }

  void _viewIntegration(String integrationId) {
    // Navigate to specific integration details
  }

  void _viewAllFeatured() {
    // Show full featured integrations view
  }
}

class FeaturedIntegration {
  final String id;
  final String name;
  final IconData icon;
  final Color brandColor;
  final String badge;

  const FeaturedIntegration({
    required this.id,
    required this.name,
    required this.icon,
    required this.brandColor,
    this.badge = '',
  });
}