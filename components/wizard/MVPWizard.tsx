import React, { useState, Component, ErrorInfo, ReactNode, useEffect } from 'react';
import { Button } from '../ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Progress } from '../ui/progress';
import { Badge } from '../ui/badge';
import { MVPStep1Role } from './MVPStep1Role';
import { MVPStep2Tools } from './MVPStep2Tools';
import { MVPStep3Upload } from './MVPStep3Upload';
import { MVPStep4Style } from './MVPStep4Style';
import { MVPStep5Deploy } from './MVPStep5Deploy';
import { ConfigPreview } from './ConfigPreview';
import { FeedbackSystem } from './FeedbackSystem';
import { useAnalytics } from './AnalyticsTracker';
import { Brain, Users, FileText, Palette, Rocket, ArrowRight, ArrowLeft, AlertTriangle, RefreshCw } from 'lucide-react';

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

const STEPS = [
  { id: 1, title: 'Your Role', icon: Users, description: 'What do you do?' },
  { id: 2, title: 'Your Tools', icon: FileText, description: 'What tools do you use?' },
  { id: 3, title: 'Upload Specs', icon: Brain, description: 'Upload requirements (optional)' },
  { id: 4, title: 'Your Style', icon: Palette, description: 'How should it communicate?' },
  { id: 5, title: 'Deploy', icon: Rocket, description: 'Where should it run?' }
];

interface ErrorBoundaryProps {
  children: ReactNode;
  fallback?: ReactNode;
}

interface ErrorBoundaryState {
  hasError: boolean;
  error?: Error;
}

class StepErrorBoundary extends Component<ErrorBoundaryProps, ErrorBoundaryState> {
  constructor(props: ErrorBoundaryProps) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('MVPWizard step error:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback || (
        <div className="text-center py-8 space-y-4">
          <div className="flex justify-center">
            <AlertTriangle className="w-12 h-12 text-destructive" />
          </div>
          <h3 className="text-lg font-semibold text-destructive">Something went wrong</h3>
          <p className="text-muted-foreground">
            This step encountered an error. You can try refreshing or continue to the next step.
          </p>
          <Button 
            variant="outline" 
            onClick={() => this.setState({ hasError: false, error: undefined })}
            className="flex items-center gap-2"
          >
            <RefreshCw className="w-4 h-4" />
            Try Again
          </Button>
        </div>
      );
    }

    return this.props.children;
  }
}

const initializeWizardData = (): MVPWizardData => {
  try {
    const saved = localStorage.getItem('mvp_wizard_data');
    if (saved) {
      const parsed = JSON.parse(saved);
      // Validate the structure
      if (parsed && typeof parsed === 'object') {
        return {
          role: parsed.role || '',
          tools: Array.isArray(parsed.tools) ? parsed.tools : [],
          uploadedFiles: [],
          extractedConstraints: Array.isArray(parsed.extractedConstraints) ? parsed.extractedConstraints : [],
          style: {
            tone: parsed.style?.tone || '',
            responseLength: parsed.style?.responseLength || '',
            constraints: Array.isArray(parsed.style?.constraints) ? parsed.style.constraints : []
          },
          deployment: {
            platform: parsed.deployment?.platform || '',
            configuration: parsed.deployment?.configuration || null
          }
        };
      }
    }
  } catch (error) {
    console.warn('Failed to load wizard data from localStorage:', error);
    localStorage.removeItem('mvp_wizard_data');
  }
  
  return {
    role: '',
    tools: [],
    uploadedFiles: [],
    extractedConstraints: [],
    style: {
      tone: '',
      responseLength: '',
      constraints: []
    },
    deployment: {
      platform: '',
      configuration: null
    }
  };
};

