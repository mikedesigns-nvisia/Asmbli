import React, { useState, useEffect, Suspense } from 'react';
import { AuthProvider } from './contexts/AuthContext';
import { LandingPage } from './components/LandingPage';
import { Layout } from './components/Layout';
import { WizardSidebar } from './components/WizardSidebar';
import { CodePreviewPanel } from './components/CodePreviewPanel';
import { FlowDiagram } from './components/FlowDiagram';
import { WizardSelectionTracker } from './components/WizardSelectionTracker';
import { TemplatesPage } from './components/templates/TemplatesPage';
import { TemplateReviewPage } from './components/templates/TemplateReviewPage';
import { SaveTemplateDialog } from './components/templates/SaveTemplateDialog';
import { OnboardingModal } from './components/OnboardingModal';
import { MVPWizard } from './components/wizard/MVPWizard';

import { WizardHeader } from './components/WizardHeader';
import { FloatingProgressIndicator } from './components/FloatingProgressIndicator';
import { Step0BuildPath } from './components/wizard/Step0BuildPath';
import { Step1AgentProfile } from './components/wizard/Step1AgentProfile';
import { RoleBasedSecurityStep } from './components/wizard/RoleBasedSecurityStep';
import { Step4BehaviorStyle } from './components/wizard/Step4BehaviorStyle';
import { Step5TestValidate } from './components/wizard/Step5TestValidate';
import { RoleBasedDeployStep } from './components/wizard/RoleBasedDeployStep';
import { DesignPrototyperStep } from './components/wizard/DesignPrototyperStep';

