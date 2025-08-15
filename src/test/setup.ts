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

// Mock ResizeObserver
global.ResizeObserver = class ResizeObserver {
  constructor(callback: ResizeObserverCallback) {}
  observe(target: Element) {}
  unobserve(target: Element) {}
  disconnect() {}
};

// Mock IntersectionObserver
global.IntersectionObserver = class IntersectionObserver {
  constructor(callback: IntersectionObserverCallback) {}
  observe(target: Element) {}
  unobserve(target: Element) {}
  disconnect() {}
};

// Mock localStorage
const localStorageMock = {
  getItem: vi.fn(),
  setItem: vi.fn(),
  removeItem: vi.fn(),
  clear: vi.fn(),
};
Object.defineProperty(window, 'localStorage', {
  value: localStorageMock
});

// Mock URL methods for file download tests
Object.defineProperty(global.URL, 'createObjectURL', {
  value: vi.fn(() => 'mock-blob-url'),
});

Object.defineProperty(global.URL, 'revokeObjectURL', {
  value: vi.fn(),
});

// Import vi globally for mocks
import { vi } from 'vitest';
(global as any).vi = vi;