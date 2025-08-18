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

const CHATMCP_PLATFORM = {
  id: 'chatmcp',
  name: 'ChatMCP',
  description: 'Native MCP client with cross-platform AI chat interface',
  icon: MessageSquare,
  difficulty: 'Easy',
  setupTime: '3 minutes',
  downloadUrl: 'https://github.com/daodao97/chatmcp',
  downloadLinks: {
    windows: 'https://github.com/daodao97/chatmcp/releases/latest/download/chatmcp-windows.exe',
    mac: 'https://github.com/daodao97/chatmcp/releases/latest/download/chatmcp-macos.dmg',
    linux: 'https://github.com/daodao97/chatmcp/releases/latest/download/chatmcp-linux.AppImage'
  },
  docsUrl: 'https://github.com/daodao97/chatmcp',
  features: [
    'Native MCP protocol support',
    'Cross-platform compatibility', 
    'Local data synchronization',
    'Multiple LLM provider support',
    'Flutter-based modern UI'
  ],
  benefits: [
    '🚀 Purpose-built for MCP servers',
    '🔒 Your data stays local',
    '⚡ Lightning-fast Flutter UI',
    '🌐 Works on all platforms',
    '🎛️ Full control over AI models'
  ],
  requirements: [
    'ChatMCP v1.0+',
    'Node.js 18+ (for MCP servers)',
    '4GB+ RAM recommended'
  ]
};

