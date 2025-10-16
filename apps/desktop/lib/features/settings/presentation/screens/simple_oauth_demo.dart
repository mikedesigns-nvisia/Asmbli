import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';

/// Simple OAuth demo without external dependencies
class SimpleOAuthDemo extends StatelessWidget {
  const SimpleOAuthDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return Scaffold(
      backgroundColor: colors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.backgroundGradientStart,
              colors.backgroundGradientMiddle,
              colors.backgroundGradientEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(SpacingTokens.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Icon(
                    Icons.account_circle,
                    size: 60,
                    color: colors.primary,
                  ),
                ),
                
                SizedBox(height: SpacingTokens.xxl),
                
                Text(
                  'Connected Accounts',
                  style: TextStyles.pageTitle.copyWith(
                    color: colors.onSurface,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                SizedBox(height: SpacingTokens.md),
                
                Text(
                  'Link your accounts to expand capabilities',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: SpacingTokens.xxl),
                
                // Connected section
                _buildSection('Connected Accounts', 0, colors, Icons.check_circle, Colors.green),
                
                SizedBox(height: SpacingTokens.xl),
                
                // Available section  
                _buildSection('Available to Connect', 4, colors, Icons.add_circle_outline, colors.primary),
                
                SizedBox(height: SpacingTokens.xxl),
                
                // Demo providers
                _buildProviderCard('GitHub', 'Access repositories and code', Icons.code, colors),
                SizedBox(height: SpacingTokens.md),
                _buildProviderCard('Slack', 'Send messages and notifications', Icons.chat, colors),
                SizedBox(height: SpacingTokens.md),
                _buildProviderCard('Linear', 'Manage issues and projects', Icons.linear_scale, colors),
                SizedBox(height: SpacingTokens.md),
                _buildProviderCard('Microsoft', 'Access files and calendar', Icons.business, colors),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, int count, ThemeColors colors, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        SizedBox(width: SpacingTokens.sm),
        Text(
          title.toUpperCase(),
          style: TextStyles.labelMedium.copyWith(
            color: colors.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(width: SpacingTokens.sm),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: SpacingTokens.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: colors.onSurfaceVariant.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count.toString(),
            style: TextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProviderCard(String name, String description, IconData icon, ThemeColors colors) {
    return Container(
      padding: EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.onSurfaceVariant.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              icon,
              color: colors.onSurfaceVariant,
              size: 24,
            ),
          ),
          
          SizedBox(width: SpacingTokens.lg),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyles.bodyLarge.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: SpacingTokens.md,
              vertical: SpacingTokens.sm,
            ),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Connect',
              style: TextStyles.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}