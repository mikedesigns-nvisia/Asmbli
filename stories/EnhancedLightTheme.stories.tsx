import type { Meta, StoryObj } from '@storybook/react';
import { Button } from '../components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../components/ui/card';
import { Badge } from '../components/ui/badge';
import { ThemeToggle } from '../components/ui/theme-toggle';

const meta: Meta = {
  title: 'Design System/Themes/Enhanced Light Mode',
  parameters: {
    layout: 'fullscreen',
    docs: {
      description: {
        component: 'Enhanced bone and banana pudding light theme with darker colors, rich surfaces, and dark chips/badges.',
      },
    },
  },
  tags: ['autodocs'],
};

export default meta;
type Story = StoryObj<typeof meta>;

export const EnhancedPalette: Story = {
  render: () => (
    <div className="p-8 bg-background text-foreground min-h-screen" data-theme="light">
      <div className="max-w-6xl mx-auto space-y-8">
        <div className="flex items-center justify-between">
          <h1 className="text-4xl font-bold text-bone-950">Enhanced Light Theme</h1>
          <ThemeToggle />
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          
          {/* Enhanced Bone Palette */}
          <Card className="bg-bone-100 border-bone-400">
            <CardHeader>
              <CardTitle className="text-bone-950">Enhanced Bone Palette</CardTitle>
              <CardDescription className="text-bone-700">Darker, richer cream tones</CardDescription>
            </CardHeader>
            <CardContent className="space-y-3">
              {[
                { name: 'bone-50', desc: 'Warmer off-white', value: '54 18% 94%' },
                { name: 'bone-200', desc: 'Medium cream', value: '50 14% 86%' },
                { name: 'bone-400', desc: 'Medium bone', value: '46 10% 72%' },
                { name: 'bone-600', desc: 'Darker bone', value: '42 6% 50%' },
                { name: 'bone-800', desc: 'Rich bone', value: '38 4% 28%' },
                { name: 'bone-950', desc: 'Extra dark', value: '34 2% 12%' },
              ].map((color) => (
                <div key={color.name} className="flex items-center gap-3">
                  <div 
                    className="w-8 h-8 rounded-full border border-bone-400"
                    style={{ backgroundColor: `hsl(${color.value})` }}
                  />
                  <div>
                    <div className="font-medium text-sm">{color.name}</div>
                    <div className="text-xs text-bone-700">{color.desc}</div>
                  </div>
                </div>
              ))}
            </CardContent>
          </Card>

          {/* Surface Colors */}
          <Card className="bg-sidebar border-bone-400 text-sidebar-foreground">
            <CardHeader>
              <CardTitle className="text-bone-950">Surface Colors</CardTitle>
              <CardDescription className="text-bone-700">Sidebar and navbar surfaces</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="p-4 bg-navbar border border-bone-400 rounded-lg">
                <h4 className="font-medium text-sm mb-2">Navbar Surface</h4>
                <p className="text-xs text-bone-700">Uses bone-200 for navigation bars</p>
              </div>
              <div className="p-4 bg-sidebar border border-bone-400 rounded-lg">
                <h4 className="font-medium text-sm mb-2">Sidebar Surface</h4>
                <p className="text-xs text-bone-700">Rich cream for side panels</p>
              </div>
            </CardContent>
          </Card>

          {/* Dark Elements */}
          <Card className="bg-bone-100 border-bone-400">
            <CardHeader>
              <CardTitle className="text-bone-950">Dark Elements</CardTitle>
              <CardDescription className="text-bone-700">Chips and badges for light mode</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <h4 className="font-medium text-sm mb-2">Dark Chips</h4>
                <div className="flex flex-wrap gap-2">
                  <Badge variant="chip">API</Badge>
                  <Badge variant="chip">React</Badge>
                  <Badge variant="chip">TypeScript</Badge>
                </div>
              </div>
              <div>
                <h4 className="font-medium text-sm mb-2">Dark Badges</h4>
                <div className="flex flex-wrap gap-2">
                  <Badge variant="dark">New</Badge>
                  <Badge variant="dark">Pro</Badge>
                  <Badge variant="dark">Beta</Badge>
                </div>
              </div>
              <p className="text-xs text-bone-700">
                Dark elements provide excellent contrast against light backgrounds
              </p>
            </CardContent>
          </Card>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <Card className="bg-bone-100 border-bone-400">
            <CardHeader>
              <CardTitle className="text-bone-950">Enhanced Buttons</CardTitle>
              <CardDescription className="text-bone-700">Rich banana pudding primary</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex flex-wrap gap-3">
                <Button variant="default">Primary</Button>
                <Button variant="secondary">Secondary</Button>
                <Button variant="outline">Outline</Button>
                <Button variant="ghost">Ghost</Button>
              </div>
              <p className="text-xs text-bone-700">
                Buttons use enhanced pudding-600 with better contrast ratios
              </p>
            </CardContent>
          </Card>

          <Card className="bg-bone-100 border-bone-400">
            <CardHeader>
              <CardTitle className="text-bone-950">Typography</CardTitle>
              <CardDescription className="text-bone-700">High contrast text hierarchy</CardDescription>
            </CardHeader>
            <CardContent className="space-y-3">
              <h1 className="text-2xl font-bold text-bone-950">Heading 1</h1>
              <h2 className="text-xl font-semibold text-bone-900">Heading 2</h2>
              <h3 className="text-lg font-medium text-bone-800">Heading 3</h3>
              <p className="text-base text-bone-950">
                Body text with enhanced contrast
              </p>
              <p className="text-sm text-bone-700">
                Secondary text with good readability
              </p>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  ),
  parameters: {
    docs: {
      description: {
        story: 'Enhanced light theme with darker colors, rich surfaces, and dark accent elements.',
      },
    },
  },
};