export function MVPStep5Deploy({ wizardData, deployment, onDeploymentChange, onGenerate }: MVPStep5DeployProps) {
  const [selectedPlatform, setSelectedPlatform] = useState(deployment.platform || 'chatmcp');
  const [generatedConfigs, setGeneratedConfigs] = useState<Record<string, string>>({});
  const [configState, setConfigState] = useState<'idle' | 'generating' | 'ready'>('idle');

  // Auto-select ChatMCP on component mount
  React.useEffect(() => {
    if (!selectedPlatform || selectedPlatform !== 'chatmcp') {
      handlePlatformSelect('chatmcp');
    }
  }, []);

  const handlePlatformSelect = (platformId: string) => {
    setSelectedPlatform(platformId);
    
    if (platformId && wizardData) {
      setConfigState('generating');
      
      try {
        console.log('MVPStep5Deploy: Generating ChatMCP configs...');
        const configs = generateDeploymentConfigs(wizardData);
        console.log('MVPStep5Deploy: Generated configs:', Object.keys(configs));
        
        setGeneratedConfigs(configs);
        onDeploymentChange({
          platform: platformId,
          configuration: configs['chatmcp-config.json']
        });
        setConfigState('ready');
      } catch (error) {
        console.error('ChatMCP config generation failed:', error);
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

  const downloadAllFiles = () => {
    // Download all the generated files
    Object.entries(generatedConfigs).forEach(([filename, content]) => {
      setTimeout(() => downloadFile(content, filename), 100);
    });
  };

  return (
    <div className="space-y-6">
      <div className="text-center space-y-2">
        <h2 className="text-2xl font-bold">Deploy with ChatMCP</h2>
        <p className="text-muted-foreground">
          The next-generation AI chat client built specifically for MCP servers
        </p>
      </div>

      {/* Why ChatMCP */}
      <Card className="border-blue-500/20 bg-blue-500/5">
        <CardContent className="p-6">
          <div className="flex items-center gap-3 mb-4">
            <div className="p-2 bg-blue-500/20 rounded-lg">
              <MessageSquare className="w-6 h-6 text-blue-600" />
            </div>
            <div>
              <h3 className="font-semibold text-blue-900">Why ChatMCP?</h3>
              <p className="text-sm text-blue-700">Purpose-built for Model Context Protocol</p>
            </div>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <h4 className="font-medium text-blue-900">🚀 Native MCP Support</h4>
              <p className="text-sm text-blue-700">Unlike other AI clients, ChatMCP was designed from the ground up for MCP servers</p>
            </div>
            <div className="space-y-2">
              <h4 className="font-medium text-blue-900">⚡ Lightning Fast</h4>
              <p className="text-sm text-blue-700">Flutter-based UI with native performance on all platforms</p>
            </div>
            <div className="space-y-2">
              <h4 className="font-medium text-blue-900">🔒 Privacy First</h4>
              <p className="text-sm text-blue-700">Your conversations and data stay completely local</p>
            </div>
            <div className="space-y-2">
              <h4 className="font-medium text-blue-900">🌐 True Cross-Platform</h4>
              <p className="text-sm text-blue-700">Windows, macOS, Linux, iOS, Android, and Web</p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Quick Download Links */}
      <Card className="border-green-500/20 bg-green-500/5">
        <CardContent className="p-4">
          <div className="flex items-center gap-2 mb-3">
            <Download className="w-4 h-4 text-green-600" />
            <h3 className="font-medium text-green-900">Quick Download ChatMCP</h3>
            <Badge variant="outline" className="bg-green-500/10 text-green-600 border-green-500/30 text-xs">
              {(() => {
                const userOS = detectOS() as keyof typeof OS_INFO;
                const osInfo = OS_INFO[userOS];
                return `${osInfo.icon} ${osInfo.name}`;
              })()}
            </Badge>
          </div>
          <div className="flex flex-wrap gap-2 mb-3">
            {Object.entries(CHATMCP_PLATFORM.downloadLinks).map(([os, link]) => {
              const osInfo = OS_INFO[os as keyof typeof OS_INFO];
              return (
                <Button
                  key={os}
                  variant="outline"
                  size="sm"
                  className="text-xs hover:bg-green-500/10 hover:border-green-500/30"
                  onClick={() => window.open(link, '_blank')}
                >
                  {osInfo.icon} {osInfo.name}
                </Button>
              );
            })}
          </div>
          <div className="flex items-center justify-between">
            <p className="text-xs text-muted-foreground">
              💡 Download ChatMCP first, then generate your agent configuration below
            </p>
            <Button
              variant="ghost"
              size="sm"
              className="text-xs text-green-600 hover:bg-green-500/10"
              onClick={() => {
                Object.values(CHATMCP_PLATFORM.downloadLinks).forEach((link, index) => {
                  setTimeout(() => window.open(link, '_blank'), index * 500);
                });
              }}
            >
              <Download className="w-3 h-3 mr-1" />
              Download All
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Platform Card */}
      <Card className="border-primary/30 bg-gradient-to-br from-primary/10 via-primary/5 to-transparent shadow-lg ring-2 ring-primary/20">
        <CardHeader className="text-center pb-4">
          <div className="w-16 h-16 mx-auto rounded-full flex items-center justify-center mb-3 bg-primary/20">
            <MessageSquare className="w-8 h-8 text-primary" />
          </div>
          
          <div className="space-y-2">
            <CardTitle className="text-xl">{CHATMCP_PLATFORM.name}</CardTitle>
            <CardDescription className="text-sm leading-relaxed">
              {CHATMCP_PLATFORM.description}
            </CardDescription>
          </div>
          
          <div className="flex justify-center gap-2">
            <Badge variant="outline" className="text-xs border-green-500/30 text-green-600 bg-green-500/10">
              {CHATMCP_PLATFORM.difficulty}
            </Badge>
            <Badge variant="outline" className="text-xs border-blue-500/30 text-blue-600 bg-blue-500/10">
              <Clock className="w-3 h-3 mr-1" />
              {CHATMCP_PLATFORM.setupTime}
            </Badge>
          </div>
        </CardHeader>
        
        <CardContent className="space-y-4">
          {/* Key Benefits */}
          <div className="space-y-2">
            <h4 className="font-medium text-sm">Why This Platform?</h4>
            <div className="space-y-1">
              {CHATMCP_PLATFORM.benefits.slice(0, 3).map((benefit, index) => (
                <div key={index} className="text-xs text-muted-foreground">
                  {benefit}
                </div>
              ))}
            </div>
          </div>
          
          {/* Selection Status */}
          <div className="flex items-center justify-center pt-2 border-t border-border/50">
            <div className="flex items-center gap-2 text-primary font-medium text-sm">
              <CheckCircle className="w-4 h-4" />
              Selected & Ready
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Configuration & Setup */}
      <Card className="border-primary/30 bg-gradient-to-r from-primary/5 to-blue-500/5">
        <CardHeader>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-primary/20 rounded-lg">
                <MessageSquare className="w-6 h-6 text-primary" />
              </div>
              <div>
                <CardTitle className="text-xl">ChatMCP Agent Package</CardTitle>
                <CardDescription className="text-base">
                  Complete deployment package for ChatMCP
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
                  <h4 className="font-medium">Generated ChatMCP Package</h4>
                  <Badge variant="outline">
                    MCP Protocol
                  </Badge>
                </div>
                
                {configState === 'generating' ? (
                  <div className="flex items-center justify-center py-8">
                    <div className="flex items-center gap-3">
                      <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-primary"></div>
                      <span className="text-muted-foreground">Generating ChatMCP configuration...</span>
                    </div>
                  </div>
                ) : (
                  <div className="space-y-4">
                    <div className="bg-muted/50 p-4 rounded-lg border border-primary/20">
                      <h5 className="font-medium mb-2">Package Contents:</h5>
                      <ul className="text-sm space-y-1 text-muted-foreground">
                        <li>✅ chatmcp-config.json - MCP server configuration</li>
                        <li>✅ install-chatmcp.sh - Unix/macOS installer</li>
                        <li>✅ install-chatmcp.bat - Windows installer</li>
                        <li>✅ chatmcp-setup.md - Complete setup guide</li>
                        <li>✅ environment-setup.md - API key configuration</li>
                      </ul>
                    </div>
                    
                    <div className="flex flex-col sm:flex-row gap-3">
                      <Button
                        onClick={downloadAllFiles}
                        className="flex items-center gap-2"
                      >
                        <Download className="w-4 h-4" />
                        Download Complete Package
                      </Button>
                      
                      <Button
                        variant="outline"
                        onClick={() => downloadFile(
                          generatedConfigs['chatmcp-config.json'] || '{}', 
                          'chatmcp-config.json'
                        )}
                        className="flex items-center gap-2"
                      >
                        <FileText className="w-4 h-4" />
                        Config Only
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
                  <div className="flex items-start gap-3">
                    <div className="w-6 h-6 rounded-full bg-primary/20 flex items-center justify-center text-primary text-sm font-medium">
                      1
                    </div>
                    <div className="flex-1">
                      <p className="text-sm font-medium">Download ChatMCP</p>
                      <p className="text-xs text-muted-foreground">Get the latest version for your platform</p>
                    </div>
                  </div>
                  
                  <div className="flex items-start gap-3">
                    <div className="w-6 h-6 rounded-full bg-primary/20 flex items-center justify-center text-primary text-sm font-medium">
                      2
                    </div>
                    <div className="flex-1">
                      <p className="text-sm font-medium">Run installer script</p>
                      <p className="text-xs text-muted-foreground">Install MCP servers and dependencies</p>
                    </div>
                  </div>
                  
                  <div className="flex items-start gap-3">
                    <div className="w-6 h-6 rounded-full bg-primary/20 flex items-center justify-center text-primary text-sm font-medium">
                      3
                    </div>
                    <div className="flex-1">
                      <p className="text-sm font-medium">Load configuration</p>
                      <p className="text-xs text-muted-foreground">Import chatmcp-config.json in ChatMCP settings</p>
                    </div>
                  </div>
                  
                  <div className="flex items-start gap-3">
                    <div className="w-6 h-6 rounded-full bg-success/20 flex items-center justify-center text-success text-sm font-medium">
                      ✓
                    </div>
                    <div className="flex-1">
                      <p className="text-sm font-medium">Start chatting!</p>
                      <p className="text-xs text-muted-foreground">Your agent is ready with all MCP servers</p>
                    </div>
                  </div>
                </div>
                
                <Alert>
                  <FileText className="h-4 w-4" />
                  <AlertDescription>
                    Complete setup instructions included in the downloaded package.
                  </AlertDescription>
                </Alert>
              </div>
            </TabsContent>
            
            <TabsContent value="features" className="space-y-4">
              <div className="space-y-4">
                <h4 className="font-medium">What You Get</h4>
                
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-3">
                    <h5 className="text-sm font-medium text-primary">Core Features</h5>
                    {CHATMCP_PLATFORM.features.map((feature, index) => (
                      <div key={index} className="flex items-center gap-2 text-sm">
                        <CheckCircle className="w-4 h-4 text-success flex-shrink-0" />
                        <span>{feature}</span>
                      </div>
                    ))}
                  </div>
                  
                  <div className="space-y-3">
                    <h5 className="text-sm font-medium text-primary">Key Benefits</h5>
                    {CHATMCP_PLATFORM.benefits.map((benefit, index) => (
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
                      <h5 className="font-medium text-primary">Perfect for Modern AI</h5>
                      <p className="text-sm text-muted-foreground mt-1">
                        ChatMCP is the future of AI chat clients - built specifically for the MCP protocol.
                        Get the best performance and features for your custom agent.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </TabsContent>
          </Tabs>
        </CardContent>
      </Card>

      {/* Ready to Deploy */}
      {configState === 'ready' && (
        <div className="text-center space-y-4">
          <div className="p-6 bg-gradient-to-r from-success/10 to-primary/10 border border-success/30 rounded-lg">
            <div className="flex items-center justify-center gap-3 mb-4">
              <CheckCircle className="w-8 h-8 text-success" />
              <h3 className="text-xl font-semibold text-success">Your ChatMCP Agent is Ready!</h3>
            </div>
            
            <p className="text-muted-foreground mb-6">
              We've generated everything you need to deploy your custom AI agent with ChatMCP. 
              Download the complete package and follow the setup guide to get started.
            </p>
            
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Button
                size="lg"
                onClick={() => {
                  downloadAllFiles();
                  onGenerate();
                }}
                className="bg-primary hover:bg-primary/90 text-primary-foreground px-8 py-4"
              >
                <Download className="w-5 h-5 mr-2" />
                Download Complete Package
              </Button>
              
              <Button
                size="lg"
                variant="outline"
                onClick={() => window.open(CHATMCP_PLATFORM.docsUrl, '_blank')}
                className="border-primary/30 text-primary hover:bg-primary/10 px-8 py-4"
              >
                <ExternalLink className="w-5 h-5 mr-2" />
                ChatMCP Documentation
              </Button>
            </div>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 text-center">
            <div className="space-y-2">
              <div className="text-2xl">🚀</div>
              <h4 className="font-semibold">Next-Gen MCP</h4>
              <p className="text-sm text-muted-foreground">Built specifically for Model Context Protocol</p>
            </div>
            <div className="space-y-2">
              <div className="text-2xl">⚡</div>
              <h4 className="font-semibold">Lightning Fast</h4>
              <p className="text-sm text-muted-foreground">Flutter-based native performance</p>
            </div>
            <div className="space-y-2">
              <div className="text-2xl">🌐</div>
              <h4 className="font-semibold">True Cross-Platform</h4>
              <p className="text-sm text-muted-foreground">Works everywhere you do</p>
            </div>
          </div>
        </div>
      )}

      {/* Node.js Requirement */}
      <Card className="border-orange-500/20 bg-orange-500/5">
        <CardContent className="p-4">
          <div className="flex items-center gap-2 mb-3">
            <Zap className="w-4 h-4 text-orange-600" />
            <h3 className="font-medium text-orange-900">Required Dependency</h3>
          </div>
          <div className="flex items-center justify-between">
            <div className="space-y-1">
              <p className="text-sm font-medium">Node.js 18+</p>
              <p className="text-xs text-muted-foreground">Required for MCP server execution</p>
            </div>
            <Button
              variant="outline"
              size="sm"
              className="hover:bg-orange-500/10 hover:border-orange-500/30"
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
          🚀 ChatMCP is the future of AI chat - purpose-built for MCP servers with native performance.
        </p>
        <p className="text-xs text-muted-foreground">
          Your complete agent package includes everything needed for deployment.
        </p>
      </div>
    </div>
  );
}