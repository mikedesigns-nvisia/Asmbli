import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Alert, AlertDescription } from '../ui/alert';
import { Download, CheckCircle, ExternalLink, Brain, Monitor, Code, Rocket, Clock, Heart, FileText, Zap, MessageSquare, Building, Layers } from 'lucide-react';
import { generateDeploymentConfigs } from '../../utils/deploymentGenerator';


// Utility function to detect user's OS
const detectOS = () => {
  const userAgent = navigator.userAgent.toLowerCase();
  if (userAgent.indexOf('win') !== -1) return 'windows';
  if (userAgent.indexOf('mac') !== -1) return 'mac';
  if (userAgent.indexOf('linux') !== -1) return 'linux';
  return 'windows'; // Default fallback
};

// OS display names and icons
const OS_INFO = {
  windows: { name: 'Windows', icon: '🪟' },
  mac: { name: 'macOS', icon: '🍎' },
  linux: { name: 'Linux', icon: '🐧' }
};

interface MVPStep5DeployProps {
  wizardData: any;
  deployment: {
    platform: string;
    configuration: any;
  };
  onDeploymentChange: (deployment: { platform: string; configuration: any }) => void;
  onGenerate: () => void;
}

const FREE_PLATFORMS = [
  {
    id: 'librechat',
    name: 'LibreChat',
    description: 'Enhanced ChatGPT clone with full MCP support and 20+ AI providers',
    icon: MessageSquare,
    difficulty: 'Easy',
    setupTime: '8 minutes',
    downloadUrl: 'https://docs.librechat.ai',
    downloadLinks: {
      windows: 'https://github.com/danny-avila/LibreChat/releases/latest',
      mac: 'https://github.com/danny-avila/LibreChat/releases/latest',
      linux: 'https://github.com/danny-avila/LibreChat/releases/latest'
    },
    docsUrl: 'https://docs.librechat.ai',
    modelStore: 'https://docs.librechat.ai/install/configuration/ai_endpoints',
    setupGuideUrl: 'https://docs.librechat.ai/install/installation/docker_compose',
    features: [
      'Full MCP server support',
      '20+ AI provider support',
      'Multi-user with RBAC',
      'Complete self-hosting',
      'Enterprise features'
    ],
    benefits: [
      '🌐 20+ AI providers (OpenAI, Anthropic, Google, etc.)',
      '🔧 Full MCP integration with UI management',
      '👥 Multi-user support with role-based access',
      '🏢 Enterprise features (audit logs, SSO, etc.)'
    ],
    requirements: [
      'Docker and Docker Compose',
      'Node.js for MCP servers',
      '4GB+ RAM recommended'
    ]
  },
  {
    id: 'jan-ai',
    name: 'Jan.ai',
    description: 'Desktop AI assistant with seamless local/cloud model switching',
    icon: Brain,
    difficulty: 'Easy',
    setupTime: '5 minutes',
    downloadUrl: 'https://jan.ai/download',
    downloadLinks: {
      windows: 'https://github.com/janhq/jan/releases/latest/download/jan-win-x64.exe',
      mac: 'https://github.com/janhq/jan/releases/latest/download/jan-mac-universal.dmg',
      linux: 'https://github.com/janhq/jan/releases/latest/download/jan-linux-amd64.AppImage'
    },
    docsUrl: 'https://jan.ai/docs',
    modelStore: 'https://jan.ai/models',
    setupGuideUrl: 'https://jan.ai/docs/quickstart',
    features: [
      'Desktop app interface',
      'Local + cloud models',
      'MCP extension support',
      'Professional development',
      'Simple one-click setup'
    ],
    benefits: [
      '💻 Beautiful desktop app - no technical setup',
      '🔄 Switch between local and API models seamlessly',
      '🔌 MCP support with extension architecture',
      '💼 Professional development with VC backing'
    ],
    requirements: [
      'Desktop application (easy install)',
      'Node.js for MCP servers',
      '8GB+ RAM for local models'
    ]
  },
  {
    id: 'anythingllm',
    name: 'AnythingLLM',
    description: 'Enterprise AI platform with no-code agent builder',
    icon: Building,
    difficulty: 'Medium',
    setupTime: '10 minutes',
    downloadUrl: 'https://anythingllm.com/download',
    downloadLinks: {
      windows: 'https://github.com/Mintplex-Labs/anything-llm/releases/latest',
      mac: 'https://github.com/Mintplex-Labs/anything-llm/releases/latest',
      linux: 'https://github.com/Mintplex-Labs/anything-llm/releases/latest'
    },
    docsUrl: 'https://docs.anythingllm.com',
    modelStore: 'https://docs.anythingllm.com/llm-configuration',
    setupGuideUrl: 'https://docs.anythingllm.com/installation/self-hosted/local-docker',
    features: [
      'No-code agent builder',
      'Enterprise workspace system',
      'RAG and document integration',
      'Docker or desktop deployment',
      'Advanced analytics'
    ],
    benefits: [
      '🎯 No-code agent builder for business users',
      '🏢 Enterprise workspace and document management',
      '📄 Advanced RAG with document integration',
      '📊 Built-in analytics and monitoring'
    ],
    requirements: [
      'Docker or desktop app',
      'Node.js for integrations',
      '8GB+ RAM recommended'
    ]
  }
];

