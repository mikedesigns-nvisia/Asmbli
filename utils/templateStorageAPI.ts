import { AgentTemplate, TemplateCategory } from '../types/templates';
import { WizardData } from '../types/wizard';
import { UserRole } from '../types/auth';
import { getAllTemplates } from '../types/agent-templates';

/**
 * API-based template storage that makes HTTP requests to Netlify functions
 * instead of direct database calls (which don't work in the browser)
 */
export class TemplateStorageAPI {
  private static baseUrl = '';

  /**
   * Get the base URL for API calls
   */
  private static getBaseUrl(): string {
    if (typeof window !== 'undefined') {
      return window.location.origin;
    }
    return 'https://asmbli.netlify.app'; // fallback for SSR
  }

  /**
   * Save a template via API
   */
  static async saveTemplate(
    wizardData: WizardData,
    templateInfo: {
      name: string;
      description: string;
      category: string;
      tags: string[];
    },
    userId?: string,
    isPublic = false
  ): Promise<AgentTemplate> {
    const response = await fetch(`${this.getBaseUrl()}/.netlify/functions/templates`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        wizardData,
        templateInfo,
        userId,
        isPublic
      }),
    });

    if (!response.ok) {
      throw new Error(`Failed to save template: ${response.statusText}`);
    }

    const data = await response.json();
    return data.template;
  }

  /**
   * Get templates via API
   */
  static async getTemplates(userRole: UserRole = 'beginner', userId?: string): Promise<AgentTemplate[]> {
    try {
      const params = new URLSearchParams({
        action: 'list',
        role: userRole,
        ...(userId && { userId })
      });

      const response = await fetch(`${this.getBaseUrl()}/.netlify/functions/templates?${params}`);
      
      if (!response.ok) {
        // Console output removed for production
        return this.getFallbackTemplates(userRole);
      }

      const data = await response.json();
      
      // Combine API templates with pre-configured templates
      const preConfiguredTemplates = this.getPreConfiguredTemplates(userRole);
      
      return [
        ...preConfiguredTemplates,
        ...(data.templates || [])
      ];
    } catch (error) {
      // Console output removed for production
      return this.getFallbackTemplates(userRole);
    }
  }

  /**
   * Get a single template by ID
   */
  static async getTemplate(id: string, userRole: UserRole = 'beginner'): Promise<AgentTemplate | null> {
    try {
      // Check pre-configured templates first
      const preConfigured = this.getPreConfiguredTemplates(userRole);
      const preConfiguredTemplate = preConfigured.find(t => t.id === id);
      if (preConfiguredTemplate) {
        return preConfiguredTemplate;
      }

      const response = await fetch(`${this.getBaseUrl()}/.netlify/functions/templates?action=get&id=${id}`);
      
      if (!response.ok) {
        return null;
      }

      const data = await response.json();
      return data.template;
    } catch (error) {
      // Console output removed for production
      return null;
    }
  }

  /**
   * Increment template usage count
   */
  static async incrementUsageCount(id: string, userId?: string): Promise<void> {
    try {
      await fetch(`${this.getBaseUrl()}/.netlify/functions/templates`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          templateId: id,
          userId
        }),
      });
    } catch (error) {
      // Console output removed for production
    }
  }

  /**
   * Get template categories
   */
  static async getCategories(): Promise<TemplateCategory[]> {
    try {
      const response = await fetch(`${this.getBaseUrl()}/.netlify/functions/templates?action=categories`);
      
      if (!response.ok) {
        return this.getDefaultCategories();
      }

      const data = await response.json();
      return data.categories || this.getDefaultCategories();
    } catch (error) {
      // Console output removed for production
      return this.getDefaultCategories();
    }
  }

  /**
   * Export template as JSON string by ID
   */
  static async exportTemplate(id: string): Promise<string | null> {
    try {
      const template = await this.getTemplate(id);
      if (!template) return null;
      return JSON.stringify(template, null, 2);
    } catch (error) {
      // Console output removed for production
      return null;
    }
  }

  /**
   * Import template from JSON string
   */
  static async importTemplate(
    templateJson: string, 
    userId?: string,
    isPublic = false
  ): Promise<AgentTemplate | null> {
    try {
      const template: AgentTemplate = JSON.parse(templateJson);
      
      // Validate required fields
      if (!template.name || !template.wizardData) {
        throw new Error('Invalid template format');
      }

      // Save as new template
      return await this.saveTemplate(
        template.wizardData,
        {
          name: template.name,
          description: template.description,
          category: template.category,
          tags: template.tags
        },
        userId,
        isPublic
      );
    } catch (error) {
      // Console output removed for production
      return null;
    }
  }

  /**
   * Delete a template by ID (placeholder)
   */
  static async deleteTemplate(id: string, userId?: string): Promise<boolean> {
    // For now, just log the request
    // Console output removed for production
    return true;
  }

  /**
   * Filter templates based on criteria
   */
  static filterTemplates(templates: AgentTemplate[], filters: {
    category?: string;
    tags?: string[];
    searchQuery?: string;
  }): AgentTemplate[] {
    return templates.filter(template => {
      // Category filter
      if (filters.category && template.category !== filters.category) {
        return false;
      }
      
      // Tags filter
      if (filters.tags && filters.tags.length > 0) {
        const hasMatchingTag = filters.tags.some(tag => 
          template.tags.includes(tag)
        );
        if (!hasMatchingTag) return false;
      }
      
      // Search query filter
      if (filters.searchQuery) {
        const query = filters.searchQuery.toLowerCase();
        const matchesName = template.name.toLowerCase().includes(query);
        const matchesDescription = template.description.toLowerCase().includes(query);
        const matchesTags = template.tags.some(tag => 
          tag.toLowerCase().includes(query)
        );
        
        if (!matchesName && !matchesDescription && !matchesTags) {
          return false;
        }
      }
      
      return true;
    });
  }

  /**
   * Get pre-configured templates (these don't require database)
   */
  private static getPreConfiguredTemplates(userRole: UserRole): AgentTemplate[] {
    if (userRole === 'beginner') return [];
    
    const availableAgentTemplates = getAllTemplates(userRole === 'beta' ? 'power_user' : userRole);
    return availableAgentTemplates.map(template => ({
      id: template.id,
      name: template.name,
      description: template.description,
      category: template.category,
      tags: [template.targetRole, 'pre-configured', ...template.config.requiredMcps],
      createdAt: '2024-01-01T00:00:00.000Z',
      updatedAt: '2024-01-01T00:00:00.000Z',
      isPublic: true,
      usageCount: 0,
      wizardData: this.convertAgentTemplateToWizardData(template),
      isPreConfigured: true,
      agentTemplateData: template
    }));
  }

  /**
   * Get fallback templates when API fails
   */
  private static getFallbackTemplates(userRole: UserRole): AgentTemplate[] {
    return this.getPreConfiguredTemplates(userRole);
  }

  /**
   * Get default categories
   */
  private static getDefaultCategories(): TemplateCategory[] {
    return [
      {
        id: 'design',
        name: 'Design',
        description: 'Design tools, prototyping, and creative workflow agents',
        icon: '🎨',
        color: '#F59E0B'
      },
      {
        id: 'code',
        name: 'Development',
        description: 'Code review, development, and engineering workflow agents',
        icon: '💻',
        color: '#6366F1'
      },
      {
        id: 'content',
        name: 'Content Creation',
        description: 'Writing, editing, and content generation assistants',
        icon: '✍️',
        color: '#10B981'
      },
      {
        id: 'analysis',
        name: 'Research & Analysis',
        description: 'Data analysis, research, and information gathering agents',
        icon: '📊',
        color: '#8B5CF6'
      }
    ];
  }

  /**
   * Convert agent template to wizard data format
   */
  private static convertAgentTemplateToWizardData(agentTemplate: any): WizardData {
    return {
      // Step 1: Agent Profile
      agentName: agentTemplate.config.agentName,
      agentDescription: agentTemplate.config.agentDescription,
      primaryPurpose: agentTemplate.config.primaryPurpose,
      targetEnvironment: 'development',
      deploymentTargets: agentTemplate.config.recommendedDeployment || [],
      
      // Step 2: Extensions & Integrations
      extensions: [],
      
      // Step 3: Security & Access
      security: {
        authMethod: null,
        permissions: [],
        vaultIntegration: 'none',
        auditLogging: false,
        rateLimiting: true,
        sessionTimeout: 3600
      },
      
      // Step 4: Behavior & Style
      tone: 'professional',
      responseLength: 3,
      constraints: ['Be helpful and accurate', 'Follow safety guidelines'],
      constraintDocs: {},
      
      // Step 5: Test & Validate
      testResults: {
        connectionTests: {},
        latencyTests: {},
        securityValidation: true,
        overallStatus: 'passed' as const
      },
      
      // Step 6: Deploy
      deploymentFormat: 'desktop'
    };
  }
}