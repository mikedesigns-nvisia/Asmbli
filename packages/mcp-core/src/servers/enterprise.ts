import type { MCPServer } from '@agentengine/shared-types'

// Design & Prototyping Category
export const DESIGN_SERVERS: MCPServer[] = [
  {
    id: 'figma-mcp',
    name: 'Figma MCP Server',
    type: 'figma',
    supportedPlatforms: ['web', 'desktop'],
    requiredAuth: [{ type: 'oauth', name: 'FIGMA_ACCESS_TOKEN', required: true }],
    config: { 
      features: ['design-files', 'code-connect', 'dev-mode', 'components'],
      pricing: 'freemium'
    },
    enabled: false
  },
  {
    id: 'sketch-api',
    name: 'Sketch Cloud API',
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'],
    requiredAuth: [{ type: 'api_key', name: 'SKETCH_API_TOKEN', required: true }],
    config: { features: ['design-management', 'cloud-sync'], pricing: 'paid' },
    enabled: false
  },
  {
    id: 'zeplin-api', 
    name: 'Zeplin Specifications',
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'],
    requiredAuth: [{ type: 'api_key', name: 'ZEPLIN_API_TOKEN', required: true }],
    config: { features: ['design-specs', 'handoff'], pricing: 'freemium' },
    enabled: false
  },
  {
    id: 'storybook-api',
    name: 'Storybook Integration',
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'],
    config: { 
      features: ['component-docs', 'visual-testing', 'accessibility'],
      pricing: 'free'
    },
    enabled: false
  },
  {
    id: 'design-tokens',
    name: 'Design Tokens Studio',
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'],
    config: { features: ['cross-platform-tokens', 'figma-sync'] },
    enabled: false
  }
]

// Microsoft 365 Suite  
export const MICROSOFT_SERVERS: MCPServer[] = [
  {
    id: 'microsoft-graph',
    name: 'Microsoft Graph API',
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'],
    requiredAuth: [{ type: 'oauth', name: 'Microsoft OAuth', required: true }],
    config: { 
      features: ['unified-api', 'm365-integration', 'current-enhancements'],
      scopes: ['Mail.Read', 'Calendars.ReadWrite', 'Files.ReadWrite']
    },
    enabled: false
  },
  {
    id: 'microsoft-teams',
    name: 'Microsoft Teams',
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'],
    requiredAuth: [{ type: 'oauth', name: 'Teams OAuth', required: true }],
    config: { features: ['team-collaboration', 'channels'], pricing: 'freemium' },
    enabled: false
  },
  {
    id: 'outlook-api',
    name: 'Outlook Mail & Calendar',
    type: 'custom', 
    supportedPlatforms: ['web', 'desktop'],
    requiredAuth: [{ type: 'oauth', name: 'Outlook OAuth', required: true }],
    config: { features: ['email-management', 'calendar'], pricing: 'freemium' },
    enabled: false
  },
  {
    id: 'sharepoint-online',
    name: 'SharePoint Online',
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'],
    requiredAuth: [{ type: 'oauth', name: 'SharePoint OAuth', required: true }],
    config: { features: ['document-management', 'workflows'], pricing: 'paid' },
    enabled: false
  },
  {
    id: 'onedrive-api',
    name: 'OneDrive for Business',
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'],
    requiredAuth: [{ type: 'oauth', name: 'OneDrive OAuth', required: true }],
    config: { features: ['cloud-storage', 'file-sync'], pricing: 'freemium' },
    enabled: false
  },
  {
    id: 'power-bi',
    name: 'Power BI',
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'],
    requiredAuth: [{ type: 'oauth', name: 'PowerBI OAuth', required: true }],
    config: { features: ['data-visualization', 'dashboards'], pricing: 'paid' },
    enabled: false
  },
  {
    id: 'power-automate',
    name: 'Power Automate',
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'], 
    requiredAuth: [{ type: 'oauth', name: 'PowerAutomate OAuth', required: true }],
    config: { features: ['workflow-automation', 'connectors'], pricing: 'freemium' },
    enabled: false
  },
  {
    id: 'azure-cognitive',
    name: 'Azure Cognitive Services',
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'],
    requiredAuth: [{ type: 'api_key', name: 'AZURE_COGNITIVE_KEY', required: true }],
    config: { features: ['ai-services', 'cognitive-apis'], pricing: 'usage-based' },
    enabled: false
  }
]