// Lazy load the extensions step for better performance
const RoleBasedExtensionsStep = React.lazy(() => import('./components/wizard/RoleBasedExtensionsStep').then(module => ({ default: module.RoleBasedExtensionsStep })));
import { WizardData } from './types/wizard';
import { AgentTemplate } from './types/templates';
import { AgentTemplate as NewAgentTemplate } from './types/agent-templates';
import { generatePrompt } from './utils/promptGenerator';
import { generateDeploymentConfigs } from './utils/deploymentGenerator';
import { TemplateStorageAPI } from './utils/templateStorageAPI';
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
  const [showTemplateReview, setShowTemplateReview] = useState(false);
  const [selectedTemplateForReview, setSelectedTemplateForReview] = useState<AgentTemplate | null>(null);
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
  const [selectedAgentTemplate, setSelectedAgentTemplate] = useState<NewAgentTemplate | null>(null);
  const [isTemplateMode, setIsTemplateMode] = useState(false);
  const [templateFiles, setTemplateFiles] = useState<any[]>([]);
  const [categories, setCategories] = useState<any[]>([]);
  const [allTags, setAllTags] = useState<string[]>([]);
  
  // Use templateFiles to avoid unused variable warning
  console.log('Template files:', templateFiles);

  // Load categories and tags for template dialogs
  useEffect(() => {
    const loadTemplateData = async () => {
      try {
        const [categoriesData, templatesData] = await Promise.all([
          TemplateStorageAPI.getCategories(),
          TemplateStorageAPI.getTemplates(user?.role || 'beginner', user?.id)
        ]);
        setCategories(categoriesData);
        setAllTags(templatesData.flatMap(t => t.tags));
      } catch (error) {
        console.error('Failed to load template data:', error);
      }
    };
    
    if (user) {
      loadTemplateData();
    }
  }, [user]);

  // Role-based step configuration
  const getStepConfiguration = () => {
    const userRole = user?.role || 'beginner';
    
    const allSteps = [
      { name: 'Build Path', isVisible: true },
      { name: 'Agent Profile', isVisible: true },
      { name: 'Extensions', isVisible: true },
      { name: 'Security', isVisible: true },
      { name: 'Behavior', isVisible: true },
      { name: 'Testing', isVisible: true },
      { name: 'Deploy', isVisible: true }
    ];

    // For beginners, hide advanced steps
    if (userRole === 'beginner') {
      // Hide advanced security and testing features
      allSteps[3].name = 'Basic Security'; // Simplified security step name
      allSteps[5].name = 'Quick Test'; // Simplified testing step name
    } else if (userRole === 'power_user') {
      // Power users get enhanced step names
      allSteps[3].name = 'Advanced Security';
      allSteps[5].name = 'Testing & Validation';
    } else if (userRole === 'enterprise') {
      // Enterprise gets full feature names
      allSteps[3].name = 'Enterprise Security';
      allSteps[5].name = 'Full Validation Suite';
    }

    return allSteps;
  };

  const stepConfiguration = getStepConfiguration();
  const totalVisibleSteps = stepConfiguration.filter(step => step.isVisible).length;

  // Generate configurations when wizard data changes
  // For template mode, generate earlier since we skip steps
  useEffect(() => {
    const shouldGenerate = isTemplateMode ? currentStep >= 1 : currentStep >= 5;
    if (shouldGenerate && wizardData.agentName) {
      const prompt = generatePrompt(wizardData);
      setPromptOutput(prompt);
      
      const configs = generateDeploymentConfigs(wizardData, prompt);
      setDeploymentConfigs(configs);
    }
  }, [currentStep, wizardData, isTemplateMode]);

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

  const handleSaveTemplate = async (templateInfo: {
    name: string;
    description: string;
    category: string;
    tags: string[];
  }) => {
    try {
      await TemplateStorageAPI.saveTemplate(wizardData, templateInfo, user?.id);
      setShowSaveTemplateDialog(false);
    } catch (error) {
      console.error('Failed to save template:', error);
    }
  };

  const handleShowTemplateReview = (template: AgentTemplate) => {
    setSelectedTemplateForReview(template);
    setShowTemplateReview(true);
    setShowTemplates(false);
  };

  const handleBackToTemplates = () => {
    setShowTemplateReview(false);
    setSelectedTemplateForReview(null);
    setShowTemplates(true);
  };

  const handleDeployTemplate = (templateWizardData: WizardData) => {
    setWizardData(templateWizardData);
    setShowTemplateReview(false);
    setSelectedTemplateForReview(null);
    setShowTemplates(false);
    setShowLanding(false);
    setCurrentStep(6); // Go directly to deploy step
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleCustomizeTemplate = (templateWizardData: WizardData) => {
    setWizardData(templateWizardData);
    setShowTemplateReview(false);
    setSelectedTemplateForReview(null);
    setShowTemplates(false);
    setShowLanding(false);
    setCurrentStep(1); // Start from agent profile step
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const updateWizardData = (updates: Partial<WizardData> | any) => {
    // Handle template mode initialization
    if (updates.buildType === 'template' && updates.selectedTemplate) {
      setSelectedAgentTemplate(updates.selectedTemplate);
      setIsTemplateMode(true);
      setTemplateFiles(updates.templateFiles || []);
      
      // Update wizard data with template configuration
      setWizardData(prev => ({
        ...prev,
        agentName: updates.agentName,
        agentDescription: updates.agentDescription,
        primaryPurpose: updates.primaryPurpose,
        buildType: 'template',
        selectedTemplate: updates.selectedTemplate,
        isPreConfigured: true,
        // Fill in defaults for skipped steps
        extensions: updates.requiredMcps?.map((mcp: string) => ({
          id: mcp,
          name: mcp,
          enabled: true,
          category: 'core',
          provider: 'template',
          pricing: 'free',
          connectionType: 'mcp'
        })) || [],
        security: {
          authMethod: updates.securitySettings?.authMethod || null,
          permissions: updates.securitySettings?.permissions || [],
          vaultIntegration: 'none',
          auditLogging: false,
          rateLimiting: true,
          sessionTimeout: 3600
        },
        tone: 'professional',
        responseLength: 3,
        constraints: ['Be helpful and accurate', 'Follow safety guidelines'],
        constraintDocs: {},
        testResults: {
          connectionTests: {},
          latencyTests: {},
          securityValidation: true,
          overallStatus: 'passed' as const
        },
        deploymentFormat: 'desktop',
        targetEnvironment: 'production',
        ...updates
      }));
    } else {
      // Add default constraints for beginners if none are set and they're updating behavior
      const updatedData = { ...updates };
      if (user?.role === 'beginner' && 
          updates.constraints !== undefined && 
          updates.constraints.length === 0 && 
          updates.tone) {
        updatedData.constraints = ['helpful', 'safe'];
        updatedData.constraintDocs = {
          helpful: 'Provide clear, actionable, and useful responses',
          safe: 'Avoid harmful, inappropriate, or misleading content'
        };
      }
      setWizardData(prev => ({ ...prev, ...updatedData }));
    }
  };

  // Fixed validation logic according to Guidelines requirements
  const canGoNext = () => {
    // Template mode users auto-pass validation since everything is pre-configured
    if (isTemplateMode) {
      return true;
    }

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
        // Step 4 mandatory validation: Behavior & Style - constraints optional for beginners
        const constraintsRequired = user?.role !== 'beginner';
        return wizardData.tone !== null && 
               (constraintsRequired ? wizardData.constraints.length > 0 : true) &&
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
    // Check if we need to show design prototyper step
    const shouldShowDesignStep = isTemplateMode && 
                                selectedAgentTemplate?.id === 'design-prototyper-free' && 
                                currentStep === 1;

    if (shouldShowDesignStep) {
      return (
        <DesignPrototyperStep
          template={selectedAgentTemplate}
          onNext={nextStep}
          onBack={prevStep}
          onUpdate={(files) => setTemplateFiles(files)}
        />
      );
    }

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
        // For template mode, if NOT design prototyper, skip to deployment
        if (isTemplateMode && selectedAgentTemplate?.id !== 'design-prototyper-free') {
          // Skip to deployment for non-design template users
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
        }
        // For design prototyper or non-template mode, show normal step 1
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
        // For template mode, go to deployment after template-specific steps
        if (isTemplateMode) {
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
        }
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
        // Skip security for template mode  
        if (isTemplateMode) {
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
        }
        return (
          <RoleBasedSecurityStep
            data={wizardData}
            onUpdate={updateWizardData}
            onNext={nextStep}
            onPrev={prevStep}
          />
        );
      case 4:
        // Skip behavior/style for template mode
        if (isTemplateMode) {
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
        }
        return (
          <Step4BehaviorStyle
            data={wizardData}
            onUpdate={updateWizardData}
            onNext={nextStep}
            onPrev={prevStep}
          />
        );
      case 5:
        // Skip testing for template mode
        if (isTemplateMode) {
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
        }
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

  // Show MVP wizard for beta users (bypass everything else)
  if (isAuthenticated && user?.role === 'beta') {
    return <MVPWizard />;
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

  // Show template review page
  if (showTemplateReview && selectedTemplateForReview?.agentTemplateData) {
    return (
      <div className="container-max-width mx-auto">
        <TemplateReviewPage
          template={selectedTemplateForReview.agentTemplateData}
          onBack={handleBackToTemplates}
          onDeploy={handleDeployTemplate}
          onCustomize={handleCustomizeTemplate}
        />
      </div>
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
          onShowTemplateReview={handleShowTemplateReview}
          onDeployTemplate={handleDeployTemplate}
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
        totalSteps={totalVisibleSteps}
        stepInfo={stepConfiguration}
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
          categories={categories}
          existingTags={allTags}
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