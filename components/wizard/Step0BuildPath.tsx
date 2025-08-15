import React, { useState } from 'react';
import { Button } from '../ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '../ui/dialog';
import { Input } from '../ui/input';
import { Textarea } from '../ui/textarea';
import { Label } from '../ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { ArrowRight, Settings, HelpCircle, CheckCircle, Zap, Globe, Package, Cloud, AlertCircle, MessageSquare, PenTool, BarChart3, Code, Palette, Search, Sparkles, User, Briefcase } from 'lucide-react';

interface Step0BuildPathProps {
  data: any;
  onUpdate: (updates: any) => void;
  onNext: () => void;
}

interface DeploymentRecommendation {
  platform: string;
  confidence: number;
  reasons: string[];
  concerns?: string[];
}

interface QuestionnaireAnswers {
  // Agent Profile
  agentName: string;
  agentDescription: string;
  agentCompany: string;
  primaryPurpose: string;
  targetEnvironment: string;
  
  // Deployment Questions
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
  },
  {
    id: 'content',
    title: 'Content Generator',
    description: 'Create articles, emails, and marketing copy',
    icon: <PenTool className="w-5 h-5" />,
    features: ['SEO optimization', 'Brand voice', 'Multiple formats'],
  },
  {
    id: 'analyzer',
    title: 'Data Analyzer',
    description: 'Extract insights and analyze information',
    icon: <BarChart3 className="w-5 h-5" />,
    features: ['Pattern detection', 'Trend analysis', 'Report generation'],
  },
  {
    id: 'coder',
    title: 'Code Assistant',
    description: 'Programming help and code generation',
    icon: <Code className="w-5 h-5" />,
    features: ['Code review', 'Bug fixing', 'Documentation'],
  },
  {
    id: 'designer',
    title: 'Design Prototyper',
    description: 'AI-powered design assistance and rapid prototyping',
    icon: <Palette className="w-5 h-5" />,
    features: ['UI/UX design', 'Design systems', 'Rapid prototyping'],
  },
  {
    id: 'researcher',
    title: 'Research Assistant',
    description: 'Research, summarize, and synthesize information from multiple sources',
    icon: <Search className="w-5 h-5" />,
    features: ['Document analysis', 'Citation management', 'Knowledge synthesis'],
  }
];

