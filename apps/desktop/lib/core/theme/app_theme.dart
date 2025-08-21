import 'package:flutter/material.dart';

class AppTheme {
  // Exact Colors from the Web App CSS - Converted from HSL to RGB
  // Light Mode Theme
  static const Color lightBackground = Color(0xFFFBF9F5);    // hsl(54, 35%, 97%)
  static const Color lightForeground = Color(0xFF3D3328);    // hsl(45, 29%, 15%)
  static const Color lightCard = Color(0xFFFCFAF7);          // hsl(54, 30%, 98%)
  static const Color lightCardForeground = Color(0xFF3D3328); // hsl(45, 29%, 15%)
  static const Color lightPrimary = Color(0xFF3D3328);       // hsl(45, 29%, 15%) - Dark primary
  static const Color lightPrimaryForeground = Color(0xFFFBF9F5); // hsl(54, 35%, 97%)
  static const Color lightSecondary = Color(0xFFF5F2ED);     // hsl(50, 30%, 93%)
  static const Color lightSecondaryForeground = Color(0xFF3D3328); // hsl(45, 29%, 15%)
  static const Color lightMuted = Color(0xFFF6F3EE);         // hsl(50, 25%, 94%)
  static const Color lightMutedForeground = Color(0xFF736B5F); // hsl(45, 16%, 46%)
  static const Color lightAccent = Color(0xFFF5F2ED);        // hsl(50, 30%, 93%)
  static const Color lightAccentForeground = Color(0xFF3D3328); // hsl(45, 29%, 15%)
  static const Color lightBorder = Color(0xFFE8E1D3);        // hsl(52, 25%, 89%)
  static const Color lightInput = Color(0xFFE8E1D3);         // hsl(52, 25%, 89%)
  
  // Dark Mode Colors (keep existing)
  static const Color darkBackground = Color(0xFF0C0C0F);     // hsl(222.2, 84%, 4.9%)
  static const Color darkForeground = Color(0xFFFAFAFA);     // hsl(210, 40%, 98%)
  static const Color darkCard = Color(0xFF0C0C0F);           // hsl(222.2, 84%, 4.9%)
  static const Color darkCardForeground = Color(0xFFFAFAFA); // hsl(210, 40%, 98%)
  static const Color darkPrimary = Color(0xFFFAFAFA);        // hsl(210, 40%, 98%)
  static const Color darkPrimaryForeground = Color(0xFF1C1C1F); // hsl(222.2, 47.4%, 11.2%)

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: ColorScheme.light(
        brightness: Brightness.light,
        primary: lightPrimary,
        onPrimary: lightPrimaryForeground,
        secondary: lightSecondary,
        onSecondary: lightSecondaryForeground,
        surface: lightCard,
        onSurface: lightCardForeground,
        background: lightBackground,
        onBackground: lightForeground,
        error: const Color(0xFFDC2626),
        onError: Colors.white,
        outline: lightBorder,
        surfaceVariant: lightMuted,
        onSurfaceVariant: lightMutedForeground,
      ),
      
      // AppBar Theme - Clean and minimal
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: lightForeground,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
          color: lightForeground,
        ),
      ),
      
      // Card Theme - Clean white cards with subtle borders
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: lightBorder.withOpacity(0.5)),
        ),
        color: lightCard,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      
      // Button Themes - Matching web app styling
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimary, // Dark button
          foregroundColor: lightPrimaryForeground, // White text
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
          foregroundColor: lightPrimary,
          side: BorderSide(color: lightBorder),
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
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightForeground,
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
          borderSide: BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: lightPrimary, width: 2),
        ),
        filled: true,
        fillColor: lightInput,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      
      // Typography - Space Grotesk throughout
      fontFamily: 'Space Grotesk',
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
          color: lightForeground,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 45,
          fontWeight: FontWeight.w400,
          color: lightForeground,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: lightForeground,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: lightForeground,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
          color: lightForeground,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: lightForeground,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: lightForeground,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          color: lightForeground,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: lightForeground,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          color: lightForeground,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          color: lightMutedForeground,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          color: lightMutedForeground,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: lightForeground,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: lightMutedForeground,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: lightMutedForeground,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.dark(
        brightness: Brightness.dark,
        primary: darkPrimary,
        onPrimary: darkPrimaryForeground,
        secondary: const Color(0xFF383838),
        onSecondary: const Color(0xFFA3A3A3),
        surface: darkCard,
        onSurface: darkCardForeground,
        background: darkBackground,
        onBackground: darkForeground,
        error: const Color(0xFFF87171),
        onError: Colors.white,
        outline: const Color(0xFF383838),
        surfaceVariant: const Color(0xFF262529),
        onSurfaceVariant: const Color(0xFFA3A3A3),
      ),
      
      // AppBar Theme - Clean and minimal
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: darkForeground,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
          color: darkForeground,
        ),
      ),
      
      // Card Theme - Dark cards with subtle borders
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: const Color(0xFF383838).withOpacity(0.5)),
        ),
        color: darkCard,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      
      // Button Themes - Matching dark styling
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: darkPrimaryForeground,
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
          foregroundColor: darkPrimary,
          side: const BorderSide(color: Color(0xFF383838)),
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
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkForeground,
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
          borderSide: const BorderSide(color: Color(0xFF383838)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF383838)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkPrimary, width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF1C1C1F),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      
      // Typography - Space Grotesk throughout
      fontFamily: 'Space Grotesk',
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
          color: darkForeground,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 45,
          fontWeight: FontWeight.w400,
          color: darkForeground,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: darkForeground,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: darkForeground,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
          color: darkForeground,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: darkForeground,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: darkForeground,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          color: darkForeground,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: darkForeground,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          color: darkForeground,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          color: const Color(0xFFA3A3A3),
        ),
        bodySmall: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          color: const Color(0xFFA3A3A3),
        ),
        labelLarge: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: darkForeground,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: const Color(0xFFA3A3A3),
        ),
        labelSmall: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: const Color(0xFFA3A3A3),
        ),
      ),
    );
  }
}