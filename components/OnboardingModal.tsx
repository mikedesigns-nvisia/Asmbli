import { useState, useEffect } from 'react';
import { Button } from './ui/button';
import { Card, CardContent } from './ui/card';
import { Badge } from './ui/badge';
import { 
  ArrowRight, 
  Sparkles, 
  Rocket, 
  X, 
  User, 
  Puzzle,
  Shield,
  Palette,
  TestTube,
  Download,
  ChevronLeft,
  ChevronRight,
  Play,
  Bot,
  Wand2,
  Target,
  Lightbulb,
  Heart,
} from 'lucide-react';

interface OnboardingModalProps {
  open: boolean;
  onClose: () => void;
}

interface OnboardingStep {
  id: number;
  icon: React.ReactNode;
  title: string;
  description: string;
  details: string;
  highlight: string;
  color: string;
  preview: string;
}

export function OnboardingModal({ open, onClose }: OnboardingModalProps) {
  const [currentStep, setCurrentStep] = useState(0);
  const [isAnimating, setIsAnimating] = useState(false);
  const steps: OnboardingStep[] = [
    {
      id: 1,
      icon: <User className="w-8 h-8" />,
      title: "Define Your Agent",
      description: "Give your AI agent a name, purpose, and personality that reflects its role.",
      details: "Think of this like hiring a brilliant new team member. You'll define their expertise, communication style, and primary responsibilities.",
      highlight: "Agent Identity & Purpose",
      color: "hsl(var(--color-primary))",
      preview: "Name your agent, describe its purpose, and set its primary role and target environment."
    },
    {
      id: 2,
      icon: <Puzzle className="w-8 h-8" />,
      title: "Choose Extensions",
      description: "Connect your agent to powerful tools and services through MCP extensions.",
      details: "From GitHub and Slack to databases and APIs - give your agent the superpowers it needs to be truly useful in your workflow.",
      highlight: "46+ Integrations Available",
      color: "hsl(158 64% 52%)",
      preview: "Browse our extension library and select the tools your agent needs to access."
    },
    {
      id: 3,
      icon: <Shield className="w-8 h-8" />,
      title: "Configure Security",
      description: "Set up authentication, permissions, and security protocols with enterprise-grade controls.",
      details: "Your agent will handle sensitive data securely with OAuth 2.1, role-based access, and comprehensive audit logging.",
      highlight: "Enterprise-Ready Security",
      color: "hsl(43 96% 56%)",
      preview: "Configure authentication methods, set permissions, and enable security features."
    },
    {
      id: 4,
      icon: <Palette className="w-8 h-8" />,
      title: "Define Behavior",
      description: "Customize how your agent communicates, responds, and handles different requests.",
      details: "Set the perfect tone, response style, and operational guidelines that match your team's culture and needs.",
      highlight: "Tailored Communication Style",
      color: "hsl(280 100% 70%)",
      preview: "Choose communication style, response preferences, and operational constraints."
    },
    {
      id: 5,
      icon: <TestTube className="w-8 h-8" />,
      title: "Test & Validate",
      description: "Run comprehensive tests to ensure your agent works flawlessly before deployment.",
      details: "We'll verify connections, validate security settings, and run performance tests to guarantee everything works perfectly.",
      highlight: "Quality Assurance",
      color: "hsl(200 100% 60%)",
      preview: "Run automated tests to verify connections, security, and performance."
    },
    {
      id: 6,
      icon: <Download className="w-8 h-8" />,
      title: "Deploy Everywhere",
      description: "Generate ready-to-use configurations for multiple platforms in seconds.",
      details: "One agent, infinite possibilities - deploy to Claude Desktop, Microsoft Copilot, Docker, Kubernetes, and more with auto-generated configs.",
      highlight: "Multi-Platform Deployment",
      color: "hsl(0 84% 60%)",
      preview: "Generate deployment configs for your chosen platforms and export your agent."
    }
  ];

  const welcomeStep = {
    icon: <Bot className="w-12 h-12" />,
    title: "Welcome to Agent/Engine",
    subtitle: "Your AI Agent Creation Journey Starts Here",
    description: "The complete toolkit for designing, building, and deploying AI agents that work seamlessly across any platform.",
    details: "In just 6 simple steps, you'll create a powerful AI agent that understands your needs, connects to your tools, and works exactly how you want it to."
  };

  useEffect(() => {
    if (open) {
      document.body.style.overflow = 'hidden';
      return () => {
        document.body.style.overflow = 'unset';
      };
    }
  }, [open]);

  const nextStep = () => {
    if (currentStep < steps.length) {
      setIsAnimating(true);
      setTimeout(() => {
        setCurrentStep(currentStep + 1);
        setIsAnimating(false);
      }, 150);
    }
  };

  const prevStep = () => {
    if (currentStep > 0) {
      setIsAnimating(true);
      setTimeout(() => {
        setCurrentStep(currentStep - 1);
        setIsAnimating(false);
      }, 150);
    }
  };

  const handleComplete = () => {
    onClose();
  };

  const handleSkip = () => {
    onClose();
  };

  if (!open) return null;

  const currentStepData = currentStep === 0 ? null : steps[currentStep - 1];
  const progress = ((currentStep) / (steps.length + 1)) * 100;

  return (
    <div className="fixed inset-0 z-modal bg-black/80 backdrop-blur-sm flex items-center justify-center component-padding-sm animate-fadeIn">
      <Card className="w-full max-w-3xl mx-auto shadow-2xl border-border/40 bg-background/95 backdrop-blur-xl animate-slideIn">
        <CardContent className="component-padding-xl">
          {/* Header */}
          <div className="flex items-center justify-between mb-phi-lg">
            <div className="flex items-center content-gap-sm">
              <div className="w-10 h-10 bg-gradient-to-br from-primary/20 to-purple-400/20 rounded-xl flex items-center justify-center border border-primary/20">
                <Wand2 className="w-5 h-5 text-primary" />
              </div>
              <div>
                <h2 className="text-lg font-semibold font-display">Getting Started</h2>
                <p className="text-sm text-muted-foreground">
                  Step {currentStep} of {steps.length + 1}
                </p>
              </div>
            </div>
            <Button 
              variant="ghost" 
              size="sm" 
              onClick={onClose}
              className="text-muted-foreground hover:text-foreground accessible-button"
            >
              <X className="w-4 h-4" />
            </Button>
          </div>

          {/* Progress Bar */}
          <div className="mb-phi-xl">
            <div className="w-full bg-muted/50 rounded-full h-2 overflow-hidden">
              <div 
                className="h-full bg-gradient-to-r from-primary to-purple-400 transition-all duration-500 ease-out"
                style={{ width: `${progress}%` }}
              />
            </div>
            <div className="flex justify-between mt-phi-sm">
              <span className="text-xs text-muted-foreground">Welcome</span>
              <span className="text-xs text-muted-foreground">Ready to Build!</span>
            </div>
          </div>

          {/* Content */}
          <div className={`transition-all duration-300 ${isAnimating ? 'opacity-50 scale-[0.98]' : 'opacity-100 scale-100'}`}>
            {currentStep === 0 ? (
              // Welcome Step
              <div className="text-center content-spacing-lg">
                <div className="mb-phi-xl">
                  <div className="w-24 h-24 bg-gradient-to-br from-primary/20 to-purple-400/20 rounded-3xl flex items-center justify-center mx-auto mb-phi-md border-2 border-primary/20">
                    {welcomeStep.icon}
                  </div>
                  <Badge className="bg-primary/10 text-primary border-primary/30 mb-phi-md px-phi-md py-phi-sm">
                    <Sparkles className="w-4 h-4 mr-2" />
                    AI Agent Builder
                  </Badge>
                </div>

                <h1 className="text-4xl font-bold font-display leading-tight mb-phi-sm">
                  {welcomeStep.title}
                </h1>
                <p className="text-xl text-primary/80 font-medium mb-phi-md">
                  {welcomeStep.subtitle}
                </p>
                <p className="text-lg text-muted-foreground mb-phi-md max-w-2xl mx-auto leading-relaxed">
                  {welcomeStep.description}
                </p>
                <p className="text-foreground/80 max-w-xl mx-auto leading-relaxed mb-phi-xl">
                  {welcomeStep.details}
                </p>

                <div className="grid grid-cols-1 sm:grid-cols-3 gap-phi-md mt-phi-xl">
                  <div className="component-padding-md rounded-xl bg-primary/5 border border-primary/20 hover:bg-primary/10 transition-colors">
                    <div className="text-3xl font-bold text-primary mb-phi-xs">6</div>
                    <div className="text-sm font-medium mb-phi-xs">Simple Steps</div>
                    <div className="text-xs text-muted-foreground">Easy to follow</div>
                  </div>
                  <div className="component-padding-md rounded-xl bg-success/5 border border-success/20 hover:bg-success/10 transition-colors">
                    <div className="text-3xl font-bold text-success mb-phi-xs">46+</div>
                    <div className="text-sm font-medium mb-phi-xs">Integrations</div>
                    <div className="text-xs text-muted-foreground">Ready to use</div>
                  </div>
                  <div className="component-padding-md rounded-xl bg-purple-500/5 border border-purple-500/20 hover:bg-purple-500/10 transition-colors">
                    <div className="text-3xl font-bold text-purple-400 mb-phi-xs">∞</div>
                    <div className="text-sm font-medium mb-phi-xs">Possibilities</div>
                    <div className="text-xs text-muted-foreground">Unlimited potential</div>
                  </div>
                </div>
              </div>
            ) : (
              // Step Content
              <div className="content-spacing-lg">
                <div className="flex items-start content-gap-lg mb-phi-xl">
                  <div 
                    className="w-20 h-20 rounded-2xl flex items-center justify-center flex-shrink-0 border-2 relative overflow-hidden"
                    style={{ 
                      backgroundColor: `${currentStepData!.color}08`, 
                      borderColor: `${currentStepData!.color}30`,
                      color: currentStepData!.color
                    }}
                  >
                    <div 
                      className="absolute inset-0 opacity-10"
                      style={{ background: `radial-gradient(circle at center, ${currentStepData!.color}40 0%, transparent 70%)` }}
                    />
                    {currentStepData!.icon}
                  </div>

                  <div className="flex-1 min-w-0">
                    <div className="mb-phi-sm">
                      <Badge 
                        className="mb-phi-sm text-xs font-medium"
                        style={{ 
                          backgroundColor: `${currentStepData!.color}10`,
                          color: currentStepData!.color,
                          borderColor: `${currentStepData!.color}30`
                        }}
                      >
                        <Target className="w-3 h-3 mr-1" />
                        {currentStepData!.highlight}
                      </Badge>
                    </div>
                    <h2 className="text-3xl font-bold font-display mb-phi-sm">
                      {currentStepData!.title}
                    </h2>
                    <p className="text-lg text-muted-foreground mb-phi-md leading-relaxed">
                      {currentStepData!.description}
                    </p>
                    <p className="text-foreground/80 leading-relaxed">
                      {currentStepData!.details}
                    </p>
                  </div>
                </div>

                {/* Step Preview */}
                <div className="bg-gradient-to-br from-muted/20 to-muted/5 rounded-xl component-padding-md border border-border/40">
                  <div className="flex items-center content-gap-sm mb-phi-sm">
                    <div 
                      className="w-6 h-6 rounded-lg flex items-center justify-center"
                      style={{ backgroundColor: `${currentStepData!.color}15` }}
                    >
                      <Lightbulb 
                        className="w-3 h-3"
                        style={{ color: currentStepData!.color }}
                      />
                    </div>
                    <span className="text-sm font-medium">What you'll do in this step:</span>
                  </div>
                  <p className="text-sm text-muted-foreground leading-relaxed">
                    {currentStepData!.preview}
                  </p>
                </div>

                {/* Fun Fact */}
                {currentStep === 2 && (
                  <div className="mt-phi-md bg-gradient-to-r from-success/10 to-success/5 rounded-lg component-padding-sm border border-success/20">
                    <div className="flex items-center content-gap-sm text-success">
                      <Heart className="w-4 h-4" />
                      <span className="text-sm font-medium">Fun fact: Our most popular extensions are GitHub, Slack, and Notion!</span>
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>

          {/* Footer */}
          <div className="flex items-center justify-between pt-phi-xl border-t border-border/30 mt-phi-xl">
            <div className="flex items-center content-gap-sm">
              {currentStep > 0 && (
                <Button 
                  variant="ghost" 
                  onClick={prevStep}
                  className="text-muted-foreground hover:text-foreground accessible-button"
                >
                  <ChevronLeft className="w-4 h-4 mr-1" />
                  Previous
                </Button>
              )}
            </div>

            <div className="flex items-center content-gap-sm">
              <Button 
                variant="ghost" 
                onClick={handleSkip}
                className="text-muted-foreground hover:text-foreground accessible-button"
              >
                Skip Tutorial
              </Button>
              
              {currentStep === steps.length ? (
                <Button 
                  onClick={handleComplete}
                  className="bg-gradient-to-r from-primary to-purple-600 hover:from-primary/90 hover:to-purple-600/90 shadow-lg shadow-primary/20 accessible-button"
                >
                  <Rocket className="w-4 h-4 mr-2" />
                  Start Building
                  <Sparkles className="w-4 h-4 ml-2" />
                </Button>
              ) : (
                <Button 
                  onClick={nextStep}
                  className="bg-primary hover:bg-primary/90 accessible-button"
                >
                  {currentStep === 0 ? (
                    <>
                      <Play className="w-4 h-4 mr-2" />
                      Get Started
                    </>
                  ) : (
                    <>
                      Next Step
                      <ChevronRight className="w-4 h-4 ml-1" />
                    </>
                  )}
                  <ArrowRight className="w-4 h-4 ml-1 group-hover:translate-x-1 transition-transform" />
                </Button>
              )}
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}