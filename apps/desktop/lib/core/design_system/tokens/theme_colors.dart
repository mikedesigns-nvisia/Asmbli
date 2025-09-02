import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Theme-aware color provider - USE THIS INSTEAD OF SemanticColors
class ThemeColors {
 final BuildContext context;
 final ThemeData theme;
 final String? _colorScheme;
 
 ThemeColors(this.context, {String? colorScheme}) 
   : theme = Theme.of(context), 
     _colorScheme = colorScheme;
     
 // Get the actual selected color scheme from the theme service
 String get _actualColorScheme {
   if (_colorScheme != null) return _colorScheme!;
   
   // Try to get the current scheme from Provider
   if (context is ConsumerWidget || context is ConsumerStatefulWidget) {
     try {
       // This is a hack - we'll need to access the provider differently
       // For now, let's determine based on theme colors
       return _detectSchemeFromTheme();
     } catch (e) {
       return 'warm-neutral';
     }
   }
   return _detectSchemeFromTheme();
 }
 
 // Detect the color scheme based on theme colors
 String _detectSchemeFromTheme() {
   final primaryColor = theme.colorScheme.primary;
   
   if (isDark) {
     // Detect based on dark mode primary colors
     if (primaryColor == const Color(0xFF60A5FA)) return 'cool-blue';
     if (primaryColor == const Color(0xFFB8E6C8)) return 'forest-green';
     if (primaryColor == const Color(0xFFD4956B)) return 'sunset-orange';
     return 'warm-neutral'; // E6C794
   } else {
     // Detect based on light mode primary colors
     if (primaryColor == const Color(0xFF1E3A8A)) return 'cool-blue';
     if (primaryColor == const Color(0xFF1E3B2B)) return 'forest-green';
     if (primaryColor == const Color(0xFF9A3412)) return 'sunset-orange';
     return 'warm-neutral'; // 8B6F47
   }
 }
 
 bool get isDark => theme.brightness == Brightness.dark;
 
 // Background colors
 Color get background => theme.scaffoldBackgroundColor;
 Color get surface => theme.colorScheme.surface;
 Color get surfaceVariant => theme.colorScheme.surfaceContainerHighest;
 Color get surfaceSecondary => theme.colorScheme.secondary;
 
 // Enhanced background gradients that get darker towards edges
 Color get backgroundGradientStart {
 final scheme = _actualColorScheme;
 
 if (isDark) {
 switch (scheme) {
 case 'cool-blue':
 return const Color(0xFF1E293B); // Darker blue center
 case 'forest-green':
 return const Color(0xFF142019); // Lighter forest center (from old mint)
 case 'sunset-orange':
 return const Color(0xFF5C2D1F); // Desaturated orange center
 default: // warm-neutral
 return const Color(0xFF3D2B1F); // Warm brown center
 }
 } else {
 switch (scheme) {
 case 'cool-blue':
 return const Color(0xFFFAFCFF); // Lighter blue center
 case 'forest-green':
 return const Color(0xFFF8FCFA); // Lighter mint center (from old mint)
 case 'sunset-orange':
 return const Color(0xFFFFFBF7); // Almost white orange center
 default: // warm-neutral
 return const Color(0xFFFCFBF9); // Lighter cream center
 }
 }
 }
 
 Color get backgroundGradientMiddle {
 final scheme = _actualColorScheme;
 
 if (isDark) {
 switch (scheme) {
 case 'cool-blue':
 return const Color(0xFF0F172A); // Main blue
 case 'forest-green':
 return const Color(0xFF0F1C14); // Main forest (from old mint)
 case 'sunset-orange':
 return const Color(0xFF4A2117); // Main desaturated orange
 default: // warm-neutral
 return const Color(0xFF2B1F14); // Main warm brown
 }
 } else {
 switch (scheme) {
 case 'cool-blue':
 return const Color(0xFFF0F9FF); // Main blue
 case 'forest-green':
 return const Color(0xFFF5FBF8); // Main mint (from old mint)
 case 'sunset-orange':
 return const Color(0xFFFFF7ED); // Main light orange
 default: // warm-neutral
 return const Color(0xFFFAF8F5); // Main warm cream
 }
 }
 }
 
 Color get backgroundGradientEnd {
 final scheme = _actualColorScheme;
 
 if (isDark) {
 switch (scheme) {
 case 'cool-blue':
 return const Color(0xFF0C1220); // Darker blue edges
 case 'forest-green':
 return const Color(0xFF0A140F); // Darker forest edges (from old mint)
 case 'sunset-orange':
 return const Color(0xFF2E1810); // Darker desaturated orange edges
 default: // warm-neutral
 return const Color(0xFF1F1611); // Darker warm brown edges
 }
 } else {
 switch (scheme) {
 case 'cool-blue':
 return const Color(0xFFE0F2FE); // Darker blue edges
 case 'forest-green':
 return const Color(0xFFE8F3ED); // Darker mint edges (from old mint)
 case 'sunset-orange':
 return const Color(0xFFFED7AA); // Darker orange edges
 default: // warm-neutral
 return const Color(0xFFF0E6D6); // Darker cream edges
 }
 }
 }
 
 // Text colors
 Color get onSurface => theme.colorScheme.onSurface;
 Color get onSurfaceVariant => theme.colorScheme.onSurfaceVariant;
 Color get onBackground => theme.colorScheme.onSurface;
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
 Color get headerBackground {
 final scheme = _actualColorScheme;
 
 if (isDark) {
 switch (scheme) {
 case 'cool-blue':
 return const Color(0xFF1E293B).withValues(alpha: 0.90); // Blue navigation background
 case 'forest-green':
 return const Color(0xFF1F3325).withValues(alpha: 0.90); // Forest navigation background 
 case 'sunset-orange':
 return const Color(0xFF664029).withValues(alpha: 0.90); // Warm orange navigation background
 default: // warm-neutral
 return const Color(0xFF423126).withValues(alpha: 0.90); // Warm brown navigation background
 }
 } else {
 return const Color(0x80FFFFFF); // Semi-transparent white
 }
 }
 
 Color get headerBorder => border.withValues(alpha: 0.3);
 
 Color get cardBackground => surface;
 Color get cardBorder => border.withValues(alpha: 0.5);
 
 Color get inputBackground => isDark
 ? backgroundGradientStart
 : surfaceVariant;
 
 Color get mutedForeground => onSurfaceVariant;
}