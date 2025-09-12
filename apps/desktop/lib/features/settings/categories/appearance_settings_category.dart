import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/design_system.dart';
import '../../../core/theme/color_schemes.dart';
import '../../../core/services/theme_service.dart';
import '../components/settings_field.dart';
import '../providers/settings_provider.dart';

/// Appearance settings category - theme and display configuration
class AppearanceSettingsCategory extends ConsumerWidget {
  const AppearanceSettingsCategory({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ThemeColors(context);
    final themeState = ref.watch(themeServiceProvider);
    final appearanceSettings = ref.watch(appearanceSettingsProvider);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Theme mode section
              SettingsSection(
                title: 'Theme Mode',
                description: 'Choose between light, dark, or system theme',
                children: [
                  _buildThemeModeSelector(themeState, ref, colors),
                ],
              ),
              
              const SizedBox(height: SpacingTokens.xxl),
              
              // Color scheme section
              SettingsSection(
                title: 'Color Scheme',
                description: 'Select your preferred color palette',
                children: [
                  _buildColorSchemeSelector(themeState, ref, colors),
                ],
              ),
              
              const SizedBox(height: SpacingTokens.xxl),
              
              // Display options section
              SettingsSection(
                title: 'Display Options',
                description: 'Customize your interface display settings',
                children: [
                  SettingsToggle(
                    label: 'Compact Mode',
                    description: 'Reduce spacing and padding for a denser interface',
                    value: appearanceSettings.compactMode,
                    onChanged: (value) {
                      // Handle compact mode toggle
                    },
                  ),
                  const SizedBox(height: SpacingTokens.md),
                  _buildFontSizeSlider(appearanceSettings, colors),
                ],
              ),
              
              const SizedBox(height: SpacingTokens.xxl),
              
              // Preview section
              SettingsSection(
                title: 'Preview',
                description: 'Preview your current theme and color settings',
                children: [
                  _buildThemePreview(colors),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build theme mode selector
  Widget _buildThemeModeSelector(ThemeState themeState, WidgetRef ref, ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme Mode',
              style: TextStyles.labelMedium.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: SpacingTokens.md),
            Row(
              children: [
                Expanded(
                  child: _buildThemeModeOption(
                    'Light',
                    Icons.light_mode,
                    ThemeMode.light,
                    themeState.themeMode,
                    ref,
                    colors,
                  ),
                ),
                const SizedBox(width: SpacingTokens.sm),
                Expanded(
                  child: _buildThemeModeOption(
                    'Dark',
                    Icons.dark_mode,
                    ThemeMode.dark,
                    themeState.themeMode,
                    ref,
                    colors,
                  ),
                ),
                const SizedBox(width: SpacingTokens.sm),
                Expanded(
                  child: _buildThemeModeOption(
                    'System',
                    Icons.settings_brightness,
                    ThemeMode.system,
                    themeState.themeMode,
                    ref,
                    colors,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build individual theme mode option
  Widget _buildThemeModeOption(
    String label,
    IconData icon,
    ThemeMode mode,
    ThemeMode currentMode,
    WidgetRef ref,
    ThemeColors colors,
  ) {
    final isSelected = mode == currentMode;
    
    return GestureDetector(
      onTap: () async {
        try {
          await ref.read(themeServiceProvider.notifier).setTheme(mode);
        } catch (e) {
          // Handle error if needed
        }
      },
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.md),
        decoration: BoxDecoration(
          color: isSelected 
              ? colors.primary.withOpacity(0.1)
              : colors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? colors.primary : colors.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: SpacingTokens.sm),
            Text(
              label,
              style: TextStyles.labelMedium.copyWith(
                color: isSelected ? colors.primary : colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build color scheme selector
  Widget _buildColorSchemeSelector(ThemeState themeState, WidgetRef ref, ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Color Scheme',
              style: TextStyles.labelMedium.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: SpacingTokens.md),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: SpacingTokens.sm,
                mainAxisSpacing: SpacingTokens.sm,
                childAspectRatio: 3,
              ),
              itemCount: AppColorSchemes.all.length,
              itemBuilder: (context, index) {
                final scheme = AppColorSchemes.all[index];
                return _buildColorSchemeOption(
                  scheme,
                  themeState.colorScheme,
                  ref,
                  colors,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build individual color scheme option
  Widget _buildColorSchemeOption(
    AppColorScheme scheme,
    String currentScheme,
    WidgetRef ref,
    ThemeColors colors,
  ) {
    final isSelected = scheme.id == currentScheme;
    
    return GestureDetector(
      onTap: () async {
        try {
          await ref.read(themeServiceProvider.notifier).setColorScheme(scheme.id);
        } catch (e) {
          // Handle error if needed
        }
      },
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.sm),
        decoration: BoxDecoration(
          color: isSelected 
              ? colors.primary.withOpacity(0.1)
              : colors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Color preview circles
            SizedBox(
              width: 40,
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: scheme.lightColorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.xs),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: scheme.lightColorScheme.tertiary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: SpacingTokens.sm),
            Expanded(
              child: Text(
                scheme.name,
                style: TextStyles.labelMedium.copyWith(
                  color: isSelected ? colors.primary : colors.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                color: colors.primary,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  /// Build font size slider
  Widget _buildFontSizeSlider(dynamic appearanceSettings, ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Font Size',
                  style: TextStyles.labelMedium.copyWith(color: colors.onSurface),
                ),
                const Spacer(),
                Text(
                  '${appearanceSettings.fontSize.round()}px',
                  style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.md),
            Slider(
              value: appearanceSettings.fontSize,
              min: 12.0,
              max: 20.0,
              divisions: 8,
              activeColor: colors.primary,
              onChanged: (value) {
                // Handle font size change
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Small',
                  style: TextStyles.captionMedium.copyWith(color: colors.onSurfaceVariant),
                ),
                Text(
                  'Large',
                  style: TextStyles.captionMedium.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build theme preview
  Widget _buildThemePreview(ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme Preview',
              style: TextStyles.headingSmall.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: SpacingTokens.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(SpacingTokens.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.backgroundGradientStart,
                    colors.backgroundGradientMiddle,
                    colors.backgroundGradientEnd,
                  ],
                ),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                        ),
                        child: Icon(
                          Icons.palette,
                          color: colors.onPrimary,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: SpacingTokens.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sample Card',
                            style: TextStyles.labelLarge.copyWith(color: colors.onSurface),
                          ),
                          Text(
                            'This is how your theme looks',
                            style: TextStyles.captionMedium.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.md),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 32,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                          ),
                          child: Center(
                            child: Text(
                              'Primary',
                              style: TextStyles.labelMedium.copyWith(color: colors.onPrimary),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: SpacingTokens.sm),
                      Expanded(
                        child: Container(
                          height: 32,
                          decoration: BoxDecoration(
                            color: colors.accent,
                            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                          ),
                          child: Center(
                            child: Text(
                              'Accent',
                              style: TextStyles.labelMedium.copyWith(color: colors.onSurface),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}