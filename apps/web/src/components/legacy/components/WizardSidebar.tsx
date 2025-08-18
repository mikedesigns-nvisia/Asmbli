import React from 'react';
import { Check, User, Layers, Shield, Palette, TestTube, Rocket, Route } from 'lucide-react';

interface WizardStep {
  id: number;
  title: string;
  subtitle: string;
  icon: React.ReactNode;
  status: 'completed' | 'active' | 'upcoming';
}

interface WizardSidebarProps {
  currentStep: number;
  totalSteps: number;
}

export function WizardSidebar({ currentStep, totalSteps }: WizardSidebarProps) {
  const steps: WizardStep[] = [
    {
      id: 0,
      title: 'Build Path',
      subtitle: 'Choose your approach',
      icon: <Route className="w-5 h-5" />,
      status: currentStep > 0 ? 'completed' : currentStep === 0 ? 'active' : 'upcoming'
    },
    {
      id: 1,
      title: 'Agent Profile',
      subtitle: 'Define identity & purpose',
      icon: <User className="w-5 h-5" />,
      status: currentStep > 1 ? 'completed' : currentStep === 1 ? 'active' : 'upcoming'
    },
    {
      id: 2,
      title: 'Extensions & Integrations',
      subtitle: 'Connect AI capabilities',
      icon: <Layers className="w-5 h-5" />,
      status: currentStep > 2 ? 'completed' : currentStep === 2 ? 'active' : 'upcoming'
    },
    {
      id: 3,
      title: 'Security & Access',
      subtitle: 'Set authentication',
      icon: <Shield className="w-5 h-5" />,
      status: currentStep > 3 ? 'completed' : currentStep === 3 ? 'active' : 'upcoming'
    },
    {
      id: 4,
      title: 'Behavior & Style',
      subtitle: 'Communication settings',
      icon: <Palette className="w-5 h-5" />,
      status: currentStep > 4 ? 'completed' : currentStep === 4 ? 'active' : 'upcoming'
    },
    {
      id: 5,
      title: 'Test & Validate',
      subtitle: 'Verify configuration',
      icon: <TestTube className="w-5 h-5" />,
      status: currentStep > 5 ? 'completed' : currentStep === 5 ? 'active' : 'upcoming'
    },
    {
      id: 6,
      title: 'Deploy',
      subtitle: 'Launch your agent',
      icon: <Rocket className="w-5 h-5" />,
      status: currentStep > 6 ? 'completed' : currentStep === 6 ? 'active' : 'upcoming'
    }
  ];

  const progressPercentage = (currentStep / (totalSteps - 1)) * 100;

  return (
    <div className="p-4 lg:p-6 h-full flex flex-col">
      {/* Header */}
      <div className="mb-6 lg:mb-8">
        <h2 className="text-base lg:text-lg font-semibold text-foreground mb-2 font-display">
          Agent Builder
        </h2>
        <p className="text-xs lg:text-sm text-foreground/70">
          Build universal AI agents across any platform
        </p>
      </div>

      {/* Progress bar */}
      <div className="mb-8">
        <div className="flex items-center justify-between mb-2">
          <span className="text-sm font-medium text-foreground">Progress</span>
          <span className="text-sm text-foreground/70">
            {currentStep}/{totalSteps}
          </span>
        </div>
        <div className="w-full bg-muted rounded-full h-2 overflow-hidden">
          <div 
            className="h-full bg-gradient-to-r from-primary to-primary/80 transition-all duration-500 ease-out"
            style={{ width: `${progressPercentage}%` }}
          />
        </div>
        <div className="text-xs text-foreground/60 mt-1">
          {Math.round(progressPercentage)}% complete
        </div>
      </div>

      {/* Steps timeline */}
      <div className="flex-1 relative">
        {/* Timeline line */}
        <div className="absolute left-6 top-6 bottom-6 w-px bg-border"></div>
        <div 
          className="absolute left-6 top-6 w-px bg-gradient-to-b from-primary to-primary/50 transition-all duration-500"
          style={{ height: `${Math.min(progressPercentage, 100)}%` }}
        />

        {/* Steps */}
        <div className="space-y-6">
          {steps.map((step, index) => (
            <div key={step.id} className="relative flex items-start animate-slideIn" style={{ animationDelay: `${index * 100}ms` }}>
              {/* Step indicator */}
              <div className={`
                relative z-10 flex items-center justify-center w-12 h-12 rounded-full border-2 transition-all duration-300
                ${step.status === 'completed' 
                  ? 'bg-primary border-primary text-primary-foreground' 
                  : step.status === 'active'
                  ? 'bg-primary/10 border-primary text-primary animate-pulse'
                  : 'bg-background border-muted text-muted-foreground'
                }
              `} style={{
                boxShadow: step.status === 'active' ? '0 0 20px rgba(99, 102, 241, 0.5)' : 'none'
              }}>
                {step.status === 'completed' ? (
                  <Check className="w-5 h-5" />
                ) : (
                  step.icon
                )}
              </div>

              {/* Step content */}
              <div className="ml-4 min-w-0 flex-1">
                <div className={`
                  font-medium transition-colors duration-200
                  ${step.status === 'active' ? 'text-foreground' : 
                    step.status === 'completed' ? 'text-foreground' : 'text-muted-foreground'}
                `}>
                  {step.title}
                </div>
                <div className="text-sm text-foreground/60 mt-1">
                  {step.subtitle}
                </div>
                
                {/* Active indicator */}
                {step.status === 'active' && (
                  <div className="mt-2 flex items-center space-x-2">
                    <div className="w-2 h-2 bg-primary rounded-full animate-pulse"></div>
                    <span className="text-xs text-primary font-medium">In Progress</span>
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Footer */}
    </div>
  );
}