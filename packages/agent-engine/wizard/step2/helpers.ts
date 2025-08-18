import { Extension, ExtensionCategory } from './types';

export const getRecommendations = (
  primaryPurpose: string, 
  deploymentTargets: string[]
): string[] => {
  const recommendations: string[] = [];

  // Base recommendations by purpose
  switch (primaryPurpose) {
    case 'chatbot':
      recommendations.push('slack', 'discord-bot', 'telegram-bot', 'openai-api', 'anthropic-api');
      break;
    case 'content-creator':
      recommendations.push('openai-api', 'github', 'notion-api', 'brave-browser');
      break;
    case 'data-analyst':
      recommendations.push('supabase-api', 'openai-api', 'google-analytics', 'mixpanel-api');
      break;
    case 'developer-assistant':
      recommendations.push('github', 'storybook-api', 'openai-api', 'chrome-extension');
      break;
    case 'research-assistant':
      recommendations.push('openai-api', 'notion-api', 'google-drive', 'brave-browser');
      break;
    case 'design-agent':
      recommendations.push('figma-mcp', 'storybook-api', 'design-tokens', 'supabase-api');
      break;
    case 'productivity-assistant':
      recommendations.push('zapier-webhooks', 'gmail-api', 'notion-api', 'brave-browser');
      break;
    case 'web-automation':
      recommendations.push('brave-browser', 'chrome-extension', 'firefox-extension', 'zapier-webhooks');
      break;
  }

  // Add design-specific recommendations for design-related purposes
  if (primaryPurpose.includes('design') || deploymentTargets.includes('figma')) {
    recommendations.push('figma-mcp', 'design-tokens', 'storybook-api');
  }

  return Array.from(new Set(recommendations)); // Remove duplicates
};

export const filterExtensions = (
  categories: ExtensionCategory[],
  searchQuery: string,
  activePlatformFilter: string,
  activeFilters: string[],
  recommendations: string[],
  selectedExtensions: Extension[]
): ExtensionCategory[] => {
  if (!categories || !Array.isArray(categories)) {
    return [];
  }

  const isExtensionSelected = (extensionId: string) => {
    return selectedExtensions.some(s => s.id === extensionId);
  };

  return categories.map(category => ({
    ...category,
    extensions: (category.extensions || []).filter(extension => {
      // Search filter
      const matchesSearch = searchQuery === '' || 
        extension.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        extension.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
        extension.category.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (extension.capabilities || []).some(cap => cap.toLowerCase().includes(searchQuery.toLowerCase()));

      // Platform filter - handle both primary and supported connection types
      const matchesPlatform = activePlatformFilter === 'all' || 
        extension.connectionType === activePlatformFilter ||
        (extension.supportedConnectionTypes && extension.supportedConnectionTypes.includes(activePlatformFilter)) ||
        (activePlatformFilter === 'bot-token' && extension.authMethod === 'bot-token') ||
        (activePlatformFilter === 'oauth' && extension.authMethod === 'oauth');

      // Active filters
      const matchesFilters = activeFilters.length === 0 || activeFilters.some(filter => {
        switch (filter) {
          case 'recommended':
            return recommendations.includes(extension.id);
          case 'selected':
            return isExtensionSelected(extension.id);
          case 'verified':
            return extension.pricing === 'free' || extension.provider === 'GitHub'; // Simple verification logic
          case 'microsoft':
            return extension.provider === 'Microsoft' || extension.category.includes('Microsoft');
          case 'popular':
            return extension.complexity === 'low' || extension.features.length > 5;
          case 'enterprise':
            return extension.pricing === 'paid' || extension.setupComplexity >= 3;
          case 'ai-powered':
            return extension.category === 'AI & Machine Learning' || extension.provider.includes('AI');
          case 'translation':
            return extension.connectionType === 'api'; // Simple translation support logic
          case 'official-mcp':
            return extension.connectionType === 'mcp';
          case 'mcp':
            return extension.connectionType === 'mcp' || 
                   extension.type === 'mcp-server' || 
                   extension.id.includes('mcp') ||
                   (extension.supportedConnectionTypes && extension.supportedConnectionTypes.includes('mcp'));
          case 'anthropic':
            return extension.provider === 'Anthropic' || extension.id.includes('anthropic');
          case 'openai':
            return extension.provider === 'OpenAI' || extension.id.includes('openai');
          case 'design':
            return extension.category === 'Design & Prototyping';
          case 'browser':
            return extension.category === 'Browser & Web Tools';
          case 'automation':
            return extension.category === 'Automation & Productivity';
          case 'email':
            return extension.category === 'Email & Communication';
          case 'free':
            return extension.pricing === 'free';
          case 'privacy':
            return extension.provider === 'Brave Software' || extension.provider === 'Mozilla' || extension.features.some(f => f.toLowerCase().includes('privacy'));
          default:
            return true;
        }
      });

      return matchesSearch && matchesPlatform && matchesFilters;
    })
  })).filter(category => category.extensions && category.extensions.length > 0);
};

