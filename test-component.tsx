import React from 'react';

// This component has hardcoded values that should be detected
export function TestComponent() {
  return (
    <div 
      style={{
        padding: '16px',        // Should suggest var(--space-4)
        margin: '24px',         // Should suggest var(--space-6)
        borderRadius: '8px',    // Should suggest var(--radius-lg)
        color: '#3b82f6',       // Should suggest design token
        fontSize: '1rem'        // Should suggest var(--text-base)
      }}
      className="p-[16px] text-[#3b82f6]" // Should detect arbitrary values
    >
      Test component with hardcoded values
    </div>
  );
}

// This component uses design tokens correctly
export function GoodComponent() {
  return (
    <div 
      style={{
        padding: 'var(--space-4)',
        margin: 'var(--space-6)',
        borderRadius: 'var(--radius-lg)',
        color: 'hsl(var(--color-primary))',
        fontSize: 'var(--text-base)'
      }}
      className="p-4 text-primary rounded-lg"
    >
      Component using design tokens correctly
    </div>
  );
}