import 'package:flutter/material.dart';
import '../../../../../core/design_system/design_system.dart';

/// Collapsible Status Panel - Shows integration status summary when expanded
class CollapsibleStatusPanel extends StatelessWidget {
  final VoidCallback onCollapse;

  const CollapsibleStatusPanel({
    super.key,
    required this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: SpacingTokens.pageHorizontal),
      padding: EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.onSurface.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with collapse button
          Row(
            children: [
              Text(
                'Quick Status',
                style: TextStyles.bodyLarge.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              IconButton(
                onPressed: onCollapse,
                icon: Icon(Icons.close, color: colors.onSurfaceVariant),
                tooltip: 'Collapse status panel',
              ),
            ],
          ),
          
          SizedBox(height: SpacingTokens.componentSpacing),
          
          // Status Summary
          Row(
            children: [
              _buildStatusItem('4 Active', Icons.check_circle, colors.success, colors),
              _buildDivider(colors),
              _buildStatusItem('2 Need Attention', Icons.warning_amber, colors.warning, colors),
              _buildDivider(colors),
              _buildStatusItem('1 Installing', Icons.download, colors.info, colors),
            ],
          ),
          
          SizedBox(height: SpacingTokens.componentSpacing),
          
          // Quick Actions
          Row(
            children: [
              AsmblButton.secondary(
                text: 'View Details',
                icon: Icons.visibility,
                onPressed: _viewDetails,
              ),
              SizedBox(width: SpacingTokens.componentSpacing),
              AsmblButton.secondary(
                text: 'Fix Issues',
                icon: Icons.build,
                onPressed: _fixIssues,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, IconData icon, Color color, ThemeColors colors) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: SpacingTokens.iconSpacing),
          Flexible(
            child: Text(
              label,
              style: TextStyles.bodyMedium.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ThemeColors colors) {
    return Container(
      width: 1,
      height: 24,
      margin: EdgeInsets.symmetric(horizontal: SpacingTokens.componentSpacing),
      color: colors.border,
    );
  }

  void _viewDetails() {
    // Navigate to detailed status view
  }

  void _fixIssues() {
    // Navigate to troubleshooting/fix issues view
  }
}