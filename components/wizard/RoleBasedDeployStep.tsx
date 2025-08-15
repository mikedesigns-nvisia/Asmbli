import React from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Button } from '../ui/button';
import { Rocket, CheckCircle, ArrowUp, Download, Monitor, Zap } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { WizardData } from '../../types/wizard';
import { Step6Deploy } from './Step6Deploy';

interface RoleBasedDeployStepProps {
  data: WizardData;
  onUpdate: (updates: Partial<WizardData>) => void;
  onStartOver: () => void;
  promptOutput: string;
  deploymentConfigs: Record<string, string>;
  copiedItem: string | null;
  onCopy: (text: string, itemType: string) => Promise<void>;
  onSaveAsTemplate?: () => void;
}

export function RoleBasedDeployStep(props: RoleBasedDeployStepProps) {
  const { user, hasFeature, updateUserRole } = useAuth();

  if (!user) return null;

  // Beginner users get simplified deployment options
  if (user.role === 'beginner') {
    const beginnerDeploymentOptions = [
      {
        id: 'claude-desktop',
        title: 'Claude Desktop',
        description: 'One-click installation for Claude Desktop app',
        icon: <Monitor className="w-8 h-8" />,
        difficulty: 'Beginner',
        time: '2 minutes',
        features: ['Local installation', 'No server needed', 'Works offline'],
        recommended: true
      },
      {
        id: 'lm-studio',
        title: 'LM Studio',
        description: 'Deploy to your local LM Studio instance',
        icon: <Zap className="w-8 h-8" />,
        difficulty: 'Beginner',
        time: '3 minutes',
        features: ['Local AI models', 'Privacy focused', 'No cloud dependency'],
        recommended: false
      }
    ];

    return (
      <div className="space-y-8 animate-fadeIn">
        <div>
          <h2 className="text-2xl font-bold text-foreground mb-2">Deploy Your Agent</h2>
          <p className="text-muted-foreground">
            Your agent is ready! Choose a simple deployment option optimized for beginners.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {beginnerDeploymentOptions.map((option) => (
            <Card 
              key={option.id}
              className={`cursor-pointer transition-all duration-300 hover:shadow-lg ${
                option.recommended ? 'ring-2 ring-green-500 bg-green-50/50' : 'hover:ring-1 hover:ring-primary/30'
              }`}
            >
              {option.recommended && (
                <div className="absolute -top-2 left-4">
                  <Badge className="bg-green-500 text-white">
                    Recommended
                  </Badge>
                </div>
              )}
              
              <CardHeader className="text-center pb-4">
                <div className={`w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4 ${
                  option.recommended ? 'bg-green-100' : 'bg-blue-100'
                }`}>
                  {option.icon}
                </div>
                <CardTitle className="text-xl">{option.title}</CardTitle>
                <CardDescription className="text-sm">{option.description}</CardDescription>
              </CardHeader>
              
              <CardContent className="space-y-4">
                <div className="flex items-center justify-between text-sm">
                  <span className="text-muted-foreground">Difficulty</span>
                  <Badge variant="outline" className="text-green-600 border-green-200">
                    {option.difficulty}
                  </Badge>
                </div>
                
                <div className="flex items-center justify-between text-sm">
                  <span className="text-muted-foreground">Setup Time</span>
                  <span className="font-medium">{option.time}</span>
                </div>
                
                <div className="space-y-2">
                  <div className="text-sm font-medium">Features:</div>
                  {option.features.map((feature, index) => (
                    <div key={index} className="flex items-center gap-2 text-sm">
                      <CheckCircle className="w-3 h-3 text-green-500" />
                      <span>{feature}</span>
                    </div>
                  ))}
                </div>
                
                <Button 
                  className={`w-full ${
                    option.recommended ? 'bg-green-600 hover:bg-green-700' : ''
                  }`}
                  onClick={() => props.onCopy(
                    props.deploymentConfigs[option.id] || 'Configuration not available',
                    option.title
                  )}
                >
                  <Download className="w-4 h-4 mr-2" />
                  Download {option.title} Config
                </Button>
              </CardContent>
            </Card>
          ))}
        </div>

        <Card className="border-orange-500/20 bg-orange-500/5">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-orange-600">
              <ArrowUp className="w-5 h-5" />
              Want More Deployment Options?
            </CardTitle>
            <CardDescription>
              Upgrade to access cloud deployment, Kubernetes, Docker, and enterprise options
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
              <div className="space-y-2">
                <div className="font-medium">Power User ($29/mo)</div>
                <ul className="space-y-1 text-muted-foreground">
                  <li>• Railway, Render, Fly.io</li>
                  <li>• Vercel, Cloud Run</li>
                  <li>• Docker deployment</li>
                  <li>• Custom domains</li>
                </ul>
              </div>
              <div className="space-y-2">
                <div className="font-medium">Enterprise ($199/mo)</div>
                <ul className="space-y-1 text-muted-foreground">
                  <li>• Kubernetes orchestration</li>
                  <li>• Multi-region deployment</li>
                  <li>• Enterprise security</li>
                  <li>• Dedicated support</li>
                </ul>
              </div>
            </div>
            
            <div className="flex gap-2">
              <Button 
                variant="outline" 
                className="border-orange-300 text-orange-700 hover:bg-orange-100"
                onClick={() => updateUserRole('power_user')}
              >
                Upgrade to Power User
              </Button>
              <Button 
                variant="outline" 
                className="border-orange-300 text-orange-700 hover:bg-orange-100"
                onClick={() => updateUserRole('enterprise')}
              >
                Upgrade to Enterprise
              </Button>
            </div>
          </CardContent>
        </Card>

        <div className="flex justify-between pt-4">
          <Button variant="outline" onClick={props.onStartOver}>
            Start Over
          </Button>
          <div className="flex gap-3">
            {props.onSaveAsTemplate && (
              <Button variant="outline" onClick={props.onSaveAsTemplate}>
                Save as Template
              </Button>
            )}
            <Button onClick={props.onStartOver} className="bg-green-600 hover:bg-green-700">
              Build Another Agent
            </Button>
          </div>
        </div>
      </div>
    );
  }

  // Power User and Enterprise get full deployment options
  return <Step6Deploy {...props} />;
}