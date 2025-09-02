import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_system/design_system.dart';

/// Quick Actions Bar - Primary actions for integration management
/// Adapts to user experience level and provides contextual shortcuts
class QuickActionsBar extends ConsumerWidget {
  final VoidCallback? onDetectionRequested;
  final VoidCallback? onAddIntegrationRequested;
  final VoidCallback? onImportRequested;
  final VoidCallback? onSuggestionsRequested;
  final bool isExpertMode;

  const QuickActionsBar({
    super.key,
    this.onDetectionRequested,
    this.onAddIntegrationRequested,
    this.onImportRequested,
    this.onSuggestionsRequested,
    this.isExpertMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ThemeColors(context);
    
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Primary Actions Row
          Row(
            children: [
              // Add Integration - Smart primary action
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.add_circle,
                  label: 'Add Integration',
                  description: 'Browse and install new integrations',
                  isPrimary: true,
                  onPressed: onAddIntegrationRequested,
                ),
              ),
              
              const SizedBox(width: SpacingTokens.componentSpacing),
              
              // Auto Detection - One-click discovery
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.auto_fix_high,
                  label: 'Auto Detect',
                  description: 'Scan system for compatible tools',
                  onPressed: onDetectionRequested,
                ),
              ),
              
              const SizedBox(width: SpacingTokens.componentSpacing),
              
              // Smart Suggestions - AI-powered recommendations
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.lightbulb,
                  label: 'Get Suggestions',
                  description: 'AI-powered integration recommendations',
                  onPressed: onSuggestionsRequested,
                ),
              ),
              
              // Expert Mode Actions
              if (isExpertMode) ...[
                const SizedBox(width: SpacingTokens.componentSpacing),
                
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.file_upload,
                    label: 'Import Config',
                    description: 'Import existing configuration',
                    onPressed: onImportRequested,
                  ),
                ),
              ],
            ],
          ),
          
          // Secondary Actions Row (Expert Mode)
          if (isExpertMode) ...[
            const SizedBox(height: SpacingTokens.componentSpacing),
            _buildSecondaryActions(colors, ref),
          ],
        ],
      ),
    );
  }

  Widget _buildSecondaryActions(ThemeColors colors, WidgetRef ref) {
    return Row(
      children: [
        // Bulk Operations
        _SecondaryActionButton(
          icon: Icons.checklist,
          label: 'Bulk Actions',
          onPressed: () => _showBulkActions(ref),
        ),
        
        const SizedBox(width: SpacingTokens.iconSpacing),
        
        // Health Check
        _SecondaryActionButton(
          icon: Icons.health_and_safety,
          label: 'Health Check',
          onPressed: () => _runHealthCheck(ref),
        ),
        
        const SizedBox(width: SpacingTokens.iconSpacing),
        
        // Export/Backup
        _SecondaryActionButton(
          icon: Icons.backup,
          label: 'Backup Config',
          onPressed: () => _exportConfiguration(ref),
        ),
        
        const Spacer(),
        
        // Quick Stats
        _buildQuickStats(colors, ref),
      ],
    );
  }

  Widget _buildQuickStats(ThemeColors colors, WidgetRef ref) {
    // TODO: Get real stats from integration service
    return Row(
      children: [
        _StatChip(
          label: 'Active',
          value: '12',
          color: colors.success ?? colors.primary,
        ),
        const SizedBox(width: SpacingTokens.iconSpacing),
        _StatChip(
          label: 'Issues',
          value: '2',
          color: colors.warning ?? colors.primary,
        ),
      ],
    );
  }

  void _showBulkActions(WidgetRef ref) {
    // TODO: Implement bulk operations dialog
  }

  void _runHealthCheck(WidgetRef ref) {
    // TODO: Implement health check functionality
  }

  void _exportConfiguration(WidgetRef ref) {
    // TODO: Implement configuration export
  }
}

/// Primary action button with prominent styling and description
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.description,
    this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        child: Container(
          padding: const EdgeInsets.all(SpacingTokens.componentSpacing),
          decoration: BoxDecoration(
            color: isPrimary 
              ? colors.primary.withValues(alpha: 0.1)
              : colors.surfaceVariant,
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            border: Border.all(
              color: isPrimary ? colors.primary : colors.border,
              width: isPrimary ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(SpacingTokens.iconSpacing),
                decoration: BoxDecoration(
                  color: isPrimary 
                    ? colors.primary
                    : colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isPrimary 
                    ? colors.onPrimary
                    : colors.primary,
                ),
              ),
              
              const SizedBox(height: SpacingTokens.iconSpacing),
              
              // Label
              Text(
                label,
                style: TextStyles.bodyLarge.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: SpacingTokens.xs_precise),
              
              // Description
              Text(
                description,
                style: TextStyles.caption.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Secondary action button for expert mode additional actions
class _SecondaryActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _SecondaryActionButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.componentSpacing,
            vertical: SpacingTokens.iconSpacing,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: SpacingTokens.xs_precise),
              Text(
                label,
                style: TextStyles.caption.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small statistical chip for quick stats display
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.iconSpacing,
        vertical: SpacingTokens.xs_precise,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: SpacingTokens.xs_precise),
          Text(
            label,
            style: TextStyles.caption.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}