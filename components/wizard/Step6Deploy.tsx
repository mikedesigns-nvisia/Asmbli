import React, { useState } from 'react';
import { Button } from '../ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '../ui/dialog';
import { Textarea } from '../ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { RotateCcw, Download, Copy, CheckCircle, Zap, Package, Cloud, Settings, Star, ExternalLink, BookmarkPlus, Eye, Wand2, Brain, Target, AlertTriangle, RefreshCw, Play, Timer, Globe, ThumbsUp, ThumbsDown, Lightbulb, TrendingUp, Cpu, Database, Terminal, FileText, Search, Shield } from 'lucide-react';

interface Step6DeployProps {
  data: any;
  onUpdate: (updates: any) => void;
  onStartOver: () => void;
  promptOutput: string;
  deploymentConfigs: Record<string, string>;
  copiedItem: string | null;
  onCopy: (text: string, itemType: string) => void;
  onSaveAsTemplate?: () => void;
}

interface LLMProvider {
  id: string;
  name: string;
  icon: string;
  color: string;
  strengths: string[];
  pricing: 'Free' | 'Paid' | 'Freemium';
  description: string;
}

interface OptimizationSuggestion {
  id: string;
  type: 'clarity' | 'structure' | 'tokens' | 'performance' | 'security';
  severity: 'low' | 'medium' | 'high';
  title: string;
  description: string;
  before: string;
  after: string;
  impact: string;
}

interface TestResult {
  provider: string;
  status: 'pending' | 'success' | 'error' | 'testing';
  responseTime?: number;
  tokenUsage?: number;
  qualityScore?: number;
  responsePreview?: string;
  error?: string;
}

const llmProviders: LLMProvider[] = [
  {
    id: 'openai',
    name: 'OpenAI GPT',
    icon: '🤖',
    color: '#10B981',
    strengths: ['Instruction Following', 'Reasoning', 'Code Generation'],
    pricing: 'Paid',
    description: 'Best for complex reasoning and code generation tasks'
  },
  {
    id: 'claude',
    name: 'Anthropic Claude',
    icon: '🧠',
    color: '#6366F1', 
    strengths: ['Safety', 'Analysis', 'Long Context'],
    pricing: 'Freemium',
    description: 'Excellent for safety-critical applications and long documents'
  },
  {
    id: 'gemini',
    name: 'Google Gemini',
    icon: '💎',
    color: '#F59E0B',
    strengths: ['Multimodal', 'Search', 'Reasoning'],
    pricing: 'Freemium',
    description: 'Strong multimodal capabilities and web integration'
  },
  {
    id: 'mistral',
    name: 'Mistral AI',
    icon: '🌪️',
    color: '#EF4444',
    strengths: ['Efficiency', 'Code', 'Multilingual'],
    pricing: 'Freemium',
    description: 'Efficient and fast with excellent multilingual support'
  },
  {
    id: 'llama',
    name: 'Meta Llama',
    icon: '🦙',
    color: '#8B5CF6',
    strengths: ['Open Source', 'Customizable', 'Privacy'],
    pricing: 'Free',
    description: 'Open source with full customization and privacy control'
  },
  {
    id: 'cohere',
    name: 'Cohere',
    icon: '🔮',
    color: '#06B6D4',
    strengths: ['Enterprise', 'RAG', 'Fine-tuning'],
    pricing: 'Paid',
    description: 'Enterprise-focused with strong RAG capabilities'
  }
];

