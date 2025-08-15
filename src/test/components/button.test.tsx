import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { Button } from '../../../components/ui/button';
import { validateComponentTokenUsage } from '../../utils/design-token-validator';

describe('Button Component - Design System Compliance', () => {
  it('should render with proper design token classes', () => {
    render(<Button>Test Button</Button>);
    const button = screen.getByRole('button');
    
    // Check for design system classes
    expect(button).toHaveClass('inline-flex');
    expect(button).toHaveClass('items-center');
    expect(button).toHaveClass('justify-center');
    expect(button).toHaveClass('rounded-md'); // Should use --radius-base
  });

  it('should apply variant classes correctly', () => {
    const { rerender } = render(<Button variant="destructive">Destructive</Button>);
    let button = screen.getByRole('button');
    expect(button).toHaveClass('bg-destructive');
    expect(button).toHaveClass('text-destructive-foreground');

    rerender(<Button variant="outline">Outline</Button>);
    button = screen.getByRole('button');
    expect(button).toHaveClass('border');
    expect(button).toHaveClass('border-input');
    expect(button).toHaveClass('bg-background');
  });

  it('should apply size classes correctly', () => {
    const { rerender } = render(<Button size="sm">Small</Button>);
    let button = screen.getByRole('button');
    expect(button).toHaveClass('h-8');
    expect(button).toHaveClass('px-3');

    rerender(<Button size="lg">Large</Button>);
    button = screen.getByRole('button');
    expect(button).toHaveClass('h-10');
    expect(button).toHaveClass('px-8');
  });

  it('should pass design token validation', () => {
    const buttonCode = `
      <Button 
        className="inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium"
        style={{ 
          padding: 'var(--space-2-5) var(--space-4)',
          borderRadius: 'var(--radius-lg)'
        }}
      >
        Button with tokens
      </Button>
    `;
    
    const validation = validateComponentTokenUsage(buttonCode);
    expect(validation.isValid).toBe(true);
    expect(validation.errors).toHaveLength(0);
  });

  it('should detect hardcoded values in inline styles', () => {
    const buttonCodeWithHardcoded = `
      <Button 
        style={{ 
          padding: '10px 16px',
          borderRadius: '8px',
          color: '#3b82f6'
        }}
      >
        Button with hardcoded values
      </Button>
    `;
    
    const validation = validateComponentTokenUsage(buttonCodeWithHardcoded);
    expect(validation.isValid).toBe(false);
    expect(validation.errors.length).toBeGreaterThan(0);
  });

  it('should maintain focus styles with design tokens', () => {
    render(<Button>Focusable Button</Button>);
    const button = screen.getByRole('button');
    
    // Check for focus ring classes that use design tokens
    expect(button).toHaveClass('focus-visible:outline-none');
    expect(button).toHaveClass('focus-visible:ring-1');
    expect(button).toHaveClass('focus-visible:ring-ring');
  });

  it('should handle disabled state correctly', () => {
    render(<Button disabled>Disabled Button</Button>);
    const button = screen.getByRole('button');
    
    expect(button).toBeDisabled();
    expect(button).toHaveClass('disabled:pointer-events-none');
    expect(button).toHaveClass('disabled:opacity-50');
  });
});