// Communication & Collaboration
export const COMMUNICATION_SERVERS: MCPServer[] = [
  {
    id: 'slack',
    name: 'Slack Integration',
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'],
    requiredAuth: [
      { type: 'oauth', name: 'Slack OAuth', required: false },
      { type: 'bearer_token', name: 'SLACK_BOT_TOKEN', required: true }
    ],
    config: { 
      connectionTypes: ['api', 'mcp'],
      features: ['messaging', 'file-sharing', 'workflows'],
      pricing: 'freemium'
    },
    enabled: false
  },
  {
    id: 'discord-bot',
    name: 'Discord Bot Integration',
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'],
    requiredAuth: [{ type: 'bearer_token', name: 'DISCORD_BOT_TOKEN', required: true }],
    config: { features: ['server-management', 'community-tools'], pricing: 'free' },
    enabled: false
  },
  {
    id: 'telegram-bot',
    name: 'Telegram Bot API', 
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'],
    requiredAuth: [{ type: 'bearer_token', name: 'TELEGRAM_BOT_TOKEN', required: true }],
    config: { features: ['messaging-api', 'bot-framework'], pricing: 'free' },
    enabled: false
  },
  {
    id: 'gmail-api',
    name: 'Gmail Integration',
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'],
    requiredAuth: [{ type: 'oauth', name: 'Gmail OAuth', required: true }],
    config: { 
      features: ['email-ops', 'advanced-search', 'labels', 'attachments'],
      pricing: 'free'
    },
    enabled: false
  }
]

// AI & Machine Learning
export const AI_SERVERS: MCPServer[] = [
  {
    id: 'openai-api',
    name: 'OpenAI GPT Models', 
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'],
    requiredAuth: [{ type: 'api_key', name: 'OPENAI_API_KEY', required: true }],
    config: { 
      models: ['gpt-4', 'dall-e', 'whisper', 'embeddings'],
      pricing: 'paid'
    },
    enabled: false
  },
  {
    id: 'anthropic-api',
    name: 'Anthropic Claude',
    type: 'custom', 
    supportedPlatforms: ['web', 'desktop'],
    requiredAuth: [{ type: 'api_key', name: 'ANTHROPIC_API_KEY', required: true }],
    config: { 
      features: ['constitutional-ai', 'long-context', 'safety'],
      pricing: 'paid' 
    },
    enabled: false
  }
]

// Browser Extensions
export const BROWSER_SERVERS: MCPServer[] = [
  {
    id: 'brave-browser',
    name: 'Brave Browser Extension',
    type: 'custom',
    supportedPlatforms: ['desktop'],
    config: { 
      features: ['privacy-focus', 'ad-blocking', 'web-scraping'],
      security: 'low-complexity'
    },
    enabled: false
  },
  {
    id: 'chrome-extension',
    name: 'Chrome Browser Extension',
    type: 'custom',
    supportedPlatforms: ['desktop'],
    config: { features: ['web-automation', 'tab-management'] },
    enabled: false
  },
  {
    id: 'firefox-extension',
    name: 'Firefox Browser Extension',
    type: 'custom',
    supportedPlatforms: ['desktop'],
    config: { features: ['privacy-focused', 'automation'] },
    enabled: false
  },
  {
    id: 'safari-extension',
    name: 'Safari Web Extension',
    type: 'custom',
    supportedPlatforms: ['desktop'],
    config: { features: ['native-macos', 'ios-integration'] },
    enabled: false
  }
]

// Cloud Storage & Automation
export const CLOUD_SERVERS: MCPServer[] = [
  {
    id: 'google-drive',
    name: 'Google Drive',
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'],
    requiredAuth: [{ type: 'oauth', name: 'Google Drive OAuth', required: true }],
    config: { features: ['file-management', 'collaboration'] },
    enabled: false
  },
  {
    id: 'dropbox-api',
    name: 'Dropbox Storage', 
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'],
    requiredAuth: [{ type: 'oauth', name: 'Dropbox OAuth', required: true }],
    config: { features: ['cloud-storage', 'file-sharing'], pricing: 'freemium' },
    enabled: false
  },
  {
    id: 'supabase-api',
    name: 'Supabase Database API',
    type: 'database',
    supportedPlatforms: ['web', 'desktop'],
    requiredAuth: [{ type: 'api_key', name: 'SUPABASE_API_KEY', required: true }],
    config: { 
      features: ['postgresql', 'real-time', 'file-storage', 'api-endpoints'],
      pricing: 'freemium'
    },
    enabled: false
  },
  {
    id: 'zapier-webhooks',
    name: 'Zapier Automation',
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'],
    requiredAuth: [{ type: 'api_key', name: 'ZAPIER_API_KEY', required: true }],
    config: { 
      features: ['5000-apps', 'workflows', 'triggers', 'data-transformation'],
      pricing: 'freemium'
    },
    enabled: false
  },
  {
    id: 'make-automation',
    name: 'Make (Integromat)',
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'],
    requiredAuth: [{ type: 'api_key', name: 'MAKE_API_KEY', required: true }],
    config: { features: ['visual-automation', 'advanced-workflows'] },
    enabled: false
  },
  {
    id: 'ifttt-api',
    name: 'IFTTT Applets',
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'],
    requiredAuth: [{ type: 'api_key', name: 'IFTTT_API_KEY', required: true }],
    config: { features: ['consumer-automation', 'simple-triggers'] },
    enabled: false
  }
]

