import { AgentTemplate, TemplateCategory } from '../types/templates';
import { WizardData, Extension } from '../types/wizard';
import { getAllTemplates } from '../types/agent-templates';
import { UserRole } from '../types/auth';
import { extensionsLibrary } from '../data/extensions-library';
import { Database } from '../lib/database';

// Default template categories
const defaultCategories: TemplateCategory[] = [
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
  },
  {
    id: 'conversation',
    name: 'Customer Service',
    description: 'Support, FAQ, and customer interaction agents',
    icon: '💬',
    color: '#06B6D4'
  },
  {
    id: 'research',
    name: 'Research',
    description: 'Information gathering and research assistants',
    icon: '🔍',
    color: '#84CC16'
  },
  {
    id: 'custom',
    name: 'Custom',
    description: 'Specialized and custom-built agent templates',
    icon: '🎯',
    color: '#EF4444'
  }
];

// Helper function to map MCP IDs to extension objects
function mapMcpIdsToExtensions(mcpIds: string[]): Extension[] {
  return mcpIds.map(mcpId => {
    const extension = extensionsLibrary.find(ext => ext.id === mcpId);
    if (extension) {
      return {
        ...extension,
        enabled: true // Pre-configured templates have their extensions enabled
      };
    }
    
    // If extension not found, create a placeholder
    return {
      id: mcpId,
      name: mcpId.replace('-', ' ').replace(/\b\w/g, l => l.toUpperCase()),
      description: `${mcpId} integration for specialized functionality`,
      category: 'Integration',
      provider: 'External',
      icon: 'Settings',
      complexity: 'medium' as const,
      enabled: true,
      connectionType: 'mcp' as const,
      authMethod: 'api-key',
      pricing: 'freemium' as const,
      features: ['External service integration'],
      capabilities: ['API access'],
      requirements: ['Service account or API key'],
      documentation: '#',
      setupComplexity: 2,
      configuration: {}
    };
  });
}

