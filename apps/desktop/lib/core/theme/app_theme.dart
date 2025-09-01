import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
 // Mint (Light) and Forest (Dark) Theme Colors with Enhanced Gradients
 // Light Mode Theme - Mint
 static const Color lightBackground = Color(0xFFF5FBF8); // Soft mint background
 static const Color lightBackgroundGradientStart = Color(0xFFF8FCFA); // Lighter mint center
 static const Color lightBackgroundGradientMiddle = Color(0xFFF5FBF8); // Main mint
 static const Color lightBackgroundGradientEnd = Color(0xFFE8F3ED); // Darker mint edges
 static const Color lightForeground = Color(0xFF1E3B2B); // Deep forest green text
 static const Color lightCard = Color(0xFFF7FCFA); // Lighter mint background/cards
 static const Color lightCardForeground = Color(0xFF1E3B2B); // Deep forest green text
 static const Color lightPrimary = Color(0xFF1E3B2B); // Deep forest green primary
 static const Color lightPrimaryForeground = Color(0xFFF5FBF8); // Soft mint on primary
 static const Color lightSecondary = Color(0xFFEDF5F1); // Secondary surface
 static const Color lightSecondaryForeground = Color(0xFF1E3B2B); // Deep forest green text
 static const Color lightMuted = Color(0xFFEEF6F2); // Muted mint background
 static const Color lightMutedForeground = Color(0xFF4A6B5A); // Muted forest green text
 static const Color lightAccent = Color(0xFF6B9080); // Sage green accent
 static const Color lightAccentForeground = Color(0xFFFFFFFF); // White text on accent
 static const Color lightBorder = Color(0xFFD3E8DC); // Soft mint border
 static const Color lightInput = Color(0xFFD3E8DC); // Input backgrounds
 
 // Dark Mode Colors - Forest with Enhanced Gradients
 static const Color darkBackground = Color(0xFF0F1C14); // Deep forest background
 static const Color darkBackgroundGradientStart = Color(0xFF142019); // Lighter forest center
 static const Color darkBackgroundGradientMiddle = Color(0xFF0F1C14); // Main forest
 static const Color darkBackgroundGradientEnd = Color(0xFF0A140F); // Darker forest edges
 static const Color darkForeground = Color(0xFFF0F8F3); // Light mint
 static const Color darkCard = Color(0xFF1A2920); // Forest surface
 static const Color darkCardForeground = Color(0xFFF0F8F3); // Light mint
 static const Color darkPrimary = Color(0xFFB8E6C8); // Bright mint accent
 static const Color darkPrimaryForeground = Color(0xFF0F1C14); // Dark forest on mint
 static const Color darkAccent = Color(0xFF8DBF9E); // Brighter sage accent for dark theme
 static const Color darkAccentForeground = Color(0xFF0F1C14); // Dark forest text on accent

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
 tertiary: lightAccent,
 onTertiary: lightAccentForeground,
 surface: lightCard,
 onSurface: lightCardForeground,
 background: lightBackground,
 onBackground: lightForeground,
 error: Color(0xFFDC2626),
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
 titleTextStyle: TextStyle(
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
 side: BorderSide(color: lightBorder.withValues(alpha: 0.5)),
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
 textStyle: TextStyle(
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
 textStyle: TextStyle(
  fontWeight: FontWeight.w500,
 fontSize: 14,
 ),
 ),
 ),
 
 textButtonTheme: TextButtonThemeData(
 style: TextButton.styleFrom(
 foregroundColor: lightForeground,
 textStyle: GoogleFonts.fustat(
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
 
 // Typography - Fustat throughout
  textTheme: TextTheme(
 displayLarge: TextStyle(
  fontSize: 57,
 fontWeight: FontWeight.w400,
 letterSpacing: -0.25,
 color: lightForeground,
 ),
 displayMedium: TextStyle(
  fontSize: 45,
 fontWeight: FontWeight.w400,
 color: lightForeground,
 ),
 displaySmall: TextStyle(
  fontSize: 36,
 fontWeight: FontWeight.w400,
 color: lightForeground,
 ),
 headlineLarge: TextStyle(
  fontSize: 32,
 fontWeight: FontWeight.w700,
 letterSpacing: -0.5,
 color: lightForeground,
 ),
 headlineMedium: TextStyle(
  fontSize: 28,
 fontWeight: FontWeight.w600,
 letterSpacing: -0.25,
 color: lightForeground,
 ),
 headlineSmall: TextStyle(
  fontSize: 24,
 fontWeight: FontWeight.w600,
 color: lightForeground,
 ),
 titleLarge: TextStyle(
  fontSize: 22,
 fontWeight: FontWeight.w500,
 color: lightForeground,
 ),
 titleMedium: TextStyle(
  fontSize: 16,
 fontWeight: FontWeight.w500,
 letterSpacing: 0.15,
 color: lightForeground,
 ),
 titleSmall: TextStyle(
  fontSize: 14,
 fontWeight: FontWeight.w500,
 letterSpacing: 0.1,
 color: lightForeground,
 ),
 bodyLarge: TextStyle(
  fontSize: 16,
 fontWeight: FontWeight.w400,
 letterSpacing: 0.5,
 color: lightForeground,
 ),
 bodyMedium: TextStyle(
  fontSize: 14,
 fontWeight: FontWeight.w400,
 letterSpacing: 0.25,
 color: lightMutedForeground,
 ),
 bodySmall: TextStyle(
  fontSize: 12,
 fontWeight: FontWeight.w400,
 letterSpacing: 0.4,
 color: lightMutedForeground,
 ),
 labelLarge: TextStyle(
  fontSize: 14,
 fontWeight: FontWeight.w500,
 letterSpacing: 0.1,
 color: lightForeground,
 ),
 labelMedium: TextStyle(
  fontSize: 12,
 fontWeight: FontWeight.w500,
 letterSpacing: 0.5,
 color: lightMutedForeground,
 ),
 labelSmall: TextStyle(
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
 secondary: Color(0xFF1F2F25),
 onSecondary: Color(0xFFA0BDA8),
 tertiary: darkAccent,
 onTertiary: darkAccentForeground,
 surface: darkCard,
 onSurface: darkCardForeground,
 background: darkBackground,
 onBackground: darkForeground,
 error: Color(0xFFF87171),
 onError: Colors.white,
 outline: Color(0xFF2B3F33),
 surfaceVariant: const Color(0xFF1F2F25),
 onSurfaceVariant: const Color(0xFFA0BDA8),
 ),
 
 // AppBar Theme - Clean and minimal
 appBarTheme: AppBarTheme(
 elevation: 0,
 scrolledUnderElevation: 0,
 backgroundColor: Colors.transparent,
 foregroundColor: darkForeground,
 surfaceTintColor: Colors.transparent,
 titleTextStyle: const TextStyle(
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
 side: BorderSide(color: const Color(0xFF2B3F33).withValues(alpha: 0.5)),
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
 textStyle: GoogleFonts.fustat(
  fontWeight: FontWeight.w500,
 fontSize: 14,
 ),
 ),
 ),
 
 outlinedButtonTheme: OutlinedButtonThemeData(
 style: OutlinedButton.styleFrom(
 foregroundColor: darkPrimary,
 side: const BorderSide(color: Color(0xFF2B3F33)),
 elevation: 0,
 backgroundColor: Colors.transparent,
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(8),
 ),
 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
 textStyle: GoogleFonts.fustat(
  fontWeight: FontWeight.w500,
 fontSize: 14,
 ),
 ),
 ),
 
 textButtonTheme: TextButtonThemeData(
 style: TextButton.styleFrom(
 foregroundColor: darkForeground,
 textStyle: GoogleFonts.fustat(
  fontWeight: FontWeight.w500,
 fontSize: 14,
 ),
 ),
 ),
 
 // Input Theme
 inputDecorationTheme: InputDecorationTheme(
 border: OutlineInputBorder(
 borderRadius: BorderRadius.circular(8),
 borderSide: const BorderSide(color: Color(0xFF2B3F33)),
 ),
 enabledBorder: OutlineInputBorder(
 borderRadius: BorderRadius.circular(8),
 borderSide: const BorderSide(color: Color(0xFF2B3F33)),
 ),
 focusedBorder: OutlineInputBorder(
 borderRadius: BorderRadius.circular(8),
 borderSide: const BorderSide(color: darkPrimary, width: 2),
 ),
 filled: true,
 fillColor: const Color(0xFF142019),
 contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
 ),
 
 // Typography - Fustat throughout
  textTheme: TextTheme(
 displayLarge: TextStyle(
  fontSize: 57,
 fontWeight: FontWeight.w400,
 letterSpacing: -0.25,
 color: darkForeground,
 ),
 displayMedium: TextStyle(
  fontSize: 45,
 fontWeight: FontWeight.w400,
 color: darkForeground,
 ),
 displaySmall: TextStyle(
  fontSize: 36,
 fontWeight: FontWeight.w400,
 color: darkForeground,
 ),
 headlineLarge: TextStyle(
  fontSize: 32,
 fontWeight: FontWeight.w700,
 letterSpacing: -0.5,
 color: darkForeground,
 ),
 headlineMedium: TextStyle(
  fontSize: 28,
 fontWeight: FontWeight.w600,
 letterSpacing: -0.25,
 color: darkForeground,
 ),
 headlineSmall: TextStyle(
  fontSize: 24,
 fontWeight: FontWeight.w600,
 color: darkForeground,
 ),
 titleLarge: TextStyle(
  fontSize: 22,
 fontWeight: FontWeight.w500,
 color: darkForeground,
 ),
 titleMedium: TextStyle(
  fontSize: 16,
 fontWeight: FontWeight.w500,
 letterSpacing: 0.15,
 color: darkForeground,
 ),
 titleSmall: TextStyle(
  fontSize: 14,
 fontWeight: FontWeight.w500,
 letterSpacing: 0.1,
 color: darkForeground,
 ),
 bodyLarge: TextStyle(
  fontSize: 16,
 fontWeight: FontWeight.w400,
 letterSpacing: 0.5,
 color: darkForeground,
 ),
 bodyMedium: TextStyle(
  fontSize: 14,
 fontWeight: FontWeight.w400,
 letterSpacing: 0.25,
 color: const Color(0xFFA0BDA8),
 ),
 bodySmall: TextStyle(
  fontSize: 12,
 fontWeight: FontWeight.w400,
 letterSpacing: 0.4,
 color: const Color(0xFFA0BDA8),
 ),
 labelLarge: TextStyle(
  fontSize: 14,
 fontWeight: FontWeight.w500,
 letterSpacing: 0.1,
 color: darkForeground,
 ),
 labelMedium: TextStyle(
  fontSize: 12,
 fontWeight: FontWeight.w500,
 letterSpacing: 0.5,
 color: const Color(0xFFA0BDA8),
 ),
 labelSmall: TextStyle(
  fontSize: 11,
 fontWeight: FontWeight.w500,
 letterSpacing: 0.5,
 color: const Color(0xFFA0BDA8),
 ),
 ),
 );
 }
}