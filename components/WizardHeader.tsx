import React from 'react';
import { Button } from './ui/button';
import { ChevronLeft, ChevronRight, BookmarkPlus, Library } from 'lucide-react';

interface WizardHeaderProps {
  currentStep: number;
  totalSteps: number;
  onNext: () => void;
  onPrev: () => void;
  canGoNext?: boolean;
  isLoading?: boolean;
  onSaveAsTemplate?: () => void;
  onViewTemplates?: () => void;
  hasValidConfiguration?: boolean;
}

export function WizardHeader({ 
  currentStep, 
  totalSteps, 
  onNext, 
  onPrev, 
  canGoNext = true,
  isLoading = false,
  onSaveAsTemplate,
  onViewTemplates,
  hasValidConfiguration = false
}: WizardHeaderProps) {
  const getNextButtonText = () => {
    switch (currentStep) {
      case 0:
        return "Choose Build Path";
      case 1:
        return "Continue to Extensions";
      case 2:
        return "Continue to Security";
      case 3:
        return "Continue to Behavior";
      case 4:
        return "Continue to Testing";
      case 5:
        return "Continue to Deploy";
      case 6:
        return "Start Over";
      default:
        return "Continue";
    }
  };

  const getNextButtonIcon = () => {
    return currentStep === 6 ? null : ChevronRight;
  };

  return (
    <div className="flex items-center justify-between mb-8 pb-6 border-b border-border/30">
      {/* Back Button */}
      <div className="flex-1">
        {currentStep > 0 ? (
          <Button
            variant="ghost"
            onClick={onPrev}
            className="hover:bg-muted/50 text-foreground/70 hover:text-foreground transition-all duration-200"
            disabled={isLoading}
          >
            <ChevronLeft className="w-4 h-4 mr-2" />
            Back
          </Button>
        ) : (
          <div /> // Empty div to maintain spacing
        )}
      </div>

      {/* Step Indicator and Template Actions */}
      <div className="flex-1 flex items-center justify-center gap-4">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-card border border-border whitespace-nowrap shadow-sm">
          <span className="text-sm text-foreground font-medium whitespace-nowrap">
            Step {currentStep + 1} of {totalSteps}
          </span>
        </div>

        {/* Template Actions */}
        <div className="flex items-center gap-2">
          {onViewTemplates && (
            <Button
              variant="ghost"
              size="sm"
              onClick={onViewTemplates}
              className="text-xs hover:bg-muted/50 text-[rgba(224,151,97,1)] hover:text-foreground"
            >
              <Library className="w-4 h-4 mr-1" />
              Templates
            </Button>
          )}
          
          {onSaveAsTemplate && hasValidConfiguration && (
            <Button
              variant="ghost"
              size="sm"
              onClick={onSaveAsTemplate}
              className="text-xs hover:bg-muted/50 text-[rgba(44,173,44,1)] hover:text-foreground"
            >
              <BookmarkPlus className="w-4 h-4 mr-1" />
              Save
            </Button>
          )}
        </div>
      </div>

      {/* Next Button */}
      <div className="flex-1 flex justify-end">
        <Button
          onClick={onNext}
          disabled={!canGoNext || isLoading}
          className="bg-gradient-to-r from-primary to-primary/80 hover:from-primary/90 hover:to-primary/70 transition-all duration-200 px-6"
        >
          {getNextButtonText()}
          {getNextButtonIcon() && (
            <ChevronRight className="w-4 h-4 ml-2" />
          )}
        </Button>
      </div>
    </div>
  );
}