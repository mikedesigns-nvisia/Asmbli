import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_system/design_system.dart';
import '../../../../../core/services/theme_service.dart';
import '../adaptive_integration_router.dart';

/// Quick Settings Panel - Right sidebar with most common settings
class QuickSettingsPanel extends ConsumerWidget {
  const QuickSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ThemeColors(context);

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.pageHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel Header
          Text(
            'Quick Settings',
            style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: SpacingTokens.componentSpacing),
          
          // Quick Settings Cards
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildAppearanceCard(colors, ref),
                  const SizedBox(height: SpacingTokens.componentSpacing),
                  _buildIntegrationCard(colors, ref),
                  const SizedBox(height: SpacingTokens.componentSpacing),
                  _buildSystemCard(colors),
                  const SizedBox(height: SpacingTokens.componentSpacing),
                  _buildHelpCard(colors),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceCard(ThemeColors colors, WidgetRef ref) {
    final currentThemeMode = ref.watch(themeServiceProvider);
    final themeService = ref.read(themeServiceProvider.notifier);

    return _QuickSettingsCard(
      title: 'Appearance',
      icon: Icons.palette,
      color: colors.primary,
      children: [
        _QuickToggle(
          label: 'Dark Mode',
          value: currentThemeMode == ThemeMode.dark,
          onChanged: (value) {
            themeService.setTheme(value ? ThemeMode.dark : ThemeMode.light);
          },
        ),
        const SizedBox(height: SpacingTokens.componentSpacing),
        _QuickSlider(
          label: 'UI Scale',
          value: 1.0,
          min: 0.8,
          max: 1.4,
          onChanged: (value) {
            // UI scaling would be implemented through theme service
            // For now, this shows the interaction pattern
          },
        ),
      ],
    );
  }

  Widget _buildIntegrationCard(ThemeColors colors, WidgetRef ref) {
    return _QuickSettingsCard(
      title: 'Integration Experience',
      icon: Icons.hub,
      color: colors.accent,
      children: const [
        IntegrationExperienceToggle(),
      ],
    );
  }

  Widget _buildSystemCard(ThemeColors colors) {
    return _QuickSettingsCard(
      title: 'System',
      icon: Icons.computer,
      color: colors.info,
      children: [
        _QuickToggle(
          label: 'Start with System',
          value: false,
          onChanged: (value) {
            // Desktop autostart functionality would be implemented here
            // This would integrate with system-specific APIs
          },
        ),
        const SizedBox(height: SpacingTokens.componentSpacing),
        _QuickToggle(
          label: 'Minimize to Tray',
          value: true,
          onChanged: (value) {
            // System tray behavior would be configured here
            // This would integrate with desktop window management
          },
        ),
        const SizedBox(height: SpacingTokens.componentSpacing),
        _QuickAction(
          label: 'Check for Updates',
          icon: Icons.update,
          onPressed: () {
            // Check for updates functionality would go here
          },
        ),
      ],
    );
  }

  Widget _buildHelpCard(ThemeColors colors) {
    return _QuickSettingsCard(
      title: 'Help & Support',
      icon: Icons.help,
      color: colors.success,
      children: [
        _QuickAction(
          label: 'Documentation',
          icon: Icons.book,
          onPressed: () {
            // Open documentation functionality would go here
          },
        ),
        const SizedBox(height: SpacingTokens.iconSpacing),
        _QuickAction(
          label: 'Keyboard Shortcuts',
          icon: Icons.keyboard,
          onPressed: () {
            // Show keyboard shortcuts functionality would go here
          },
        ),
        const SizedBox(height: SpacingTokens.iconSpacing),
        _QuickAction(
          label: 'Report Issue',
          icon: Icons.bug_report,
          onPressed: () {
            // Report issue functionality would go here
          },
        ),
      ],
    );
  }
}

class _QuickSettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _QuickSettingsCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.onSurface.withOpacity( 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(SpacingTokens.iconSpacing),
                decoration: BoxDecoration(
                  color: color.withOpacity( 0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: color,
                ),
              ),
              const SizedBox(width: SpacingTokens.componentSpacing),
              Text(
                title,
                style: TextStyles.bodyLarge.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: SpacingTokens.componentSpacing),
          
          // Card Content
          ...children,
        ],
      ),
    );
  }
}

class _QuickToggle extends StatelessWidget {
  final String label;
  final bool value;
  final Function(bool) onChanged;

  const _QuickToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _QuickSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final Function(double) onChanged;

  const _QuickSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
            ),
            Text(
              '${(value * 100).round()}%',
              style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.iconSpacing),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.iconSpacing),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: SpacingTokens.componentSpacing),
            Text(
              label,
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
            ),
            const Spacer(),
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

}