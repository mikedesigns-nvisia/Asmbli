/**
 * Design Token Types
 * Type definitions for brand design system tokens from Flutter app
 */

/**
 * Color palette with semantic naming
 */
export interface ColorTokens {
  // Primary brand colors
  primary: string;
  primaryVariant: string;
  onPrimary: string;

  // Secondary/accent colors
  secondary: string;
  secondaryVariant: string;
  onSecondary: string;

  // Background colors
  background: string;
  surface: string;
  onBackground: string;
  onSurface: string;

  // Semantic colors
  error: string;
  warning: string;
  success: string;
  info: string;

  // Text colors
  textPrimary: string;
  textSecondary: string;
  textDisabled: string;

  // Border colors
  border: string;
  borderLight: string;
  borderDark: string;

  // Additional brand colors
  [key: string]: string;
}

/**
 * Spacing scale using golden ratio
 */
export interface SpacingTokens {
  xs: number;      // 4px
  sm: number;      // 8px
  md: number;      // 13px
  lg: number;      // 16px
  xl: number;      // 21px
  xxl: number;     // 24px
  xxxl: number;    // 32px
  [key: string]: number;
}

/**
 * Typography system
 */
export interface TypographyToken {
  fontFamily: string;
  fontSize: number;
  fontWeight: string | number;
  lineHeight: number;
  letterSpacing?: number;
}

export interface TypographyTokens {
  // Display styles
  displayLarge: TypographyToken;
  displayMedium: TypographyToken;
  displaySmall: TypographyToken;

  // Heading styles
  headingLarge: TypographyToken;
  headingMedium: TypographyToken;
  headingSmall: TypographyToken;

  // Body styles
  bodyLarge: TypographyToken;
  bodyMedium: TypographyToken;
  bodySmall: TypographyToken;

  // Label styles
  labelLarge: TypographyToken;
  labelMedium: TypographyToken;
  labelSmall: TypographyToken;

  [key: string]: TypographyToken;
}

/**
 * Border radius tokens
 */
export interface BorderRadiusTokens {
  none: number;
  sm: number;
  md: number;
  lg: number;
  xl: number;
  full: number;
  [key: string]: number;
}

/**
 * Shadow tokens
 */
export interface ShadowToken {
  offsetX: number;
  offsetY: number;
  blur: number;
  spread: number;
  color: string;
  opacity: number;
}

export interface ShadowTokens {
  none: ShadowToken;
  sm: ShadowToken;
  md: ShadowToken;
  lg: ShadowToken;
  xl: ShadowToken;
  [key: string]: ShadowToken;
}

/**
 * Animation tokens
 */
export interface AnimationTokens {
  durationFast: number;
  durationMedium: number;
  durationSlow: number;
  easingLinear: string;
  easingEaseIn: string;
  easingEaseOut: string;
  easingEaseInOut: string;
  [key: string]: number | string;
}

/**
 * Complete design token system
 */
export interface DesignTokens {
  colors: ColorTokens;
  spacing: SpacingTokens;
  typography: TypographyTokens;
  borderRadius: BorderRadiusTokens;
  shadows: ShadowTokens;
  animation: AnimationTokens;
  version?: string;
  lastUpdated?: string;
}

/**
 * Design token request from Flutter app
 */
export interface DesignTokenRequest {
  brandId?: string;
  includeDefaults?: boolean;
}

/**
 * Design token response from Flutter app
 */
export interface DesignTokenResponse {
  success: boolean;
  tokens?: DesignTokens;
  error?: string;
  metadata?: {
    brandName?: string;
    version?: string;
    lastUpdated?: string;
  };
}

/**
 * Design token application to canvas elements
 */
export interface TokenApplication {
  elementId: string;
  tokenType: 'color' | 'spacing' | 'typography' | 'borderRadius' | 'shadow';
  tokenPath: string; // e.g., 'colors.primary', 'spacing.lg'
  property: string;  // e.g., 'fillColor', 'padding', 'fontSize'
}

/**
 * Token-based style preset
 */
export interface TokenStylePreset {
  name: string;
  description?: string;
  tokens: {
    colors?: Partial<ColorTokens>;
    spacing?: Partial<SpacingTokens>;
    typography?: Partial<TypographyTokens>;
    borderRadius?: Partial<BorderRadiusTokens>;
    shadows?: Partial<ShadowTokens>;
  };
}
