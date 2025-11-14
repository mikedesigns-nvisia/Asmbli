import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../tokens/spacing_tokens.dart';
import '../tokens/theme_colors.dart';
import '../../services/theme_service.dart';
import '../../theme/color_schemes.dart';

class ThemeToggle extends ConsumerStatefulWidget {
  const ThemeToggle({super.key});

  @override
  ConsumerState<ThemeToggle> createState() => _ThemeToggleState();
}

class _ThemeToggleState extends ConsumerState<ThemeToggle> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggleOverlay() {
    if (_overlayEntry != null) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    final colors = ThemeColors(context);
    final themeService = ref.read(themeServiceProvider.notifier);
    final themeState = ref.read(themeServiceProvider);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 200,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(-170, 45), // Position below and to the left
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            color: colors.surface,
            child: Container(
              padding: const EdgeInsets.all(SpacingTokens.sm),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border.withValues(alpha: 0.5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: AppColorSchemes.all.map((scheme) {
                  final isSelected = scheme.id == themeState.colorScheme;
                  
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        themeService.setColorScheme(scheme.id);
                        _removeOverlay();
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SpacingTokens.sm,
                          vertical: SpacingTokens.xs,
                        ),
                        child: Row(
                          children: [
                            // Color preview circles
                            Row(
                              children: scheme.colors.take(3).map((color) {
                                return Container(
                                  width: 12,
                                  height: 12,
                                  margin: const EdgeInsets.only(right: 2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: color,
                                    border: Border.all(
                                      color: colors.border.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(width: SpacingTokens.sm),
                            Expanded(
                              child: Text(
                                scheme.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected ? colors.primary : colors.onSurface,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check,
                                size: 16,
                                color: colors.primary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final themeService = ref.watch(themeServiceProvider.notifier);
    final themeState = ref.watch(themeServiceProvider);
    
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
          color: colors.surface.withValues(alpha: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Light/Dark Mode Toggle
            _buildThemeModeToggle(colors, themeService, themeState),
            
            // Divider
            Container(
              height: 24,
              width: 1,
              color: colors.border.withValues(alpha: 0.3),
              margin: const EdgeInsets.symmetric(horizontal: 4),
            ),
            
            // Color Scheme Selector
            _buildColorSchemeSelector(colors, themeService, themeState),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeModeToggle(ThemeColors colors, ThemeService themeService, ThemeState themeState) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => themeService.toggleTheme(),
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.md,
            vertical: SpacingTokens.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                themeService.getThemeIcon(),
                size: 18,
                color: colors.onSurface,
              ),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                themeState.mode == ThemeMode.light ? 'Light' : 'Dark',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorSchemeSelector(ThemeColors colors, ThemeService themeService, ThemeState themeState) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleOverlay,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.sm,
            vertical: SpacingTokens.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Current color indicator
              _buildColorIndicator(themeState.colorScheme),
              const SizedBox(width: SpacingTokens.xs),
              Icon(
                _overlayEntry != null ? Icons.expand_less : Icons.expand_more,
                size: 16,
                color: colors.onSurface,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorIndicator(String colorSchemeId) {
    final scheme = AppColorSchemes.all.firstWhere(
      (s) => s.id == colorSchemeId,
      orElse: () => AppColorSchemes.all.first,
    );
    
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.colors.first, // Use primary color
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }

}