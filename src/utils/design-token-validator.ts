/**
 * Design Token Validation Utilities
 * Validates that components use design tokens instead of hardcoded values
 */

export interface ValidationResult {
  isValid: boolean;
  errors: string[];
  warnings: string[];
}

/**
 * Design token mapping for common hardcoded values
 */
const SPACING_TOKENS: Record<string, string> = {
  '2px': 'var(--space-0-5)',
  '4px': 'var(--space-1)',
  '6px': 'var(--space-1-5)',
  '8px': 'var(--space-2)',
  '12px': 'var(--space-3)',
  '16px': 'var(--space-4)',
  '20px': 'var(--space-5)',
  '24px': 'var(--space-6)',
  '32px': 'var(--space-8)',
  '48px': 'var(--space-12)',
  '64px': 'var(--space-16)',
};

const RADIUS_TOKENS: Record<string, string> = {
  '2px': 'var(--radius-sm)',
  '4px': 'var(--radius-base)',
  '6px': 'var(--radius-md)',
  '8px': 'var(--radius-lg)',
  '12px': 'var(--radius-xl)',
  '16px': 'var(--radius-2xl)',
};

const FONT_SIZE_TOKENS: Record<string, string> = {
  '0.75rem': 'var(--text-xs)',
  '0.875rem': 'var(--text-sm)',
  '1rem': 'var(--text-base)',
  '1.125rem': 'var(--text-lg)',
  '1.25rem': 'var(--text-xl)',
  '1.875rem': 'var(--text-3xl)',
  '2.25rem': 'var(--text-4xl)',
};

/**
 * Patterns for detecting hardcoded values
 */
const HARDCODED_PATTERNS = [
  // Spacing values (px, rem, em)
  { pattern: /\b(\d+(?:\.\d+)?)(px|rem|em)\b/g, type: 'spacing' },
  // Hex colors
  { pattern: /#[0-9a-fA-F]{3,8}\b/g, type: 'color' },
  // RGB/RGBA colors
  { pattern: /rgba?\([^)]+\)/g, type: 'color' },
  // HSL colors
  { pattern: /hsla?\([^)]+\)/g, type: 'color' },
];

/**
 * Extract all design tokens from CSS content
 */
export function extractDesignTokens(css: string): string[] {
  const tokenPattern = /var\((--[^)]+)\)/g;
  const tokens: string[] = [];
  let match;
  
  while ((match = tokenPattern.exec(css)) !== null) {
    tokens.push(match[1]);
  }
  
  return [...new Set(tokens)];
}

/**
 * Check for hardcoded values in CSS and suggest design token alternatives
 */
export function checkHardcodedValues(css: string): string[] {
  const violations: string[] = [];
  
  // Skip validation for Tailwind @apply directives
  if (css.includes('@apply')) {
    return violations;
  }
  
  // Skip if already using CSS custom properties
  if (css.includes('var(--')) {
    return violations;
  }
  
  HARDCODED_PATTERNS.forEach(({ pattern, type }) => {
    let match;
    pattern.lastIndex = 0; // Reset regex
    while ((match = pattern.exec(css)) !== null) {
      const value = match[0];
      
      // Get context around the match for better error messages
      const start = Math.max(0, match.index - 10);
      const end = Math.min(css.length, match.index + match[0].length + 10);
      const context = css.slice(start, end).trim();
      
      // Determine appropriate suggestion based on context
      let suggestion: string;
      if (type === 'color') {
        suggestion = 'design token';
      } else if (/border-radius|rounded/.test(context)) {
        suggestion = RADIUS_TOKENS[value] || 'border radius token';
      } else if (/font-size|text/.test(context)) {
        suggestion = FONT_SIZE_TOKENS[value] || 'font size token';
      } else {
        // Default to spacing tokens
        suggestion = SPACING_TOKENS[value] || 'design token';
      }
      
      violations.push(`Hardcoded value detected: ${context} - use ${suggestion} instead`);
    }
  });
  
  return violations;
}

