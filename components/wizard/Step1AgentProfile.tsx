import React, { useState } from 'react';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Textarea } from '../ui/textarea';
import { Label } from '../ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Bot, Settings, Target, Zap, ArrowRight, User, Briefcase, CheckCircle, HelpCircle, MessageSquare, PenTool, BarChart3, Code, Package, Cloud, Globe, AlertCircle, Palette, Search } from 'lucide-react';
import { SavedTemplatesWidget } from '../templates/SavedTemplatesWidget';
import { AgentTemplate } from '../../types/templates';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '../ui/dialog';

interface Step1AgentProfileProps {
  data: any;
  onUpdate: (updates: any) => void;
  onNext: () => void;
  onUseTemplate?: (template: AgentTemplate) => void;
  onViewAllTemplates?: () => void;
}

interface DeploymentRecommendation {
  platform: string;
  confidence: number;
  reasons: string[];
  concerns?: string[];
}

interface QuestionnaireAnswers {
  technicalLevel: 'beginner' | 'intermediate' | 'advanced';
  expectedUsers: 'personal' | 'team' | 'company' | 'public';
  budget: 'free' | 'low' | 'medium' | 'enterprise';
  performance: 'basic' | 'standard' | 'high' | 'critical';
  availability: 'development' | 'business' | 'mission_critical';
  regions: 'single' | 'multi' | 'global';
  security: 'basic' | 'standard' | 'enterprise' | 'government';
  maintenance: 'none' | 'minimal' | 'managed' | 'full_support';
}

const useCases = [
  {
    id: 'chatbot',
    title: 'Conversational AI',
    description: 'Interactive chatbots and virtual assistants',
    icon: <MessageSquare className="w-5 h-5" />,
    features: ['Multi-turn conversations', 'Context awareness', 'Natural responses'],
    gradient: 'from-blue-500/10 to-cyan-500/10'
  },
  {
    id: 'content',
    title: 'Content Generator',
    description: 'Create articles, emails, and marketing copy',
    icon: <PenTool className="w-5 h-5" />,
    features: ['SEO optimization', 'Brand voice', 'Multiple formats'],
    gradient: 'from-purple-500/10 to-pink-500/10'
  },
  {
    id: 'analyzer',
    title: 'Data Analyzer',
    description: 'Extract insights and analyze information',
    icon: <BarChart3 className="w-5 h-5" />,
    features: ['Pattern detection', 'Trend analysis', 'Report generation'],
    gradient: 'from-green-500/10 to-emerald-500/10'
  },
  {
    id: 'coder',
    title: 'Code Assistant',
    description: 'Programming help and code generation',
    icon: <Code className="w-5 h-5" />,
    features: ['Code review', 'Bug fixing', 'Documentation'],
    gradient: 'from-orange-500/10 to-red-500/10'
  },
  {
    id: 'designer',
    title: 'Design Prototyper',
    description: 'AI-powered design assistance and rapid prototyping',
    icon: <Palette className="w-5 h-5" />,
    features: ['UI/UX design', 'Design systems', 'Rapid prototyping'],
    gradient: 'from-pink-500/10 to-rose-500/10'
  },
  {
    id: 'researcher',
    title: 'Research Assistant',
    description: 'Research, summarize, and synthesize information from multiple sources',
    icon: <Search className="w-5 h-5" />,
    features: ['Document analysis', 'Citation management', 'Knowledge synthesis'],
    gradient: 'from-indigo-500/10 to-purple-500/10'
  }
];

