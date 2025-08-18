import { useState } from 'react';
import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Textarea } from './ui/textarea';
import { Tabs, TabsContent, TabsList, TabsTrigger } from './ui/tabs';
import { 
  ArrowLeft,
  Wand2,
  Brain,
  Zap,
  CheckCircle,
  AlertTriangle,
  Copy,
  Download,
  RefreshCw,
  Play,
  BarChart3,
  Target,
  FileText,
  Lightbulb,
  TrendingUp,
  Eye,
  Cpu,
  Timer,
  Globe,
  Star,
  Shield,
  Sparkles
} from 'lucide-react';

interface SystemPromptOptimizerProps {
  onBackToLanding: () => void;
  onBackToWizard: () => void;
  initialPrompt?: string;
}

interface LLMProvider {
  id: string;
  name: string;
  icon: string;
  color: string;
  strengths: string[];
  pricing: 'Free' | 'Paid' | 'Freemium';
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
    pricing: 'Paid'
  },
  {
    id: 'claude',
    name: 'Anthropic Claude',
    icon: '🧠',
    color: '#6366F1', 
    strengths: ['Safety', 'Analysis', 'Long Context'],
    pricing: 'Freemium'
  },
  {
    id: 'gemini',
    name: 'Google Gemini',
    icon: '💎',
    color: '#F59E0B',
    strengths: ['Multimodal', 'Search', 'Reasoning'],
    pricing: 'Freemium'
  },
  {
    id: 'mistral',
    name: 'Mistral AI',
    icon: '🌪️',
    color: '#EF4444',
    strengths: ['Efficiency', 'Code', 'Multilingual'],
    pricing: 'Freemium'
  },
  {
    id: 'llama',
    name: 'Meta Llama',
    icon: '🦙',
    color: '#8B5CF6',
    strengths: ['Open Source', 'Customizable', 'Privacy'],
    pricing: 'Free'
  },
  {
    id: 'cohere',
    name: 'Cohere',
    icon: '🔮',
    color: '#06B6D4',
    strengths: ['Enterprise', 'RAG', 'Fine-tuning'],
    pricing: 'Paid'
  }
];

