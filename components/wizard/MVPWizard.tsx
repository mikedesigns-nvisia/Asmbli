import React, { useState } from 'react';
import { Button } from '../ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Progress } from '../ui/progress';
import { Badge } from '../ui/badge';
import { MVPStep1Role } from './MVPStep1Role';
import { MVPStep2Tools } from './MVPStep2Tools';
import { MVPStep3Upload } from './MVPStep3Upload';
import { MVPStep4Style } from './MVPStep4Style';
import { MVPStep5Deploy } from './MVPStep5Deploy';
import { Brain, Users, FileText, Palette, Rocket, ArrowRight, ArrowLeft } from 'lucide-react';

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

export function MVPWizard() {
  const [currentStep, setCurrentStep] = useState(1);
  const [isGenerating, setIsGenerating] = useState(false);
  const [wizardData, setWizardData] = useState<MVPWizardData>({
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
  });


  const updateWizardData = (updates: Partial<MVPWizardData>) => {
    setWizardData(prev => ({ ...prev, ...updates }));
  };

  const nextStep = () => {
    if (currentStep < STEPS.length) {
      setCurrentStep(currentStep + 1);
    }
  };

  const prevStep = () => {
    if (currentStep > 1) {
      setCurrentStep(currentStep - 1);
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
        return null;
    }
  };

  const progressPercentage = (currentStep / STEPS.length) * 100;

  return (
    <div className="min-h-screen bg-gradient-to-br from-background via-background to-primary/5">
      <div className="container mx-auto px-4 py-8">
        {/* Header */}
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold text-foreground mb-2">
            Create Your Custom AI Agent
          </h1>
          <p className="text-xl text-muted-foreground mb-6">
            Get an AI that knows YOUR workflow, constraints, and preferences
          </p>
          
          {/* Progress Indicator */}
          <div className="max-w-2xl mx-auto space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-sm text-muted-foreground">Step {currentStep} of {STEPS.length}</span>
              <Badge variant="outline" className="bg-primary/10 text-primary border-primary/30">
                {Math.round(progressPercentage)}% Complete
              </Badge>
            </div>
            <Progress value={progressPercentage} className="h-2" />
            
            {/* Step indicators */}
            <div className="flex justify-between items-center">
              {STEPS.map((step) => {
                const StepIcon = step.icon;
                const isActive = currentStep === step.id;
                const isCompleted = currentStep > step.id;
                
                return (
                  <div key={step.id} className="flex flex-col items-center space-y-2">
                    <div className={`
                      w-10 h-10 rounded-full flex items-center justify-center border-2 transition-all
                      ${isActive ? 'bg-primary border-primary text-primary-foreground' :
                        isCompleted ? 'bg-success border-success text-success-foreground' :
                        'bg-muted border-muted-foreground/30 text-muted-foreground'}
                    `}>
                      <StepIcon className="w-5 h-5" />
                    </div>
                    <div className="text-center">
                      <div className={`text-sm font-medium ${
                        isActive ? 'text-primary' : 
                        isCompleted ? 'text-success' : 
                        'text-muted-foreground'
                      }`}>
                        {step.title}
                      </div>
                      <div className="text-xs text-muted-foreground hidden sm:block">
                        {step.description}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>

        {/* Main Content */}
        <div className="max-w-4xl mx-auto">
          <Card className="border-0 shadow-xl bg-card/80 backdrop-blur-sm">
            <CardHeader className="text-center">
              <CardTitle className="text-2xl flex items-center justify-center gap-3">
                {React.createElement(STEPS[currentStep - 1].icon, { className: "w-6 h-6 text-primary" })}
                {STEPS[currentStep - 1].title}
              </CardTitle>
              <CardDescription className="text-lg">
                {STEPS[currentStep - 1].description}
              </CardDescription>
            </CardHeader>
            
            <CardContent className="space-y-6">
              {/* Step Content */}
              <div className="min-h-[400px]">
                {renderStep()}
              </div>
              
              {/* Navigation */}
              <div className="flex justify-between items-center pt-6 border-t border-border/50">
                <Button
                  variant="outline"
                  onClick={prevStep}
                  disabled={currentStep === 1}
                  className="flex items-center gap-2"
                >
                  <ArrowLeft className="w-4 h-4" />
                  Previous
                </Button>
                
                <div className="text-center">
                  <p className="text-sm text-muted-foreground">
                    Takes about {Math.max(1, STEPS.length - currentStep + 1)} more {Math.max(1, STEPS.length - currentStep + 1) === 1 ? 'minute' : 'minutes'}
                  </p>
                </div>
                
                <Button
                  onClick={nextStep}
                  disabled={!canProceed() || currentStep === STEPS.length}
                  className="flex items-center gap-2"
                >
                  {currentStep === STEPS.length ? 'Complete' : 'Next'}
                  <ArrowRight className="w-4 h-4" />
                </Button>
              </div>
            </CardContent>
          </Card>
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
      </div>
    </div>
  );
}