import type { MCPServer } from '@agentengine/shared-types';

export interface MCPServerTemplate {
  id: string;
  name: string;
  description: string;
  category: string;
  difficulty: 'beginner' | 'intermediate' | 'advanced';
  server: Omit<MCPServer, 'enabled'>;
  configFields: MCPConfigField[];
  setupInstructions: string[];
  prerequisites: string[];
  examples: MCPExample[];
  tags: string[];
}

export interface MCPConfigField {
  name: string;
  label: string;
  type: 'text' | 'password' | 'number' | 'boolean' | 'select' | 'path' | 'url';
  required: boolean;
  description: string;
  placeholder?: string;
  defaultValue?: any;
  options?: { label: string; value: any }[];
  validation?: {
    pattern?: string;
    min?: number;
    max?: number;
    message?: string;
  };
}

export interface MCPExample {
  title: string;
  description: string;
  command: string;
  expectedResult: string;
}

// Core Templates - Most commonly used MCP servers
export const CORE_TEMPLATES: MCPServerTemplate[] = [
  {
    id: 'filesystem-template',
    name: 'Filesystem Access',
    description: 'Read, write, and manage files and directories on your local system',
    category: 'Development',
    difficulty: 'beginner',
    server: {
      id: 'filesystem-mcp',
      name: 'Filesystem MCP Server',
      type: 'filesystem',
      config: {
        features: ['read', 'write', 'list', 'create', 'delete'],
        pricing: 'free'
      }
    },
    configFields: [
      {
        name: 'rootPath',
        label: 'Root Directory',
        type: 'path',
        required: true,
        description: 'The root directory that the MCP server can access',
        placeholder: 'C:\\Users\\YourName\\Documents',
        defaultValue: process.cwd?.() || ''
      },
      {
        name: 'readOnly',
        label: 'Read Only Mode',
        type: 'boolean',
        required: false,
        description: 'If enabled, only allow reading files (no writing/deleting)',
        defaultValue: false
      },
      {
        name: 'allowedExtensions',
        label: 'Allowed File Extensions',
        type: 'text',
        required: false,
        description: 'Comma-separated list of allowed file extensions (leave empty for all)',
        placeholder: '.txt,.md,.json,.js,.ts'
      }
    ],
    setupInstructions: [
      'Install uvx: npm install -g @modelcontextprotocol/uvx',
      'Choose a root directory for file access',
      'Consider using read-only mode for safety',
      'Test with a simple file read operation'
    ],
    prerequisites: [
      'Node.js installed',
      'uvx package manager',
      'Local filesystem access permissions'
    ],
    examples: [
      {
        title: 'Read a file',
        description: 'Read the contents of a specific file',
        command: 'read file "README.md"',
        expectedResult: 'Returns the contents of README.md file'
      },
      {
        title: 'List directory',
        description: 'List files in the current directory',
        command: 'list files in current directory',
        expectedResult: 'Returns array of files and directories'
      },
      {
        title: 'Create a file',
        description: 'Create a new file with content',
        command: 'create file "test.txt" with content "Hello World"',
        expectedResult: 'Creates test.txt with the specified content'
      }
    ],
    tags: ['files', 'local', 'development', 'basic']
  },

  {
    id: 'github-template',
    name: 'GitHub Integration',
    description: 'Access GitHub repositories, issues, pull requests, and more',
    category: 'Development',
    difficulty: 'intermediate',
    server: {
      id: 'github-mcp',
      name: 'GitHub MCP Server',
      type: 'github',
      config: {
        features: ['repositories', 'issues', 'pull-requests', 'commits'],
        pricing: 'free'
      },
      requiredAuth: [
        { type: 'api_key', name: 'GITHUB_TOKEN', required: true }
      ]
    },
    configFields: [
      {
        name: 'GITHUB_TOKEN',
        label: 'GitHub Personal Access Token',
        type: 'password',
        required: true,
        description: 'GitHub PAT with appropriate permissions for your repositories',
        placeholder: 'ghp_xxxxxxxxxxxxxxxxxxxx'
      },
      {
        name: 'defaultOwner',
        label: 'Default Repository Owner',
        type: 'text',
        required: false,
        description: 'Default GitHub username/organization for repository operations',
        placeholder: 'your-username'
      },
      {
        name: 'includeForks',
        label: 'Include Forked Repositories',
        type: 'boolean',
        required: false,
        description: 'Include forked repositories in repository listings',
        defaultValue: false
      }
    ],
    setupInstructions: [
      'Go to GitHub Settings > Developer settings > Personal access tokens',
      'Create a new token with repo, issues, and pull_request permissions',
      'Copy the token (you won\'t see it again)',
      'Paste the token in the configuration field'
    ],
    prerequisites: [
      'GitHub account',
      'Personal Access Token with appropriate permissions',
      'Internet connection'
    ],
    examples: [
      {
        title: 'List repositories',
        description: 'Get a list of your repositories',
        command: 'list my repositories',
        expectedResult: 'Returns array of repository objects'
      },
      {
        title: 'Get repository info',
        description: 'Get detailed information about a repository',
        command: 'get info for repository "owner/repo-name"',
        expectedResult: 'Returns repository details, stars, forks, etc.'
      },
      {
        title: 'Create an issue',
        description: 'Create a new issue in a repository',
        command: 'create issue "Bug report" in repository "owner/repo"',
        expectedResult: 'Creates a new issue and returns the issue URL'
      }
    ],
    tags: ['github', 'git', 'repositories', 'collaboration', 'api']
  },

  {
    id: 'postgres-template',
    name: 'PostgreSQL Database',
    description: 'Query and manage PostgreSQL databases with full SQL support',
    category: 'Database',
    difficulty: 'intermediate',
    server: {
      id: 'postgres-mcp',
      name: 'PostgreSQL MCP Server',
      type: 'database',
      config: {
        features: ['queries', 'schema', 'transactions'],
        pricing: 'free'
      }
    },
    configFields: [
      {
        name: 'connectionString',
        label: 'Connection String',
        type: 'text',
        required: true,
        description: 'PostgreSQL connection string',
        placeholder: 'postgresql://username:password@localhost:5432/database',
        validation: {
          pattern: '^postgresql://.+',
          message: 'Must be a valid PostgreSQL connection string'
        }
      },
      {
        name: 'ssl',
        label: 'Use SSL',
        type: 'boolean',
        required: false,
        description: 'Enable SSL connection to the database',
        defaultValue: true
      },
      {
        name: 'maxConnections',
        label: 'Maximum Connections',
        type: 'number',
        required: false,
        description: 'Maximum number of concurrent database connections',
        defaultValue: 5,
        validation: {
          min: 1,
          max: 20,
          message: 'Must be between 1 and 20'
        }
      }
    ],
    setupInstructions: [
      'Ensure PostgreSQL server is running and accessible',
      'Create a database user with appropriate permissions',
      'Test the connection string with a PostgreSQL client',
      'Configure firewall rules if connecting remotely'
    ],
    prerequisites: [
      'PostgreSQL server running',
      'Database connection credentials',
      'Network access to database server'
    ],
    examples: [
      {
        title: 'Query data',
        description: 'Execute a SELECT query',
        command: 'query "SELECT * FROM users LIMIT 10"',
        expectedResult: 'Returns array of user records'
      },
      {
        title: 'Get table schema',
        description: 'Describe the structure of a table',
        command: 'describe table "users"',
        expectedResult: 'Returns column definitions and constraints'
      },
      {
        title: 'Execute update',
        description: 'Update records in a table',
        command: 'update users set active=true where id=1',
        expectedResult: 'Returns number of affected rows'
      }
    ],
    tags: ['database', 'sql', 'postgresql', 'data', 'backend']
  },

  {
    id: 'memory-template',
    name: 'Memory Storage',
    description: 'Persistent memory for storing and recalling information across conversations',
    category: 'Utility',
    difficulty: 'beginner',
    server: {
      id: 'memory-mcp',
      name: 'Memory MCP Server',
      type: 'custom',
      config: {
        features: ['persistent-storage', 'key-value', 'search'],
        pricing: 'free'
      }
    },
    configFields: [
      {
        name: 'storageType',
        label: 'Storage Type',
        type: 'select',
        required: true,
        description: 'Choose how memory data is stored',
        defaultValue: 'file',
        options: [
          { label: 'File System', value: 'file' },
          { label: 'In Memory (temporary)', value: 'memory' },
          { label: 'SQLite Database', value: 'sqlite' }
        ]
      },
      {
        name: 'storagePath',
        label: 'Storage Path',
        type: 'path',
        required: false,
        description: 'Path where memory data will be stored (for file/sqlite storage)',
        placeholder: './memory-data',
        defaultValue: './memory-data'
      },
      {
        name: 'maxEntries',
        label: 'Maximum Entries',
        type: 'number',
        required: false,
        description: 'Maximum number of memory entries to store',
        defaultValue: 1000,
        validation: {
          min: 10,
          max: 10000,
          message: 'Must be between 10 and 10,000'
        }
      }
    ],
    setupInstructions: [
      'Choose a storage type based on your persistence needs',
      'Set a storage path for file-based storage',
      'Configure maximum entries to prevent unlimited growth',
      'Test with simple remember/recall operations'
    ],
    prerequisites: [
      'File system write permissions (for file storage)',
      'SQLite support (for sqlite storage)'
    ],
    examples: [
      {
        title: 'Store information',
        description: 'Remember a piece of information',
        command: 'remember that John\'s favorite color is blue',
        expectedResult: 'Information stored successfully'
      },
      {
        title: 'Recall information',
        description: 'Retrieve stored information',
        command: 'what is John\'s favorite color?',
        expectedResult: 'Returns: John\'s favorite color is blue'
      },
      {
        title: 'Search memories',
        description: 'Search through stored information',
        command: 'search for information about John',
        expectedResult: 'Returns all stored information related to John'
      }
    ],
    tags: ['memory', 'storage', 'persistence', 'recall', 'utility']
  },

  {
    id: 'search-template',
    name: 'Web Search',
    description: 'Search the web using Brave Search API for current information',
    category: 'Information',
    difficulty: 'beginner',
    server: {
      id: 'search-mcp',
      name: 'Brave Search MCP Server',
      type: 'web',
      config: {
        features: ['web-search', 'real-time', 'privacy-focused'],
        pricing: 'freemium'
      },
      requiredAuth: [
        { type: 'api_key', name: 'BRAVE_API_KEY', required: true }
      ]
    },
    configFields: [
      {
        name: 'BRAVE_API_KEY',
        label: 'Brave Search API Key',
        type: 'password',
        required: true,
        description: 'API key from Brave Search API',
        placeholder: 'BSA-xxxxxxxxxxxxxxxxxxxx'
      },
      {
        name: 'defaultRegion',
        label: 'Default Search Region',
        type: 'select',
        required: false,
        description: 'Default region for search results',
        defaultValue: 'US',
        options: [
          { label: 'United States', value: 'US' },
          { label: 'United Kingdom', value: 'GB' },
          { label: 'Canada', value: 'CA' },
          { label: 'Australia', value: 'AU' },
          { label: 'Global', value: 'ALL' }
        ]
      },
      {
        name: 'maxResults',
        label: 'Maximum Results',
        type: 'number',
        required: false,
        description: 'Maximum number of search results to return',
        defaultValue: 10,
        validation: {
          min: 1,
          max: 50,
          message: 'Must be between 1 and 50'
        }
      }
    ],
    setupInstructions: [
      'Sign up for Brave Search API at search.brave.com/api',
      'Get your API key from the dashboard',
      'Configure your preferred search region',
      'Set reasonable result limits to avoid quota issues'
    ],
    prerequisites: [
      'Brave Search API account',
      'Valid API key',
      'Internet connection'
    ],
    examples: [
      {
        title: 'Web search',
        description: 'Search for current information on the web',
        command: 'search for "latest AI developments 2024"',
        expectedResult: 'Returns current web search results about AI developments'
      },
      {
        title: 'News search',
        description: 'Find recent news articles',
        command: 'find recent news about climate change',
        expectedResult: 'Returns recent news articles about climate change'
      },
      {
        title: 'Technical search',
        description: 'Search for technical information',
        command: 'search for "React hooks best practices"',
        expectedResult: 'Returns technical articles and documentation'
      }
    ],
    tags: ['search', 'web', 'information', 'current', 'brave']
  }
];

