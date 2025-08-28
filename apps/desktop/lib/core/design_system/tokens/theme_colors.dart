import 'package:flutter/material.dart';
import '../../../core/services/theme_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Theme-aware color provider - USE THIS INSTEAD OF SemanticColors
class ThemeColors {
 final BuildContext context;
 final ThemeData theme;
 final String? _colorScheme;
 
 ThemeColors(this.context, {String? colorScheme}) 
   : theme = Theme.of(context), 
     _colorScheme = colorScheme;
 
 bool get isDark => theme.brightness == Brightness.dark;
 
 // Background colors
 Color get background => theme.scaffoldBackgroundColor;
 Color get surface => theme.colorScheme.surface;
 Color get surfaceVariant => theme.colorScheme.surfaceVariant;
 Color get surfaceSecondary => theme.colorScheme.secondary;
 
 // Enhanced background gradients that get darker towards edges
 Color get backgroundGradientStart {
 final scheme = _colorScheme ?? 'mint-green';
 
 if (isDark) {
 switch (scheme) {
 case 'cool-blue':
 return Color(0xFF1E293B); // Darker blue center
 case 'forest-green':
 return Color(0xFF1F5A32); // Lighter forest center
 case 'sunset-orange':
 return Color(0xFF9A3412); // Lighter orange center
 default: // mint-green
 return Color(0xFF142019); // Lighter mint-forest center
 }
 } else {
 switch (scheme) {
 case 'cool-blue':
 return Color(0xFFFAFCFF); // Lighter blue center
 case 'forest-green':
 return Color(0xFFFAFDFB); // Almost white green center
 case 'sunset-orange':
 return Color(0xFFFFFBF7); // Almost white orange center
 default: // mint-green
 return Color(0xFFF8FCFA); // Lighter mint center
 }
 }
 }
 
 Color get backgroundGradientMiddle {
 final scheme = _colorScheme ?? 'mint-green';
 
 if (isDark) {
 switch (scheme) {
 case 'cool-blue':
 return Color(0xFF0F172A); // Main blue
 case 'forest-green':
 return Color(0xFF14532D); // Main forest
 case 'sunset-orange':
 return Color(0xFF7C2D12); // Main orange
 default: // mint-green
 return Color(0xFF0F1C14); // Main forest
 }
 } else {
 switch (scheme) {
 case 'cool-blue':
 return Color(0xFFF0F9FF); // Main blue
 case 'forest-green':
 return Color(0xFFF0FDF4); // Main light green
 case 'sunset-orange':
 return Color(0xFFFFF7ED); // Main light orange
 default: // mint-green
 return Color(0xFFF5FBF8); // Main mint
 }
 }
 }
 
 Color get backgroundGradientEnd {
 final scheme = _colorScheme ?? 'mint-green';
 
 if (isDark) {
 switch (scheme) {
 case 'cool-blue':
 return Color(0xFF0C1220); // Darker blue edges
 case 'forest-green':
 return Color(0xFF0F2419); // Darker forest edges
 case 'sunset-orange':
 return Color(0xFF571A08); // Darker orange edges
 default: // mint-green
 return Color(0xFF0A140F); // Darker forest edges
 }
 } else {
 switch (scheme) {
 case 'cool-blue':
 return Color(0xFFE0F2FE); // Darker blue edges
 case 'forest-green':
 return Color(0xFFDCFCE7); // Darker green edges
 case 'sunset-orange':
 return Color(0xFFFED7AA); // Darker orange edges
 default: // mint-green
 return Color(0xFFE8F3ED); // Darker mint edges
 }
 }
 }
 
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
 Color get headerBackground {
 if (isDark) {
 return backgroundGradientStart.withValues(alpha: 0.6);
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