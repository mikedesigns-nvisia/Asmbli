import { Extension } from '../types/wizard';

export const extensionsLibrary: Extension[] = [
  // Core MCP Server Extensions
  {
    id: 'filesystem-mcp',
    name: 'Filesystem MCP Server',
    description: 'Access and manage local files and directories through Model Context Protocol',
    category: 'Development & Code',
    provider: 'MCP Core',
    complexity: 'low',
    enabled: false,
    connectionType: 'mcp',
    authMethod: 'none',
    pricing: 'free',
    features: [
      'Read and write local files',
      'Directory traversal and listing',
      'File search and pattern matching',
      'File metadata access',
      'Permission management',
      'Batch operations',
      'File watching and monitoring',
      'Safe sandbox operations'
    ],
    capabilities: [
      'File operations',
      'Directory access',
      'Search functionality',
      'Metadata extraction',
      'Permission control',
      'Batch processing',
      'File monitoring',
      'Sandbox security'
    ],
    requirements: [
      'Local filesystem access permissions',
      'MCP server runtime',
      'Directory permissions configuration'
    ],
    documentation: 'https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem',
    setupComplexity: 1,
    configuration: {
      allowedPaths: [],
      readOnly: false,
      maxFileSize: '10MB',
      allowedExtensions: ['*']
    }
  },
  {
    id: 'git-mcp',
    name: 'Git MCP Server',
    description: 'Git repository operations and version control through Model Context Protocol',
    category: 'Development & Code',
    provider: 'MCP Core',
    complexity: 'medium',
    enabled: false,
    connectionType: 'mcp',
    authMethod: 'ssh-key',
    pricing: 'free',
    features: [
      'Repository cloning and initialization',
      'Branch management and switching',
      'Commit history and diff analysis',
      'File staging and committing',
      'Remote repository operations',
      'Merge conflict resolution',
      'Tag and release management',
      'Submodule support'
    ],
    capabilities: [
      'Repository operations',
      'Branch management',
      'Version history',
      'File tracking',
      'Remote sync',
      'Conflict resolution',
      'Release management',
      'Submodule handling'
    ],
    requirements: [
      'Git installed locally',
      'Repository access permissions',
      'SSH keys or authentication setup'
    ],
    documentation: 'https://github.com/modelcontextprotocol/servers/tree/main/src/git',
    setupComplexity: 2,
    configuration: {
      defaultBranch: 'main',
      remoteUrl: '',
      sshKey: '',
      author: { name: '', email: '' }
    }
  },
  {
    id: 'postgres-mcp',
    name: 'PostgreSQL MCP Server',
    description: 'PostgreSQL database operations and queries through Model Context Protocol',
    category: 'Analytics & Data',
    provider: 'MCP Core',
    complexity: 'high',
    enabled: false,
    connectionType: 'mcp',
    authMethod: 'database-credentials',
    pricing: 'free',
    features: [
      'SQL query execution',
      'Database schema introspection',
      'Table and view operations',
      'Data insertion and updates',
      'Transaction management',
      'Stored procedure execution',
      'Index and performance analysis',
      'Connection pooling'
    ],
    capabilities: [
      'SQL operations',
      'Schema management',
      'Data manipulation',
      'Transaction control',
      'Procedure execution',
      'Performance analysis',
      'Connection management',
      'Security controls'
    ],
    requirements: [
      'PostgreSQL database access',
      'Database credentials',
      'Network connectivity to database'
    ],
    documentation: 'https://github.com/modelcontextprotocol/servers/tree/main/src/postgres',
    setupComplexity: 4,
    configuration: {
      host: 'localhost',
      port: 5432,
      database: '',
      username: '',
      password: '',
      ssl: true
    }
  },
  {
    id: 'memory-mcp',
    name: 'Memory MCP Server',
    description: 'Persistent memory and knowledge base management for AI agents',
    category: 'AI & Machine Learning',
    provider: 'MCP Core',
    complexity: 'medium',
    enabled: false,
    connectionType: 'mcp',
    authMethod: 'none',
    pricing: 'free',
    features: [
      'Persistent knowledge storage',
      'Semantic search and retrieval',
      'Context-aware memory management',
      'Entity relationship tracking',
      'Memory consolidation',
      'Fact verification and updates',
      'Memory expiration policies',
      'Cross-session continuity'
    ],
    capabilities: [
      'Knowledge storage',
      'Semantic search',
      'Context management',
      'Relationship tracking',
      'Memory consolidation',
      'Fact management',
      'Policy enforcement',
      'Session continuity'
    ],
    requirements: [
      'Vector database or embedding storage',
      'Memory persistence layer',
      'Embedding model access'
    ],
    documentation: 'https://github.com/modelcontextprotocol/servers/tree/main/src/memory',
    setupComplexity: 3,
    configuration: {
      storageBackend: 'sqlite',
      embeddingModel: 'text-embedding-3-small',
      maxMemories: 10000,
      retentionDays: 30
    }
  },
  {
    id: 'search-mcp',
    name: 'Search MCP Server',
    description: 'Web search and information retrieval through Model Context Protocol',
    category: 'Browser & Web Tools',
    provider: 'MCP Core',
    complexity: 'low',
    enabled: false,
    connectionType: 'mcp',
    authMethod: 'api-key',
    pricing: 'freemium',
    features: [
      'Web search with multiple engines',
      'Real-time information retrieval',
      'Search result ranking and filtering',
      'Domain-specific searches',
      'Image and video search',
      'News and recent content',
      'Safe search filtering',
      'Multi-language support'
    ],
    capabilities: [
      'Web search',
      'Information retrieval',
      'Result filtering',
      'Domain searches',
      'Media search',
      'News retrieval',
      'Content filtering',
      'Language support'
    ],
    requirements: [
      'Search API keys (Google, Bing, etc.)',
      'Rate limiting configuration',
      'Content filtering policies'
    ],
    documentation: 'https://github.com/modelcontextprotocol/servers/tree/main/src/search',
    setupComplexity: 2,
    configuration: {
      searchEngine: 'google',
      apiKey: '',
      maxResults: 10,
      safeSearch: 'moderate'
    }
  },
  {
    id: 'terminal-mcp',
    name: 'Terminal MCP Server',
    description: 'Execute shell commands and terminal operations through Model Context Protocol',
    category: 'Development & Code',
    provider: 'MCP Core',
    complexity: 'high',
    enabled: false,
    connectionType: 'mcp',
    authMethod: 'none',
    pricing: 'free',
    features: [
      'Shell command execution',
      'Environment variable management',
      'Process monitoring and control',
      'File system operations',
      'Package manager integration',
      'Build tool automation',
      'System information queries',
      'Security sandboxing'
    ],
    capabilities: [
      'Command execution',
      'Environment control',
      'Process management',
      'File operations',
      'Package management',
      'Build automation',
      'System queries',
      'Security controls'
    ],
    requirements: [
      'Terminal/shell access',
      'Execution permissions',
      'Security policy configuration'
    ],
    documentation: 'https://github.com/modelcontextprotocol/servers/tree/main/src/terminal',
    setupComplexity: 4,
    configuration: {
      allowedCommands: [],
      workingDirectory: '/tmp',
      timeout: 30,
      sandboxed: true
    }
  },
  {
    id: 'http-mcp',
    name: 'HTTP MCP Server',
    description: 'HTTP client for API requests and web service integration',
    category: 'Development & Code',
    provider: 'MCP Core',
    complexity: 'medium',
    enabled: false,
    connectionType: 'mcp',
    authMethod: 'api-key',
    pricing: 'free',
    features: [
      'HTTP GET, POST, PUT, DELETE requests',
      'Request header and body customization',
      'Authentication handling',
      'Response parsing and formatting',
      'Error handling and retries',
      'Rate limiting and throttling',
      'SSL/TLS certificate validation',
      'Proxy and middleware support'
    ],
    capabilities: [
      'HTTP operations',
      'Request customization',
      'Authentication',
      'Response handling',
      'Error management',
      'Rate limiting',
      'SSL validation',
      'Proxy support'
    ],
    requirements: [
      'Network connectivity',
      'API endpoints and credentials',
      'SSL certificates if required'
    ],
    documentation: 'https://github.com/modelcontextprotocol/servers/tree/main/src/http',
    setupComplexity: 2,
    configuration: {
      baseUrl: '',
      defaultHeaders: {},
      timeout: 10000,
      retries: 3
    }
  },
  {
    id: 'calendar-mcp',
    name: 'Calendar MCP Server',
    description: 'Calendar and scheduling operations through Model Context Protocol',
    category: 'Automation & Productivity',
    provider: 'MCP Core',
    complexity: 'medium',
    enabled: false,
    connectionType: 'mcp',
    authMethod: 'oauth',
    pricing: 'free',
    features: [
      'Event creation and management',
      'Calendar synchronization',
      'Meeting scheduling',
      'Availability checking',
      'Reminder and notification setup',
      'Recurring event handling',
      'Multi-calendar support',
      'Time zone management'
    ],
    capabilities: [
      'Event management',
      'Calendar sync',
      'Scheduling',
      'Availability',
      'Notifications',
      'Recurring events',
      'Multi-calendar',
      'Time zones'
    ],
    requirements: [
      'Calendar service access (Google, Outlook, etc.)',
      'OAuth credentials',
      'Calendar permissions'
    ],
    documentation: 'https://github.com/modelcontextprotocol/servers/tree/main/src/calendar',
    setupComplexity: 3,
    configuration: {
      calendarProvider: 'google',
      defaultCalendar: '',
      reminderMinutes: 15,
      timeZone: 'UTC'
    }
  },

  // Design & Prototyping Extensions
  {
    id: 'figma-mcp',
    name: 'Figma MCP Server',
    description: 'Connect to Figma files, components, and design systems through Model Context Protocol',
    category: 'Design & Prototyping',
    provider: 'Figma',
    complexity: 'medium',
    enabled: false,
    connectionType: 'mcp',
    authMethod: 'oauth',
    pricing: 'freemium',
    features: [
      'Access Figma files and projects',
      'Read and modify design components',
      'Extract design tokens and styles',
      'Manage design system libraries',
      'Collaborate on design reviews',
      'Export assets and specifications'
    ],
    capabilities: [
      'Design file access',
      'Component management',
      'Style extraction',
      'Asset export',
      'Collaboration',
      'Version control'
    ],
    requirements: [
      'Figma account with API access',
      'Team or organization workspace',
      'Design system or component library setup'
    ],
    documentation: 'https://www.figma.com/developers/api',
    setupComplexity: 3,
    configuration: {
      apiKey: '',
      teamId: '',
      projectIds: [],
      permissions: ['read', 'write', 'comment'],
      syncInterval: '5m'
    }
  },
  {
    id: 'supabase-api',
    name: 'Supabase Database API',
    description: 'Full-stack database and API platform for storing design data, user feedback, and collaboration',
    category: 'Design & Prototyping',
    provider: 'Supabase',
    complexity: 'medium',
    enabled: false,
    connectionType: 'api',
    authMethod: 'api-key',
    pricing: 'freemium',
    features: [
      'PostgreSQL database for design data',
      'Real-time collaboration features',
      'File storage for design assets',
      'User authentication and permissions',
      'API endpoints for custom integrations',
      'Analytics and usage tracking'
    ],
    capabilities: [
      'Database operations',
      'Real-time subscriptions',
      'File storage',
      'Authentication',
      'API generation',
      'Edge functions'
    ],
    requirements: [
      'Supabase project setup',
      'Database schema for design data',
      'API key and security configuration'
    ],
    documentation: 'https://supabase.com/docs',
    setupComplexity: 4,
    configuration: {
      projectUrl: '',
      apiKey: '',
      tables: ['designs', 'components', 'feedback', 'versions'],
      policies: 'row_level_security',
      storage: 'design_assets'
    }
  },
  {
    id: 'design-tokens',
    name: 'Design Tokens Studio',
    description: 'Manage and synchronize design tokens across design tools and code repositories',
    category: 'Design & Prototyping',
    provider: 'Design Tokens Studio',
    complexity: 'medium',
    enabled: false,
    connectionType: 'api',
    authMethod: 'oauth',
    pricing: 'paid',
    features: [
      'Centralized token management',
      'Multi-platform synchronization',
      'Version control for tokens',
      'Automated code generation',
      'Design system consistency',
      'Token validation and testing'
    ],
    capabilities: [
      'Token management',
      'Cross-platform sync',
      'Code generation',
      'Validation',
      'Version control',
      'Documentation'
    ],
    requirements: [
      'Design Tokens Studio account',
      'Connected design tools (Figma, Sketch)',
      'Repository for token storage'
    ],
    documentation: 'https://docs.tokens.studio/',
    setupComplexity: 3,
    configuration: {
      studioUrl: '',
      tokenSets: [],
      syncTargets: ['figma', 'github', 'storybook'],
      format: 'style-dictionary'
    }
  },
  {
    id: 'storybook-api',
    name: 'Storybook Integration',
    description: 'Connect to Storybook for component documentation, testing, and design system management',
    category: 'Design & Prototyping',
    provider: 'Storybook',
    complexity: 'medium',
    enabled: false,
    connectionType: 'api',
    authMethod: 'none',
    pricing: 'free',
    features: [
      'Component story management',
      'Visual testing integration',
      'Documentation generation',
      'Design system showcase',
      'Accessibility testing',
      'Cross-browser compatibility'
    ],
    capabilities: [
      'Story management',
      'Visual testing',
      'Documentation',
      'Accessibility',
      'Testing',
      'Deployment'
    ],
    requirements: [
      'Storybook project setup',
      'Component library',
      'Build and deployment pipeline'
    ],
    documentation: 'https://storybook.js.org/docs',
    setupComplexity: 3,
    configuration: {
      storybookUrl: '',
      stories: [],
      addons: ['docs', 'controls', 'viewport', 'a11y'],
      buildCommand: 'build-storybook'
    }
  },
  {
    id: 'sketch-api',
    name: 'Sketch Cloud API',
    description: 'Access Sketch Cloud documents, symbols, and shared libraries for design collaboration',
    category: 'Design & Prototyping',
    provider: 'Sketch',
    complexity: 'medium',
    enabled: false,
    connectionType: 'api',
    authMethod: 'oauth',
    pricing: 'paid',
    features: [
      'Cloud document access',
      'Symbol library management',
      'Version history tracking',
      'Team collaboration',
      'Asset extraction',
      'Design specifications'
    ],
    capabilities: [
      'Document access',
      'Symbol management',
      'Version control',
      'Collaboration',
      'Asset export',
      'Specifications'
    ],
    requirements: [
      'Sketch for Teams subscription',
      'Cloud workspace setup',
      'Design libraries and documents'
    ],
    documentation: 'https://developer.sketch.com/',
    setupComplexity: 3,
    configuration: {
      workspaceId: '',
      libraries: [],
      documents: [],
      permissions: 'read-write'
    }
  },
  {
    id: 'zeplin-api',
    name: 'Zeplin Specifications',
    description: 'Generate and manage design specifications, assets, and developer handoff documentation',
    category: 'Design & Prototyping',
    provider: 'Zeplin',
    complexity: 'low',
    enabled: false,
    connectionType: 'api',
    authMethod: 'api-key',
    pricing: 'freemium',
    features: [
      'Design specification generation',
      'Asset export and optimization',
      'Style guide creation',
      'Developer handoff tools',
      'Design-to-code workflows',
      'Team collaboration features'
    ],
    capabilities: [
      'Specification generation',
      'Asset management',
      'Style guides',
      'Handoff tools',
      'Code snippets',
      'Collaboration'
    ],
    requirements: [
      'Zeplin account and projects',
      'Connected design files',
      'Team workspace setup'
    ],
    documentation: 'https://docs.zeplin.dev/',
    setupComplexity: 2,
    configuration: {
      projectId: '',
      apiToken: '',
      platforms: ['web', 'ios', 'android'],
      assetFormats: ['svg', 'png', 'pdf']
    }
  },

  // Development & Collaboration Extensions (Enhanced)
  {
    id: 'github',
    name: 'GitHub Integration',
    description: 'Access GitHub repositories for code analysis, pull requests, issues, and collaborative development via API or MCP',
    category: 'Development & Code',
    provider: 'GitHub',
    complexity: 'medium',
    enabled: false,
    connectionType: 'api',
    authMethod: 'oauth',
    pricing: 'freemium',
    supportedConnectionTypes: ['api', 'mcp'],
    features: [
      'Repository and file access',
      'Pull request management',
      'Issue tracking and creation',
      'Code review and comments',
      'Branch and commit operations',
      'GitHub Actions integration',
      'Design system repository management',
      'Component library maintenance',
      'MCP server protocol support',
      'Webhook handling',
      'Team and permission management'
    ],
    capabilities: [
      'Repository access',
      'Code operations',
      'Pull requests',
      'Issue management',
      'Collaboration',
      'CI/CD integration',
      'Design system ops',
      'Documentation',
      'MCP protocol',
      'Event handling',
      'Access control'
    ],
    requirements: [
      'GitHub account and repository access',
      'Personal access token, OAuth, or GitHub App setup',
      'Repository permissions for intended operations'
    ],
    documentation: 'https://docs.github.com/en/rest',
    setupComplexity: 3,
    configuration: {
      connectionType: 'api',
      owner: '',
      repositories: [],
      permissions: ['read', 'write', 'admin'],
      webhooks: true,
      actions: true,
      token: '',
      organization: '',
      webhookSecret: ''
    }
  },
  {
    id: 'slack',
    name: 'Slack Integration',
    description: 'Integrate with Slack for team communication, notifications, and design collaboration workflows via API or MCP',
    category: 'Communication & Collaboration',
    provider: 'Slack',
    complexity: 'medium',
    enabled: false,
    connectionType: 'api',
    authMethod: 'oauth',
    pricing: 'freemium',
    supportedConnectionTypes: ['api', 'mcp'],
    features: [
      'Channel and DM messaging',
      'File and image sharing',
      'Design review notifications',
      'Automated status updates',
      'Team collaboration workflows',
      'Integration with design tools',
      'Feedback collection and routing',
      'Design system announcements',
      'MCP server protocol support',
      'User and workspace management',
      'Bot interactions',
      'Event handling'
    ],
    capabilities: [
      'Messaging',
      'File sharing',
      'Notifications',
      'Workflows',
      'Integrations',
      'Collaboration',
      'Feedback',
      'Broadcasting',
      'MCP protocol',
      'User management',
      'Bot management',
      'Event processing'
    ],
    requirements: [
      'Slack workspace with app permissions',
      'Bot token, OAuth credentials, or MCP setup',
      'Channel access for intended operations'
    ],
    documentation: 'https://api.slack.com/',
    setupComplexity: 3,
    configuration: {
      connectionType: 'api',
      workspaceId: '',
      channels: ['#design', '#frontend', '#design-system'],
      botToken: '',
      appToken: '',
      signingSecret: '',
      permissions: ['chat:write', 'files:read', 'channels:read']
    }
  },
  {
    id: 'notion-api',
    name: 'Notion Workspace',
    description: 'Connect to Notion for design documentation, project management, and knowledge base creation',
    category: 'Documentation & Knowledge',
    provider: 'Notion',
    complexity: 'medium',
    enabled: false,
    connectionType: 'api',
    authMethod: 'oauth',
    pricing: 'freemium',
    features: [
      'Page and database management',
      'Design documentation creation',
      'Project tracking and planning',
      'Knowledge base organization',
      'Template and workflow automation',
      'Design system documentation',
      'Component library cataloging',
      'Design process documentation'
    ],
    capabilities: [
      'Content management',
      'Database operations',
      'Documentation',
      'Organization',
      'Automation',
      'Collaboration',
      'Templates',
      'Knowledge base'
    ],
    requirements: [
      'Notion workspace with integration access',
      'Database and page permissions',
      'OAuth or internal integration setup'
    ],
    documentation: 'https://developers.notion.com/',
    setupComplexity: 3,
    configuration: {
      workspaceId: '',
      databases: ['design-components', 'projects', 'documentation'],
      pages: [],
      permissions: 'read-write'
    }
  },
  {
    id: 'linear-api',
    name: 'Linear Project Management',
    description: 'Integrate with Linear for design task management, bug tracking, and project planning',
    category: 'Project Management',
    provider: 'Linear',
    complexity: 'medium',
    enabled: false,
    connectionType: 'api',
    authMethod: 'api-key',
    pricing: 'paid',
    features: [
      'Issue and task management',
      'Design bug tracking',
      'Sprint and milestone planning',
      'Team workflow automation',
      'Progress tracking and reporting',
      'Design request management',
      'Cross-team collaboration',
      'Design system roadmap planning'
    ],
    capabilities: [
      'Task management',
      'Bug tracking',
      'Planning',
      'Automation',
      'Reporting',
      'Collaboration',
      'Workflows',
      'Roadmapping'
    ],
    requirements: [
      'Linear workspace and team access',
      'API key with appropriate permissions',
      'Project and team setup'
    ],
    documentation: 'https://developers.linear.app/',
    setupComplexity: 2,
    configuration: {
      teamId: '',
      projectIds: [],
      apiKey: '',
      labels: ['design', 'frontend', 'bug', 'enhancement']
    }
  },

  // AI & Content Extensions (Design-Enhanced)
  {
    id: 'openai-api',
    name: 'OpenAI GPT Models',
    description: 'Access OpenAI GPT models for design content generation, code assistance, and creative ideation',
    category: 'AI & Machine Learning',
    provider: 'OpenAI',
    complexity: 'low',
    enabled: false,
    connectionType: 'api',
    authMethod: 'api-key',
    pricing: 'paid',
    features: [
      'Text generation and editing',
      'Code generation and review',
      'Design content creation',
      'Component documentation',
      'Design system guidelines',
      'Accessibility recommendations',
      'UX copy and microcopy',
      'Design critique and feedback'
    ],
    capabilities: [
      'Text generation',
      'Code assistance',
      'Content creation',
      'Documentation',
      'Guidelines',
      'Accessibility',
      'Copywriting',
      'Analysis'
    ],
    requirements: [
      'OpenAI API key with sufficient credits',
      'Model access permissions',
      'Usage monitoring and rate limiting'
    ],
    documentation: 'https://platform.openai.com/docs',
    setupComplexity: 1,
    configuration: {
      apiKey: '',
      model: 'gpt-4',
      maxTokens: 4096,
      temperature: 0.7
    }
  },
  {
    id: 'anthropic-api',
    name: 'Anthropic Claude',
    description: 'Integrate Claude for safe AI assistance in design workflows, documentation, and analysis',
    category: 'AI & Machine Learning',
    provider: 'Anthropic',
    complexity: 'low',
    enabled: false,
    connectionType: 'api',
    authMethod: 'api-key',
    pricing: 'paid',
    features: [
      'Safe and helpful AI responses',
      'Long-context understanding',
      'Design analysis and critique',
      'Accessibility auditing',
      'Design system consistency checks',
      'Code review and suggestions',
      'Documentation improvement',
      'Design process optimization'
    ],
    capabilities: [
      'AI assistance',
      'Long context',
      'Analysis',
      'Auditing',
      'Consistency',
      'Code review',
      'Documentation',
      'Optimization'
    ],
    requirements: [
      'Anthropic API key',
      'Model access and usage limits',
      'Safety and content guidelines'
    ],
    documentation: 'https://docs.anthropic.com/',
    setupComplexity: 1,
    configuration: {
      apiKey: '',
      model: 'claude-3-sonnet',
      maxTokens: 4096,
      temperature: 0.3
    }
  },

  // Data & Analytics Extensions
  {
    id: 'google-analytics',
    name: 'Google Analytics',
    description: 'Access website and app analytics data for design performance insights and user behavior analysis',
    category: 'Analytics & Data',
    provider: 'Google',
    complexity: 'high',
    enabled: false,
    connectionType: 'api',
    authMethod: 'oauth',
    pricing: 'freemium',
    features: [
      'Website traffic and user analytics',
      'Design performance metrics',
      'User journey tracking',
      'Conversion rate analysis',
      'A/B testing results',
      'Design impact measurement',
      'User behavior insights',
      'Performance optimization data'
    ],
    capabilities: [
      'Analytics data',
      'Performance metrics',
      'User tracking',
      'Conversion analysis',
      'A/B testing',
      'Impact measurement',
      'Behavioral insights',
      'Optimization'
    ],
    requirements: [
      'Google Analytics account and property',
      'API access and OAuth credentials',
      'Data and reporting permissions'
    ],
    documentation: 'https://developers.google.com/analytics',
    setupComplexity: 4,
    configuration: {
      propertyId: '',
      viewId: '',
      metrics: ['pageviews', 'sessions', 'conversion_rate'],
      dimensions: ['page', 'device', 'source']
    }
  },
  {
    id: 'mixpanel-api',
    name: 'Mixpanel Analytics',
    description: 'Product analytics for understanding user interactions with design components and features',
    category: 'Analytics & Data',
    provider: 'Mixpanel',
    complexity: 'medium',
    enabled: false,
    connectionType: 'api',
    authMethod: 'api-key',
    pricing: 'freemium',
    features: [
      'Event tracking and analysis',
      'User behavior funnels',
      'Component interaction metrics',
      'Design experiment tracking',
      'Cohort analysis',
      'Custom event properties',
      'Real-time data streams',
      'Design performance dashboards'
    ],
    capabilities: [
      'Event tracking',
      'Funnel analysis',
      'Component metrics',
      'Experimentation',
      'Cohort analysis',
      'Custom properties',
      'Real-time data',
      'Dashboards'
    ],
    requirements: [
      'Mixpanel project with data',
      'API credentials and permissions',
      'Event tracking implementation'
    ],
    documentation: 'https://developer.mixpanel.com/',
    setupComplexity: 3,
    configuration: {
      projectId: '',
      apiSecret: '',
      events: ['component_click', 'page_view', 'form_submit'],
      properties: ['component_type', 'page_url', 'user_type']
    }
  },

  // File & Asset Management Extensions
  {
    id: 'google-drive',
    name: 'Google Drive',
    description: 'Access and manage design files, assets, and collaborative documents in Google Drive',
    category: 'File & Asset Management',
    provider: 'Google',
    complexity: 'medium',
    enabled: false,
    connectionType: 'api',
    authMethod: 'oauth',
    pricing: 'freemium',
    features: [
      'File and folder management',
      'Design asset organization',
      'Collaborative document editing',
      'Version history tracking',
      'Sharing and permissions',
      'Search and discovery',
      'Integration with Google Workspace',
      'Design file synchronization'
    ],
    capabilities: [
      'File management',
      'Asset organization',
      'Collaboration',
      'Version control',
      'Sharing',
      'Search',
      'Workspace integration',
      'Synchronization'
    ],
    requirements: [
      'Google account with Drive access',
      'OAuth credentials and scopes',
      'File and folder permissions'
    ],
    documentation: 'https://developers.google.com/drive',
    setupComplexity: 3,
    configuration: {
      folderId: '',
      permissions: 'read-write',
      fileTypes: ['sketch', 'fig', 'psd', 'ai', 'pdf'],
      sync: true
    }
  },
  {
    id: 'dropbox-api',
    name: 'Dropbox Storage',
    description: 'Cloud file storage and sharing for design assets, prototypes, and collaborative workflows',
    category: 'File & Asset Management',
    provider: 'Dropbox',
    complexity: 'low',
    enabled: false,
    connectionType: 'api',
    authMethod: 'oauth',
    pricing: 'freemium',
    features: [
      'File upload and download',
      'Folder organization and sharing',
      'Design asset management',
      'Collaborative file access',
      'Version history and recovery',
      'Link sharing and permissions',
      'Paper document integration',
      'Design feedback collection'
    ],
    capabilities: [
      'File operations',
      'Organization',
      'Asset management',
      'Collaboration',
      'Version history',
      'Link sharing',
      'Document integration',
      'Feedback collection'
    ],
    requirements: [
      'Dropbox account with API access',
      'OAuth app registration',
      'File and folder permissions'
    ],
    documentation: 'https://www.dropbox.com/developers',
    setupComplexity: 2,
    configuration: {
      appKey: '',
      appSecret: '',
      accessToken: '',
      rootFolder: '/Design Assets'
    }
  },

  // Browser & Web Extensions
  {
    id: 'brave-browser',
    name: 'Brave Browser Extension',
    description: 'Privacy-focused browser extension for web scraping, bookmarks, and tab management with ad-blocking capabilities',
    category: 'Browser & Web Tools',
    provider: 'Brave Software',
    complexity: 'low',
    enabled: false,
    connectionType: 'extension',
    authMethod: 'none',
    pricing: 'free',
    features: [
      'Privacy-focused web browsing',
      'Built-in ad and tracker blocking',
      'Tab and bookmark management',
      'Web scraping capabilities',
      'Page content extraction',
      'Form automation',
      'Screenshot capture',
      'Web API interactions'
    ],
    capabilities: [
      'Web navigation',
      'Content extraction',
      'Privacy protection',
      'Ad blocking',
      'Tab management',
      'Bookmark sync',
      'Form filling',
      'Screen capture'
    ],
    requirements: [
      'Brave browser installed',
      'Extension permissions granted',
      'Browser automation setup'
    ],
    documentation: 'https://brave.com/developers/',
    setupComplexity: 1,
    configuration: {
      autoBlock: true,
      shieldsUp: true,
      cookieBlocking: 'strict',
      fingerprintBlocking: 'aggressive'
    }
  },
  {
    id: 'chrome-extension',
    name: 'Chrome Browser Extension',
    description: 'Comprehensive browser automation and web interaction capabilities through Chrome extensions',
    category: 'Browser & Web Tools',
    provider: 'Google Chrome',
    complexity: 'low',
    enabled: false,
    connectionType: 'extension',
    authMethod: 'none',
    pricing: 'free',
    features: [
      'Browser automation and control',
      'Web page interaction',
      'Content scraping and extraction',
      'Form automation and filling',
      'Screenshot and recording',
      'Bookmark and history access',
      'Tab and window management',
      'Extension ecosystem access'
    ],
    capabilities: [
      'Browser control',
      'Web scraping',
      'Page interaction',
      'Form automation',
      'Content extraction',
      'Media capture',
      'Extension integration',
      'Developer tools'
    ],
    requirements: [
      'Google Chrome browser',
      'Extension development environment',
      'Chrome Web Store access'
    ],
    documentation: 'https://developer.chrome.com/docs/extensions/',
    setupComplexity: 2,
    configuration: {
      permissions: ['activeTab', 'storage', 'bookmarks'],
      manifest: 'v3',
      contentScripts: true,
      backgroundService: true
    }
  },
  {
    id: 'firefox-extension',
    name: 'Firefox Browser Extension',
    description: 'Mozilla Firefox extension for privacy-focused web automation and content management',
    category: 'Browser & Web Tools',
    provider: 'Mozilla',
    complexity: 'low',
    enabled: false,
    connectionType: 'extension',
    authMethod: 'none',
    pricing: 'free',
    features: [
      'Privacy-first browser automation',
      'Enhanced tracking protection',
      'Web content manipulation',
      'Multi-account container support',
      'Advanced privacy controls',
      'Custom user agent management',
      'Cookie and session handling',
      'Developer-friendly APIs'
    ],
    capabilities: [
      'Browser automation',
      'Privacy protection',
      'Content management',
      'Container isolation',
      'Tracking protection',
      'Session management',
      'Developer tools',
      'Add-on ecosystem'
    ],
    requirements: [
      'Mozilla Firefox browser',
      'Add-on development setup',
      'Firefox Developer Edition (optional)'
    ],
    documentation: 'https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons',
    setupComplexity: 2,
    configuration: {
      containersEnabled: true,
      trackingProtection: 'strict',
      cookiePolicy: 'same-site',
      webextensions: true
    }
  },
  {
    id: 'safari-extension',
    name: 'Safari Web Extension',
    description: 'Native Safari extension for macOS and iOS web automation and content management',
    category: 'Browser & Web Tools',
    provider: 'Apple Safari',
    complexity: 'medium',
    enabled: false,
    connectionType: 'extension',
    authMethod: 'none',
    pricing: 'free',
    features: [
      'Native macOS/iOS integration',
      'Intelligent tracking prevention',
      'Cross-device synchronization',
      'Privacy-focused web automation',
      'Content blocking capabilities',
      'Keychain integration',
      'Handoff and Continuity support',
      'App Store distribution'
    ],
    capabilities: [
      'Native integration',
      'Privacy protection',
      'Cross-device sync',
      'Content blocking',
      'Keychain access',
      'Continuity features',
      'App Store deployment',
      'iOS compatibility'
    ],
    requirements: [
      'macOS with Safari 14+',
      'Xcode for development',
      'Apple Developer account (for distribution)'
    ],
    documentation: 'https://developer.apple.com/documentation/safariservices',
    setupComplexity: 3,
    configuration: {
      trackingPrevention: true,
      contentBlocking: 'aggressive',
      keychainAccess: true,
      handoffEnabled: true
    }
  },

  // Microsoft 365 & Office Extensions
  {
    id: 'microsoft-teams',
    name: 'Microsoft Teams',
    description: 'Integrate with Microsoft Teams for team communication, meetings, and collaborative workflows',
    category: 'Communication & Collaboration',
    provider: 'Microsoft',
    complexity: 'medium',
    enabled: false,
    connectionType: 'api',
    authMethod: 'oauth',
    pricing: 'freemium',
    features: [
      'Team channel messaging',
      'Meeting scheduling and management',
      'File sharing and collaboration',
      'Bot framework integration',
      'Adaptive cards and notifications',
      'Graph API access',
      'Custom app development',
      'Workflow automation'
    ],
    capabilities: [
      'Messaging',
      'Meetings',
      'File collaboration',
      'Bot integration',
      'Notifications',
      'Graph API',
      'Custom apps',
      'Automation'
    ],
    requirements: [
      'Microsoft 365 subscription',
      'Teams app registration',
      'Azure AD permissions'
    ],
    documentation: 'https://docs.microsoft.com/en-us/microsoftteams/platform/',
    setupComplexity: 3,
    configuration: {
      tenantId: '',
      clientId: '',
      clientSecret: '',
      scopes: ['TeamMember.Read.All', 'Chat.ReadWrite'],
      botFramework: true
    }
  },
  {
    id: 'sharepoint-online',
    name: 'SharePoint Online',
    description: 'Access SharePoint sites, lists, libraries, and content for document management and collaboration',
    category: 'Documentation & Knowledge',
    provider: 'Microsoft',
    complexity: 'high',
    enabled: false,
    connectionType: 'api',
    authMethod: 'oauth',
    pricing: 'paid',
    features: [
      'Site and list management',
      'Document library access',
      'Content type management',
      'Workflow automation',
      'Search and metadata',
      'Permissions management',
      'Version control',
      'Custom web parts'
    ],
    capabilities: [
      'Site management',
      'Document handling',
      'Content management',
      'Workflow automation',
      'Search',
      'Permissions',
      'Versioning',
      'Customization'
    ],
    requirements: [
      'SharePoint Online license',
      'Site collection admin rights',
      'Azure AD app registration'
    ],
    documentation: 'https://docs.microsoft.com/en-us/sharepoint/dev/',
    setupComplexity: 4,
    configuration: {
      siteUrl: '',
      tenantId: '',
      clientId: '',
      permissions: ['Sites.ReadWrite.All', 'Files.ReadWrite.All']
    }
  },
  {
    id: 'onedrive-api',
    name: 'OneDrive for Business',
    description: 'Cloud file storage and synchronization for business documents and collaboration',
    category: 'File & Asset Management',
    provider: 'Microsoft',
    complexity: 'medium',
    enabled: false,
    connectionType: 'api',
    authMethod: 'oauth',
    pricing: 'paid',
    features: [
      'File upload and download',
      'Folder synchronization',
      'Sharing and permissions',
      'Version history',
      'Collaborative editing',
      'Large file handling',
      'Metadata management',
      'Integration with Office apps'
    ],
    capabilities: [
      'File operations',
      'Synchronization',
      'Sharing',
      'Version control',
      'Collaboration',
      'Large files',
      'Metadata',
      'Office integration'
    ],
    requirements: [
      'Microsoft 365 Business subscription',
      'OneDrive for Business license',
      'Azure AD authentication'
    ],
    documentation: 'https://docs.microsoft.com/en-us/onedrive/developer/',
    setupComplexity: 3,
    configuration: {
      tenantId: '',
      clientId: '',
      driveId: '',
      scopes: ['Files.ReadWrite.All', 'Sites.ReadWrite.All']
    }
  },
  {
    id: 'outlook-api',
    name: 'Outlook Mail & Calendar',
    description: 'Email management, calendar scheduling, and contact management through Outlook API',
    category: 'Email & Communication',
    provider: 'Microsoft',
    complexity: 'medium',
    enabled: false,
    connectionType: 'api',
    authMethod: 'oauth',
    pricing: 'freemium',
    features: [
      'Email sending and receiving',
      'Calendar event management',
      'Contact and address book access',
      'Meeting scheduling',
      'Email filtering and rules',
      'Attachment handling',
      'Folder organization',
      'Unified messaging'
    ],
    capabilities: [
      'Email management',
      'Calendar operations',
      'Contact management',
      'Meeting scheduling',
      'Filtering',
      'Attachments',
      'Organization',
      'Messaging'
    ],
    requirements: [
      'Microsoft 365 or Outlook.com account',
      'Microsoft Graph permissions',
      'Azure AD app registration'
    ],
    documentation: 'https://docs.microsoft.com/en-us/graph/api/resources/mail-api-overview',
    setupComplexity: 3,
    configuration: {
      tenantId: '',
      clientId: '',
      scopes: ['Mail.ReadWrite', 'Calendars.ReadWrite', 'Contacts.ReadWrite']
    }
  },
  {
    id: 'power-bi',
    name: 'Power BI',
    description: 'Business intelligence and data visualization with interactive dashboards and reports',
    category: 'Analytics & Data',
    provider: 'Microsoft',
    complexity: 'high',
    enabled: false,
    connectionType: 'api',
    authMethod: 'oauth',
    pricing: 'paid',
    features: [
      'Dataset management',
      'Report and dashboard creation',
      'Data refresh automation',
      'Workspace administration',
      'Row-level security',
      'Custom visuals',
      'Embedded analytics',
      'Real-time streaming'
    ],
    capabilities: [
      'Data visualization',
      'Report generation',
      'Dashboard management',
      'Data refresh',
      'Administration',
      'Security',
      'Custom visuals',
      'Streaming data'
    ],
    requirements: [
      'Power BI Pro or Premium license',
      'Azure AD tenant access',
      'Workspace administration rights'
    ],
    documentation: 'https://docs.microsoft.com/en-us/power-bi/developer/',
    setupComplexity: 4,
    configuration: {
      tenantId: '',
      clientId: '',
      workspaceId: '',
      permissions: ['Dataset.ReadWrite.All', 'Report.ReadWrite.All']
    }
  },
  {
    id: 'power-automate',
    name: 'Power Automate',
    description: 'Workflow automation and business process automation across Microsoft 365 and third-party services',
    category: 'Automation & Productivity',
    provider: 'Microsoft',
    complexity: 'medium',
    enabled: false,
    connectionType: 'api',
    authMethod: 'oauth',
    pricing: 'freemium',
    features: [
      'Workflow creation and management',
      'Trigger-based automation',
      'Approval processes',
      'Data transformation',
      'Integration with 350+ connectors',
      'AI Builder integration',
      'Business process flows',
      'Robotic process automation'
    ],
    capabilities: [
      'Workflow automation',
      'Process automation',
      'Approvals',
      'Data transformation',
      'Connector integration',
      'AI integration',
      'Business processes',
      'RPA'
    ],
    requirements: [
      'Microsoft 365 subscription',
      'Power Automate license',
      'Environment administration rights'
    ],
    documentation: 'https://docs.microsoft.com/en-us/power-automate/',
    setupComplexity: 3,
    configuration: {
      tenantId: '',
      environmentId: '',
      connectionReferences: [],
      triggers: ['manual', 'scheduled', 'dataverse']
    }
  },
  {
    id: 'power-apps',
    name: 'Power Apps',
    description: 'Low-code application development platform for creating custom business applications',
    category: 'Development & Code',
    provider: 'Microsoft',
    complexity: 'high',
    enabled: false,
    connectionType: 'api',
    authMethod: 'oauth',
    pricing: 'paid',
    features: [
      'Canvas and model-driven apps',
      'Custom connector creation',
      'Data source integration',
      'Component framework',
      'App lifecycle management',
      'Power Platform CLI',
      'Solution packaging',
      'Environment management'
    ],
    capabilities: [
      'App development',
      'Custom connectors',
      'Data integration',
      'Component framework',
      'ALM',
      'CLI tools',
      'Solution management',
      'Environment control'
    ],
    requirements: [
      'Power Apps license',
      'Power Platform environment',
      'Development environment access'
    ],
    documentation: 'https://docs.microsoft.com/en-us/powerapps/developer/',
    setupComplexity: 4,
    configuration: {
      tenantId: '',
      environmentId: '',
      solutionId: '',
      publisherPrefix: 'new_'
    }
  },
  {
    id: 'azure-cognitive',
    name: 'Azure Cognitive Services',
    description: 'AI and machine learning services including vision, speech, language, and decision APIs',
    category: 'AI & Machine Learning',
    provider: 'Microsoft',
    complexity: 'medium',
    enabled: false,
    connectionType: 'api',
    authMethod: 'api-key',
    pricing: 'paid',
    features: [
      'Computer vision and OCR',
      'Speech-to-text and text-to-speech',
      'Language understanding (LUIS)',
      'Text analytics and sentiment',
      'Face recognition and detection',
      'Custom vision training',
      'Translator services',
      'Content moderator'
    ],
    capabilities: [
      'Computer vision',
      'Speech processing',
      'Language understanding',
      'Text analytics',
      'Face recognition',
      'Custom AI models',
      'Translation',
      'Content moderation'
    ],
    requirements: [
      'Azure subscription',
      'Cognitive Services resource',
      'API keys and endpoints'
    ],
    documentation: 'https://docs.microsoft.com/en-us/azure/cognitive-services/',
    setupComplexity: 3,
    configuration: {
      subscriptionKey: '',
      endpoint: '',
      region: 'eastus',
      services: ['vision', 'speech', 'language']
    }
  },
  {
    id: 'microsoft-graph',
    name: 'Microsoft Graph API',
    description: 'Unified API endpoint for accessing Microsoft 365, Windows, and Enterprise Mobility + Security services',
    category: 'Development & Code',
    provider: 'Microsoft',
    complexity: 'high',
    enabled: false,
    connectionType: 'api',
    authMethod: 'oauth',
    pricing: 'freemium',
    features: [
      'Unified Microsoft 365 access',
      'User and group management',
      'Calendar and mail integration',
      'Files and SharePoint access',
      'Teams and Yammer integration',
      'Security and compliance',
      'Analytics and insights',
      'Device and identity management'
    ],
    capabilities: [
      'Unified API access',
      'Identity management',
      'Productivity services',
      'File services',
      'Communication platforms',
      'Security services',
      'Analytics',
      'Device management'
    ],
    requirements: [
      'Azure AD tenant',
      'App registration with permissions',
      'Microsoft 365 or Azure subscription'
    ],
    documentation: 'https://docs.microsoft.com/en-us/graph/',
    setupComplexity: 4,
    configuration: {
      tenantId: '',
      clientId: '',
      clientSecret: '',
      scopes: ['User.Read', 'Mail.ReadWrite', 'Files.ReadWrite.All']
    }
  },
  {
    id: 'office-365-api',
    name: 'Office 365 APIs',
    description: 'Direct integration with Word, Excel, PowerPoint, and other Office applications via APIs',
    category: 'Documentation & Knowledge',
    provider: 'Microsoft',
    complexity: 'medium',
    enabled: false,
    connectionType: 'api',
    authMethod: 'oauth',
    pricing: 'paid',
    features: [
      'Word document automation',
      'Excel workbook manipulation',
      'PowerPoint presentation creation',
      'OneNote notebook access',
      'Visio diagram integration',
      'Office Add-in development',
      'Document conversion',
      'Template management'
    ],
    capabilities: [
      'Document automation',
      'Spreadsheet operations',
      'Presentation management',
      'Note-taking',
      'Diagram creation',
      'Add-in development',
      'File conversion',
      'Template handling'
    ],
    requirements: [
      'Microsoft 365 subscription',
      'Office applications installed',
      'Developer tools and SDKs'
    ],
    documentation: 'https://docs.microsoft.com/en-us/office/dev/',
    setupComplexity: 3,
    configuration: {
      tenantId: '',
      applicationId: '',
      officeVersion: '365',
      addInManifest: ''
    }
  },

  // Productivity & Automation Extensions
  {
    id: 'zapier-webhooks',
    name: 'Zapier Automation',
    description: 'Connect to 5000+ apps through Zapier workflows and automation triggers',
    category: 'Automation & Productivity',
    provider: 'Zapier',
    complexity: 'medium',
    enabled: false,
    connectionType: 'webhook',
    authMethod: 'api-key',
    pricing: 'freemium',
    features: [
      'Multi-app workflow automation',
      'Trigger-based task execution',
      'Data transformation and routing',
      'Conditional logic and filters',
      'Scheduled and real-time automation',
      'Error handling and retries',
      'Webhook and API integrations',
      'Custom app connections'
    ],
    capabilities: [
      'Workflow automation',
      'Multi-app integration',
      'Data transformation',
      'Conditional logic',
      'Scheduling',
      'Error handling',
      'Webhook processing',
      'Custom integrations'
    ],
    requirements: [
      'Zapier account with automation access',
      'Connected app accounts',
      'Webhook endpoints configured'
    ],
    documentation: 'https://zapier.com/developer',
    setupComplexity: 3,
    configuration: {
      webhookUrl: '',
      triggerApps: [],
      actionApps: [],
      filters: true
    }
  },
  {
    id: 'ifttt-applets',
    name: 'IFTTT Applets',
    description: 'Simple automation platform connecting consumer apps and IoT devices',
    category: 'Automation & Productivity',
    provider: 'IFTTT',
    complexity: 'low',
    enabled: false,
    connectionType: 'webhook',
    authMethod: 'oauth',
    pricing: 'freemium',
    features: [
      'Simple if-this-then-that logic',
      'Consumer app integrations',
      'IoT device connectivity',
      'Social media automation',
      'Smart home integration',
      'Location-based triggers',
      'Time and date scheduling',
      'Mobile app notifications'
    ],
    capabilities: [
      'Simple automation',
      'Consumer integrations',
      'IoT connectivity',
      'Social automation',
      'Smart home',
      'Location triggers',
      'Scheduling',
      'Mobile notifications'
    ],
    requirements: [
      'IFTTT account and app access',
      'Connected service accounts',
      'Mobile app for management'
    ],
    documentation: 'https://ifttt.com/developers',
    setupComplexity: 1,
    configuration: {
      applets: [],
      triggers: ['location', 'time', 'weather'],
      actions: ['notification', 'email', 'sms']
    }
  },
  {
    id: 'make-scenarios',
    name: 'Make (Integromat)',
    description: 'Advanced visual automation platform for complex multi-step workflows',
    category: 'Automation & Productivity',
    provider: 'Make',
    complexity: 'high',
    enabled: false,
    connectionType: 'api',
    authMethod: 'api-key',
    pricing: 'freemium',
    features: [
      'Visual workflow builder',
      'Advanced data processing',
      'Multi-branch scenario logic',
      'Real-time and scheduled execution',
      'Error handling and debugging',
      'Data storage and manipulation',
      'Custom function development',
      'Team collaboration features'
    ],
    capabilities: [
      'Visual automation',
      'Complex workflows',
      'Data processing',
      'Multi-branch logic',
      'Real-time execution',
      'Error handling',
      'Custom functions',
      'Team collaboration'
    ],
    requirements: [
      'Make account with scenario access',
      'Connected app credentials',
      'Workflow design and testing'
    ],
    documentation: 'https://www.make.com/en/api-documentation',
    setupComplexity: 4,
    configuration: {
      scenarios: [],
      dataStores: [],
      webhooks: [],
      errorHandling: 'advanced'
    }
  },
  {
    id: 'microsoft-power-automate',
    name: 'Microsoft Power Automate',
    description: 'Enterprise-grade workflow automation integrated with Microsoft 365 and Azure',
    category: 'Automation & Productivity',
    provider: 'Microsoft',
    complexity: 'high',
    enabled: false,
    connectionType: 'api',
    authMethod: 'oauth',
    pricing: 'paid',
    features: [
      'Microsoft 365 deep integration',
      'Enterprise-grade security',
      'Desktop and cloud automation',
      'AI-powered process mining',
      'Approval workflows',
      'Document processing',
      'Teams and SharePoint integration',
      'Compliance and governance'
    ],
    capabilities: [
      'M365 integration',
      'Enterprise security',
      'Desktop automation',
      'AI processing',
      'Approval workflows',
      'Document automation',
      'Teams integration',
      'Governance'
    ],
    requirements: [
      'Microsoft 365 or Azure subscription',
      'Power Platform license',
      'Organizational permissions'
    ],
    documentation: 'https://docs.microsoft.com/power-automate/',
    setupComplexity: 4,
    configuration: {
      tenantId: '',
      clientId: '',
      flows: [],
      connectors: ['sharepoint', 'teams', 'outlook']
    }
  },

  // Email & Communication Extensions
  {
    id: 'gmail-api',
    name: 'Gmail Integration',
    description: 'Full Gmail API access for email automation, management, and communication workflows',
    category: 'Email & Communication',
    provider: 'Google Gmail',
    complexity: 'medium',
    enabled: false,
    connectionType: 'api',
    authMethod: 'oauth',
    pricing: 'free',
    features: [
      'Email sending and receiving',
      'Advanced search and filtering',
      'Label and folder management',
      'Attachment processing',
      'Draft management',
      'Signature and template support',
      'Bulk email operations',
      'Threading and conversation tracking'
    ],
    capabilities: [
      'Email automation',
      'Message processing',
      'Search and filter',
      'Label management',
      'Attachment handling',
      'Template system',
      'Bulk operations',
      'Conversation tracking'
    ],
    requirements: [
      'Gmail account with API access',
      'Google Cloud Project setup',
      'OAuth 2.0 credentials'
    ],
    documentation: 'https://developers.google.com/gmail/api',
    setupComplexity: 3,
    configuration: {
      clientId: '',
      clientSecret: '',
      scopes: ['gmail.readonly', 'gmail.send'],
      labels: []
    }
  },
  {
    id: 'outlook-api',
    name: 'Microsoft Outlook',
    description: 'Microsoft Graph integration for Outlook email, calendar, and contact management',
    category: 'Email & Communication',
    provider: 'Microsoft Outlook',
    complexity: 'medium',
    enabled: false,
    connectionType: 'api',
    authMethod: 'oauth',
    pricing: 'free',
    features: [
      'Email and calendar integration',
      'Contact and address book access',
      'Meeting scheduling and management',
      'Shared mailbox support',
      'Exchange Online integration',
      'Advanced security features',
      'Mobile device synchronization',
      'Enterprise compliance tools'
    ],
    capabilities: [
      'Email management',
      'Calendar integration',
      'Contact management',
      'Meeting scheduling',
      'Shared mailboxes',
      'Exchange integration',
      'Mobile sync',
      'Compliance'
    ],
    requirements: [
      'Microsoft 365 or Outlook.com account',
      'Azure AD application registration',
      'Microsoft Graph permissions'
    ],
    documentation: 'https://docs.microsoft.com/graph/api/resources/mail-api-overview',
    setupComplexity: 3,
    configuration: {
      tenantId: '',
      clientId: '',
      scopes: ['Mail.Read', 'Mail.Send', 'Calendars.ReadWrite'],
      mailboxes: []
    }
  },
  {
    id: 'discord-bot',
    name: 'Discord Bot Integration',
    description: 'Discord bot capabilities for community management, notifications, and automated interactions',
    category: 'Email & Communication',
    provider: 'Discord',
    complexity: 'medium',
    enabled: false,
    connectionType: 'api',
    authMethod: 'bot-token',
    pricing: 'free',
    features: [
      'Server and channel management',
      'Message sending and monitoring',
      'Slash command creation',
      'Voice channel integration',
      'Role and permission management',
      'Embed and rich message support',
      'Webhook integrations',
      'Community moderation tools'
    ],
    capabilities: [
      'Server management',
      'Message automation',
      'Command handling',
      'Voice integration',
      'Role management',
      'Rich messaging',
      'Webhook support',
      'Moderation tools'
    ],
    requirements: [
      'Discord application and bot token',
      'Server permissions for bot',
      'Developer mode enabled'
    ],
    documentation: 'https://discord.com/developers/docs',
    setupComplexity: 2,
    configuration: {
      botToken: '',
      guildId: '',
      permissions: ['send_messages', 'manage_channels'],
      intents: ['message_content', 'guild_messages']
    }
  },
  {
    id: 'telegram-bot',
    name: 'Telegram Bot API',
    description: 'Telegram bot integration for messaging, notifications, and automated customer support',
    category: 'Email & Communication',
    provider: 'Telegram',
    complexity: 'low',
    enabled: false,
    connectionType: 'api',
    authMethod: 'bot-token',
    pricing: 'free',
    features: [
      'Message sending and receiving',
      'Inline keyboard creation',
      'File and media sharing',
      'Group and channel management',
      'Webhook and polling support',
      'Custom command creation',
      'Payment processing integration',
      'Multi-language support'
    ],
    capabilities: [
      'Message automation',
      'Keyboard interfaces',
      'Media handling',
      'Group management',
      'Webhook processing',
      'Command system',
      'Payment integration',
      'Localization'
    ],
    requirements: [
      'Telegram bot token from BotFather',
      'Server for webhook endpoint',
      'SSL certificate for webhooks'
    ],
    documentation: 'https://core.telegram.org/bots/api',
    setupComplexity: 1,
    configuration: {
      botToken: '',
      webhookUrl: '',
      allowedUpdates: ['message', 'callback_query'],
      commands: []
    }
  }
];

