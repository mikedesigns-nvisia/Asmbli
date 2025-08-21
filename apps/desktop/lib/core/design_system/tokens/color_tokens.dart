import 'package:flutter/material.dart';

// Design tokens for Mint (Light) and Forest (Dark) themes
class ColorTokens {
  // Base Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  
  // Mint Palette (Light Theme)
  static const Color background1 = Color(0xFFF5FBF8);    // Soft mint background
  static const Color background2 = Color(0xFFF7FCFA);    // Lighter mint background/cards
  static const Color surface = Color(0xFFF7FCFA);        // Card surface
  static const Color muted = Color(0xFFEEF6F2);          // Muted mint background
  static const Color secondary = Color(0xFFEDF5F1);      // Secondary surface
  
  // Text Colors
  static const Color foreground = Color(0xFF1E3B2B);     // Deep forest green text
  static const Color mutedForeground = Color(0xFF4A6B5A); // Muted forest green text
  
  // Primary (Deep Forest Green)
  static const Color primary = Color(0xFF1E3B2B);        // Primary action color
  static const Color primaryForeground = Color(0xFFF5FBF8); // Text on primary
  
  // Borders and Lines
  static const Color border = Color(0xFFD3E8DC);         // Soft mint border
  static const Color input = Color(0xFFD3E8DC);          // Input backgrounds
  
  // Interactive States (subtle overlays)
  static const Color hover = Color(0x0A1E3B2B);          // 4% primary overlay
  static const Color pressed = Color(0x141E3B2B);        // 8% primary overlay
  static const Color focus = Color(0x1A1E3B2B);          // 10% primary overlay
  
  // Semantic Colors (harmonious with mint/forest palette)
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFFAAF00);
  static const Color error = Color(0xFFDC2626);
  
  // Forest Palette (Dark Theme)
  static const Color darkBackground1 = Color(0xFF0F1C14);  // Deep forest background
  static const Color darkBackground2 = Color(0xFF142019);  // Slightly lighter forest
  static const Color darkSurface = Color(0xFF1A2920);      // Forest surface
  static const Color darkMuted = Color(0xFF1F2F25);        // Muted forest surface
  static const Color darkBorder = Color(0xFF2B3F33);       // Forest border
  
  // Forest text (soft mint greens)
  static const Color darkForeground = Color(0xFFF0F8F3);    // Light mint
  static const Color darkMutedForeground = Color(0xFFA0BDA8); // Muted mint
  
  // Forest primary (bright mint accent)
  static const Color darkPrimary = Color(0xFFB8E6C8);       // Bright mint accent
  static const Color darkPrimaryForeground = Color(0xFF0F1C14); // Dark forest on mint
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
  static const Color headerBorder = Color(0x4DD3E8DC); // border.withOpacity(0.3)
  
  // State Colors
  static const Color success = ColorTokens.success;
  static const Color warning = ColorTokens.warning;
  static const Color error = ColorTokens.error;
}