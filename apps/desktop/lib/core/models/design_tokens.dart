import 'package:equatable/equatable.dart';
import 'dart:convert';

/// Design tokens for consistent design system implementation
///
/// Week 3: Used by MCPPenpotServer to apply brand standards to designs
class DesignTokens extends Equatable {
  final ColorTokens colors;
  final TypographyTokens typography;
  final SpacingTokens spacing;
  final EffectTokens effects;

  const DesignTokens({
    required this.colors,
    required this.typography,
    required this.spacing,
    required this.effects,
  });

  /// Default tokens matching Asmbli design system
  factory DesignTokens.defaultTokens() {
    return DesignTokens(
      colors: ColorTokens.defaultColors(),
      typography: TypographyTokens.defaultTypography(),
      spacing: SpacingTokens.defaultSpacing(),
      effects: EffectTokens.defaultEffects(),
    );
  }

  /// Parse design tokens from JSON (from context documents)
  factory DesignTokens.fromJson(Map<String, dynamic> json) {
    return DesignTokens(
      colors: ColorTokens.fromJson(json['colors'] ?? {}),
      typography: TypographyTokens.fromJson(json['typography'] ?? {}),
      spacing: SpacingTokens.fromJson(json['spacing'] ?? {}),
      effects: EffectTokens.fromJson(json['effects'] ?? {}),
    );
  }

  /// Parse design tokens from markdown content (from context documents)
  factory DesignTokens.fromMarkdown(String markdown) {
    try {
      // Look for JSON code block in markdown
      final jsonMatch = RegExp(r'```json\s*\n([\s\S]*?)\n```').firstMatch(markdown);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(1)!;
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        return DesignTokens.fromJson(json);
      }

      // Fallback to default if no JSON found
      return DesignTokens.defaultTokens();
    } catch (e) {
      // Fallback to default on parse error
      return DesignTokens.defaultTokens();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'colors': colors.toJson(),
      'typography': typography.toJson(),
      'spacing': spacing.toJson(),
      'effects': effects.toJson(),
    };
  }

  @override
  List<Object?> get props => [colors, typography, spacing, effects];
}

/// Color design tokens
class ColorTokens extends Equatable {
  final String primary;
  final String secondary;
  final String accent;
  final String text;
  final String textSecondary;
  final String background;
  final String surface;
  final String border;
  final String success;
  final String warning;
  final String error;

  const ColorTokens({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.text,
    required this.textSecondary,
    required this.background,
    required this.surface,
    required this.border,
    required this.success,
    required this.warning,
    required this.error,
  });

  factory ColorTokens.defaultColors() {
    return const ColorTokens(
      primary: '#4ECDC4',
      secondary: '#556270',
      accent: '#FF6B6B',
      text: '#1A1A1A',
      textSecondary: '#6B7280',
      background: '#FFFFFF',
      surface: '#F9FAFB',
      border: '#E5E7EB',
      success: '#10B981',
      warning: '#F59E0B',
      error: '#EF4444',
    );
  }

  factory ColorTokens.fromJson(Map<String, dynamic> json) {
    final defaults = ColorTokens.defaultColors();
    return ColorTokens(
      primary: json['primary'] as String? ?? defaults.primary,
      secondary: json['secondary'] as String? ?? defaults.secondary,
      accent: json['accent'] as String? ?? defaults.accent,
      text: json['text'] as String? ?? defaults.text,
      textSecondary: json['textSecondary'] as String? ?? defaults.textSecondary,
      background: json['background'] as String? ?? defaults.background,
      surface: json['surface'] as String? ?? defaults.surface,
      border: json['border'] as String? ?? defaults.border,
      success: json['success'] as String? ?? defaults.success,
      warning: json['warning'] as String? ?? defaults.warning,
      error: json['error'] as String? ?? defaults.error,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primary': primary,
      'secondary': secondary,
      'accent': accent,
      'text': text,
      'textSecondary': textSecondary,
      'background': background,
      'surface': surface,
      'border': border,
      'success': success,
      'warning': warning,
      'error': error,
    };
  }

  @override
  List<Object?> get props => [
        primary,
        secondary,
        accent,
        text,
        textSecondary,
        background,
        surface,
        border,
        success,
        warning,
        error,
      ];
}