export class TemplateStorageDB {
  /**
   * Save a template to the database
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
    const templateConfig = {
      wizardData: { ...wizardData },
      category: templateInfo.category,
      tags: templateInfo.tags,
      version: '1.0.0'
    };

    const dbTemplate = await Database.saveTemplate(
      templateInfo.name,
      templateInfo.description,
      templateConfig,
      isPublic,
      userId
    );

    // Convert database template to AgentTemplate format
    const agentTemplate: AgentTemplate = {
      id: dbTemplate.id,
      name: dbTemplate.name,
      description: dbTemplate.description,
      category: dbTemplate.config.category,
      tags: dbTemplate.config.tags,
      createdAt: dbTemplate.created_at,
      updatedAt: dbTemplate.created_at,
      isPublic: dbTemplate.is_public,
      usageCount: 0, // Initialize usage count
      wizardData: dbTemplate.config.wizardData
    };

    // Log the action if user ID is provided
    if (userId) {
      await Database.logUserAction(userId, 'template_saved', { templateId: dbTemplate.id });
    }

    return agentTemplate;
  }

  /**
   * Get all templates for a user with pre-configured templates based on role
   */
  static async getTemplates(userRole: UserRole = 'beginner', userId?: string): Promise<AgentTemplate[]> {
    try {
      // Get user templates if userId provided
      let userTemplates: any[] = [];
      if (userId) {
        userTemplates = await Database.getUserTemplates(userId);
      }

      // Get public templates
      const publicTemplates = await Database.getPublicTemplates();

      // Get pre-configured templates based on user role
      const availableAgentTemplates = userRole === 'beginner' ? [] : getAllTemplates(userRole === 'beta' ? 'power_user' : userRole);
      const preConfiguredTemplates = availableAgentTemplates.map(template => ({
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

      // Convert database templates to AgentTemplate format
      const convertDbTemplate = (dbTemplate: any): AgentTemplate => ({
        id: dbTemplate.id,
        name: dbTemplate.name,
        description: dbTemplate.description,
        category: dbTemplate.config.category || 'custom',
        tags: dbTemplate.config.tags || [],
        createdAt: dbTemplate.created_at,
        updatedAt: dbTemplate.updated_at || dbTemplate.created_at,
        isPublic: dbTemplate.is_public,
        usageCount: 0, // TODO: Track usage count
        wizardData: dbTemplate.config.wizardData,
        creatorName: dbTemplate.creator_name
      });

      const convertedUserTemplates = userTemplates.map(convertDbTemplate);
      const convertedPublicTemplates = publicTemplates.map(convertDbTemplate);

      // Combine all templates, avoiding duplicates
      const allTemplates = [
        ...preConfiguredTemplates,
        ...convertedUserTemplates,
        ...convertedPublicTemplates.filter(pub => 
          !convertedUserTemplates.find(user => user.id === pub.id)
        )
      ];

      return allTemplates;
    } catch (error) {
      console.error('Error loading templates from database:', error);
      // Fallback to pre-configured templates only
      const availableAgentTemplates = userRole === 'beginner' ? [] : getAllTemplates(userRole === 'beta' ? 'power_user' : userRole);
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
      extensions: [
        ...mapMcpIdsToExtensions(agentTemplate.config.requiredMcps || []),
        ...mapMcpIdsToExtensions(agentTemplate.config.optionalMcps || []).map(ext => ({ ...ext, enabled: false }))
      ],
      
      // Step 3: Security & Access
      security: {
        authMethod: agentTemplate.config.securitySettings?.authMethod === 'oauth' ? 'oauth' : 
                    agentTemplate.config.securitySettings?.authMethod === 'enterprise' ? 'mtls' : null,
        permissions: agentTemplate.config.securitySettings?.permissions || [],
        vaultIntegration: 'none',
        auditLogging: false,
        rateLimiting: true,
        sessionTimeout: 3600
      },
      
      // Step 4: Behavior & Style
      tone: null,
      responseLength: 200,
      constraints: [],
      constraintDocs: {},
      
      // Step 5: Test & Validate
      testResults: {
        connectionTests: {},
        latencyTests: {},
        securityValidation: true,
        overallStatus: 'pending'
      },
      
      // Step 6: Deploy
      deploymentFormat: 'desktop'
    };
  }

  /**
   * Get a specific template by ID
   */
  static async getTemplate(id: string, userRole: UserRole = 'beginner', userId?: string): Promise<AgentTemplate | null> {
    try {
      // First check if it's a pre-configured template
      const availableAgentTemplates = userRole === 'beginner' ? [] : getAllTemplates(userRole === 'beta' ? 'power_user' : userRole);
      const preConfiguredTemplate = availableAgentTemplates.find(template => template.id === id);
      
      if (preConfiguredTemplate) {
        return {
          id: preConfiguredTemplate.id,
          name: preConfiguredTemplate.name,
          description: preConfiguredTemplate.description,
          category: preConfiguredTemplate.category,
          tags: [preConfiguredTemplate.targetRole, 'pre-configured', ...preConfiguredTemplate.config.requiredMcps],
          createdAt: '2024-01-01T00:00:00.000Z',
          updatedAt: '2024-01-01T00:00:00.000Z',
          isPublic: true,
          usageCount: 0,
          wizardData: this.convertAgentTemplateToWizardData(preConfiguredTemplate),
          isPreConfigured: true,
          agentTemplateData: preConfiguredTemplate
        };
      }

      // Check database
      const dbTemplate = await Database.getTemplateById(id);
      if (!dbTemplate) return null;

      return {
        id: dbTemplate.id,
        name: dbTemplate.name,
        description: dbTemplate.description,
        category: dbTemplate.config.category || 'custom',
        tags: dbTemplate.config.tags || [],
        createdAt: dbTemplate.created_at,
        updatedAt: dbTemplate.updated_at || dbTemplate.created_at,
        isPublic: dbTemplate.is_public,
        usageCount: 0,
        wizardData: dbTemplate.config.wizardData,
        creatorName: dbTemplate.creator_name
      };
    } catch (error) {
      console.error('Error fetching template:', error);
      return null;
    }
  }

  /**
   * Increment usage count for a template
   */
  static async incrementUsageCount(id: string, userId?: string): Promise<void> {
    try {
      // Only track usage for database templates, not pre-configured ones
      const template = await Database.getTemplateById(id);
      if (template && userId) {
        await Database.logUserAction(userId, 'template_used', { templateId: id });
      }
    } catch (error) {
      console.error('Error incrementing usage count:', error);
    }
  }

  /**
   * Get template categories
   */
  static async getCategories(): Promise<TemplateCategory[]> {
    try {
      // For now, return default categories
      // In future, these could be stored in database and customizable
      return defaultCategories;
    } catch (error) {
      console.error('Error loading template categories:', error);
      return defaultCategories;
    }
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
   * Export template as JSON string
   */
  static exportTemplate(template: AgentTemplate): string {
    return JSON.stringify(template, null, 2);
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
      console.error('Error importing template:', error);
      return null;
    }
  }
}