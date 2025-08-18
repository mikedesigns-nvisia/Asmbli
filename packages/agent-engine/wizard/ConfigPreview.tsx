import { useEffect, useState, useMemo } from 'react';
import { Button } from '../ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Badge } from '../ui/badge';
import { Copy, Download, Eye, Check } from 'lucide-react';
import { CopyToClipboard } from 'react-copy-to-clipboard';
import { toast } from 'sonner';
import * as yaml from 'js-yaml';
import Prism from 'prismjs';
import { ShareExportSystem } from './ShareExportSystem';
import 'prismjs/themes/prism-tomorrow.css';
import 'prismjs/components/prism-json';
import 'prismjs/components/prism-yaml';

interface MVPWizardData {
  role: 'developer' | 'creator' | 'researcher' | '';
  tools: string[];
  uploadedFiles: File[];
  extractedConstraints: string[];
  style: {
    tone: string;
    responseLength: string;
    constraints: string[];
  };
  deployment: {
    platform: string;
    configuration: any;
  };
}

interface ConfigPreviewProps {
  wizardData: MVPWizardData;
  className?: string;
}

interface AgentConfig {
  name: string;
  version: string;
  description: string;
  role: string;
  tools: string[];
  style: {
    tone: string;
    responseLength: string;
    constraints: string[];
  };
  deployment: {
    platform: string;
    configuration: any;
  };
  metadata: {
    createdAt: string;
    extractedConstraints: string[];
    totalFiles: number;
  };
}

