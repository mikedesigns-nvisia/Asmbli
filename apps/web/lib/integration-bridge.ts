// Bridge between unified IntegrationRegistry and web agent configurations
// This ensures consistency between desktop and web integration definitions

import { IntegrationRegistry, IntegrationDefinition, IntegrationCategory } from '@agent-engine/core';

export interface MCPServer {
  id: string;
  name: string;
  description: string;
  status: 'connected' | 'disconnected' | 'error';
  icon: string;
}

export interface Agent {
  id: string;
  name: string;
  description: string;
  category: string;
  tags: string[];
  mcpServers: MCPServer[];
  systemPrompt: string;
  modelConfig: {
    temperature: number;
    maxTokens: number;
    topP: number;
  };
  capabilities: string[];
  avatar?: string;
}

// Map IntegrationDefinitions to MCPServers for web agents
function integrationToMCPServer(integration: IntegrationDefinition): MCPServer {
  return {
    id: integration.id,
    name: integration.name,
    description: integration.description,
    status: integration.isAvailable ? 'connected' : 'disconnected',
    icon: getIconName((integration as any).icon), // Convert Flutter IconData to web icon name
  };
}

// Convert Flutter icons to web-friendly names
function getIconName(flutterIcon: any): string {
  // This is a simplified mapping - in a real implementation,
  // you'd want a comprehensive icon mapping system
  const iconMap: { [key: string]: string } = {
    'Icons.folder': 'FileText',
    'Icons.source': 'Code',
    'Icons.code': 'Github',
    'Icons.design_services': 'Figma',
    'Icons.storage': 'Database',
    'Icons.search': 'Search',
    'Icons.terminal': 'Terminal',
    'Icons.http': 'Globe',
    'Icons.psychology': 'Database',
    'Icons.chat': 'MessageSquare',
    'Icons.note': 'FileText',
    'Icons.cloud': 'Cloud',
    'Icons.linear_scale': 'Target',
    'Icons.calendar_today': 'Calendar',
    'Icons.access_time': 'Clock',
    'Icons.auto_awesome': 'Zap',
  };
  
  return iconMap[flutterIcon?.toString()] || 'Settings';
}

// Get all available integrations as MCP servers
export function getAvailableMCPServers(): MCPServer[] {
  return IntegrationRegistry.allIntegrations.map(integrationToMCPServer);
}

// Get integrations by category
export function getMCPServersByCategory(category: IntegrationCategory): MCPServer[] {
  return IntegrationRegistry.getByCategory(category).map(integrationToMCPServer);
}

// Pre-configured agent templates using unified integration definitions
export const agentTemplates: Omit<Agent, 'id' | 'mcpServers'>[] = [
  {
    name: 'Research Assistant',
    description: 'Advanced research agent with web search, document analysis, and citation capabilities',
    category: 'Research',
    tags: ['research', 'analysis', 'citations', 'web-search'],
    systemPrompt: 'You are a professional research assistant. Your role is to help users conduct thorough research, analyze information from multiple sources, and provide well-cited, accurate summaries. Always verify information from multiple sources and provide proper citations.',
    modelConfig: {
      temperature: 0.3,
      maxTokens: 4096,
      topP: 0.9
    },
    capabilities: ['Web search', 'Document analysis', 'Citation generation', 'Fact verification'],
  },
  {
    name: 'Code Assistant',
    description: 'Full-stack development assistant with GitHub integration and code analysis',
    category: 'Development',
    tags: ['coding', 'github', 'debugging', 'development'],
    systemPrompt: 'You are an expert software developer and code assistant. Help users write clean, efficient code, debug issues, and follow best practices. You have access to GitHub repositories and can perform code analysis, reviews, and provide implementation suggestions.',
    modelConfig: {
      temperature: 0.1,
      maxTokens: 8192,
      topP: 0.95
    },
    capabilities: ['Code generation', 'Bug fixing', 'Code review', 'Architecture advice'],
  },
  {
    name: 'Design Assistant',
    description: 'Creative design agent with Figma integration and visual analysis',
    category: 'Design',
    tags: ['design', 'figma', 'ui-ux', 'creative'],
    systemPrompt: 'You are a professional UI/UX designer and design assistant. Help users create beautiful, functional designs, analyze design systems, and provide feedback on visual hierarchy, accessibility, and user experience.',
    modelConfig: {
      temperature: 0.7,
      maxTokens: 4096,
      topP: 0.9
    },
    capabilities: ['Design feedback', 'Component creation', 'Design system analysis', 'Accessibility review'],
  },
  {
    name: 'Data Analyst',
    description: 'Advanced data analysis with database access and visualization capabilities',
    category: 'Analytics',
    tags: ['data', 'analysis', 'sql', 'visualization'],
    systemPrompt: 'You are a professional data analyst with expertise in SQL, data visualization, and statistical analysis. Help users explore their data, identify patterns, create meaningful visualizations, and derive actionable insights.',
    modelConfig: {
      temperature: 0.2,
      maxTokens: 6144,
      topP: 0.9
    },
    capabilities: ['SQL queries', 'Data visualization', 'Statistical analysis', 'Pattern recognition'],
  },
];

