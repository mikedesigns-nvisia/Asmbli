import React, { useState } from 'react';
import { Button } from '../ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Slider } from '../ui/slider';
import { Textarea } from '../ui/textarea';
import { Label } from '../ui/label';
import { Collapsible, CollapsibleContent, CollapsibleTrigger } from '../ui/collapsible';
import { ArrowRight, ArrowLeft, MessageSquare, Palette, CheckCircle, FileText, Zap, Brain, Heart, Briefcase, ChevronDown, ChevronRight, FileEdit, Figma, Layers, Paintbrush, Component, Ruler, BookOpen } from 'lucide-react';

interface Step4BehaviorStyleProps {
  data: any;
  onUpdate: (updates: any) => void;
  onNext: () => void;
  onPrev: () => void;
}

export function Step4BehaviorStyle({ data, onUpdate, onNext, onPrev }: Step4BehaviorStyleProps) {
  const [behaviorConfig, setBehaviorConfig] = useState({
    tone: data.tone || null,
    responseLength: data.responseLength || 3,
    constraints: data.constraints || [],
    constraintDocs: data.constraintDocs || {}
  });

  const [expandedConstraints, setExpandedConstraints] = useState<Record<string, boolean>>({});

  const toneOptions = [
    {
      id: 'professional',
      name: 'Professional',
      description: 'Business-appropriate, formal, and authoritative communication',
      icon: Briefcase,
      characteristics: ['Formal Language', 'Clear Structure', 'Authoritative Tone', 'Business Focus'],
      example: 'I can assist you with analyzing your quarterly performance metrics to identify key growth opportunities and optimization strategies.'
    },
    {
      id: 'friendly',
      name: 'Friendly',
      description: 'Warm, approachable, and conversational interactions',
      icon: Heart,
      characteristics: ['Conversational', 'Warm Tone', 'Approachable', 'Empathetic'],
      example: 'I\'d be happy to help you explore your data! Let\'s dive into those metrics and see what interesting insights we can discover together.'
    },
    {
      id: 'technical',
      name: 'Technical',
      description: 'Precise, detailed, and technically accurate responses',
      icon: Brain,
      characteristics: ['Technical Precision', 'Detailed Explanations', 'Accuracy Focus', 'Expert Language'],
      example: 'Based on your dataset\'s statistical distribution (μ=45.7, σ=12.3), I recommend implementing a Z-score normalization technique for optimal model performance.'
    },
    {
      id: 'creative',
      name: 'Creative',
      description: 'Imaginative, innovative, and engaging communication style',
      icon: Palette,
      characteristics: ['Imaginative Language', 'Creative Solutions', 'Engaging Tone', 'Innovative Thinking'],
      example: 'Think of your data as a treasure map! Those patterns we\'re seeing are like hidden gems waiting to be discovered and transformed into actionable insights.'
    },
    {
      id: 'analytical',
      name: 'Analytical',
      description: 'Logical, structured, and data-driven communication',
      icon: Zap,
      characteristics: ['Data-Driven', 'Logical Structure', 'Evidence-Based', 'Systematic Approach'],
      example: 'The data indicates three primary trends: (1) 23% increase in Q3 performance, (2) seasonal variance of ±15%, and (3) correlation coefficient of 0.87 between variables X and Y.'
    }
  ];

  const constraintOptions = [
    {
      id: 'citations',
      name: 'Source Citations Required',
      description: 'Always include proper citations and references for external information',
      category: 'accuracy',
      impact: 'Enhances credibility and allows fact-checking'
    },
    {
      id: 'json',
      name: 'Structured JSON Output',
      description: 'Format responses as valid JSON when requested for API integration',
      category: 'format',
      impact: 'Enables seamless API integration and parsing'
    },
    {
      id: 'token',
      name: 'Response Length Optimization',
      description: 'Keep responses under 500 tokens for cost and latency optimization',
      category: 'performance',
      impact: 'Reduces API costs and improves response times'
    },
    {
      id: 'persona',
      name: 'Consistent Persona',
      description: 'Maintain character and voice throughout multi-turn conversations',
      category: 'consistency',
      impact: 'Provides coherent user experience across sessions'
    },
    {
      id: 'safety',
      name: 'Content Safety Filtering',
      description: 'Apply comprehensive filters to prevent harmful or inappropriate content',
      category: 'safety',
      impact: 'Ensures brand safety and regulatory compliance'
    },
    {
      id: 'branding',
      name: 'Brand Guidelines Compliance',
      description: 'Follow organizational brand voice and messaging standards',
      category: 'branding',
      impact: 'Maintains consistent brand experience'
    },
    {
      id: 'compliance',
      name: 'Regulatory Compliance',
      description: 'Ensure responses meet industry-specific regulatory requirements',
      category: 'compliance',
      impact: 'Reduces legal risk and ensures standards adherence'
    },
    {
      id: 'performance',
      name: 'Performance Monitoring',
      description: 'Track response metrics for continuous improvement',
      category: 'monitoring',
      impact: 'Enables data-driven optimization and quality control'
    },
    // Design-specific constraints
    {
      id: 'design-system',
      name: 'Design System Compliance',
      description: 'Ensure all design recommendations follow established design system guidelines',
      category: 'design',
      impact: 'Maintains design consistency and component reuse'
    },
    {
      id: 'accessibility',
      name: 'Accessibility Standards (WCAG)',
      description: 'Apply WCAG 2.1 AA accessibility guidelines to all design decisions',
      category: 'design',
      impact: 'Ensures inclusive design and regulatory compliance'
    },
    {
      id: 'responsive-design',
      name: 'Responsive Design Requirements',
      description: 'Consider mobile-first design principles and responsive breakpoints',
      category: 'design',
      impact: 'Ensures optimal experience across all device sizes'
    },
    {
      id: 'brand-consistency',
      name: 'Visual Brand Consistency',
      description: 'Adhere to brand colors, typography, and visual identity guidelines',
      category: 'design',
      impact: 'Maintains cohesive brand experience across touchpoints'
    },
    {
      id: 'figma-integration',
      name: 'Figma File Structure',
      description: 'Follow Figma naming conventions and file organization standards',
      category: 'design',
      impact: 'Improves design team collaboration and file management'
    },
    {
      id: 'design-tokens',
      name: 'Design Tokens Usage',
      description: 'Use design tokens for colors, spacing, and typography decisions',
      category: 'design',
      impact: 'Ensures scalable and maintainable design decisions'
    }
  ];

  const lengthLabels = {
    1: { label: 'Very Concise', description: 'Under 100 words', useCase: 'Quick answers, summaries' },
    2: { label: 'Concise', description: '100-200 words', useCase: 'Brief explanations, overviews' },
    3: { label: 'Balanced', description: '200-400 words', useCase: 'Standard responses, tutorials' },
    4: { label: 'Detailed', description: '400-600 words', useCase: 'In-depth analysis, guides' },
    5: { label: 'Comprehensive', description: '600+ words', useCase: 'Complete documentation, reports' }
  };

  const categoryColors = {
    accuracy: 'bg-blue-500/10 text-blue-400 border-blue-500/30',
    format: 'bg-green-500/10 text-green-400 border-green-500/30',
    performance: 'bg-purple-500/10 text-purple-400 border-purple-500/30',
    consistency: 'bg-orange-500/10 text-orange-400 border-orange-500/30',
    safety: 'bg-red-500/10 text-red-400 border-red-500/30',
    branding: 'bg-pink-500/10 text-pink-400 border-pink-500/30',
    compliance: 'bg-yellow-500/10 text-yellow-400 border-yellow-500/30',
    monitoring: 'bg-cyan-500/10 text-cyan-400 border-cyan-500/30',
    design: 'bg-indigo-500/10 text-indigo-400 border-indigo-500/30'
  };

  const updateBehaviorConfig = (field: string, value: any) => {
    const updated = { ...behaviorConfig, [field]: value };
    setBehaviorConfig(updated);
    onUpdate(updated);
  };

  const selectTone = (toneId: string) => {
    updateBehaviorConfig('tone', toneId);
  };

  const toggleConstraint = (constraintId: string) => {
    const constraints = behaviorConfig.constraints || [];
    const newConstraints = constraints.includes(constraintId)
      ? constraints.filter((c: string) => c !== constraintId)
      : [...constraints, constraintId];
    
    // If removing constraint, also remove its documentation
    const newConstraintDocs = { ...behaviorConfig.constraintDocs };
    if (!newConstraints.includes(constraintId)) {
      delete newConstraintDocs[constraintId];
    }
    
    // Update both fields at once
    const updated = { 
      ...behaviorConfig, 
      constraints: newConstraints,
      constraintDocs: newConstraintDocs 
    };
    setBehaviorConfig(updated);
    onUpdate(updated);
  };

  const updateConstraintDoc = (constraintId: string, documentation: string) => {
    const newConstraintDocs = {
      ...behaviorConfig.constraintDocs,
      [constraintId]: documentation
    };
    const updated = { 
      ...behaviorConfig, 
      constraintDocs: newConstraintDocs 
    };
    setBehaviorConfig(updated);
    onUpdate(updated);
  };

  const toggleConstraintExpanded = (constraintId: string) => {
    setExpandedConstraints(prev => ({
      ...prev,
      [constraintId]: !prev[constraintId]
    }));
  };

  // Check if user has design-related extensions
  const hasDesignExtensions = data.extensions?.some((ext: any) => 
    ext.enabled && ['figma-mcp', 'storybook-api', 'design-tokens', 'sketch-api', 'zeplin-api'].includes(ext.id)
  );

  return (
    <div className="space-y-8 animate-fadeIn">
      <div className="text-center space-y-4">
        <h1 className="bg-gradient-to-r from-primary to-purple-400 bg-clip-text text-transparent">
          Behavior & Communication Style
        </h1>
        <p className="text-muted-foreground max-w-2xl mx-auto">
          Configure how your AI agent communicates with users. Define the tone, response length,
          and operational constraints to match your specific requirements and brand guidelines.
        </p>
      </div>

      {/* Communication Tone */}
      <Card className="selection-card">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <MessageSquare className="w-5 h-5 text-primary" />
            Communication Tone & Style *
          </CardTitle>
          <CardDescription>
            Select the communication style that best matches your use case and audience
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {toneOptions.map((tone) => {
              const Icon = tone.icon;
              const isSelected = behaviorConfig.tone === tone.id;
              
              return (
                <div
                  key={tone.id}
                  className={`p-6 rounded-xl border cursor-pointer transition-all duration-300 hover:border-primary/50 hover:-translate-y-1 ${
                    isSelected
                      ? 'border-primary bg-gradient-to-br from-primary/10 to-transparent shadow-lg'
                      : 'border-border hover:shadow-md'
                  }`}
                  onClick={() => selectTone(tone.id)}
                >
                  <div className="space-y-4">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        <Icon className={`w-6 h-6 ${isSelected ? 'text-primary' : 'text-muted-foreground'}`} />
                        <h3 className="font-semibold">{tone.name}</h3>
                      </div>
                      {isSelected && <CheckCircle className="w-5 h-5 text-primary" />}
                    </div>
                    
                    <p className="text-sm text-muted-foreground leading-relaxed">
                      {tone.description}
                    </p>

                    <div className="flex flex-wrap gap-1">
                      {tone.characteristics.map((char) => (
                        <Badge key={char} variant="outline" className="chip-hug text-xs">
                          {char}
                        </Badge>
                      ))}
                    </div>

                    <div className="p-3 bg-muted/30 rounded-lg border-l-4 border-primary/30">
                      <p className="text-sm font-medium text-muted-foreground mb-1">Example:</p>
                      <p className="text-sm italic">"{tone.example}"</p>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </CardContent>
      </Card>

      {/* Response Length Configuration */}
      <Card className="selection-card">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <FileText className="w-5 h-5 text-primary" />
            Response Length Preference
          </CardTitle>
          <CardDescription>
            Configure the default length and detail level for agent responses
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <span className="font-medium">Response Length</span>
              <Badge variant="secondary" className="chip-hug">
                {lengthLabels[behaviorConfig.responseLength as keyof typeof lengthLabels].label}
              </Badge>
            </div>
            
            <Slider
              value={[behaviorConfig.responseLength]}
              onValueChange={(value) => updateBehaviorConfig('responseLength', value[0])}
              min={1}
              max={5}
              step={1}
              className="w-full"
            />
            
            <div className="flex justify-between text-xs text-muted-foreground">
              <span>Very Concise</span>
              <span>Balanced</span>
              <span>Comprehensive</span>
            </div>
          </div>

          <div className="p-4 bg-muted/30 rounded-lg">
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <span className="font-medium">
                  {lengthLabels[behaviorConfig.responseLength as keyof typeof lengthLabels].label}
                </span>
                <span className="text-sm text-muted-foreground">
                  {lengthLabels[behaviorConfig.responseLength as keyof typeof lengthLabels].description}
                </span>
              </div>
              <p className="text-sm text-muted-foreground">
                <span className="font-medium">Best for:</span> {lengthLabels[behaviorConfig.responseLength as keyof typeof lengthLabels].useCase}
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Design-Specific Requirements (shown if design extensions are enabled) */}
      {hasDesignExtensions && (
        <Card className="selection-card border-indigo-500/30 bg-gradient-to-br from-indigo-500/5 to-transparent">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Figma className="w-5 h-5 text-indigo-400" />
              Design Agent Requirements
              <Badge className="bg-indigo-500/20 text-indigo-400 border-indigo-500/30">
                Design Extensions Detected
              </Badge>
            </CardTitle>
            <CardDescription>
              Additional requirements for design-focused agents working with Figma, Storybook, and design systems
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {[
                {
                  icon: Component,
                  title: 'Component Library',
                  description: 'Reference and maintain design system components',
                  requirement: 'Always check existing components before creating new ones'
                },
                {
                  icon: Paintbrush,
                  title: 'Brand Guidelines',
                  description: 'Follow brand colors, typography, and visual identity',
                  requirement: 'Use approved brand assets and style guidelines'
                },
                {
                  icon: Ruler,
                  title: 'Design Standards',
                  description: 'Apply consistent spacing, sizing, and layout principles',
                  requirement: 'Follow 8px grid system and responsive breakpoints'
                },
                {
                  icon: Layers,
                  title: 'File Organization',
                  description: 'Maintain clean Figma file structure and naming',
                  requirement: 'Use consistent naming conventions and layer organization'
                },
                {
                  icon: BookOpen,
                  title: 'Documentation',
                  description: 'Create and update component and pattern documentation',
                  requirement: 'Document design decisions and usage guidelines'
                }
              ].map((item, index) => {
                const Icon = item.icon;
                return (
                  <div key={index} className="p-4 rounded-lg border border-indigo-500/20 bg-indigo-500/5">
                    <div className="space-y-2">
                      <div className="flex items-center gap-2">
                        <Icon className="w-5 h-5 text-indigo-400" />
                        <h4 className="font-medium">{item.title}</h4>
                      </div>
                      <p className="text-sm text-muted-foreground">{item.description}</p>
                      <p className="text-xs text-indigo-300 font-medium">{item.requirement}</p>
                    </div>
                  </div>
                );
              })}
            </div>

            <div className="p-4 bg-indigo-500/10 rounded-lg border border-indigo-500/20">
              <h4 className="font-medium text-indigo-300 mb-2">Design System Integration</h4>
              <p className="text-sm text-muted-foreground mb-3">
                Your agent will have access to design tools and should follow these additional guidelines:
              </p>
              <ul className="text-sm text-muted-foreground space-y-1">
                <li>• Sync with Figma design tokens and component libraries</li>
                <li>• Generate Storybook-compatible component documentation</li>
                <li>• Ensure accessibility compliance (WCAG 2.1 AA)</li>
                <li>• Maintain design system consistency across platforms</li>
                <li>• Provide design feedback and improvement suggestions</li>
              </ul>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Operational Constraints */}
      <Card className="selection-card">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Zap className="w-5 h-5 text-primary" />
            Operational Constraints & Requirements *
          </CardTitle>
          <CardDescription>
            Select at least one constraint or requirement for your agent's operation
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            {constraintOptions.map((constraint) => {
              const isSelected = behaviorConfig.constraints?.includes(constraint.id);
              
              return (
                <div
                  key={constraint.id}
                  className={`p-4 rounded-lg border cursor-pointer transition-all duration-200 hover:border-primary/50 ${
                    isSelected 
                      ? 'border-primary bg-primary/5' 
                      : 'border-border'
                  }`}
                  onClick={() => toggleConstraint(constraint.id)}
                >
                  <div className="space-y-3">
                    <div className="flex items-start justify-between">
                      <div className="space-y-1">
                        <div className="flex items-center gap-2">
                          <h4 className="font-medium">{constraint.name}</h4>
                          <Badge 
                            variant="outline" 
                            className={`chip-hug text-xs ${categoryColors[constraint.category as keyof typeof categoryColors]}`}
                          >
                            {constraint.category}
                          </Badge>
                        </div>
                        <p className="text-sm text-muted-foreground">{constraint.description}</p>
                      </div>
                      {isSelected && <CheckCircle className="w-5 h-5 text-primary" />}
                    </div>
                    
                    <div className="text-xs text-muted-foreground">
                      <span className="font-medium">Impact:</span> {constraint.impact}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>

          {behaviorConfig.constraints?.length > 0 ? (
            <div className="mt-6 space-y-4">
              <div className="p-4 bg-primary/5 rounded-lg border border-primary/30">
                <h4 className="font-medium mb-2">Selected Constraints Summary</h4>
                <div className="flex flex-wrap gap-2">
                  {behaviorConfig.constraints.map((constraintId: string) => {
                    const constraint = constraintOptions.find(c => c.id === constraintId);
                    return constraint ? (
                      <Badge key={constraintId} className="chip-hug bg-primary/20 text-primary">
                        {constraint.name}
                      </Badge>
                    ) : null;
                  })}
                </div>
                <p className="text-sm text-muted-foreground mt-2">
                  These constraints will be enforced during agent operation and included in the system prompt.
                </p>
              </div>

              {/* Constraint Documentation */}
              <Card className="border-primary/20">
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <FileEdit className="w-5 h-5 text-primary" />
                    Constraint Documentation & Instructions
                  </CardTitle>
                  <CardDescription>
                    Add specific documentation, policies, or instructions for each selected constraint
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  {behaviorConfig.constraints.map((constraintId: string) => {
                    const constraint = constraintOptions.find(c => c.id === constraintId);
                    const isExpanded = expandedConstraints[constraintId];
                    
                    if (!constraint) return null;
                    
                    return (
                      <div key={constraintId} className="border border-border rounded-lg">
                        <Collapsible
                          open={isExpanded}
                          onOpenChange={() => toggleConstraintExpanded(constraintId)}
                        >
                          <CollapsibleTrigger asChild>
                            <Button
                              variant="ghost"
                              className="w-full p-4 justify-between text-left hover:bg-muted/50"
                            >
                              <div className="flex items-center gap-3">
                                <Badge 
                                  variant="outline" 
                                  className={`chip-hug text-xs ${categoryColors[constraint.category as keyof typeof categoryColors]}`}
                                >
                                  {constraint.category}
                                </Badge>
                                <span className="font-medium">{constraint.name}</span>
                                {behaviorConfig.constraintDocs[constraintId] && (
                                  <Badge variant="secondary" className="chip-hug text-xs">
                                    Documented
                                  </Badge>
                                )}
                              </div>
                              {isExpanded ? (
                                <ChevronDown className="h-4 w-4" />
                              ) : (
                                <ChevronRight className="h-4 w-4" />
                              )}
                            </Button>
                          </CollapsibleTrigger>
                          <CollapsibleContent className="px-4 pb-4">
                            <div className="space-y-3">
                              <div className="text-sm text-muted-foreground">
                                <p><span className="font-medium">Description:</span> {constraint.description}</p>
                                <p><span className="font-medium">Impact:</span> {constraint.impact}</p>
                              </div>
                              
                              <div className="space-y-2">
                                <Label htmlFor={`constraint-doc-${constraintId}`}>
                                  Custom Documentation & Instructions
                                </Label>
                                <Textarea
                                  id={`constraint-doc-${constraintId}`}
                                  placeholder={`Add specific policies, guidelines, or instructions for "${constraint.name}"...

Example:
• Specific regulatory requirements
• Custom implementation details
• Company-specific policies
• Technical specifications${constraint.category === 'design' ? '\n• Design system guidelines\n• Component usage rules\n• Brand compliance requirements' : ''}`}
                                  value={behaviorConfig.constraintDocs[constraintId] || ''}
                                  onChange={(e) => updateConstraintDoc(constraintId, e.target.value)}
                                  className="bg-input-background min-h-[120px] resize-none"
                                />
                                <p className="text-xs text-muted-foreground">
                                  This documentation will be included in your agent's system prompt and deployment configuration.
                                </p>
                              </div>
                            </div>
                          </CollapsibleContent>
                        </Collapsible>
                      </div>
                    );
                  })}
                  
                  {behaviorConfig.constraints.length > 0 && (
                    <div className="p-3 bg-muted/30 rounded-lg">
                      <p className="text-sm text-muted-foreground">
                        <span className="font-medium">💡 Tip:</span> Detailed documentation helps ensure your AI agent follows 
                        specific organizational policies and regulatory requirements for each operational constraint.
                      </p>
                    </div>
                  )}
                </CardContent>
              </Card>
            </div>
          ) : (
            <div className="mt-6 p-4 bg-destructive/5 rounded-lg border border-destructive/30">
              <h4 className="font-medium mb-2 text-destructive">Selection Required</h4>
              <p className="text-sm text-muted-foreground">
                Please select at least one operational constraint to continue to the next step.
              </p>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Navigation */}
      <div className="flex justify-between pt-6">
        <Button variant="outline" onClick={onPrev} className="px-8">
          <ArrowLeft className="w-4 h-4 mr-2" />
          Back
        </Button>
        <Button 
          onClick={onNext}
          className="px-8 py-2 bg-primary hover:bg-primary/90 text-primary-foreground"
        >
          Test & Validate
          <ArrowRight className="w-4 h-4 ml-2" />
        </Button>
      </div>
    </div>
  );
}