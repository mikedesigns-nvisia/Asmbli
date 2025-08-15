import React, { useState, useEffect, Suspense } from 'react';
import { AuthProvider } from './contexts/AuthContext';
import { LandingPage } from './components/LandingPage';
import { Layout } from './components/Layout';
import { WizardSidebar } from './components/WizardSidebar';
import { CodePreviewPanel } from './components/CodePreviewPanel';
import { FlowDiagram } from './components/FlowDiagram';
import { WizardSelectionTracker } from './components/WizardSelectionTracker';
import { TemplatesPage } from './components/templates/TemplatesPage';
import { SaveTemplateDialog } from './components/templates/SaveTemplateDialog';
import { OnboardingModal } from './components/OnboardingModal';

import { WizardHeader } from './components/WizardHeader';
import { FloatingProgressIndicator } from './components/FloatingProgressIndicator';
import { Step0BuildPath } from './components/wizard/Step0BuildPath';
import { Step1AgentProfile } from './components/wizard/Step1AgentProfile';
import { RoleBasedSecurityStep } from './components/wizard/RoleBasedSecurityStep';
import { Step4BehaviorStyle } from './components/wizard/Step4BehaviorStyle';
import { Step5TestValidate } from './components/wizard/Step5TestValidate';
import { RoleBasedDeployStep } from './components/wizard/RoleBasedDeployStep';

// Lazy load the extensions step for better performance
const RoleBasedExtensionsStep = React.lazy(() => import('./components/wizard/RoleBasedExtensionsStep').then(module => ({ default: module.RoleBasedExtensionsStep })));
import { WizardData } from './types/wizard';
import { AgentTemplate } from './types/templates';
import { generatePrompt } from './utils/promptGenerator';
import { generateDeploymentConfigs } from './utils/deploymentGenerator';
import { TemplateStorage } from './utils/templateStorage';
import { useAuth } from './contexts/AuthContext';
import { AuthModal } from './components/auth/AuthModal';

const initialWizardData: WizardData = {
  agentName: '',
  agentDescription: '',
  primaryPurpose: '',
  targetEnvironment: 'development',
  deploymentTargets: ['claude-desktop'],
  extensions: [],
  security: {
    authMethod: null,
    permissions: [],
    vaultIntegration: 'none',
    auditLogging: false,
    rateLimiting: true,
    sessionTimeout: 3600
  },
  tone: null,
  responseLength: 3,
  constraints: [],
  constraintDocs: {},
  testResults: {
    connectionTests: {},
    latencyTests: {},
    securityValidation: true,
    overallStatus: 'passed'
  },
  deploymentFormat: 'desktop'
};

