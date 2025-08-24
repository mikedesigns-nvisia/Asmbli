import type { MCPServer } from '@agentengine/shared-types';
import type { MCPServerTemplate, MCPConfigField } from './index';
import { ALL_TEMPLATES } from './index';
import { ENTERPRISE_TEMPLATES } from './enterprise';

export interface TemplateValidationResult {
  valid: boolean;
  errors: TemplateValidationError[];
  warnings: string[];
}

export interface TemplateValidationError {
  field: string;
  message: string;
  code: string;
}

export interface TemplateInstantiationResult {
  success: boolean;
  server?: MCPServer;
  errors?: string[];
  warnings?: string[];
}

export class MCPTemplateManager {
  private templates: MCPServerTemplate[];

  constructor(includeEnterprise: boolean = true) {
    this.templates = includeEnterprise 
      ? [...ALL_TEMPLATES, ...ENTERPRISE_TEMPLATES]
      : ALL_TEMPLATES;
  }

  /**
   * Get all available templates
   */
  getAllTemplates(): MCPServerTemplate[] {
    return this.templates;
  }

  /**
   * Get template by ID
   */
  getTemplate(id: string): MCPServerTemplate | undefined {
    return this.templates.find(template => template.id === id);
  }

  /**
   * Get templates by category
   */
  getTemplatesByCategory(category: string): MCPServerTemplate[] {
    return this.templates.filter(template => template.category === category);
  }

  /**
   * Get all unique categories
   */
  getCategories(): string[] {
    return [...new Set(this.templates.map(template => template.category))];
  }

  /**
   * Search templates by query
   */
  searchTemplates(query: string): MCPServerTemplate[] {
    const lowerQuery = query.toLowerCase();
    return this.templates.filter(template =>
      template.name.toLowerCase().includes(lowerQuery) ||
      template.description.toLowerCase().includes(lowerQuery) ||
      template.tags.some(tag => tag.toLowerCase().includes(lowerQuery)) ||
      template.category.toLowerCase().includes(lowerQuery)
    );
  }

  /**
   * Get templates by difficulty level
   */
  getTemplatesByDifficulty(difficulty: 'beginner' | 'intermediate' | 'advanced'): MCPServerTemplate[] {
    return this.templates.filter(template => template.difficulty === difficulty);
  }

  /**
   * Get popular/recommended templates
   */
  getPopularTemplates(): MCPServerTemplate[] {
    // Return templates that are commonly used and beginner-friendly
    return this.templates.filter(template => 
      template.difficulty === 'beginner' || 
      ['filesystem-template', 'github-template', 'memory-template', 'search-template'].includes(template.id)
    );
  }

  /**
   * Validate template configuration values
   */
  validateTemplateConfig(templateId: string, config: Record<string, any>): TemplateValidationResult {
    const template = this.getTemplate(templateId);
    if (!template) {
      return {
        valid: false,
        errors: [{ field: 'template', message: 'Template not found', code: 'TEMPLATE_NOT_FOUND' }],
        warnings: []
      };
    }

    const errors: TemplateValidationError[] = [];
    const warnings: string[] = [];

    // Validate each config field
    for (const field of template.configFields) {
      const value = config[field.name];

      // Required field validation
      if (field.required && (value === undefined || value === null || value === '')) {
        errors.push({
          field: field.name,
          message: `${field.label} is required`,
          code: 'REQUIRED_FIELD'
        });
        continue;
      }

      // Skip validation if field is not provided and not required
      if (value === undefined || value === null || value === '') {
        continue;
      }

      // Type validation
      const typeError = this.validateFieldType(field, value);
      if (typeError) {
        errors.push(typeError);
        continue;
      }

      // Custom validation rules
      const validationError = this.validateFieldRules(field, value);
      if (validationError) {
        errors.push(validationError);
      }

      // Warnings for potential issues
      const warning = this.checkFieldWarnings(field, value);
      if (warning) {
        warnings.push(warning);
      }
    }

    return {
      valid: errors.length === 0,
      errors,
      warnings
    };
  }

  /**
   * Create an MCP server instance from a template and configuration
   */
  instantiateTemplate(templateId: string, config: Record<string, any>, serverId?: string): TemplateInstantiationResult {
    const template = this.getTemplate(templateId);
    if (!template) {
      return {
        success: false,
        errors: ['Template not found']
      };
    }

    // Validate configuration first
    const validation = this.validateTemplateConfig(templateId, config);
    if (!validation.valid) {
      return {
        success: false,
        errors: validation.errors.map(error => `${error.field}: ${error.message}`),
        warnings: validation.warnings
      };
    }

    try {
      // Create server instance with template data and user config
      const server: MCPServer = {
        ...template.server,
        id: serverId || template.server.id,
        enabled: true,
        config: {
          ...template.server.config,
          ...config
        }
      };

      // Add auth configuration if provided
      if (template.server.requiredAuth) {
        const authConfig: Record<string, any> = {};
        for (const auth of template.server.requiredAuth) {
          if (config[auth.name]) {
            authConfig[auth.name] = config[auth.name];
          }
        }
        if (Object.keys(authConfig).length > 0) {
          server.config = { ...server.config, ...authConfig };
        }
      }

      return {
        success: true,
        server,
        warnings: validation.warnings
      };

    } catch (error) {
      return {
        success: false,
        errors: [`Failed to instantiate template: ${error}`]
      };
    }
  }

