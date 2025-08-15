import type { Meta, StoryObj } from '@storybook/react';
import { Button } from '../components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../components/ui/card';
import { ThemeToggle } from '../components/ui/theme-toggle';

const meta: Meta = {
  title: 'Design System/Themes/Light Mode (Bone & Banana Pudding)',
  parameters: {
    layout: 'fullscreen',
    docs: {
      description: {
        component: 'Beautiful bone and banana pudding inspired light theme with warm, creamy colors.',
      },
    },
  },
  tags: ['autodocs'],
};

export default meta;
type Story = StoryObj<typeof meta>;

export const ColorPalette: Story = {
  render: () => (
    <div className="p-8 bg-background text-foreground min-h-screen" data-theme="light">
      <div className="max-w-6xl mx-auto space-y-8">
        <div className="flex items-center justify-between">
          <h1 className="text-4xl font-bold text-bone-900">Bone & Banana Pudding Theme</h1>
          <ThemeToggle />
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          
          {/* Bone Palette */}
          <Card className="bg-bone-50 border-bone-200">
            <CardHeader>
              <CardTitle className="text-bone-900">Bone Palette</CardTitle>
              <CardDescription className="text-bone-600">Warm cream and off-white tones</CardDescription>
            </CardHeader>
            <CardContent className="space-y-3">
              {[
                { name: 'bone-50', desc: 'Pure bone white', value: '60 20% 98%' },
                { name: 'bone-100', desc: 'Lightest cream', value: '54 15% 96%' },
                { name: 'bone-200', desc: 'Light cream', value: '52 12% 92%' },
                { name: 'bone-300', desc: 'Soft cream', value: '50 10% 88%' },
                { name: 'bone-500', desc: 'True bone', value: '46 6% 75%' },
                { name: 'bone-700', desc: 'Deep bone', value: '42 4% 52%' },
                { name: 'bone-900', desc: 'Darkest bone', value: '38 2% 22%' },
              ].map((color) => (
                <div key={color.name} className="flex items-center gap-3">
                  <div 
                    className={`w-8 h-8 rounded-full border border-bone-300`}
                    style={{ backgroundColor: `hsl(${color.value})` }}
                  />
                  <div>
                    <div className="font-medium text-sm">{color.name}</div>
                    <div className="text-xs text-bone-600">{color.desc}</div>
                  </div>
                </div>
              ))}
            </CardContent>
          </Card>

          {/* Banana Pudding Palette */}
          <Card className="bg-pudding-50 border-pudding-200">
            <CardHeader>
              <CardTitle className="text-bone-900">Banana Pudding Palette</CardTitle>
              <CardDescription className="text-bone-600">Warm yellows and golden tones</CardDescription>
            </CardHeader>
            <CardContent className="space-y-3">
              {[
                { name: 'pudding-50', desc: 'Lightest cream', value: '52 85% 95%' },
                { name: 'pudding-100', desc: 'Vanilla cream', value: '50 80% 92%' },
                { name: 'pudding-200', desc: 'Light banana', value: '48 75% 88%' },
                { name: 'pudding-400', desc: 'Medium banana', value: '44 65% 75%' },
                { name: 'pudding-500', desc: 'True banana pudding', value: '42 60% 68%' },
                { name: 'pudding-600', desc: 'Rich banana', value: '40 55% 60%' },
                { name: 'pudding-800', desc: 'Golden brown', value: '36 45% 38%' },
              ].map((color) => (
                <div key={color.name} className="flex items-center gap-3">
                  <div 
                    className={`w-8 h-8 rounded-full border border-pudding-300`}
                    style={{ backgroundColor: `hsl(${color.value})` }}
                  />
                  <div>
                    <div className="font-medium text-sm">{color.name}</div>
                    <div className="text-xs text-bone-600">{color.desc}</div>
                  </div>
                </div>
              ))}
            </CardContent>
          </Card>

          {/* Accent Colors */}
          <Card className="bg-vanilla border-bone-200">
            <CardHeader>
              <CardTitle className="text-bone-900">Accent Colors</CardTitle>
              <CardDescription className="text-bone-600">Complementary warm tones</CardDescription>
            </CardHeader>
            <CardContent className="space-y-3">
              {[
                { name: 'vanilla', desc: 'Soft vanilla', value: '48 35% 88%' },
                { name: 'cream', desc: 'Rich cream', value: '54 25% 94%' },
                { name: 'caramel', desc: 'Rich caramel', value: '32 72% 45%' },
                { name: 'toast', desc: 'Warm toast', value: '36 50% 65%' },
                { name: 'honey', desc: 'Golden honey', value: '44 85% 72%' },
              ].map((color) => (
                <div key={color.name} className="flex items-center gap-3">
                  <div 
                    className={`w-8 h-8 rounded-full border border-bone-300`}
                    style={{ backgroundColor: `hsl(${color.value})` }}
                  />
                  <div>
                    <div className="font-medium text-sm">{color.name}</div>
                    <div className="text-xs text-bone-600">{color.desc}</div>
                  </div>
                </div>
              ))}
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  ),
  parameters: {
    docs: {
      description: {
        story: 'Complete color palette for the bone and banana pudding light theme.',
      },
    },
  },
};