export const sortExtensions = (
  categories: ExtensionCategory[],
  sortBy: 'popular' | 'recent' | 'alphabetical' | 'security'
): ExtensionCategory[] => {
  if (!categories || !Array.isArray(categories)) {
    return [];
  }

  const sortedCategories = [...categories];
  
  sortedCategories.forEach(category => {
    if (category.extensions && Array.isArray(category.extensions)) {
      category.extensions.sort((a, b) => {
        switch (sortBy) {
          case 'popular':
            // Sort by number of features as a proxy for popularity
            return (b.features?.length || 0) - (a.features?.length || 0);
          case 'recent':
            // Sort by complexity as a proxy for recent updates
            const complexityOrder = { low: 1, medium: 2, high: 3 };
            return complexityOrder[b.complexity as keyof typeof complexityOrder] - 
                   complexityOrder[a.complexity as keyof typeof complexityOrder];
          case 'alphabetical':
            return a.name.localeCompare(b.name);
          case 'security':
            const securityOrder = { high: 3, medium: 2, low: 1 };
            return (securityOrder[b.setupComplexity as keyof typeof securityOrder] || 1) - 
                   (securityOrder[a.setupComplexity as keyof typeof securityOrder] || 1);
          default:
            return 0;
        }
      });
    }
  });

  return sortedCategories;
};

export const applyTemplate = (
  template: string,
  recommendations: string[],
  deploymentTargets: string[],
  availableExtensions: Extension[]
): Extension[] => {
  if (!availableExtensions || !Array.isArray(availableExtensions)) {
    return [];
  }

  let templateExtensions: Array<{id: string, platforms: string[]}> = [];
  
  switch (template) {
    case 'development':
      templateExtensions = [
        { id: 'github', platforms: ['api'] },
        { id: 'storybook-api', platforms: ['api'] },
        { id: 'openai-api', platforms: ['api'] }
      ];
      break;
    case 'microsoft':
      templateExtensions = [
        { id: 'microsoft-teams', platforms: ['api'] },
        { id: 'sharepoint-online', platforms: ['api'] },
        { id: 'onedrive-api', platforms: ['api'] },
        { id: 'outlook-api', platforms: ['api'] },
        { id: 'power-automate', platforms: ['api'] },
        { id: 'microsoft-graph', platforms: ['api'] },
        { id: 'office-365-api', platforms: ['api'] }
      ];
      break;
    case 'universal':
      templateExtensions = [
        { id: 'github', platforms: ['api'] },
        { id: 'slack', platforms: ['api'] },
        { id: 'openai-api', platforms: ['api'] },
        { id: 'notion-api', platforms: ['api'] }
      ];
      break;
    case 'recommended':
      templateExtensions = recommendations.map(id => ({ 
        id, 
        platforms: ['api'] 
      }));
      break;
    case 'mcp-core':
      templateExtensions = [
        { id: 'figma-mcp', platforms: ['mcp'] },
        { id: 'storybook-api', platforms: ['api'] },
        { id: 'supabase-api', platforms: ['api'] }
      ];
      break;
    case 'openai-suite':
      templateExtensions = [
        { id: 'openai-api', platforms: ['api'] },
        { id: 'anthropic-api', platforms: ['api'] }
      ];
      break;
    case 'design':
      templateExtensions = [
        { id: 'figma-mcp', platforms: ['mcp'] },
        { id: 'design-tokens', platforms: ['api'] },
        { id: 'storybook-api', platforms: ['api'] },
        { id: 'supabase-api', platforms: ['api'] }
      ];
      break;
    case 'browser-tools':
      templateExtensions = [
        { id: 'brave-browser', platforms: ['extension'] },
        { id: 'chrome-extension', platforms: ['extension'] },
        { id: 'firefox-extension', platforms: ['extension'] }
      ];
      break;
    case 'productivity':
      templateExtensions = [
        { id: 'zapier-webhooks', platforms: ['webhook'] },
        { id: 'outlook-api', platforms: ['api'] },
        { id: 'notion-api', platforms: ['api'] },
        { id: 'power-automate', platforms: ['api'] }
      ];
      break;
  }

  return templateExtensions
    .map(({ id, platforms }) => {
      const template = availableExtensions.find(s => s.id === id);
      return template ? { 
        ...template, 
        enabled: true, 
        selectedPlatforms: platforms,
        status: 'configuring' as const, 
        configProgress: 50 
      } : null;
    })
    .filter(Boolean) as Extension[];
};