import React from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from './ui/dialog';
import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { Card, CardContent } from './ui/card';
import { 
  X, 
  Zap, 
  Shield, 
  Puzzle, 
  Settings, 
  TestTube, 
  Rocket,
  User,
  CheckCircle,
  Sparkles
} from 'lucide-react';

interface OnboardingModalProps {
  open: boolean;
  onClose: () => void;
}

export function OnboardingModal({ open, onClose }: OnboardingModalProps) {
  const wizardSteps = [
    {
      icon: User,
      title: "Agent Profile",
      description: "Define your AI agent's identity and purpose"
    },
    {
      icon: Puzzle,
      title: "Extensions & Integrations",
      description: "Connect to MCP servers, APIs, and enterprise tools"
    },
    {
      icon: Shield,
      title: "Security & Access",
      description: "Configure authentication, permissions, and vault integration"
    },
    {
      icon: Settings,
      title: "Behavior & Style",
      description: "Customize tone, response length, and constraints"
    },
    {
      icon: TestTube,
      title: "Test & Validate",
      description: "Verify connections and validate security settings"
    },
    {
      icon: Rocket,
      title: "Deploy",
      description: "Generate configurations for multiple deployment targets"
    }
  ];

  const features = [
    "13+ Enterprise integrations (GitHub, Slack, Jira, etc.)",
    "Multi-platform deployment (Desktop, Docker, Kubernetes)",
    "Advanced security with OAuth 2.1, mTLS, and vault integration",
    "Real-time configuration preview and validation",
    "Team workspace collaboration",
    "Comprehensive audit trails"
  ];

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-[95vw] w-full max-h-[90vh] overflow-y-auto p-0 border-0 bg-transparent">
        <div className="relative bg-gradient-to-br from-card/95 to-card/90 backdrop-blur-xl rounded-2xl border border-border/50 shadow-2xl">
          {/* Close button */}
          <Button
            variant="ghost"
            size="icon"
            onClick={onClose}
            className="absolute top-4 right-4 z-10 h-8 w-8 rounded-full bg-muted/20 hover:bg-muted/40"
          >
            <X className="h-4 w-4" />
          </Button>

          {/* Header */}
          <DialogHeader className="px-8 sm:px-12 lg:px-16 pt-8 pb-4 text-center">
            <div className="mx-auto mb-4 p-3 rounded-2xl bg-gradient-to-br from-primary/20 to-primary/10 w-fit">
              <Sparkles className="h-8 w-8 text-primary" />
            </div>
            <DialogTitle className="text-3xl mb-2">
              Welcome to AgentEngine
            </DialogTitle>
            <DialogDescription className="text-xl text-muted-foreground max-w-6xl mx-auto leading-relaxed">
              An enterprise-grade wizard for creating sophisticated AI prompts and MCP server configurations. 
              Build, secure, and deploy AI agents with confidence.
            </DialogDescription>
            <div className="flex justify-center gap-2 mt-4">
              <Badge variant="secondary" className="text-xs">
                <Shield className="w-3 h-3 mr-1" />
                Enterprise Security
              </Badge>
              <Badge variant="secondary" className="text-xs">
                <Zap className="w-3 h-3 mr-1" />
                Multi-Platform
              </Badge>
              <Badge variant="secondary" className="text-xs">
                <CheckCircle className="w-3 h-3 mr-1" />
                Production Ready
              </Badge>
            </div>
          </DialogHeader>

          <div className="px-8 sm:px-12 lg:px-16 pb-8">
            {/* 6-Step Process */}
            <div className="mb-12">
              <h3 className="text-2xl mb-8 text-center">6-Step Configuration Wizard</h3>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-3 2xl:grid-cols-6 gap-6 lg:gap-8">
                {wizardSteps.map((step, index) => {
                  const Icon = step.icon;
                  return (
                    <Card key={index} className="bg-muted/20 border-border/30 hover:bg-muted/30 transition-colors">
                      <CardContent className="p-6">
                        <div className="text-center space-y-4">
                          <div className="mx-auto p-3 rounded-xl bg-primary/10 w-fit">
                            <Icon className="w-6 h-6 text-primary" />
                          </div>
                          <div>
                            <div className="mb-2">
                              <span className="text-sm text-primary font-medium">
                                Step {index + 1}
                              </span>
                            </div>
                            <h4 className="font-semibold text-base mb-3">{step.title}</h4>
                            <p className="text-sm text-muted-foreground leading-relaxed">
                              {step.description}
                            </p>
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  );
                })}
              </div>
            </div>

            {/* Key Features */}
            <div className="mb-12">
              <h3 className="text-2xl mb-8 text-center">Enterprise Features</h3>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 2xl:grid-cols-3 gap-4 lg:gap-6">
                {features.map((feature, index) => (
                  <div key={index} className="flex items-center gap-4 p-4 rounded-lg bg-muted/10">
                    <CheckCircle className="w-5 h-5 text-success flex-shrink-0" />
                    <span className="text-base">{feature}</span>
                  </div>
                ))}
              </div>
            </div>

            {/* CTA */}
            <div className="text-center">
              <Button 
                onClick={onClose}
                size="lg"
                className="bg-gradient-to-r from-primary to-primary/80 hover:from-primary/90 hover:to-primary/70 text-primary-foreground px-8"
              >
                <Rocket className="w-4 h-4 mr-2" />
                Start Building Your Agent
              </Button>
              <p className="text-xs text-muted-foreground mt-3">
                Get started in under 5 minutes • No credit card required
              </p>
            </div>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}