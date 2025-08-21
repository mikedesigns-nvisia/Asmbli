import 'package:flutter/material.dart';

// Design tokens for Banana Pudding (Light) and Midnight Mocha (Dark) themes
class ColorTokens {
  // Base Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  
  // Banana Pudding Palette (Light Theme)
  static const Color background1 = Color(0xFFFBF9F5);    // Primary background
  static const Color background2 = Color(0xFFFCFAF7);    // Secondary background/cards
  static const Color surface = Color(0xFFFCFAF7);        // Card surface
  static const Color muted = Color(0xFFF6F3EE);          // Muted background
  static const Color secondary = Color(0xFFF5F2ED);      // Secondary surface
  
  // Text Colors
  static const Color foreground = Color(0xFF3D3328);     // Primary text
  static const Color mutedForeground = Color(0xFF736B5F); // Secondary text
  
  // Primary (Dark Brown/Charcoal)
  static const Color primary = Color(0xFF3D3328);        // Primary action color
  static const Color primaryForeground = Color(0xFFFBF9F5); // Text on primary
  
  // Borders and Lines
  static const Color border = Color(0xFFE8E1D3);         // Primary border
  static const Color input = Color(0xFFE8E1D3);          // Input backgrounds
  
  // Interactive States (subtle overlays)
  static const Color hover = Color(0x0A3D3328);          // 4% primary overlay
  static const Color pressed = Color(0x143D3328);        // 8% primary overlay
  static const Color focus = Color(0x1A3D3328);          // 10% primary overlay
  
  // Semantic Colors (harmonious with your palette)
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  
  // Midnight Mocha Palette (Dark Theme)
  static const Color darkBackground1 = Color(0xFF1A1814);  // Rich mocha brown
  static const Color darkBackground2 = Color(0xFF1F1D18);  // Slightly lighter mocha
  static const Color darkSurface = Color(0xFF252319);      // Coffee surface
  static const Color darkMuted = Color(0xFF2A2820);        // Muted mocha surface
  static const Color darkBorder = Color(0xFF3D3A30);       // Warm mocha border
  
  // Midnight Mocha text (warm creams like foam on coffee)
  static const Color darkForeground = Color(0xFFFAF8F3);    // Cream foam
  static const Color darkMutedForeground = Color(0xFFB5AA9A); // Latte foam
  
  // Midnight Mocha primary (cream accent like coffee foam)
  static const Color darkPrimary = Color(0xFFE8DFD0);       // Coffee foam cream
  static const Color darkPrimaryForeground = Color(0xFF1A1814); // Dark mocha on cream
}

class SemanticColors {
  // Surface Colors
  static const Color surface = ColorTokens.surface;
  static const Color surfaceVariant = ColorTokens.muted;
  static const Color surfaceSecondary = ColorTokens.secondary;
  
  // Background Colors
  static const Color background = ColorTokens.background1;
  static const Color backgroundGradientStart = ColorTokens.background1;
  static const Color backgroundGradientEnd = ColorTokens.background2;
  
  // Text Colors
  static const Color onSurface = ColorTokens.foreground;
  static const Color onSurfaceVariant = ColorTokens.mutedForeground;
  static const Color onSurfaceSecondary = ColorTokens.mutedForeground;
  
  // Primary Colors
  static const Color primary = ColorTokens.primary;
  static const Color onPrimary = ColorTokens.primaryForeground;
  
  // Border Colors
  static const Color border = ColorTokens.border;
  static const Color borderSubtle = ColorTokens.border;
  
  // Header Colors
  static const Color headerBackground = Color(0x80FFFFFF); // white.withOpacity(0.5)
  static const Color headerBorder = Color(0x4DE8E1D3); // border.withOpacity(0.3)
  
  // State Colors
  static const Color success = ColorTokens.success;
  static const Color warning = ColorTokens.warning;
  static const Color error = ColorTokens.error;
}