export const ComponentShowcase: Story = {
  render: () => (
    <div className="min-h-screen bg-background text-foreground" data-theme="light">
      <header className="surface-navbar p-4 border-b border-border">
        <div className="flex items-center justify-between max-w-6xl mx-auto">
          <h1 className="text-xl font-semibold">Enhanced Light Theme App</h1>
          <div className="flex items-center gap-4">
            <Badge variant="chip">v2.0</Badge>
            <ThemeToggle />
          </div>
        </div>
      </header>
      
      <div className="flex">
        <aside className="w-64 surface-sidebar border-r border-border min-h-[calc(100vh-73px)]">
          <div className="p-4 space-y-4">
            <h2 className="font-semibold text-sidebar-foreground">Navigation</h2>
            <nav className="space-y-2">
              <div className="selection-card">
                <div className="flex items-center gap-2">
                  <span>Dashboard</span>
                  <Badge variant="dark">Active</Badge>
                </div>
              </div>
              <div className="selection-card">
                <div className="flex items-center gap-2">
                  <span>Projects</span>
                  <Badge variant="chip">3</Badge>
                </div>
              </div>
              <div className="selection-card">
                <span>Settings</span>
              </div>
            </nav>
          </div>
        </aside>

        <main className="flex-1 p-8">
          <div className="max-w-4xl mx-auto space-y-6">
            <div className="selection-card">
              <h2 className="text-xl font-semibold mb-4">Project Overview</h2>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
                <Card>
                  <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                      API Service
                      <Badge variant="dark">Live</Badge>
                    </CardTitle>
                    <CardDescription>RESTful API endpoints</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="flex gap-2">
                      <Badge variant="chip">Node.js</Badge>
                      <Badge variant="chip">Express</Badge>
                    </div>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                      Frontend App
                      <Badge variant="dark">Dev</Badge>
                    </CardTitle>
                    <CardDescription>React application</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="flex gap-2">
                      <Badge variant="chip">React</Badge>
                      <Badge variant="chip">TypeScript</Badge>
                    </div>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                      Database
                      <Badge variant="dark">Staging</Badge>
                    </CardTitle>
                    <CardDescription>PostgreSQL instance</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="flex gap-2">
                      <Badge variant="chip">PostgreSQL</Badge>
                      <Badge variant="chip">Prisma</Badge>
                    </div>
                  </CardContent>
                </Card>
              </div>
              
              <div className="flex gap-3">
                <Button variant="default">Deploy All</Button>
                <Button variant="secondary">View Logs</Button>
                <Button variant="outline">Settings</Button>
              </div>
            </div>
          </div>
        </main>
      </div>
    </div>
  ),
  parameters: {
    docs: {
      description: {
        story: 'Complete application layout showing enhanced surfaces, dark chips/badges, and improved contrast.',
      },
    },
  },
};