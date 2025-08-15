import { describe, it, expect } from 'vitest';
import { validateDesignTokenUsage, extractDesignTokens, checkHardcodedValues } from '../utils/design-token-validator';

describe('Design Token Validation', () => {
  describe('validateDesignTokenUsage', () => {
    it('should validate proper design token usage in CSS', () => {
      const validCSS = `
        .component {
          padding: var(--space-4);
          color: hsl(var(--color-primary));
          border-radius: var(--radius-lg);
        }
      `;
      
      const result = validateDesignTokenUsage(validCSS);
      expect(result.isValid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    it('should detect hardcoded values', () => {
      const invalidCSS = `
        .component {
          padding: 16px;
          color: #3b82f6;
          border-radius: 8px;
        }
      `;
      
      const result = validateDesignTokenUsage(invalidCSS);
      expect(result.isValid).toBe(false);
      expect(result.errors.length).toBeGreaterThan(0);
      expect(result.errors.some(error => error.includes('16px'))).toBe(true);
      expect(result.errors.some(error => error.includes('#3b82f6'))).toBe(true);
      expect(result.errors.some(error => error.includes('8px'))).toBe(true);
    });

    it('should allow Tailwind classes', () => {
      const tailwindCSS = `
        .component {
          @apply p-4 text-primary rounded-lg;
        }
      `;
      
      const result = validateDesignTokenUsage(tailwindCSS);
      expect(result.isValid).toBe(true);
    });
  });

  describe('extractDesignTokens', () => {
    it('should extract all design tokens from CSS', () => {
      const css = `
        .component {
          padding: var(--space-4);
          margin: var(--space-phi-md);
          color: hsl(var(--color-primary));
        }
      `;
      
      const tokens = extractDesignTokens(css);
      expect(tokens).toContain('--space-4');
      expect(tokens).toContain('--space-phi-md');
      expect(tokens).toContain('--color-primary');
    });
  });

  describe('checkHardcodedValues', () => {
    it('should detect various hardcoded value patterns', () => {
      const violations = [
        { css: 'padding: 16px', shouldContain: '16px' },
        { css: 'margin: 24px', shouldContain: '24px' },
        { css: 'color: #3b82f6', shouldContain: '#3b82f6' },
        { css: 'border-radius: 8px', shouldContain: '8px' },
        { css: 'font-size: 1rem', shouldContain: '1rem' },
        { css: 'gap: 32px', shouldContain: '32px' },
      ];

      violations.forEach(({ css, shouldContain }) => {
        const result = checkHardcodedValues(css);
        expect(result.length).toBeGreaterThan(0);
        expect(result[0]).toContain(shouldContain);
      });
    });

    it('should not flag valid design token usage', () => {
      const validValues = [
        'padding: var(--space-4)',
        'color: hsl(var(--color-primary))',
        'border-radius: var(--radius-lg)',
        'font-size: var(--text-base)',
      ];

      validValues.forEach((css) => {
        const result = checkHardcodedValues(css);
        expect(result).toHaveLength(0);
      });
    });
  });
});