// Deployment recommendation algorithm
function generateDeploymentRecommendations(answers: Partial<QuestionnaireAnswers>): DeploymentRecommendation[] {
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
  if (answers.technicalLevel === 'intermediate' && ['team', 'company'].includes(answers.expectedUsers || '')) {
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

export function Step0BuildPath({ data, onUpdate, onNext }: Step0BuildPathProps) {
  const [selectedPath, setSelectedPath] = useState<'guided' | 'custom' | null>(data?.buildType || null);
  const [showGuidedWizard, setShowGuidedWizard] = useState(false);
  const [currentQuestion, setCurrentQuestion] = useState(0);
  const [answers, setAnswers] = useState<Partial<QuestionnaireAnswers>>({});
  const [recommendations, setRecommendations] = useState<DeploymentRecommendation[]>([]);
  const [showResults, setShowResults] = useState(false);

  const questions = [
    // Agent Profile Questions
    {
      id: 'agentName',
      title: 'What\'s your agent\'s name?',
      description: 'Give your AI agent a memorable name that reflects its purpose.',
      type: 'text',
      placeholder: 'e.g., Customer Support Bot, Research Assistant, Code Helper'
    },
    {
      id: 'agentDescription',
      title: 'What will your agent do?',
      description: 'Describe your agent\'s main purpose and capabilities in 2-3 sentences.',
      type: 'textarea',
      placeholder: 'e.g., An intelligent assistant that helps customers with product questions, troubleshooting, and order support. It can access our knowledge base and escalate complex issues to human agents.'
    },
    {
      id: 'agentCompany',
      title: 'Company or Organization (Optional)',
      description: 'What company or project is this agent for?',
      type: 'text',
      placeholder: 'e.g., Acme Corp, Personal Project'
    },
    {
      id: 'primaryPurpose',
      title: 'What\'s your agent\'s primary use case?',
      description: 'Choose the category that best matches your agent\'s main function.',
      type: 'select',
      options: useCases
    },
    {
      id: 'targetEnvironment',
      title: 'What environment will you deploy to?',
      description: 'Select your target deployment environment.',
      type: 'select',
      options: [
        { id: 'development', title: 'Development', description: 'For testing and development' },
        { id: 'staging', title: 'Staging', description: 'For pre-production testing' },
        { id: 'production', title: 'Production', description: 'For live deployment' }
      ]
    },
    
    // Deployment Questions
    {
      id: 'technicalLevel',
      title: 'What\'s your technical expertise level?',
      description: 'This helps us recommend the right complexity level for your deployment.',
      type: 'select',
      options: [
        { id: 'beginner', title: 'Beginner', description: 'I prefer simple, one-click solutions' },
        { id: 'intermediate', title: 'Intermediate', description: 'I can handle some configuration and CLI tools' },
        { id: 'advanced', title: 'Advanced', description: 'I\'m comfortable with complex infrastructure and DevOps' }
      ]
    },
    {
      id: 'expectedUsers',
      title: 'Who will be using your AI agent?',
      description: 'Different scales require different deployment approaches.',
      type: 'select',
      options: [
        { id: 'personal', title: 'Just Me', description: 'Personal use or small experiments' },
        { id: 'team', title: 'Small Team', description: '5-50 people in my organization' },
        { id: 'company', title: 'Company', description: '50-1000 employees' },
        { id: 'public', title: 'Public Users', description: 'Thousands of external users' }
      ]
    },
    {
      id: 'budget',
      title: 'What\'s your budget preference?',
      description: 'We\'ll recommend options that fit your budget constraints.',
      type: 'select',
      options: [
        { id: 'free', title: 'Free Tier', description: 'I want to start with free options' },
        { id: 'low', title: 'Low Cost', description: '$5-50/month for basic usage' },
        { id: 'medium', title: 'Medium Budget', description: '$50-500/month for growing needs' },
        { id: 'enterprise', title: 'Enterprise', description: '$500+/month with full features' }
      ]
    },
    {
      id: 'performance',
      title: 'What performance level do you need?',
      description: 'Higher performance requirements may need more robust solutions.',
      type: 'select',
      options: [
        { id: 'basic', title: 'Basic', description: 'Response times under 5 seconds are fine' },
        { id: 'standard', title: 'Standard', description: 'Response times under 2 seconds' },
        { id: 'high', title: 'High Performance', description: 'Sub-second response times' },
        { id: 'critical', title: 'Mission Critical', description: 'Ultra-low latency required' }
      ]
    },
    {
      id: 'availability',
      title: 'How critical is uptime?',
      description: 'Different availability needs require different deployment strategies.',
      type: 'select',
      options: [
        { id: 'development', title: 'Development', description: 'Occasional downtime is acceptable' },
        { id: 'business', title: 'Business Hours', description: '99.5% uptime during business hours' },
        { id: 'mission_critical', title: 'Mission Critical', description: '99.9%+ uptime required 24/7' }
      ]
    },
    {
      id: 'regions',
      title: 'Where are your users located?',
      description: 'Geographic distribution affects deployment strategy.',
      type: 'select',
      options: [
        { id: 'single', title: 'Single Region', description: 'Users are primarily in one geographic area' },
        { id: 'multi', title: 'Multiple Regions', description: 'Users across 2-3 major regions' },
        { id: 'global', title: 'Global', description: 'Users worldwide need low latency' }
      ]
    },
    {
      id: 'security',
      title: 'What are your security requirements?',
      description: 'Security needs vary by industry and use case.',
      type: 'select',
      options: [
        { id: 'basic', title: 'Basic', description: 'Standard HTTPS and basic auth' },
        { id: 'standard', title: 'Standard', description: 'Role-based access and audit logs' },
        { id: 'enterprise', title: 'Enterprise', description: 'Advanced security, compliance, SOC 2' },
        { id: 'government', title: 'Government', description: 'FISMA, FedRAMP compliance required' }
      ]
    },
    {
      id: 'maintenance',
      title: 'How much maintenance do you want to handle?',
      description: 'Some solutions require more hands-on management than others.',
      type: 'select',
      options: [
        { id: 'none', title: 'Zero Maintenance', description: 'I want a completely managed solution' },
        { id: 'minimal', title: 'Minimal', description: 'Occasional updates and monitoring' },
        { id: 'managed', title: 'Some Management', description: 'I can handle basic DevOps tasks' },
        { id: 'full_support', title: 'Full Control', description: 'I want complete control over infrastructure' }
      ]
    }
  ];

  const handlePathSelect = (path: 'guided' | 'custom') => {
    setSelectedPath(path);
    
    if (path === 'guided') {
      setShowGuidedWizard(true);
      setCurrentQuestion(0);
      setAnswers({});
      setRecommendations([]);
      setShowResults(false);
    } else {
      // Custom path - go directly to Step 1 with basic setup
      onUpdate({
        buildType: 'custom'
      });
      onNext();
    }
  };

  const handleAnswerChange = (questionId: string, value: string) => {
    const newAnswers = { ...answers, [questionId]: value };
    setAnswers(newAnswers);
  };

  const handleNextQuestion = () => {
    if (currentQuestion < questions.length - 1) {
      setCurrentQuestion(currentQuestion + 1);
    } else {
      // Generate recommendations and complete guided setup
      const recs = generateDeploymentRecommendations(answers);
      setRecommendations(recs);
      setShowResults(true);
    }
  };

  const handlePreviousQuestion = () => {
    if (currentQuestion > 0) {
      setCurrentQuestion(currentQuestion - 1);
    }
  };

  const handleCompleteGuidedSetup = () => {
    // Save all answers and proceed to next step
    onUpdate({
      buildType: 'guided',
      agentName: answers.agentName,
      agentDescription: answers.agentDescription,
      agentCompany: answers.agentCompany,
      primaryPurpose: answers.primaryPurpose,
      targetEnvironment: answers.targetEnvironment,
      recommendedDeployment: recommendations.length > 0 ? recommendations[0].platform : null,
      deploymentRecommendations: recommendations,
      guidedAnswers: answers
    });
    setShowGuidedWizard(false);
    onNext();
  };

  const currentQuestionData = questions[currentQuestion];
  const currentAnswer = currentQuestionData ? answers[currentQuestionData.id as keyof QuestionnaireAnswers] : null;
  const canProceed = currentAnswer && currentAnswer.toString().trim().length > 0;

  return (
    <div className="p-8 animate-fadeIn">
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <div className="text-center mb-12">
          <div className="inline-flex items-center gap-2 bg-primary/10 text-primary px-4 py-2 rounded-full text-sm font-medium mb-6">
            <Sparkles className="w-4 h-4" />
            AI Agent Builder
          </div>
          <h1 className="text-4xl font-bold text-foreground mb-4">
            Choose Your Build Experience
          </h1>
          <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
            Get started with AI-powered guidance or dive straight into custom configuration
          </p>
        </div>

        {/* Path Selection Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8 mb-12">
          {/* Guided Build Option */}
          <Card 
            className={`cursor-pointer transition-all duration-300 hover:shadow-lg hover:scale-105 group ${
              selectedPath === 'guided' ? 'ring-2 ring-primary shadow-lg' : 'hover:border-primary/50'
            }`}
            onClick={() => handlePathSelect('guided')}
          >
            <CardHeader className="text-center pb-4">
              <div className="w-20 h-20 bg-gradient-to-br from-blue-500/20 to-purple-500/20 rounded-2xl flex items-center justify-center mx-auto mb-6 group-hover:scale-110 transition-transform">
                <HelpCircle className="w-10 h-10 text-blue-500" />
              </div>
              <CardTitle className="text-2xl mb-2">🚀 Guided Build</CardTitle>
              <CardDescription className="text-base">
                AI-powered questionnaire creates your agent automatically
              </CardDescription>
              <div className="mt-3">
                <Badge variant="secondary" className="bg-green-500/10 text-green-600 border-green-500/20">
                  👋 Good for first-time users
                </Badge>
              </div>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="space-y-4">
                <div className="flex items-center gap-3">
                  <CheckCircle className="w-5 h-5 text-green-500 flex-shrink-0" />
                  <span>Smart questionnaire (5-8 minutes)</span>
                </div>
                <div className="flex items-center gap-3">
                  <CheckCircle className="w-5 h-5 text-green-500 flex-shrink-0" />
                  <span>AI-powered deployment recommendations</span>
                </div>
                <div className="flex items-center gap-3">
                  <CheckCircle className="w-5 h-5 text-green-500 flex-shrink-0" />
                  <span>Pre-configured best practices</span>
                </div>
                <div className="flex items-center gap-3">
                  <CheckCircle className="w-5 h-5 text-green-500 flex-shrink-0" />
                  <span>Optimized for your specific needs</span>
                </div>
              </div>
              
              <div className="pt-4 border-t">
                <Badge className="bg-blue-500/20 text-blue-600 border-blue-500/30 text-sm px-3 py-1">
                  ⭐ Recommended for most users
                </Badge>
              </div>
            </CardContent>
          </Card>

          {/* Custom Build Option */}
          <Card 
            className={`cursor-pointer transition-all duration-300 hover:shadow-lg hover:scale-105 group ${
              selectedPath === 'custom' ? 'ring-2 ring-primary shadow-lg' : 'hover:border-primary/50'
            }`}
            onClick={() => handlePathSelect('custom')}
          >
            <CardHeader className="text-center pb-4">
              <div className="w-20 h-20 bg-gradient-to-br from-orange-500/20 to-red-500/20 rounded-2xl flex items-center justify-center mx-auto mb-6 group-hover:scale-110 transition-transform">
                <Settings className="w-10 h-10 text-orange-500" />
              </div>
              <CardTitle className="text-2xl mb-2">⚙️ Custom Build</CardTitle>
              <CardDescription className="text-base">
                Full control over every configuration option
              </CardDescription>
              <div className="mt-3">
                <Badge variant="secondary" className="bg-blue-500/10 text-blue-600 border-blue-500/20">
                  🧠 Good for technical-minded people
                </Badge>
              </div>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="space-y-4">
                <div className="flex items-center gap-3">
                  <CheckCircle className="w-5 h-5 text-green-500 flex-shrink-0" />
                  <span>Complete configuration control</span>
                </div>
                <div className="flex items-center gap-3">
                  <CheckCircle className="w-5 h-5 text-green-500 flex-shrink-0" />
                  <span>Access to all deployment options</span>
                </div>
                <div className="flex items-center gap-3">
                  <CheckCircle className="w-5 h-5 text-green-500 flex-shrink-0" />
                  <span>Advanced security settings</span>
                </div>
                <div className="flex items-center gap-3">
                  <CheckCircle className="w-5 h-5 text-green-500 flex-shrink-0" />
                  <span>Expert-level customization</span>
                </div>
              </div>
              
              <div className="pt-4 border-t">
                <Badge variant="outline" className="border-orange-500/30 text-orange-600 text-sm px-3 py-1">
                  🔧 For experienced developers
                </Badge>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Guided Build Wizard */}
        <Dialog open={showGuidedWizard} onOpenChange={setShowGuidedWizard}>
          <DialogContent className="max-w-3xl max-h-[90vh] overflow-y-auto">
            <DialogHeader>
              <DialogTitle className="text-xl">
                {showResults ? '🎉 Your AI Agent Configuration' : `Guided Setup (${currentQuestion + 1}/${questions.length})`}
              </DialogTitle>
              <DialogDescription>
                {showResults 
                  ? 'Perfect! Here\'s your customized AI agent setup with deployment recommendations.'
                  : 'Answer these questions to build your AI agent automatically.'
                }
              </DialogDescription>
            </DialogHeader>

            {!showResults ? (
              <div className="space-y-6">
                {/* Progress bar */}
                <div className="w-full bg-muted rounded-full h-3">
                  <div 
                    className="bg-gradient-to-r from-blue-500 to-purple-500 h-3 rounded-full transition-all duration-500"
                    style={{ width: `${((currentQuestion + 1) / questions.length) * 100}%` }}
                  />
                </div>

                {/* Question */}
                <div className="space-y-6">
                  <div>
                    <h3 className="text-lg font-semibold mb-2">
                      {currentQuestionData?.title}
                    </h3>
                    <p className="text-muted-foreground">
                      {currentQuestionData?.description}
                    </p>
                  </div>

                  {/* Question Input */}
                  <div className="space-y-4">
                    {currentQuestionData?.type === 'text' && (
                      <div className="space-y-2">
                        <Input
                          placeholder={currentQuestionData.placeholder}
                          value={answers[currentQuestionData.id as keyof QuestionnaireAnswers] || ''}
                          onChange={(e) => handleAnswerChange(currentQuestionData.id, e.target.value)}
                          className="text-base p-4"
                        />
                      </div>
                    )}

                    {currentQuestionData?.type === 'textarea' && (
                      <div className="space-y-2">
                        <Textarea
                          placeholder={currentQuestionData.placeholder}
                          value={answers[currentQuestionData.id as keyof QuestionnaireAnswers] || ''}
                          onChange={(e) => handleAnswerChange(currentQuestionData.id, e.target.value)}
                          className="text-base p-4 min-h-[120px]"
                        />
                      </div>
                    )}

                    {currentQuestionData?.type === 'select' && (
                      <div className="grid grid-cols-1 gap-3">
                        {currentQuestionData.options?.map((option: any) => (
                          <div
                            key={option.id}
                            className={`
                              p-4 rounded-lg border cursor-pointer transition-all duration-200
                              ${answers[currentQuestionData.id as keyof QuestionnaireAnswers] === option.id
                                ? 'border-primary bg-primary/10 shadow-sm'
                                : 'border-border hover:border-primary/50 hover:bg-muted/50'
                              }
                            `}
                            onClick={() => handleAnswerChange(currentQuestionData.id, option.id)}
                          >
                            <div className="flex items-start gap-3">
                              <div className={`
                                w-4 h-4 rounded-full border-2 mt-1 transition-colors
                                ${answers[currentQuestionData.id as keyof QuestionnaireAnswers] === option.id
                                  ? 'border-primary bg-primary'
                                  : 'border-muted-foreground'
                                }
                              `}>
                                {answers[currentQuestionData.id as keyof QuestionnaireAnswers] === option.id && (
                                  <div className="w-2 h-2 bg-white rounded-full mx-auto mt-0.5" />
                                )}
                              </div>
                              <div className="flex-1">
                                <div className="flex items-center gap-2">
                                  {option.icon && <span>{option.icon}</span>}
                                  <div className="font-medium">{option.title}</div>
                                </div>
                                <div className="text-sm text-muted-foreground mt-1">{option.description}</div>
                                {option.features && (
                                  <div className="flex flex-wrap gap-1 mt-2">
                                    {option.features.map((feature: string, index: number) => (
                                      <Badge key={index} variant="outline" className="text-xs">
                                        {feature}
                                      </Badge>
                                    ))}
                                  </div>
                                )}
                              </div>
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                </div>

                {/* Navigation */}
                <div className="flex justify-between pt-6 border-t">
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
                    className="bg-gradient-to-r from-blue-500 to-purple-500 hover:from-blue-600 hover:to-purple-600"
                  >
                    {currentQuestion === questions.length - 1 ? 'Generate Agent' : 'Next'}
                    <ArrowRight className="w-4 h-4 ml-2" />
                  </Button>
                </div>
              </div>
            ) : (
              <div className="space-y-6">
                {/* Agent Summary */}
                <Card className="border-primary/20 bg-primary/5">
                  <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                      <User className="w-5 h-5" />
                      {answers.agentName}
                    </CardTitle>
                    <CardDescription>
                      {answers.agentDescription}
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="flex items-center gap-4 text-sm">
                      <Badge variant="outline">{useCases.find(uc => uc.id === answers.primaryPurpose)?.title}</Badge>
                      <Badge variant="outline">{answers.targetEnvironment}</Badge>
                      {answers.agentCompany && <Badge variant="outline">{answers.agentCompany}</Badge>}
                    </div>
                  </CardContent>
                </Card>

                {/* Deployment Recommendations */}
                <div className="space-y-4">
                  <h3 className="text-lg font-semibold">🚀 Recommended Deployment</h3>
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
                <div className="flex justify-between pt-6 border-t">
                  <Button
                    variant="outline"
                    onClick={() => {
                      setShowResults(false);
                      setCurrentQuestion(0);
                    }}
                  >
                    Start Over
                  </Button>
                  <Button 
                    onClick={handleCompleteGuidedSetup}
                    className="bg-gradient-to-r from-blue-500 to-purple-500 hover:from-blue-600 hover:to-purple-600"
                  >
                    Continue Building Agent
                    <ArrowRight className="w-4 h-4 ml-2" />
                  </Button>
                </div>
              </div>
            )}
          </DialogContent>
        </Dialog>

        {/* Navigation */}
        <div className="flex items-center justify-center">
          <div className="text-sm text-muted-foreground">
            Choose your path to get started
          </div>
        </div>
      </div>
    </div>
  );
}