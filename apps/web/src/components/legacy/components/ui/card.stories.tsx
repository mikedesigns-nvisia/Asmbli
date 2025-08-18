import type { Meta, StoryObj } from '@storybook/react';
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from './card';
import { Button } from './button';

const meta: Meta<typeof Card> = {
  title: 'Design System/Components/Card',
  component: Card,
  parameters: {
    layout: 'centered',
    docs: {
      description: {
        component: 'Card component using design system tokens for spacing, colors, and shadows.',
      },
    },
  },
  tags: ['autodocs'],
};

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
  render: () => (
    <Card className="w-[350px]">
      <CardHeader>
        <CardTitle>Card Title</CardTitle>
        <CardDescription>Card description goes here.</CardDescription>
      </CardHeader>
      <CardContent>
        <p>This is the card content area using design system spacing tokens.</p>
      </CardContent>
      <CardFooter>
        <Button>Action</Button>
      </CardFooter>
    </Card>
  ),
};

export const WithDesignTokens: Story = {
  render: () => (
    <div className="space-y-6">
      <h3 className="text-lg font-semibold">Design Token Usage</h3>
      
      {/* Standard card */}
      <Card className="w-[350px]">
        <CardHeader className="component-padding-md">
          <CardTitle className="text-xl font-semibold">Standard Spacing</CardTitle>
          <CardDescription>Uses component-padding-md token</CardDescription>
        </CardHeader>
        <CardContent className="component-padding-md">
          <p>Content with standard design system spacing.</p>
        </CardContent>
      </Card>

      {/* Golden ratio spacing */}
      <Card className="w-[350px]">
        <CardHeader style={{ padding: 'var(--space-phi-md)' }}>
          <CardTitle className="text-xl font-semibold">Golden Ratio Spacing</CardTitle>
          <CardDescription>Uses phi-based spacing tokens</CardDescription>
        </CardHeader>
        <CardContent style={{ padding: 'var(--space-phi-md)' }}>
          <div className="space-y-phi-sm">
            <p>Content with golden ratio spacing.</p>
            <p>Elements spaced using --space-phi-sm.</p>
          </div>
        </CardContent>
      </Card>

      {/* Custom radius */}
      <Card className="w-[350px]" style={{ borderRadius: 'var(--radius-2xl)' }}>
        <CardHeader>
          <CardTitle className="text-xl font-semibold">Custom Radius</CardTitle>
          <CardDescription>Uses --radius-2xl token</CardDescription>
        </CardHeader>
        <CardContent>
          <p>Card with larger border radius from design tokens.</p>
        </CardContent>
      </Card>
    </div>
  ),
  parameters: {
    docs: {
      description: {
        story: 'Cards demonstrating various design token usage patterns.',
      },
    },
  },
};

export const SpacingVariations: Story = {
  render: () => (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
      <Card className="component-padding-xs">
        <CardHeader>
          <CardTitle>Extra Small Padding</CardTitle>
          <CardDescription>component-padding-xs</CardDescription>
        </CardHeader>
        <CardContent>
          <p>Compact card layout.</p>
        </CardContent>
      </Card>

      <Card className="component-padding-sm">
        <CardHeader>
          <CardTitle>Small Padding</CardTitle>
          <CardDescription>component-padding-sm</CardDescription>
        </CardHeader>
        <CardContent>
          <p>Small card layout.</p>
        </CardContent>
      </Card>

      <Card className="component-padding-md">
        <CardHeader>
          <CardTitle>Medium Padding</CardTitle>
          <CardDescription>component-padding-md</CardDescription>
        </CardHeader>
        <CardContent>
          <p>Medium card layout.</p>
        </CardContent>
      </Card>

      <Card className="component-padding-lg">
        <CardHeader>
          <CardTitle>Large Padding</CardTitle>
          <CardDescription>component-padding-lg</CardDescription>
        </CardHeader>
        <CardContent>
          <p>Large card layout.</p>
        </CardContent>
      </Card>
    </div>
  ),
  parameters: {
    docs: {
      description: {
        story: 'Cards showing different padding sizes using design system component tokens.',
      },
    },
  },
};