  /**
   * Get template configuration schema for UI generation
   */
  getTemplateSchema(templateId: string): MCPConfigField[] {
    const template = this.getTemplate(templateId);
    return template ? template.configFields : [];
  }

  /**
   * Get template setup information
   */
  getTemplateSetupInfo(templateId: string): {
    instructions: string[];
    prerequisites: string[];
    examples: any[];
  } | null {
    const template = this.getTemplate(templateId);
    if (!template) return null;

    return {
      instructions: template.setupInstructions,
      prerequisites: template.prerequisites,
      examples: template.examples
    };
  }

  /**
   * Export template as JSON for sharing or backup
   */
  exportTemplate(templateId: string): string | null {
    const template = this.getTemplate(templateId);
    if (!template) return null;

    return JSON.stringify(template, null, 2);
  }

  /**
   * Import custom template from JSON
   */
  importTemplate(templateJson: string): { success: boolean; error?: string; template?: MCPServerTemplate } {
    try {
      const template = JSON.parse(templateJson) as MCPServerTemplate;
      
      // Basic validation
      if (!template.id || !template.name || !template.server) {
        return { success: false, error: 'Invalid template structure' };
      }

      // Check for ID conflicts
      if (this.getTemplate(template.id)) {
        return { success: false, error: `Template with ID '${template.id}' already exists` };
      }

      // Add to templates list
      this.templates.push(template);

      return { success: true, template };

    } catch (error) {
      return { success: false, error: 'Invalid JSON format' };
    }
  }

  // Private validation methods
  private validateFieldType(field: MCPConfigField, value: any): TemplateValidationError | null {
    switch (field.type) {
      case 'number':
        if (typeof value !== 'number' && isNaN(Number(value))) {
          return {
            field: field.name,
            message: `${field.label} must be a number`,
            code: 'INVALID_TYPE'
          };
        }
        break;

      case 'boolean':
        if (typeof value !== 'boolean') {
          return {
            field: field.name,
            message: `${field.label} must be true or false`,
            code: 'INVALID_TYPE'
          };
        }
        break;

      case 'url':
        try {
          new URL(value);
        } catch {
          return {
            field: field.name,
            message: `${field.label} must be a valid URL`,
            code: 'INVALID_URL'
          };
        }
        break;

      case 'path':
        if (typeof value !== 'string' || value.trim().length === 0) {
          return {
            field: field.name,
            message: `${field.label} must be a valid path`,
            code: 'INVALID_PATH'
          };
        }
        break;

      case 'select':
        if (field.options && !field.options.some(option => option.value === value)) {
          return {
            field: field.name,
            message: `${field.label} must be one of the available options`,
            code: 'INVALID_OPTION'
          };
        }
        break;
    }

    return null;
  }

  private validateFieldRules(field: MCPConfigField, value: any): TemplateValidationError | null {
    if (!field.validation) return null;

    const validation = field.validation;

    // Pattern validation
    if (validation.pattern && typeof value === 'string') {
      const regex = new RegExp(validation.pattern);
      if (!regex.test(value)) {
        return {
          field: field.name,
          message: validation.message || `${field.label} format is invalid`,
          code: 'PATTERN_MISMATCH'
        };
      }
    }

    // Number range validation
    if (field.type === 'number') {
      const numValue = typeof value === 'number' ? value : Number(value);
      
      if (validation.min !== undefined && numValue < validation.min) {
        return {
          field: field.name,
          message: validation.message || `${field.label} must be at least ${validation.min}`,
          code: 'MIN_VALUE'
        };
      }

      if (validation.max !== undefined && numValue > validation.max) {
        return {
          field: field.name,
          message: validation.message || `${field.label} must not exceed ${validation.max}`,
          code: 'MAX_VALUE'
        };
      }
    }

    return null;
  }

  private checkFieldWarnings(field: MCPConfigField, value: any): string | null {
    // API token warnings
    if (field.type === 'password' && field.name.includes('TOKEN')) {
      if (typeof value === 'string' && value.length < 20) {
        return `${field.label} seems short for an API token`;
      }
    }

    // Path warnings
    if (field.type === 'path' && typeof value === 'string') {
      if (value.includes(' ') && !value.includes('"')) {
        return `${field.label} contains spaces and should be quoted`;
      }
    }

    // URL warnings
    if (field.type === 'url' && typeof value === 'string') {
      if (value.startsWith('http://')) {
        return `${field.label} uses HTTP instead of HTTPS (less secure)`;
      }
    }

    return null;
  }
}