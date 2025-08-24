import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Tabs, TabsContent, TabsList, TabsTrigger } from './ui/tabs';
import { Badge } from './ui/badge';
import { Copy, CheckCircle, Download, Code, Package, FileText, Zap, Settings } from 'lucide-react';

interface CodePreviewPanelProps {
  promptOutput: string;
  deploymentConfigs: Record<string, string>;
  flowDiagram: React.ReactNode;
  currentStep: number;
}

const configTabs = [
  {
    id: 'prompt',
    label: 'System Prompt',
    icon: FileText,
    filename: 'system-prompt.md',
    description: 'Complete system prompt with extension integration and constraints'
  },
  {
    id: 'desktop',
    label: 'Desktop (.dxt)',
    icon: Zap,
    filename: 'agent-extension.dxt',
    description: 'One-click Claude Desktop extension format',
    recommended: true
  },
  {
    id: 'docker',
    label: 'Docker Compose',
    icon: Package,
    filename: 'docker-compose.yml',
    description: 'Container orchestration for development'
  },
  {
    id: 'kubernetes',
    label: 'Kubernetes',
    icon: Settings,
    filename: 'k8s-deployment.yaml',
    description: 'Production-grade orchestration'
  },
  {
    id: 'json',
    label: 'Raw JSON',
    icon: Code,
    filename: 'agent-config.json',
    description: 'Flexible JSON for custom implementations'
  }
];

export function CodePreviewPanel({ 
  promptOutput, 
  deploymentConfigs, 
  flowDiagram, 
  currentStep 
}: CodePreviewPanelProps) {
  const [copiedItem, setCopiedItem] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState('prompt');

  const copyToClipboard = async (text: string, itemType: string) => {
    try {
      await navigator.clipboard.writeText(text);
      setCopiedItem(itemType);
      setTimeout(() => setCopiedItem(null), 2000);
    } catch (err) {
      // Console output removed for production
    }
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

  const getContent = (tabId: string) => {
    return tabId === 'prompt' ? promptOutput : deploymentConfigs[tabId] || '';
  };

  const getCurrentTab = () => configTabs.find(tab => tab.id === activeTab) || configTabs[0];

  return (
    <div className="h-full flex flex-col space-y-4">
      {/* Flow Diagram */}
      {currentStep >= 2 && (
        <Card className="selection-card">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm">Agent Flow</CardTitle>
          </CardHeader>
          <CardContent className="p-2">
            {flowDiagram}
          </CardContent>
        </Card>
      )}

      {/* Configuration Preview */}
      <Card className="selection-card flex-1 min-h-0">
        <CardHeader className="pb-2">
          <div className="flex items-center justify-between">
            <CardTitle className="text-sm">Configuration Preview</CardTitle>
            <div className="flex gap-1">
              <Button 
                variant="outline" 
                size="sm"
                onClick={() => copyToClipboard(getContent(activeTab), activeTab)}
                className="text-xs px-2 py-1 h-auto"
              >
                {copiedItem === activeTab ? <CheckCircle className="w-3 h-3" /> : <Copy className="w-3 h-3" />}
              </Button>
              <Button 
                variant="outline" 
                size="sm"
                onClick={() => downloadFile(getContent(activeTab), getCurrentTab().filename)}
                className="text-xs px-2 py-1 h-auto"
              >
                <Download className="w-3 h-3" />
              </Button>
            </div>
          </div>
        </CardHeader>
        <CardContent className="flex-1 min-h-0 p-2">
          <Tabs value={activeTab} onValueChange={setActiveTab} className="h-full flex flex-col">
            <TabsList className="grid grid-cols-2 gap-1 mb-2 h-auto p-1">
              {configTabs.slice(0, 2).map((tab) => {
                const Icon = tab.icon;
                return (
                  <TabsTrigger 
                    key={tab.id} 
                    value={tab.id}
                    className="text-xs px-2 py-1.5 h-auto flex items-center gap-1.5"
                  >
                    <Icon className="w-3 h-3 flex-shrink-0" />
                    <span className="truncate">{tab.label}</span>
                    {tab.recommended && currentStep >= 6 && (
                      <Badge variant="secondary" className="text-xs px-1 py-0 h-auto ml-0.5">
                        ★
                      </Badge>
                    )}
                  </TabsTrigger>
                );
              })}
            </TabsList>

            {currentStep >= 6 && (
              <TabsList className="grid grid-cols-3 gap-1 mb-2 h-auto p-1">
                {configTabs.slice(2).map((tab) => {
                  const Icon = tab.icon;
                  return (
                    <TabsTrigger 
                      key={tab.id} 
                      value={tab.id}
                      className="text-xs px-2 py-1.5 h-auto flex items-center gap-1.5 justify-center sm:justify-start"
                    >
                      <Icon className="w-3 h-3 flex-shrink-0" />
                      <span className="hidden sm:inline truncate">{tab.label}</span>
                    </TabsTrigger>
                  );
                })}
              </TabsList>
            )}
            
            {configTabs.map((tab) => (
              <TabsContent key={tab.id} value={tab.id} className="flex-1 min-h-0 m-0">
                <div className="h-full flex flex-col">
                  <div className="mb-3">
                    <p className="text-xs text-muted-foreground leading-relaxed">{tab.description}</p>
                  </div>
                  <div className="flex-1 min-h-0">
                    <pre className="bg-muted/30 p-4 rounded-lg overflow-auto text-xs font-mono h-full border leading-relaxed">
                      <code className="block">
                        {getContent(tab.id) || `Configuration will appear here as you complete the wizard...`}
                      </code>
                    </pre>
                  </div>
                </div>
              </TabsContent>
            ))}
          </Tabs>
        </CardContent>
      </Card>
    </div>
  );
}