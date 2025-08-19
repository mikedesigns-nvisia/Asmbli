export interface MCPServer {
  id: string
  name: string
  description: string
  status: 'connected' | 'disconnected' | 'error'
  icon: string
}

export interface Agent {
  id: string
  name: string
  description: string
  category: string
  tags: string[]
  mcpServers: MCPServer[]
  systemPrompt: string
  modelConfig: {
    temperature: number
    maxTokens: number
    topP: number
  }
  capabilities: string[]
  avatar?: string
}

export const agentLibrary: Agent[] = [
  {
    id: 'research-assistant',
    name: 'Research Assistant',
    description: 'Advanced research agent with web search, document analysis, and citation capabilities',
    category: 'Research',
    tags: ['research', 'analysis', 'citations', 'web-search'],
    mcpServers: [
      {
        id: 'search',
        name: 'Web Search',
        description: 'Real-time web search capabilities',
        status: 'connected',
        icon: 'Search'
      },
      {
        id: 'filesystem',
        name: 'Filesystem',
        description: 'File operations and document access',
        status: 'connected',
        icon: 'FileText'
      },
      {
        id: 'memory',
        name: 'Memory',
        description: 'Knowledge storage and retrieval',
        status: 'connected',
        icon: 'Database'
      },
      {
        id: 'notion',
        name: 'Notion',
        description: 'Research documentation and knowledge organization',
        status: 'connected',
        icon: 'FileText'
      }
    ],
    systemPrompt: 'You are a professional research assistant. Your role is to help users conduct thorough research, analyze information from multiple sources, and provide well-cited, accurate summaries. Always verify information from multiple sources and provide proper citations. Use Notion to organize research findings and maintain comprehensive documentation.',"
    modelConfig: {
      temperature: 0.3,
      maxTokens: 4096,
      topP: 0.9
    },
    capabilities: ['Web search', 'Document analysis', 'Citation generation', 'Fact verification']
  },
  {
    id: 'code-assistant',
    name: 'Code Assistant',
    description: 'Full-stack development assistant with GitHub integration and code analysis',
    category: 'Development',
    tags: ['coding', 'github', 'debugging', 'development'],
    mcpServers: [
      {
        id: 'github',
        name: 'GitHub',
        description: 'Repository management and code operations',
        status: 'connected',
        icon: 'Github'
      },
      {
        id: 'filesystem',
        name: 'Filesystem',
        description: 'File operations and code access',
        status: 'connected',
        icon: 'FileText'
      },
      {
        id: 'git',
        name: 'Git',
        description: 'Version control operations',
        status: 'connected',
        icon: 'Code'
      },
      {
        id: 'vscode',
        name: 'VSCode',
        description: 'Code editing and workspace control',
        status: 'connected',
        icon: 'Code'
      },
      {
        id: 'slack',
        name: 'Slack',
        description: 'Team communication and code collaboration',
        status: 'connected',
        icon: 'MessageSquare'
      }
    ],
    systemPrompt: 'You are an expert software developer and code assistant. Help users write clean, efficient code, debug issues, and follow best practices. You have access to GitHub repositories and can perform code analysis, reviews, and provide implementation suggestions. You can also coordinate with team members through Slack for code reviews and project updates.',
    modelConfig: {
      temperature: 0.1,
      maxTokens: 8192,
      topP: 0.95
    },
    capabilities: ['Code generation', 'Bug fixing', 'Code review', 'Architecture advice']
  },
  {
    id: 'design-assistant',
    name: 'Design Assistant',
    description: 'Creative design agent with Figma integration and visual analysis',
    category: 'Design',
    tags: ['design', 'figma', 'ui-ux', 'creative'],
    mcpServers: [
      {
        id: 'figma',
        name: 'Figma',
        description: 'Design files and component access',
        status: 'connected',
        icon: 'Figma'
      },
      {
        id: 'filesystem',
        name: 'Filesystem',
        description: 'File operations and asset management',
        status: 'connected',
        icon: 'FileText'
      },
      {
        id: 'vscode',
        name: 'VSCode',
        description: 'Code editing and component implementation',
        status: 'connected',
        icon: 'Code'
      },
      {
        id: 'github',
        name: 'GitHub',
        description: 'Design system repository management',
        status: 'connected',
        icon: 'Github'
      },
      {
        id: 'notion',
        name: 'Notion',
        description: 'Design documentation and specifications',
        status: 'connected',
        icon: 'FileText'
      },
      {
        id: 'slack',
        name: 'Slack',
        description: 'Design feedback and team collaboration',
        status: 'connected',
        icon: 'MessageSquare'
      }
    ],
    systemPrompt: 'You are a professional UI/UX designer and design assistant. Help users create beautiful, functional designs, analyze design systems, and provide feedback on visual hierarchy, accessibility, and user experience. Use Notion for design documentation and Slack for team collaboration and feedback collection.',"
    modelConfig: {
      temperature: 0.7,
      maxTokens: 4096,
      topP: 0.9
    },
    capabilities: ['Design feedback', 'Component creation', 'Design system analysis', 'Accessibility review']
  },
  {
    id: 'data-analyst',
    name: 'Data Analyst',
    description: 'Advanced data analysis with database access and visualization capabilities',
    category: 'Analytics',
    tags: ['data', 'analysis', 'sql', 'visualization'],
    mcpServers: [
      {
        id: 'postgresql',
        name: 'PostgreSQL',
        description: 'Database queries and schema operations',
        status: 'connected',
        icon: 'Database'
      },
      {
        id: 'filesystem',
        name: 'Filesystem',
        description: 'File operations and data access',
        status: 'connected',
        icon: 'FileText'
      },
      {
        id: 'memory',
        name: 'Memory',
        description: 'Data insights and pattern storage',
        status: 'connected',
        icon: 'Database'
      }
    ],
    systemPrompt: 'You are a professional data analyst with expertise in SQL, data visualization, and statistical analysis. Help users explore their data, identify patterns, create meaningful visualizations, and derive actionable insights.',
    modelConfig: {
      temperature: 0.2,
      maxTokens: 6144,
      topP: 0.9
    },
    capabilities: ['SQL queries', 'Data visualization', 'Statistical analysis', 'Pattern recognition']
  },
  {
    id: 'content-creator',
    name: 'Content Creator',
    description: 'Creative writing and content strategy with web research capabilities',
    category: 'Content',
    tags: ['writing', 'content', 'marketing', 'creative'],
    mcpServers: [
      {
        id: 'search',
        name: 'Web Search',
        description: 'Research trending topics and competitors',
        status: 'connected',
        icon: 'Search'
      },
      {
        id: 'filesystem',
        name: 'Filesystem',
        description: 'Content storage and management',
        status: 'connected',
        icon: 'FileText'
      },
      {
        id: 'notion',
        name: 'Notion',
        description: 'Content calendar and editorial planning',
        status: 'connected',
        icon: 'FileText'
      },
      {
        id: 'slack',
        name: 'Slack',
        description: 'Team collaboration and content approvals',
        status: 'connected',
        icon: 'MessageSquare'
      }
    ],
    systemPrompt: 'You are a professional content creator and copywriter. Help users create engaging content, develop content strategies, write compelling copy, and optimize content for different platforms and audiences. Use Notion for content planning and editorial calendars, and Slack for team collaboration and content approvals.',"
    modelConfig: {
      temperature: 0.8,
      maxTokens: 4096,
      topP: 0.95
    },
    capabilities: ['Content writing', 'SEO optimization', 'Social media strategy', 'Brand voice development']
  },
  {
    id: 'project-manager',
    name: 'Project Manager',
    description: 'Comprehensive project management with Linear, Notion, and Slack integration',
    category: 'Management',
    tags: ['project-management', 'team-coordination', 'planning', 'collaboration'],
    mcpServers: [
      {
        id: 'linear',
        name: 'Linear',
        description: 'Issue tracking and project management',
        status: 'connected',
        icon: 'Target'
      },
      {
        id: 'notion',
        name: 'Notion',
        description: 'Documentation and knowledge management',
        status: 'connected',
        icon: 'FileText'
      },
      {
        id: 'slack',
        name: 'Slack',
        description: 'Team communication and updates',
        status: 'connected',
        icon: 'MessageSquare'
      },
      {
        id: 'github',
        name: 'GitHub',
        description: 'Code repository and development tracking',
        status: 'connected',
        icon: 'Github'
      }
    ],
    systemPrompt: 'You are an experienced project manager specializing in software development teams. Help coordinate projects across Linear for task tracking, Notion for documentation, Slack for team communication, and GitHub for development oversight. Focus on clear communication, timeline management, and team productivity.',
    modelConfig: {
      temperature: 0.4,
      maxTokens: 4096,
      topP: 0.9
    },
    capabilities: ['Project planning', 'Task coordination', 'Team communication', 'Progress tracking', 'Documentation management']
  },
  {
    id: 'knowledge-manager',
    name: 'Knowledge Manager',
    description: 'Organizational knowledge management with Notion and search capabilities',
    category: 'Knowledge',
    tags: ['documentation', 'knowledge-base', 'organization', 'search'],
    mcpServers: [
      {
        id: 'notion',
        name: 'Notion',
        description: 'Knowledge base and documentation management',
        status: 'connected',
        icon: 'FileText'
      },
      {
        id: 'search',
        name: 'Web Search',
        description: 'External information research',
        status: 'connected',
        icon: 'Search'
      },
      {
        id: 'filesystem',
        name: 'Filesystem',
        description: 'Local document management',
        status: 'connected',
        icon: 'FileText'
      },
      {
        id: 'memory',
        name: 'Memory',
        description: 'Knowledge synthesis and connections',
        status: 'connected',
        icon: 'Database'
      }
    ],
    systemPrompt: 'You are a knowledge management specialist. Help organize information in Notion, create structured documentation, maintain knowledge bases, and ensure information is easily discoverable and actionable for teams.',
    modelConfig: {
      temperature: 0.3,
      maxTokens: 4096,
      topP: 0.9
    },
    capabilities: ['Documentation structuring', 'Knowledge synthesis', 'Information architecture', 'Search optimization']
  },
  {
    id: 'team-coordinator',
    name: 'Team Coordinator',
    description: 'Team collaboration and communication management with Slack and Linear',
    category: 'Collaboration',
    tags: ['team-management', 'communication', 'coordination', 'productivity'],
    mcpServers: [
      {
        id: 'slack',
        name: 'Slack',
        description: 'Team communication and channel management',
        status: 'connected',
        icon: 'MessageSquare'
      },
      {
        id: 'linear',
        name: 'Linear',
        description: 'Task assignment and progress tracking',
        status: 'connected',
        icon: 'Target'
      },
      {
        id: 'notion',
        name: 'Notion',
        description: 'Meeting notes and team documentation',
        status: 'connected',
        icon: 'FileText'
      }
    ],
    systemPrompt: 'You are a team coordination specialist focused on improving team communication and productivity. Help manage Slack conversations, coordinate tasks in Linear, and maintain team documentation in Notion. Facilitate clear communication and ensure everyone stays aligned.',
    modelConfig: {
      temperature: 0.5,
      maxTokens: 4096,
      topP: 0.9
    },
    capabilities: ['Team communication', 'Task delegation', 'Meeting facilitation', 'Status tracking']
  }
]

export const getAgentById = (id: string): Agent | undefined => {
  return agentLibrary.find(agent => agent.id === id)
}

export const getAgentsByCategory = (category: string): Agent[] => {
  return agentLibrary.filter(agent => agent.category === category)
}

export const searchAgents = (query: string): Agent[] => {
  const lowercaseQuery = query.toLowerCase()
  return agentLibrary.filter(agent => 
    agent.name.toLowerCase().includes(lowercaseQuery) ||
    agent.description.toLowerCase().includes(lowercaseQuery) ||
    agent.tags.some(tag => tag.toLowerCase().includes(lowercaseQuery))
  )
}