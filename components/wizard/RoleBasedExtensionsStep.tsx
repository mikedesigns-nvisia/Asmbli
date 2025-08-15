
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Button } from '../ui/button';
import { Layers, CheckCircle, ArrowUp, Zap, MessageSquare, PenTool, BarChart3 } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { WizardData } from '../../types/wizard';
import { Step2Extensions } from './Step2Extensions';

interface RoleBasedExtensionsStepProps {
  data: WizardData;
  onUpdate: (updates: Partial<WizardData>) => void;
  onNext: () => void;
  onPrev: () => void;
}

export function RoleBasedExtensionsStep({ data, onUpdate, onNext, onPrev }: RoleBasedExtensionsStepProps) {
  const { user } = useAuth();

  if (!user) return null;

  // Beginner users get basic pre-selected extensions
  if (user.role === 'beginner') {
    const basicExtensions = [
      {
        id: 'claude-conversation',
        title: 'Claude Conversation',
        description: 'Enhanced conversation capabilities with memory',
        icon: <MessageSquare className="w-6 h-6" />,
        category: 'AI & ML',
        included: true
      },
      {
        id: 'basic-web-search',
        title: 'Web Search',
        description: 'Search the web for current information',
        icon: <BarChart3 className="w-6 h-6" />,
        category: 'Data & Research',
        included: true
      },
      {
        id: 'text-generation',
        title: 'Text Generation',
        description: 'Generate and edit text content',
        icon: <PenTool className="w-6 h-6" />,
        category: 'Content',
        included: true
      }
    ];

    // Auto-configure basic extensions for beginners
    React.useEffect(() => {
      const configuredExtensions = basicExtensions.map(ext => ({
        id: ext.id,
        enabled: ext.included,
        config: {},
        selectedPlatforms: ['claude-desktop', 'lm-studio'],
        category: ext.category,
        securityLevel: 'low'
      }));
      
      onUpdate({ extensions: configuredExtensions });
    }, [onUpdate]);

    return (
      <div className="space-y-8 animate-fadeIn">
        <div>
          <h2 className="text-2xl font-bold text-foreground mb-2">Extensions & Integrations</h2>
          <p className="text-muted-foreground">
            Your agent comes with essential extensions pre-configured and ready to use.
          </p>
        </div>

        <Card className="border-green-500/20 bg-green-500/5">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-green-600">
              <Layers className="w-5 h-5" />
              Essential Extensions Included
            </CardTitle>
            <CardDescription>
              Perfect starter pack for new AI agent builders
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {basicExtensions.map((extension) => (
                <div key={extension.id} className="p-4 bg-background rounded-lg border border-green-200">
                  <div className="flex items-start gap-3">
                    <div className="p-2 bg-green-100 rounded-lg">
                      {extension.icon}
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-2">
                        <h4 className="font-medium">{extension.title}</h4>
                        <CheckCircle className="w-4 h-4 text-green-500" />
                      </div>
                      <p className="text-sm text-muted-foreground mt-1">{extension.description}</p>
                      <Badge variant="outline" className="mt-2 text-xs">
                        {extension.category}
                      </Badge>
                    </div>
                  </div>
                </div>
              ))}
            </div>

            <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
              <div className="flex items-start gap-3">
                <Zap className="w-5 h-5 text-blue-600 mt-0.5" />
                <div>
                  <h4 className="font-medium text-blue-900">Optimized for Local Deployment</h4>
                  <p className="text-sm text-blue-700 mt-1">
                    These extensions work perfectly with LM Studio, Claude Desktop, and other local AI tools. 
                    No complex configuration needed - just deploy and start using your agent!
                  </p>
                </div>
              </div>
            </div>

            <div className="p-4 bg-orange-50 border border-orange-200 rounded-lg">
              <div className="flex items-start gap-3">
                <ArrowUp className="w-5 h-5 text-orange-600 mt-0.5" />
                <div className="flex-1">
                  <h4 className="font-medium text-orange-900">Want Advanced Extensions?</h4>
                  <p className="text-sm text-orange-700 mt-1">
                    Upgrade to access 100+ extensions including databases, APIs, enterprise integrations, and custom connectors.
                  </p>
                  <div className="flex gap-2 mt-3">
                    <Button 
                      size="sm" 
                      variant="outline" 
                      className="border-orange-300 text-orange-700 hover:bg-orange-100"
                      onClick={() => updateUserRole('power_user')}
                    >
                      Power User - 25+ Extensions
                    </Button>
                    <Button 
                      size="sm" 
                      variant="outline" 
                      className="border-orange-300 text-orange-700 hover:bg-orange-100"
                      onClick={() => updateUserRole('enterprise')}
                    >
                      Enterprise - All Extensions
                    </Button>
                  </div>
                </div>
              </div>
            </div>

            <div className="flex justify-between pt-4">
              <Button variant="outline" onClick={onPrev}>
                Previous
              </Button>
              <Button onClick={onNext} className="bg-green-600 hover:bg-green-700">
                Continue with Essential Extensions
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }

  // Power User and Enterprise get full extensions access
  return <Step2Extensions data={data} onUpdate={onUpdate} onNext={onNext} onPrev={onPrev} />;
}