/// Typography design tokens
class TypographyTokens extends Equatable {
  final String headingFont;
  final String bodyFont;
  final String monoFont;
  final double baseSize;
  final Map<String, double> scale;
  final Map<String, int> weights;

  const TypographyTokens({
    required this.headingFont,
    required this.bodyFont,
    required this.monoFont,
    required this.baseSize,
    required this.scale,
    required this.weights,
  });

  factory TypographyTokens.defaultTypography() {
    return const TypographyTokens(
      headingFont: 'Space Grotesk',
      bodyFont: 'Inter',
      monoFont: 'JetBrains Mono',
      baseSize: 16,
      scale: {
        'xs': 12,
        'sm': 14,
        'base': 16,
        'lg': 18,
        'xl': 20,
        '2xl': 24,
        '3xl': 30,
        '4xl': 36,
        '5xl': 48,
      },
      weights: {
        'light': 300,
        'regular': 400,
        'medium': 500,
        'semibold': 600,
        'bold': 700,
      },
    );
  }

  factory TypographyTokens.fromJson(Map<String, dynamic> json) {
    final defaults = TypographyTokens.defaultTypography();
    return TypographyTokens(
      headingFont: json['headingFont'] as String? ?? defaults.headingFont,
      bodyFont: json['bodyFont'] as String? ?? defaults.bodyFont,
      monoFont: json['monoFont'] as String? ?? defaults.monoFont,
      baseSize: (json['baseSize'] as num?)?.toDouble() ?? defaults.baseSize,
      scale: (json['scale'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ??
          defaults.scale,
      weights: (json['weights'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int),
          ) ??
          defaults.weights,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'headingFont': headingFont,
      'bodyFont': bodyFont,
      'monoFont': monoFont,
      'baseSize': baseSize,
      'scale': scale,
      'weights': weights,
    };
  }

  @override
  List<Object?> get props => [headingFont, bodyFont, monoFont, baseSize, scale, weights];
}

/// Spacing design tokens
class SpacingTokens extends Equatable {
  final int unit;
  final Map<String, int> scale;

  const SpacingTokens({
    required this.unit,
    required this.scale,
  });

  factory SpacingTokens.defaultSpacing() {
    return const SpacingTokens(
      unit: 8,
      scale: {
        'xs': 4,
        'sm': 8,
        'md': 16,
        'lg': 24,
        'xl': 32,
        '2xl': 48,
        '3xl': 64,
      },
    );
  }

  factory SpacingTokens.fromJson(Map<String, dynamic> json) {
    final defaults = SpacingTokens.defaultSpacing();
    return SpacingTokens(
      unit: json['unit'] as int? ?? defaults.unit,
      scale: (json['scale'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int),
          ) ??
          defaults.scale,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unit': unit,
      'scale': scale,
    };
  }

  @override
  List<Object?> get props => [unit, scale];
}

/// Effect design tokens (shadows, blur, etc.)
class EffectTokens extends Equatable {
  final Map<String, String> shadows;
  final Map<String, int> borderRadius;

  const EffectTokens({
    required this.shadows,
    required this.borderRadius,
  });

  factory EffectTokens.defaultEffects() {
    return const EffectTokens(
      shadows: {
        'sm': '0 1px 2px rgba(0,0,0,0.05)',
        'md': '0 4px 8px rgba(0,0,0,0.1)',
        'lg': '0 10px 20px rgba(0,0,0,0.15)',
        'xl': '0 20px 40px rgba(0,0,0,0.2)',
      },
      borderRadius: {
        'sm': 4,
        'md': 8,
        'lg': 12,
        'xl': 16,
        'full': 9999,
      },
    );
  }

  factory EffectTokens.fromJson(Map<String, dynamic> json) {
    final defaults = EffectTokens.defaultEffects();
    return EffectTokens(
      shadows: (json['shadows'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as String),
          ) ??
          defaults.shadows,
      borderRadius: (json['borderRadius'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int),
          ) ??
          defaults.borderRadius,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shadows': shadows,
      'borderRadius': borderRadius,
    };
  }

  @override
  List<Object?> get props => [shadows, borderRadius];
}