// Deployment recommendation algorithm
function generateDeploymentRecommendations(answers: QuestionnaireAnswers): DeploymentRecommendation[] {
  const recommendations: DeploymentRecommendation[] = [];
  
  // Desktop Extension (.dxt) - Always a top choice for Claude integration
  if (answers.technicalLevel === 'beginner' || answers.expectedUsers === 'personal') {
    recommendations.push({
      platform: 'desktop',
      confidence: 95,
      reasons: [
        'One-click installation with no configuration',
        'Perfect for Claude Desktop integration',
        'No infrastructure management required'
      ]
    });
  }

  // Railway - Great for modern developers
  if (answers.technicalLevel === 'intermediate' && ['team', 'company'].includes(answers.expectedUsers)) {
    recommendations.push({
      platform: 'railway',
      confidence: 90,
      reasons: [
        'Zero-config deployment with automatic CI/CD',
        'Usage-based pricing perfect for growing teams',
        'Real-time monitoring and scaling'
      ]
    });
  }

  // Render - Free tier and simplicity
  if (answers.budget === 'free' || (answers.technicalLevel === 'beginner' && answers.expectedUsers !== 'personal')) {
    recommendations.push({
      platform: 'render',
      confidence: 85,
      reasons: [
        'Free tier available for small projects',
        'Simple Blueprint YAML configuration',
        'Automatic SSL and DDoS protection'
      ]
    });
  }

  // Fly.io - Global edge deployment
  if (answers.regions === 'global' || answers.performance === 'critical') {
    recommendations.push({
      platform: 'fly',
      confidence: 88,
      reasons: [
        'Global edge deployment in 30+ regions',
        'Sub-250ms boot times worldwide',
        'Auto-sleep for cost optimization'
      ],
      concerns: answers.technicalLevel === 'beginner' ? ['Requires some command-line experience'] : undefined
    });
  }

  // Kubernetes - Full control for advanced users
  if (answers.technicalLevel === 'advanced' && answers.availability === 'mission_critical') {
    recommendations.push({
      platform: 'kubernetes',
      confidence: 92,
      reasons: [
        'Complete control over infrastructure',
        'High availability and auto-scaling',
        'Enterprise-grade observability'
      ],
      concerns: ['Requires significant DevOps expertise', 'Complex setup and maintenance']
    });
  }

  // Sort by confidence and return top 3
  return recommendations
    .sort((a, b) => b.confidence - a.confidence)
    .slice(0, 3);
}

const deploymentIcons = {
  desktop: Zap,
  railway: Zap,
  render: Globe,
  fly: Globe,
  vercel: Zap,
  cloudrun: Cloud,
  kubernetes: Cloud,
  docker: Package,
  json: Settings
};

const deploymentNames = {
  desktop: 'Desktop Extension (.dxt)',
  railway: 'Railway',
  render: 'Render',
  fly: 'Fly.io',
  vercel: 'Vercel',
  cloudrun: 'Google Cloud Run',
  kubernetes: 'Kubernetes',
  docker: 'Docker Compose',
  json: 'Raw JSON'
};