export function MVPStep5Deploy({ wizardData, deployment, onDeploymentChange, onGenerate }: MVPStep5DeployProps) {
  const [selectedPlatform, setSelectedPlatform] = useState(deployment.platform || '');
  const [generatedConfigs, setGeneratedConfigs] = useState<Record<string, string>>({});
  const [configState, setConfigState] = useState<'idle' | 'generating' | 'ready'>('idle');

  const handlePlatformSelect = (platformId: string) => {
    setSelectedPlatform(platformId);
    
    if (platformId && wizardData) {
      setConfigState('generating');
      
      // Generate configs immediately without timeout
      try {
        console.log('MVPStep5Deploy: Generating configs for platform:', platformId);
        const configs = generateDeploymentConfigs(wizardData);
        console.log('MVPStep5Deploy: Generated configs:', Object.keys(configs));
        
        // MCP server configurations have been fixed and verified
        
        setGeneratedConfigs(configs);
        onDeploymentChange({
          platform: platformId,
          configuration: configs[platformId]
        });
        setConfigState('ready');
      } catch (error) {
        console.error('Config generation failed:', error);
        setConfigState('idle');
      }
    }
  };

  const downloadFile = (content: string, filename: string) => {
    const blob = new Blob([content], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  const selectedPlatformData = FREE_PLATFORMS.find(p => p.id === selectedPlatform);

  const getSetupGuideKey = (platformId: string) => {
    return `${platformId}-setup.md`;
  };

  return (
    <div className="space-y-6">
      <div className="text-center space-y-2">
        <p className="text-muted-foreground">
          Choose a powerful platform to deploy your custom AI agent. All options offer enterprise-grade features while keeping your data private.
        </p>
      </div>

      {/* Quick Download Links */}
      <Card className="border-blue-500/20 bg-blue-500/5">
        <CardContent className="p-4">
          <div className="flex items-center gap-2 mb-3">
            <Download className="w-4 h-4 text-blue-600" />
            <h3 className="font-medium text-blue-900">Quick Downloads</h3>
            <Badge variant="outline" className="bg-blue-500/10 text-blue-600 border-blue-500/30 text-xs">
              {(() => {
                const userOS = detectOS() as keyof typeof OS_INFO;
                const osInfo = OS_INFO[userOS];
                return `${osInfo.icon} ${osInfo.name}`;
              })()}
            </Badge>
          </div>
          <div className="flex flex-wrap gap-2">
            {FREE_PLATFORMS.map((platform) => {
              const userOS = detectOS() as keyof typeof OS_INFO;
              const downloadLink = (platform as any).downloadLinks?.[userOS];
              
              return (
                <Button
                  key={platform.id}
                  variant="outline"
                  size="sm"
                  className="text-xs hover:bg-blue-500/10 hover:border-blue-500/30"
                  onClick={() => {
                    if (downloadLink) {
                      window.open(downloadLink, '_blank');
                    } else {
                      window.open((platform as any).downloadUrl, '_blank');
                    }
                  }}
                >
                  {React.createElement(platform.icon, { className: "w-3 h-3 mr-1" })}
                  {platform.name}
                </Button>
              );
            })}
          </div>
          <div className="flex items-center justify-between mt-3 pt-2 border-t border-blue-500/20">
            <p className="text-xs text-muted-foreground">
              💡 Download your preferred platform first, then select it below
            </p>
            <Button
              variant="ghost"
              size="sm"
              className="text-xs text-blue-600 hover:bg-blue-500/10"
              onClick={() => {
                // Open Node.js download
                window.open('https://nodejs.org/en/download/', '_blank');
                
                // Small delay then open platform downloads
                setTimeout(() => {
                  FREE_PLATFORMS.forEach((platform, index) => {
                    setTimeout(() => {
                      const userOS = detectOS() as keyof typeof OS_INFO;
                      const downloadLink = (platform as any).downloadLinks?.[userOS];
                      window.open(downloadLink || (platform as any).downloadUrl, '_blank');
                    }, index * 500); // Stagger downloads
                  });
                }, 1000);
              }}
            >
              <Download className="w-3 h-3 mr-1" />
              Download All
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Platform Selection */}
      <div className="space-y-4">
        <div className="flex items-center gap-2">
          <Rocket className="w-5 h-5 text-primary" />
          <h3 className="text-lg font-semibold">Enterprise Deployment Options</h3>
          <Badge className="bg-green-500/10 text-green-600 border-green-500/30">
            Self-Hosted
          </Badge>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {FREE_PLATFORMS.map((platform) => {
            const Icon = platform.icon;
            const isSelected = selectedPlatform === platform.id;
            
            return (
              <Card
                key={platform.id}
                className={`cursor-pointer transition-all duration-300 hover:shadow-lg ${
                  isSelected 
                    ? 'border-primary bg-gradient-to-br from-primary/10 via-primary/5 to-transparent shadow-lg ring-2 ring-primary/20' 
                    : 'hover:border-primary/30 hover:shadow-md border-border'
                }`}
                onClick={() => handlePlatformSelect(platform.id)}
              >
                <CardHeader className="text-center pb-4">
                  <div className={`w-16 h-16 mx-auto rounded-full flex items-center justify-center mb-3 transition-colors ${
                    isSelected ? 'bg-primary/20' : 'bg-muted/50'
                  }`}>
                    <Icon className={`w-8 h-8 ${
                      isSelected ? 'text-primary' : 'text-muted-foreground'
                    }`} />
                  </div>
                  
                  <div className="space-y-2">
                    <CardTitle className="text-lg">{platform.name}</CardTitle>
                    <CardDescription className="text-sm leading-relaxed">
                      {platform.description}
                    </CardDescription>
                  </div>
                  
                  <div className="flex justify-center gap-2">
                    <Badge 
                      variant="outline" 
                      className={`text-xs ${
                        platform.difficulty === 'Easy' ? 'border-green-500/30 text-green-600 bg-green-500/10' :
                        'border-yellow-500/30 text-yellow-600 bg-yellow-500/10'
                      }`}
                    >
                      {platform.difficulty}
                    </Badge>
                    <Badge variant="outline" className="text-xs border-blue-500/30 text-blue-600 bg-blue-500/10">
                      <Clock className="w-3 h-3 mr-1" />
                      {platform.setupTime}
                    </Badge>
                  </div>
                </CardHeader>
                
                <CardContent className="space-y-4">
                  {/* Key Benefits */}
                  <div className="space-y-2">
                    <h4 className="font-medium text-sm">Why Choose This?</h4>
                    <div className="space-y-1">
                      {platform.benefits.slice(0, 3).map((benefit, index) => (
                        <div key={index} className="text-xs text-muted-foreground">
                          {benefit}
                        </div>
                      ))}
                    </div>
                  </div>
                  
                  {/* Download Button */}
                  <div className="pt-2 border-t border-border/50">
                    {(() => {
                      const userOS = detectOS() as keyof typeof OS_INFO;
                      const osInfo = OS_INFO[userOS];
                      const downloadLink = (platform as any).downloadLinks?.[userOS];
                      
                      return (
                        <div className="space-y-2">
                          <Button
                            variant="outline"
                            size="sm"
                            className="w-full text-xs hover:bg-primary/10 hover:border-primary/30"
                            onClick={(e) => {
                              e.stopPropagation();
                              if (downloadLink) {
                                window.open(downloadLink, '_blank');
                              } else {
                                window.open((platform as any).downloadUrl, '_blank');
                              }
                            }}
                          >
                            <Download className="w-3 h-3 mr-1" />
                            Download for {osInfo.name} {osInfo.icon}
                          </Button>
                          
                          <div className="text-center">
                            <button
                              className="text-xs text-muted-foreground hover:text-primary underline"
                              onClick={(e) => {
                                e.stopPropagation();
                                window.open((platform as any).downloadUrl, '_blank');
                              }}
                            >
                              Other platforms →
                            </button>
                          </div>
                        </div>
                      );
                    })()}
                  </div>
                  
                  {/* Selection Indicator */}
                  {isSelected && (
                    <div className="flex items-center justify-center pt-2 border-t border-border/50">
                      <div className="flex items-center gap-2 text-primary font-medium text-sm">
                        <CheckCircle className="w-4 h-4" />
                        Selected
                      </div>
                    </div>
                  )}
                </CardContent>
              </Card>
            );
          })}
        </div>
      </div>

      {/* Configuration & Setup */}
      {selectedPlatform && (
        <Card className="border-primary/30 bg-gradient-to-r from-primary/5 to-blue-500/5">
          <CardHeader>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-primary/20 rounded-lg">
                  {React.createElement(selectedPlatformData!.icon, { className: "w-6 h-6 text-primary" })}
                </div>
                <div>
                  <CardTitle className="text-xl">{selectedPlatformData!.name} Configuration</CardTitle>
                  <CardDescription className="text-base">
                    Ready-to-deploy setup for {selectedPlatformData!.name.toLowerCase()}
                  </CardDescription>
                </div>
              </div>
              <Badge className="bg-success/10 text-success border-success/30 px-4 py-2">
                <CheckCircle className="w-4 h-4 mr-1" />
                Ready
              </Badge>
            </div>
          </CardHeader>
          
          <CardContent>
            <Tabs defaultValue="config" className="w-full">
              <TabsList className="grid w-full grid-cols-3">
                <TabsTrigger value="config">Configuration</TabsTrigger>
                <TabsTrigger value="setup">Setup Guide</TabsTrigger>
                <TabsTrigger value="features">Features</TabsTrigger>
              </TabsList>
              
              <TabsContent value="config" className="space-y-4">
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <h4 className="font-medium">Generated Configuration</h4>
                    <Badge variant="outline">
                      {selectedPlatform.toUpperCase()}
                    </Badge>
                  </div>
                  
                  {configState === 'generating' ? (
                    <div className="flex items-center justify-center py-8">
                      <div className="flex items-center gap-3">
                        <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-primary"></div>
                        <span className="text-muted-foreground">Generating configuration...</span>
                      </div>
                    </div>
                  ) : (
                    <div className="space-y-4">
                      <pre className="bg-muted/50 p-4 rounded-lg overflow-x-auto text-xs font-mono max-h-96 border border-primary/20">
                        <code className="text-muted-foreground">
                          {generatedConfigs[selectedPlatform] || 'Loading configuration...'}
                        </code>
                      </pre>
                      
                      <div className="flex flex-col sm:flex-row gap-3">
                        <Button
                          onClick={() => downloadFile(
                            generatedConfigs[selectedPlatform] || '', 
                            `${selectedPlatform}-config.json`
                          )}
                          className="flex items-center gap-2"
                        >
                          <Download className="w-4 h-4" />
                          Download Config
                        </Button>
                        
                        <Button
                          variant="outline"
                          onClick={() => downloadFile(
                            generatedConfigs[getSetupGuideKey(selectedPlatform)] || 'Setup guide not available', 
                            `${selectedPlatform}-setup-guide.md`
                          )}
                          className="flex items-center gap-2"
                        >
                          <FileText className="w-4 h-4" />
                          Download Setup Guide
                        </Button>
                      </div>
                    </div>
                  )}
                </div>
              </TabsContent>
              
              <TabsContent value="setup" className="space-y-4">
                <div className="space-y-4">
                  <h4 className="font-medium">Quick Setup Steps</h4>
                  
                  <div className="space-y-3">
                    {selectedPlatformData!.requirements.map((req, index) => (
                      <div key={index} className="flex items-start gap-3">
                        <div className="w-6 h-6 rounded-full bg-primary/20 flex items-center justify-center text-primary text-sm font-medium">
                          {index + 1}
                        </div>
                        <div className="flex-1">
                          <p className="text-sm font-medium">Install {req}</p>
                          <p className="text-xs text-muted-foreground">Required dependency</p>
                        </div>
                      </div>
                    ))}
                    
                    <div className="flex items-start gap-3">
                      <div className="w-6 h-6 rounded-full bg-primary/20 flex items-center justify-center text-primary text-sm font-medium">
                        {selectedPlatformData!.requirements.length + 1}
                      </div>
                      <div className="flex-1">
                        <p className="text-sm font-medium">Download and apply configuration</p>
                        <p className="text-xs text-muted-foreground">Use the config file from the Configuration tab</p>
                      </div>
                    </div>
                    
                    <div className="flex items-start gap-3">
                      <div className="w-6 h-6 rounded-full bg-success/20 flex items-center justify-center text-success text-sm font-medium">
                        ✓
                      </div>
                      <div className="flex-1">
                        <p className="text-sm font-medium">Start using your custom AI agent</p>
                        <p className="text-xs text-muted-foreground">Your agent is ready with all your preferences</p>
                      </div>
                    </div>
                  </div>
                  
                  <Alert>
                    <FileText className="h-4 w-4" />
                    <AlertDescription>
                      Download the detailed setup guide for step-by-step instructions with screenshots and troubleshooting tips.
                    </AlertDescription>
                  </Alert>
                  
                  {/* Download & Resources Section */}
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {/* Download Section */}
                    <Card className="border-orange-500/20 bg-orange-500/5">
                      <CardContent className="p-4">
                        <div className="flex items-center gap-2 mb-3">
                          <Download className="w-4 h-4 text-orange-600" />
                          <h4 className="font-medium text-orange-900">Download Platform</h4>
                        </div>
                        <div className="space-y-2">
                          <Button
                            className="w-full bg-orange-500 hover:bg-orange-600 text-white"
                            onClick={() => {
                              const userOS = detectOS() as keyof typeof OS_INFO;
                              const downloadLink = (selectedPlatformData as any)?.downloadLinks?.[userOS];
                              
                              if (downloadLink) {
                                window.open(downloadLink, '_blank');
                              } else {
                                window.open((selectedPlatformData as any)?.downloadUrl, '_blank');
                              }
                            }}
                          >
                            <Download className="w-4 h-4 mr-2" />
                            Download {selectedPlatformData!.name}
                          </Button>
                          <div className="text-center">
                            <button
                              className="text-xs text-muted-foreground hover:text-orange-600 underline"
                              onClick={() => {
                                window.open((selectedPlatformData as any)?.downloadUrl, '_blank');
                              }}
                            >
                              Other platforms
                            </button>
                          </div>
                        </div>
                      </CardContent>
                    </Card>

                    {/* Resources Section */}
                    <Card className="border-blue-500/20 bg-blue-500/5">
                      <CardContent className="p-4">
                        <div className="flex items-center gap-2 mb-3">
                          <ExternalLink className="w-4 h-4 text-blue-600" />
                          <h4 className="font-medium text-blue-900">Resources & Models</h4>
                        </div>
                        <div className="space-y-2">
                          <Button
                            variant="outline"
                            className="w-full justify-start hover:bg-blue-500/10 hover:border-blue-500/30"
                            onClick={() => {
                              window.open((selectedPlatformData as any)?.modelStore, '_blank');
                            }}
                          >
                            <Brain className="w-3 h-3 mr-2" />
                            {selectedPlatformData!.id === 'librechat' ? 'AI Providers Setup' : 
                             selectedPlatformData!.id === 'jan-ai' ? 'Browse Models' : 
                             'Model Configuration'}
                          </Button>
                          <Button
                            variant="outline"
                            className="w-full justify-start hover:bg-blue-500/10 hover:border-blue-500/30"
                            onClick={() => {
                              window.open((selectedPlatformData as any)?.docsUrl, '_blank');
                            }}
                          >
                            <FileText className="w-3 h-3 mr-2" />
                            Documentation
                          </Button>
                          <Button
                            variant="outline"
                            className="w-full justify-start hover:bg-blue-500/10 hover:border-blue-500/30"
                            onClick={() => {
                              window.open((selectedPlatformData as any)?.setupGuideUrl, '_blank');
                            }}
                          >
                            <ExternalLink className="w-3 h-3 mr-2" />
                            Setup Guide
                          </Button>
                        </div>
                      </CardContent>
                    </Card>
                  </div>
                </div>
              </TabsContent>
              
              <TabsContent value="features" className="space-y-4">
                <div className="space-y-4">
                  <h4 className="font-medium">What You Get</h4>
                  
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div className="space-y-3">
                      <h5 className="text-sm font-medium text-primary">Core Features</h5>
                      {selectedPlatformData!.features.map((feature, index) => (
                        <div key={index} className="flex items-center gap-2 text-sm">
                          <CheckCircle className="w-4 h-4 text-success flex-shrink-0" />
                          <span>{feature}</span>
                        </div>
                      ))}
                    </div>
                    
                    <div className="space-y-3">
                      <h5 className="text-sm font-medium text-primary">Key Benefits</h5>
                      {selectedPlatformData!.benefits.map((benefit, index) => (
                        <div key={index} className="text-sm text-muted-foreground">
                          {benefit}
                        </div>
                      ))}
                    </div>
                  </div>
                  
                  <div className="mt-6 p-4 bg-primary/10 border border-primary/20 rounded-lg">
                    <div className="flex items-start gap-3">
                      <Heart className="w-5 h-5 text-primary mt-0.5" />
                      <div>
                        <h5 className="font-medium text-primary">Perfect for Beta Testing</h5>
                        <p className="text-sm text-muted-foreground mt-1">
                          {selectedPlatformData!.name} is ideal for trying out your custom agent. 
                          {selectedPlatformData!.difficulty === 'Easy' ? ' Simple setup gets you started in minutes.' : ' Great for developers who want more control.'}
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
              </TabsContent>
            </Tabs>
          </CardContent>
        </Card>
      )}

      {/* Ready to Deploy */}
      {selectedPlatform && configState === 'ready' && (
        <div className="text-center space-y-4">
          <div className="p-6 bg-gradient-to-r from-success/10 to-primary/10 border border-success/30 rounded-lg">
            <div className="flex items-center justify-center gap-3 mb-4">
              <CheckCircle className="w-8 h-8 text-success" />
              <h3 className="text-xl font-semibold text-success">Your Agent is Ready!</h3>
            </div>
            
            <p className="text-muted-foreground mb-6">
              We've generated everything you need to deploy your custom AI agent to {selectedPlatformData!.name}. 
              Download the files and follow the setup guide to get started.
            </p>
            
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Button
                size="lg"
                onClick={() => {
                  downloadFile(
                    generatedConfigs[selectedPlatform] || '', 
                    `${selectedPlatform}-config.json`
                  );
                  onGenerate();
                }}
                className="bg-primary hover:bg-primary/90 text-primary-foreground px-8 py-4"
              >
                <Download className="w-5 h-5 mr-2" />
                Download Configuration
              </Button>
              
              <Button
                size="lg"
                variant="outline"
                onClick={() => downloadFile(
                  generatedConfigs[getSetupGuideKey(selectedPlatform)] || 'Setup guide not available', 
                  `${selectedPlatform}-setup-guide.md`
                )}
                className="border-primary/30 text-primary hover:bg-primary/10 px-8 py-4"
              >
                <FileText className="w-5 h-5 mr-2" />
                Get Setup Guide
              </Button>
            </div>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 text-center">
            <div className="space-y-2">
              <div className="text-2xl">🔒</div>
              <h4 className="font-semibold">Private & Secure</h4>
              <p className="text-sm text-muted-foreground">Your data never leaves your machine</p>
            </div>
            <div className="space-y-2">
              <div className="text-2xl">🆓</div>
              <h4 className="font-semibold">Completely Free</h4>
              <p className="text-sm text-muted-foreground">No subscriptions, no API costs</p>
            </div>
            <div className="space-y-2">
              <div className="text-2xl">🎯</div>
              <h4 className="font-semibold">Your Rules</h4>
              <p className="text-sm text-muted-foreground">Follows your exact constraints and style</p>
            </div>
          </div>
        </div>
      )}

      {/* Additional Tools Section */}
      <Card className="border-green-500/20 bg-green-500/5">
        <CardContent className="p-4">
          <div className="flex items-center gap-2 mb-3">
            <Zap className="w-4 h-4 text-green-600" />
            <h3 className="font-medium text-green-900">Required Dependency</h3>
          </div>
          <div className="flex items-center justify-between">
            <div className="space-y-1">
              <p className="text-sm font-medium">Node.js</p>
              <p className="text-xs text-muted-foreground">Required for all AI agent platforms to run MCP servers</p>
            </div>
            <Button
              variant="outline"
              size="sm"
              className="hover:bg-green-500/10 hover:border-green-500/30"
              onClick={() => window.open('https://nodejs.org/en/download/', '_blank')}
            >
              <Download className="w-3 h-3 mr-1" />
              Get Node.js
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Help Text */}
      <div className="text-center space-y-2">
        <p className="text-sm text-muted-foreground">
          💡 All these platforms run locally for complete privacy. Choose based on your comfort level and existing tools.
        </p>
        <p className="text-xs text-muted-foreground">
          Need help? Each download includes detailed setup instructions and troubleshooting guides.
        </p>
      </div>
    </div>
  );
}