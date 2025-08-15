import { AgentTemplate, TemplateCategory } from '../types/templates';
import { WizardData, Extension } from '../types/wizard';
import { getAllTemplates } from '../types/agent-templates';
import { UserRole } from '../types/auth';
import { extensionsLibrary } from '../data/extensions-library';

const TEMPLATES_STORAGE_KEY = 'agentengine_templates';
const CATEGORIES_STORAGE_KEY = 'agentengine_template_categories';

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

export class TemplateStorage {
  static saveTemplate(wizardData: WizardData, templateInfo: {
    name: string;
    description: string;
    category: string;
    tags: string[];
  }): AgentTemplate {
    const templates = this.getTemplates();
    const now = new Date().toISOString();
    
    const newTemplate: AgentTemplate = {
      id: crypto.randomUUID(),
      name: templateInfo.name,
      description: templateInfo.description,
      category: templateInfo.category,
      tags: templateInfo.tags,
      createdAt: now,
      updatedAt: now,
      isPublic: false,
      usageCount: 0,
      wizardData: { ...wizardData }
    };

    templates.push(newTemplate);
    localStorage.setItem(TEMPLATES_STORAGE_KEY, JSON.stringify(templates));
    
    return newTemplate;
  }

  static getTemplates(userRole: UserRole = 'beginner'): AgentTemplate[] {
    try {
      const stored = localStorage.getItem(TEMPLATES_STORAGE_KEY);
      const userTemplates = stored ? JSON.parse(stored) : [];
      
      // Get pre-configured templates based on user role
      // Only power users and enterprise get pro templates
      const availableAgentTemplates = userRole === 'beginner' ? [] : getAllTemplates(userRole);
      const preConfiguredTemplates = availableAgentTemplates.map(template => ({
        ...template,
        // Convert agent template to regular template format
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
        // Mark as pre-configured for different handling
        isPreConfigured: true,
        agentTemplateData: template // Store original agent template data
      }));
      
      // Combine user templates with pre-configured templates
      return [...preConfiguredTemplates, ...userTemplates];
    } catch (error) {
      console.error('Error loading templates:', error);
      return [];
    }
  }

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

  static getTemplate(id: string, userRole: UserRole = 'beginner'): AgentTemplate | null {
    const templates = this.getTemplates(userRole);
    return templates.find(t => t.id === id) || null;
  }

  static updateTemplate(id: string, updates: Partial<AgentTemplate>): boolean {
    // Only allow updating user-created templates, not pre-configured ones
    const stored = localStorage.getItem(TEMPLATES_STORAGE_KEY);
    const userTemplates = stored ? JSON.parse(stored) : [];
    const index = userTemplates.findIndex((t: AgentTemplate) => t.id === id);
    
    if (index === -1) return false;
    
    userTemplates[index] = { 
      ...userTemplates[index], 
      ...updates, 
      updatedAt: new Date().toISOString() 
    };
    
    localStorage.setItem(TEMPLATES_STORAGE_KEY, JSON.stringify(userTemplates));
    return true;
  }

  static deleteTemplate(id: string): boolean {
    // Only allow deleting user-created templates, not pre-configured ones
    const stored = localStorage.getItem(TEMPLATES_STORAGE_KEY);
    const userTemplates = stored ? JSON.parse(stored) : [];
    const filteredTemplates = userTemplates.filter((t: AgentTemplate) => t.id !== id);
    
    if (filteredTemplates.length === userTemplates.length) return false;
    
    localStorage.setItem(TEMPLATES_STORAGE_KEY, JSON.stringify(filteredTemplates));
    return true;
  }

  static incrementUsageCount(id: string): void {
    const template = this.getTemplate(id);
    if (template) {
      this.updateTemplate(id, { usageCount: template.usageCount + 1 });
    }
  }

  static getCategories(): TemplateCategory[] {
    try {
      const stored = localStorage.getItem(CATEGORIES_STORAGE_KEY);
      const categories = stored ? JSON.parse(stored) : defaultCategories;
      
      // Ensure default categories are present
      if (!stored) {
        localStorage.setItem(CATEGORIES_STORAGE_KEY, JSON.stringify(defaultCategories));
      }
      
      return categories;
    } catch (error) {
      console.error('Error loading template categories:', error);
      return defaultCategories;
    }
  }

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

  static exportTemplate(id: string): string | null {
    const template = this.getTemplate(id);
    if (!template) return null;
    
    return JSON.stringify(template, null, 2);
  }

  static importTemplate(templateJson: string): AgentTemplate | null {
    try {
      const template: AgentTemplate = JSON.parse(templateJson);
      
      // Validate required fields
      if (!template.name || !template.wizardData) {
        throw new Error('Invalid template format');
      }
      
      // Generate new ID and timestamps
      const importedTemplate: AgentTemplate = {
        ...template,
        id: crypto.randomUUID(),
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        usageCount: 0
      };
      
      const templates = this.getTemplates();
      templates.push(importedTemplate);
      localStorage.setItem(TEMPLATES_STORAGE_KEY, JSON.stringify(templates));
      
      return importedTemplate;
    } catch (error) {
      console.error('Error importing template:', error);
      return null;
    }
  }
}