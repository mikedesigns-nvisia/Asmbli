import React, { useState } from 'react';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Textarea } from '../ui/textarea';
import { Label } from '../ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Bot, Settings, Target, Zap } from 'lucide-react';
import { SavedTemplatesWidget } from '../templates/SavedTemplatesWidget';
import { AgentTemplate } from '../../types/templates';

interface Step1AgentProfileProps {
  data: any;
  onUpdate: (updates: any) => void;
  onNext: () => void;
  onUseTemplate?: (template: AgentTemplate) => void;
  onViewAllTemplates?: () => void;
}

export function Step1AgentProfile({ data, onUpdate, onNext, onUseTemplate, onViewAllTemplates }: Step1AgentProfileProps) {
  const [formData, setFormData] = useState({
    agentName: data.agentName || '',
    agentDescription: data.agentDescription || '',
    primaryPurpose: data.primaryPurpose || '',
    targetEnvironment: data.targetEnvironment || 'development'
  });

  const purposeOptions = [
    {
      id: 'chatbot',
      title: 'Conversational Assistant',
      description: 'Interactive chatbot for customer support, general assistance, and conversational AI',
      icon: Bot,
      capabilities: ['Natural Language Processing', 'Context Awareness', 'Multi-turn Conversations']
    },
    {
      id: 'content-creator', 
      title: 'Content Creator',
      description: 'Professional content generation for marketing, documentation, and creative writing',
      icon: Target,
      capabilities: ['Content Strategy', 'SEO Optimization', 'Brand Voice Consistency']
    },
    {
      id: 'data-analyst',
      title: 'Data Analyst',
      description: 'Advanced data analysis, pattern recognition, and business intelligence insights',
      icon: Settings,
      capabilities: ['Statistical Analysis', 'Data Visualization', 'Predictive Modeling']
    },
    {
      id: 'developer-assistant',
      title: 'Developer Assistant', 
      description: 'Code generation, debugging, architecture guidance, and technical mentoring',
      icon: Zap,
      capabilities: ['Code Generation', 'Architecture Review', 'Best Practices']
    },
    {
      id: 'research-assistant',
      title: 'Research Assistant',
      description: 'Comprehensive research, fact-checking, citation management, and knowledge synthesis',
      icon: Target,
      capabilities: ['Information Synthesis', 'Citation Management', 'Fact Verification']
    }
  ];

  const environmentOptions = [
    {
      value: 'development',
      label: 'Development',
      description: 'Testing environment with debug features and extensive logging',
      features: ['Debug Mode', 'Verbose Logging', 'Fast Iterations']
    },
    {
      value: 'staging',
      label: 'Staging',
      description: 'Pre-production environment for final testing and validation',
      features: ['Production Mirror', 'Integration Testing', 'Performance Monitoring']
    },
    {
      value: 'production',
      label: 'Production',
      description: 'Live environment with optimized performance and reliability',
      features: ['High Availability', 'Auto-scaling', 'Advanced Security']
    }
  ];

  const handleInputChange = (field: string, value: string) => {
    const updated = { ...formData, [field]: value };
    setFormData(updated);
    onUpdate(updated);
  };



  return (
    <div className="space-y-8 animate-fadeIn">
      <div className="text-center space-y-4">
        <h1 className="bg-gradient-to-r from-primary to-purple-400 bg-clip-text text-transparent">
          Agent Profile Configuration
        </h1>
        <p className="text-muted-foreground max-w-2xl mx-auto">
          Define your AI agent's identity, purpose, and deployment environment. This forms the foundation
          for selecting the right extensions and configuring your agent's behavior.
        </p>
      </div>

      <div className="space-y-8">
        {/* Basic Information - Full Width */}
        <Card className="selection-card">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Bot className="w-5 h-5 text-primary" />
              Basic Information
            </CardTitle>
            <CardDescription>
              Fundamental details that define your agent's identity
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-6">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              <div className="space-y-2">
                <Label htmlFor="agent-name">Agent Name *</Label>
                <Input
                  id="agent-name"
                  placeholder="e.g., CustomerSupport AI, ContentCreator Pro"
                  value={formData.agentName}
                  onChange={(e) => handleInputChange('agentName', e.target.value)}
                  className="bg-input-background"
                />
                <p className="text-xs text-muted-foreground">
                  Choose a descriptive name that reflects your agent's role
                </p>
              </div>

              <div className="space-y-2 lg:row-span-2">
                <Label htmlFor="agent-description">Agent Description *</Label>
                <Textarea
                  id="agent-description"
                  placeholder="Describe your agent's purpose, capabilities, and target use cases..."
                  value={formData.agentDescription}
                  onChange={(e) => handleInputChange('agentDescription', e.target.value)}
                  className="bg-input-background min-h-[120px] resize-none"
                />
                <p className="text-xs text-muted-foreground">
                  Provide context about your agent's intended use and capabilities
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Target Environment - Full Width */}
        <Card className="selection-card">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Settings className="w-5 h-5 text-primary" />
              Target Environment
            </CardTitle>
            <CardDescription>
              Choose the deployment environment for your agent
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
              {environmentOptions.map((env) => (
                <div
                  key={env.value}
                  className={`p-4 rounded-lg border cursor-pointer transition-all duration-200 hover:border-primary/50 ${ 
                    formData.targetEnvironment === env.value
                      ? 'border-primary bg-primary/5'
                      : 'border-border'
                  }`}
                  onClick={() => handleInputChange('targetEnvironment', env.value)}
                >
                  <div className="flex items-start justify-between">
                    <div className="space-y-1">
                      <div className="flex items-center gap-2">
                        <h4 className="font-medium">{env.label}</h4>
                        {formData.targetEnvironment === env.value && (
                          <Badge variant="secondary" className="chip-hug text-xs">Selected</Badge>
                        )}
                      </div>
                      <p className="text-sm text-muted-foreground">{env.description}</p>
                    </div>
                  </div>
                  <div className="flex flex-wrap gap-1 mt-3">
                    {env.features.map((feature) => (
                      <Badge key={feature} variant="outline" className="chip-hug text-xs">
                        {feature}
                      </Badge>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Saved Templates Widget - Full Width */}
        {onUseTemplate && onViewAllTemplates && (
          <SavedTemplatesWidget
            onUseTemplate={onUseTemplate}
            onViewAllTemplates={onViewAllTemplates}
          />
        )}
      </div>

      {/* Primary Purpose Selection */}
      <Card className="selection-card">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Target className="w-5 h-5 text-primary" />
            Primary Purpose *
          </CardTitle>
          <CardDescription>
            Select your agent's main function and specialization area
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {purposeOptions.map((option) => {
              const Icon = option.icon;
              const isSelected = formData.primaryPurpose === option.id;
              
              return (
                <div
                  key={option.id}
                  className={`p-6 rounded-xl border cursor-pointer transition-all duration-300 hover:border-primary/50 hover:-translate-y-1 ${
                    isSelected
                      ? 'border-primary bg-gradient-to-br from-primary/10 to-transparent shadow-lg'
                      : 'border-border hover:shadow-md'
                  }`}
                  onClick={() => handleInputChange('primaryPurpose', option.id)}
                  style={{
                    background: isSelected 
                      ? 'rgba(24, 24, 27, 0.9)' 
                      : 'rgba(24, 24, 27, 0.6)',
                    backdropFilter: 'blur(12px)'
                  }}
                >
                  <div className="space-y-4">
                    <div className="flex items-center justify-between">
                      <Icon className={`w-8 h-8 ${isSelected ? 'text-primary' : 'text-muted-foreground'}`} />
                      {isSelected && (
                        <Badge className="chip-hug bg-primary/20 text-primary border-primary/30">
                          Selected
                        </Badge>
                      )}
                    </div>
                    
                    <div className="space-y-2">
                      <h3 className="font-semibold">{option.title}</h3>
                      <p className="text-sm text-muted-foreground leading-relaxed">
                        {option.description}
                      </p>
                    </div>

                    <div className="flex flex-wrap gap-1">
                      {option.capabilities.map((capability) => (
                        <Badge 
                          key={capability} 
                          variant="outline" 
                          className={`chip-hug text-xs ${isSelected ? 'border-primary/30' : ''}`}
                        >
                          {capability}
                        </Badge>
                      ))}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </CardContent>
      </Card>


    </div>
  );
}