// Create agents with appropriate MCP servers based on their category and purpose
export function createAgentLibrary(): Agent[] {
  const agents: Agent[] = [];
  
  agentTemplates.forEach((template, index) => {
    const mcpServers: MCPServer[] = [];
    
    // Add relevant integrations based on agent category and purpose
    switch (template.category) {
      case 'Research':
        mcpServers.push(
          ...getMCPServersByCategory(IntegrationCategory.utilities).filter(s => s.id === 'web-search'),
          ...getMCPServersByCategory(IntegrationCategory.local).filter(s => ['filesystem', 'memory'].includes(s.id)),
          ...getMCPServersByCategory(IntegrationCategory.cloudAPIs).filter(s => s.id === 'notion')
        );
        break;
        
      case 'Development':
        mcpServers.push(
          ...getMCPServersByCategory(IntegrationCategory.cloudAPIs).filter(s => ['github', 'slack'].includes(s.id)),
          ...getMCPServersByCategory(IntegrationCategory.local).filter(s => ['filesystem', 'git'].includes(s.id))
        );
        break;
        
      case 'Design':
        mcpServers.push(
          ...getMCPServersByCategory(IntegrationCategory.cloudAPIs).filter(s => ['figma', 'github', 'notion', 'slack'].includes(s.id)),
          ...getMCPServersByCategory(IntegrationCategory.local).filter(s => s.id === 'filesystem')
        );
        break;
        
      case 'Analytics':
        mcpServers.push(
          ...getMCPServersByCategory(IntegrationCategory.databases).filter(s => s.id === 'postgresql'),
          ...getMCPServersByCategory(IntegrationCategory.local).filter(s => ['filesystem', 'memory'].includes(s.id))
        );
        break;
    }
    
    agents.push({
      id: template.name.toLowerCase().replace(/\s+/g, '-'),
      mcpServers,
      ...template,
    });
  });
  
  return agents;
}

// Export for backward compatibility
export const agentLibrary = createAgentLibrary();

export const getAgentById = (id: string): Agent | undefined => {
  return agentLibrary.find(agent => agent.id === id);
};

export const getAgentsByCategory = (category: string): Agent[] => {
  return agentLibrary.filter(agent => agent.category === category);
};

export const searchAgents = (query: string): Agent[] => {
  const lowercaseQuery = query.toLowerCase();
  return agentLibrary.filter(agent => 
    agent.name.toLowerCase().includes(lowercaseQuery) ||
    agent.description.toLowerCase().includes(lowercaseQuery) ||
    agent.tags.some(tag => tag.toLowerCase().includes(lowercaseQuery))
  );
};