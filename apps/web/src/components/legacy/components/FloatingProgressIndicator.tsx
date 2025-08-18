import { useState, useEffect } from 'react';
import { Button } from './ui/button';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from './ui/tooltip';
import { 
  ChevronUp, 
  ChevronDown, 
  CheckCircle2, 
  Circle,
  ArrowUp
} from 'lucide-react';

interface StepInfo {
  name: string;
  isVisible: boolean;
}

interface FloatingProgressIndicatorProps {
  currentStep: number;
  totalSteps: number;
  stepInfo?: StepInfo[];
  onStepClick?: (step: number) => void;
  canGoNext: boolean;
  canGoPrev: boolean;
  onNext: () => void;
  onPrev: () => void;
}

export function FloatingProgressIndicator({
  currentStep,
  totalSteps,
  stepInfo,
  onStepClick,
  canGoNext,
  canGoPrev,
  onNext,
  onPrev
}: FloatingProgressIndicatorProps) {
  const [isVisible, setIsVisible] = useState(false);
  const [isExpanded, setIsExpanded] = useState(false);
  const [scrollPosition, setScrollPosition] = useState(0);

  useEffect(() => {
    const handleScroll = () => {
      const position = window.scrollY;
      setScrollPosition(position);
      
      // Show indicator after scrolling down 100px
      setIsVisible(position > 100);
    };

    window.addEventListener('scroll', handleScroll, { passive: true });
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const scrollToTop = () => {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const defaultStepNames = [
    'Agent Profile',
    'Extensions',
    'Security',
    'Behavior',
    'Testing',
    'Deploy'
  ];

  // Use provided stepInfo or fall back to default names
  const steps = stepInfo || defaultStepNames.map(name => ({ name, isVisible: true }));
  const visibleSteps = steps.filter(step => step.isVisible);
  const visibleStepNames = visibleSteps.map(step => step.name);

  const progressPercentage = ((currentStep - 1) / (totalSteps - 1)) * 100;
  const circumference = 2 * Math.PI * 24; // radius of 24
  const strokeDashoffset = circumference - (progressPercentage / 100) * circumference;

  if (!isVisible) return null;

  return (
    <div className="fixed bottom-4 right-4 sm:bottom-6 sm:right-6 z-50 flex flex-col items-end gap-3">
      {/* Scroll to Top Button */}
      {scrollPosition > 400 && (
        <TooltipProvider>
          <Tooltip>
            <TooltipTrigger asChild>
              <Button
                variant="outline"
                size="sm"
                onClick={scrollToTop}
                className="rounded-full w-10 h-10 p-0 bg-card/90 backdrop-blur-xl border-border/50 hover:bg-card/95 hover:border-primary/50 transition-all duration-300 hover:scale-105"
                style={{
                  boxShadow: '0 4px 16px rgba(0, 0, 0, 0.2), 0 0 0 1px rgba(255, 255, 255, 0.05)'
                }}
              >
                <ArrowUp className="w-4 h-4" />
              </Button>
            </TooltipTrigger>
            <TooltipContent side="left">
              <p>Scroll to top</p>
            </TooltipContent>
          </Tooltip>
        </TooltipProvider>
      )}

      {/* Main Progress Indicator */}
      <div 
        className={`bg-card/90 backdrop-blur-xl rounded-2xl border border-border/50 transition-all duration-500 ease-out hover:border-border/70 ${
          isExpanded ? 'p-4 max-w-xs sm:max-w-sm' : 'p-3'
        }`}
        style={{
          boxShadow: '0 8px 32px rgba(0, 0, 0, 0.3), 0 0 0 1px rgba(255, 255, 255, 0.05)'
        }}
      >
        {/* Collapsed View */}
        {!isExpanded && (
          <div 
            className="flex items-center gap-3 cursor-pointer"
            onClick={() => setIsExpanded(true)}
          >
            {/* Circular Progress */}
            <div className="relative w-12 h-12">
              <svg className="w-12 h-12 transform -rotate-90" viewBox="0 0 56 56">
                {/* Background circle */}
                <circle
                  cx="28"
                  cy="28"
                  r="24"
                  stroke="rgba(39, 39, 42, 0.8)"
                  strokeWidth="3"
                  fill="none"
                />
                {/* Progress circle */}
                <circle
                  cx="28"
                  cy="28"
                  r="24"
                  stroke="#6366F1"
                  strokeWidth="3"
                  fill="none"
                  strokeLinecap="round"
                  strokeDasharray={circumference}
                  strokeDashoffset={strokeDashoffset}
                  className="transition-all duration-700 ease-out"
                  style={{
                    filter: 'drop-shadow(0 0 8px rgba(99, 102, 241, 0.5))'
                  }}
                />
              </svg>
              {/* Step number */}
              <div className="absolute inset-0 flex items-center justify-center">
                <span className="text-sm font-semibold text-primary">
                  {currentStep}
                </span>
              </div>
            </div>

            {/* Step info */}
            <div className="min-w-0">
              <div className="text-xs text-muted-foreground">
                Step {currentStep} of {totalSteps}
              </div>
              <div className="text-sm font-medium truncate">
                {visibleStepNames[currentStep - 1] || 'Step'}
              </div>
            </div>

            {/* Expand button */}
            <ChevronUp className="w-4 h-4 text-muted-foreground" />
          </div>
        )}

        {/* Expanded View */}
        {isExpanded && (
          <div className="space-y-4 w-full min-w-0">
            {/* Header */}
            <div className="flex items-center justify-between">
              <div className="min-w-0">
                <div className="text-xs text-muted-foreground">Wizard Progress</div>
                <div className="text-sm font-medium">
                  Step {currentStep} of {totalSteps}
                </div>
              </div>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setIsExpanded(false)}
                className="w-6 h-6 p-0 hover:bg-muted/50 flex-shrink-0"
              >
                <ChevronDown className="w-4 h-4" />
              </Button>
            </div>

            {/* Progress bar */}
            <div className="space-y-2">
              <div className="flex justify-between text-xs text-muted-foreground">
                <span>{Math.round(progressPercentage)}% Complete</span>
                <span className="hidden sm:inline">
                  {totalSteps - currentStep} step{totalSteps - currentStep !== 1 ? 's' : ''} left
                </span>
                <span className="sm:hidden">
                  {totalSteps - currentStep} left
                </span>
              </div>
              <div className="w-full bg-muted/30 rounded-full h-2 overflow-hidden relative">
                <div 
                  className="h-full bg-gradient-to-r from-primary to-primary/80 transition-all duration-700 ease-out relative"
                  style={{ width: `${progressPercentage}%` }}
                >
                  {/* Animated shine effect */}
                  <div 
                    className="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent animate-shimmer"
                    style={{
                      backgroundSize: '200% 100%',
                      animation: progressPercentage > 0 ? 'shimmer 2s infinite' : 'none'
                    }}
                  />
                </div>
              </div>
            </div>

            {/* Steps list */}
            <div className="space-y-1">
              {visibleStepNames.map((name, index) => {
                const stepNum = index + 1;
                const isCompleted = stepNum < currentStep;
                const isCurrent = stepNum === currentStep;
                const isClickable = stepNum <= currentStep; // Allow clicking on current and completed steps only

                return (
                  <TooltipProvider key={stepNum}>
                    <Tooltip>
                      <TooltipTrigger asChild>
                        <div
                          className={`flex items-center gap-2 p-2 rounded-lg text-xs transition-all duration-200 ${
                            isClickable 
                              ? 'cursor-pointer hover:bg-muted/30' 
                              : 'cursor-not-allowed opacity-50'
                          } ${
                            isCurrent ? 'bg-primary/10 border border-primary/20' : ''
                          }`}
                          onClick={() => isClickable && onStepClick?.(stepNum)}
                        >
                          {isCompleted ? (
                            <CheckCircle2 className="w-4 h-4 text-primary flex-shrink-0" />
                          ) : isCurrent ? (
                            <Circle className="w-4 h-4 text-primary flex-shrink-0 animate-pulse" />
                          ) : (
                            <Circle className="w-4 h-4 text-muted-foreground flex-shrink-0" />
                          )}
                          <span className={`truncate ${
                            isCurrent ? 'text-primary font-medium' : 
                            isCompleted ? 'text-foreground' : 'text-muted-foreground'
                          }`}>
                            {stepNum}. {name}
                          </span>
                        </div>
                      </TooltipTrigger>
                      <TooltipContent side="left">
                        <p>
                          {isCompleted ? 'Click to return to this step' :
                           isCurrent ? 'Current step' :
                           'Complete previous steps to unlock'}
                        </p>
                      </TooltipContent>
                    </Tooltip>
                  </TooltipProvider>
                );
              })}
            </div>

            {/* Navigation buttons */}
            <div className="flex gap-2 pt-2 border-t border-border/30">
              <Button
                variant="outline"
                size="sm"
                onClick={onPrev}
                disabled={!canGoPrev}
                className="flex-1 text-xs min-w-0"
              >
                <ChevronUp className="w-3 h-3 sm:mr-1" />
                <span className="hidden sm:inline">Previous</span>
                <span className="sm:hidden">Prev</span>
              </Button>
              <Button
                size="sm"
                onClick={onNext}
                disabled={!canGoNext}
                className="flex-1 text-xs min-w-0"
              >
                <span className="hidden sm:inline">Next</span>
                <span className="sm:hidden">Next</span>
                <ChevronDown className="w-3 h-3 sm:ml-1" />
              </Button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}