/**
 * Validate that CSS uses design tokens instead of hardcoded values
 */
export function validateDesignTokenUsage(css: string): ValidationResult {
  const errors = checkHardcodedValues(css);
  const warnings: string[] = [];
  
  // Check for missing design token usage
  const tokens = extractDesignTokens(css);
  if (tokens.length === 0 && !css.includes('@apply')) {
    warnings.push('No design tokens detected - consider using CSS custom properties for consistency');
  }
  
  return {
    isValid: errors.length === 0,
    errors,
    warnings,
  };
}

/**
 * Validate a React component for design token compliance
 */
export function validateComponentTokenUsage(componentCode: string): ValidationResult {
  const errors: string[] = [];
  const warnings: string[] = [];
  
  // Extract inline styles - more comprehensive pattern
  const inlineStylePattern = /style\s*=\s*\{\s*([^}]+)\s*\}/gs;
  let match;
  
  while ((match = inlineStylePattern.exec(componentCode)) !== null) {
    const styleContent = match[1];
    
    // Check each style property individually
    const propertyPattern = /(\w+(?:-\w+)*)\s*:\s*['"`]?([^,}]+)['"`]?[,}]/g;
    let propMatch;
    
    while ((propMatch = propertyPattern.exec(styleContent)) !== null) {
      const property = propMatch[1];
      const value = propMatch[2].trim().replace(/['"`]/g, '');
      
      // Skip if already using CSS custom properties
      if (value.includes('var(--')) continue;
      
      // Check for hardcoded values
      const violations = checkHardcodedValues(`${property}: ${value}`);
      errors.push(...violations);
    }
  }
  
  // Check for className patterns with arbitrary values
  const classNamePattern = /className\s*=\s*["`']([^"`']+)["`']/g;
  while ((match = classNamePattern.exec(componentCode)) !== null) {
    const className = match[1];
    
    // Check for Tailwind arbitrary values like p-[16px]
    const arbitraryPattern = /\w+-\[([^\]]+)\]/g;
    let arbMatch;
    while ((arbMatch = arbitraryPattern.exec(className)) !== null) {
      const value = arbMatch[1];
      if (/\d+(px|rem|em)/.test(value) || /#[0-9a-fA-F]{3,8}/.test(value)) {
        errors.push(`Arbitrary Tailwind value detected: ${arbMatch[0]} - use design token classes instead`);
      }
    }
    
    // Check for potential hardcoded Tailwind values
    if (className.includes('p-[') || className.includes('m-[') || className.includes('text-[')) {
      warnings.push(`Consider using design token utility classes instead of: ${className}`);
    }
  }
  
  return {
    isValid: errors.length === 0,
    errors,
    warnings,
  };
}

/**
 * Get available design tokens by category
 */
export function getDesignTokensByCategory() {
  return {
    spacing: {
      standard: ['--space-1', '--space-2', '--space-3', '--space-4', '--space-6', '--space-8', '--space-12'],
      golden: ['--space-phi-xs', '--space-phi-sm', '--space-phi-md', '--space-phi-lg', '--space-phi-xl'],
      component: ['--component-padding-xs', '--component-padding-sm', '--component-padding-md', '--component-padding-lg'],
    },
    colors: {
      semantic: ['--color-background', '--color-foreground', '--color-primary', '--color-secondary'],
      states: ['--color-success', '--color-warning', '--color-destructive'],
      ui: ['--color-border', '--color-input', '--color-muted'],
    },
    typography: {
      sizes: ['--text-xs', '--text-sm', '--text-base', '--text-lg', '--text-xl', '--text-2xl'],
      families: ['--font-sans', '--font-display', '--font-mono'],
      weights: ['--font-normal', '--font-medium', '--font-semibold', '--font-bold'],
    },
    radius: ['--radius-sm', '--radius-base', '--radius-md', '--radius-lg', '--radius-xl'],
  };
}