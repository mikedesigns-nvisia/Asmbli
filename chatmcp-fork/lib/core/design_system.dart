import 'package:flutter/material.dart';

class AsmbliDesignSystem {
  // Brand Colors
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color primaryIndigoLight = Color(0xFF818CF8);
  static const Color primaryIndigoDark = Color(0xFF4F46E5);
  
  static const Color secondaryPurple = Color(0xFF8B5CF6);
  static const Color secondaryPurpleLight = Color(0xFFA78BFA);
  static const Color secondaryPurpleDark = Color(0xFF7C3AED);
  
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentRed = Color(0xFFEF4444);
  
  // Neutral Colors
  static const Color neutral50 = Color(0xFFF9FAFB);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral300 = Color(0xFFD1D5DB);
  static const Color neutral400 = Color(0xFF9CA3AF);
  static const Color neutral500 = Color(0xFF6B7280);
  static const Color neutral600 = Color(0xFF4B5563);
  static const Color neutral700 = Color(0xFF374151);
  static const Color neutral800 = Color(0xFF1F2937);
  static const Color neutral900 = Color(0xFF111827);
  
  // Dark Theme Background Colors
  static const Color darkBg = Color(0xFF0A0E27);
  static const Color darkBgSecondary = Color(0xFF1A1F3A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceSecondary = Color(0xFF2D3748);
  
  // Light Theme Background Colors
  static const Color lightBg = Color(0xFFF8F9FE);
  static const Color lightBgSecondary = Color(0xFFE8ECFD);
  static const Color lightSurface = Colors.white;
  static const Color lightSurfaceSecondary = Color(0xFFF7F8FC);
  
  // Role-based Colors
  static const Color roleDeveloper = Color(0xFF3B82F6);
  static const Color roleCreator = Color(0xFFEC4899);
  static const Color roleResearcher = Color(0xFF8B5CF6);
  static const Color roleEnterprise = Color(0xFF059669);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryIndigo, secondaryPurple],
  );
  
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkBg, darkBgSecondary],
  );
  
  static const LinearGradient lightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lightBg, lightBgSecondary],
  );
  
  // Typography
  static const String fontFamily = 'Inter';
  static const String monoFontFamily = 'JetBrains Mono';
  
  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: -0.5),
    displayMedium: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: -0.25),
    displaySmall: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
    headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
  );
  
  // Border Radius
  static const double radiusXs = 4;
  static const double radiusSm = 6;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusXl = 16;
  static const double radius2xl = 24;
  static const double radiusFull = 9999;
  
  // Spacing
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;
  static const double space12 = 48;
  static const double space16 = 64;
  
  // Shadows
  static List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];
  
  static List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> shadowXl = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> shadowGlow = [
    BoxShadow(
      color: primaryIndigo.withOpacity(0.3),
      blurRadius: 20,
      spreadRadius: -5,
    ),
  ];
  
  // Themes
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryIndigo,
    scaffoldBackgroundColor: lightBg,
    fontFamily: fontFamily,
    textTheme: textTheme,
    colorScheme: const ColorScheme.light(
      primary: primaryIndigo,
      secondary: secondaryPurple,
      tertiary: accentAmber,
      surface: lightSurface,
      surfaceContainer: lightSurfaceSecondary,
      error: accentRed,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: neutral900,
      onError: Colors.white,
    ),
    cardTheme: CardTheme(
      color: lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        side: const BorderSide(color: neutral200, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryIndigo,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: space4, vertical: space3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryIndigo,
        side: const BorderSide(color: primaryIndigo),
        padding: const EdgeInsets.symmetric(horizontal: space4, vertical: space3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: space3, vertical: space3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: neutral200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: neutral200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: primaryIndigo, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: accentRed),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: lightSurfaceSecondary,
      selectedColor: primaryIndigo.withOpacity(0.2),
      labelStyle: textTheme.labelMedium!,
      padding: const EdgeInsets.symmetric(horizontal: space2, vertical: space1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusFull),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: neutral200,
      thickness: 1,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: lightSurface,
      foregroundColor: neutral900,
      elevation: 0,
      centerTitle: false,
    ),
  );
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryIndigo,
    scaffoldBackgroundColor: darkBg,
    fontFamily: fontFamily,
    textTheme: textTheme,
    colorScheme: const ColorScheme.dark(
      primary: primaryIndigo,
      secondary: secondaryPurple,
      tertiary: accentAmber,
      surface: darkSurface,
      surfaceContainer: darkSurfaceSecondary,
      error: accentRed,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: neutral100,
      onError: Colors.white,
    ),
    cardTheme: CardTheme(
      color: darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        side: BorderSide(color: neutral700.withOpacity(0.5), width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryIndigo,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: space4, vertical: space3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryIndigoLight,
        side: const BorderSide(color: primaryIndigo),
        padding: const EdgeInsets.symmetric(horizontal: space4, vertical: space3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurfaceSecondary,
      contentPadding: const EdgeInsets.symmetric(horizontal: space3, vertical: space3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: neutral700.withOpacity(0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: neutral700.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: primaryIndigo, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: accentRed),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: darkSurfaceSecondary,
      selectedColor: primaryIndigo.withOpacity(0.3),
      labelStyle: textTheme.labelMedium!.copyWith(color: neutral100),
      padding: const EdgeInsets.symmetric(horizontal: space2, vertical: space1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusFull),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: neutral700.withOpacity(0.5),
      thickness: 1,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: neutral100,
      elevation: 0,
      centerTitle: false,
    ),
  );
}

// Custom Widget Extensions
class AsmbliCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool showGlow;

  const AsmbliCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.isSelected = false,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: padding ?? const EdgeInsets.all(AsmbliDesignSystem.space4),
        decoration: BoxDecoration(
          color: isDark ? AsmbliDesignSystem.darkSurface : AsmbliDesignSystem.lightSurface,
          borderRadius: BorderRadius.circular(AsmbliDesignSystem.radiusLg),
          border: Border.all(
            color: isSelected
                ? AsmbliDesignSystem.primaryIndigo
                : isDark
                    ? AsmbliDesignSystem.neutral700.withOpacity(0.5)
                    : AsmbliDesignSystem.neutral200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: showGlow
              ? AsmbliDesignSystem.shadowGlow
              : isSelected
                  ? AsmbliDesignSystem.shadowLg
                  : AsmbliDesignSystem.shadowMd,
        ),
        child: child,
      ),
    );
  }
}

class AsmbliButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;
  final IconData? icon;

  const AsmbliButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isPrimary = true,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final buttonChild = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: AsmbliDesignSystem.space2),
              ],
              Text(label),
            ],
          );

    if (isPrimary) {
      return ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: buttonChild,
      );
    } else {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: buttonChild,
      );
    }
  }
}

class AsmbliChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? color;

  const AsmbliChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onTap != null ? (_) => onTap!() : null,
      backgroundColor: color?.withOpacity(0.1),
      selectedColor: (color ?? AsmbliDesignSystem.primaryIndigo).withOpacity(0.2),
      checkmarkColor: color ?? AsmbliDesignSystem.primaryIndigo,
    );
  }
}