import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Typography tokens using Google Fonts Fustat
class TypographyTokens {
 static String get fontFamily => GoogleFonts.fustat().fontFamily ?? 'SF Pro Display';
 
 // Font Weights 
 static const FontWeight regular = FontWeight.w400;
 static const FontWeight medium = FontWeight.w500;
 static const FontWeight semiBold = FontWeight.w600;
 static const FontWeight bold = FontWeight.w700;
 
 // Font Sizes - Clear hierarchy with proper progression
 static const double fontSizeXXL = 32.0;  // Page titles
 static const double fontSizeXL = 24.0;   // Section titles  
 static const double fontSizeLG = 20.0;   // Card titles, brand
 static const double fontSizeMD = 16.0;   // Body text, buttons
 static const double fontSizeSM = 14.0;   // Small body, labels
 static const double fontSizeXS = 12.0;   // Captions, metadata
}

// Text styles using Google Fonts Fustat with improved hierarchy
class TextStyles {
 // ===== HEADINGS =====
 
 // Page Headers - Primary page titles
 static TextStyle get pageTitle => GoogleFonts.fustat(
   fontSize: TypographyTokens.fontSizeXXL,  // 32px
   fontWeight: TypographyTokens.bold,
   letterSpacing: -0.5,
   height: 1.2,
 );
 
 // Section Headers - Main content sections
 static TextStyle get sectionTitle => GoogleFonts.fustat(
   fontSize: TypographyTokens.fontSizeXL,   // 24px
   fontWeight: TypographyTokens.semiBold,
   letterSpacing: -0.2,
   height: 1.3,
 );
 
 // Card/Component Headers
 static TextStyle get cardTitle => GoogleFonts.fustat(
   fontSize: TypographyTokens.fontSizeLG,   // 20px
   fontWeight: TypographyTokens.semiBold,
   letterSpacing: -0.1,
   height: 1.3,
 );
 
 // Brand Title (your "Asmbli" style)  
 static TextStyle get brandTitle => GoogleFonts.fustat(
   fontSize: TypographyTokens.fontSizeLG,   // 20px
   fontWeight: TypographyTokens.bold,
   fontStyle: FontStyle.italic,
   letterSpacing: -0.3,
   height: 1.2,
 );
 
 // ===== BODY TEXT =====
 
 // Primary body text - Main readable content (ACCESSIBILITY COMPLIANT)
 static TextStyle get bodyLarge => GoogleFonts.fustat(
   fontSize: TypographyTokens.fontSizeMD,   // 16px
   fontWeight: TypographyTokens.regular,
   letterSpacing: 0.1,
   height: 1.5,
 );
 
 // Secondary body text - Still accessible  
 static TextStyle get bodyMedium => GoogleFonts.fustat(
   fontSize: TypographyTokens.fontSizeSM,   // 14px
   fontWeight: TypographyTokens.regular,
   letterSpacing: 0.1,
   height: 1.4,
 );
 
 // Metadata/captions - Minimum accessible size
 static TextStyle get bodySmall => GoogleFonts.fustat(
   fontSize: TypographyTokens.fontSizeXS,   // 12px
   fontWeight: TypographyTokens.regular,
   letterSpacing: 0.2,
   height: 1.4,
 );
 
 // ===== INTERACTIVE ELEMENTS =====
 
 // Button Text
 static TextStyle get button => GoogleFonts.fustat(
   fontSize: TypographyTokens.fontSizeSM,   // 14px
   fontWeight: TypographyTokens.medium,
   letterSpacing: 0.1,
   height: 1.2,
 );
 
 // Navigation elements
 static TextStyle get navButton => GoogleFonts.fustat(
   fontSize: TypographyTokens.fontSizeSM,   // 14px
   fontWeight: TypographyTokens.medium,
   letterSpacing: 0.1,
   height: 1.3,
 );
 
 // ===== LABELS & METADATA =====
 
 // Form labels, important metadata
 static TextStyle get labelLarge => GoogleFonts.fustat(
   fontSize: TypographyTokens.fontSizeSM,   // 14px
   fontWeight: TypographyTokens.medium,
   letterSpacing: 0.1,
   height: 1.3,
 );
 
 // Secondary labels
 static TextStyle get labelMedium => GoogleFonts.fustat(
   fontSize: TypographyTokens.fontSizeXS,   // 12px
   fontWeight: TypographyTokens.medium,
   letterSpacing: 0.2,
   height: 1.3,
 );
 
 // Captions, helper text, timestamps
 static TextStyle get caption => GoogleFonts.fustat(
   fontSize: TypographyTokens.fontSizeXS,   // 12px
   fontWeight: TypographyTokens.regular,
   letterSpacing: 0.2,
   height: 1.3,
 );
 
 // ===== COMPATIBILITY ALIASES ===== 
 
 // Material Design compatibility
 static TextStyle get titleLarge => pageTitle;
 static TextStyle get titleMedium => cardTitle; 
 static TextStyle get titleSmall => labelLarge;
 static TextStyle get headlineLarge => pageTitle;
 static TextStyle get headlineMedium => sectionTitle;
 static TextStyle get headlineSmall => cardTitle;
 static TextStyle get headingMedium => cardTitle;
 
 // Legacy aliases removed - use labelMedium instead
}