export function MVPWizard() {
  const [currentStep, setCurrentStep] = useState(1);
  const [wizardData, setWizardData] = useState<MVPWizardData>(initializeWizardData);
  const {
    trackStepEnter,
    trackRoleSelection,
    trackToolsSelection,
    trackStyleConfig,
    trackPlatformSelection,
    trackCompletion,
    trackBackNavigation
  } = useAnalytics();

  // Track initial step on mount
  useEffect(() => {
    trackStepEnter(currentStep);
  }, [trackStepEnter, currentStep]);

  const updateWizardData = (updates: Partial<MVPWizardData>) => {
    setWizardData(prev => {
      const newData = { ...prev, ...updates };
      try {
        localStorage.setItem('mvp_wizard_data', JSON.stringify(newData));
        
        // Track user choices
        if (updates.role) trackRoleSelection(updates.role);
        if (updates.tools) trackToolsSelection(updates.tools);
        if (updates.style) trackStyleConfig(updates.style);
        if (updates.deployment?.platform) trackPlatformSelection(updates.deployment.platform);
        
      } catch (error) {
        console.warn('Failed to save wizard data to localStorage:', error);
      }
      return newData;
    });
  };

  const nextStep = () => {
    if (currentStep < STEPS.length) {
      const nextStepNum = currentStep + 1;
      setCurrentStep(nextStepNum);
      trackStepEnter(nextStepNum);
      
      // Track completion if this is the last step
      if (nextStepNum === STEPS.length) {
        trackCompletion();
      }
    }
  };

  const prevStep = () => {
    if (currentStep > 1) {
      const prevStepNum = currentStep - 1;
      trackBackNavigation(currentStep, prevStepNum);
      setCurrentStep(prevStepNum);
      trackStepEnter(prevStepNum);
    }
  };

  const canProceed = () => {
    switch (currentStep) {
      case 1:
        return wizardData.role !== '';
      case 2:
        return wizardData.tools.length > 0;
      case 3:
        return true; // Optional step
      case 4:
        return wizardData.style.tone !== '';
      case 5:
        return wizardData.deployment.platform !== '';
      default:
        return false;
    }
  };

  const renderStep = () => {
    try {
      switch (currentStep) {
        case 1:
          return (
            <MVPStep1Role
              selectedRole={wizardData.role}
              onRoleSelect={(role) => updateWizardData({ role })}
            />
          );
        case 2:
          return (
            <MVPStep2Tools
              selectedRole={wizardData.role}
              selectedTools={wizardData.tools}
              onToolsChange={(tools) => updateWizardData({ tools })}
            />
          );
        case 3:
          return (
            <MVPStep3Upload
              extractedConstraints={wizardData.extractedConstraints}
              selectedRole={wizardData.role}
              onFilesChange={(uploadedFiles, extractedConstraints) => 
                updateWizardData({ uploadedFiles, extractedConstraints })
              }
            />
          );
        case 4:
          return (
            <MVPStep4Style
              selectedRole={wizardData.role}
              style={wizardData.style}
              extractedConstraints={wizardData.extractedConstraints}
              onStyleChange={(style) => updateWizardData({ style })}
            />
          );
        case 5:
          return (
            <MVPStep5Deploy
              wizardData={wizardData}
              deployment={wizardData.deployment}
              onDeploymentChange={(deployment) => updateWizardData({ deployment })}
              onGenerate={() => setIsGenerating(true)}
            />
          );
        default:
          return (
            <div className="text-center py-8">
              <p className="text-muted-foreground">Invalid step</p>
            </div>
          );
      }
    } catch (error) {
      console.error('Error rendering step:', error);
      return (
        <div className="text-center py-8 space-y-4">
          <AlertTriangle className="w-12 h-12 text-destructive mx-auto" />
          <h3 className="text-lg font-semibold text-destructive">Step Error</h3>
          <p className="text-muted-foreground">
            This step couldn't load properly. Try refreshing or continue to the next step.
          </p>
        </div>
      );
    }
  };

  const progressPercentage = (currentStep / STEPS.length) * 100;

  return (
    <div className="min-h-screen bg-background">
      <div className="container mx-auto px-4 py-8 max-w-7xl">
        {/* Header */}
        <div className="text-center mb-8 wizard-header">
          <h1 className="text-3xl md:text-4xl font-bold text-foreground mb-3">
            Create Your Custom AI Agent
          </h1>
          <p className="text-lg text-muted-foreground mb-6">
            Get an AI that knows YOUR workflow, constraints, and preferences
          </p>
          
          {/* Progress Indicator */}
          <div className="max-w-4xl mx-auto space-y-4 progress-indicator">
            <div className="flex items-center justify-between">
              <span className="text-sm text-muted-foreground">Step {currentStep} of {STEPS.length}</span>
              <Badge variant="secondary" className="text-xs px-2 py-1">
                {Math.round(progressPercentage)}% Complete
              </Badge>
            </div>
            <Progress value={progressPercentage} className="h-2" />
            
            {/* Step indicators */}
            <div className="flex justify-center items-center">
              <div className="flex items-center gap-3 md:gap-6 overflow-x-auto pb-2">
                {STEPS.map((step, index) => {
                  const StepIcon = step.icon;
                  const isActive = currentStep === step.id;
                  const isCompleted = currentStep > step.id;
                  
                  return (
                    <React.Fragment key={step.id}>
                      <div className="flex flex-col items-center space-y-2 min-w-0 flex-shrink-0">
                        <div className={`
                          w-10 h-10 md:w-11 md:h-11 rounded-full flex items-center justify-center border transition-all duration-200
                          ${isActive ? 'bg-primary border-primary text-primary-foreground' :
                            isCompleted ? 'bg-primary/10 border-primary text-primary' :
                            'bg-background border-border text-muted-foreground hover:border-primary/50'}
                        `}>
                          <StepIcon className="w-4 h-4 md:w-5 md:h-5" />
                        </div>
                        <div className="text-center max-w-20 md:max-w-24">
                          <div className={`text-xs md:text-sm font-medium leading-tight ${
                            isActive ? 'text-foreground' : 
                            isCompleted ? 'text-primary' : 
                            'text-muted-foreground'
                          }`}>
                            {step.title}
                          </div>
                          <div className="text-xs text-muted-foreground/70 hidden lg:block leading-tight mt-1">
                            {step.description}
                          </div>
                        </div>
                      </div>
                      {index < STEPS.length - 1 && (
                        <div className={`
                          hidden sm:block w-6 md:w-8 h-px transition-colors duration-200
                          ${isCompleted ? 'bg-primary/50' : 'bg-border'}
                        `} />
                      )}
                    </React.Fragment>
                  );
                })}
              </div>
            </div>
          </div>
        </div>

        {/* Main Content */}
        <div className="grid grid-cols-1 xl:grid-cols-3 gap-8">
          {/* Wizard Steps */}
          <div className="xl:col-span-2">
            <Card className="shadow-lg border-border">
              <CardHeader className="text-center pb-6">
                <CardTitle className="text-xl md:text-2xl font-semibold flex items-center justify-center gap-3 text-foreground">
                  {React.createElement(STEPS[currentStep - 1].icon, { className: "w-5 h-5 md:w-6 md:h-6 text-primary" })}
                  {STEPS[currentStep - 1].title}
                </CardTitle>
                <CardDescription className="text-base text-muted-foreground">
                  {STEPS[currentStep - 1].description}
                </CardDescription>
              </CardHeader>
              
              <CardContent className="space-y-6">
                {/* Step Content */}
                <div className={`min-h-[400px] ${
                  currentStep === 1 ? 'step-role' :
                  currentStep === 2 ? 'step-tools' :
                  currentStep === 3 ? 'step-upload' :
                  currentStep === 4 ? 'step-style' :
                  currentStep === 5 ? 'step-deploy' : ''
                }`}>
                  <StepErrorBoundary>
                    {renderStep()}
                  </StepErrorBoundary>
                </div>
                
                {/* Navigation */}
                <div className="flex flex-col sm:flex-row justify-between items-center gap-4 pt-6 border-t border-border">
                  <Button
                    variant="outline"
                    onClick={prevStep}
                    disabled={currentStep === 1}
                    className="flex items-center gap-2 w-full sm:w-auto"
                  >
                    <ArrowLeft className="w-4 h-4" />
                    Previous
                  </Button>
                  
                  <div className="text-center order-first sm:order-none">
                    <p className="text-sm text-muted-foreground">
                      Takes about {Math.max(1, STEPS.length - currentStep + 1)} more {Math.max(1, STEPS.length - currentStep + 1) === 1 ? 'minute' : 'minutes'}
                    </p>
                  </div>
                  
                  <Button
                    onClick={nextStep}
                    disabled={!canProceed() || currentStep === STEPS.length}
                    className="flex items-center gap-2 w-full sm:w-auto"
                  >
                    {currentStep === STEPS.length ? 'Complete' : 'Next'}
                    <ArrowRight className="w-4 h-4" />
                  </Button>
                </div>
              </CardContent>
            </Card>

            {/* Mobile Configuration Preview */}
            <div className="lg:hidden mt-6">
              <ConfigPreview 
                wizardData={wizardData} 
                className="config-preview"
              />
            </div>
          </div>

          {/* Desktop Configuration Preview */}
          <div className="xl:col-span-1 hidden lg:block">
            <div className="xl:sticky xl:top-8 config-preview">
              <ConfigPreview 
                wizardData={wizardData} 
                className="max-h-[calc(100vh-10rem)] overflow-y-auto"
              />
            </div>
          </div>
        </div>

        {/* Benefits Footer */}
        <div className="max-w-4xl mx-auto mt-12 text-center">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="space-y-2">
              <div className="text-2xl">🔒</div>
              <h3 className="font-semibold">Your Data Stays Private</h3>
              <p className="text-sm text-muted-foreground">Run locally on LM Studio, Ollama, or VS Code</p>
            </div>
            <div className="space-y-2">
              <div className="text-2xl">🆓</div>
              <h3 className="font-semibold">Completely Free</h3>
              <p className="text-sm text-muted-foreground">No subscriptions, no API costs, no limits</p>
            </div>
            <div className="space-y-2">
              <div className="text-2xl">🎯</div>
              <h3 className="font-semibold">Your Rules</h3>
              <p className="text-sm text-muted-foreground">AI that follows your exact constraints and preferences</p>
            </div>
          </div>
        </div>

        {/* Feedback System */}
        <FeedbackSystem
          currentStep={currentStep}
          wizardData={wizardData}
        />
      </div>
    </div>
  );
}