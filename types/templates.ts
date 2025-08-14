import { WizardData } from './wizard';

export interface AgentTemplate {
  id: string;
  name: string;
  description: string;
  category: string;
  tags: string[];
  createdAt: string;
  updatedAt: string;
  author?: string;
  isPublic: boolean;
  usageCount: number;
  wizardData: WizardData;
  thumbnail?: string;
}

export interface TemplateCategory {
  id: string;
  name: string;
  description: string;
  icon: string;
  color: string;
}

export interface TemplateFilters {
  category?: string;
  tags?: string[];
  searchQuery?: string;
}