function AuthenticatedApp() {
  const { user, isAuthenticated, isLoading, getPreConfiguredSettings } = useAuth();
  const [showLanding, setShowLanding] = useState(true);
  const [showTemplates, setShowTemplates] = useState(false);
  const [showSaveTemplateDialog, setShowSaveTemplateDialog] = useState(false);
  const [showOnboarding, setShowOnboarding] = useState(false);
  const [showAuthModal, setShowAuthModal] = useState(false);
  const [currentStep, setCurrentStep] = useState(0);
  const [copiedItem, setCopiedItem] = useState<string | null>(null);
  const [wizardData, setWizardData] = useState<WizardData>(() => {
    const preConfigured = getPreConfiguredSettings();
    return { ...initialWizardData, ...preConfigured };
  });
  const [promptOutput, setPromptOutput] = useState('');
  const [deploymentConfigs, setDeploymentConfigs] = useState<Record<string, string>>({});

  // Generate configurations when wizard data changes
  useEffect(() => {
    if (currentStep >= 5) {
      const prompt = generatePrompt(wizardData);
      setPromptOutput(prompt);
      
      const configs = generateDeploymentConfigs(wizardData, prompt);
      setDeploymentConfigs(configs);
    }
  }, [currentStep, wizardData]);

  const copyToClipboard = async (text: string, itemType: string) => {
    try {
      await navigator.clipboard.writeText(text);
      setCopiedItem(itemType);
      setTimeout(() => setCopiedItem(null), 2000);
    } catch (err) {
      console.error('Failed to copy:', err);
    }
  };

  const nextStep = () => {
    if (currentStep < 6) {
      setCurrentStep(currentStep + 1);
      // Scroll to top with smooth behavior
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }
  };

  const prevStep = () => {
    if (currentStep > 0) {
      setCurrentStep(currentStep - 1);
      // Scroll to top with smooth behavior
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }
  };

  const goToStep = (step: number) => {
    if (step >= 0 && step <= 6) {
      setCurrentStep(step);
      // Scroll to top with smooth behavior
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }
  };

  const startOver = () => {
    setCurrentStep(0);
    setWizardData(initialWizardData);
    setPromptOutput('');
    setDeploymentConfigs({});
    // Scroll to top with smooth behavior
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleGetStarted = () => {
    if (!isAuthenticated) {
      setShowAuthModal(true);
      return;
    }
    setShowLanding(false);
    setShowTemplates(false);
    setShowOnboarding(true);
    // Scroll to top with smooth behavior
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleOnboardingComplete = () => {
    setShowOnboarding(false);
    // Start the wizard from step 0
    setCurrentStep(0);
  };

  const handleViewTemplates = () => {
    setShowLanding(false);
    setShowTemplates(true);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleBackToWizard = () => {
    setShowTemplates(false);
    setShowLanding(false);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleBackToLanding = () => {
    setShowTemplates(false);
    setShowLanding(true);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleUseTemplate = (template: AgentTemplate) => {
    setWizardData(template.wizardData);
    setShowTemplates(false);
    setShowLanding(false);
    setCurrentStep(0);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleSaveAsTemplate = () => {
    setShowSaveTemplateDialog(true);
  };

  const handleSaveTemplate = (templateInfo: {
    name: string;
    description: string;
    category: string;
    tags: string[];
  }) => {
    TemplateStorage.saveTemplate(wizardData, templateInfo);
    setShowSaveTemplateDialog(false);
  };

  const updateWizardData = (updates: Partial<WizardData>) => {
    setWizardData(prev => ({ ...prev, ...updates }));
  };

  // Fixed validation logic according to Guidelines requirements
  const canGoNext = () => {
    switch (currentStep) {
      case 0:
        // Step 0: Build path selection - always allow progression once path is selected
        return true;
      case 1:
        // Step 1 mandatory validation: Agent Profile must be complete
        return wizardData.agentName.trim() !== '' && 
               wizardData.agentDescription.trim() !== '' && 
               wizardData.primaryPurpose.trim() !== '';
      case 2:
        // Extensions step - at least one extension should be configured, but not mandatory
        return true; // Allow progression even without extensions for flexibility
      case 3:
        // Security step - authentication method should be set (auto-pass for beginners)
        return user?.role === 'beginner' || wizardData.security.authMethod !== null;
      case 4:
        // Step 4 mandatory validation: Behavior & Style with operational constraints
        return wizardData.tone !== null && 
               wizardData.constraints.length > 0 &&
               wizardData.responseLength > 0;
      case 5:
        // Test & Validate step - can proceed if tests passed or if user skips testing
        return wizardData.testResults.overallStatus === 'passed' || wizardData.testResults.overallStatus === 'skipped';
      case 6:
        return true;
      default:
        return true;
    }
  };

  // Check if configuration is valid enough to save as template
  const hasValidConfiguration = () => {
    return wizardData.agentName.trim() !== '' && 
           wizardData.agentDescription.trim() !== '' && 
           wizardData.primaryPurpose.trim() !== '';
  };

  // Loading component for extensions step
  const ExtensionsStepLoading = () => (
    <div className="space-y-6 animate-fadeIn">
      <div className="text-center space-y-4">
        <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-primary/10 border border-primary/20">
          <div className="w-4 h-4 rounded-full bg-primary animate-pulse"></div>
          <span className="text-sm font-medium">Loading Extensions Library...</span>
        </div>
        <p className="text-sm text-muted-foreground max-w-md mx-auto">
          Loading MCP servers, API integrations, and extension library with Microsoft 365, AI services, and development tools.
        </p>
      </div>
      
      {/* Skeleton grid */}
      <div className="extension-grid">
        {Array.from({ length: 6 }).map((_, i) => (
          <div key={i} className="selection-card animate-shimmer-wave" style={{ animationDelay: `${i * 100}ms` }}>
            <div className="space-y-3">
              <div className="flex items-start justify-between">
                <div className="space-y-2 flex-1">
                  <div className="h-4 bg-muted/50 rounded w-3/4 animate-shimmer"></div>
                  <div className="h-3 bg-muted/30 rounded w-full animate-shimmer" style={{ animationDelay: '200ms' }}></div>
                </div>
                <div className="w-12 h-6 bg-muted/40 rounded animate-shimmer" style={{ animationDelay: '100ms' }}></div>
              </div>
              <div className="flex gap-1.5">
                {Array.from({ length: 3 }).map((_, j) => (
                  <div key={j} className="h-5 w-16 bg-muted/40 rounded animate-shimmer" style={{ animationDelay: `${j * 150}ms` }}></div>
                ))}
              </div>
              <div className="flex items-center justify-between">
                <div className="h-4 bg-muted/40 rounded w-20 animate-shimmer" style={{ animationDelay: '300ms' }}></div>
                <div className="h-8 w-20 bg-primary/20 rounded animate-shimmer" style={{ animationDelay: '400ms' }}></div>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );

  const renderCurrentStep = () => {
    switch (currentStep) {
      case 0:
        return (
          <Step0BuildPath
            data={wizardData}
            onUpdate={updateWizardData}
            onNext={nextStep}
          />
        );
      case 1:
        return (
          <Step1AgentProfile
            data={wizardData}
            onUpdate={updateWizardData}
            onNext={nextStep}
            onUseTemplate={handleUseTemplate}
            onViewAllTemplates={handleViewTemplates}
          />
        );
      case 2:
        return (
          <Suspense fallback={<ExtensionsStepLoading />}>
            <RoleBasedExtensionsStep
              data={wizardData}
              onUpdate={updateWizardData}
              onNext={nextStep}
              onPrev={prevStep}
            />
          </Suspense>
        );
      case 3:
        return (
          <RoleBasedSecurityStep
            data={wizardData}
            onUpdate={updateWizardData}
            onNext={nextStep}
            onPrev={prevStep}
          />
        );
      case 4:
        return (
          <Step4BehaviorStyle
            data={wizardData}
            onUpdate={updateWizardData}
            onNext={nextStep}
            onPrev={prevStep}
          />
        );
      case 5:
        return (
          <Step5TestValidate
            data={wizardData}
            onUpdate={updateWizardData}
            onNext={nextStep}
            onPrev={prevStep}
          />
        );
      case 6:
        return (
          <RoleBasedDeployStep
            data={wizardData}
            onUpdate={updateWizardData}
            onStartOver={startOver}
            promptOutput={promptOutput}
            deploymentConfigs={deploymentConfigs}
            copiedItem={copiedItem}
            onCopy={copyToClipboard}
            onSaveAsTemplate={handleSaveAsTemplate}
          />
        );
      default:
        return null;
    }
  };

  // Show loading screen while checking authentication
  if (isLoading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="text-center space-y-4">
          <div className="w-8 h-8 border-4 border-primary/20 border-t-primary rounded-full animate-spin mx-auto"></div>
          <p className="text-muted-foreground">Loading...</p>
        </div>
      </div>
    );
  }

  // Show landing page initially
  if (showLanding) {
    return (
      <LandingPage 
        onGetStarted={handleGetStarted} 
        onViewTemplates={handleViewTemplates}
      />
    );
  }

  // Show templates page
  if (showTemplates) {
    return (
      <div className="container-max-width mx-auto">
        <TemplatesPage
          currentWizardData={wizardData}
          onUseTemplate={handleUseTemplate}
          onBackToWizard={handleBackToWizard}
        />
      </div>
    );
  }

  // Show onboarding modal (rendered over wizard when active)
  if (showOnboarding) {
    return (
      <>
        {/* Wizard background */}
        <div className="container-max-width mx-auto">
          <Layout
            sidebar={<WizardSidebar currentStep={currentStep} totalSteps={7} />}
            rightPanel={
              <CodePreviewPanel
                promptOutput={promptOutput}
                deploymentConfigs={deploymentConfigs}
                flowDiagram={<FlowDiagram wizardData={wizardData} />}
                currentStep={currentStep}
              />
            }
            selectionTracker={
              <WizardSelectionTracker 
                wizardData={wizardData} 
                currentStep={currentStep} 
              />
            }
          >
            <div className="content-width">
              <WizardHeader
                currentStep={currentStep}
                totalSteps={7}
                onNext={currentStep === 6 ? startOver : nextStep}
                onPrev={prevStep}
                canGoNext={canGoNext()}
                onSaveAsTemplate={handleSaveAsTemplate}
                onViewTemplates={handleViewTemplates}
                hasValidConfiguration={hasValidConfiguration()}
              />
              {renderCurrentStep()}
            </div>
          </Layout>
        </div>

        {/* Onboarding Modal Overlay */}
        <OnboardingModal 
          open={showOnboarding}
          onClose={() => setShowOnboarding(false)}
        />
      </>
    );
  }

  // Show wizard flow directly after landing page
  return (
    <div className="container-max-width mx-auto">
      <Layout
        sidebar={<WizardSidebar currentStep={currentStep} totalSteps={7} />}
        rightPanel={
          <CodePreviewPanel
            promptOutput={promptOutput}
            deploymentConfigs={deploymentConfigs}
            flowDiagram={<FlowDiagram wizardData={wizardData} />}
            currentStep={currentStep}
          />
        }
        selectionTracker={
          <WizardSelectionTracker 
            wizardData={wizardData} 
            currentStep={currentStep} 
          />
        }
      >
        <div className="content-width">
          <WizardHeader
            currentStep={currentStep}
            totalSteps={7}
            onNext={currentStep === 6 ? startOver : nextStep}
            onPrev={prevStep}
            canGoNext={canGoNext()}
            onSaveAsTemplate={handleSaveAsTemplate}
            onViewTemplates={handleViewTemplates}
            hasValidConfiguration={hasValidConfiguration()}
          />
          {renderCurrentStep()}
        </div>
      </Layout>

      {/* Floating Progress Indicator */}
      <FloatingProgressIndicator
        currentStep={currentStep}
        totalSteps={7}
        onStepClick={goToStep}
        canGoNext={canGoNext()}
        canGoPrev={currentStep > 0}
        onNext={currentStep === 6 ? startOver : nextStep}
        onPrev={prevStep}
      />

      {/* Save Template Dialog */}
      {showSaveTemplateDialog && (
        <SaveTemplateDialog
          isOpen={showSaveTemplateDialog}
          onClose={() => setShowSaveTemplateDialog(false)}
          onSave={handleSaveTemplate}
          categories={TemplateStorage.getCategories()}
          existingTags={TemplateStorage.getTemplates().flatMap(t => t.tags)}
        />
      )}

      {/* Auth Modal */}
      <AuthModal 
        isOpen={showAuthModal} 
        onClose={() => setShowAuthModal(false)}
        defaultTab="signup"
      />
    </div>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <AuthenticatedApp />
    </AuthProvider>
  );
}