import '@testing-library/jest-dom';

// Mock CSS custom properties for testing
Object.defineProperty(window, 'getComputedStyle', {
  value: () => ({
    getPropertyValue: (prop: string) => {
      // Mock design token values
      const tokens: Record<string, string> = {
        '--space-4': '16px',
        '--space-6': '24px',
        '--space-8': '32px',
        '--radius-lg': '8px',
        '--text-base': '16px',
        '--color-primary': '239 84% 67%',
        '--color-background': '240 10% 4%',
        '--color-foreground': '0 0% 98%',
      };
      return tokens[prop] || '';
    },
  }),
});