import { useEffect, useRef } from 'react';

interface AnalyticsEvent {
  event: string;
  properties: Record<string, any>;
  timestamp: string;
  sessionId: string;
  userId?: string;
}

interface WizardAnalytics {
  sessionStart: string;
  currentStep: number;
  stepStartTime: string;
  stepDuration: Record<number, number>;
  completionRate: number;
  abandonmentPoint?: number;
  userChoices: {
    role?: string;
    tools: string[];
    style?: string;
    platform?: string;
  };
  interactions: {
    clicks: number;
    backNavigations: number;
    errors: number;
    helpUsage: number;
  };
}

class AnalyticsService {
  private sessionId: string;
  private events: AnalyticsEvent[] = [];
  private wizardData: WizardAnalytics;
  private isOptedOut: boolean = false;

  constructor() {
    this.sessionId = this.generateSessionId();
    this.wizardData = this.initializeWizardData();
    this.isOptedOut = localStorage.getItem('analytics_opt_out') === 'true';
    this.loadExistingData();
  }

  private generateSessionId(): string {
    return `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  private initializeWizardData(): WizardAnalytics {
    return {
      sessionStart: new Date().toISOString(),
      currentStep: 1,
      stepStartTime: new Date().toISOString(),
      stepDuration: {},
      completionRate: 0,
      userChoices: {
        tools: []
      },
      interactions: {
        clicks: 0,
        backNavigations: 0,
        errors: 0,
        helpUsage: 0
      }
    };
  }

  private loadExistingData() {
    try {
      const savedData = localStorage.getItem('wizard_analytics');
      if (savedData) {
        const parsed = JSON.parse(savedData);
        // Only load if it's from the same session (within last hour)
        const sessionAge = Date.now() - new Date(parsed.sessionStart).getTime();
        if (sessionAge < 60 * 60 * 1000) { // 1 hour
          this.wizardData = { ...this.wizardData, ...parsed };
        }
      }
    } catch (error) {
      console.warn('Failed to load analytics data:', error);
    }
  }

  private saveData() {
    if (this.isOptedOut) return;
    
    try {
      localStorage.setItem('wizard_analytics', JSON.stringify(this.wizardData));
      localStorage.setItem('analytics_events', JSON.stringify(this.events));
    } catch (error) {
      console.warn('Failed to save analytics data:', error);
    }
  }

  // Privacy-friendly event tracking
  track(event: string, properties: Record<string, any> = {}) {
    if (this.isOptedOut) return;

    const analyticsEvent: AnalyticsEvent = {
      event,
      properties: this.sanitizeProperties(properties),
      timestamp: new Date().toISOString(),
      sessionId: this.sessionId
    };

    this.events.push(analyticsEvent);
    this.saveData();

    // Keep only last 100 events to manage storage
    if (this.events.length > 100) {
      this.events = this.events.slice(-100);
    }
  }

  private sanitizeProperties(properties: Record<string, any>): Record<string, any> {
    // Remove any potentially sensitive data
    const sanitized = { ...properties };
    delete sanitized.email;
    delete sanitized.personalInfo;
    delete sanitized.apiKeys;
    
    // Truncate long strings
    Object.keys(sanitized).forEach(key => {
      if (typeof sanitized[key] === 'string' && sanitized[key].length > 100) {
        sanitized[key] = sanitized[key].substring(0, 100) + '...';
      }
    });

    return sanitized;
  }

  // Wizard-specific tracking methods
  stepEntered(step: number, metadata: Record<string, any> = {}) {
    const now = new Date().toISOString();
    
    // Calculate duration for previous step
    if (this.wizardData.currentStep !== step) {
      const previousStep = this.wizardData.currentStep;
      const stepStartTime = new Date(this.wizardData.stepStartTime).getTime();
      const duration = Date.now() - stepStartTime;
      
      this.wizardData.stepDuration[previousStep] = duration;
      
      this.track('wizard_step_completed', {
        step: previousStep,
        duration,
        nextStep: step
      });
    }

    this.wizardData.currentStep = step;
    this.wizardData.stepStartTime = now;
    this.wizardData.completionRate = (step / 5) * 100; // Assuming 5 steps

    this.track('wizard_step_entered', {
      step,
      ...metadata
    });

    this.saveData();
  }

  roleSelected(role: string) {
    this.wizardData.userChoices.role = role;
    this.track('wizard_role_selected', { role });
    this.saveData();
  }

  toolsSelected(tools: string[]) {
    this.wizardData.userChoices.tools = tools;
    this.track('wizard_tools_selected', { 
      tools, 
      toolCount: tools.length,
      categories: this.categorizeTools(tools)
    });
    this.saveData();
  }

  styleConfigured(style: Record<string, any>) {
    this.wizardData.userChoices.style = style.tone;
    this.track('wizard_style_configured', {
      tone: style.tone,
      responseLength: style.responseLength,
      constraintCount: style.constraints?.length || 0
    });
    this.saveData();
  }

  platformSelected(platform: string) {
    this.wizardData.userChoices.platform = platform;
    this.track('wizard_platform_selected', { platform });
    this.saveData();
  }

  wizardCompleted() {
    const totalDuration = Date.now() - new Date(this.wizardData.sessionStart).getTime();
    
    this.track('wizard_completed', {
      totalDuration,
      stepDurations: this.wizardData.stepDuration,
      finalChoices: this.wizardData.userChoices,
      totalInteractions: this.wizardData.interactions
    });

    // Mark completion
    this.wizardData.completionRate = 100;
    this.saveData();

    // Optional: Send aggregated data to analytics endpoint
    this.sendAggregatedData();
  }

  wizardAbandoned(step: number, reason?: string) {
    this.wizardData.abandonmentPoint = step;
    
    this.track('wizard_abandoned', {
      step,
      reason,
      partialChoices: this.wizardData.userChoices,
      timeSpent: Date.now() - new Date(this.wizardData.sessionStart).getTime()
    });

    this.saveData();
  }

  // Interaction tracking
  backNavigation(fromStep: number, toStep: number) {
    this.wizardData.interactions.backNavigations++;
    this.track('wizard_back_navigation', { fromStep, toStep });
    this.saveData();
  }

  errorEncountered(error: string, step: number) {
    this.wizardData.interactions.errors++;
    this.track('wizard_error', { error, step });
    this.saveData();
  }

  helpUsed(type: 'tour' | 'tooltip' | 'dialog') {
    this.wizardData.interactions.helpUsage++;
    this.track('help_used', { type });
    this.saveData();
  }

  configPreviewUsed(action: 'copy' | 'download' | 'share', format?: string) {
    this.track('config_preview_used', { action, format });
    this.saveData();
  }

  feedbackSubmitted(type: string, rating?: number) {
    this.track('feedback_submitted', { type, rating });
    this.saveData();
  }

  private categorizeTools(tools: string[]): Record<string, number> {
    const categories: Record<string, number> = {
      development: 0,
      design: 0,
      productivity: 0,
      communication: 0,
      other: 0
    };

    const toolCategories: Record<string, string> = {
      'git': 'development',
      'github': 'development',
      'vscode': 'development',
      'figma': 'design',
      'notion': 'productivity',
      'slack': 'communication',
      'discord': 'communication'
    };

    tools.forEach(tool => {
      const category = toolCategories[tool.toLowerCase()] || 'other';
      categories[category]++;
    });

    return categories;
  }

  private async sendAggregatedData() {
    if (this.isOptedOut) return;

    try {
      // Only send aggregated, non-personal data
      const aggregatedData = {
        sessionId: this.sessionId,
        completionRate: this.wizardData.completionRate,
        totalDuration: this.wizardData.stepDuration,
        choicePatterns: {
          role: this.wizardData.userChoices.role,
          toolCount: this.wizardData.userChoices.tools.length,
          platform: this.wizardData.userChoices.platform
        },
        interactions: this.wizardData.interactions,
        timestamp: new Date().toISOString()
      };

      // In a real app, you'd send this to your analytics endpoint
      console.log('Analytics data (would be sent to server):', aggregatedData);
      
      // Store locally for potential later sync
      const existingData = JSON.parse(localStorage.getItem('analytics_queue') || '[]');
      existingData.push(aggregatedData);
      localStorage.setItem('analytics_queue', JSON.stringify(existingData));

    } catch (error) {
      console.warn('Failed to send analytics data:', error);
    }
  }

  // Privacy controls
  optOut() {
    this.isOptedOut = true;
    localStorage.setItem('analytics_opt_out', 'true');
    localStorage.removeItem('wizard_analytics');
    localStorage.removeItem('analytics_events');
    localStorage.removeItem('analytics_queue');
    this.events = [];
  }

  optIn() {
    this.isOptedOut = false;
    localStorage.removeItem('analytics_opt_out');
  }

  getInsights(): Record<string, any> {
    if (this.isOptedOut) return {};

    return {
      sessionDuration: Date.now() - new Date(this.wizardData.sessionStart).getTime(),
      currentStep: this.wizardData.currentStep,
      completionRate: this.wizardData.completionRate,
      totalInteractions: Object.values(this.wizardData.interactions).reduce((a, b) => a + b, 0),
      averageStepTime: Object.values(this.wizardData.stepDuration).reduce((a, b) => a + b, 0) / Object.keys(this.wizardData.stepDuration).length || 0
    };
  }

  exportData(): string {
    if (this.isOptedOut) return '{}';
    
    return JSON.stringify({
      wizardData: this.wizardData,
      events: this.events
    }, null, 2);
  }
}

// Singleton instance
let analyticsInstance: AnalyticsService | null = null;

export const getAnalytics = (): AnalyticsService => {
  if (!analyticsInstance) {
    analyticsInstance = new AnalyticsService();
  }
  return analyticsInstance;
};

// React hook for using analytics
export const useAnalytics = () => {
  const analytics = getAnalytics();
  const stepRef = useRef<number>(1);

  useEffect(() => {
    // Page view tracking
    analytics.track('page_view', {
      page: 'wizard',
      userAgent: navigator.userAgent,
      screenSize: `${window.screen.width}x${window.screen.height}`,
      timestamp: new Date().toISOString()
    });

    // Track page visibility changes
    const handleVisibilityChange = () => {
      if (document.hidden) {
        analytics.track('page_hidden');
      } else {
        analytics.track('page_visible');
      }
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);

    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange);
    };
  }, [analytics]);

  return {
    trackStepEnter: (step: number, metadata?: Record<string, any>) => {
      if (stepRef.current !== step) {
        analytics.stepEntered(step, metadata);
        stepRef.current = step;
      }
    },
    trackRoleSelection: (role: string) => analytics.roleSelected(role),
    trackToolsSelection: (tools: string[]) => analytics.toolsSelected(tools),
    trackStyleConfig: (style: Record<string, any>) => analytics.styleConfigured(style),
    trackPlatformSelection: (platform: string) => analytics.platformSelected(platform),
    trackCompletion: () => analytics.wizardCompleted(),
    trackAbandonment: (step: number, reason?: string) => analytics.wizardAbandoned(step, reason),
    trackBackNavigation: (from: number, to: number) => analytics.backNavigation(from, to),
    trackError: (error: string, step: number) => analytics.errorEncountered(error, step),
    trackHelpUsage: (type: 'tour' | 'tooltip' | 'dialog') => analytics.helpUsed(type),
    trackConfigPreview: (action: 'copy' | 'download' | 'share', format?: string) => 
      analytics.configPreviewUsed(action, format),
    trackFeedback: (type: string, rating?: number) => analytics.feedbackSubmitted(type, rating),
    track: (event: string, properties?: Record<string, any>) => analytics.track(event, properties),
    getInsights: () => analytics.getInsights(),
    exportData: () => analytics.exportData(),
    optOut: () => analytics.optOut(),
    optIn: () => analytics.optIn()
  };
};