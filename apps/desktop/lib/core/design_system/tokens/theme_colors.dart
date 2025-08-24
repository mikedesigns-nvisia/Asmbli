import 'package:flutter/material.dart';

// Theme-aware color provider - USE THIS INSTEAD OF SemanticColors
class ThemeColors {
 final BuildContext context;
 final ThemeData theme;
 
 ThemeColors(this.context) : theme = Theme.of(context);
 
 bool get isDark => theme.brightness == Brightness.dark;
 
 // Background colors
 Color get background => theme.scaffoldBackgroundColor;
 Color get surface => theme.colorScheme.surface;
 Color get surfaceVariant => theme.colorScheme.surfaceVariant;
 Color get surfaceSecondary => theme.colorScheme.secondary;
 
 // Enhanced background gradients that get darker towards edges
 Color get backgroundGradientStart => isDark 
 ? Color(0xFF142019) // Lighter forest center
 : Color(0xFFF8FCFA); // Lighter mint center
 
 Color get backgroundGradientMiddle => isDark 
 ? Color(0xFF0F1C14) // Main forest
 : Color(0xFFF5FBF8); // Main mint
 
 Color get backgroundGradientEnd => isDark 
 ? Color(0xFF0A140F) // Darker forest edges
 : const Color(0xFFE8F3ED); // Darker mint edges
 
 // Text colors
 Color get onSurface => theme.colorScheme.onSurface;
 Color get onSurfaceVariant => theme.colorScheme.onSurfaceVariant;
 Color get onBackground => theme.colorScheme.onBackground;
 Color get onSurfaceSecondary => theme.colorScheme.onSurfaceVariant;
 
 // Primary colors
 Color get primary => theme.colorScheme.primary;
 Color get onPrimary => theme.colorScheme.onPrimary;
 
 // Accent colors
 Color get accent => theme.colorScheme.tertiary;
 Color get onAccent => theme.colorScheme.onTertiary;
 
 // Border colors
 Color get border => theme.colorScheme.outline;
 Color get borderSubtle => theme.colorScheme.outline.withValues(alpha: 0.5);
 
 // Semantic colors
 Color get success => isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
 Color get warning => const Color(0xFFFAAF00);
 Color get error => theme.colorScheme.error;
 Color get info => isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
 
 // Interactive states
 Color get hover => primary.withValues(alpha: 0.04);
 Color get pressed => primary.withValues(alpha: 0.08);
 Color get focus => primary.withValues(alpha: 0.12);
 
 // Special colors
 Color get headerBackground => isDark 
 ? const Color(0x99142019) // Semi-transparent dark forest
 : const Color(0x80FFFFFF); // Semi-transparent white
 
 Color get headerBorder => border.withValues(alpha: 0.3);
 
 Color get cardBackground => surface;
 Color get cardBorder => border.withValues(alpha: 0.5);
 
 Color get inputBackground => isDark
 ? const Color(0xFF142019)
 : const Color(0xFFD3E8DC);
 
 Color get mutedForeground => onSurfaceVariant;
}