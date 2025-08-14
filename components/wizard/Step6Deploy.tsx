import React, { useState } from 'react';
import { Button } from '../ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '../ui/dialog';
import { Textarea } from '../ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { RotateCcw, Download, Copy, CheckCircle, Zap, Package, Cloud, Settings, Star, ExternalLink, BookmarkPlus, Eye, Wand2, Brain, Target, AlertTriangle, RefreshCw, Play, Timer, Globe, ThumbsUp, ThumbsDown, Lightbulb, TrendingUp, Cpu, Database, Terminal, FileText, Search } from 'lucide-react';

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
      description: 'Production-grade orchestration for enterprise deployments',
      icon: Cloud,
      recommended: false,
      difficulty: 'Hard',
      features: [
        'High availability',
        'Auto-scaling',
        'Rolling deployments',
        'Service mesh ready',
        'Enterprise grade'
      ],
      instructions: [
        'Apply the Kubernetes manifests: kubectl apply -f agent-deployment.yaml',
        'Configure ingress and TLS certificates',
        'Set up monitoring and logging',
        'Configure auto-scaling policies',
        'Deploy to your Kubernetes cluster'
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
      <div className="text-center space-y-4">
        <h1 className="bg-gradient-to-r from-primary to-purple-400 bg-clip-text text-transparent">
          Deploy Your AI Agent
        </h1>
        <p className="text-muted-foreground max-w-2xl mx-auto">
          Your agent is configured and tested! Choose your deployment format, optimize your system prompt, 
          and get ready to deploy your custom AI agent with enterprise-grade capabilities.
        </p>
        
        {/* Primary Action CTAs */}
        <div className="flex items-center justify-center gap-4 pt-4">
          <Button 
            variant="outline" 
            onClick={() => setShowPromptModal(true)}
            className="px-6 py-2 border-primary/30 text-primary hover:bg-primary/10"
          >
            <Eye className="w-4 h-4 mr-2" />
            View System Prompt
          </Button>
          {onSaveAsTemplate && (
            <Button 
              onClick={onSaveAsTemplate}
              className="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground"
            >
              <BookmarkPlus className="w-4 h-4 mr-2" />
              Save as Template
            </Button>
          )}
        </div>
      </div>

      {/* Deployment Success Summary */}
      <Card className="selection-card border-success/30">
        <CardHeader>
          <div className="flex items-center gap-2">
            <CheckCircle className="w-6 h-6 text-success" />
            <CardTitle className="text-success">Configuration Complete!</CardTitle>
          </div>
          <CardDescription>
            Your AI agent is ready for deployment with the following configuration
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
            <div className="space-y-1">
              <div className="font-medium">Agent Profile</div>
              <div className="text-muted-foreground">{data.agentName || 'Custom Agent'}</div>
            </div>
            <div className="space-y-1">
              <div className="font-medium">Extensions</div>
              <div className="text-muted-foreground">{data.extensions?.filter((s: any) => s.enabled).length || 0} configured</div>
            </div>
            <div className="space-y-1">
              <div className="font-medium">Security</div>
              <div className="text-muted-foreground capitalize">{data.security?.authMethod || 'Basic'} auth</div>
            </div>
            <div className="space-y-1">
              <div className="font-medium">Test Status</div>
              <div className="text-success capitalize">{data.testResults?.overallStatus || 'Ready'}</div>
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
          <div className="flex flex-col sm:flex-row items-start sm:items-center gap-4">
            <div className="flex-1 space-y-2">
              <label className="text-sm font-medium">Target LLM Provider</label>
              <Select value={targetLLM} onValueChange={setTargetLLM}>
                <SelectTrigger className="w-full sm:w-64">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {llmProviders.map((provider) => (
                    <SelectItem key={provider.id} value={provider.id}>
                      <div className="flex items-center gap-2">
                        <span>{provider.icon}</span>
                        <div className="flex flex-col">
                          <span>{provider.name}</span>
                          <span className="text-xs text-muted-foreground">{provider.description}</span>
                        </div>
                      </div>
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            
            <div className="flex items-center gap-2">
              {selectedLLMData && (
                <div className="flex items-center gap-2 px-3 py-2 bg-muted/50 rounded-lg">
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
                className="bg-orange-500 hover:bg-orange-500/90 px-6"
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

      {/* Main Deployment Interface */}
      <Tabs defaultValue="deploy" className="space-y-6">
        <TabsList className="grid w-full grid-cols-3">
          <TabsTrigger value="deploy">Deploy Configuration</TabsTrigger>
          <TabsTrigger value="optimize">
            <Wand2 className="w-4 h-4 mr-2" />
            Optimize Prompt
            {analysisComplete && (
              <Badge className="ml-2 bg-success/20 text-success border-success/30 text-xs">
                Ready
              </Badge>
            )}
          </TabsTrigger>
          <TabsTrigger value="test">Test & Compare</TabsTrigger>
        </TabsList>

        <TabsContent value="deploy" className="space-y-6">
          {/* Deployment Format Selection */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {deploymentFormats.map((format) => {
              const Icon = format.icon;
              const isSelected = selectedFormat === format.id;
              
              return (
                <Card 
                  key={format.id}
                  className={`cursor-pointer transition-all duration-300 hover:-translate-y-1 ${
                    isSelected 
                      ? 'border-primary bg-gradient-to-br from-primary/10 to-transparent shadow-lg' 
                      : 'hover:border-primary/50 hover:shadow-md'
                  }`}
                  onClick={() => setSelectedFormat(format.id)}
                >
                  <CardHeader className="pb-4">
                    <div className="flex items-start justify-between">
                      <div className="flex items-center gap-3">
                        <Icon className={`w-6 h-6 ${isSelected ? 'text-primary' : 'text-muted-foreground'}`} />
                        <div>
                          <CardTitle className="text-base flex items-center gap-2">
                            {format.name}
                            {format.recommended && (
                              <Star className="w-4 h-4 text-yellow-400 fill-yellow-400" />
                            )}
                          </CardTitle>
                          <CardDescription className="text-sm">{format.description}</CardDescription>
                        </div>
                      </div>
                      {isSelected && <CheckCircle className="w-5 h-5 text-primary" />}
                    </div>
                  </CardHeader>
                  
                  <CardContent className="space-y-4">
                    <div className="flex items-center justify-between">
                      <Badge 
                        variant="outline" 
                        className={`chip-hug text-xs ${
                          format.difficulty === 'Easy' ? 'border-success/30 text-success' :
                          format.difficulty === 'Medium' ? 'border-warning/30 text-warning' : 
                          'border-destructive/30 text-destructive'
                        }`}
                      >
                        {format.difficulty} Setup
                      </Badge>
                      {format.recommended && (
                        <Badge className="chip-hug text-xs bg-primary/20 text-primary border-primary/30">
                          Recommended
                        </Badge>
                      )}
                    </div>

                    <div className="space-y-2">
                      <div className="text-sm font-medium">Key Features:</div>
                      <div className="grid grid-cols-1 gap-1">
                        {format.features.slice(0, 3).map((feature) => (
                          <div key={feature} className="text-sm text-muted-foreground flex items-center gap-2">
                            <div className="w-1.5 h-1.5 bg-primary rounded-full" />
                            {feature}
                          </div>
                        ))}
                      </div>
                    </div>
                  </CardContent>
                </Card>
              );
            })}
          </div>

          {/* Configuration Output */}
          <Card className="selection-card">
            <CardHeader>
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <Package className="w-5 h-5 text-primary" />
                  <CardTitle>{selectedFormatData?.name} Configuration</CardTitle>
                </div>
                <div className="flex gap-2">
                  <Button 
                    variant="outline" 
                    size="sm"
                    onClick={() => handleCopy(selectedFormat === 'prompt' ? promptOutput : deploymentConfigs[selectedFormat] || '')}
                  >
                    {copiedItem === selectedFormat ? <CheckCircle className="w-4 h-4" /> : <Copy className="w-4 h-4" />}
                    {copiedItem === selectedFormat ? 'Copied!' : 'Copy'}
                  </Button>
                  <Button 
                    variant="default" 
                    size="sm"
                    onClick={handleDownload}
                    className="bg-primary hover:bg-primary/90"
                  >
                    <Download className="w-4 h-4 mr-2" />
                    Download {getFileExtension(selectedFormat)}
                  </Button>
                </div>
              </div>
              <CardDescription>
                Ready-to-use configuration for {selectedFormatData?.name.toLowerCase()}
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Tabs value="config" className="w-full">
                <TabsList className="grid w-full grid-cols-2">
                  <TabsTrigger value="config">Configuration File</TabsTrigger>
                  <TabsTrigger value="instructions">Setup Instructions</TabsTrigger>
                </TabsList>
                
                <TabsContent value="config" className="space-y-4">
                  <div className="relative">
                    <pre className="bg-muted/30 p-4 rounded-lg overflow-x-auto text-sm font-mono max-h-96 border">
                      <code>
                        {selectedFormat === 'prompt' ? promptOutput : deploymentConfigs[selectedFormat] || 'Loading configuration...'}
                      </code>
                    </pre>
                  </div>
                </TabsContent>

                <TabsContent value="instructions" className="space-y-4">
                  <div className="space-y-4">
                    <div className="flex items-center gap-2">
                      <Badge variant="outline" className={`chip-hug ${
                        selectedFormatData?.difficulty === 'Easy' ? 'border-success/30 text-success' :
                        selectedFormatData?.difficulty === 'Medium' ? 'border-warning/30 text-warning' : 
                        'border-destructive/30 text-destructive'
                      }`}>
                        {selectedFormatData?.difficulty} Difficulty
                      </Badge>
                      {selectedFormatData?.recommended && (
                        <Badge className="chip-hug bg-primary/20 text-primary border-primary/30">
                          <Star className="w-3 h-3 mr-1" />
                          Recommended
                        </Badge>
                      )}
                    </div>

                    <div className="space-y-3">
                      <h4 className="font-medium">Deployment Steps:</h4>
                      <ol className="space-y-2">
                        {selectedFormatData?.instructions.map((instruction, index) => (
                          <li key={index} className="flex items-start gap-3">
                            <div className="w-6 h-6 bg-primary/20 text-primary rounded-full flex items-center justify-center text-sm font-medium mt-0.5">
                              {index + 1}
                            </div>
                            <div className="text-sm text-muted-foreground flex-1">{instruction}</div>
                          </li>
                        ))}
                      </ol>
                    </div>

                    {selectedFormat === 'desktop' && (
                      <div className="p-4 bg-primary/5 rounded-lg border border-primary/30">
                        <div className="flex items-center gap-2 mb-2">
                          <Star className="w-4 h-4 text-primary" />
                          <span className="font-medium text-primary">Recommended Choice</span>
                        </div>
                        <p className="text-sm text-muted-foreground">
                          Desktop Extension (.dxt) provides the easiest deployment experience with automatic extension management, 
                          built-in security controls, and instant availability in Claude Desktop.
                        </p>
                      </div>
                    )}
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

      {/* Navigation */}
      <div className="flex justify-between pt-6">
        <Button variant="outline" onClick={onStartOver} className="px-8">
          <RotateCcw className="w-4 h-4 mr-2" />
          Create New Agent
        </Button>
        <div className="text-sm text-muted-foreground flex items-center gap-2">
          <CheckCircle className="w-4 h-4 text-success" />
          Your agent is ready to deploy!
        </div>
      </div>

      {/* System Prompt Modal */}
      <Dialog open={showPromptModal} onOpenChange={setShowPromptModal}>
        <DialogContent className="max-w-4xl max-h-[80vh] overflow-hidden">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Eye className="w-5 h-5 text-primary" />
              Generated System Prompt
            </DialogTitle>
            <DialogDescription>
              Complete system prompt for your AI agent with all configurations, constraints, and behavioral guidelines.
            </DialogDescription>
          </DialogHeader>
          <div className="flex-1 overflow-hidden">
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div className="text-sm text-muted-foreground">
                  Character count: {promptOutput.length.toLocaleString()}
                </div>
                <div className="flex gap-2">
                  <Button 
                    variant="outline" 
                    size="sm"
                    onClick={() => onCopy(promptOutput, 'system-prompt')}
                  >
                    {copiedItem === 'system-prompt' ? <CheckCircle className="w-4 h-4" /> : <Copy className="w-4 h-4" />}
                    {copiedItem === 'system-prompt' ? 'Copied!' : 'Copy'}
                  </Button>
                  <Button 
                    variant="default" 
                    size="sm"
                    onClick={() => downloadFile(promptOutput, `${(data.agentName || 'ai-agent').toLowerCase().replace(/[^a-z0-9]/g, '-')}-system-prompt.txt`)}
                    className="bg-primary hover:bg-primary/90"
                  >
                    <Download className="w-4 h-4 mr-2" />
                    Download
                  </Button>
                </div>
              </div>
              <div className="relative max-h-[60vh] overflow-y-auto">
                <pre className="bg-muted/30 p-4 rounded-lg text-sm font-mono whitespace-pre-wrap border">
                  <code>{promptOutput}</code>
                </pre>
              </div>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}