export function ConfigPreview({ wizardData, className = '' }: ConfigPreviewProps) {
  const [copySuccess, setCopySuccess] = useState<{ [key: string]: boolean }>({});
  const [highlightedCode, setHighlightedCode] = useState<{ [key: string]: string }>({});

  const agentConfig: AgentConfig = useMemo(() => ({
    name: `${wizardData.role || 'custom'}-agent`,
    version: '1.0.0',
    description: `A custom AI agent configured for ${wizardData.role || 'general'} workflows`,
    role: wizardData.role || 'general',
    tools: wizardData.tools,
    style: wizardData.style,
    deployment: wizardData.deployment,
    metadata: {
      createdAt: new Date().toISOString(),
      extractedConstraints: wizardData.extractedConstraints,
      totalFiles: wizardData.uploadedFiles.length
    }
  }), [wizardData]);

  const jsonConfig = useMemo(() => JSON.stringify(agentConfig, null, 2), [agentConfig]);
  const yamlConfig = useMemo(() => yaml.dump(agentConfig, { indent: 2 }), [agentConfig]);

  const mcpConfig = useMemo(() => ({
    servers: wizardData.tools.reduce((acc, tool) => {
      acc[tool] = {
        command: 'node',
        args: [`./servers/${tool}/index.js`],
        env: {}
      };
      return acc;
    }, {} as Record<string, any>)
  }), [wizardData.tools]);

  const mcpJsonConfig = useMemo(() => JSON.stringify(mcpConfig, null, 2), [mcpConfig]);

  const deploymentScript = useMemo(() => {
    const platform = wizardData.deployment.platform;
    switch (platform) {
      case 'vs-code':
        return `# VS Code Claude Extension Setup
1. Install Claude extension from VS Code marketplace
2. Copy the configuration below to your settings.json
3. Restart VS Code

{
  "claude.agentConfig": ${JSON.stringify(agentConfig, null, 4)}
}`;
      case 'lm-studio':
        return `# LM Studio Setup
1. Open LM Studio
2. Go to Settings > Agent Configuration
3. Import the JSON configuration
4. Select your preferred model

# Config file location:
# ~/.lmstudio/agent-configs/${agentConfig.name}.json`;
      case 'ollama':
        return `# Ollama Setup
ollama create ${agentConfig.name} -f Modelfile

# Modelfile content:
FROM llama2
PARAMETER temperature 0.7
SYSTEM """${agentConfig.description}
Role: ${agentConfig.role}
Style: ${agentConfig.style.tone}
Tools: ${agentConfig.tools.join(', ')}
"""`;
      default:
        return `# Generic Deployment
1. Save the configuration as agent-config.json
2. Use with your preferred AI platform
3. Ensure MCP servers are properly configured`;
    }
  }, [wizardData.deployment.platform, agentConfig]);

  useEffect(() => {
    // Highlight code when configs change
    const highlightCode = () => {
      const codes = {
        json: Prism.highlight(jsonConfig, Prism.languages.json, 'json'),
        yaml: Prism.highlight(yamlConfig, Prism.languages.yaml, 'yaml'),
        mcp: Prism.highlight(mcpJsonConfig, Prism.languages.json, 'json')
      };
      setHighlightedCode(codes);
    };

    // Small delay to ensure Prism is ready
    setTimeout(highlightCode, 100);
  }, [jsonConfig, yamlConfig, mcpJsonConfig]);

  const handleCopy = (format: string, _content: string) => {
    setCopySuccess({ ...copySuccess, [format]: true });
    toast.success(`${format.toUpperCase()} configuration copied to clipboard!`);
    
    setTimeout(() => {
      setCopySuccess({ ...copySuccess, [format]: false });
    }, 2000);
  };

  const downloadConfig = (format: string, content: string, filename: string) => {
    const blob = new Blob([content], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    toast.success(`${format.toUpperCase()} configuration downloaded!`);
  };


  const getCompletionPercentage = () => {
    let completed = 0;
    let total = 5;
    
    if (wizardData.role) completed++;
    if (wizardData.tools.length > 0) completed++;
    if (wizardData.extractedConstraints.length > 0 || wizardData.uploadedFiles.length > 0) completed++;
    if (wizardData.style.tone) completed++;
    if (wizardData.deployment.platform) completed++;
    
    return Math.round((completed / total) * 100);
  };

  return (
    <Card className={`${className} shadow-lg border-border`}>
      <CardHeader className="pb-4">
        <div className="flex flex-col gap-4">
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center gap-2 text-lg text-foreground">
              <Eye className="w-4 h-4 text-primary" />
              Live Preview
            </CardTitle>
            <Badge variant="secondary" className="text-xs px-2 py-1">
              {getCompletionPercentage()}% Complete
            </Badge>
          </div>
          <p className="text-xs text-muted-foreground leading-relaxed">
            Real-time preview of your agent configuration. Updates automatically as you make changes.
          </p>
          <div className="flex gap-2">
            <ShareExportSystem wizardData={wizardData} />
          </div>
        </div>
      </CardHeader>

      <CardContent className="space-y-3">
        <Tabs defaultValue="json" className="w-full">
          <TabsList className="grid w-full grid-cols-4 h-8">
            <TabsTrigger value="json" className="text-xs">JSON</TabsTrigger>
            <TabsTrigger value="yaml" className="text-xs">YAML</TabsTrigger>
            <TabsTrigger value="mcp" className="text-xs">MCP</TabsTrigger>
            <TabsTrigger value="deployment" className="text-xs">Deploy</TabsTrigger>
          </TabsList>

          <TabsContent value="json" className="space-y-2">
            <div className="flex items-center justify-between">
              <h4 className="text-xs font-medium">Agent Configuration</h4>
              <div className="flex gap-1">
                <CopyToClipboard
                  text={jsonConfig}
                  onCopy={() => handleCopy('json', jsonConfig)}
                >
                  <Button variant="outline" size="sm" className="flex items-center gap-1 h-7 px-2">
                    {copySuccess.json ? (
                      <Check className="w-3 h-3 text-primary" />
                    ) : (
                      <Copy className="w-3 h-3" />
                    )}
                    <span className="text-xs">Copy</span>
                  </Button>
                </CopyToClipboard>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => downloadConfig('json', jsonConfig, `${agentConfig.name}-config.json`)}
                  className="flex items-center gap-1 h-7 px-2"
                >
                  <Download className="w-3 h-3" />
                  <span className="text-xs">Download</span>
                </Button>
              </div>
            </div>
            <div className="relative">
              <pre className="bg-slate-900 text-slate-100 p-3 rounded-lg overflow-x-auto text-xs max-h-80 overflow-y-auto">
                <code 
                  dangerouslySetInnerHTML={{ 
                    __html: highlightedCode.json || jsonConfig 
                  }}
                />
              </pre>
            </div>
          </TabsContent>

          <TabsContent value="yaml" className="space-y-2">
            <div className="flex items-center justify-between">
              <h4 className="text-xs font-medium">YAML Configuration</h4>
              <div className="flex gap-1">
                <CopyToClipboard
                  text={yamlConfig}
                  onCopy={() => handleCopy('yaml', yamlConfig)}
                >
                  <Button variant="outline" size="sm" className="flex items-center gap-1 h-7 px-2">
                    {copySuccess.yaml ? (
                      <Check className="w-3 h-3 text-primary" />
                    ) : (
                      <Copy className="w-3 h-3" />
                    )}
                    <span className="text-xs">Copy</span>
                  </Button>
                </CopyToClipboard>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => downloadConfig('yaml', yamlConfig, `${agentConfig.name}-config.yaml`)}
                  className="flex items-center gap-1 h-7 px-2"
                >
                  <Download className="w-3 h-3" />
                  <span className="text-xs">Download</span>
                </Button>
              </div>
            </div>
            <div className="relative">
              <pre className="bg-slate-900 text-slate-100 p-3 rounded-lg overflow-x-auto text-xs max-h-80 overflow-y-auto">
                <code 
                  dangerouslySetInnerHTML={{ 
                    __html: highlightedCode.yaml || yamlConfig 
                  }}
                />
              </pre>
            </div>
          </TabsContent>

          <TabsContent value="mcp" className="space-y-3">
            <div className="flex items-center justify-between">
              <h4 className="text-sm font-medium">MCP Server Configuration</h4>
              <div className="flex gap-2">
                <CopyToClipboard
                  text={mcpJsonConfig}
                  onCopy={() => handleCopy('mcp', mcpJsonConfig)}
                >
                  <Button variant="outline" size="sm" className="flex items-center gap-1">
                    {copySuccess.mcp ? (
                      <Check className="w-4 h-4 text-primary" />
                    ) : (
                      <Copy className="w-4 h-4" />
                    )}
                    Copy
                  </Button>
                </CopyToClipboard>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => downloadConfig('mcp', mcpJsonConfig, 'mcp-config.json')}
                  className="flex items-center gap-1"
                >
                  <Download className="w-4 h-4" />
                  Download
                </Button>
              </div>
            </div>
            <div className="relative">
              <pre className="bg-slate-900 text-slate-100 p-4 rounded-lg overflow-x-auto text-sm max-h-96 overflow-y-auto">
                <code 
                  dangerouslySetInnerHTML={{ 
                    __html: highlightedCode.mcp || mcpJsonConfig 
                  }}
                />
              </pre>
            </div>
            <p className="text-xs text-muted-foreground">
              Use this configuration with Claude Desktop or other MCP-compatible clients.
            </p>
          </TabsContent>

          <TabsContent value="deployment" className="space-y-3">
            <div className="flex items-center justify-between">
              <h4 className="text-sm font-medium">Deployment Instructions</h4>
              <div className="flex gap-2">
                <CopyToClipboard
                  text={deploymentScript}
                  onCopy={() => handleCopy('deployment', deploymentScript)}
                >
                  <Button variant="outline" size="sm" className="flex items-center gap-1">
                    {copySuccess.deployment ? (
                      <Check className="w-4 h-4 text-primary" />
                    ) : (
                      <Copy className="w-4 h-4" />
                    )}
                    Copy
                  </Button>
                </CopyToClipboard>
              </div>
            </div>
            <div className="relative">
              <pre className="bg-slate-900 text-slate-100 p-4 rounded-lg overflow-x-auto text-sm max-h-96 overflow-y-auto whitespace-pre-wrap">
                {deploymentScript}
              </pre>
            </div>
          </TabsContent>
        </Tabs>

        {/* Configuration Summary */}
        <div className="mt-6 p-4 bg-muted/30 rounded-lg border border-border">
          <h4 className="text-sm font-medium mb-3 text-foreground">Configuration Summary</h4>
          <div className="grid grid-cols-2 gap-3 text-sm">
            <div>
              <span className="text-muted-foreground">Role:</span>
              <span className="ml-2 font-medium text-foreground">{wizardData.role || 'Not selected'}</span>
            </div>
            <div>
              <span className="text-muted-foreground">Tools:</span>
              <span className="ml-2 font-medium text-foreground">{wizardData.tools.length}</span>
            </div>
            <div>
              <span className="text-muted-foreground">Style:</span>
              <span className="ml-2 font-medium text-foreground">{wizardData.style.tone || 'Not configured'}</span>
            </div>
            <div>
              <span className="text-muted-foreground">Platform:</span>
              <span className="ml-2 font-medium text-foreground">{wizardData.deployment.platform || 'Not selected'}</span>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}