export const ComponentShowcase: Story = {
  render: () => (
    <div className="p-8 bg-background text-foreground min-h-screen" data-theme="light">
      <div className="max-w-4xl mx-auto space-y-8">
        <div className="flex items-center justify-between">
          <h1 className="text-3xl font-bold">Light Theme Components</h1>
          <ThemeToggle />
        </div>
        
        <div className="space-y-6">
          <section>
            <h2 className="text-xl font-semibold mb-4 text-bone-800">Buttons</h2>
            <div className="flex flex-wrap gap-4">
              <Button variant="default">Primary (Banana Pudding)</Button>
              <Button variant="secondary">Secondary (Bone)</Button>
              <Button variant="outline">Outline</Button>
              <Button variant="ghost">Ghost</Button>
              <Button variant="destructive">Destructive</Button>
            </div>
          </section>

          <section>
            <h2 className="text-xl font-semibold mb-4 text-bone-800">Cards</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <Card>
                <CardHeader>
                  <CardTitle>Default Card</CardTitle>
                  <CardDescription>Using bone background with soft shadows</CardDescription>
                </CardHeader>
                <CardContent>
                  <p className="text-sm text-muted-foreground">
                    This card uses the light theme's bone color palette for a warm, 
                    inviting appearance perfect for content display.
                  </p>
                </CardContent>
              </Card>
              
              <Card className="bg-pudding-50 border-pudding-200">
                <CardHeader>
                  <CardTitle className="text-pudding-800">Pudding Card</CardTitle>
                  <CardDescription className="text-pudding-600">Enhanced with banana pudding colors</CardDescription>
                </CardHeader>
                <CardContent>
                  <p className="text-sm text-pudding-700">
                    This variation uses the banana pudding palette for highlighted content
                    or important information sections.
                  </p>
                </CardContent>
              </Card>
            </div>
          </section>

          <section>
            <h2 className="text-xl font-semibold mb-4 text-bone-800">Typography Hierarchy</h2>
            <div className="space-y-4">
              <h1 className="text-4xl font-bold text-bone-900">Heading 1 - Darkest Bone</h1>
              <h2 className="text-3xl font-semibold text-bone-800">Heading 2 - Rich Bone</h2>
              <h3 className="text-2xl font-medium text-bone-700">Heading 3 - Deep Bone</h3>
              <p className="text-base text-bone-900">
                Body text uses the darkest bone color for excellent readability on the 
                light bone background. This creates a warm, comfortable reading experience.
              </p>
              <p className="text-sm text-bone-600">
                Secondary text uses medium bone tones for hierarchy and visual organization
                while maintaining the warm, inviting aesthetic.
              </p>
            </div>
          </section>

          <section>
            <h2 className="text-xl font-semibold mb-4 text-bone-800">State Colors</h2>
            <div className="grid grid-cols-2 gap-4">
              <div className="p-4 bg-green-50 border border-green-200 rounded-lg">
                <h4 className="font-medium text-green-800">Success State</h4>
                <p className="text-sm text-green-700">Warm green tones for positive feedback</p>
              </div>
              <div className="p-4 bg-red-50 border border-red-200 rounded-lg">
                <h4 className="font-medium text-red-800">Error State</h4>
                <p className="text-sm text-red-700">Warm red tones for error messaging</p>
              </div>
              <div className="p-4 bg-orange-50 border border-orange-200 rounded-lg">
                <h4 className="font-medium text-orange-800">Warning State</h4>
                <p className="text-sm text-orange-700">Caramel tones for warnings</p>
              </div>
              <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
                <h4 className="font-medium text-blue-800">Info State</h4>
                <p className="text-sm text-blue-700">Soft blue tones for information</p>
              </div>
            </div>
          </section>
        </div>
      </div>
    </div>
  ),
  parameters: {
    docs: {
      description: {
        story: 'Component showcase demonstrating how the light theme affects all UI elements.',
      },
    },
  },
};