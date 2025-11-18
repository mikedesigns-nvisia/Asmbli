/**
 * Design Token Client
 * Fetches and manages brand design system tokens from Flutter app
 */

import type {
  DesignTokens,
  DesignTokenRequest,
  DesignTokenResponse,
  TokenStylePreset,
} from '../types/design-tokens';

export class DesignTokenClient {
  private bridgeUrl: string;
  private cachedTokens: DesignTokens | null = null;
  private lastFetchTime: number = 0;
  private cacheDuration: number = 5 * 60 * 1000; // 5 minutes

  constructor(bridgeUrl: string = 'http://localhost:3000') {
    this.bridgeUrl = bridgeUrl;
  }

  /**
   * Fetch design tokens from Flutter app
   */
  async fetchTokens(request?: DesignTokenRequest): Promise<DesignTokens> {
    // Check cache first
    const now = Date.now();
    if (this.cachedTokens && (now - this.lastFetchTime) < this.cacheDuration) {
      console.log('Using cached design tokens');
      return this.cachedTokens;
    }

    try {
      const response = await fetch(`${this.bridgeUrl}/api/design-tokens`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(request || { includeDefaults: true }),
      });

      if (!response.ok) {
        throw new Error(`Failed to fetch design tokens: ${response.statusText}`);
      }

      const data: DesignTokenResponse = await response.json();

      if (!data.success || !data.tokens) {
        throw new Error(data.error || 'No tokens returned from Flutter app');
      }

      // Cache the tokens
      this.cachedTokens = data.tokens;
      this.lastFetchTime = now;

      console.log('Design tokens fetched successfully:', data.metadata);
      return data.tokens;
    } catch (error) {
      console.error('Error fetching design tokens:', error);

      // If fetch fails but we have cached tokens, return them
      if (this.cachedTokens) {
        console.log('Using stale cached tokens due to fetch error');
        return this.cachedTokens;
      }

      // Otherwise, return default tokens
      return this.getDefaultTokens();
    }
  }

  /**
   * Get token value by path (e.g., 'colors.primary', 'spacing.lg')
   */
  getTokenValue(tokenPath: string, tokens?: DesignTokens): any {
    const tokensToUse = tokens || this.cachedTokens || this.getDefaultTokens();
    const parts = tokenPath.split('.');

    let value: any = tokensToUse;
    for (const part of parts) {
      if (value && typeof value === 'object' && part in value) {
        value = value[part];
      } else {
        console.warn(`Token path not found: ${tokenPath}`);
        return undefined;
      }
    }

    return value;
  }

  /**
   * Apply token to element property
   */
  applyToken(tokenPath: string, property: string): any {
    const value = this.getTokenValue(tokenPath);

    // Convert token value to property-specific format
    switch (property) {
      case 'fillColor':
      case 'strokeColor':
      case 'color':
        return this.ensureColorFormat(value);

      case 'fontSize':
      case 'width':
      case 'height':
      case 'padding':
      case 'margin':
        return this.ensureNumber(value);

      case 'fontFamily':
        return this.ensureString(value);

      case 'fontWeight':
        return this.ensureFontWeight(value);

      default:
        return value;
    }
  }

  /**
   * Get default design tokens (fallback)
   */
  private getDefaultTokens(): DesignTokens {
    return {
      colors: {
        primary: '#4ECDC4',
        primaryVariant: '#3BA9A1',
        onPrimary: '#FFFFFF',
        secondary: '#FF6B6B',
        secondaryVariant: '#E55A5A',
        onSecondary: '#FFFFFF',
        background: '#F8F9FA',
        surface: '#FFFFFF',
        onBackground: '#2D3E50',
        onSurface: '#2D3E50',
        error: '#EF4444',
        warning: '#F59E0B',
        success: '#10B981',
        info: '#3B82F6',
        textPrimary: '#2D3E50',
        textSecondary: '#6B7280',
        textDisabled: '#9CA3AF',
        border: '#E5E7EB',
        borderLight: '#F3F4F6',
        borderDark: '#D1D5DB',
      },
      spacing: {
        xs: 4,
        sm: 8,
        md: 13,
        lg: 16,
        xl: 21,
        xxl: 24,
        xxxl: 32,
      },
      typography: {
        displayLarge: {
          fontFamily: 'Space Grotesk',
          fontSize: 57,
          fontWeight: 700,
          lineHeight: 64,
        },
        displayMedium: {
          fontFamily: 'Space Grotesk',
          fontSize: 45,
          fontWeight: 700,
          lineHeight: 52,
        },
        displaySmall: {
          fontFamily: 'Space Grotesk',
          fontSize: 36,
          fontWeight: 600,
          lineHeight: 44,
        },
        headingLarge: {
          fontFamily: 'Space Grotesk',
          fontSize: 32,
          fontWeight: 600,
          lineHeight: 40,
        },
        headingMedium: {
          fontFamily: 'Space Grotesk',
          fontSize: 28,
          fontWeight: 600,
          lineHeight: 36,
        },
        headingSmall: {
          fontFamily: 'Space Grotesk',
          fontSize: 24,
          fontWeight: 600,
          lineHeight: 32,
        },
        bodyLarge: {
          fontFamily: 'Space Grotesk',
          fontSize: 16,
          fontWeight: 400,
          lineHeight: 24,
        },
        bodyMedium: {
          fontFamily: 'Space Grotesk',
          fontSize: 14,
          fontWeight: 400,
          lineHeight: 20,
        },
        bodySmall: {
          fontFamily: 'Space Grotesk',
          fontSize: 12,
          fontWeight: 400,
          lineHeight: 16,
        },
        labelLarge: {
          fontFamily: 'Space Grotesk',
          fontSize: 14,
          fontWeight: 500,
          lineHeight: 20,
        },
        labelMedium: {
          fontFamily: 'Space Grotesk',
          fontSize: 12,
          fontWeight: 500,
          lineHeight: 16,
        },
        labelSmall: {
          fontFamily: 'Space Grotesk',
          fontSize: 11,
          fontWeight: 500,
          lineHeight: 16,
        },
      },
      borderRadius: {
        none: 0,
        sm: 2,
        md: 6,
        lg: 8,
        xl: 12,
        full: 9999,
      },
      shadows: {
        none: {
          offsetX: 0,
          offsetY: 0,
          blur: 0,
          spread: 0,
          color: '#000000',
          opacity: 0,
        },
        sm: {
          offsetX: 0,
          offsetY: 1,
          blur: 2,
          spread: 0,
          color: '#000000',
          opacity: 0.05,
        },
        md: {
          offsetX: 0,
          offsetY: 4,
          blur: 6,
          spread: -1,
          color: '#000000',
          opacity: 0.1,
        },
        lg: {
          offsetX: 0,
          offsetY: 10,
          blur: 15,
          spread: -3,
          color: '#000000',
          opacity: 0.1,
        },
        xl: {
          offsetX: 0,
          offsetY: 20,
          blur: 25,
          spread: -5,
          color: '#000000',
          opacity: 0.1,
        },
      },
      animation: {
        durationFast: 150,
        durationMedium: 300,
        durationSlow: 500,
        easingLinear: 'linear',
        easingEaseIn: 'ease-in',
        easingEaseOut: 'ease-out',
        easingEaseInOut: 'ease-in-out',
      },
      version: '1.0.0',
      lastUpdated: new Date().toISOString(),
    };
  }

  /**
   * Get cached tokens
   */
  getCachedTokens(): DesignTokens | null {
    return this.cachedTokens;
  }

  /**
   * Clear cache (force refresh on next fetch)
   */
  clearCache(): void {
    this.cachedTokens = null;
    this.lastFetchTime = 0;
  }

  /**
   * Set cache duration
   */
  setCacheDuration(milliseconds: number): void {
    this.cacheDuration = milliseconds;
  }

  /**
   * Update bridge URL
   */
  setBridgeUrl(url: string): void {
    this.bridgeUrl = url;
  }

  // Helper methods for type conversion

  private ensureColorFormat(value: any): string {
    if (typeof value === 'string') {
      // Ensure it starts with #
      return value.startsWith('#') ? value : `#${value}`;
    }
    return '#000000'; // Default black
  }

  private ensureNumber(value: any): number {
    if (typeof value === 'number') {
      return value;
    }
    if (typeof value === 'string') {
      const parsed = parseFloat(value);
      return isNaN(parsed) ? 0 : parsed;
    }
    return 0;
  }

  private ensureString(value: any): string {
    return String(value);
  }

  private ensureFontWeight(value: any): string | number {
    if (typeof value === 'number') {
      return value;
    }
    if (typeof value === 'string') {
      // Convert named weights to numbers
      const weightMap: Record<string, number> = {
        'thin': 100,
        'extralight': 200,
        'light': 300,
        'normal': 400,
        'regular': 400,
        'medium': 500,
        'semibold': 600,
        'bold': 700,
        'extrabold': 800,
        'black': 900,
      };
      return weightMap[value.toLowerCase()] || value;
    }
    return 400; // Default to normal
  }

  /**
   * Get style preset by name
   */
  async getStylePreset(presetName: string): Promise<TokenStylePreset | null> {
    try {
      const response = await fetch(`${this.bridgeUrl}/api/style-presets/${presetName}`);

      if (!response.ok) {
        return null;
      }

      const preset: TokenStylePreset = await response.json();
      return preset;
    } catch (error) {
      console.error('Error fetching style preset:', error);
      return null;
    }
  }

  /**
   * Get all available style presets
   */
  async listStylePresets(): Promise<TokenStylePreset[]> {
    try {
      const response = await fetch(`${this.bridgeUrl}/api/style-presets`);

      if (!response.ok) {
        return [];
      }

      const presets: TokenStylePreset[] = await response.json();
      return presets;
    } catch (error) {
      console.error('Error listing style presets:', error);
      return [];
    }
  }
}