// Development Templates - Advanced development tools
export const DEVELOPMENT_TEMPLATES: MCPServerTemplate[] = [
  {
    id: 'git-template',
    name: 'Git Repository Management',
    description: 'Manage Git repositories with commits, branches, and history',
    category: 'Development',
    difficulty: 'intermediate',
    server: {
      id: 'git-mcp',
      name: 'Git MCP Server',
      type: 'git',
      config: {
        features: ['commits', 'branches', 'history', 'diff'],
        pricing: 'free'
      }
    },
    configFields: [
      {
        name: 'repositoryPath',
        label: 'Repository Path',
        type: 'path',
        required: true,
        description: 'Path to the Git repository',
        placeholder: '/path/to/your/repo'
      },
      {
        name: 'allowDestructive',
        label: 'Allow Destructive Operations',
        type: 'boolean',
        required: false,
        description: 'Allow operations that can modify repository state',
        defaultValue: false
      }
    ],
    setupInstructions: [
      'Ensure Git is installed on your system',
      'Navigate to a Git repository directory',
      'Consider safety settings for destructive operations',
      'Test with basic Git status operations'
    ],
    prerequisites: [
      'Git installed',
      'Git repository initialized',
      'Proper Git configuration'
    ],
    examples: [
      {
        title: 'Check status',
        description: 'Get the current Git repository status',
        command: 'check git status',
        expectedResult: 'Returns current branch, staged/unstaged files'
      },
      {
        title: 'View commit history',
        description: 'Show recent commit history',
        command: 'show last 10 commits',
        expectedResult: 'Returns commit history with messages and authors'
      },
      {
        title: 'Create branch',
        description: 'Create a new Git branch',
        command: 'create branch "feature/new-feature"',
        expectedResult: 'Creates and optionally switches to new branch'
      }
    ],
    tags: ['git', 'version-control', 'development', 'repository']
  },

  {
    id: 'http-template',
    name: 'HTTP API Client',
    description: 'Make HTTP requests to APIs and web services',
    category: 'Development',
    difficulty: 'intermediate',
    server: {
      id: 'http-mcp',
      name: 'HTTP MCP Server',
      type: 'api',
      config: {
        features: ['get', 'post', 'put', 'delete', 'headers'],
        pricing: 'free'
      }
    },
    configFields: [
      {
        name: 'baseURL',
        label: 'Base URL',
        type: 'url',
        required: false,
        description: 'Default base URL for API requests',
        placeholder: 'https://api.example.com'
      },
      {
        name: 'defaultHeaders',
        label: 'Default Headers',
        type: 'text',
        required: false,
        description: 'Default headers for all requests (JSON format)',
        placeholder: '{"Authorization": "Bearer token", "Content-Type": "application/json"}',
        defaultValue: '{"Content-Type": "application/json"}'
      },
      {
        name: 'timeout',
        label: 'Request Timeout (seconds)',
        type: 'number',
        required: false,
        description: 'Maximum time to wait for HTTP responses',
        defaultValue: 30,
        validation: {
          min: 1,
          max: 300,
          message: 'Must be between 1 and 300 seconds'
        }
      }
    ],
    setupInstructions: [
      'Configure base URL if working with a specific API',
      'Set up authentication headers if required',
      'Configure appropriate timeouts for your use case',
      'Test with simple GET requests first'
    ],
    prerequisites: [
      'Internet connection',
      'API endpoints to test with',
      'Authentication credentials if required'
    ],
    examples: [
      {
        title: 'GET request',
        description: 'Make a GET request to an API endpoint',
        command: 'make GET request to "https://api.github.com/user"',
        expectedResult: 'Returns API response data'
      },
      {
        title: 'POST request',
        description: 'Send data with a POST request',
        command: 'POST to "/api/users" with data {"name": "John"}',
        expectedResult: 'Returns created resource or confirmation'
      },
      {
        title: 'API with headers',
        description: 'Make request with custom headers',
        command: 'GET "/api/data" with header "Authorization: Bearer token"',
        expectedResult: 'Returns authenticated API response'
      }
    ],
    tags: ['http', 'api', 'rest', 'requests', 'web-services']
  }
];

// All templates combined
export const ALL_TEMPLATES: MCPServerTemplate[] = [
  ...CORE_TEMPLATES,
  ...DEVELOPMENT_TEMPLATES
];

// Template utilities
export function getTemplateById(id: string): MCPServerTemplate | undefined {
  return ALL_TEMPLATES.find(template => template.id === id);
}

export function getTemplatesByCategory(category: string): MCPServerTemplate[] {
  return ALL_TEMPLATES.filter(template => template.category === category);
}

export function getTemplatesByDifficulty(difficulty: 'beginner' | 'intermediate' | 'advanced'): MCPServerTemplate[] {
  return ALL_TEMPLATES.filter(template => template.difficulty === difficulty);
}

export function searchTemplates(query: string): MCPServerTemplate[] {
  const lowerQuery = query.toLowerCase();
  return ALL_TEMPLATES.filter(template =>
    template.name.toLowerCase().includes(lowerQuery) ||
    template.description.toLowerCase().includes(lowerQuery) ||
    template.tags.some(tag => tag.toLowerCase().includes(lowerQuery))
  );
}

export function getPopularTemplates(): MCPServerTemplate[] {
  // Return core templates as they are the most commonly used
  return CORE_TEMPLATES;
}