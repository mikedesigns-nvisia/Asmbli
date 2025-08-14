import React from 'react';
import { Folder, Globe, Database, Plug, ArrowRight, ArrowLeft, Info } from 'lucide-react';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';

interface Step2Props {
  selectedTools: string[];
  onToggle: (value: string) => void;
  onNext: () => void;
  onPrev: () => void;
}

const mcpTools = [
  {
    id: 'files',
    title: 'File System',
    description: 'Read, write, and manage files and directories',
    icon: <Folder className="w-8 h-8" />,
    capabilities: ['File I/O operations', 'Directory traversal', 'Permission handling'],
    serverName: 'filesystem-mcp',
    color: 'from-blue-500 to-blue-600',
    popular: true
  },
  {
    id: 'web',
    title: 'Web Search & Browse',
    description: 'Search the internet and browse web pages',
    icon: <Globe className="w-8 h-8" />,
    capabilities: ['Real-time search', 'Web scraping', 'Content extraction'],
    serverName: 'web-search-mcp',
    color: 'from-green-500 to-green-600',
    popular: true
  },
  {
    id: 'database',
    title: 'Database & Vectors',
    description: 'SQL databases and vector similarity search',
    icon: <Database className="w-8 h-8" />,
    capabilities: ['SQL queries', 'Vector search', 'Data analytics'],
    serverName: 'database-mcp',
    color: 'from-purple-500 to-purple-600',
    popular: false
  },
  {
    id: 'api',
    title: 'API Gateway',
    description: 'Connect to external APIs and services',
    icon: <Plug className="w-8 h-8" />,
    capabilities: ['HTTP requests', 'Authentication', 'Rate limiting'],
    serverName: 'api-gateway-mcp',
    color: 'from-orange-500 to-orange-600',
    popular: false
  }
];

export function Step2MCPTools({ selectedTools, onToggle, onNext, onPrev }: Step2Props) {
  return (
    <div className="p-8 animate-fadeIn">
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <div className="text-center mb-12">
          <h2 className="text-3xl font-bold text-foreground mb-4">
            What tools should your AI access?
          </h2>
          <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
            MCP (Model Context Protocol) servers extend your AI's capabilities with external tools and data sources.
          </p>
        </div>

        {/* MCP Tools Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
          {mcpTools.map((tool) => {
            const isSelected = selectedTools.includes(tool.id);
            
            return (
              <div
                key={tool.id}
                className={`
                  selection-card cursor-pointer group relative overflow-hidden
                  ${isSelected ? 'selected border-primary' : 'border-border'}
                `}
                onClick={() => onToggle(tool.id)}
              >
                <div className="relative p-6">
                  {/* Popular badge */}
                  {tool.popular && (
                    <Badge className="absolute top-4 right-4 bg-primary text-primary-foreground text-xs">
                      Popular
                    </Badge>
                  )}
                  
                  <div className="flex items-start space-x-4">
                    <div className={`
                      p-3 rounded-xl transition-all duration-200
                      ${isSelected 
                        ? `bg-gradient-to-br ${tool.color} text-white` 
                        : 'bg-muted text-muted-foreground group-hover:bg-primary group-hover:text-primary-foreground'}
                    `}>
                      {tool.icon}
                    </div>
                    
                    <div className="flex-1">
                      <h3 className="text-xl font-semibold text-foreground mb-2">
                        {tool.title}
                      </h3>
                      <p className="text-muted-foreground mb-4">
                        {tool.description}
                      </p>
                      
                      <div className="space-y-2 mb-4">
                        {tool.capabilities.map((capability, index) => (
                          <div key={index} className="flex items-center text-sm text-muted-foreground">
                            <div className="w-1.5 h-1.5 bg-primary rounded-full mr-3 flex-shrink-0" />
                            {capability}
                          </div>
                        ))}
                      </div>
                      
                      <div className="flex items-center space-x-2">
                        <code className="text-xs bg-muted px-2 py-1 rounded font-mono">
                          {tool.serverName}
                        </code>
                      </div>
                    </div>
                  </div>
                  
                  {isSelected && (
                    <div className="absolute top-4 left-4 w-6 h-6 bg-primary rounded-full flex items-center justify-center animate-fadeIn">
                      <div className="w-2 h-2 bg-primary-foreground rounded-full" />
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>

        {/* Selected tools visualization */}
        {selectedTools.length > 0 && (
          <div className="backdrop-blur-xl p-6 rounded-xl mb-8 animate-fadeIn" style={{
            background: 'rgba(24, 24, 27, 0.8)',
            border: '1px solid rgba(255, 255, 255, 0.1)',
            boxShadow: '0 0 0 1px rgba(255, 255, 255, 0.05)'
          }}>
            <h4 className="text-lg font-semibold text-foreground mb-4 flex items-center">
              <Info className="w-5 h-5 mr-2" />
              Selected MCP Servers
            </h4>
            
            <div className="flex flex-wrap gap-3 mb-4">
              {selectedTools.map((toolId) => {
                const tool = mcpTools.find(t => t.id === toolId);
                if (!tool) return null;
                
                return (
                  <div key={toolId} className={`
                    px-4 py-2 rounded-lg bg-gradient-to-r ${tool.color} text-white flex items-center space-x-2
                  `}>
                    <div className="w-4 h-4">
                      {React.cloneElement(tool.icon, { className: 'w-4 h-4' })}
                    </div>
                    <span className="text-sm font-medium">{tool.serverName}</span>
                  </div>
                );
              })}
            </div>
            
            <div className="text-sm text-muted-foreground">
              These servers will be included in your MCP configuration. You can modify the setup later.
            </div>
          </div>
        )}

        {/* Architecture info */}
        <div className="backdrop-blur-xl p-6 rounded-xl mb-8" style={{
          background: 'rgba(24, 24, 27, 0.8)',
          border: '1px solid rgba(255, 255, 255, 0.1)',
          boxShadow: '0 0 0 1px rgba(255, 255, 255, 0.05)'
        }}>
          <h4 className="text-lg font-semibold text-foreground mb-4">
            How MCP Works
          </h4>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="text-center">
              <div className="w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-3">
                <span className="text-primary font-bold">1</span>
              </div>
              <h5 className="font-medium text-foreground mb-2">Connect</h5>
              <p className="text-sm text-muted-foreground">AI connects to MCP servers</p>
            </div>
            <div className="text-center">
              <div className="w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-3">
                <span className="text-primary font-bold">2</span>
              </div>
              <h5 className="font-medium text-foreground mb-2">Request</h5>
              <p className="text-sm text-muted-foreground">AI requests tool capabilities</p>
            </div>
            <div className="text-center">
              <div className="w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-3">
                <span className="text-primary font-bold">3</span>
              </div>
              <h5 className="font-medium text-foreground mb-2">Execute</h5>
              <p className="text-sm text-muted-foreground">Tools perform actions and return data</p>
            </div>
          </div>
        </div>

        {/* Navigation */}
        <div className="flex items-center justify-between">
          <Button onClick={onPrev} variant="outline">
            <ArrowLeft className="w-4 h-4 mr-2" />
            Back
          </Button>
          
          <div className="text-sm text-muted-foreground">
            Step 2 of 5 • {selectedTools.length} tool(s) selected
          </div>
          
          <Button onClick={onNext} className="shadow-lg" style={{
            boxShadow: '0 4px 12px rgba(99, 102, 241, 0.3)'
          }}>
            Continue
            <ArrowRight className="w-4 h-4 ml-2" />
          </Button>
        </div>
      </div>
    </div>
  );
}