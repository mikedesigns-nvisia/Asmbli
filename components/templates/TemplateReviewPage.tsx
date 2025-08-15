import { useState, useEffect } from 'react';
import { Button } from '../ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Separator } from '../ui/separator';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { ScrollArea } from '../ui/scroll-area';
import { 
  ArrowLeft, 
  Play, 
  Settings, 
  Shield, 
  FileText, 
  Download, 
  Cloud,
  CheckCircle,
  AlertCircle,
  Info,
  Zap,
  Code,
  Palette,
  Globe,
  Lock,
  Upload,
  Copy,
  Check,
  Eye
} from 'lucide-react';
import { AgentTemplate } from '../../types/agent-templates';
import { WizardData } from '../../types/wizard';
import { generatePrompt } from '../../utils/promptGenerator';
import { generateDeploymentConfigs } from '../../utils/deploymentGenerator';

interface TemplateReviewPageProps {
  template: AgentTemplate;
  onBack: () => void;
  onDeploy: (wizardData: WizardData) => void;
  onCustomize: (wizardData: WizardData) => void;
}

export function TemplateReviewPage({ 
  template, 
  onBack, 
  onDeploy, 
  onCustomize 
}: TemplateReviewPageProps) {
  const [wizardData, setWizardData] = useState<WizardData | null>(null);
  const [deploymentConfigs, setDeploymentConfigs] = useState<Record<string, string>>({});
  const [isGenerating, setIsGenerating] = useState(false);
  const [showDeploymentPreview, setShowDeploymentPreview] = useState(false);
  const [copiedConfig, setCopiedConfig] = useState<string | null>(null);
  const [promptOutput, setPromptOutput] = useState<string>('');

  // Generate and display prompt output when wizardData changes
  useEffect(() => {
    if (wizardData) {
      const prompt = generatePrompt(wizardData);
      setPromptOutput(prompt);
    }
  }, [wizardData]);

  // Convert agent template to wizard data
  useEffect(() => {
    const convertedData: WizardData = {
      // Agent Profile
      agentName: template.config.agentName,
      agentDescription: template.config.agentDescription,
      primaryPurpose: template.config.primaryPurpose,
      targetEnvironment: 'production',
      deploymentTargets: template.config.recommendedDeployment || [],
      
      // Extensions - will be populated from extension IDs
      extensions: [], // TODO: Convert MCP IDs to extension objects
      
      // Security
      security: {
        authMethod: template.config.securitySettings?.authMethod === 'oauth' ? 'oauth' : 
                    template.config.securitySettings?.authMethod === 'enterprise' ? 'mtls' : null,
        permissions: template.config.securitySettings?.permissions || [],
        vaultIntegration: template.config.securitySettings?.localOnly ? 'none' : 'hashicorp',
        auditLogging: !template.config.securitySettings?.localOnly,
        rateLimiting: true,
        sessionTimeout: 3600
      },
      
      // Behavior
      tone: 'professional',
      responseLength: 3,
      constraints: [],
      constraintDocs: {},
      
      // Testing
      testResults: {
        connectionTests: {},
        latencyTests: {},
        securityValidation: true,
        overallStatus: 'passed'
      },
      
      // Deployment
      deploymentFormat: 'docker'
    };

    setWizardData(convertedData);
  }, [template]);

  // Generate prompt and deployment configs
  useEffect(() => {
    if (!wizardData) return;

    setIsGenerating(true);
    
    // Generate prompt
    const prompt = generatePrompt(wizardData);
    setPromptOutput(prompt);
    
    // Generate deployment configs
    const configs = generateDeploymentConfigs(wizardData);
    setDeploymentConfigs(configs);
    
    setIsGenerating(false);
  }, [wizardData]);

  const getAuthMethodIcon = (method: string | null) => {
    switch (method) {
      case 'oauth': return <Globe className="w-4 h-4" />;
      case 'mtls': return <Shield className="w-4 h-4" />;
      default: return <Lock className="w-4 h-4" />;
    }
  };

  const getDeploymentIcon = (target: string) => {
    switch (target) {
      case 'docker': return <Code className="w-4 h-4" />;
      case 'kubernetes': return <Cloud className="w-4 h-4" />;
      case 'claude-desktop': return <Settings className="w-4 h-4" />;
      default: return <FileText className="w-4 h-4" />;
    }
  };

  if (!wizardData) {
    return (
      <div className="flex items-center justify-center min-h-96">
        <div className="text-center">
          <div className="animate-spin w-8 h-8 border-2 border-primary border-t-transparent rounded-full mx-auto mb-4"></div>
          <p className="text-muted-foreground">Loading template configuration...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="content-width mx-auto px-4 py-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button variant="ghost" onClick={onBack} className="flex items-center gap-2">
            <ArrowLeft className="w-4 h-4" />
            Back to Templates
          </Button>
          <div>
            <h1 className="text-3xl font-bold flex items-center gap-3">
              <span className="text-2xl">{template.icon}</span>
              {template.name}
            </h1>
            <p className="text-muted-foreground">
              Premium pre-optimized {template.targetRole.replace('_', ' ')} agent template with enterprise-grade settings
            </p>
          </div>
        </div>
        
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2">
            <Badge variant="outline" className="flex items-center gap-1">
              <CheckCircle className="w-3 h-3 text-green-500" />
              Premium Template
            </Badge>
            <Badge variant="outline" className="bg-primary/10">
              {template.targetRole.replace('_', ' ')}
            </Badge>
          </div>
          
          {/* Premium Pricing Badge */}
          <div className="text-right">
            <div className="text-2xl font-bold text-primary">$29/mo</div>
            <div className="text-xs text-muted-foreground">per agent instance</div>
          </div>
        </div>
      </div>

      {/* Template Overview */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Info className="w-5 h-5" />
            Template Overview
          </CardTitle>
          <CardDescription>
            {template.description}
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <h4 className="font-medium mb-2">Category</h4>
              <Badge variant="outline" className="capitalize">
                {template.category}
              </Badge>
            </div>
            <div>
              <h4 className="font-medium mb-2">Primary Purpose</h4>
              <Badge variant="outline" className="capitalize">
                {template.config.primaryPurpose}
              </Badge>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Premium Value Proposition */}
      <Card className="border-primary/20 bg-primary/5">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Badge className="bg-primary text-primary-foreground">
              Premium Value
            </Badge>
            What's Included
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-3">
              <div className="flex items-start gap-3">
                <CheckCircle className="w-5 h-5 text-green-500 mt-0.5" />
                <div>
                  <p className="font-medium">Pre-optimized Configuration</p>
                  <p className="text-sm text-muted-foreground">Enterprise-grade settings fine-tuned by experts</p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <CheckCircle className="w-5 h-5 text-green-500 mt-0.5" />
                <div>
                  <p className="font-medium">Advanced MCP Integrations</p>
                  <p className="text-sm text-muted-foreground">{template.config.requiredMcps.length} premium MCP servers included</p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <CheckCircle className="w-5 h-5 text-green-500 mt-0.5" />
                <div>
                  <p className="font-medium">Production-Ready Security</p>
                  <p className="text-sm text-muted-foreground">Enterprise auth, audit logging, and vault integration</p>
                </div>
              </div>
            </div>
            <div className="space-y-3">
              <div className="flex items-start gap-3">
                <CheckCircle className="w-5 h-5 text-green-500 mt-0.5" />
                <div>
                  <p className="font-medium">Priority Support</p>
                  <p className="text-sm text-muted-foreground">24/7 technical support and deployment assistance</p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <CheckCircle className="w-5 h-5 text-green-500 mt-0.5" />
                <div>
                  <p className="font-medium">Multi-Platform Deployment</p>
                  <p className="text-sm text-muted-foreground">Docker, Kubernetes, and cloud platform configs</p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <CheckCircle className="w-5 h-5 text-green-500 mt-0.5" />
                <div>
                  <p className="font-medium">Regular Updates</p>
                  <p className="text-sm text-muted-foreground">Continuous optimization and new feature integration</p>
                </div>
              </div>
            </div>
          </div>
          
          <Separator className="my-4" />
          
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-muted-foreground">Compare to building from scratch:</p>
              <p className="text-lg font-semibold text-green-600">Save 40+ hours of configuration time</p>
            </div>
            <div className="text-right">
              <p className="text-sm text-muted-foreground line-through">$99/mo custom development</p>
              <p className="text-2xl font-bold text-primary">$29/mo</p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Configuration Details */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Agent Configuration */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Palette className="w-5 h-5" />
              Agent Configuration
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <h4 className="font-medium mb-2">Agent Name</h4>
              <p className="text-sm text-muted-foreground">{wizardData.agentName}</p>
            </div>
            <div>
              <h4 className="font-medium mb-2">Description</h4>
              <p className="text-sm text-muted-foreground">{wizardData.agentDescription}</p>
            </div>
            <div>
              <h4 className="font-medium mb-2">Target Environment</h4>
              <Badge variant="outline">{wizardData.targetEnvironment}</Badge>
            </div>
          </CardContent>
        </Card>

        {/* Security Configuration */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Shield className="w-5 h-5" />
              Security Configuration
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <h4 className="font-medium mb-2 flex items-center gap-2">
                {getAuthMethodIcon(wizardData.security.authMethod)}
                Authentication
              </h4>
              <Badge variant="outline">
                {wizardData.security.authMethod || 'None'}
              </Badge>
            </div>
            <div>
              <h4 className="font-medium mb-2">Permissions</h4>
              <div className="flex flex-wrap gap-1">
                {wizardData.security.permissions.map(perm => (
                  <Badge key={perm} variant="outline" className="text-xs">
                    {perm}
                  </Badge>
                ))}
              </div>
            </div>
            <div>
              <h4 className="font-medium mb-2">Security Features</h4>
              <div className="space-y-1 text-sm">
                <div className="flex items-center gap-2">
                  {wizardData.security.auditLogging ? 
                    <CheckCircle className="w-3 h-3 text-green-500" /> : 
                    <AlertCircle className="w-3 h-3 text-yellow-500" />
                  }
                  Audit Logging
                </div>
                <div className="flex items-center gap-2">
                  {wizardData.security.rateLimiting ? 
                    <CheckCircle className="w-3 h-3 text-green-500" /> : 
                    <AlertCircle className="w-3 h-3 text-yellow-500" />
                  }
                  Rate Limiting
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Extensions & Integrations */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Zap className="w-5 h-5" />
            Extensions & Integrations
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <h4 className="font-medium mb-3">Required MCPs</h4>
              <div className="space-y-2">
                {template.config.requiredMcps.map(mcp => (
                  <div key={mcp} className="flex items-center gap-2">
                    <CheckCircle className="w-4 h-4 text-green-500" />
                    <span className="text-sm">{mcp}</span>
                  </div>
                ))}
              </div>
            </div>
            <div>
              <h4 className="font-medium mb-3">Optional MCPs</h4>
              <div className="space-y-2">
                {(template.config.optionalMcps || []).map(mcp => (
                  <div key={mcp} className="flex items-center gap-2">
                    <Info className="w-4 h-4 text-blue-500" />
                    <span className="text-sm">{mcp}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Special Features */}
      {template.config.specialFeatures && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Upload className="w-5 h-5" />
              Special Features
            </CardTitle>
          </CardHeader>
          <CardContent>
            {template.config.specialFeatures.uploadSupport && (
              <div className="space-y-3">
                <h4 className="font-medium">File Upload Support</h4>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm text-muted-foreground mb-2">Supported File Types:</p>
                    <div className="flex flex-wrap gap-1">
                      {template.config.specialFeatures.uploadSupport.allowedTypes.map(type => (
                        <Badge key={type} variant="outline" className="text-xs">
                          {type}
                        </Badge>
                      ))}
                    </div>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground mb-2">Max File Size:</p>
                    <Badge variant="outline">
                      {template.config.specialFeatures.uploadSupport.maxFileSize}
                    </Badge>
                  </div>
                </div>
                <p className="text-sm text-muted-foreground">
                  {template.config.specialFeatures.uploadSupport.description}
                </p>
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {/* Deployment Options */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center justify-between">
            <span className="flex items-center gap-2">
              <Cloud className="w-5 h-5" />
              Deployment Options
            </span>
            {Object.keys(deploymentConfigs).length > 0 && (
              <Button
                variant="outline"
                size="sm"
                onClick={() => setShowDeploymentPreview(!showDeploymentPreview)}
                className="flex items-center gap-2"
              >
                <Eye className="w-4 h-4" />
                {showDeploymentPreview ? 'Hide' : 'Preview'} Configs
              </Button>
            )}
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {wizardData.deploymentTargets.map(target => (
              <div key={target} className="flex items-center gap-3 p-3 border rounded-lg">
                {getDeploymentIcon(target)}
                <div>
                  <p className="font-medium capitalize">{target.replace('-', ' ')}</p>
                  <p className="text-xs text-muted-foreground">Ready to deploy</p>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Deployment Preview */}
      {showDeploymentPreview && Object.keys(deploymentConfigs).length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <FileText className="w-5 h-5" />
              Deployment Configuration Preview
            </CardTitle>
            <CardDescription>
              Review the generated configuration files before deployment
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Tabs defaultValue={promptOutput ? "prompt" : Object.keys(deploymentConfigs)[0]} className="w-full">
              <TabsList className="grid w-full" style={{ gridTemplateColumns: `repeat(${Math.min(Object.keys(deploymentConfigs).length + (promptOutput ? 1 : 0), 4)}, 1fr)` }}>
                {promptOutput && (
                  <TabsTrigger value="prompt" className="text-xs">
                    Generated Prompt
                  </TabsTrigger>
                )}
                {Object.keys(deploymentConfigs).map(configKey => {
                  // Extract display name from config key
                  const displayName = configKey.includes('docker') ? 'Docker' :
                                    configKey.includes('kubernetes') ? 'Kubernetes' :
                                    configKey.includes('claude') ? 'Claude Desktop' :
                                    configKey.includes('railway') ? 'Railway' :
                                    configKey.includes('render') ? 'Render' :
                                    configKey.includes('vercel') ? 'Vercel' :
                                    configKey.includes('mcp') && configKey.includes('figma') ? 'Figma MCP' :
                                    configKey.includes('mcp') && configKey.includes('filesystem') ? 'File MCP' :
                                    configKey.includes('mcp') && configKey.includes('git') ? 'Git MCP' :
                                    configKey.replace(/_/g, ' ').replace('.', ' ');
                  
                  return (
                    <TabsTrigger key={configKey} value={configKey} className="text-xs">
                      {displayName}
                    </TabsTrigger>
                  );
                })}
              </TabsList>
              
              {promptOutput && (
                <TabsContent value="prompt" className="mt-4">
                  <div className="space-y-3">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <FileText className="w-4 h-4 text-muted-foreground" />
                        <span className="text-sm font-medium">Generated Agent Prompt</span>
                      </div>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => navigator.clipboard.writeText(promptOutput)}
                      >
                        <Copy className="w-4 h-4 mr-2" />
                        Copy
                      </Button>
                    </div>
                    <pre className="bg-muted p-4 rounded-lg text-sm overflow-x-auto whitespace-pre-wrap">
                      {promptOutput}
                    </pre>
                  </div>
                </TabsContent>
              )}
              
              {Object.entries(deploymentConfigs).map(([configKey, configContent]) => (
                <TabsContent key={configKey} value={configKey} className="mt-4">
                  <div className="space-y-3">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <Code className="w-4 h-4 text-muted-foreground" />
                        <span className="text-sm font-medium">{configKey}</span>
                      </div>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => {
                          navigator.clipboard.writeText(configContent);
                          setCopiedConfig(configKey);
                          setTimeout(() => setCopiedConfig(null), 2000);
                        }}
                        className="flex items-center gap-2"
                      >
                        {copiedConfig === configKey ? (
                          <>
                            <Check className="w-3 h-3" />
                            Copied
                          </>
                        ) : (
                          <>
                            <Copy className="w-3 h-3" />
                            Copy
                          </>
                        )}
                      </Button>
                    </div>
                    
                    <ScrollArea className="h-96 w-full rounded-md border bg-muted/30">
                      <pre className="p-4 text-xs font-mono whitespace-pre-wrap break-all">
                        {configContent}
                      </pre>
                    </ScrollArea>
                  </div>
                </TabsContent>
              ))}
            </Tabs>
          </CardContent>
        </Card>
      )}

      {/* Action Buttons */}
      <div className="flex items-center justify-between pt-6 border-t">
        <Button variant="outline" onClick={() => onCustomize(wizardData)}>
          <Settings className="w-4 h-4 mr-2" />
          Customize Settings
        </Button>
        
        <div className="flex items-center gap-3">
          <Button 
            variant="outline" 
            disabled={isGenerating || Object.keys(deploymentConfigs).length === 0}
            onClick={() => {
              // Create a zip file with all configs
              const configs = Object.entries(deploymentConfigs);
              if (configs.length === 1) {
                // Single file - download directly
                const [filename, content] = configs[0];
                const blob = new Blob([content], { type: 'text/plain' });
                const url = URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = filename;
                a.click();
                URL.revokeObjectURL(url);
              } else {
                // Multiple files - create a simple text file with all configs
                let combinedContent = `# ${template.name} - Deployment Configurations\n\n`;
                configs.forEach(([filename, content]) => {
                  combinedContent += `\n## ${filename}\n\n${content}\n\n${'='.repeat(80)}\n`;
                });
                const blob = new Blob([combinedContent], { type: 'text/plain' });
                const url = URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = `${template.id}-deployment-configs.txt`;
                a.click();
                URL.revokeObjectURL(url);
              }
            }}
          >
            <Download className="w-4 h-4 mr-2" />
            Export Config
          </Button>
          <Button 
            onClick={() => onDeploy(wizardData)} 
            disabled={isGenerating}
            className="min-w-32 bg-primary hover:bg-primary/90"
            size="lg"
          >
            {isGenerating ? (
              <div className="flex items-center gap-2">
                <div className="animate-spin w-4 h-4 border-2 border-white border-t-transparent rounded-full"></div>
                Preparing...
              </div>
            ) : (
              <>
                <Play className="w-4 h-4 mr-2" />
                Deploy Premium Agent - $29/mo
              </>
            )}
          </Button>
        </div>
      </div>
    </div>
  );
}