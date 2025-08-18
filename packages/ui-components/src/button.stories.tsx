import type { Meta, StoryObj } from '@storybook/react';
import { Button } from './button';

const meta: Meta<typeof Button> = {
  title: 'Design System/Components/Button',
  component: Button,
  parameters: {
    layout: 'centered',
    docs: {
      description: {
        component: 'Button component built with design tokens for consistent styling and behavior.',
      },
    },
  },
  tags: ['autodocs'],
  argTypes: {
    variant: {
      control: { type: 'select' },
      options: ['default', 'destructive', 'outline', 'secondary', 'ghost', 'link'],
      description: 'Visual style variant using design system tokens',
    },
    size: {
      control: { type: 'select' },
      options: ['default', 'sm', 'lg', 'icon'],
      description: 'Size variant using design system spacing tokens',
    },
    asChild: {
      control: 'boolean',
      description: 'Render as child element',
    },
    disabled: {
      control: 'boolean',
      description: 'Disabled state',
    },
  },
};

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
  args: {
    children: 'Button',
  },
};

export const Variants: Story = {
  render: () => (
    <div className="flex flex-wrap gap-4">
      <Button variant="default">Default</Button>
      <Button variant="secondary">Secondary</Button>
      <Button variant="destructive">Destructive</Button>
      <Button variant="outline">Outline</Button>
      <Button variant="ghost">Ghost</Button>
      <Button variant="link">Link</Button>
    </div>
  ),
  parameters: {
    docs: {
      description: {
        story: 'All button variants using design system color tokens.',
      },
    },
  },
};

export const Sizes: Story = {
  render: () => (
    <div className="flex flex-wrap items-center gap-4">
      <Button size="sm">Small</Button>
      <Button size="default">Default</Button>
      <Button size="lg">Large</Button>
      <Button size="icon">🚀</Button>
    </div>
  ),
  parameters: {
    docs: {
      description: {
        story: 'Button sizes using design system spacing tokens.',
      },
    },
  },
};

export const States: Story = {
  render: () => (
    <div className="flex flex-wrap gap-4">
      <Button>Normal</Button>
      <Button disabled>Disabled</Button>
      <Button className="hover:bg-primary/90">Hover (simulated)</Button>
      <Button className="focus-visible:ring-1 focus-visible:ring-ring">Focus (simulated)</Button>
    </div>
  ),
  parameters: {
    docs: {
      description: {
        story: 'Button states showing design token usage for interactions.',
      },
    },
  },
};

// Design token validation story
export const DesignTokenValidation: Story = {
  render: () => (
    <div className="space-y-4 p-6 border rounded-lg">
      <h3 className="text-lg font-semibold">Design Token Validation</h3>
      <div className="space-y-2 text-sm">
        <p><strong>Colors:</strong> Uses CSS custom properties from design-tokens.css</p>
        <p><strong>Spacing:</strong> Uses --space-* tokens for padding</p>
        <p><strong>Border Radius:</strong> Uses --radius-* tokens</p>
        <p><strong>Typography:</strong> Uses --text-* and --font-* tokens</p>
      </div>
      <div className="grid grid-cols-2 gap-4">
        <Button style={{ 
          backgroundColor: 'hsl(var(--color-primary))',
          color: 'hsl(var(--color-primary-foreground))',
          padding: 'var(--space-2-5) var(--space-4)',
          borderRadius: 'var(--radius-lg)',
          fontSize: 'var(--text-base)'
        }}>
          Direct Token Usage
        </Button>
        <Button>Tailwind Classes</Button>
      </div>
    </div>
  ),
  parameters: {
    docs: {
      description: {
        story: 'Demonstrates direct design token usage vs Tailwind classes.',
      },
    },
  },
};