// Productivity & Project Management
export const PRODUCTIVITY_SERVERS: MCPServer[] = [
  {
    id: 'notion-api',
    name: 'Notion Workspace',
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'],
    requiredAuth: [{ type: 'oauth', name: 'Notion OAuth', required: true }],
    config: { features: ['workspace-management', 'content-creation'] },
    enabled: false
  },
  {
    id: 'linear-api',
    name: 'Linear Project Management',
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'],
    requiredAuth: [{ type: 'api_key', name: 'LINEAR_API_KEY', required: true }],
    config: { features: ['task-management', 'bug-tracking'] },
    enabled: false
  },
  {
    id: 'google-analytics',
    name: 'Google Analytics',
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'], 
    requiredAuth: [{ type: 'oauth', name: 'Google Analytics OAuth', required: true }],
    config: { features: ['web-analytics', 'reporting'], pricing: 'freemium' },
    enabled: false
  },
  {
    id: 'mixpanel-analytics',
    name: 'Mixpanel Analytics',
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'],
    requiredAuth: [{ type: 'api_key', name: 'MIXPANEL_API_KEY', required: true }],
    config: { features: ['product-analytics', 'user-tracking'], pricing: 'freemium' },
    enabled: false
  }
]

// Enterprise Cloud Platforms
export const ENTERPRISE_CLOUD_SERVERS: MCPServer[] = [
  {
    id: 'aws-mcp',
    name: 'AWS MCP Server',
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'],
    requiredAuth: [
      { type: 'api_key', name: 'AWS_ACCESS_KEY_ID', required: true },
      { type: 'api_key', name: 'AWS_SECRET_ACCESS_KEY', required: true }
    ],
    config: { 
      services: ['ec2', 's3', 'lambda', 'rds', 'cloudwatch'],
      features: ['complete-aws-integration']
    },
    enabled: false
  },
  {
    id: 'google-cloud-mcp',
    name: 'Google Cloud MCP Server',
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'],
    requiredAuth: [{ type: 'oauth', name: 'GCP OAuth', required: true }],
    config: { 
      services: ['compute-engine', 'cloud-storage', 'bigquery', 'ai-platform'],
      features: ['ai-capabilities']
    },
    enabled: false
  },
  {
    id: 'azure-mcp',
    name: 'Microsoft Azure MCP Server',
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'],
    requiredAuth: [{ type: 'oauth', name: 'Azure OAuth', required: true }],
    config: { 
      services: ['virtual-machines', 'storage', 'sql-database', 'active-directory'],
      features: ['enterprise-integration']
    },
    enabled: false
  },
  {
    id: 'vercel-mcp',
    name: 'Vercel MCP Server',
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'],
    requiredAuth: [{ type: 'bearer_token', name: 'VERCEL_TOKEN', required: true }],
    config: { features: ['nextjs-deployment', 'edge-functions'] },
    enabled: false
  }
]

// Security & Enterprise
export const SECURITY_SERVERS: MCPServer[] = [
  {
    id: 'hashicorp-vault',
    name: 'HashiCorp Vault MCP Server',
    type: 'custom',
    supportedPlatforms: ['desktop'], // Desktop only for security
    requiredAuth: [{ type: 'bearer_token', name: 'VAULT_TOKEN', required: true }],
    config: { features: ['enterprise-secrets', 'dynamic-credentials'] },
    enabled: false
  }
]

// Export all server collections
export const ALL_ENTERPRISE_SERVERS: Record<string, MCPServer> = {
  ...DESIGN_SERVERS.reduce((acc, server) => ({ ...acc, [server.id]: server }), {} as Record<string, MCPServer>),
  ...MICROSOFT_SERVERS.reduce((acc, server) => ({ ...acc, [server.id]: server }), {} as Record<string, MCPServer>),
  ...COMMUNICATION_SERVERS.reduce((acc, server) => ({ ...acc, [server.id]: server }), {} as Record<string, MCPServer>),
  ...AI_SERVERS.reduce((acc, server) => ({ ...acc, [server.id]: server }), {} as Record<string, MCPServer>),
  ...BROWSER_SERVERS.reduce((acc, server) => ({ ...acc, [server.id]: server }), {} as Record<string, MCPServer>),
  ...CLOUD_SERVERS.reduce((acc, server) => ({ ...acc, [server.id]: server }), {} as Record<string, MCPServer>),
  ...PRODUCTIVITY_SERVERS.reduce((acc, server) => ({ ...acc, [server.id]: server }), {} as Record<string, MCPServer>),
  ...ENTERPRISE_CLOUD_SERVERS.reduce((acc, server) => ({ ...acc, [server.id]: server }), {} as Record<string, MCPServer>),
  ...SECURITY_SERVERS.reduce((acc, server) => ({ ...acc, [server.id]: server }), {} as Record<string, MCPServer>)
}