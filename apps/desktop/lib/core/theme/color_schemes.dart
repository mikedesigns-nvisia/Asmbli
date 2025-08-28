import 'package:flutter/material.dart';

/// Color scheme definitions for the app
/// Each scheme contains light and dark variants
class AppColorSchemes {
  // Mint Green (Current Default)
  static const String mintGreen = 'mint-green';
  
  // Cool Blue (New)
  static const String coolBlue = 'cool-blue';
  
  // Forest Green
  static const String forestGreen = 'forest-green';
  
  // Sunset Orange
  static const String sunsetOrange = 'sunset-orange';

  /// Get all available color scheme options for UI
  static List<ColorSchemeOption> get all => [
    ColorSchemeOption(mintGreen, 'Mint Green', [
      const Color(0xFF1E3B2B), // primary
      const Color(0xFF6B9080), // accent  
      const Color(0xFFF5FBF8), // background
    ]),
    ColorSchemeOption(coolBlue, 'Cool Blue', [
      const Color(0xFF1E3A8A), // primary
      const Color(0xFF3B82F6), // accent
      const Color(0xFFF0F9FF), // background
    ]),
    ColorSchemeOption(forestGreen, 'Forest Green', [
      const Color(0xFF14532D), // primary
      const Color(0xFF22C55E), // accent
      const Color(0xFFF0FDF4), // background
    ]),
    ColorSchemeOption(sunsetOrange, 'Sunset Orange', [
      const Color(0xFF9A3412), // primary
      const Color(0xFFF97316), // accent
      const Color(0xFFFFF7ED), // background
    ]),
  ];

  /// Get theme data for a specific color scheme
  static ThemeData getTheme(String schemeId, bool isDark) {
    switch (schemeId) {
      case coolBlue:
        return isDark ? _coolBlueDarkTheme : _coolBlueLightTheme;
      case forestGreen:
        return isDark ? _forestGreenDarkTheme : _forestGreenLightTheme;
      case sunsetOrange:
        return isDark ? _sunsetOrangeDarkTheme : _sunsetOrangeLightTheme;
      case mintGreen:
      default:
        return isDark ? _mintGreenDarkTheme : _mintGreenLightTheme;
    }
  }

  // MINT GREEN THEMES (Current Default)
  
  static ThemeData get _mintGreenLightTheme {
    const background = Color(0xFFF5FBF8); // Soft mint background
    const surface = Color(0xFFF7FCFA); // Lighter mint surface
    const primary = Color(0xFF1E3B2B); // Deep forest green primary
    const accent = Color(0xFF6B9080); // Sage green accent
    const onSurface = Color(0xFF1E3B2B); // Deep forest green text
    const onSurfaceVariant = Color(0xFF4A6B5A); // Muted forest green text
    const border = Color(0xFFD3E8DC); // Soft mint border

    return _buildThemeData(
      brightness: Brightness.light,
      background: background,
      surface: surface,
      primary: primary,
      onPrimary: Color(0xFFF5FBF8),
      accent: accent,
      onAccent: Colors.white,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      border: border,
      surfaceVariant: Color(0xFFEEF6F2),
      backgroundGradientStart: Color(0xFFF8FCFA),
      backgroundGradientEnd: Color(0xFFE8F3ED),
    );
  }

  static ThemeData get _mintGreenDarkTheme {
    const background = Color(0xFF0F1C14); // Deep forest background
    const surface = Color(0xFF1A2920); // Forest surface
    const primary = Color(0xFFB8E6C8); // Bright mint accent
    const accent = Color(0xFF8DBF9E); // Brighter sage accent
    const onSurface = Color(0xFFF0F8F3); // Light mint
    const onSurfaceVariant = Color(0xFFA0BDA8); // Muted mint
    const border = Color(0xFF2B3F33);

    return _buildThemeData(
      brightness: Brightness.dark,
      background: background,
      surface: surface,
      primary: primary,
      onPrimary: Color(0xFF0F1C14),
      accent: accent,
      onAccent: Color(0xFF0F1C14),
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      border: border,
      surfaceVariant: Color(0xFF1F2F25),
      backgroundGradientStart: Color(0xFF142019),
      backgroundGradientEnd: Color(0xFF0A140F),
    );
  }

