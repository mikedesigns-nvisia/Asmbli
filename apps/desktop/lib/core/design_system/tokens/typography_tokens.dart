import 'package:flutter/material.dart';

// Typography tokens based on your existing Space Grotesk usage
class TypographyTokens {
 static const String fontFamily = 'Space Grotesk';
 
 // Font Weights (from your existing usage)
 static const FontWeight regular = FontWeight.w400;
 static const FontWeight medium = FontWeight.w500;
 static const FontWeight semiBold = FontWeight.w600;
 static const FontWeight bold = FontWeight.w700;
}

// Text styles matching your existing patterns
class TextStyles {
 // Brand Title (your "Asmbli" style)
 static const TextStyle brandTitle = TextStyle(
 fontFamily: TypographyTokens.fontFamily,
 fontSize: 20,
 fontWeight: TypographyTokens.bold,
 fontStyle: FontStyle.italic,
 letterSpacing: -0.5,
 );
 
 // Page Headers
 static const TextStyle pageTitle = TextStyle(
 fontFamily: TypographyTokens.fontFamily,
 fontSize: 32,
 fontWeight: TypographyTokens.bold,
 letterSpacing: -0.5,
 );
 
 static const TextStyle sectionTitle = TextStyle(
 fontFamily: TypographyTokens.fontFamily,
 fontSize: 24,
 fontWeight: TypographyTokens.semiBold,
 );
 
 static const TextStyle cardTitle = TextStyle(
 fontFamily: TypographyTokens.fontFamily,
 fontSize: 18,
 fontWeight: TypographyTokens.semiBold,
 );
 
 // Body Text
 static const TextStyle bodyLarge = TextStyle(
 fontFamily: TypographyTokens.fontFamily,
 fontSize: 16,
 fontWeight: TypographyTokens.regular,
 letterSpacing: 0.5,
 );
 
 static const TextStyle bodyMedium = TextStyle(
 fontFamily: TypographyTokens.fontFamily,
 fontSize: 14,
 fontWeight: TypographyTokens.regular,
 letterSpacing: 0.25,
 );
 
 static const TextStyle bodySmall = TextStyle(
 fontFamily: TypographyTokens.fontFamily,
 fontSize: 12,
 fontWeight: TypographyTokens.regular,
 letterSpacing: 0.4,
 );
 
 // Button Text (your existing button style)
 static const TextStyle button = TextStyle(
 fontFamily: TypographyTokens.fontFamily,
 fontSize: 14,
 fontWeight: TypographyTokens.medium,
 );
 
 // Navigation Button
 static const TextStyle navButton = TextStyle(
 fontFamily: TypographyTokens.fontFamily,
 fontSize: 14,
 fontWeight: TypographyTokens.medium,
 );
 
 // Labels
 static const TextStyle labelLarge = TextStyle(
 fontFamily: TypographyTokens.fontFamily,
 fontSize: 14,
 fontWeight: TypographyTokens.medium,
 letterSpacing: 0.1,
 );
 
 static const TextStyle labelMedium = TextStyle(
 fontFamily: TypographyTokens.fontFamily,
 fontSize: 12,
 fontWeight: TypographyTokens.medium,
 letterSpacing: 0.5,
 );
 
 static const TextStyle labelSmall = TextStyle(
 fontFamily: TypographyTokens.fontFamily,
 fontSize: 11,
 fontWeight: TypographyTokens.medium,
 letterSpacing: 0.5,
 );
 
 // Caption/Helper Text
 static const TextStyle caption = TextStyle(
 fontFamily: TypographyTokens.fontFamily,
 fontSize: 11,
 fontWeight: TypographyTokens.medium,
 letterSpacing: 0.5,
 );
 
 // Additional title styles for compatibility
 static const TextStyle titleLarge = pageTitle;
 static const TextStyle titleMedium = cardTitle;
 static const TextStyle titleSmall = labelLarge;
}