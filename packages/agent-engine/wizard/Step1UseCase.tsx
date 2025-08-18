import { useState } from 'react';
import { MessageSquare, PenTool, BarChart3, Code, ArrowRight, Zap, Globe, Package, Cloud, Settings, CheckCircle, AlertCircle, HelpCircle, User, Briefcase } from 'lucide-react';
import { Button } from '../ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '../ui/dialog';
import { Input } from '../ui/input';
import { Textarea } from '../ui/textarea';
import { Label } from '../ui/label';

interface Step1Props {
  selectedUseCase: string | null;
  onSelect: (value: string) => void;
  onNext: () => void;
  data?: any;
  onUpdate?: (updates: any) => void;
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
    icon: <MessageSquare className="w-8 h-8" />,
    features: ['Multi-turn conversations', 'Context awareness', 'Natural responses'],
    gradient: 'from-blue-500/10 to-cyan-500/10'
  },
  {
    id: 'content',
    title: 'Content Generator',
    description: 'Create articles, emails, and marketing copy',
    icon: <PenTool className="w-8 h-8" />,
    features: ['SEO optimization', 'Brand voice', 'Multiple formats'],
    gradient: 'from-purple-500/10 to-pink-500/10'
  },
  {
    id: 'analyzer',
    title: 'Data Analyzer',
    description: 'Extract insights and analyze information',
    icon: <BarChart3 className="w-8 h-8" />,
    features: ['Pattern detection', 'Trend analysis', 'Report generation'],
    gradient: 'from-green-500/10 to-emerald-500/10'
  },
  {
    id: 'coder',
    title: 'Code Assistant',
    description: 'Programming help and code generation',
    icon: <Code className="w-8 h-8" />,
    features: ['Code review', 'Bug fixing', 'Documentation'],
    gradient: 'from-orange-500/10 to-red-500/10'
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

  // Vercel - Great for frontend-heavy applications
  if (answers.expectedUsers === 'public' && answers.performance !== 'critical') {
    recommendations.push({
      platform: 'vercel',
      confidence: 82,
      reasons: [
        'Excellent for serverless functions',
        'Built-in analytics and monitoring',
        'Preview deployments for testing'
      ]
    });
  }

  // Google Cloud Run - Enterprise serverless
  if (answers.budget === 'enterprise' && answers.security === 'enterprise') {
    recommendations.push({
      platform: 'cloudrun',
      confidence: 87,
      reasons: [
        'Fully managed serverless containers',
        'Google Cloud integration',
        'Pay-per-request pricing'
      ]
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

  // Docker Compose - Development and staging
  if (answers.availability === 'development' || answers.technicalLevel === 'intermediate') {
    recommendations.push({
      platform: 'docker',
      confidence: 80,
      reasons: [
        'Great for development environments',
        'Consistent across team members',
        'Easy local testing'
      ]
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

export function Step1UseCase({ selectedUseCase, onSelect, onNext, data, onUpdate }: Step1Props) {
  const [showBuildTypeModal, setShowBuildTypeModal] = useState(false);
  const [buildType, setBuildType] = useState<'guided' | 'custom' | null>(data?.buildType || null);
  const [showRecommendationWizard, setShowRecommendationWizard] = useState(false);
  const [currentQuestion, setCurrentQuestion] = useState(0);
  const [answers, setAnswers] = useState<Partial<QuestionnaireAnswers>>({});
  const [recommendations, setRecommendations] = useState<DeploymentRecommendation[]>([]);
  const [showResults, setShowResults] = useState(false);
  
  // Agent profile state
  const [agentName, setAgentName] = useState(data?.agentName || '');
  const [agentDescription, setAgentDescription] = useState(data?.agentDescription || '');
  const [agentCompany, setAgentCompany] = useState(data?.agentCompany || '');

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
    if (onUpdate && recommendations.length > 0) {
      onUpdate({
        buildType: 'guided',
        recommendedDeployment: recommendations[0].platform,
        deploymentRecommendations: recommendations
      });
    }
    setShowRecommendationWizard(false);
  };

  const handleStartWizard = () => {
    setShowRecommendationWizard(true);
    setCurrentQuestion(0);
    setAnswers({});
    setRecommendations([]);
    setShowResults(false);
  };

  const handleBuildTypeSelect = (type: 'guided' | 'custom') => {
    setBuildType(type);
    if (onUpdate) {
      onUpdate({ buildType: type });
    }
    
    if (type === 'guided') {
      setShowBuildTypeModal(false);
      handleStartWizard();
    } else {
      setShowBuildTypeModal(false);
    }
  };

  const handleShowBuildOptions = () => {
    setShowBuildTypeModal(true);
  };

  const handleAgentProfileUpdate = (field: string, value: string) => {
    if (field === 'name') setAgentName(value);
    if (field === 'description') setAgentDescription(value);
    if (field === 'company') setAgentCompany(value);
    
    if (onUpdate) {
      onUpdate({
        agentName: field === 'name' ? value : agentName,
        agentDescription: field === 'description' ? value : agentDescription,
        agentCompany: field === 'company' ? value : agentCompany
      });
    }
  };

  const currentQuestionData = questions[currentQuestion];
  const canProceed = currentQuestionData && answers[currentQuestionData.id as keyof QuestionnaireAnswers];
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
                    value={agentName}
                    onChange={(e) => handleAgentProfileUpdate('name', e.target.value)}
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
                    value={agentDescription}
                    onChange={(e) => handleAgentProfileUpdate('description', e.target.value)}
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
                    value={agentCompany}
                    onChange={(e) => handleAgentProfileUpdate('company', e.target.value)}
                    className="bg-background"
                  />
                  <p className="text-xs text-muted-foreground">
                    Your company or project name
                  </p>
                </div>

                {/* Profile completion indicator */}
                <div className="pt-4 border-t">
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted-foreground">Profile Completion</span>
                    <span className="font-medium">
                      {agentName && agentDescription ? '100%' : agentName || agentDescription ? '50%' : '0%'}
                    </span>
                  </div>
                  <div className="w-full bg-muted rounded-full h-2 mt-2">
                    <div 
                      className="bg-primary h-2 rounded-full transition-all duration-300"
                      style={{ 
                        width: agentName && agentDescription ? '100%' : agentName || agentDescription ? '50%' : '0%' 
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
              <CardContent>
                <div className="grid grid-cols-1 gap-3">
                  {useCases.map((useCase) => (
                    <div
                      key={useCase.id}
                      className={`
                        cursor-pointer group relative overflow-hidden rounded-lg border p-4 transition-all duration-200
                        ${selectedUseCase === useCase.id 
                          ? 'border-primary bg-primary/5 shadow-md' 
                          : 'border-border hover:border-primary/50 hover:bg-muted/50'}
                      `}
                      onClick={() => onSelect(useCase.id)}
                    >
                      <div className="flex items-start gap-3">
                        <div className={`
                          p-2 rounded-lg transition-colors duration-200
                          ${selectedUseCase === useCase.id 
                            ? 'bg-primary text-primary-foreground' 
                            : 'bg-muted text-muted-foreground group-hover:bg-primary/20'}
                        `}>
                          {React.cloneElement(useCase.icon as React.ReactElement, { className: 'w-5 h-5' })}
                        </div>
                        
                        <div className="flex-1">
                          <div className="flex items-center justify-between">
                            <h4 className="font-semibold text-foreground">
                              {useCase.title}
                            </h4>
                            {selectedUseCase === useCase.id && (
                              <CheckCircle className="w-4 h-4 text-primary" />
                            )}
                          </div>
                          <p className="text-sm text-muted-foreground mt-1">
                            {useCase.description}
                          </p>
                          <div className="flex flex-wrap gap-1 mt-2">
                            {useCase.features.map((feature, index) => (
                              <Badge 
                                key={index} 
                                variant="outline" 
                                className="text-xs py-0 px-2"
                              >
                                {feature}
                              </Badge>
                            ))}
                          </div>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>
        </div>

        {/* Additional options */}
        <div className="backdrop-blur-xl p-6 rounded-xl mb-8" style={{
          background: 'rgba(24, 24, 27, 0.8)',
          border: '1px solid rgba(255, 255, 255, 0.1)',
          boxShadow: '0 0 0 1px rgba(255, 255, 255, 0.05)'
        }}>
          <h4 className="text-lg font-semibold text-foreground mb-4">
            Need something custom?
          </h4>
          <p className="text-muted-foreground mb-4">
            These templates provide optimized starting points, but you can customize everything in the following steps.
          </p>
          <div className="flex items-center space-x-4">
            <Button variant="outline" size="sm">
              Import Template
            </Button>
            <Button variant="ghost" size="sm">
              Start from Scratch
            </Button>
          </div>
        </div>

        {/* Build Type Selection - Only show after profile and use case are complete */}
        {selectedUseCase && agentName && agentDescription && (
          <div className="backdrop-blur-xl p-6 rounded-xl mb-8 animate-fadeIn" style={{
            background: 'rgba(24, 24, 27, 0.8)',
            border: '1px solid rgba(255, 255, 255, 0.1)',
            boxShadow: '0 0 0 1px rgba(255, 255, 255, 0.05)'
          }}>
            <div className="flex items-center justify-between mb-4">
              <div>
                <h4 className="text-lg font-semibold text-foreground mb-2">
                  🚀 Choose Your Build Experience
                </h4>
                <p className="text-muted-foreground">
                  {buildType 
                    ? buildType === 'guided' 
                      ? 'Great! We\'ll guide you with personalized deployment recommendations.'
                      : 'Perfect! You\'ll have full control over all configuration options.'
                    : 'How would you like to configure your AI agent?'
                  }
                </p>
              </div>
              {!buildType ? (
                <Button onClick={handleShowBuildOptions} className="flex items-center gap-2">
                  <HelpCircle className="w-4 h-4" />
                  Choose Path
                </Button>
              ) : (
                <Button 
                  variant="outline" 
                  onClick={() => setBuildType(null)} 
                  className="flex items-center gap-2"
                >
                  <Settings className="w-4 h-4" />
                  Change Path
                </Button>
              )}
            </div>
            
            {buildType && (
              <div className="mt-4 p-4 bg-primary/10 border border-primary/20 rounded-lg">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-primary/20 rounded-full flex items-center justify-center">
                    {buildType === 'guided' ? (
                      <HelpCircle className="w-5 h-5 text-primary" />
                    ) : (
                      <Settings className="w-5 h-5 text-primary" />
                    )}
                  </div>
                  <div>
                    <div className="font-medium text-foreground">
                      {buildType === 'guided' ? 'Guided Build' : 'Custom Build'}
                    </div>
                    <div className="text-sm text-muted-foreground">
                      {buildType === 'guided' 
                        ? 'AI-powered recommendations based on your specific requirements'
                        : 'Full control over every configuration and deployment option'
                      }
                    </div>
                  </div>
                  <CheckCircle className="w-5 h-5 text-primary ml-auto" />
                </div>
                
                {buildType === 'guided' && data?.recommendedDeployment && (
                  <div className="mt-3 pt-3 border-t border-primary/20">
                    <div className="flex items-center gap-2 text-sm">
                      <CheckCircle className="w-4 h-4 text-primary" />
                      <span className="text-foreground">
                        Recommended platform: <strong>{deploymentNames[data.recommendedDeployment as keyof typeof deploymentNames]}</strong>
                      </span>
                    </div>
                  </div>
                )}
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
              {agentName && agentDescription ? (
                <CheckCircle className="w-4 h-4 text-green-500" />
              ) : (
                <div className="w-4 h-4 rounded-full border-2 border-muted-foreground" />
              )}
              <span className={agentName && agentDescription ? 'text-foreground' : 'text-muted-foreground'}>
                Agent Profile
              </span>
            </div>
            <div className="w-8 h-px bg-border" />
            <div className="flex items-center gap-2">
              {selectedUseCase ? (
                <CheckCircle className="w-4 h-4 text-green-500" />
              ) : (
                <div className="w-4 h-4 rounded-full border-2 border-muted-foreground" />
              )}
              <span className={selectedUseCase ? 'text-foreground' : 'text-muted-foreground'}>
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
            Step 1 of 5
          </div>
          
          <Button 
            onClick={onNext}
            disabled={!agentName || !agentDescription || !selectedUseCase || !buildType}
            className="shadow-lg"
            style={{
              boxShadow: (agentName && agentDescription && selectedUseCase && buildType) ? '0 4px 12px rgba(99, 102, 241, 0.3)' : 'none'
            }}
          >
            {!agentName || !agentDescription 
              ? 'Complete agent profile to continue'
              : !selectedUseCase 
                ? 'Select a use case to continue'
                : !buildType 
                  ? 'Choose your build path to continue'
                  : 'Continue'
            }
            <ArrowRight className="w-4 h-4 ml-2" />
          </Button>
        </div>
      </div>
    </div>
  );
}