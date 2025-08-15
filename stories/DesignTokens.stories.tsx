import type { Meta, StoryObj } from '@storybook/react';

const meta: Meta = {
  title: 'Design System/Tokens/Overview',
  parameters: {
    layout: 'fullscreen',
    docs: {
      description: {
        component: 'Comprehensive overview of the asmbli design token system.',
      },
    },
  },
  tags: ['autodocs'],
};

export default meta;
type Story = StoryObj<typeof meta>;

export const ColorTokens: Story = {
  render: () => (
    <div className="p-8 space-y-8">
      <h1 className="text-3xl font-bold">Color Tokens</h1>
      
      <section>
        <h2 className="text-2xl font-semibold mb-4">Primary Colors</h2>
        <div className="grid grid-cols-5 gap-4">
          {[50, 100, 200, 300, 400, 500, 600, 700, 800, 900].map((shade) => (
            <div key={shade} className="space-y-2">
              <div 
                className="h-16 rounded-lg border"
                style={{ backgroundColor: `hsl(var(--color-primary-${shade}))` }}
              />
              <div className="text-sm">
                <div className="font-mono">primary-{shade}</div>
                <div className="text-muted-foreground">--color-primary-{shade}</div>
              </div>
            </div>
          ))}
        </div>
      </section>

      <section>
        <h2 className="text-2xl font-semibold mb-4">Semantic Colors</h2>
        <div className="grid grid-cols-4 gap-4">
          {[
            { name: 'background', token: '--color-background' },
            { name: 'foreground', token: '--color-foreground' },
            { name: 'muted', token: '--color-muted' },
            { name: 'accent', token: '--color-accent' },
            { name: 'success', token: '--color-success' },
            { name: 'warning', token: '--color-warning' },
            { name: 'destructive', token: '--color-destructive' },
            { name: 'border', token: '--color-border' },
          ].map((color) => (
            <div key={color.name} className="space-y-2">
              <div 
                className="h-16 rounded-lg border"
                style={{ backgroundColor: `hsl(var(${color.token}))` }}
              />
              <div className="text-sm">
                <div className="font-mono">{color.name}</div>
                <div className="text-muted-foreground">{color.token}</div>
              </div>
            </div>
          ))}
        </div>
      </section>
    </div>
  ),
  parameters: {
    docs: {
      description: {
        story: 'All color tokens in the design system with their CSS custom property names.',
      },
    },
  },
};

export const SpacingTokens: Story = {
  render: () => (
    <div className="p-8 space-y-8">
      <h1 className="text-3xl font-bold">Spacing Tokens</h1>
      
      <section>
        <h2 className="text-2xl font-semibold mb-4">Golden Ratio Spacing</h2>
        <div className="space-y-4">
          {[
            { name: 'phi-xs', value: '0.382rem', token: '--space-phi-xs' },
            { name: 'phi-sm', value: '0.618rem', token: '--space-phi-sm' },
            { name: 'phi-base', value: '1rem', token: '--space-phi-base' },
            { name: 'phi-md', value: '1.618rem', token: '--space-phi-md' },
            { name: 'phi-lg', value: '2.618rem', token: '--space-phi-lg' },
            { name: 'phi-xl', value: '4.236rem', token: '--space-phi-xl' },
            { name: 'phi-2xl', value: '6.854rem', token: '--space-phi-2xl' },
          ].map((space) => (
            <div key={space.name} className="flex items-center gap-4">
              <div className="w-32 text-sm font-mono">{space.name}</div>
              <div 
                className="bg-primary h-4 rounded"
                style={{ width: space.value }}
              />
              <div className="text-sm text-muted-foreground">
                {space.value} ({space.token})
              </div>
            </div>
          ))}
        </div>
      </section>

      <section>
        <h2 className="text-2xl font-semibold mb-4">Component Spacing</h2>
        <div className="space-y-4">
          {[
            { name: 'component-padding-xs', value: 'var(--space-3)', description: '12px' },
            { name: 'component-padding-sm', value: 'var(--space-4)', description: '16px' },
            { name: 'component-padding-md', value: 'var(--space-6)', description: '24px' },
            { name: 'component-padding-lg', value: 'var(--space-8)', description: '32px' },
            { name: 'component-padding-xl', value: 'var(--space-12)', description: '48px' },
          ].map((space) => (
            <div key={space.name} className="flex items-center gap-4">
              <div className="w-48 text-sm font-mono">{space.name}</div>
              <div 
                className="bg-secondary border rounded p-2"
                style={{ padding: space.value }}
              >
                <div className="bg-primary w-16 h-4 rounded" />
              </div>
              <div className="text-sm text-muted-foreground">
                {space.description}
              </div>
            </div>
          ))}
        </div>
      </section>
    </div>
  ),
  parameters: {
    docs: {
      description: {
        story: 'Spacing tokens including golden ratio and component-specific spacing.',
      },
    },
  },
};

export const TypographyTokens: Story = {
  render: () => (
    <div className="p-8 space-y-8">
      <h1 className="text-3xl font-bold">Typography Tokens</h1>
      
      <section>
        <h2 className="text-2xl font-semibold mb-4">Font Sizes</h2>
        <div className="space-y-4">
          {[
            { name: 'text-xs', token: '--text-xs', value: '12px' },
            { name: 'text-sm', token: '--text-sm', value: '14px' },
            { name: 'text-base', token: '--text-base', value: '16px' },
            { name: 'text-lg', token: '--text-lg', value: '18px' },
            { name: 'text-xl', token: '--text-xl', value: '20px' },
            { name: 'text-2xl', token: '--text-2xl', value: '24px' },
            { name: 'text-3xl', token: '--text-3xl', value: '30px' },
            { name: 'text-4xl', token: '--text-4xl', value: '36px' },
          ].map((size) => (
            <div key={size.name} className="flex items-baseline gap-4">
              <div className="w-24 text-sm font-mono">{size.name}</div>
              <div 
                className="font-medium"
                style={{ fontSize: `var(${size.token})` }}
              >
                The quick brown fox jumps
              </div>
              <div className="text-sm text-muted-foreground">
                {size.value} ({size.token})
              </div>
            </div>
          ))}
        </div>
      </section>

      <section>
        <h2 className="text-2xl font-semibold mb-4">Font Families</h2>
        <div className="space-y-4">
          <div className="space-y-2">
            <div className="text-sm font-mono">--font-sans</div>
            <div style={{ fontFamily: 'var(--font-sans)' }} className="text-lg">
              Inter, system sans-serif stack
            </div>
          </div>
          <div className="space-y-2">
            <div className="text-sm font-mono">--font-display</div>
            <div style={{ fontFamily: 'var(--font-display)' }} className="text-lg">
              Noto Sans JP, display typography
            </div>
          </div>
          <div className="space-y-2">
            <div className="text-sm font-mono">--font-mono</div>
            <div style={{ fontFamily: 'var(--font-mono)' }} className="text-lg">
              JetBrains Mono, monospace code
            </div>
          </div>
        </div>
      </section>
    </div>
  ),
  parameters: {
    docs: {
      description: {
        story: 'Typography tokens including font sizes, families, and weights.',
      },
    },
  },
};