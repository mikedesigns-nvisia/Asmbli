import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Typography tokens using Google Fonts Fustat
class TypographyTokens {
 static String get fontFamily => GoogleFonts.fustat().fontFamily!;
 
 // Font Weights (from your existing usage)
 static const FontWeight regular = FontWeight.w400;
 static const FontWeight medium = FontWeight.w500;
 static const FontWeight semiBold = FontWeight.w600;
 static const FontWeight bold = FontWeight.w700;
}

// Text styles using Google Fonts Fustat
class TextStyles {
 // Brand Title (your "Asmbli" style)
 static TextStyle get brandTitle => GoogleFonts.fustat(
   fontSize: 20,
   fontWeight: TypographyTokens.bold,
   fontStyle: FontStyle.italic,
   letterSpacing: -0.5,
 );
 
 // Page Headers
 static TextStyle get pageTitle => GoogleFonts.fustat(
   fontSize: 32,
   fontWeight: TypographyTokens.bold,
   letterSpacing: -0.5,
 );
 
 static TextStyle get sectionTitle => GoogleFonts.fustat(
   fontSize: 24,
   fontWeight: TypographyTokens.semiBold,
 );
 
 static TextStyle get cardTitle => GoogleFonts.fustat(
   fontSize: 18,
   fontWeight: TypographyTokens.semiBold,
 );
 
 // Body Text
 static TextStyle get bodyLarge => GoogleFonts.fustat(
   fontSize: 16,
   fontWeight: TypographyTokens.regular,
   letterSpacing: 0.5,
 );
 
 static TextStyle get bodyMedium => GoogleFonts.fustat(
   fontSize: 14,
   fontWeight: TypographyTokens.regular,
   letterSpacing: 0.25,
 );
 
 static TextStyle get bodySmall => GoogleFonts.fustat(
   fontSize: 12,
   fontWeight: TypographyTokens.regular,
   letterSpacing: 0.4,
 );
 
 // Button Text (your existing button style)
 static TextStyle get button => GoogleFonts.fustat(
   fontSize: 14,
   fontWeight: TypographyTokens.medium,
 );
 
 // Navigation Button
 static TextStyle get navButton => GoogleFonts.fustat(
   fontSize: 14,
   fontWeight: TypographyTokens.medium,
 );
 
 // Labels
 static TextStyle get labelLarge => GoogleFonts.fustat(
   fontSize: 14,
   fontWeight: TypographyTokens.medium,
   letterSpacing: 0.1,
 );
 
 static TextStyle get labelMedium => GoogleFonts.fustat(
   fontSize: 12,
   fontWeight: TypographyTokens.medium,
   letterSpacing: 0.5,
 );
 
 static TextStyle get labelSmall => GoogleFonts.fustat(
   fontSize: 11,
   fontWeight: TypographyTokens.medium,
   letterSpacing: 0.5,
 );
 
 // Caption/Helper Text
 static TextStyle get caption => GoogleFonts.fustat(
   fontSize: 11,
   fontWeight: TypographyTokens.medium,
   letterSpacing: 0.5,
 );
 
 // Additional title styles for compatibility
 static TextStyle get titleLarge => pageTitle;
 static TextStyle get titleMedium => cardTitle;
 static TextStyle get titleSmall => labelLarge;
 
 // Headline styles for compatibility
 static TextStyle get headlineLarge => pageTitle;
 static TextStyle get headlineMedium => sectionTitle;
 static TextStyle get headlineSmall => cardTitle;
 static TextStyle get headingMedium => cardTitle;
}