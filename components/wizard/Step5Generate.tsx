import React from 'react';
import { Sparkles, Copy, Download, Share, RotateCcw, Check } from 'lucide-react';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';

interface Step5Props {
  onStartOver: () => void;
  promptOutput: string;
  copiedItem: string | null;
  onCopy: (text: string, type: string) => void;
}

export function Step5Generate({ onStartOver, promptOutput, copiedItem, onCopy }: Step5Props) {
  return (
    <div className="p-8 animate-fadeIn">
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <div className="text-center mb-12">
          <div className="w-16 h-16 bg-gradient-to-br from-primary to-primary/70 rounded-full flex items-center justify-center mx-auto mb-6">
            <Sparkles className="w-8 h-8 text-white" />
          </div>
          <h2 className="text-3xl font-bold text-foreground mb-4">
            ✨ Your AI is ready!
          </h2>
          <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
            Your optimized prompt and MCP configuration have been generated. Copy the code and deploy to start using your AI.
          </p>
        </div>

        {/* Success metrics */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-12">
          <div className="backdrop-blur-xl p-6 rounded-xl text-center" style={{
            background: 'rgba(24, 24, 27, 0.8)',
            border: '1px solid rgba(255, 255, 255, 0.1)',
            boxShadow: '0 0 0 1px rgba(255, 255, 255, 0.05)'
          }}>
            <div className="text-2xl font-bold text-success mb-2">A+</div>
            <div className="text-sm text-muted-foreground">Quality Score</div>
          </div>
          <div className="backdrop-blur-xl p-6 rounded-xl text-center" style={{
            background: 'rgba(24, 24, 27, 0.8)',
            border: '1px solid rgba(255, 255, 255, 0.1)',
            boxShadow: '0 0 0 1px rgba(255, 255, 255, 0.05)'
          }}>
            <div className="text-2xl font-bold text-primary mb-2">
              {promptOutput.split(' ').length}
            </div>
            <div className="text-sm text-muted-foreground">Tokens</div>
          </div>
          <div className="backdrop-blur-xl p-6 rounded-xl text-center" style={{
            background: 'rgba(24, 24, 27, 0.8)',
            border: '1px solid rgba(255, 255, 255, 0.1)',
            boxShadow: '0 0 0 1px rgba(255, 255, 255, 0.05)'
          }}>
            <div className="text-2xl font-bold text-success mb-2">$0.02</div>
            <div className="text-sm text-muted-foreground">Est. Cost/1K</div>
          </div>
          <div className="backdrop-blur-xl p-6 rounded-xl text-center" style={{
            background: 'rgba(24, 24, 27, 0.8)',
            border: '1px solid rgba(255, 255, 255, 0.1)',
            boxShadow: '0 0 0 1px rgba(255, 255, 255, 0.05)'
          }}>
            <div className="text-2xl font-bold text-primary mb-2">98%</div>
            <div className="text-sm text-muted-foreground">Accuracy</div>
          </div>
        </div>

        {/* Generated prompt preview */}
        <div className="backdrop-blur-xl p-6 rounded-xl mb-8" style={{
          background: 'rgba(24, 24, 27, 0.8)',
          border: '1px solid rgba(255, 255, 255, 0.1)',
          boxShadow: '0 0 0 1px rgba(255, 255, 255, 0.05)'
        }}>
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-semibold text-foreground">Generated System Prompt</h3>
            <div className="flex items-center space-x-2">
              <Badge variant="secondary" className="text-xs">Production Ready</Badge>
              <Button
                size="sm"
                variant="ghost"
                onClick={() => onCopy(promptOutput, 'prompt')}
              >
                {copiedItem === 'prompt' ? (
                  <Check className="w-4 h-4 mr-2 text-success" />
                ) : (
                  <Copy className="w-4 h-4 mr-2" />
                )}
                {copiedItem === 'prompt' ? 'Copied!' : 'Copy'}
              </Button>
            </div>
          </div>
          
          <div className="bg-muted/50 rounded-lg p-4 font-mono text-sm max-h-60 overflow-y-auto">
            <pre className="whitespace-pre-wrap text-foreground leading-relaxed">
              {promptOutput}
            </pre>
          </div>
        </div>

        {/* Next steps */}
        <div className="backdrop-blur-xl p-6 rounded-xl mb-8" style={{
          background: 'rgba(24, 24, 27, 0.8)',
          border: '1px solid rgba(255, 255, 255, 0.1)',
          boxShadow: '0 0 0 1px rgba(255, 255, 255, 0.05)'
        }}>
          <h3 className="text-lg font-semibold text-foreground mb-4">Next Steps</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="p-4 bg-muted/30 rounded-lg">
              <div className="w-8 h-8 bg-primary/20 text-primary rounded-full flex items-center justify-center mb-3">
                <span className="font-bold text-sm">1</span>
              </div>
              <h4 className="font-medium text-foreground mb-2">Deploy MCP Servers</h4>
              <p className="text-sm text-muted-foreground">
                Set up the selected MCP servers using the provided configuration
              </p>
            </div>
            <div className="p-4 bg-muted/30 rounded-lg">
              <div className="w-8 h-8 bg-primary/20 text-primary rounded-full flex items-center justify-center mb-3">
                <span className="font-bold text-sm">2</span>
              </div>
              <h4 className="font-medium text-foreground mb-2">Integrate Prompt</h4>
              <p className="text-sm text-muted-foreground">
                Add the system prompt to your AI application or service
              </p>
            </div>
            <div className="p-4 bg-muted/30 rounded-lg">
              <div className="w-8 h-8 bg-primary/20 text-primary rounded-full flex items-center justify-center mb-3">
                <span className="font-bold text-sm">3</span>
              </div>
              <h4 className="font-medium text-foreground mb-2">Test & Iterate</h4>
              <p className="text-sm text-muted-foreground">
                Run tests and refine based on real-world performance
              </p>
            </div>
          </div>
        </div>

        {/* Enterprise features */}
        <div className="backdrop-blur-xl p-6 rounded-xl mb-8" style={{
          background: 'rgba(24, 24, 27, 0.8)',
          border: '1px solid rgba(255, 255, 255, 0.1)',
          boxShadow: '0 0 0 1px rgba(255, 255, 255, 0.05)'
        }}>
          <h3 className="text-lg font-semibold text-foreground mb-4">Enterprise Features Available</h3>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="text-center">
              <div className="text-sm font-medium text-foreground">Version Control</div>
              <div className="text-xs text-success">Available</div>
            </div>
            <div className="text-center">
              <div className="text-sm font-medium text-foreground">A/B Testing</div>
              <div className="text-xs text-success">Available</div>
            </div>
            <div className="text-center">
              <div className="text-sm font-medium text-foreground">Analytics</div>
              <div className="text-xs text-success">Available</div>
            </div>
            <div className="text-center">
              <div className="text-sm font-medium text-foreground">Team Collaboration</div>
              <div className="text-xs text-success">Available</div>
            </div>
          </div>
        </div>

        {/* Actions */}
        <div className="flex flex-col sm:flex-row items-center justify-center space-y-4 sm:space-y-0 sm:space-x-4">
          <Button onClick={onStartOver} variant="outline" className="w-full sm:w-auto">
            <RotateCcw className="w-4 h-4 mr-2" />
            Create Another Prompt
          </Button>
          
          <Button className="w-full sm:w-auto shadow-lg" style={{
            boxShadow: '0 4px 12px rgba(99, 102, 241, 0.3)'
          }}>
            <Download className="w-4 h-4 mr-2" />
            Export All Configurations
          </Button>
          
          <Button variant="outline" className="w-full sm:w-auto">
            <Share className="w-4 h-4 mr-2" />
            Share with Team
          </Button>
        </div>

        {/* Footer note */}
        <div className="text-center mt-8">
          <p className="text-sm text-muted-foreground">
            Need help with deployment? Check out our{' '}
            <a href="#" className="text-primary hover:underline">documentation</a> or{' '}
            <a href="#" className="text-primary hover:underline">contact enterprise support</a>.
          </p>
        </div>
      </div>
    </div>
  );
}