export function SystemPromptOptimizer({ onBackToLanding, onBackToWizard, initialPrompt = '' }: SystemPromptOptimizerProps) {
  const [originalPrompt, setOriginalPrompt] = useState(initialPrompt);
  const [optimizedPrompt, setOptimizedPrompt] = useState('');
  const [selectedProviders, setSelectedProviders] = useState<string[]>(['openai', 'claude', 'gemini']);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [isTesting, setIsTesting] = useState(false);
  const [analysisComplete, setAnalysisComplete] = useState(false);
  const [testResults, setTestResults] = useState<Record<string, TestResult>>({});
  const [optimizationScore, setOptimizationScore] = useState(0);
  const [copiedItem, setCopiedItem] = useState<string | null>(null);
  
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

  const handleAnalyzePrompt = async () => {
    setIsAnalyzing(true);
    setAnalysisComplete(false);
    
    // Simulate analysis
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    // Generate mock optimized prompt
    const optimized = `You are an expert AI assistant with the following capabilities and guidelines:

ROLE: Professional assistant specialized in providing comprehensive, accurate information

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

CONSTRAINTS:
- Keep responses concise yet complete
- Avoid speculation without clear disclaimers
- Focus on actionable information
- Adapt complexity to user's apparent expertise level

Remember: Your goal is to be genuinely helpful while maintaining high standards of accuracy and clarity.`;

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

  const copyToClipboard = async (text: string, itemType: string) => {
    try {
      await navigator.clipboard.writeText(text);
      setCopiedItem(itemType);
      setTimeout(() => setCopiedItem(null), 2000);
    } catch (err) {
      console.error('Failed to copy:', err);
    }
  };

  const downloadPrompt = (prompt: string, filename: string) => {
    const blob = new Blob([prompt], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${filename}.txt`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
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
      case 'security': return Shield;
      default: return Lightbulb;
    }
  };

  return (
    <div className="content-width mx-auto px-4 py-6 space-y-8">
      {/* Header */}
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <Button variant="ghost" onClick={onBackToLanding} className="flex items-center gap-2">
              <ArrowLeft className="w-4 h-4" />
              Back to Landing
            </Button>
            <div>
              <h1 className="text-3xl font-bold flex items-center gap-3">
                <div className="relative">
                  <Wand2 className="w-8 h-8 text-orange-500" />
                  <div className="absolute -top-1 -right-1 w-3 h-3 bg-orange-500 rounded-full animate-pulse"></div>
                </div>
                System Prompt Optimizer
              </h1>
              <p className="text-muted-foreground">
                Optimize your system prompts for better performance across all major LLMs
              </p>
            </div>
          </div>
          
          <div className="flex items-center gap-3">
            <Badge variant="outline" className="flex items-center gap-1 bg-orange-500/20 text-orange-400 border-orange-500/30">
              <Cpu className="w-3 h-3" />
              Multi-LLM Support
            </Badge>
            <Button variant="outline" onClick={onBackToWizard}>
              <Brain className="w-4 h-4 mr-2" />
              Agent Builder
            </Button>
          </div>
        </div>

        {/* Quick Stats */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {[
            { label: 'Supported LLMs', value: llmProviders.length, icon: Globe },
            { label: 'Optimization Score', value: analysisComplete ? `${optimizationScore}%` : '--', icon: Target },
            { label: 'Token Efficiency', value: analysisComplete ? '+25%' : '--', icon: Zap },
            { label: 'Response Quality', value: analysisComplete ? '+40%' : '--', icon: Star }
          ].map((stat, index) => {
            const Icon = stat.icon;
            return (
              <Card key={index} className="selection-card text-center">
                <CardContent className="p-4">
                  <Icon className="w-6 h-6 text-primary mx-auto mb-2" />
                  <div className="text-2xl font-bold text-primary">{stat.value}</div>
                  <div className="text-xs text-muted-foreground">{stat.label}</div>
                </CardContent>
              </Card>
            );
          })}
        </div>
      </div>

      {/* Main Optimizer Interface */}
      <Tabs defaultValue="optimize" className="space-y-6">
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="optimize">Optimize</TabsTrigger>
          <TabsTrigger value="test">Test & Compare</TabsTrigger>
          <TabsTrigger value="analyze">Analysis</TabsTrigger>
          <TabsTrigger value="templates">Templates</TabsTrigger>
        </TabsList>

        <TabsContent value="optimize" className="space-y-6">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Original Prompt */}
            <Card className="selection-card">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <FileText className="w-5 h-5 text-muted-foreground" />
                  Original Prompt
                </CardTitle>
                <CardDescription>
                  Paste your current system prompt here for optimization
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <Textarea
                  placeholder="Enter your system prompt here..."
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
                    <Button
                      onClick={handleAnalyzePrompt}
                      disabled={!originalPrompt.trim() || isAnalyzing}
                      className="bg-orange-500 hover:bg-orange-500/90"
                    >
                      {isAnalyzing ? (
                        <>
                          <RefreshCw className="w-4 h-4 mr-2 animate-spin" />
                          Analyzing...
                        </>
                      ) : (
                        <>
                          <Wand2 className="w-4 h-4 mr-2" />
                          Optimize Prompt
                        </>
                      )}
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Optimized Prompt */}
            <Card className="selection-card">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Sparkles className="w-5 h-5 text-primary" />
                  Optimized Prompt
                  {analysisComplete && (
                    <Badge className="bg-green-500/20 text-green-400 border-green-500/30">
                      <TrendingUp className="w-3 h-3 mr-1" />
                      +{optimizationScore}% Better
                    </Badge>
                  )}
                </CardTitle>
                <CardDescription>
                  AI-optimized version of your prompt with improvements
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
                      onClick={() => downloadPrompt(optimizedPrompt, 'optimized_system_prompt')}
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
                </CardTitle>
                <CardDescription>
                  Specific improvements applied to your prompt
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
                  <BarChart3 className="w-5 h-5 text-primary" />
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

        <TabsContent value="analyze" className="space-y-6">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Analysis Overview */}
            <Card className="selection-card">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Brain className="w-5 h-5 text-primary" />
                  Prompt Analysis Overview
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-6">
                {analysisComplete ? (
                  <>
                    <div className="space-y-4">
                      <div className="flex items-center justify-between">
                        <span className="text-sm font-medium">Overall Quality Score</span>
                        <span className="text-2xl font-bold text-primary">{optimizationScore}%</span>
                      </div>
                      
                      <div className="space-y-3">
                        {[
                          { label: 'Clarity', score: Math.floor(Math.random() * 20) + 80, color: 'bg-green-500' },
                          { label: 'Structure', score: Math.floor(Math.random() * 25) + 70, color: 'bg-blue-500' },
                          { label: 'Specificity', score: Math.floor(Math.random() * 30) + 65, color: 'bg-yellow-500' },
                          { label: 'Token Efficiency', score: Math.floor(Math.random() * 35) + 60, color: 'bg-purple-500' }
                        ].map((metric) => (
                          <div key={metric.label} className="space-y-2">
                            <div className="flex justify-between text-sm">
                              <span>{metric.label}</span>
                              <span>{metric.score}%</span>
                            </div>
                            <div className="w-full bg-muted rounded-full h-2">
                              <div 
                                className={`${metric.color} h-2 rounded-full transition-all duration-1000`}
                                style={{ width: `${metric.score}%` }}
                              ></div>
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>

                    <div className="space-y-3">
                      <h4 className="font-medium">Key Improvements</h4>
                      <div className="space-y-2 text-sm text-muted-foreground">
                        <div className="flex items-center gap-2">
                          <CheckCircle className="w-4 h-4 text-green-400" />
                          Improved instruction clarity (+15%)
                        </div>
                        <div className="flex items-center gap-2">
                          <CheckCircle className="w-4 h-4 text-green-400" />
                          Added response structure (+25%)
                        </div>
                        <div className="flex items-center gap-2">
                          <CheckCircle className="w-4 h-4 text-green-400" />
                          Optimized token usage (+12%)
                        </div>
                      </div>
                    </div>
                  </>
                ) : (
                  <div className="text-center py-8 text-muted-foreground">
                    <Brain className="w-12 h-12 mx-auto mb-4 opacity-50" />
                    <p>Run an analysis to see detailed insights about your prompt</p>
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Best Practices */}
            <Card className="selection-card">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Lightbulb className="w-5 h-5 text-yellow-400" />
                  Best Practices Guide
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-4 text-sm">
                  {[
                    {
                      title: 'Be Specific and Clear',
                      description: 'Use precise language and avoid ambiguous terms. Specify exactly what you want the AI to do.',
                      example: 'Instead of "be helpful", use "provide step-by-step solutions with examples"'
                    },
                    {
                      title: 'Define the Response Format',
                      description: 'Specify how you want the response structured for consistency.',
                      example: 'Structure as: 1) Summary 2) Details 3) Examples 4) Next steps'
                    },
                    {
                      title: 'Set Clear Boundaries',
                      description: 'Define what the AI should and shouldn\'t do to avoid unwanted behavior.',
                      example: 'Always cite sources, never speculate, acknowledge uncertainty'
                    },
                    {
                      title: 'Use Examples When Possible',
                      description: 'Show examples of desired outputs to guide the AI\'s responses.',
                      example: 'Provide 2-3 examples of the ideal response format'
                    }
                  ].map((practice, index) => (
                    <div key={index} className="space-y-2 pb-4 border-b border-border/30 last:border-0">
                      <h4 className="font-medium text-primary">{practice.title}</h4>
                      <p className="text-muted-foreground">{practice.description}</p>
                      <div className="bg-muted/50 rounded-md p-2 text-xs font-mono">
                        💡 {practice.example}
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="templates" className="space-y-6">
          <Card className="selection-card">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <FileText className="w-5 h-5 text-primary" />
                Prompt Templates
              </CardTitle>
              <CardDescription>
                Ready-to-use system prompt templates for common use cases
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {[
                  {
                    name: 'Customer Support Agent',
                    description: 'Professional, helpful, and empathetic customer service responses',
                    category: 'Business',
                    preview: 'You are a professional customer support representative...'
                  },
                  {
                    name: 'Technical Documentation Writer',
                    description: 'Clear, comprehensive technical writing with examples',
                    category: 'Technical',
                    preview: 'You are an expert technical writer who creates...'
                  },
                  {
                    name: 'Code Review Assistant',
                    description: 'Constructive code feedback with improvement suggestions',
                    category: 'Development',
                    preview: 'You are an experienced software engineer conducting...'
                  },
                  {
                    name: 'Educational Tutor',
                    description: 'Patient, encouraging teaching with step-by-step explanations',
                    category: 'Education',
                    preview: 'You are a knowledgeable and patient tutor who...'
                  }
                ].map((template, index) => (
                  <Card key={index} className="selection-card cursor-pointer hover:scale-105 transition-transform">
                    <CardContent className="p-4 space-y-3">
                      <div className="flex items-start justify-between">
                        <div className="space-y-1">
                          <h4 className="font-medium">{template.name}</h4>
                          <Badge variant="secondary" className="chip-hug">
                            {template.category}
                          </Badge>
                        </div>
                        <Button variant="outline" size="sm">
                          <Copy className="w-4 h-4" />
                        </Button>
                      </div>
                      
                      <p className="text-sm text-muted-foreground">
                        {template.description}
                      </p>
                      
                      <div className="bg-muted/50 rounded-md p-2 text-xs font-mono text-muted-foreground">
                        {template.preview}
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}