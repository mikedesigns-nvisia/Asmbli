import type { MCPServer } from '@agentengine/shared-types'

// Core MCP Protocol Servers (Official implementations)
export const CORE_MCP_SERVERS: MCPServer[] = [
  {
    id: 'filesystem-mcp',
    name: 'Filesystem MCP Server',
    type: 'filesystem',
    supportedPlatforms: ['desktop'], // Desktop only for security
    command: 'uvx @modelcontextprotocol/server-filesystem',
    config: { 
      features: ['file-io', 'directory-traversal', 'search', 'metadata', 'permissions', 'batch-operations', 'file-monitoring'],
      security: 'low-complexity',
      sandboxed: true
    },
    requiredAuth: [],
    enabled: false,
    version: '1.0.0'
  },
  {
    id: 'git-mcp',
    name: 'Git MCP Server',
    type: 'git',
    supportedPlatforms: ['desktop'],
    command: 'uvx @modelcontextprotocol/server-git',
    config: { 
      features: ['repo-cloning', 'branch-management', 'commit-history', 'staging', 'remote-operations', 'merge-resolution'],
      security: 'medium-complexity',
      status: 'early-development'
    },
    requiredAuth: [],
    enabled: false,
    version: '0.1.0'
  },
  {
    id: 'github',
    name: 'GitHub Integration',
    type: 'github', 
    supportedPlatforms: ['web', 'desktop'],
    command: 'uvx @modelcontextprotocol/server-github',
    config: { 
      features: ['repository-access', 'pull-requests', 'issues', 'code-review', 'actions-integration', 'design-system-management'],
      connectionTypes: ['api', 'mcp', 'copilot'],
      apiUrl: 'https://api.github.com'
    },
    requiredAuth: [
      { 
        type: 'bearer_token', 
        name: 'GITHUB_PERSONAL_ACCESS_TOKEN', 
        required: true,
        description: 'GitHub personal access token with repo access'
      }
    ],
    enabled: false,
    version: '1.0.0'
  },
  {
    id: 'postgres-mcp',
    name: 'PostgreSQL MCP Server',
    type: 'database',
    supportedPlatforms: ['web', 'desktop'],
    command: 'uvx @modelcontextprotocol/server-postgres',
    config: { 
      features: ['sql-execution', 'schema-introspection', 'performance-analysis'],
      security: 'high-complexity',
      variants: ['official-readonly', 'community-full']
    },
    requiredAuth: [
      { 
        type: 'basic_auth', 
        name: 'POSTGRES_CONNECTION_STRING', 
        required: true,
        description: 'PostgreSQL connection string'
      }
    ],
    enabled: false,
    version: '1.0.0'
  },
  {
    id: 'memory-mcp',
    name: 'Memory MCP Server',
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'],
    command: 'uvx @modelcontextprotocol/server-memory',
    config: { 
      features: ['knowledge-storage', 'semantic-search', 'context-aware-management', 'entity-relationships'],
      description: 'Persistent memory and knowledge base management for AI agents'
    },
    requiredAuth: [],
    enabled: false,
    version: '1.0.0'
  },
  {
    id: 'search-mcp',
    name: 'Brave Search MCP Server',
    type: 'web',
    supportedPlatforms: ['web', 'desktop'],
    command: 'uvx @modelcontextprotocol/server-brave-search',
    config: { 
      features: ['multiple-search-engines', 'real-time-retrieval', 'ranking', 'domain-specific-searches'],
      pricing: 'freemium'
    },
    requiredAuth: [
      { 
        type: 'api_key', 
        name: 'BRAVE_API_KEY', 
        required: true,
        description: 'Brave Search API key'
      }
    ],
    enabled: false,
    version: '1.0.0'
  },
  {
    id: 'http-mcp',
    name: 'HTTP MCP Server',
    type: 'api',
    supportedPlatforms: ['web', 'desktop'],
    command: 'uvx @modelcontextprotocol/server-fetch',
    config: { 
      features: ['all-http-methods', 'authentication', 'response-parsing', 'error-handling', 'rate-limiting'],
      security: 'medium-complexity',
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH']
    },
    requiredAuth: [
      { 
        type: 'api_key', 
        name: 'HTTP_API_KEY', 
        required: false,
        description: 'Optional API key for authenticated requests'
      }
    ],
    enabled: false,
    version: '1.0.0'
  },
  {
    id: 'calendar-mcp',
    name: 'Calendar MCP Server',
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'],
    config: { 
      features: ['event-creation', 'calendar-sync', 'meeting-scheduling', 'availability-checking'],
      description: 'Calendar and scheduling operations'
    },
    requiredAuth: [
      { 
        type: 'oauth', 
        name: 'Calendar OAuth', 
        required: true,
        description: 'OAuth token for calendar access'
      }
    ],
    enabled: false,
    version: '1.0.0'
  },
  {
    id: 'sequential-thinking-mcp',
    name: 'Sequential Thinking MCP Server',
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'],
    config: { 
      features: ['sequential-thought-generation', 'problem-decomposition', 'reasoning-chains'],
      description: 'Dynamic problem-solving through thought sequences and structured reasoning',
      featured: false // Not featured due to complexity
    },
    requiredAuth: [],
    enabled: false,
    version: '0.1.0'
  },
  {
    id: 'time-mcp',
    name: 'Time MCP Server',
    type: 'custom',
    supportedPlatforms: ['web', 'desktop'],
    config: { 
      features: ['timezone-conversion', 'format-standardization', 'schedule-calculation', 'world-clock'],
      security: 'low-complexity',
      description: 'Time and timezone conversion with scheduling operations'
    },
    requiredAuth: [],
    enabled: false,
    version: '1.0.0'
  },
  {
    id: 'terminal-mcp',
    name: 'Terminal MCP Server',
    type: 'custom',
    supportedPlatforms: ['desktop'], // Desktop only for security
    config: { 
      features: ['command-execution', 'environment-management', 'process-monitoring', 'package-manager-integration'],
      security: 'high-complexity',
      description: 'Shell commands and terminal operations execution',
      featured: false, // Not featured due to security concerns
      sandboxed: true
    },
    requiredAuth: [],
    enabled: false,
    version: '1.0.0'
  }
]