// Legacy exports for backward compatibility
export const EXTENSIONS_LIBRARY = extensionsLibrary;

export const EXTENSION_CATEGORIES = [
  'Design & Prototyping',
  'Development & Code',
  'Communication & Collaboration',
  'Documentation & Knowledge',
  'Project Management',
  'AI & Machine Learning',
  'Analytics & Data',
  'File & Asset Management',
  'Browser & Web Tools',
  'Automation & Productivity',
  'Email & Communication'
];

// Helper functions to filter extensions by category
export const getExtensionsByCategory = (category: string): Extension[] => {
  return extensionsLibrary.filter(ext => ext.category === category);
};

export const getDesignExtensions = (): Extension[] => {
  return extensionsLibrary.filter(ext => 
    ext.category === 'Design & Prototyping' || 
    ext.capabilities.some(cap => 
      cap.includes('design') || 
      cap.includes('component') || 
      cap.includes('asset')
    )
  );
};

export const getFeaturedExtensions = (): Extension[] => {
  return extensionsLibrary.filter(ext => 
    ['figma-mcp', 'supabase-api', 'github-api', 'brave-browser', 'gmail-api', 'zapier-webhooks', 'openai-api', 'slack-api'].includes(ext.id)
  );
};

export const getExtensionById = (id: string): Extension | undefined => {
  return extensionsLibrary.find(ext => ext.id === id);
};

// Design-specific extension categories
export const designCategories = [
  'Design & Prototyping',
  'Development & Code',
  'Documentation & Knowledge',
  'File & Asset Management'
];

export const designTools = [
  'figma-mcp',
  'sketch-api', 
  'storybook-api',
  'design-tokens',
  'zeplin-api'
];

export const designCollaboration = [
  'supabase-api',
  'slack-api',
  'notion-api',
  'github-api',
  'linear-api'
];