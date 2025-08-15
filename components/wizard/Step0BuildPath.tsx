import { useState } from 'react';
import { Button } from '../ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '../ui/dialog';
import { Input } from '../ui/input';
import { Textarea } from '../ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { ArrowRight, Settings, HelpCircle, CheckCircle, Zap, Globe, Package, Cloud, AlertCircle, MessageSquare, PenTool, BarChart3, Code, Palette, Search, Sparkles, User } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { AgentTemplate, findMatchingTemplate, BEGINNER_AGENT_TEMPLATES } from '../../types/agent-templates';

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
  const { user, hasFeature } = useAuth();
  const [selectedPath, setSelectedPath] = useState<'guided' | 'custom' | null>(data?.buildType || null);
  const [showGuidedWizard, setShowGuidedWizard] = useState(false);
  const [currentQuestion, setCurrentQuestion] = useState(0);
  const [answers, setAnswers] = useState<Partial<QuestionnaireAnswers>>({});
  const [recommendations, setRecommendations] = useState<DeploymentRecommendation[]>([]);
  const [showResults, setShowResults] = useState(false);
  const [selectedTemplate, setSelectedTemplate] = useState<AgentTemplate | null>(null);
  const [showTemplateSelection, setShowTemplateSelection] = useState(false);
  
  const isBeginnerUser = user?.role === 'beginner';
  const canUseCustomBuilder = hasFeature('custom-builder');

  // For free/consumer users, we only ask the essential questions
  // Technical details are auto-configured based on their tier
  const questions = isBeginnerUser ? [
    // Essential Questions Only for Consumers (5 questions)
    {
      id: 'agentName',
      title: 'What would you like to call your assistant?',
      description: 'Give it a friendly name that you\'ll remember.',
      type: 'text',
      placeholder: 'e.g., Helper, Assistant, Support Bot'
    },
    {
      id: 'agentDescription',
      title: 'What do you need help with?',
      description: 'Tell us in your own words what you want your assistant to do.',
      type: 'textarea',
      placeholder: 'e.g., I need help answering customer emails, writing blog posts, or analyzing my sales data'
    },
    {
      id: 'primaryPurpose',
      title: 'What type of assistant do you need?',
      description: 'Pick the one that best matches what you\'re looking for.',
      type: 'select',
      options: useCases
    },
    {
      id: 'expectedUsers',
      title: 'Who will interact with your assistant?',
      description: 'This helps us prepare the right setup for you.',
      type: 'select',
      options: [
        { id: 'personal', title: 'Just Me', description: 'My personal assistant' },
        { id: 'team', title: 'My Team', description: 'A small group of people' },
        { id: 'company', title: 'My Whole Company', description: 'All our employees' },
        { id: 'public', title: 'My Customers', description: 'People outside my company' }
      ]
    },
    {
      id: 'targetEnvironment',
      title: 'When do you want to start using it?',
      description: 'We\'ll set it up accordingly.',
      type: 'select',
      options: [
        { id: 'development', title: 'Just Looking', description: 'I\'m exploring options' },
        { id: 'staging', title: 'Soon', description: 'Getting ready to use it' },
        { id: 'production', title: 'Right Now', description: 'I need it working today' }
      ]
    }
  ] : [
    // Full question set for power/enterprise users
    {
      id: 'agentName',
      title: 'What would you like to call your assistant?',
      description: 'Give it a friendly name that you\'ll remember.',
      type: 'text',
      placeholder: 'e.g., Helper, Assistant, Support Bot'
    },
    {
      id: 'agentDescription',
      title: 'What do you need help with?',
      description: 'Tell us in your own words what you want your assistant to do.',
      type: 'textarea',
      placeholder: 'e.g., I need help answering customer emails, writing blog posts, or analyzing my sales data'
    },
    {
      id: 'agentCompany',
      title: 'What\'s your company name? (Optional)',
      description: 'This helps us customize your assistant.',
      type: 'text',
      placeholder: 'e.g., My Business, Personal Use'
    },
    {
      id: 'primaryPurpose',
      title: 'What type of assistant do you need?',
      description: 'Pick the one that best matches what you\'re looking for.',
      type: 'select',
      options: useCases
    },
    {
      id: 'targetEnvironment',
      title: 'How will you use this assistant?',
      description: 'This helps us set it up correctly.',
      type: 'select',
      options: [
        { id: 'development', title: 'Just Testing', description: 'I\'m trying it out' },
        { id: 'staging', title: 'Getting Ready', description: 'Preparing for real use' },
        { id: 'production', title: 'Ready to Use', description: 'I need it working now' }
      ]
    },
    {
      id: 'technicalLevel',
      title: 'How do you prefer to work with technology?',
      description: 'This helps us make things as easy as possible for you.',
      type: 'select',
      options: [
        { id: 'beginner', title: 'Keep it Simple', description: 'I want everything done for me' },
        { id: 'intermediate', title: 'Some Setup OK', description: 'I can handle basic setup' },
        { id: 'advanced', title: 'I Like Control', description: 'I enjoy customizing things' }
      ]
    },
    {
      id: 'expectedUsers',
      title: 'Who will interact with your assistant?',
      description: 'This helps us prepare the right setup for you.',
      type: 'select',
      options: [
        { id: 'personal', title: 'Just Me', description: 'My personal assistant' },
        { id: 'team', title: 'My Team', description: 'A small group of people' },
        { id: 'company', title: 'My Whole Company', description: 'All our employees' },
        { id: 'public', title: 'My Customers', description: 'People outside my company' }
      ]
    },
    {
      id: 'budget',
      title: 'What would you like to spend?',
      description: 'Don\'t worry - we have great free options!',
      type: 'select',
      options: [
        { id: 'free', title: 'Nothing Yet', description: 'Let me try it free first' },
        { id: 'low', title: 'Coffee Budget', description: 'A few dollars per month' },
        { id: 'medium', title: 'Business Tool', description: 'Worth investing in' },
        { id: 'enterprise', title: 'Whatever It Takes', description: 'This is critical for us' }
      ]
    },
    {
      id: 'performance',
      title: 'When your assistant responds, how fast should it be?',
      description: 'Think about how you\'ll be using it day-to-day.',
      type: 'select',
      options: [
        { id: 'basic', title: 'Relaxed', description: 'I can wait a few seconds' },
        { id: 'standard', title: 'Snappy', description: 'Like chatting with a friend' },
        { id: 'high', title: 'Instant', description: 'No waiting at all' },
        { id: 'critical', title: 'Real-time', description: 'For live customer service' }
      ]
    }
  ];

  const handlePathSelect = (path: 'guided' | 'custom') => {
    setSelectedPath(path);
    
    if (path === 'guided') {
      if (isBeginnerUser) {
        // For beginners, start with template selection after questionnaire
        setShowGuidedWizard(true);
        setCurrentQuestion(0);
        setAnswers({});
        setRecommendations([]);
        setShowResults(false);
        setShowTemplateSelection(false);
      } else {
        // For power users and enterprise, use original guided flow
        setShowGuidedWizard(true);
        setCurrentQuestion(0);
        setAnswers({});
        setRecommendations([]);
        setShowResults(false);
      }
    } else {
      if (!canUseCustomBuilder) {
        // Free users can't access custom builder, redirect to guided
        alert('Custom builder is available for Power User and Enterprise plans. Please upgrade or use the guided builder.');
        return;
      }
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
      if (isBeginnerUser) {
        // For free users, find matching template
        const template = findMatchingTemplate(answers as Record<string, string>);
        setSelectedTemplate(template);
        setShowTemplateSelection(true);
      } else {
        // For paid users, show deployment recommendations
        const recs = generateDeploymentRecommendations(answers);
        setRecommendations(recs);
        setShowResults(true);
      }
    }
  };

  const handlePreviousQuestion = () => {
    if (currentQuestion > 0) {
      setCurrentQuestion(currentQuestion - 1);
    }
  };

  const handleCompleteGuidedSetup = () => {
    if (isBeginnerUser && selectedTemplate) {
      // Save template-based configuration for free users
      onUpdate({
        buildType: 'template',
        selectedTemplate: selectedTemplate,
        agentName: selectedTemplate.config.agentName,
        agentDescription: selectedTemplate.config.agentDescription,
        primaryPurpose: selectedTemplate.config.primaryPurpose,
        requiredMcps: selectedTemplate.config.requiredMcps,
        optionalMcps: selectedTemplate.config.optionalMcps,
        securitySettings: selectedTemplate.config.securitySettings,
        recommendedDeployment: selectedTemplate.config.recommendedDeployment[0],
        specialFeatures: selectedTemplate.config.specialFeatures,
        guidedAnswers: answers,
        isPreConfigured: true
      });
    } else {
      // Save all answers and proceed to next step for paid users
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
    }
    setShowGuidedWizard(false);
    onNext();
  };

  const handleTemplateSelection = (template: AgentTemplate) => {
    setSelectedTemplate(template);
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
            Who Are You Building For?
          </h1>
          <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
            Choose the path that matches your needs - ready-to-use AI assistants or custom development
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
              <CardTitle className="text-2xl mb-2">👤 I'm an End User</CardTitle>
              <CardDescription className="text-base">
                Get a ready-to-use AI assistant tailored to your needs
              </CardDescription>
              <div className="mt-3">
                <Badge variant="secondary" className="bg-green-500/10 text-green-600 border-green-500/20">
                  ✨ No coding required
                </Badge>
              </div>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="space-y-4">
                <div className="flex items-center gap-3">
                  <CheckCircle className="w-5 h-5 text-green-500 flex-shrink-0" />
                  <span>Simple 5-minute setup</span>
                </div>
                <div className="flex items-center gap-3">
                  <CheckCircle className="w-5 h-5 text-green-500 flex-shrink-0" />
                  <span>Pre-built AI assistants</span>
                </div>
                <div className="flex items-center gap-3">
                  <CheckCircle className="w-5 h-5 text-green-500 flex-shrink-0" />
                  <span>Works immediately</span>
                </div>
                <div className="flex items-center gap-3">
                  <CheckCircle className="w-5 h-5 text-green-500 flex-shrink-0" />
                  <span>Support included</span>
                </div>
              </div>
              
              <div className="pt-4 border-t">
                <Badge className="bg-blue-500/20 text-blue-600 border-blue-500/30 text-sm px-3 py-1">
                  ⭐ Perfect for business users
                </Badge>
              </div>
            </CardContent>
          </Card>

          {/* Custom Build Option */}
          <Card 
            className={`cursor-pointer transition-all duration-300 hover:shadow-lg hover:scale-105 group relative ${
              selectedPath === 'custom' ? 'ring-2 ring-primary shadow-lg' : 'hover:border-primary/50'
            } ${!canUseCustomBuilder ? 'opacity-75' : ''}`}
            onClick={() => handlePathSelect('custom')}
          >
            {!canUseCustomBuilder && (
              <div className="absolute inset-0 bg-black/5 rounded-lg flex items-center justify-center z-10">
                <Badge className="bg-orange-500 text-white">
                  Upgrade Required
                </Badge>
              </div>
            )}
            <CardHeader className="text-center pb-4">
              <div className="w-20 h-20 bg-gradient-to-br from-orange-500/20 to-red-500/20 rounded-2xl flex items-center justify-center mx-auto mb-6 group-hover:scale-110 transition-transform">
                <Settings className="w-10 h-10 text-orange-500" />
              </div>
              <CardTitle className="text-2xl mb-2">💻 I'm a Developer</CardTitle>
              <CardDescription className="text-base">
                Build custom AI agents with full control
              </CardDescription>
              <div className="mt-3">
                <Badge variant="secondary" className="bg-blue-500/10 text-blue-600 border-blue-500/20">
                  🔧 Requires technical skills
                </Badge>
              </div>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="space-y-4">
                <div className="flex items-center gap-3">
                  <CheckCircle className="w-5 h-5 text-green-500 flex-shrink-0" />
                  <span>Full API access</span>
                </div>
                <div className="flex items-center gap-3">
                  <CheckCircle className="w-5 h-5 text-green-500 flex-shrink-0" />
                  <span>Custom integrations</span>
                </div>
                <div className="flex items-center gap-3">
                  <CheckCircle className="w-5 h-5 text-green-500 flex-shrink-0" />
                  <span>Enterprise deployment</span>
                </div>
                <div className="flex items-center gap-3">
                  <CheckCircle className="w-5 h-5 text-green-500 flex-shrink-0" />
                  <span>Source code access</span>
                </div>
              </div>
              
              <div className="pt-4 border-t">
                <Badge variant="outline" className="border-orange-500/30 text-orange-600 text-sm px-3 py-1">
                  🚀 For technical teams
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
                {showTemplateSelection 
                  ? '🎯 Your Perfect Assistant Match'
                  : showResults 
                    ? '🎉 Your Assistant is Ready!' 
                    : `Quick Setup (Question ${currentQuestion + 1} of ${questions.length})`}
              </DialogTitle>
              <DialogDescription>
                {showTemplateSelection
                  ? 'Based on your needs, we\'ve found the perfect assistant for you.'
                  : showResults 
                    ? 'Great! Your assistant is configured and ready to help.'
                    : 'Just a few simple questions to get your assistant ready.'
                }
              </DialogDescription>
            </DialogHeader>

            {showTemplateSelection && selectedTemplate ? (
              <div className="space-y-6">
                {/* Recommended Template */}
                <Card className="border-primary dark:border-primary/50 bg-primary/5 dark:bg-primary/10">
                  <CardHeader>
                    <div className="flex items-center gap-3 mb-2">
                      <div className="text-2xl">{selectedTemplate.icon}</div>
                      <div>
                        <CardTitle className="flex items-center gap-2">
                          {selectedTemplate.name}
                          <Badge className="bg-green-500 dark:bg-green-600 text-white">
                            <Star className="w-3 h-3 mr-1" />
                            Recommended
                          </Badge>
                        </CardTitle>
                        <CardDescription className="text-base">
                          {selectedTemplate.description}
                        </CardDescription>
                      </div>
                    </div>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div>
                        <h5 className="font-medium mb-2">✨ Included Features:</h5>
                        <ul className="text-sm space-y-1">
                          {selectedTemplate.config.requiredMcps.map((mcp, i) => (
                            <li key={i} className="flex items-center gap-2">
                              <CheckCircle className="w-3 h-3 text-green-500" />
                              {mcp.replace('-mcp', '').replace('-', ' ').replace(/\b\w/g, l => l.toUpperCase())}
                            </li>
                          ))}
                        </ul>
                      </div>
                      <div>
                        <h5 className="font-medium mb-2">🚀 Pre-configured:</h5>
                        <ul className="text-sm space-y-1">
                          <li className="flex items-center gap-2">
                            <CheckCircle className="w-3 h-3 text-green-500" />
                            Security settings optimized for {selectedTemplate.targetRole}
                          </li>
                          <li className="flex items-center gap-2">
                            <CheckCircle className="w-3 h-3 text-green-500" />
                            Local deployment ready
                          </li>
                          {selectedTemplate.config.specialFeatures?.uploadSupport && (
                            <li className="flex items-center gap-2">
                              <Upload className="w-3 h-3 text-blue-500" />
                              File upload support ({selectedTemplate.config.specialFeatures.uploadSupport.maxFileSize})
                            </li>
                          )}
                        </ul>
                      </div>
                    </div>

                    {selectedTemplate.config.specialFeatures?.uploadSupport && (
                      <div className="bg-blue-50 dark:bg-blue-950/30 p-3 rounded-lg border border-blue-200 dark:border-blue-800">
                        <div className="flex items-center gap-2 text-blue-700 dark:text-blue-300 font-medium mb-1">
                          <Upload className="w-4 h-4" />
                          Upload Support Included
                        </div>
                        <p className="text-sm text-blue-600 dark:text-blue-400">
                          {selectedTemplate.config.specialFeatures.uploadSupport.description}
                        </p>
                        <div className="flex gap-2 mt-2">
                          {selectedTemplate.config.specialFeatures.uploadSupport.allowedTypes.slice(0, 4).map((type, i) => (
                            <Badge key={i} variant="outline" className="text-xs border-blue-300 dark:border-blue-700 text-blue-600 dark:text-blue-400">
                              {type}
                            </Badge>
                          ))}
                          {selectedTemplate.config.specialFeatures.uploadSupport.allowedTypes.length > 4 && (
                            <Badge variant="outline" className="text-xs border-blue-300 dark:border-blue-700 text-blue-600 dark:text-blue-400">
                              +{selectedTemplate.config.specialFeatures.uploadSupport.allowedTypes.length - 4} more
                            </Badge>
                          )}
                        </div>
                      </div>
                    )}
                  </CardContent>
                </Card>

                {/* Alternative Templates */}
                <div className="space-y-3">
                  <h4 className="font-medium text-muted-foreground">Or choose a different template:</h4>
                  <div className="grid grid-cols-1 gap-3 max-h-60 overflow-y-auto">
                    {BEGINNER_AGENT_TEMPLATES.filter(t => t.id !== selectedTemplate.id).map((template) => (
                      <Card 
                        key={template.id}
                        className="cursor-pointer transition-all hover:shadow-md hover:border-primary/50 p-3"
                        onClick={() => handleTemplateSelection(template)}
                      >
                        <div className="flex items-center gap-3">
                          <div className="text-lg">{template.icon}</div>
                          <div className="flex-1">
                            <div className="font-medium">{template.name}</div>
                            <div className="text-sm text-muted-foreground line-clamp-1">
                              {template.description}
                            </div>
                          </div>
                          <Badge variant="outline" className="text-xs">
                            {template.category}
                          </Badge>
                        </div>
                      </Card>
                    ))}
                  </div>
                </div>

                {/* Actions */}
                <div className="flex justify-between pt-6 border-t">
                  <Button
                    variant="outline"
                    onClick={() => {
                      setShowTemplateSelection(false);
                      setCurrentQuestion(questions.length - 1);
                    }}
                  >
                    Back to Questions
                  </Button>
                  <Button 
                    onClick={handleCompleteGuidedSetup}
                    className="bg-gradient-to-r from-blue-500 to-purple-500 hover:from-blue-600 hover:to-purple-600"
                  >
                    Start Using This Assistant
                    <ArrowRight className="w-4 h-4 ml-2" />
                  </Button>
                </div>
              </div>
            ) : !showResults ? (
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
                    {currentQuestion === questions.length - 1 ? 'Find My Assistant' : 'Next'}
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
                      <Card key={rec.platform} className={`${index === 0 ? 'border-primary dark:border-primary/50 bg-primary/5 dark:bg-primary/10' : ''}`}>
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
                    Get Started
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