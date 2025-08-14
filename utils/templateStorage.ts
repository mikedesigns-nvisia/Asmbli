import { AgentTemplate, TemplateCategory } from '../types/templates';
import { WizardData } from '../types/wizard';

const TEMPLATES_STORAGE_KEY = 'agentengine_templates';
const CATEGORIES_STORAGE_KEY = 'agentengine_template_categories';

// Default template categories
const defaultCategories: TemplateCategory[] = [
  {
    id: 'productivity',
    name: 'Productivity',
    description: 'Agents for task management, scheduling, and workflow optimization',
    icon: '⚡',
    color: '#10B981'
  },
  {
    id: 'development',
    name: 'Development',
    description: 'Code review, documentation, and development workflow agents',
    icon: '💻',
    color: '#6366F1'
  },
  {
    id: 'content',
    name: 'Content Creation',
    description: 'Writing, editing, and content generation assistants',
    icon: '✍️',
    color: '#F59E0B'
  },
  {
    id: 'research',
    name: 'Research & Analysis',
    description: 'Data analysis, research, and information gathering agents',
    icon: '🔍',
    color: '#8B5CF6'
  },
  {
    id: 'customer-service',
    name: 'Customer Service',
    description: 'Support, FAQ, and customer interaction agents',
    icon: '🤝',
    color: '#06B6D4'
  },
  {
    id: 'custom',
    name: 'Custom',
    description: 'Specialized and custom-built agent templates',
    icon: '🎯',
    color: '#EF4444'
  }
];

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

  static getTemplates(): AgentTemplate[] {
    try {
      const stored = localStorage.getItem(TEMPLATES_STORAGE_KEY);
      return stored ? JSON.parse(stored) : [];
    } catch (error) {
      console.error('Error loading templates:', error);
      return [];
    }
  }

  static getTemplate(id: string): AgentTemplate | null {
    const templates = this.getTemplates();
    return templates.find(t => t.id === id) || null;
  }

  static updateTemplate(id: string, updates: Partial<AgentTemplate>): boolean {
    const templates = this.getTemplates();
    const index = templates.findIndex(t => t.id === id);
    
    if (index === -1) return false;
    
    templates[index] = { 
      ...templates[index], 
      ...updates, 
      updatedAt: new Date().toISOString() 
    };
    
    localStorage.setItem(TEMPLATES_STORAGE_KEY, JSON.stringify(templates));
    return true;
  }

  static deleteTemplate(id: string): boolean {
    const templates = this.getTemplates();
    const filteredTemplates = templates.filter(t => t.id !== id);
    
    if (filteredTemplates.length === templates.length) return false;
    
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