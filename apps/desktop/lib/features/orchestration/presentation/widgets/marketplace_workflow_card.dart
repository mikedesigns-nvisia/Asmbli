import 'package:flutter/material.dart';

import '../../models/marketplace_workflow.dart';
import '../../../../core/design_system/design_system.dart';

/// Card widget for displaying marketplace workflow information
class MarketplaceWorkflowCard extends StatelessWidget {
  final MarketplaceWorkflow workflow;
  final VoidCallback onImport;
  final bool isFeatured;

  const MarketplaceWorkflowCard({
    super.key,
    required this.workflow,
    required this.onImport,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return AsmblCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with badges
          Container(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        workflow.name,
                        style: TextStyles.cardTitle.copyWith(
                          color: colors.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isFeatured)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SpacingTokens.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [colors.primary, colors.accent],
                          ),
                          borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                        ),
                        child: Text(
                          'FEATURED',
                          style: TextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: SpacingTokens.xs),
                
                // Author info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: colors.primary.withValues(alpha: 0.1),
                      child: Text(
                        workflow.author[0].toUpperCase(),
                        style: TextStyles.caption.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: SpacingTokens.sm),
                    Expanded(
                      child: Text(
                        workflow.author,
                        style: TextStyles.caption.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SpacingTokens.md),
                
                // Description
                Text(
                  workflow.description,
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: SpacingTokens.md),
                
                // Tags
                if (workflow.tags.isNotEmpty)
                  Wrap(
                    spacing: SpacingTokens.xs,
                    runSpacing: SpacingTokens.xs,
                    children: workflow.tags.take(3).map((tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                      ),
                      child: Text(
                        tag,
                        style: TextStyles.caption.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    )).toList()
                      ..addAll(workflow.tags.length > 3 ? [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: SpacingTokens.sm,
                            vertical: 2,
                          ),
                          child: Text(
                            '+${workflow.tags.length - 3}',
                            style: TextStyles.caption.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ] : []),
                  ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Stats and actions
          Container(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(BorderRadiusTokens.lg),
                bottomRight: Radius.circular(BorderRadiusTokens.lg),
              ),
            ),
            child: Column(
              children: [
                // Stats row
                Row(
                  children: [
                    _buildStatItem(
                      Icons.star,
                      workflow.ratingDisplay,
                      colors.warning,
                    ),
                    const SizedBox(width: SpacingTokens.md),
                    _buildStatItem(
                      Icons.download,
                      workflow.downloadCountDisplay,
                      colors.primary,
                    ),
                    const SizedBox(width: SpacingTokens.md),
                    _buildStatItem(
                      Icons.category,
                      workflow.category.displayName.split(' ').first,
                      colors.accent,
                    ),
                  ],
                ),
                const SizedBox(height: SpacingTokens.md),
                
                // Import button
                SizedBox(
                  width: double.infinity,
                  child: AsmblButton.primary(
                    text: 'Import Workflow',
                    icon: Icons.download,
                    onPressed: onImport,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, Color color) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: SpacingTokens.xs),
          Expanded(
            child: Text(
              value,
              style: TextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}