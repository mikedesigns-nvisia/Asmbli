import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/theme/color_schemes.dart';

class AppearanceSettingsScreen extends ConsumerStatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  ConsumerState<AppearanceSettingsScreen> createState() => _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends ConsumerState<AppearanceSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeServiceProvider);
    final colors = ThemeColors(context, colorScheme: themeState.colorScheme);
    final themeService = ref.read(themeServiceProvider.notifier);
    final currentThemeMode = themeState.mode;

    return Scaffold(
      backgroundColor: colors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.background,
              colors.background.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            const AppNavigationBar(currentRoute: AppRoutes.settings),
            _buildHeader(colors),
            Expanded(
              child: _buildMainContent(colors, currentThemeMode, themeService, themeState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.pageHorizontal),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(color: colors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back, color: colors.onSurface),
          ),
          const SizedBox(width: SpacingTokens.componentSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appearance',
                  style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
                ),
                const SizedBox(height: SpacingTokens.xs_precise),
                Text(
                  'Customize the look and feel of Asmbli',
                  style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          AsmblButton.secondary(
            text: 'Reset to Default',
            onPressed: _resetToDefaults,
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(ThemeColors colors, ThemeMode currentThemeMode, ThemeService themeService, ThemeState themeState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(SpacingTokens.pageHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThemeSection(colors, currentThemeMode, themeService),
          const SizedBox(height: SpacingTokens.sectionSpacing),
          _buildColorSchemeSection(colors, themeState),
        ],
      ),
    );
  }

  Widget _buildThemeSection(ThemeColors colors, ThemeMode currentThemeMode, ThemeService themeService) {
    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(SpacingTokens.iconSpacing),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  ),
                  child: Icon(Icons.brightness_6, color: colors.primary, size: 20),
                ),
                const SizedBox(width: SpacingTokens.componentSpacing),
                Text(
                  'Theme Mode',
                  style: TextStyles.cardTitle.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.componentSpacing),
            Text(
              'Choose between light, dark, or system-based theme',
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: SpacingTokens.componentSpacing),
            Row(
              children: [
                Expanded(child: _buildThemeOption('Light', ThemeMode.light, Icons.light_mode, currentThemeMode, themeService, colors)),
                const SizedBox(width: SpacingTokens.componentSpacing),
                Expanded(child: _buildThemeOption('Dark', ThemeMode.dark, Icons.dark_mode, currentThemeMode, themeService, colors)),
                const SizedBox(width: SpacingTokens.componentSpacing),
                Expanded(child: _buildThemeOption('System', ThemeMode.system, Icons.auto_mode, currentThemeMode, themeService, colors)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(String label, ThemeMode mode, IconData icon, ThemeMode currentMode, ThemeService themeService, ThemeColors colors) {
    final isSelected = currentMode == mode;
    return InkWell(
      onTap: () => themeService.setTheme(mode),
      borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.componentSpacing),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary.withValues(alpha: 0.1) : colors.surfaceVariant.withValues(alpha: 0.3),
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
            const SizedBox(height: SpacingTokens.iconSpacing),
            Text(
              label,
              style: TextStyles.bodyMedium.copyWith(
                color: isSelected ? colors.primary : colors.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSchemeSection(ThemeColors colors, ThemeState themeState) {
    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(SpacingTokens.iconSpacing),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  ),
                  child: Icon(Icons.palette, color: colors.accent, size: 20),
                ),
                const SizedBox(width: SpacingTokens.componentSpacing),
                Text(
                  'Color Scheme',
                  style: TextStyles.cardTitle.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.componentSpacing),
            Text(
              'Select your preferred color palette (currently using ${_getCurrentThemeName(themeState.colorScheme)})',
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: SpacingTokens.componentSpacing),
            _buildColorSchemeGrid(colors, themeState),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSchemeGrid(ThemeColors colors, ThemeState themeState) {
    final schemes = AppColorSchemes.all;

    return Wrap(
      spacing: SpacingTokens.componentSpacing,
      runSpacing: SpacingTokens.componentSpacing,
      children: schemes.map((scheme) {
        final isSelected = themeState.colorScheme == scheme.id;
        return InkWell(
          onTap: () {
            ref.read(themeServiceProvider.notifier).setColorScheme(scheme.id);
          },
          borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          child: Container(
            width: 140,
            padding: const EdgeInsets.all(SpacingTokens.componentSpacing),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              border: Border.all(
                color: isSelected ? colors.primary : colors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: scheme.colors.map((color) => Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                      border: Border.all(color: colors.border.withValues(alpha: 0.3)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: SpacingTokens.iconSpacing),
                Text(
                  scheme.name,
                  style: TextStyles.caption.copyWith(
                    color: isSelected ? colors.primary : colors.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }


  void _resetToDefaults() {
    final themeService = ref.read(themeServiceProvider.notifier);
    themeService.setTheme(ThemeMode.system);
    themeService.setColorScheme(AppColorSchemes.warmNeutral);
  }

  String _getCurrentThemeName(String colorSchemeId) {
    final schemes = AppColorSchemes.all;
    final scheme = schemes.firstWhere(
      (s) => s.id == colorSchemeId,
      orElse: () => schemes.first,
    );
    return scheme.name.toLowerCase();
  }
}

