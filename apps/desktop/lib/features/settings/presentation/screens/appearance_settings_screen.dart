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
  double _uiScale = 1.0;
  bool _compactMode = false;
  bool _showAnimations = true;
  String _selectedColorScheme = AppColorSchemes.warmNeutral;
  String _selectedFont = 'space-grotesk';

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
            AppNavigationBar(currentRoute: AppRoutes.settings),
            _buildHeader(colors),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildMainContent(colors, currentThemeMode, themeService),
                  ),
                  SizedBox(
                    width: 300,
                    child: _buildPreviewPanel(colors),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Container(
      padding: EdgeInsets.all(SpacingTokens.pageHorizontal),
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
          SizedBox(width: SpacingTokens.componentSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appearance',
                  style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
                ),
                SizedBox(height: SpacingTokens.xs_precise),
                Text(
                  'Customize the look and feel of AgentEngine',
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

  Widget _buildMainContent(ThemeColors colors, ThemeMode currentThemeMode, ThemeService themeService) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(SpacingTokens.pageHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThemeSection(colors, currentThemeMode, themeService),
          SizedBox(height: SpacingTokens.sectionSpacing),
          _buildColorSchemeSection(colors),
          SizedBox(height: SpacingTokens.sectionSpacing),
          _buildTypographySection(colors),
          SizedBox(height: SpacingTokens.sectionSpacing),
          _buildLayoutSection(colors),
          SizedBox(height: SpacingTokens.sectionSpacing),
          _buildAnimationSection(colors),
        ],
      ),
    );
  }

  Widget _buildThemeSection(ThemeColors colors, ThemeMode currentThemeMode, ThemeService themeService) {
    return AsmblCard(
      child: Padding(
        padding: EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(SpacingTokens.iconSpacing),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  ),
                  child: Icon(Icons.brightness_6, color: colors.primary, size: 20),
                ),
                SizedBox(width: SpacingTokens.componentSpacing),
                Text(
                  'Theme Mode',
                  style: TextStyles.cardTitle.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: SpacingTokens.componentSpacing),
            Text(
              'Choose between light, dark, or system-based theme',
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            ),
            SizedBox(height: SpacingTokens.componentSpacing),
            Row(
              children: [
                Expanded(child: _buildThemeOption('Light', ThemeMode.light, Icons.light_mode, currentThemeMode, themeService, colors)),
                SizedBox(width: SpacingTokens.componentSpacing),
                Expanded(child: _buildThemeOption('Dark', ThemeMode.dark, Icons.dark_mode, currentThemeMode, themeService, colors)),
                SizedBox(width: SpacingTokens.componentSpacing),
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
        padding: EdgeInsets.all(SpacingTokens.componentSpacing),
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
            SizedBox(height: SpacingTokens.iconSpacing),
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

  Widget _buildColorSchemeSection(ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(SpacingTokens.iconSpacing),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  ),
                  child: Icon(Icons.palette, color: colors.accent, size: 20),
                ),
                SizedBox(width: SpacingTokens.componentSpacing),
                Text(
                  'Color Scheme',
                  style: TextStyles.cardTitle.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: SpacingTokens.componentSpacing),
            Text(
              'Select your preferred color palette (currently using warm neutral)',
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            ),
            SizedBox(height: SpacingTokens.componentSpacing),
            _buildColorSchemeGrid(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSchemeGrid(ThemeColors colors) {
    final schemes = [
      ColorSchemeOption('warm-neutral', 'Warm Neutral', [Color(0xFF3D3328), Color(0xFF736B5F), Color(0xFFFBF9F5)]),
      ColorSchemeOption('cool-blue', 'Cool Blue', [Color(0xFF1E3A8A), Color(0xFF3B82F6), Color(0xFFF0F9FF)]),
      ColorSchemeOption('forest-green', 'Forest Green', [Color(0xFF14532D), Color(0xFF22C55E), Color(0xFFF0FDF4)]),
      ColorSchemeOption('sunset-orange', 'Sunset Orange', [Color(0xFF9A3412), Color(0xFFF97316), Color(0xFFFFF7ED)]),
    ];

    return Wrap(
      spacing: SpacingTokens.componentSpacing,
      runSpacing: SpacingTokens.componentSpacing,
      children: schemes.map((scheme) {
        final isSelected = _selectedColorScheme == scheme.id;
        return InkWell(
          onTap: () {
            setState(() => _selectedColorScheme = scheme.id);
            ref.read(themeServiceProvider.notifier).setColorScheme(scheme.id);
          },
          borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          child: Container(
            width: 140,
            padding: EdgeInsets.all(SpacingTokens.componentSpacing),
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
                    margin: EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                      border: Border.all(color: colors.border.withValues(alpha: 0.3)),
                    ),
                  )).toList(),
                ),
                SizedBox(height: SpacingTokens.iconSpacing),
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

  Widget _buildTypographySection(ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(SpacingTokens.iconSpacing),
                  decoration: BoxDecoration(
                    color: colors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  ),
                  child: Icon(Icons.font_download, color: colors.info, size: 20),
                ),
                SizedBox(width: SpacingTokens.componentSpacing),
                Text(
                  'Typography',
                  style: TextStyles.cardTitle.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: SpacingTokens.componentSpacing),
            Text(
              'Adjust font family and text display preferences',
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            ),
            SizedBox(height: SpacingTokens.componentSpacing),
            _buildFontSelector(colors),
            SizedBox(height: SpacingTokens.componentSpacing),
            _buildTextSizeSlider(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSelector(ThemeColors colors) {
    final fonts = [
      FontOption('space-grotesk', 'Space Grotesk', 'Modern geometric sans-serif'),
      FontOption('inter', 'Inter', 'Clean and readable'),
      FontOption('poppins', 'Poppins', 'Friendly and approachable'),
      FontOption('roboto', 'Roboto', 'Google\'s material design font'),
    ];

    return DropdownButtonFormField<String>(
      value: _selectedFont,
      decoration: InputDecoration(
        labelText: 'Font Family',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        ),
      ),
      items: fonts.map((font) => DropdownMenuItem(
        value: font.id,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(font.name, style: TextStyles.bodyMedium),
            Text(font.description, style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant)),
          ],
        ),
      )).toList(),
      onChanged: (value) => setState(() => _selectedFont = value!),
    );
  }

  Widget _buildTextSizeSlider(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Text Size',
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
            ),
            Text(
              '${(_uiScale * 100).round()}%',
              style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
        SizedBox(height: SpacingTokens.iconSpacing),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: _uiScale,
            min: 0.8,
            max: 1.4,
            divisions: 12,
            onChanged: (value) => setState(() => _uiScale = value),
          ),
        ),
      ],
    );
  }

  Widget _buildLayoutSection(ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(SpacingTokens.iconSpacing),
                  decoration: BoxDecoration(
                    color: colors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  ),
                  child: Icon(Icons.view_compact, color: colors.warning, size: 20),
                ),
                SizedBox(width: SpacingTokens.componentSpacing),
                Text(
                  'Layout',
                  style: TextStyles.cardTitle.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: SpacingTokens.componentSpacing),
            Text(
              'Customize the layout density and spacing',
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            ),
            SizedBox(height: SpacingTokens.componentSpacing),
            _buildToggleSetting(
              'Compact Mode',
              'Reduce spacing between elements',
              _compactMode,
              (value) => setState(() => _compactMode = value),
              colors,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimationSection(ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(SpacingTokens.iconSpacing),
                  decoration: BoxDecoration(
                    color: colors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  ),
                  child: Icon(Icons.animation, color: colors.success, size: 20),
                ),
                SizedBox(width: SpacingTokens.componentSpacing),
                Text(
                  'Animations',
                  style: TextStyles.cardTitle.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: SpacingTokens.componentSpacing),
            Text(
              'Control interface animations and transitions',
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            ),
            SizedBox(height: SpacingTokens.componentSpacing),
            _buildToggleSetting(
              'Show Animations',
              'Enable smooth transitions and hover effects',
              _showAnimations,
              (value) => setState(() => _showAnimations = value),
              colors,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSetting(String title, String subtitle, bool value, Function(bool) onChanged, ThemeColors colors) {
    return Row(
      children: [
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
                style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
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

  Widget _buildPreviewPanel(ThemeColors colors) {
    return Container(
      padding: EdgeInsets.all(SpacingTokens.pageHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview',
            style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
          ),
          SizedBox(height: SpacingTokens.componentSpacing),
          AsmblCard(
            child: Padding(
              padding: EdgeInsets.all(SpacingTokens.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sample Content',
                    style: TextStyles.cardTitle.copyWith(
                      color: colors.onSurface,
                      fontSize: 18 * _uiScale,
                    ),
                  ),
                  SizedBox(height: SpacingTokens.componentSpacing),
                  Text(
                    'This is how your text will look with the current settings applied. The preview updates in real-time as you make changes.',
                    style: TextStyles.bodyMedium.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 14 * _uiScale,
                    ),
                  ),
                  SizedBox(height: SpacingTokens.componentSpacing),
                  AsmblButton.primary(
                    text: 'Sample Button',
                    onPressed: () {},
                  ),
                  SizedBox(height: SpacingTokens.componentSpacing),
                  Container(
                    padding: EdgeInsets.all(SpacingTokens.componentSpacing),
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    ),
                    child: Text(
                      'Code example with ${_selectedFont} font family',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: colors.onSurface,
                        fontSize: 12 * _uiScale,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: SpacingTokens.sectionSpacing),
          Text(
            'Theme Info',
            style: TextStyles.bodyLarge.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: SpacingTokens.componentSpacing),
          _buildInfoRow('Color Scheme', _selectedColorScheme.replaceAll('-', ' ').toUpperCase(), colors),
          _buildInfoRow('Font Family', _selectedFont.replaceAll('-', ' ').toUpperCase(), colors),
          _buildInfoRow('UI Scale', '${(_uiScale * 100).round()}%', colors),
          _buildInfoRow('Compact Mode', _compactMode ? 'ON' : 'OFF', colors),
          _buildInfoRow('Animations', _showAnimations ? 'ENABLED' : 'DISABLED', colors),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeColors colors) {
    return Padding(
      padding: EdgeInsets.only(bottom: SpacingTokens.iconSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
          ),
          Text(
            value,
            style: TextStyles.caption.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _resetToDefaults() {
    setState(() {
      _uiScale = 1.0;
      _compactMode = false;
      _showAnimations = true;
      _selectedColorScheme = 'warm-neutral';
      _selectedFont = 'space-grotesk';
    });
    
    final themeService = ref.read(themeServiceProvider.notifier);
    themeService.setTheme(ThemeMode.system);
  }
}

class FontOption {
  final String id;
  final String name;
  final String description;

  FontOption(this.id, this.name, this.description);
}