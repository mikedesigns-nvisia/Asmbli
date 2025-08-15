import type { Meta, StoryObj } from '@storybook/react';
import { ThemeToggle } from './theme-toggle';

const meta: Meta<typeof ThemeToggle> = {
  title: 'Design System/Components/ThemeToggle',
  component: ThemeToggle,
  parameters: {
    layout: 'centered',
    docs: {
      description: {
        component: 'Theme toggle switch between bone/banana pudding light mode and dark mode.',
      },
    },
  },
  tags: ['autodocs'],
};

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
  render: () => (
    <div className="flex items-center gap-4 p-6">
      <span className="text-sm font-medium">Theme Toggle:</span>
      <ThemeToggle />
    </div>
  ),
};

export const ThemeShowcase: Story = {
  render: () => (
    <div className="space-y-6 p-8 bg-background text-foreground border rounded-lg">
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-semibold">Current Theme Showcase</h3>
        <ThemeToggle />
      </div>
      
      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-4">
          <h4 className="text-md font-medium">Colors</h4>
          <div className="space-y-2">
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 bg-primary rounded"></div>
              <span className="text-sm">Primary</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 bg-secondary rounded"></div>
              <span className="text-sm">Secondary</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 bg-muted rounded"></div>
              <span className="text-sm">Muted</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 bg-accent rounded"></div>
              <span className="text-sm">Accent</span>
            </div>
          </div>
        </div>
        
        <div className="space-y-4">
          <h4 className="text-md font-medium">Light Mode Exclusive</h4>
          <div className="space-y-2">
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 bg-bone-300 rounded"></div>
              <span className="text-sm">Bone</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 bg-pudding-400 rounded"></div>
              <span className="text-sm">Banana Pudding</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 bg-vanilla rounded"></div>
              <span className="text-sm">Vanilla</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 bg-caramel rounded"></div>
              <span className="text-sm">Caramel</span>
            </div>
          </div>
        </div>
      </div>
      
      <div className="space-y-3">
        <h4 className="text-md font-medium">Sample UI Elements</h4>
        <div className="flex gap-2">
          <button className="px-4 py-2 bg-primary text-primary-foreground rounded-md text-sm font-medium">
            Primary Button
          </button>
          <button className="px-4 py-2 bg-secondary text-secondary-foreground rounded-md text-sm font-medium">
            Secondary Button
          </button>
        </div>
        <div className="p-4 bg-card text-card-foreground border rounded-lg">
          <p className="text-sm">
            This card adapts to the current theme. In light mode, it uses bone colors with warm shadows.
            In dark mode, it uses the original enterprise dark theme.
          </p>
        </div>
      </div>
    </div>
  ),
  parameters: {
    docs: {
      description: {
        story: 'Complete theme showcase showing how colors adapt between light and dark modes.',
      },
    },
  },
};