  // COOL BLUE THEMES

  static ThemeData get _coolBlueLightTheme {
    const background = Color(0xFFF0F9FF); // Soft blue background
    const surface = Color(0xFFFAFCFF); // Lighter blue surface
    const primary = Color(0xFF1E3A8A); // Deep blue primary
    const accent = Color(0xFF3B82F6); // Bright blue accent
    const onSurface = Color(0xFF1E3A8A); // Deep blue text
    const onSurfaceVariant = Color(0xFF475569); // Muted blue-gray text
    const border = Color(0xFFDDEAF7); // Soft blue border

    return _buildThemeData(
      brightness: Brightness.light,
      background: background,
      surface: surface,
      primary: primary,
      onPrimary: Colors.white,
      accent: accent,
      onAccent: Colors.white,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      border: border,
      surfaceVariant: Color(0xFFF1F5F9),
      backgroundGradientStart: Color(0xFFFAFCFF),
      backgroundGradientEnd: Color(0xFFE0F2FE),
    );
  }

  static ThemeData get _coolBlueDarkTheme {
    const background = Color(0xFF0F172A); // Deep blue background
    const surface = Color(0xFF1E293B); // Blue-gray surface
    const primary = Color(0xFF60A5FA); // Bright blue accent
    const accent = Color(0xFF93C5FD); // Lighter blue accent
    const onSurface = Color(0xFFF1F5F9); // Light blue-white
    const onSurfaceVariant = Color(0xFFCBD5E1); // Muted light blue
    const border = Color(0xFF334155);

    return _buildThemeData(
      brightness: Brightness.dark,
      background: background,
      surface: surface,
      primary: primary,
      onPrimary: Color(0xFF0F172A),
      accent: accent,
      onAccent: Color(0xFF0F172A),
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      border: border,
      surfaceVariant: Color(0xFF292E3A),
      backgroundGradientStart: Color(0xFF1E293B),
      backgroundGradientEnd: Color(0xFF0C1220),
    );
  }

  // FOREST GREEN THEMES

  static ThemeData get _forestGreenLightTheme {
    const background = Color(0xFFF0FDF4); // Very light green
    const surface = Color(0xFFFAFDFB); // Almost white green
    const primary = Color(0xFF14532D); // Deep forest green
    const accent = Color(0xFF22C55E); // Bright green accent
    const onSurface = Color(0xFF14532D); // Deep green text
    const onSurfaceVariant = Color(0xFF365314); // Medium green text
    const border = Color(0xFFD1FAE5); // Light green border

    return _buildThemeData(
      brightness: Brightness.light,
      background: background,
      surface: surface,
      primary: primary,
      onPrimary: Colors.white,
      accent: accent,
      onAccent: Colors.white,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      border: border,
      surfaceVariant: Color(0xFFF7FEF7),
      backgroundGradientStart: Color(0xFFFAFDFB),
      backgroundGradientEnd: Color(0xFFDCFCE7),
    );
  }

  static ThemeData get _forestGreenDarkTheme {
    const background = Color(0xFF14532D); // Deep forest
    const surface = Color(0xFF1F5A32); // Lighter forest
    const primary = Color(0xFF4ADE80); // Bright green
    const accent = Color(0xFF68CC8A); // Medium bright green
    const onSurface = Color(0xFFF0FDF4); // Very light green
    const onSurfaceVariant = Color(0xFFBBF7D0); // Light green
    const border = Color(0xFF166534);

    return _buildThemeData(
      brightness: Brightness.dark,
      background: background,
      surface: surface,
      primary: primary,
      onPrimary: Color(0xFF14532D),
      accent: accent,
      onAccent: Color(0xFF14532D),
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      border: border,
      surfaceVariant: Color(0xFF166534),
      backgroundGradientStart: Color(0xFF1F5A32),
      backgroundGradientEnd: Color(0xFF0F2419),
    );
  }

  // SUNSET ORANGE THEMES