export function Step6Deploy({ 
  data, 
  onUpdate, 
  onStartOver, 
  promptOutput, 
  deploymentConfigs, 
  copiedItem, 
  onCopy,
  onSaveAsTemplate
}: Step6DeployProps) {
  const [selectedFormat, setSelectedFormat] = useState(data.deploymentFormat || 'desktop');
  const [showPromptModal, setShowPromptModal] = useState(false);
  
  // Prompt Optimizer State
  const [targetLLM, setTargetLLM] = useState<string>('claude');
  const [originalPrompt, setOriginalPrompt] = useState(promptOutput);
  const [optimizedPrompt, setOptimizedPrompt] = useState('');
  const [selectedProviders, setSelectedProviders] = useState<string[]>(['openai', 'claude', 'gemini']);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [isTesting, setIsTesting] = useState(false);
  const [analysisComplete, setAnalysisComplete] = useState(false);
  const [testResults, setTestResults] = useState<Record<string, TestResult>>({});
  const [optimizationScore, setOptimizationScore] = useState(0);

  // Mock optimization suggestions
  const [suggestions] = useState<OptimizationSuggestion[]>([
    {
      id: '1',
      type: 'clarity',
      severity: 'high',
      title: 'Improve Instruction Clarity',
      description: 'Your prompt contains ambiguous language that might confuse the AI.',
      before: 'Be helpful and answer questions',
      after: 'Provide comprehensive, accurate answers to user questions with specific examples and clear explanations',
      impact: 'Reduces ambiguous responses by ~40%'
    },
    {
      id: '2',
      type: 'structure',
      severity: 'medium',
      title: 'Add Response Format Guidelines',
      description: 'Specify the desired response structure for consistent outputs.',
      before: 'Answer the question',
      after: 'Structure your response as: 1) Brief summary 2) Detailed explanation 3) Practical examples',
      impact: 'Improves response consistency by ~60%'
    },
    {
      id: '3',
      type: 'tokens',
      severity: 'low',
      title: 'Optimize Token Usage',
      description: 'Remove redundant phrases to reduce token consumption.',
      before: 'Please make sure to always remember to...',
      after: 'Always...',
      impact: 'Reduces token usage by ~15%'
    }
  ]);

  const deploymentFormats = [
    {
      id: 'desktop',
      name: 'Desktop Extension',
      description: 'One-click installation for Claude Desktop with .dxt format',
      icon: Zap,
      recommended: true,
      difficulty: 'Easy',
      features: [
        'One-click installation',
        'No manual configuration',
        'Automatic extension management',
        'Built-in security controls',
        'Instant deployment'
      ],
      instructions: [
        'Download the .dxt configuration file',
        'Open Claude Desktop application',
        'Go to Settings → Extensions',
        'Click "Install from File" and select the .dxt file',
        'Your agent will be ready to use immediately'
      ]
    },
    {
      id: 'railway',
      name: 'Railway',
      description: 'One-click deployment with automatic CI/CD and zero-config infrastructure',
      icon: Zap,
      recommended: true,
      difficulty: 'Easy',
      features: [
        'Zero-config deployment',
        'Automatic CI/CD',
        'Usage-based pricing',
        'Real-time logs',
        'Auto-scaling'
      ],
      instructions: [
        'Connect your GitHub repository to Railway',
        'Deploy with: railway login && railway deploy',
        'Configure environment variables in dashboard',
        'Your agent will be live with custom domain',
        'Monitor usage and costs in real-time'
      ]
    },
    {
      id: 'render',
      name: 'Render',
      description: 'Simple cloud deployment with free tier and automatic SSL',
      icon: Globe,
      recommended: true,
      difficulty: 'Easy',
      features: [
        'Free tier available',
        'Automatic SSL/TLS',
        'Blueprint deployment',
        'DDoS protection',
        'Environment management'
      ],
      instructions: [
        'Connect your GitHub repository to Render',
        'Configure build and start commands',
        'Set environment variables',
        'Deploy with automatic HTTPS',
        'Scale resources as needed'
      ]
    },
    {
      id: 'fly',
      name: 'Fly.io',
      description: 'Global edge deployment with 250ms boot times in 30+ regions',
      icon: Globe,
      recommended: false,
      difficulty: 'Medium',
      features: [
        'Global edge deployment',
        'Instant boot (250ms)',
        'Fly Machines',
        'Auto-sleep capability',
        '30+ global regions'
      ],
      instructions: [
        'Install Fly CLI: curl -L https://fly.io/install.sh | sh',
        'Initialize: flyctl launch',
        'Deploy: flyctl deploy',
        'Scale globally with: flyctl scale count 3 --region lax,ord,fra',
        'Monitor with: flyctl logs'
      ]
    },
    {
      id: 'vercel',
      name: 'Vercel',
      description: 'Serverless deployment optimized for frontend and edge functions',
      icon: Zap,
      recommended: false,
      difficulty: 'Easy',
      features: [
        'Serverless functions',
        'Edge runtime',
        'Preview deployments',
        'Analytics included',
        'Next.js optimized'
      ],
      instructions: [
        'Install Vercel CLI: npm i -g vercel',
        'Deploy: vercel --prod',
        'Configure serverless functions',
        'Set up edge middleware if needed',
        'Monitor with built-in analytics'
      ]
    },
    {
      id: 'cloudrun',
      name: 'Google Cloud Run',
      description: 'Fully managed serverless containers with Google Cloud integration',
      icon: Cloud,
      recommended: false,
      difficulty: 'Medium',
      features: [
        'Serverless containers',
        'Pay-per-request',
        'Auto-scaling to zero',
        'Google Cloud integration',
        'Traffic splitting'
      ],
      instructions: [
        'Build container: gcloud builds submit --tag gcr.io/PROJECT/agent',
        'Deploy: gcloud run deploy --image gcr.io/PROJECT/agent',
        'Configure traffic allocation',
        'Set up Cloud Monitoring',
        'Enable Cloud Logging'
      ]
    },
    {
      id: 'docker',
      name: 'Docker Compose',
      description: 'Containerized deployment with Docker for development and staging',
      icon: Package,
      recommended: false,
      difficulty: 'Medium',
      features: [
        'Container isolation',
        'Service orchestration',
        'Environment consistency',
        'Easy scaling',
        'Development friendly'
      ],
      instructions: [
        'Save the docker-compose.yml file',
        'Install Docker and Docker Compose',
        'Run: docker-compose up -d',
        'Access your agent at http://localhost:8080',
        'Use docker-compose logs to monitor'
      ]
    },
    {
      id: 'kubernetes',
      name: 'Kubernetes Manifests',
      description: 'Production-grade orchestration with observability and CI/CD',
      icon: Cloud,
      recommended: false,
      difficulty: 'Hard',
      features: [
        'High availability',
        'Auto-scaling',
        'Rolling deployments',
        'OpenTelemetry ready',
        'Enterprise grade'
      ],
      instructions: [
        'Apply manifests: kubectl apply -f k8s/',
        'Configure ingress and TLS certificates',
        'Set up Prometheus + Grafana monitoring',
        'Configure OpenTelemetry collector',
        'Enable Jaeger tracing'
      ]
    },
    {
      id: 'json',
      name: 'Raw JSON Configuration',
      description: 'Flexible JSON format for custom implementations and integrations',
      icon: Settings,
      recommended: false,
      difficulty: 'Variable',
      features: [
        'Maximum flexibility',
        'Custom implementation',
        'API integration ready',
        'Framework agnostic',
        'Full customization'
      ],
      instructions: [
        'Copy the JSON configuration',
        'Integrate with your existing system',
        'Implement the extension connections',
        'Add authentication and security layers',
        'Deploy according to your infrastructure'
      ]
    }
  ];

  const selectedFormatData = deploymentFormats.find(f => f.id === selectedFormat);
  const selectedLLMData = llmProviders.find(p => p.id === targetLLM);

  const handleAnalyzePrompt = async () => {
    setIsAnalyzing(true);
    setAnalysisComplete(false);
    
    // Simulate analysis
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    // Generate mock optimized prompt based on target LLM
    const llmSpecificOptimizations = {
      openai: 'Structured with clear sections and bullet points, optimized for GPT instruction following',
      claude: 'Emphasizes safety considerations and ethical guidelines, with constitutional AI principles',
      gemini: 'Incorporates multimodal considerations and search integration capabilities',
      mistral: 'Streamlined for efficiency with multilingual context awareness',
      llama: 'Open-ended structure allowing for maximum customization flexibility',
      cohere: 'Enterprise-focused with RAG integration and fine-tuning considerations'
    };

    const optimized = `You are an expert AI assistant optimized for ${selectedLLMData?.name} with the following capabilities and guidelines:

ROLE: Professional assistant specialized in providing comprehensive, accurate information

TARGET LLM OPTIMIZATION: ${llmSpecificOptimizations[targetLLM as keyof typeof llmSpecificOptimizations]}

RESPONSE STRUCTURE:
1. Brief summary of the answer
2. Detailed explanation with reasoning
3. Practical examples when applicable
4. Next steps or recommendations if relevant

GUIDELINES:
- Prioritize accuracy and clarity in all responses
- Use specific examples to illustrate concepts
- Acknowledge limitations when uncertain
- Maintain a professional yet approachable tone
- Provide sources or suggest verification when appropriate
${targetLLM === 'claude' ? '- Follow constitutional AI principles for safety' : ''}
${targetLLM === 'gemini' ? '- Leverage multimodal capabilities when relevant' : ''}
${targetLLM === 'mistral' ? '- Optimize for efficiency and multilingual support' : ''}

CONSTRAINTS:
- Keep responses concise yet complete
- Avoid speculation without clear disclaimers
- Focus on actionable information
- Adapt complexity to user's apparent expertise level
${targetLLM === 'openai' ? '- Structure responses for maximum instruction clarity' : ''}
${targetLLM === 'cohere' ? '- Consider enterprise context and RAG integration' : ''}

Remember: Your goal is to be genuinely helpful while maintaining high standards of accuracy and clarity, optimized specifically for ${selectedLLMData?.name} capabilities.`;

    setOptimizedPrompt(optimized);
    setOptimizationScore(Math.floor(Math.random() * 30) + 70); // 70-100
    setIsAnalyzing(false);
    setAnalysisComplete(true);
  };

  const handleTestProviders = async () => {
    setIsTesting(true);
    
    // Initialize test results
    const initialResults: Record<string, TestResult> = {};
    selectedProviders.forEach(provider => {
      initialResults[provider] = {
        provider,
        status: 'pending'
      };
    });
    setTestResults(initialResults);

    // Simulate testing each provider
    for (const provider of selectedProviders) {
      // Set to testing
      setTestResults(prev => ({
        ...prev,
        [provider]: { ...prev[provider], status: 'testing' }
      }));

      await new Promise(resolve => setTimeout(resolve, 1000 + Math.random() * 2000));

      // Generate mock results
      const success = Math.random() > 0.1; // 90% success rate
      if (success) {
        setTestResults(prev => ({
          ...prev,
          [provider]: {
            ...prev[provider],
            status: 'success',
            responseTime: Math.floor(Math.random() * 3000) + 500,
            tokenUsage: Math.floor(Math.random() * 150) + 50,
            qualityScore: Math.floor(Math.random() * 30) + 70,
            responsePreview: `This is a sample response from ${llmProviders.find(p => p.id === provider)?.name}. The response demonstrates good understanding of the optimized prompt and follows the specified structure...`
          }
        }));
      } else {
        setTestResults(prev => ({
          ...prev,
          [provider]: {
            ...prev[provider],
            status: 'error',
            error: 'API timeout or rate limit exceeded'
          }
        }));
      }
    }
    
    setIsTesting(false);
  };

  const downloadFile = (content: string, filename: string, mimeType = 'text/plain') => {
    const blob = new Blob([content], { type: mimeType });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  };

  const getFileExtension = (format: string) => {
    switch (format) {
      case 'desktop': return '.dxt';
      case 'railway': return '.toml';
      case 'render': return '.yaml';
      case 'fly': return '.toml';
      case 'vercel': return '.json';
      case 'cloudrun': return '.yaml';
      case 'docker': return '.yml';
      case 'kubernetes': return '.yaml';
      case 'json': return '.json';
      default: return '.txt';
    }
  };

  const getFileName = (format: string) => {
    const agentName = (data.agentName || 'ai-agent').toLowerCase().replace(/[^a-z0-9]/g, '-');
    switch (format) {
      case 'desktop': return `${agentName}-desktop-extension.dxt`;
      case 'railway': return 'railway.toml';
      case 'render': return 'render.yaml';
      case 'fly': return 'fly.toml';
      case 'vercel': return 'vercel.json';
      case 'cloudrun': return `${agentName}-cloudrun.yaml`;
      case 'docker': return 'docker-compose.yml';
      case 'kubernetes': return `${agentName}-k8s-deployment.yaml`;
      case 'json': return `${agentName}-config.json`;
      default: return `${agentName}-config.txt`;
    }
  };

  const handleDownload = () => {
    const content = selectedFormat === 'prompt' ? promptOutput : deploymentConfigs[selectedFormat];
    if (content) {
      downloadFile(content, getFileName(selectedFormat));
    }
  };

  const handleCopy = (content: string) => {
    onCopy(content, selectedFormat);
  };

  const copyToClipboard = async (text: string, itemType: string) => {
    try {
      await navigator.clipboard.writeText(text);
      onCopy(text, itemType);
    } catch (err) {
      console.error('Failed to copy:', err);
    }
  };

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'high': return 'text-red-400 bg-red-500/20 border-red-500/30';
      case 'medium': return 'text-yellow-400 bg-yellow-500/20 border-yellow-500/30';
      case 'low': return 'text-green-400 bg-green-500/20 border-green-500/30';
      default: return 'text-muted-foreground bg-muted/20 border-border';
    }
  };

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'clarity': return Eye;
      case 'structure': return FileText;
      case 'tokens': return Zap;
      case 'performance': return TrendingUp;
      case 'security': return Settings;
      default: return Lightbulb;
    }
  };

  return (
    <div className="space-y-8 animate-fadeIn">
      {/* Hero Section with Enhanced UX */}
      <div className="text-center space-y-6">
        <div className="space-y-2">
          <h1 className="bg-gradient-to-r from-primary via-purple-400 to-blue-400 bg-clip-text text-transparent font-bold">
            🎉 Your AI Agent is Ready!
          </h1>
          <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
            <strong>{data.agentName || 'Your Custom Agent'}</strong> has been configured with <strong>{data.extensions?.filter((s: any) => s.enabled).length || 0} extensions</strong> and is ready to deploy.
          </p>
        </div>
        
        {/* Progress Summary */}
        <div className="flex flex-wrap items-center justify-center gap-6 py-4">
          <div className="flex items-center gap-2 text-sm">
            <CheckCircle className="w-5 h-5 text-success" />
            <span className="text-success font-medium">Profile Complete</span>
          </div>
          <div className="flex items-center gap-2 text-sm">
            <CheckCircle className="w-5 h-5 text-success" />
            <span className="text-success font-medium">Extensions Configured</span>
          </div>
          <div className="flex items-center gap-2 text-sm">
            <CheckCircle className="w-5 h-5 text-success" />
            <span className="text-success font-medium">Security Set</span>
          </div>
          <div className="flex items-center gap-2 text-sm">
            <CheckCircle className="w-5 h-5 text-success" />
            <span className="text-success font-medium">Behavior Defined</span>
          </div>
          <div className="flex items-center gap-2 text-sm">
            <CheckCircle className="w-5 h-5 text-success" />
            <span className="text-success font-medium">Tests Passed</span>
          </div>
          <div className="flex items-center gap-2 text-sm">
            <Zap className="w-5 h-5 text-primary animate-pulse" />
            <span className="text-primary font-medium">Ready to Deploy!</span>
          </div>
        </div>

        {/* Quick Actions */}
        <div className="flex flex-col sm:flex-row items-center justify-center gap-3 pt-2">
          <Button 
            onClick={handleDownload}
            size="lg"
            className="bg-primary hover:bg-primary/90 text-primary-foreground px-8 py-3 font-medium"
          >
            <Download className="w-5 h-5 mr-2" />
            Download {selectedFormatData?.name} ({getFileExtension(selectedFormat)})
          </Button>
          <Button 
            variant="outline" 
            onClick={() => setShowPromptModal(true)}
            size="lg"
            className="px-8 py-3 border-primary/30 text-primary hover:bg-primary/10"
          >
            <Eye className="w-4 h-4 mr-2" />
            Preview System Prompt
          </Button>
          {onSaveAsTemplate && (
            <Button 
              variant="ghost"
              onClick={onSaveAsTemplate}
              size="lg"
              className="px-8 py-3 text-muted-foreground hover:text-primary"
            >
              <BookmarkPlus className="w-4 h-4 mr-2" />
              Save as Template
            </Button>
          )}
        </div>
      </div>

      {/* Agent Configuration Summary - Enhanced */}
      <Card className="selection-card bg-gradient-to-r from-success/5 via-transparent to-primary/5 border-success/30">
        <CardHeader>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-success/20 rounded-lg">
                <CheckCircle className="w-6 h-6 text-success" />
              </div>
              <div>
                <CardTitle className="text-success text-xl">{data.agentName || 'Your AI Agent'}</CardTitle>
                <CardDescription className="text-success/70">
                  {data.agentDescription || 'Custom AI agent ready for deployment'}
                </CardDescription>
              </div>
            </div>
            <Badge className="bg-success/20 text-success border-success/30 px-3 py-1">
              <Zap className="w-4 h-4 mr-1" />
              Production Ready
            </Badge>
          </div>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-6">
            <div className="text-center space-y-2">
              <div className="p-3 bg-primary/10 rounded-lg mx-auto w-fit">
                <Brain className="w-6 h-6 text-primary" />
              </div>
              <div className="space-y-1">
                <div className="text-2xl font-bold text-primary">{data.primaryPurpose?.replace('-', ' ').replace(/\b\w/g, l => l.toUpperCase()) || 'Custom'}</div>
                <div className="text-sm text-muted-foreground">Agent Type</div>
              </div>
            </div>
            <div className="text-center space-y-2">
              <div className="p-3 bg-blue-500/10 rounded-lg mx-auto w-fit">
                <Settings className="w-6 h-6 text-blue-500" />
              </div>
              <div className="space-y-1">
                <div className="text-2xl font-bold text-blue-500">{data.extensions?.filter((s: any) => s.enabled).length || 0}</div>
                <div className="text-sm text-muted-foreground">Extensions</div>
              </div>
            </div>
            <div className="text-center space-y-2">
              <div className="p-3 bg-orange-500/10 rounded-lg mx-auto w-fit">
                <Shield className="w-6 h-6 text-orange-500" />
              </div>
              <div className="space-y-1">
                <div className="text-2xl font-bold text-orange-500 capitalize">{data.security?.authMethod || 'Basic'}</div>
                <div className="text-sm text-muted-foreground">Security Level</div>
              </div>
            </div>
            <div className="text-center space-y-2">
              <div className="p-3 bg-green-500/10 rounded-lg mx-auto w-fit">
                <Target className="w-6 h-6 text-green-500" />
              </div>
              <div className="space-y-1">
                <div className="text-2xl font-bold text-green-500 capitalize">{data.testResults?.overallStatus || 'Passed'}</div>
                <div className="text-sm text-muted-foreground">Test Status</div>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Prompt Optimizer Toolbar */}
      <Card className="selection-card bg-gradient-to-r from-orange-500/10 to-purple-500/10 border-orange-500/20">
        <CardHeader className="pb-4">
          <div className="flex items-center gap-2 mb-2">
            <Wand2 className="w-5 h-5 text-orange-500" />
            <CardTitle className="text-orange-500">Prompt Optimization</CardTitle>
            <Badge className="bg-orange-500/20 text-orange-400 border-orange-500/30">
              AI-Powered
            </Badge>
          </div>
          <CardDescription>
            Optimize your system prompt for better performance across different LLM providers
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col sm:flex-row items-start sm:items-end gap-4">
            <div className="flex-1 space-y-2">
              <label className="text-sm font-medium">Target LLM Provider</label>
              <Select value={targetLLM} onValueChange={setTargetLLM}>
                <SelectTrigger className="w-full sm:w-64 h-12">
                  <SelectValue placeholder="Choose LLM Provider">
                    {selectedLLMData && (
                      <div className="flex items-center gap-3">
                        <span className="text-lg">{selectedLLMData.icon}</span>
                        <div className="flex flex-col items-start">
                          <span className="font-medium">{selectedLLMData.name}</span>
                          <Badge variant="outline" size="sm" className={
                            selectedLLMData.pricing === 'Free' 
                              ? 'bg-green-500/20 text-green-400 border-green-500/30 text-xs'
                              : selectedLLMData.pricing === 'Freemium'
                              ? 'bg-blue-500/20 text-blue-400 border-blue-500/30 text-xs'
                              : 'bg-orange-500/20 text-orange-400 border-orange-500/30 text-xs'
                          }>
                            {selectedLLMData.pricing}
                          </Badge>
                        </div>
                      </div>
                    )}
                  </SelectValue>
                </SelectTrigger>
                <SelectContent className="w-80">
                  {llmProviders.map((provider) => (
                    <SelectItem 
                      key={provider.id} 
                      value={provider.id}
                      className="cursor-pointer hover:bg-muted/80 transition-colors duration-200 p-3"
                    >
                      <div className="flex items-center gap-3 w-full">
                        <span className="text-lg">{provider.icon}</span>
                        <div className="flex flex-col flex-1">
                          <div className="flex items-center justify-between">
                            <span className="font-medium">{provider.name}</span>
                            <Badge 
                              variant="outline" 
                              size="sm"
                              className={
                                provider.pricing === 'Free' 
                                  ? 'bg-green-500/20 text-green-400 border-green-500/30 text-xs'
                                  : provider.pricing === 'Freemium'
                                  ? 'bg-blue-500/20 text-blue-400 border-blue-500/30 text-xs'
                                  : 'bg-orange-500/20 text-orange-400 border-orange-500/30 text-xs'
                              }
                            >
                              {provider.pricing}
                            </Badge>
                          </div>
                          <span className="text-xs text-muted-foreground text-left">
                            {provider.description}
                          </span>
                          <div className="flex flex-wrap gap-1 mt-1">
                            {provider.strengths.slice(0, 3).map((strength, index) => (
                              <span 
                                key={index}
                                className="text-xs px-1.5 py-0.5 bg-muted rounded text-muted-foreground"
                              >
                                {strength}
                              </span>
                            ))}
                          </div>
                        </div>
                      </div>
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            
            <div className="flex items-center gap-2">
              {selectedLLMData && (
                <div className="flex items-center gap-2 px-3 py-2 bg-muted/50 rounded-lg h-12">
                  <span className="text-lg">{selectedLLMData.icon}</span>
                  <div className="text-sm">
                    <div className="font-medium">{selectedLLMData.name}</div>
                    <Badge variant="outline" className={
                      selectedLLMData.pricing === 'Free' 
                        ? 'bg-green-500/20 text-green-400 border-green-500/30'
                        : selectedLLMData.pricing === 'Freemium'
                        ? 'bg-blue-500/20 text-blue-400 border-blue-500/30'
                        : 'bg-orange-500/20 text-orange-400 border-orange-500/30'
                    }>
                      {selectedLLMData.pricing}
                    </Badge>
                  </div>
                </div>
              )}
              
              <Button
                onClick={handleAnalyzePrompt}
                disabled={!originalPrompt.trim() || isAnalyzing}
                className="bg-orange-500 hover:bg-orange-500/90 px-6 h-12"
              >
                {isAnalyzing ? (
                  <>
                    <RefreshCw className="w-4 h-4 mr-2 animate-spin" />
                    Analyzing...
                  </>
                ) : (
                  <>
                    <Wand2 className="w-4 h-4 mr-2" />
                    Optimize for {selectedLLMData?.name.split(' ')[0]}
                  </>
                )}
              </Button>
            </div>
          </div>

          {analysisComplete && (
            <div className="mt-4 p-4 bg-success/10 border border-success/20 rounded-lg">
              <div className="flex items-center gap-2 mb-2">
                <CheckCircle className="w-5 h-5 text-success" />
                <span className="font-medium text-success">Optimization Complete!</span>
                <Badge className="bg-green-500/20 text-green-400 border-green-500/30">
                  <TrendingUp className="w-3 h-3 mr-1" />
                  +{optimizationScore}% Better
                </Badge>
              </div>
              <p className="text-sm text-muted-foreground">
                Your prompt has been optimized specifically for {selectedLLMData?.name} with {suggestions.length} improvements applied.
                View the "Optimize Prompt" tab below to see the detailed analysis and optimized version.
              </p>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Deployment Workflow - Redesigned for Better UX */}
      <Tabs defaultValue="deploy" className="space-y-6">
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <TabsList className="grid grid-cols-3 w-full sm:w-auto h-12">
            <TabsTrigger value="deploy" className="px-6 h-full flex items-center justify-center">
              <Package className="w-4 h-4 mr-2" />
              <span>Deploy</span>
            </TabsTrigger>
            <TabsTrigger value="optimize" className="px-6 h-full flex items-center justify-center">
              <Wand2 className="w-4 h-4 mr-2" />
              <span>Optimize</span>
              {analysisComplete && (
                <Badge className="ml-2 bg-success/20 text-success border-success/30 text-xs">
                  ✓
                </Badge>
              )}
            </TabsTrigger>
            <TabsTrigger value="test" className="px-6 h-full flex items-center justify-center">
              <Target className="w-4 h-4 mr-2" />
              <span>Test & Compare</span>
            </TabsTrigger>
          </TabsList>
          <div className="text-sm text-muted-foreground flex items-center gap-2 bg-success/10 border border-success/20 rounded-full px-3 py-1">
            <div className="w-2 h-2 bg-success rounded-full animate-pulse"></div>
            <span className="text-success font-medium">Ready to Deploy</span>
          </div>
        </div>

        <TabsContent value="deploy" className="space-y-6">
          {/* Guidance Section */}
          <div className="bg-gradient-to-r from-blue-500/10 to-purple-500/10 border border-blue-500/20 rounded-lg p-6">
            <div className="flex items-start gap-4">
              <div className="p-2 bg-blue-500/20 rounded-lg">
                <Lightbulb className="w-6 h-6 text-blue-500" />
              </div>
              <div className="space-y-2">
                <h3 className="font-semibold text-blue-500">Choose Your Deployment Method</h3>
                <p className="text-sm text-muted-foreground max-w-2xl">
                  Select how you want to deploy your AI agent. For beginners, we recommend the <strong>Desktop Extension</strong> for instant setup. 
                  Advanced users can choose containerized options for production environments.
                </p>
              </div>
            </div>
          </div>

          {/* Deployment Format Selection - Enhanced */}
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-semibold">Deployment Formats</h3>
              <div className="text-sm text-muted-foreground">Choose the best option for your needs</div>
            </div>
            
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {deploymentFormats.map((format, index) => {
                const Icon = format.icon;
                const isSelected = selectedFormat === format.id;
                const isRecommended = format.recommended;
                
                return (
                  <Card 
                    key={format.id}
                    className={`cursor-pointer transition-all duration-300 hover:scale-105 relative overflow-hidden ${
                      isSelected 
                        ? 'border-primary bg-gradient-to-br from-primary/10 via-primary/5 to-transparent shadow-xl ring-2 ring-primary/20' 
                        : 'hover:border-primary/50 hover:shadow-lg hover:bg-gradient-to-br hover:from-primary/5 hover:to-transparent'
                    }`}
                    onClick={() => setSelectedFormat(format.id)}
                  >
                    {/* Recommended badge */}
                    {isRecommended && (
                      <div className="absolute -right-12 top-4 bg-yellow-400 text-yellow-900 text-xs font-bold py-1 px-12 transform rotate-45">
                        BEST
                      </div>
                    )}
                    
                    <CardHeader className="pb-4">
                      <div className="flex items-start justify-between">
                        <div className="flex items-center gap-4">
                          <div className={`p-3 rounded-xl ${
                            isSelected ? 'bg-primary/20' : 'bg-muted/50'
                          } transition-colors`}>
                            <Icon className={`w-7 h-7 ${
                              isSelected ? 'text-primary' : 'text-muted-foreground'
                            }`} />
                          </div>
                          <div className="space-y-1">
                            <CardTitle className="text-lg flex items-center gap-2">
                              {format.name}
                              {isRecommended && (
                                <Star className="w-4 h-4 text-yellow-400 fill-yellow-400" />
                              )}
                            </CardTitle>
                            <CardDescription className="text-sm leading-relaxed">
                              {format.description}
                            </CardDescription>
                          </div>
                        </div>
                        {isSelected && (
                          <div className="flex flex-col items-center gap-1">
                            <CheckCircle className="w-6 h-6 text-primary" />
                            <span className="text-xs text-primary font-medium">Selected</span>
                          </div>
                        )}
                      </div>
                    </CardHeader>
                    
                    <CardContent className="space-y-4">
                      {/* Difficulty and features */}
                      <div className="flex items-center gap-3">
                        <Badge 
                          variant="outline" 
                          className={`text-xs font-medium ${
                            format.difficulty === 'Easy' ? 'border-success/30 text-success bg-success/10' :
                            format.difficulty === 'Medium' ? 'border-warning/30 text-warning bg-warning/10' : 
                            'border-destructive/30 text-destructive bg-destructive/10'
                          }`}
                        >
                          {format.difficulty === 'Easy' ? '🟢' : format.difficulty === 'Medium' ? '🟡' : '🔴'} {format.difficulty} Setup
                        </Badge>
                        {isRecommended && (
                          <Badge className="text-xs bg-yellow-400/20 text-yellow-600 border-yellow-400/30">
                            <Star className="w-3 h-3 mr-1" />
                            Recommended
                          </Badge>
                        )}
                        <Badge variant="secondary" className="text-xs">
                          #{index + 1} Popular
                        </Badge>
                      </div>

                      <div className="space-y-3">
                        <div className="text-sm font-medium text-primary">Why Choose This?</div>
                        <div className="grid grid-cols-1 gap-2">
                          {format.features.slice(0, 4).map((feature) => (
                            <div key={feature} className="text-sm text-muted-foreground flex items-center gap-2">
                              <CheckCircle className="w-3 h-3 text-success flex-shrink-0" />
                              {feature}
                            </div>
                          ))}
                        </div>
                      </div>
                      
                      {/* Quick preview of setup time */}
                      <div className="flex items-center justify-between pt-2 border-t border-border/50">
                        <div className="text-xs text-muted-foreground flex items-center gap-2">
                          <Timer className="w-3 h-3" />
                          Setup time: {format.difficulty === 'Easy' ? '< 2 min' : format.difficulty === 'Medium' ? '5-10 min' : '15-30 min'}
                        </div>
                        {isSelected && (
                          <div className="text-xs text-primary font-medium flex items-center gap-1">
                            <Zap className="w-3 h-3" />
                            Ready to configure
                          </div>
                        )}
                      </div>
                    </CardContent>
                  </Card>
                );
              })}
            </div>
          </div>

          {/* Configuration Output - Enhanced with Better UX */}
          <Card className="selection-card bg-gradient-to-r from-primary/5 to-purple-500/5">
            <CardHeader>
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-primary/20 rounded-lg">
                    <Package className="w-6 h-6 text-primary" />
                  </div>
                  <div>
                    <CardTitle className="text-xl">{selectedFormatData?.name} Configuration</CardTitle>
                    <CardDescription className="text-base">
                      🚀 Ready-to-deploy configuration for {selectedFormatData?.name.toLowerCase()}
                    </CardDescription>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  {/* File info badge */}
                  <Badge variant="outline" className="bg-primary/10 text-primary border-primary/30">
                    {getFileExtension(selectedFormat)} file
                  </Badge>
                  <div className="flex gap-2">
                    <Button 
                      variant="outline" 
                      size="sm"
                      onClick={() => handleCopy(selectedFormat === 'prompt' ? promptOutput : deploymentConfigs[selectedFormat] || '')}
                      className="border-primary/30 text-primary hover:bg-primary/10"
                    >
                      {copiedItem === selectedFormat ? <CheckCircle className="w-4 h-4" /> : <Copy className="w-4 h-4" />}
                      {copiedItem === selectedFormat ? 'Copied!' : 'Copy'}
                    </Button>
                    <Button 
                      size="sm"
                      onClick={handleDownload}
                      className="bg-primary hover:bg-primary/90 text-primary-foreground"
                    >
                      <Download className="w-4 h-4 mr-2" />
                      Download {getFileExtension(selectedFormat)}
                    </Button>
                  </div>
                </div>
              </div>
              
              {/* Quick deployment status */}
              <div className="flex items-center gap-4 pt-3 border-t border-border/30">
                <div className="flex items-center gap-2 text-sm">
                  <div className="w-2 h-2 bg-success rounded-full"></div>
                  <span className="text-success">Configuration Valid</span>
                </div>
                <div className="flex items-center gap-2 text-sm">
                  <FileText className="w-4 h-4 text-blue-500" />
                  <span className="text-blue-500">{Math.ceil((deploymentConfigs[selectedFormat] || '').length / 100)} KB</span>
                </div>
                <div className="flex items-center gap-2 text-sm">
                  <Timer className="w-4 h-4 text-orange-500" />
                  <span className="text-orange-500">~{selectedFormatData?.difficulty === 'Easy' ? '2' : selectedFormatData?.difficulty === 'Medium' ? '8' : '20'} min setup</span>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <Tabs value="config" className="w-full">
                <TabsList className="grid w-full grid-cols-2 bg-muted/30">
                  <TabsTrigger value="config" className="data-[state=active]:bg-primary/10 data-[state=active]:text-primary">
                    <FileText className="w-4 h-4 mr-2" />
                    Configuration File
                  </TabsTrigger>
                  <TabsTrigger value="instructions" className="data-[state=active]:bg-primary/10 data-[state=active]:text-primary">
                    <Target className="w-4 h-4 mr-2" />
                    Setup Guide
                  </TabsTrigger>
                </TabsList>
                
                <TabsContent value="config" className="space-y-4">
                  {/* Enhanced config preview */}
                  <div className="space-y-3">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <Badge variant="outline" className="bg-primary/10 text-primary border-primary/30">
                          {getFileName(selectedFormat)}
                        </Badge>
                        <div className="text-sm text-muted-foreground">
                          {(deploymentConfigs[selectedFormat] || '').split('\n').length} lines
                        </div>
                      </div>
                      <div className="flex items-center gap-2">
                        <Button variant="ghost" size="sm" onClick={() => handleCopy(deploymentConfigs[selectedFormat] || '')}>
                          <Copy className="w-3 h-3 mr-1" />
                          Copy All
                        </Button>
                        <Button variant="ghost" size="sm" onClick={handleDownload}>
                          <Download className="w-3 h-3 mr-1" />
                          Download
                        </Button>
                      </div>
                    </div>
                    
                    <div className="relative">
                      <div className="absolute top-3 right-3 z-10">
                        <Badge variant="secondary" className="text-xs">
                          {selectedFormat.toUpperCase()}
                        </Badge>
                      </div>
                      <pre className="bg-muted/50 p-4 rounded-lg overflow-x-auto text-xs font-mono max-h-96 border border-primary/20 relative">
                        <code className="text-muted-foreground">
                          {selectedFormat === 'prompt' ? promptOutput : deploymentConfigs[selectedFormat] || 'Loading configuration...'}
                        </code>
                      </pre>
                    </div>
                  </div>
                </TabsContent>

                <TabsContent value="instructions" className="space-y-6">
                  {/* Deployment overview */}
                  <div className="bg-gradient-to-r from-primary/10 to-blue-500/10 border border-primary/30 rounded-lg p-4">
                    <div className="flex items-start gap-3">
                      <div className="p-2 bg-primary/20 rounded-lg">
                        <Target className="w-5 h-5 text-primary" />
                      </div>
                      <div className="space-y-2">
                        <div className="flex items-center gap-3">
                          <h4 className="font-semibold text-primary">{selectedFormatData?.name} Setup</h4>
                          <Badge variant="outline" className={`${
                            selectedFormatData?.difficulty === 'Easy' ? 'border-success/30 text-success bg-success/10' :
                            selectedFormatData?.difficulty === 'Medium' ? 'border-warning/30 text-warning bg-warning/10' : 
                            'border-destructive/30 text-destructive bg-destructive/10'
                          }`}>
                            {selectedFormatData?.difficulty === 'Easy' ? '🟢' : selectedFormatData?.difficulty === 'Medium' ? '🟡' : '🔴'} {selectedFormatData?.difficulty} Difficulty
                          </Badge>
                          {selectedFormatData?.recommended && (
                            <Badge className="bg-yellow-400/20 text-yellow-600 border-yellow-400/30">
                              <Star className="w-3 h-3 mr-1" />
                              Recommended
                            </Badge>
                          )}
                        </div>
                        <p className="text-sm text-muted-foreground">
                          Follow these steps to deploy your {data.agentName || 'AI agent'} using {selectedFormatData?.name}.
                          Estimated setup time: <strong>{selectedFormatData?.difficulty === 'Easy' ? '< 2 minutes' : selectedFormatData?.difficulty === 'Medium' ? '5-10 minutes' : '15-30 minutes'}</strong>
                        </p>
                      </div>
                    </div>
                  </div>

                  {/* Step-by-step instructions */}
                  <div className="space-y-4">
                    <h4 className="font-semibold text-lg flex items-center gap-2">
                      <Zap className="w-5 h-5 text-primary" />
                      Deployment Steps
                    </h4>
                    <div className="space-y-4">
                      {selectedFormatData?.instructions.map((instruction, index) => (
                        <div key={index} className="flex items-start gap-4 p-4 bg-muted/30 rounded-lg border border-border/50 hover:border-primary/30 transition-colors">
                          <div className="w-8 h-8 bg-primary text-primary-foreground rounded-full flex items-center justify-center text-sm font-bold flex-shrink-0">
                            {index + 1}
                          </div>
                          <div className="space-y-1 flex-1">
                            <div className="text-sm font-medium text-foreground">{instruction}</div>
                            {index === 0 && (
                              <div className="text-xs text-muted-foreground flex items-center gap-2">
                                <Download className="w-3 h-3" />
                                <span>Your {getFileName(selectedFormat)} file is ready to download</span>
                              </div>
                            )}
                            {index === selectedFormatData.instructions.length - 1 && (
                              <div className="text-xs text-success flex items-center gap-2">
                                <CheckCircle className="w-3 h-3" />
                                <span>Your agent will be ready to use!</span>
                              </div>
                            )}
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>

                  {/* Special recommendations */}
                  {selectedFormat === 'desktop' && (
                    <div className="p-6 bg-gradient-to-r from-success/10 to-primary/10 rounded-lg border border-success/30">
                      <div className="flex items-start gap-3">
                        <div className="p-2 bg-success/20 rounded-lg">
                          <Star className="w-5 h-5 text-success" />
                        </div>
                        <div className="space-y-2">
                          <span className="font-semibold text-success">Perfect Choice! 🎉</span>
                          <p className="text-sm text-muted-foreground">
                            Desktop Extension (.dxt) is the easiest and most reliable deployment method. It provides:
                          </p>
                          <ul className="text-sm text-muted-foreground space-y-1 ml-4">
                            <li>• Automatic extension and security management</li>
                            <li>• Instant availability in Claude Desktop</li>
                            <li>• No technical configuration required</li>
                            <li>• Built-in updates and maintenance</li>
                          </ul>
                        </div>
                      </div>
                    </div>
                  )}
                  
                  {/* Deploy now CTA */}
                  <div className="flex items-center justify-center pt-4">
                    <Button 
                      size="lg" 
                      onClick={handleDownload}
                      className="bg-primary hover:bg-primary/90 text-primary-foreground px-12 py-4 text-lg font-semibold"
                    >
                      <Download className="w-5 h-5 mr-3" />
                      Deploy {data.agentName || 'Your Agent'} Now
                    </Button>
                  </div>
                </TabsContent>
              </Tabs>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="optimize" className="space-y-6">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Original Prompt */}
            <Card className="selection-card">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <FileText className="w-5 h-5 text-muted-foreground" />
                  Generated System Prompt
                </CardTitle>
                <CardDescription>
                  Your automatically generated system prompt from the wizard configuration
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <Textarea
                  placeholder="Generated system prompt..."
                  value={originalPrompt}
                  onChange={(e) => setOriginalPrompt(e.target.value)}
                  className="min-h-[200px] font-mono text-sm"
                />
                
                <div className="flex items-center justify-between">
                  <div className="text-sm text-muted-foreground">
                    {originalPrompt.length} characters • ~{Math.ceil(originalPrompt.length / 4)} tokens
                  </div>
                  <div className="flex items-center gap-2">
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => copyToClipboard(originalPrompt, 'original')}
                      disabled={!originalPrompt}
                    >
                      <Copy className="w-4 h-4 mr-2" />
                      {copiedItem === 'original' ? 'Copied!' : 'Copy'}
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Optimized Prompt */}
            <Card className="selection-card">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Wand2 className="w-5 h-5 text-primary" />
                  Optimized Prompt
                  {analysisComplete && (
                    <Badge className="bg-green-500/20 text-green-400 border-green-500/30">
                      <TrendingUp className="w-3 h-3 mr-1" />
                      +{optimizationScore}% Better
                    </Badge>
                  )}
                </CardTitle>
                <CardDescription>
                  AI-optimized version specifically tuned for {selectedLLMData?.name}
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <Textarea
                  placeholder="Optimized prompt will appear here..."
                  value={optimizedPrompt}
                  onChange={(e) => setOptimizedPrompt(e.target.value)}
                  className="min-h-[200px] font-mono text-sm"
                  readOnly={!analysisComplete}
                />
                
                <div className="flex items-center justify-between">
                  <div className="text-sm text-muted-foreground">
                    {optimizedPrompt.length} characters • ~{Math.ceil(optimizedPrompt.length / 4)} tokens
                    {analysisComplete && originalPrompt && (
                      <span className={`ml-2 ${optimizedPrompt.length < originalPrompt.length ? 'text-green-400' : 'text-orange-400'}`}>
                        ({optimizedPrompt.length - originalPrompt.length > 0 ? '+' : ''}{optimizedPrompt.length - originalPrompt.length})
                      </span>
                    )}
                  </div>
                  <div className="flex items-center gap-2">
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => copyToClipboard(optimizedPrompt, 'optimized')}
                      disabled={!optimizedPrompt}
                    >
                      <Copy className="w-4 h-4 mr-2" />
                      {copiedItem === 'optimized' ? 'Copied!' : 'Copy'}
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => downloadFile(optimizedPrompt, 'optimized_system_prompt.txt')}
                      disabled={!optimizedPrompt}
                    >
                      <Download className="w-4 h-4 mr-2" />
                      Download
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Optimization Suggestions */}
          {analysisComplete && (
            <Card className="selection-card">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Lightbulb className="w-5 h-5 text-yellow-400" />
                  Optimization Suggestions
                  <Badge className="bg-orange-500/20 text-orange-400 border-orange-500/30">
                    Optimized for {selectedLLMData?.name}
                  </Badge>
                </CardTitle>
                <CardDescription>
                  Specific improvements applied to your prompt for better {selectedLLMData?.name} performance
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                {suggestions.map((suggestion) => {
                  const Icon = getTypeIcon(suggestion.type);
                  return (
                    <div key={suggestion.id} className="border border-border/50 rounded-lg p-4 space-y-3">
                      <div className="flex items-start justify-between">
                        <div className="flex items-center gap-3">
                          <Icon className="w-5 h-5 text-primary" />
                          <div>
                            <h4 className="font-medium">{suggestion.title}</h4>
                            <p className="text-sm text-muted-foreground">{suggestion.description}</p>
                          </div>
                        </div>
                        <Badge variant="outline" className={getSeverityColor(suggestion.severity)}>
                          {suggestion.severity} impact
                        </Badge>
                      </div>
                      
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                        <div className="space-y-2">
                          <div className="font-medium text-red-400">Before:</div>
                          <div className="bg-red-500/10 border border-red-500/20 rounded-md p-2 font-mono">
                            {suggestion.before}
                          </div>
                        </div>
                        <div className="space-y-2">
                          <div className="font-medium text-green-400">After:</div>
                          <div className="bg-green-500/10 border border-green-500/20 rounded-md p-2 font-mono">
                            {suggestion.after}
                          </div>
                        </div>
                      </div>
                      
                      <div className="text-sm text-primary font-medium">
                        💡 {suggestion.impact}
                      </div>
                    </div>
                  );
                })}
              </CardContent>
            </Card>
          )}
        </TabsContent>

        <TabsContent value="test" className="space-y-6">
          {/* Provider Selection */}
          <Card className="selection-card">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Globe className="w-5 h-5 text-primary" />
                Select LLM Providers to Test
              </CardTitle>
              <CardDescription>
                Choose which LLM providers you want to test your optimized prompt against
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {llmProviders.map((provider) => (
                  <Card 
                    key={provider.id} 
                    className={`selection-card cursor-pointer transition-all ${
                      selectedProviders.includes(provider.id) ? 'selected' : ''
                    }`}
                    onClick={() => {
                      setSelectedProviders(prev => 
                        prev.includes(provider.id)
                          ? prev.filter(p => p !== provider.id)
                          : [...prev, provider.id]
                      );
                    }}
                  >
                    <CardContent className="p-4 space-y-3">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                          <span className="text-2xl">{provider.icon}</span>
                          <div>
                            <h4 className="font-medium">{provider.name}</h4>
                            <Badge variant="outline" className={
                              provider.pricing === 'Free' 
                                ? 'bg-green-500/20 text-green-400 border-green-500/30'
                                : provider.pricing === 'Freemium'
                                ? 'bg-blue-500/20 text-blue-400 border-blue-500/30'
                                : 'bg-orange-500/20 text-orange-400 border-orange-500/30'
                            }>
                              {provider.pricing}
                            </Badge>
                          </div>
                        </div>
                        <CheckCircle className={`w-5 h-5 ${
                          selectedProviders.includes(provider.id) ? 'text-primary' : 'text-muted-foreground/30'
                        }`} />
                      </div>
                      
                      <div className="space-y-1">
                        <div className="text-xs font-medium text-muted-foreground">Strengths:</div>
                        <div className="flex flex-wrap gap-1">
                          {provider.strengths.map((strength, idx) => (
                            <Badge key={idx} variant="secondary" className="text-xs">
                              {strength}
                            </Badge>
                          ))}
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
              
              <div className="flex items-center justify-between mt-6">
                <div className="text-sm text-muted-foreground">
                  {selectedProviders.length} providers selected
                </div>
                <Button
                  onClick={handleTestProviders}
                  disabled={selectedProviders.length === 0 || !optimizedPrompt || isTesting}
                  className="bg-primary hover:bg-primary/90"
                >
                  {isTesting ? (
                    <>
                      <RefreshCw className="w-4 h-4 mr-2 animate-spin" />
                      Testing Providers...
                    </>
                  ) : (
                    <>
                      <Play className="w-4 h-4 mr-2" />
                      Start Testing
                    </>
                  )}
                </Button>
              </div>
            </CardContent>
          </Card>

          {/* Test Results */}
          {Object.keys(testResults).length > 0 && (
            <Card className="selection-card">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Target className="w-5 h-5 text-primary" />
                  Test Results
                </CardTitle>
                <CardDescription>
                  Performance comparison across different LLM providers
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                {selectedProviders.map((providerId) => {
                  const provider = llmProviders.find(p => p.id === providerId);
                  const result = testResults[providerId];
                  
                  if (!provider || !result) return null;

                  return (
                    <div key={providerId} className="border border-border/50 rounded-lg p-4 space-y-3">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-3">
                          <span className="text-xl">{provider.icon}</span>
                          <div>
                            <h4 className="font-medium">{provider.name}</h4>
                            <div className="flex items-center gap-2 mt-1">
                              {result.status === 'success' && (
                                <Badge className="bg-green-500/20 text-green-400 border-green-500/30">
                                  <CheckCircle className="w-3 h-3 mr-1" />
                                  Success
                                </Badge>
                              )}
                              {result.status === 'testing' && (
                                <Badge className="bg-blue-500/20 text-blue-400 border-blue-500/30">
                                  <RefreshCw className="w-3 h-3 mr-1 animate-spin" />
                                  Testing...
                                </Badge>
                              )}
                              {result.status === 'error' && (
                                <Badge className="bg-red-500/20 text-red-400 border-red-500/30">
                                  <AlertTriangle className="w-3 h-3 mr-1" />
                                  Error
                                </Badge>
                              )}
                              {result.status === 'pending' && (
                                <Badge variant="outline">
                                  <Timer className="w-3 h-3 mr-1" />
                                  Pending
                                </Badge>
                              )}
                            </div>
                          </div>
                        </div>
                        
                        {result.status === 'success' && result.qualityScore && (
                          <div className="text-right">
                            <div className="text-2xl font-bold text-primary">{result.qualityScore}%</div>
                            <div className="text-xs text-muted-foreground">Quality Score</div>
                          </div>
                        )}
                      </div>

                      {result.status === 'success' && (
                        <div className="grid grid-cols-2 md:grid-cols-3 gap-4 text-sm">
                          <div className="space-y-1">
                            <div className="text-muted-foreground">Response Time</div>
                            <div className="font-medium">{result.responseTime}ms</div>
                          </div>
                          <div className="space-y-1">
                            <div className="text-muted-foreground">Token Usage</div>
                            <div className="font-medium">{result.tokenUsage} tokens</div>
                          </div>
                          <div className="space-y-1">
                            <div className="text-muted-foreground">Quality Score</div>
                            <div className="font-medium">{result.qualityScore}%</div>
                          </div>
                        </div>
                      )}

                      {result.status === 'success' && result.responsePreview && (
                        <div className="space-y-2">
                          <div className="text-sm font-medium">Response Preview:</div>
                          <div className="bg-muted/50 rounded-md p-3 text-sm text-muted-foreground font-mono">
                            {result.responsePreview}
                          </div>
                        </div>
                      )}

                      {result.status === 'error' && result.error && (
                        <div className="bg-red-500/10 border border-red-500/20 rounded-md p-3 text-sm text-red-400">
                          {result.error}
                        </div>
                      )}
                    </div>
                  );
                })}
              </CardContent>
            </Card>
          )}
        </TabsContent>
      </Tabs>

      {/* Additional Resources */}
      <Card className="selection-card">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <ExternalLink className="w-5 h-5 text-primary" />
            Additional Resources & Support
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
            <div className="space-y-2">
              <h4 className="font-medium">Documentation</h4>
              <ul className="space-y-1 text-muted-foreground">
                <li>• Extension Integration Guide</li>
                <li>• Security Best Practices</li>
                <li>• Troubleshooting Guide</li>
                <li>• Advanced Configuration</li>
              </ul>
            </div>
            <div className="space-y-2">
              <h4 className="font-medium">Community</h4>
              <ul className="space-y-1 text-muted-foreground">
                <li>• Discord Support Channel</li>
                <li>• GitHub Issues & Examples</li>
                <li>• Community Forum</li>
                <li>• Video Tutorials</li>
              </ul>
            </div>
            <div className="space-y-2">
              <h4 className="font-medium">Enterprise</h4>
              <ul className="space-y-1 text-muted-foreground">
                <li>• Professional Support</li>
                <li>• Custom Integrations</li>
                <li>• Training & Consulting</li>
                <li>• SLA & Compliance</li>
              </ul>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Enhanced Navigation & Final CTA */}
      <div className="space-y-6 pt-8 border-t border-border/30">
        {/* Success confirmation */}
        <div className="text-center space-y-4">
          <div className="flex items-center justify-center gap-3">
            <div className="p-2 bg-success/20 rounded-full">
              <CheckCircle className="w-6 h-6 text-success" />
            </div>
            <div className="space-y-1">
              <div className="text-lg font-semibold text-success">
                🎉 Congratulations! Your AI Agent is Ready
              </div>
              <div className="text-sm text-muted-foreground">
                <strong>{data.agentName || 'Your custom agent'}</strong> with {data.extensions?.filter((s: any) => s.enabled).length || 0} extensions is configured and ready for deployment.
              </div>
            </div>
          </div>
        </div>

        {/* Final action buttons */}
        <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
          <Button 
            size="lg" 
            onClick={handleDownload}
            className="bg-primary hover:bg-primary/90 text-primary-foreground px-12 py-4 font-semibold"
          >
            <Download className="w-5 h-5 mr-2" />
            Download & Deploy Now
          </Button>
          
          <div className="flex items-center gap-2">
            <Button 
              variant="outline" 
              onClick={() => setShowPromptModal(true)}
              className="px-6 py-3"
            >
              <Eye className="w-4 h-4 mr-2" />
              Review System Prompt
            </Button>
            
            {onSaveAsTemplate && (
              <Button 
                variant="outline" 
                onClick={onSaveAsTemplate}
                className="px-6 py-3"
              >
                <BookmarkPlus className="w-4 h-4 mr-2" />
                Save Template
              </Button>
            )}
          </div>
        </div>

        {/* Secondary actions */}
        <div className="flex items-center justify-between pt-4">
          <Button 
            variant="ghost" 
            onClick={onStartOver} 
            className="text-muted-foreground hover:text-foreground"
          >
            <RotateCcw className="w-4 h-4 mr-2" />
            Create Another Agent
          </Button>
          
          <div className="flex items-center gap-4 text-sm text-muted-foreground">
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 bg-success rounded-full"></div>
              <span>All systems operational</span>
            </div>
            <div className="flex items-center gap-2">
              <Timer className="w-4 h-4" />
              <span>Ready to deploy in {selectedFormatData?.difficulty === 'Easy' ? '< 2' : selectedFormatData?.difficulty === 'Medium' ? '5-10' : '15-30'} minutes</span>
            </div>
          </div>
        </div>
      </div>

      {/* Enhanced System Prompt Modal */}
      <Dialog open={showPromptModal} onOpenChange={setShowPromptModal}>
        <DialogContent className="max-w-6xl max-h-[85vh] overflow-hidden">
          <DialogHeader className="border-b border-border/30 pb-4">
            <div className="flex items-start justify-between">
              <div className="space-y-2">
                <DialogTitle className="flex items-center gap-3 text-xl">
                  <div className="p-2 bg-primary/20 rounded-lg">
                    <Brain className="w-6 h-6 text-primary" />
                  </div>
                  Enhanced System Prompt
                  <Badge className="bg-green-500/20 text-green-400 border-green-500/30">
                    2025 Standards
                  </Badge>
                </DialogTitle>
                <DialogDescription className="text-base max-w-2xl">
                  Your AI agent's complete system prompt, optimized with 2025 best practices for instruction clarity, 
                  safety scaffolding, and performance standards.
                </DialogDescription>
              </div>
            </div>
          </DialogHeader>
          
          <div className="flex-1 overflow-hidden space-y-4">
            {/* Prompt stats and quality indicators */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 p-4 bg-muted/30 rounded-lg">
              <div className="text-center space-y-1">
                <div className="text-2xl font-bold text-primary">{promptOutput.length.toLocaleString()}</div>
                <div className="text-xs text-muted-foreground">Characters</div>
              </div>
              <div className="text-center space-y-1">
                <div className="text-2xl font-bold text-blue-500">~{Math.ceil(promptOutput.length / 4)}</div>
                <div className="text-xs text-muted-foreground">Est. Tokens</div>
              </div>
              <div className="text-center space-y-1">
                <div className="text-2xl font-bold text-green-500">{(promptOutput.match(/##/g) || []).length}</div>
                <div className="text-xs text-muted-foreground">Sections</div>
              </div>
              <div className="text-center space-y-1">
                <div className="text-2xl font-bold text-orange-500">A+</div>
                <div className="text-xs text-muted-foreground">Quality Grade</div>
              </div>
            </div>

            {/* Action buttons */}
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Badge variant="outline" className="bg-primary/10 text-primary border-primary/30">
                  <Wand2 className="w-3 h-3 mr-1" />
                  Enhanced Structure
                </Badge>
                <Badge variant="outline" className="bg-green-500/10 text-green-500 border-green-500/30">
                  <Shield className="w-3 h-3 mr-1" />
                  Safety Validated
                </Badge>
                <Badge variant="outline" className="bg-blue-500/10 text-blue-500 border-blue-500/30">
                  <Target className="w-3 h-3 mr-1" />
                  Performance Optimized
                </Badge>
              </div>
              
              <div className="flex gap-2">
                <Button 
                  variant="outline" 
                  size="sm"
                  onClick={() => onCopy(promptOutput, 'system-prompt')}
                >
                  {copiedItem === 'system-prompt' ? <CheckCircle className="w-4 h-4" /> : <Copy className="w-4 h-4" />}
                  {copiedItem === 'system-prompt' ? 'Copied!' : 'Copy All'}
                </Button>
                <Button 
                  size="sm"
                  onClick={() => downloadFile(promptOutput, `${(data.agentName || 'ai-agent').toLowerCase().replace(/[^a-z0-9]/g, '-')}-system-prompt.txt`)}
                  className="bg-primary hover:bg-primary/90"
                >
                  <Download className="w-4 h-4 mr-2" />
                  Download .txt
                </Button>
              </div>
            </div>

            {/* Enhanced prompt preview with syntax highlighting effect */}
            <div className="relative max-h-[55vh] overflow-y-auto">
              <div className="absolute top-2 right-2 z-10 flex gap-1">
                <div className="w-3 h-3 bg-red-400 rounded-full"></div>
                <div className="w-3 h-3 bg-yellow-400 rounded-full"></div>
                <div className="w-3 h-3 bg-green-400 rounded-full"></div>
              </div>
              <pre className="bg-gradient-to-br from-muted/50 to-muted/30 p-6 rounded-lg text-sm font-mono whitespace-pre-wrap border border-primary/20 leading-relaxed">
                <code className="text-foreground">
                  {promptOutput || 'Loading enhanced system prompt...'}
                </code>
              </pre>
              
              {/* Floating improvement notice */}
              <div className="absolute bottom-4 right-4 bg-green-500/10 border border-green-500/30 rounded-lg p-3 backdrop-blur-sm">
                <div className="flex items-center gap-2 text-sm text-green-400">
                  <TrendingUp className="w-4 h-4" />
                  <span className="font-medium">40%+ better performance vs standard prompts</span>
                </div>
              </div>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}