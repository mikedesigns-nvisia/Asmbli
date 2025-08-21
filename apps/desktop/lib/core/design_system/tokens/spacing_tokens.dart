// Spacing tokens based on your existing layout patterns
class SpacingTokens {
  // Base spacing from your existing code
  static const double none = 0.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;    // Your standard element spacing
  static const double xl = 20.0;
  static const double xxl = 24.0;   // Your standard page padding
  static const double xxxl = 32.0;
  static const double huge = 40.0;
  
  // Layout specific (extracted from your existing patterns)
  static const double pageHorizontal = 24.0;  // Container padding horizontal
  static const double pageVertical = 16.0;    // Container padding vertical
  static const double headerPadding = 24.0;   // Header horizontal padding
  static const double sectionSpacing = 24.0;  // Between major sections
  
  // Component specific
  static const double buttonPadding = 16.0;   // Button horizontal padding
  static const double buttonPaddingSmall = 8.0; // Button vertical padding
  static const double cardPadding = 16.0;     // Card internal padding
}

class BorderRadiusTokens {
  static const double none = 0.0;
  static const double sm = 4.0;
  static const double md = 6.0;     // Your standard button radius
  static const double lg = 8.0;     // Your input radius
  static const double xl = 12.0;    // Your card radius
  static const double pill = 999.0;
}