  static ThemeData get _sunsetOrangeLightTheme {
    const background = Color(0xFFFFF7ED); // Very light orange
    const surface = Color(0xFFFFFBF7); // Almost white orange
    const primary = Color(0xFF9A3412); // Deep orange-red
    const accent = Color(0xFFF97316); // Bright orange accent
    const onSurface = Color(0xFF9A3412); // Deep orange text
    const onSurfaceVariant = Color(0xFFEA580C); // Medium orange text
    const border = Color(0xFFFED7AA); // Light orange border

    return _buildThemeData(
      brightness: Brightness.light,
      background: background,
      surface: surface,
      primary: primary,
      onPrimary: Colors.white,
      accent: accent,
      onAccent: Colors.white,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      border: border,
      surfaceVariant: Color(0xFFFEF3C7),
      backgroundGradientStart: Color(0xFFFFFBF7),
      backgroundGradientEnd: Color(0xFFFED7AA),
    );
  }

  static ThemeData get _sunsetOrangeDarkTheme {
    const background = Color(0xFF7C2D12); // Deep orange-red
    const surface = Color(0xFF9A3412); // Lighter orange-red
    const primary = Color(0xFFFB923C); // Bright orange
    const accent = Color(0xFFFD7C3C); // Light orange accent
    const onSurface = Color(0xFFFFF7ED); // Very light orange
    const onSurfaceVariant = Color(0xFFFED7AA); // Light orange
    const border = Color(0xFFEA580C);

    return _buildThemeData(
      brightness: Brightness.dark,
      background: background,
      surface: surface,
      primary: primary,
      onPrimary: Color(0xFF7C2D12),
      accent: accent,
      onAccent: Color(0xFF7C2D12),
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      border: border,
      surfaceVariant: Color(0xFFEA580C),
      backgroundGradientStart: Color(0xFF9A3412),
      backgroundGradientEnd: Color(0xFF571A08),
    );
  }

  /// Helper method to build consistent theme data
  static ThemeData _buildThemeData({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color primary,
    required Color onPrimary,
    required Color accent,
    required Color onAccent,
    required Color onSurface,
    required Color onSurfaceVariant,
    required Color border,
    required Color surfaceVariant,
    required Color backgroundGradientStart,
    required Color backgroundGradientEnd,
  }) {
    final isDark = brightness == Brightness.dark;
    
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        onPrimary: onPrimary,
        secondary: isDark ? surface.withValues(alpha: 0.8) : surfaceVariant,
        onSecondary: onSurface,
        tertiary: accent,
        onTertiary: onAccent,
        surface: surface,
        onSurface: onSurface,
        background: background,
        onBackground: onSurface,
        error: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
        onError: Colors.white,
        outline: border,
        surfaceVariant: surfaceVariant,
        onSurfaceVariant: onSurfaceVariant,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
          color: onSurface,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border.withValues(alpha: 0.5)),
        ),
        color: surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: border),
          elevation: 0,
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),

      // Input Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        filled: true,
        fillColor: isDark ? surface : surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Typography
      fontFamily: 'Space Grotesk',
      textTheme: _buildTextTheme(onSurface, onSurfaceVariant),
    );
  }

  /// Build consistent text theme
  static TextTheme _buildTextTheme(Color onSurface, Color onSurfaceVariant) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Space Grotesk',
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: onSurface,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Space Grotesk',
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Space Grotesk',
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Space Grotesk',
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: onSurface,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Space Grotesk',
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        color: onSurface,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Space Grotesk',
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Space Grotesk',
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Space Grotesk',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: onSurface,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Space Grotesk',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: onSurface,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Space Grotesk',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: onSurface,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Space Grotesk',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: onSurfaceVariant,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Space Grotesk',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: onSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Space Grotesk',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: onSurface,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Space Grotesk',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: onSurfaceVariant,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Space Grotesk',
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: onSurfaceVariant,
      ),
    );
  }
}

/// Color scheme option for UI selection
class ColorSchemeOption {
  final String id;
  final String name;
  final List<Color> colors;

  const ColorSchemeOption(this.id, this.name, this.colors);
}