export function Step1AgentProfile({ data, onUpdate, onNext, onUseTemplate, onViewAllTemplates }: Step1AgentProfileProps) {
  const [formData, setFormData] = useState({
    agentName: data.agentName || '',
    agentDescription: data.agentDescription || '',
    agentCompany: data.agentCompany || '',
    primaryPurpose: data.primaryPurpose || '',
    targetEnvironment: data.targetEnvironment || 'development'
  });

  const [buildType, setBuildType] = useState<'guided' | 'custom' | null>(data?.buildType || null);
  const [showBuildTypeModal, setShowBuildTypeModal] = useState(false);
  const [showRecommendationWizard, setShowRecommendationWizard] = useState(false);
  const [currentQuestion, setCurrentQuestion] = useState(0);
  const [answers, setAnswers] = useState<Partial<QuestionnaireAnswers>>({});
  const [recommendations, setRecommendations] = useState<DeploymentRecommendation[]>([]);
  const [showResults, setShowResults] = useState(false);

  const questions = [
    {
      id: 'technicalLevel',
      title: 'What\'s your technical expertise level?',
      description: 'This helps us recommend the right complexity level for your deployment.',
      options: [
        { value: 'beginner', label: 'Beginner', description: 'I prefer simple, one-click solutions' },
        { value: 'intermediate', label: 'Intermediate', description: 'I can handle some configuration and CLI tools' },
        { value: 'advanced', label: 'Advanced', description: 'I\'m comfortable with complex infrastructure and DevOps' }
      ]
    },
    {
      id: 'expectedUsers',
      title: 'Who will be using your AI agent?',
      description: 'Different scales require different deployment approaches.',
      options: [
        { value: 'personal', label: 'Just Me', description: 'Personal use or small experiments' },
        { value: 'team', label: 'Small Team', description: '5-50 people in my organization' },
        { value: 'company', label: 'Company', description: '50-1000 employees' },
        { value: 'public', label: 'Public Users', description: 'Thousands of external users' }
      ]
    },
    {
      id: 'budget',
      title: 'What\'s your budget preference?',
      description: 'We\'ll recommend options that fit your budget constraints.',
      options: [
        { value: 'free', label: 'Free Tier', description: 'I want to start with free options' },
        { value: 'low', label: 'Low Cost', description: '$5-50/month for basic usage' },
        { value: 'medium', label: 'Medium Budget', description: '$50-500/month for growing needs' },
        { value: 'enterprise', label: 'Enterprise', description: '$500+/month with full features' }
      ]
    },
    {
      id: 'performance',
      title: 'What performance level do you need?',
      description: 'Higher performance requirements may need more robust solutions.',
      options: [
        { value: 'basic', label: 'Basic', description: 'Response times under 5 seconds are fine' },
        { value: 'standard', label: 'Standard', description: 'Response times under 2 seconds' },
        { value: 'high', label: 'High Performance', description: 'Sub-second response times' },
        { value: 'critical', label: 'Mission Critical', description: 'Ultra-low latency required' }
      ]
    },
    {
      id: 'availability',
      title: 'How critical is uptime?',
      description: 'Different availability needs require different deployment strategies.',
      options: [
        { value: 'development', label: 'Development', description: 'Occasional downtime is acceptable' },
        { value: 'business', label: 'Business Hours', description: '99.5% uptime during business hours' },
        { value: 'mission_critical', label: 'Mission Critical', description: '99.9%+ uptime required 24/7' }
      ]
    },
    {
      id: 'regions',
      title: 'Where are your users located?',
      description: 'Geographic distribution affects deployment strategy.',
      options: [
        { value: 'single', label: 'Single Region', description: 'Users are primarily in one geographic area' },
        { value: 'multi', label: 'Multiple Regions', description: 'Users across 2-3 major regions' },
        { value: 'global', label: 'Global', description: 'Users worldwide need low latency' }
      ]
    },
    {
      id: 'security',
      title: 'What are your security requirements?',
      description: 'Security needs vary by industry and use case.',
      options: [
        { value: 'basic', label: 'Basic', description: 'Standard HTTPS and basic auth' },
        { value: 'standard', label: 'Standard', description: 'Role-based access and audit logs' },
        { value: 'enterprise', label: 'Enterprise', description: 'Advanced security, compliance, SOC 2' },
        { value: 'government', label: 'Government', description: 'FISMA, FedRAMP compliance required' }
      ]
    },
    {
      id: 'maintenance',
      title: 'How much maintenance do you want to handle?',
      description: 'Some solutions require more hands-on management than others.',
      options: [
        { value: 'none', label: 'Zero Maintenance', description: 'I want a completely managed solution' },
        { value: 'minimal', label: 'Minimal', description: 'Occasional updates and monitoring' },
        { value: 'managed', label: 'Some Management', description: 'I can handle basic DevOps tasks' },
        { value: 'full_support', label: 'Full Control', description: 'I want complete control over infrastructure' }
      ]
    }
  ];

  const handleInputChange = (field: string, value: string) => {
    const updatedData = { ...formData, [field]: value };
    setFormData(updatedData);
    onUpdate(updatedData);
  };

  const handleAnswerSelect = (questionId: string, value: string) => {
    const newAnswers = { ...answers, [questionId]: value };
    setAnswers(newAnswers);
  };

  const handleNextQuestion = () => {
    if (currentQuestion < questions.length - 1) {
      setCurrentQuestion(currentQuestion + 1);
    } else {
      // Generate recommendations
      const recs = generateDeploymentRecommendations(answers as QuestionnaireAnswers);
      setRecommendations(recs);
      setShowResults(true);
    }
  };

  const handlePreviousQuestion = () => {
    if (currentQuestion > 0) {
      setCurrentQuestion(currentQuestion - 1);
    }
  };

  const handleAcceptRecommendations = () => {
    if (recommendations.length > 0) {
      onUpdate({
        ...formData,
        buildType: 'guided',
        recommendedDeployment: recommendations[0].platform,
        deploymentRecommendations: recommendations
      });
    }
    setShowRecommendationWizard(false);
  };

  const handleBuildTypeSelect = (type: 'guided' | 'custom') => {
    setBuildType(type);
    onUpdate({ ...formData, buildType: type });
    
    if (type === 'guided') {
      setShowBuildTypeModal(false);
      setShowRecommendationWizard(true);
      setCurrentQuestion(0);
      setAnswers({});
      setRecommendations([]);
      setShowResults(false);
    } else {
      setShowBuildTypeModal(false);
    }
  };

  const currentQuestionData = questions[currentQuestion];
  const canProceed = currentQuestionData && answers[currentQuestionData.id as keyof QuestionnaireAnswers];
  const isProfileComplete = formData.agentName && formData.agentDescription && formData.primaryPurpose;

  return (
    <div className="p-8 animate-fadeIn">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="text-center mb-8">
          <h2 className="text-3xl font-bold text-foreground mb-4">
            Configure Your AI Agent
          </h2>
          <p className="text-lg text-muted-foreground max-w-3xl mx-auto">
            Set up your agent's profile and choose its primary purpose for optimized configuration.
          </p>
        </div>

        {/* Side by Side Layout: Agent Profile + Use Cases */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
          {/* Left Column: Agent Profile */}
          <div className="space-y-6">
            <Card className="border-border bg-gradient-to-br from-blue-500/5 to-purple-500/5">
              <CardHeader>
                <div className="flex items-center gap-2 mb-2">
                  <User className="w-5 h-5 text-primary" />
                  <CardTitle>Agent Profile</CardTitle>
                </div>
                <CardDescription>
                  Basic information about your AI agent
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="agent-name">
                    Agent Name <span className="text-red-500">*</span>
                  </Label>
                  <Input
                    id="agent-name"
                    placeholder="e.g., Customer Support Bot"
                    value={formData.agentName}
                    onChange={(e) => handleInputChange('agentName', e.target.value)}
                    className="bg-background"
                  />
                  <p className="text-xs text-muted-foreground">
                    A memorable name for your AI agent
                  </p>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="agent-description">
                    Description <span className="text-red-500">*</span>
                  </Label>
                  <Textarea
                    id="agent-description"
                    placeholder="e.g., An intelligent assistant that helps customers with product questions and technical support..."
                    value={formData.agentDescription}
                    onChange={(e) => handleInputChange('agentDescription', e.target.value)}
                    className="bg-background min-h-[100px] resize-none"
                  />
                  <p className="text-xs text-muted-foreground">
                    What will your agent do? (2-3 sentences)
                  </p>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="agent-company">
                    Company/Organization
                  </Label>
                  <Input
                    id="agent-company"
                    placeholder="e.g., Acme Corp (optional)"
                    value={formData.agentCompany}
                    onChange={(e) => handleInputChange('agentCompany', e.target.value)}
                    className="bg-background"
                  />
                  <p className="text-xs text-muted-foreground">
                    Your company or project name
                  </p>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="target-environment">
                    Target Environment <span className="text-red-500">*</span>
                  </Label>
                  <Select value={formData.targetEnvironment} onValueChange={(value) => handleInputChange('targetEnvironment', value)}>
                    <SelectTrigger id="target-environment" className="bg-background">
                      <SelectValue placeholder="Select environment" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="development">Development</SelectItem>
                      <SelectItem value="staging">Staging</SelectItem>
                      <SelectItem value="production">Production</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                {/* Profile completion indicator */}
                <div className="pt-4 border-t">
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted-foreground">Profile Completion</span>
                    <span className="font-medium">
                      {formData.agentName && formData.agentDescription ? '100%' : formData.agentName || formData.agentDescription ? '50%' : '0%'}
                    </span>
                  </div>
                  <div className="w-full bg-muted rounded-full h-2 mt-2">
                    <div 
                      className="bg-primary h-2 rounded-full transition-all duration-300"
                      style={{ 
                        width: formData.agentName && formData.agentDescription ? '100%' : formData.agentName || formData.agentDescription ? '50%' : '0%' 
                      }}
                    />
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Right Column: Use Cases */}
          <div className="space-y-6">
            <Card className="border-border">
              <CardHeader>
                <div className="flex items-center gap-2 mb-2">
                  <Briefcase className="w-5 h-5 text-primary" />
                  <CardTitle>Primary Use Case</CardTitle>
                </div>
                <CardDescription>
                  What will be your agent's main function?
                </CardDescription>
              </CardHeader>
              <CardContent className="p-0">
                <div className="grid grid-cols-1 gap-1">
                  {useCases.map((useCase, index) => (
                    <div
                      key={useCase.id}
                      className={`
                        cursor-pointer group relative overflow-hidden border-0 border-b border-border/30 last:border-b-0 p-5 transition-all duration-300 hover:bg-gradient-to-r hover:${useCase.gradient} hover:shadow-sm
                        ${formData.primaryPurpose === useCase.id 
                          ? `bg-gradient-to-r ${useCase.gradient} border-primary/20 shadow-sm` 
                          : 'hover:border-primary/20'}
                      `}
                      onClick={() => handleInputChange('primaryPurpose', useCase.id)}
                    >
                      {/* Background pattern overlay */}
                      <div className={`
                        absolute inset-0 opacity-0 group-hover:opacity-10 transition-opacity duration-300
                        ${formData.primaryPurpose === useCase.id ? 'opacity-20' : ''}
                      `} 
                      style={{
                        backgroundImage: 'radial-gradient(circle at 20% 50%, rgba(120, 119, 198, 0.3), transparent 50%), radial-gradient(circle at 80% 20%, rgba(255, 119, 198, 0.3), transparent 50%), radial-gradient(circle at 40% 80%, rgba(120, 200, 255, 0.3), transparent 50%)',
                      }} />
                      
                      {/* Selection indicator */}
                      {formData.primaryPurpose === useCase.id && (
                        <div className="absolute left-0 top-0 bottom-0 w-1 bg-primary rounded-r-full" />
                      )}
                      
                      <div className="flex items-start gap-4 relative z-10">
                        {/* Enhanced icon */}
                        <div className={`
                          relative p-3 rounded-2xl transition-all duration-300 group-hover:scale-110 group-hover:rotate-3
                          ${formData.primaryPurpose === useCase.id 
                            ? 'bg-primary text-primary-foreground shadow-lg scale-110' 
                            : 'bg-gradient-to-br from-background to-muted border border-border/50 text-muted-foreground group-hover:border-primary/30 group-hover:text-primary group-hover:shadow-md'}
                        `}>
                          {useCase.icon}
                          {/* Icon glow effect */}
                          <div className={`
                            absolute inset-0 rounded-2xl blur-md opacity-0 group-hover:opacity-30 transition-opacity duration-300
                            ${formData.primaryPurpose === useCase.id ? 'opacity-40' : ''}
                          `} 
                          style={{
                            background: formData.primaryPurpose === useCase.id 
                              ? 'linear-gradient(45deg, rgb(99, 102, 241), rgb(139, 92, 246))' 
                              : 'linear-gradient(45deg, rgba(99, 102, 241, 0.5), rgba(139, 92, 246, 0.5))'
                          }} />
                        </div>
                        
                        <div className="flex-1 min-w-0">
                          {/* Header with selection state */}
                          <div className="flex items-start justify-between mb-2">
                            <div>
                              <h4 className={`
                                font-bold text-base transition-colors duration-200 group-hover:text-primary
                                ${formData.primaryPurpose === useCase.id ? 'text-primary' : 'text-foreground'}
                              `}>
                                {useCase.title}
                              </h4>
                              <div className="flex items-center gap-2 mt-1">
                                <span className={`
                                  text-xs font-medium px-2 py-1 rounded-full transition-all duration-200
                                  ${formData.primaryPurpose === useCase.id 
                                    ? 'bg-primary/20 text-primary border border-primary/30' 
                                    : 'bg-muted text-muted-foreground group-hover:bg-primary/10 group-hover:text-primary'}
                                `}>
                                  #{index + 1}
                                </span>
                                {formData.primaryPurpose === useCase.id && (
                                  <div className="flex items-center gap-1 text-xs font-medium text-primary animate-fadeIn">
                                    <CheckCircle className="w-3 h-3" />
                                    Selected
                                  </div>
                                )}
                              </div>
                            </div>
                          </div>
                          
                          {/* Description */}
                          <p className={`
                            text-sm mb-3 transition-colors duration-200 leading-relaxed
                            ${formData.primaryPurpose === useCase.id 
                              ? 'text-foreground/90' 
                              : 'text-muted-foreground group-hover:text-foreground/80'}
                          `}>
                            {useCase.description}
                          </p>
                          
                          {/* Enhanced feature badges */}
                          <div className="flex flex-wrap gap-2">
                            {useCase.features.map((feature, featureIndex) => (
                              <div
                                key={featureIndex}
                                className={`
                                  inline-flex items-center gap-1 text-xs font-medium px-3 py-1.5 rounded-full transition-all duration-200 border
                                  ${formData.primaryPurpose === useCase.id 
                                    ? 'bg-primary/10 text-primary border-primary/20' 
                                    : 'bg-background/80 text-muted-foreground border-border/50 group-hover:bg-primary/5 group-hover:text-primary/80 group-hover:border-primary/20'}
                                `}
                              >
                                <div className={`
                                  w-1.5 h-1.5 rounded-full transition-colors duration-200
                                  ${formData.primaryPurpose === useCase.id 
                                    ? 'bg-primary' 
                                    : 'bg-muted-foreground group-hover:bg-primary/60'}
                                `} />
                                {feature}
                              </div>
                            ))}
                          </div>
                        </div>
                      </div>
                      
                      {/* Hover arrow indicator */}
                      <div className={`
                        absolute right-4 top-1/2 transform -translate-y-1/2 transition-all duration-300
                        ${formData.primaryPurpose === useCase.id 
                          ? 'opacity-100 translate-x-0' 
                          : 'opacity-0 translate-x-2 group-hover:opacity-60 group-hover:translate-x-0'}
                      `}>
                        <ArrowRight className="w-4 h-4 text-primary" />
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>

            {/* Templates Widget */}
            {onUseTemplate && onViewAllTemplates && (
              <SavedTemplatesWidget
                onUseTemplate={onUseTemplate}
                onViewAllTemplates={onViewAllTemplates}
                compact={true}
              />
            )}
          </div>
        </div>

        {/* Build Path Status - Show what was selected in Step 0 */}
        {data?.buildType && (
          <div className="backdrop-blur-xl p-4 rounded-xl mb-8 animate-fadeIn bg-primary/5 border border-primary/20">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 bg-primary/20 rounded-full flex items-center justify-center">
                {data.buildType === 'guided' ? (
                  <HelpCircle className="w-4 h-4 text-primary" />
                ) : (
                  <Settings className="w-4 h-4 text-primary" />
                )}
              </div>
              <div>
                <div className="font-medium text-foreground">
                  {data.buildType === 'guided' ? '🚀 Guided Build Path' : '⚙️ Custom Build Path'}
                </div>
                <div className="text-sm text-muted-foreground">
                  {data.buildType === 'guided' 
                    ? 'Using AI-powered recommendations from your questionnaire'
                    : 'Full control over configuration and deployment options'
                  }
                </div>
              </div>
              <CheckCircle className="w-4 h-4 text-primary ml-auto" />
            </div>
            
            {data.buildType === 'guided' && data?.recommendedDeployment && (
              <div className="mt-3 pt-3 border-t border-primary/20">
                <div className="flex items-center gap-2 text-sm">
                  <CheckCircle className="w-3 h-3 text-primary" />
                  <span className="text-foreground">
                    Recommended platform: <strong>{deploymentNames[data.recommendedDeployment as keyof typeof deploymentNames]}</strong>
                  </span>
                </div>
              </div>
            )}
          </div>
        )}

        {/* Build Type Selection Modal */}
        <Dialog open={showBuildTypeModal} onOpenChange={setShowBuildTypeModal}>
          <DialogContent className="max-w-3xl">
            <DialogHeader>
              <DialogTitle>Choose Your Build Experience</DialogTitle>
              <DialogDescription>
                Select the approach that best fits your experience level and preferences.
              </DialogDescription>
            </DialogHeader>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 py-6">
              {/* Guided Build Option */}
              <Card 
                className="cursor-pointer transition-all duration-200 hover:border-primary hover:shadow-lg group"
                onClick={() => handleBuildTypeSelect('guided')}
              >
                <CardHeader className="text-center pb-4">
                  <div className="w-16 h-16 bg-gradient-to-br from-blue-500/20 to-purple-500/20 rounded-full flex items-center justify-center mx-auto mb-4 group-hover:scale-110 transition-transform">
                    <HelpCircle className="w-8 h-8 text-blue-500" />
                  </div>
                  <CardTitle className="text-xl">Guided Build</CardTitle>
                  <CardDescription>Perfect for beginners and those who want recommendations</CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="space-y-3">
                    <div className="flex items-center gap-3">
                      <CheckCircle className="w-4 h-4 text-green-500 flex-shrink-0" />
                      <span className="text-sm">AI-powered deployment recommendations</span>
                    </div>
                    <div className="flex items-center gap-3">
                      <CheckCircle className="w-4 h-4 text-green-500 flex-shrink-0" />
                      <span className="text-sm">Personalized questionnaire (2-3 minutes)</span>
                    </div>
                    <div className="flex items-center gap-3">
                      <CheckCircle className="w-4 h-4 text-green-500 flex-shrink-0" />
                      <span className="text-sm">Pre-configured best practices</span>
                    </div>
                    <div className="flex items-center gap-3">
                      <CheckCircle className="w-4 h-4 text-green-500 flex-shrink-0" />
                      <span className="text-sm">Optimized for your use case</span>
                    </div>
                  </div>
                  <div className="pt-4">
                    <Badge className="bg-blue-500/20 text-blue-600 border-blue-500/30">
                      Recommended for most users
                    </Badge>
                  </div>
                </CardContent>
              </Card>

              {/* Custom Build Option */}
              <Card 
                className="cursor-pointer transition-all duration-200 hover:border-primary hover:shadow-lg group"
                onClick={() => handleBuildTypeSelect('custom')}
              >
                <CardHeader className="text-center pb-4">
                  <div className="w-16 h-16 bg-gradient-to-br from-orange-500/20 to-red-500/20 rounded-full flex items-center justify-center mx-auto mb-4 group-hover:scale-110 transition-transform">
                    <Settings className="w-8 h-8 text-orange-500" />
                  </div>
                  <CardTitle className="text-xl">Custom Build</CardTitle>
                  <CardDescription>Full control for experienced developers</CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="space-y-3">
                    <div className="flex items-center gap-3">
                      <CheckCircle className="w-4 h-4 text-green-500 flex-shrink-0" />
                      <span className="text-sm">Complete configuration control</span>
                    </div>
                    <div className="flex items-center gap-3">
                      <CheckCircle className="w-4 h-4 text-green-500 flex-shrink-0" />
                      <span className="text-sm">Access to all deployment options</span>
                    </div>
                    <div className="flex items-center gap-3">
                      <CheckCircle className="w-4 h-4 text-green-500 flex-shrink-0" />
                      <span className="text-sm">Advanced security settings</span>
                    </div>
                    <div className="flex items-center gap-3">
                      <CheckCircle className="w-4 h-4 text-green-500 flex-shrink-0" />
                      <span className="text-sm">Expert-level customization</span>
                    </div>
                  </div>
                  <div className="pt-4">
                    <Badge variant="outline" className="border-orange-500/30 text-orange-600">
                      For advanced users
                    </Badge>
                  </div>
                </CardContent>
              </Card>
            </div>
          </DialogContent>
        </Dialog>

        {/* Guided Build Recommendation Wizard */}
        <Dialog open={showRecommendationWizard} onOpenChange={setShowRecommendationWizard}>
          <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
            <DialogHeader>
              <DialogTitle>
                {showResults ? 'Your Deployment Recommendations' : `Deployment Wizard (${currentQuestion + 1}/${questions.length})`}
              </DialogTitle>
              <DialogDescription>
                {showResults 
                  ? 'Based on your answers, here are the best deployment options for you:'
                  : 'Answer these questions to get personalized deployment recommendations.'
                }
              </DialogDescription>
            </DialogHeader>

            {!showResults ? (
              <div className="space-y-6">
                {/* Progress bar */}
                <div className="w-full bg-muted rounded-full h-2">
                  <div 
                    className="bg-primary h-2 rounded-full transition-all duration-300"
                    style={{ width: `${((currentQuestion + 1) / questions.length) * 100}%` }}
                  />
                </div>

                {/* Question */}
                <div className="space-y-4">
                  <div>
                    <h3 className="text-lg font-semibold mb-2">
                      {currentQuestionData?.title}
                    </h3>
                    <p className="text-muted-foreground text-sm">
                      {currentQuestionData?.description}
                    </p>
                  </div>

                  {/* Options */}
                  <div className="space-y-3">
                    {currentQuestionData?.options.map((option) => (
                      <div
                        key={option.value}
                        className={`
                          p-4 rounded-lg border cursor-pointer transition-all duration-200
                          ${answers[currentQuestionData.id as keyof QuestionnaireAnswers] === option.value
                            ? 'border-primary bg-primary/10'
                            : 'border-border hover:border-primary/50 hover:bg-muted/50'
                          }
                        `}
                        onClick={() => handleAnswerSelect(currentQuestionData.id, option.value)}
                      >
                        <div className="flex items-start space-x-3">
                          <div className={`
                            w-4 h-4 rounded-full border-2 mt-0.5 transition-colors
                            ${answers[currentQuestionData.id as keyof QuestionnaireAnswers] === option.value
                              ? 'border-primary bg-primary'
                              : 'border-muted-foreground'
                            }
                          `}>
                            {answers[currentQuestionData.id as keyof QuestionnaireAnswers] === option.value && (
                              <div className="w-2 h-2 bg-white rounded-full mx-auto mt-0.5" />
                            )}
                          </div>
                          <div>
                            <div className="font-medium">{option.label}</div>
                            <div className="text-sm text-muted-foreground">{option.description}</div>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Navigation */}
                <div className="flex justify-between pt-4">
                  <Button
                    variant="outline"
                    onClick={handlePreviousQuestion}
                    disabled={currentQuestion === 0}
                  >
                    Previous
                  </Button>
                  <Button
                    onClick={handleNextQuestion}
                    disabled={!canProceed}
                  >
                    {currentQuestion === questions.length - 1 ? 'Get Recommendations' : 'Next'}
                  </Button>
                </div>
              </div>
            ) : (
              <div className="space-y-6">
                {/* Recommendations */}
                <div className="space-y-4">
                  {recommendations.map((rec, index) => {
                    const IconComponent = deploymentIcons[rec.platform as keyof typeof deploymentIcons];
                    return (
                      <Card key={rec.platform} className={`${index === 0 ? 'border-primary bg-primary/5' : ''}`}>
                        <CardHeader className="pb-3">
                          <div className="flex items-center justify-between">
                            <div className="flex items-center gap-3">
                              <IconComponent className="w-5 h-5" />
                              <CardTitle className="text-lg">
                                {deploymentNames[rec.platform as keyof typeof deploymentNames]}
                              </CardTitle>
                              {index === 0 && (
                                <Badge className="bg-primary/20 text-primary border-primary/30">
                                  Recommended
                                </Badge>
                              )}
                            </div>
                            <Badge variant="outline" className="font-mono">
                              {rec.confidence}% match
                            </Badge>
                          </div>
                        </CardHeader>
                        <CardContent className="pt-0">
                          <div className="space-y-3">
                            <div>
                              <h5 className="text-sm font-medium text-green-600 mb-1 flex items-center gap-1">
                                <CheckCircle className="w-3 h-3" />
                                Why this works for you:
                              </h5>
                              <ul className="text-sm text-muted-foreground space-y-1">
                                {rec.reasons.map((reason, i) => (
                                  <li key={i} className="flex items-start gap-2">
                                    <div className="w-1 h-1 bg-current rounded-full mt-2 flex-shrink-0" />
                                    {reason}
                                  </li>
                                ))}
                              </ul>
                            </div>
                            {rec.concerns && (
                              <div>
                                <h5 className="text-sm font-medium text-orange-600 mb-1 flex items-center gap-1">
                                  <AlertCircle className="w-3 h-3" />
                                  Consider:
                                </h5>
                                <ul className="text-sm text-muted-foreground space-y-1">
                                  {rec.concerns.map((concern, i) => (
                                    <li key={i} className="flex items-start gap-2">
                                      <div className="w-1 h-1 bg-current rounded-full mt-2 flex-shrink-0" />
                                      {concern}
                                    </li>
                                  ))}
                                </ul>
                              </div>
                            )}
                          </div>
                        </CardContent>
                      </Card>
                    );
                  })}
                </div>

                {/* Actions */}
                <div className="flex justify-between pt-4">
                  <Button
                    variant="outline"
                    onClick={() => setShowResults(false)}
                  >
                    Retake Quiz
                  </Button>
                  <Button onClick={handleAcceptRecommendations}>
                    Use Recommendations
                  </Button>
                </div>
              </div>
            )}
          </DialogContent>
        </Dialog>

        {/* Progress Summary */}
        <div className="mb-6">
          <div className="flex items-center justify-center gap-6 text-sm">
            <div className="flex items-center gap-2">
              {formData.agentName && formData.agentDescription ? (
                <CheckCircle className="w-4 h-4 text-green-500" />
              ) : (
                <div className="w-4 h-4 rounded-full border-2 border-muted-foreground" />
              )}
              <span className={formData.agentName && formData.agentDescription ? 'text-foreground' : 'text-muted-foreground'}>
                Agent Profile
              </span>
            </div>
            <div className="w-8 h-px bg-border" />
            <div className="flex items-center gap-2">
              {formData.primaryPurpose ? (
                <CheckCircle className="w-4 h-4 text-green-500" />
              ) : (
                <div className="w-4 h-4 rounded-full border-2 border-muted-foreground" />
              )}
              <span className={formData.primaryPurpose ? 'text-foreground' : 'text-muted-foreground'}>
                Use Case
              </span>
            </div>
            <div className="w-8 h-px bg-border" />
            <div className="flex items-center gap-2">
              {buildType ? (
                <CheckCircle className="w-4 h-4 text-green-500" />
              ) : (
                <div className="w-4 h-4 rounded-full border-2 border-muted-foreground" />
              )}
              <span className={buildType ? 'text-foreground' : 'text-muted-foreground'}>
                Build Path
              </span>
            </div>
          </div>
        </div>

        {/* Navigation */}
        <div className="flex items-center justify-between">
          <div className="text-sm text-muted-foreground">
            Step 2 of 7
          </div>
          
          <Button 
            onClick={onNext}
            disabled={!isProfileComplete}
            className="shadow-lg"
            style={{
              boxShadow: isProfileComplete ? '0 4px 12px rgba(99, 102, 241, 0.3)' : 'none'
            }}
          >
            {!formData.agentName || !formData.agentDescription 
              ? 'Complete agent profile to continue'
              : !formData.primaryPurpose 
                ? 'Select a use case to continue'
                : 'Continue to Extensions'
            }
            <ArrowRight className="w-4 h-4 ml-2" />
          </Button>
        </div>
      </div>
    </div>
  );
}