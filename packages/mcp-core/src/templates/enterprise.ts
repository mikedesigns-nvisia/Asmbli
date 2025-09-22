import type { MCPServerTemplate } from './index';

// Enterprise Templates - Business and productivity tools
export const ENTERPRISE_TEMPLATES: MCPServerTemplate[] = [
  {
    id: 'slack-template',
    name: 'Slack Integration',
    description: 'Send messages, read channels, and manage Slack workspaces',
    category: 'Communication',
    difficulty: 'intermediate',
    server: {
      id: 'slack-mcp',
      name: 'Slack Integration',
      type: 'custom',
      config: {
        features: ['messaging', 'channels', 'users', 'files'],
        pricing: 'freemium'
      },
      requiredAuth: [
        { type: 'bearer_token', name: 'SLACK_BOT_TOKEN', required: true }
      ]
    },
    configFields: [
      {
        name: 'SLACK_BOT_TOKEN',
        label: 'Slack Bot Token',
        type: 'password',
        required: true,
        description: 'Bot token from your Slack app (starts with xoxb-)',
        placeholder: 'xoxb-xxxxxxxxxxxx-xxxxxxxxxxxx-xxxxxxxxxxxxxxxx'
      },
      {
        name: 'defaultChannel',
        label: 'Default Channel',
        type: 'text',
        required: false,
        description: 'Default channel for messages (without #)',
        placeholder: 'general'
      },
      {
        name: 'allowDM',
        label: 'Allow Direct Messages',
        type: 'boolean',
        required: false,
        description: 'Allow sending direct messages to users',
        defaultValue: true
      }
    ],
    setupInstructions: [
      'Create a Slack app at api.slack.com/apps',
      'Add Bot Token Scopes: chat:write, channels:read, users:read',
      'Install the app to your workspace',
      'Copy the Bot User OAuth Token'
    ],
    prerequisites: [
      'Slack workspace admin access',
      'Slack app creation permissions',
      'Bot token with appropriate scopes'
    ],
    examples: [
      {
        title: 'Send message',
        description: 'Send a message to a channel',
        command: 'send message "Hello team!" to #general',
        expectedResult: 'Message sent successfully to the channel'
      },
      {
        title: 'List channels',
        description: 'Get list of available channels',
        command: 'list slack channels',
        expectedResult: 'Returns array of channel names and IDs'
      },
      {
        title: 'Get channel history',
        description: 'Read recent messages from a channel',
        command: 'get last 10 messages from #general',
        expectedResult: 'Returns recent messages with authors and timestamps'
      }
    ],
    tags: ['slack', 'communication', 'messaging', 'team', 'enterprise']
  },

  {
    id: 'notion-template',
    name: 'Notion Workspace',
    description: 'Create, read, and update Notion pages and databases',
    category: 'Productivity',
    difficulty: 'advanced',
    server: {
      id: 'notion-mcp',
      name: 'Notion Workspace',
      type: 'custom',
      config: {
        features: ['pages', 'databases', 'blocks', 'properties'],
        pricing: 'freemium'
      },
      requiredAuth: [
        { type: 'api_key', name: 'NOTION_TOKEN', required: true }
      ]
    },
    configFields: [
      {
        name: 'NOTION_TOKEN',
        label: 'Notion Integration Token',
        type: 'password',
        required: true,
        description: 'Integration token from Notion developer settings',
        placeholder: 'secret_xxxxxxxxxxxxxxxxxxxx'
      },
      {
        name: 'defaultDatabase',
        label: 'Default Database ID',
        type: 'text',
        required: false,
        description: 'Default database ID for operations (optional)',
        placeholder: '12345678-1234-1234-1234-123456789012'
      },
      {
        name: 'includeArchived',
        label: 'Include Archived Pages',
        type: 'boolean',
        required: false,
        description: 'Include archived pages in search results',
        defaultValue: false
      }
    ],
    setupInstructions: [
      'Go to notion.so/my-integrations and create a new integration',
      'Copy the Internal Integration Token',
      'Share relevant pages/databases with your integration',
      'Test with a simple page read operation'
    ],
    prerequisites: [
      'Notion workspace access',
      'Integration creation permissions',
      'Pages/databases shared with integration'
    ],
    examples: [
      {
        title: 'Create page',
        description: 'Create a new page in Notion',
        command: 'create page "Meeting Notes" with content "Today we discussed..."',
        expectedResult: 'Creates new page and returns page URL'
      },
      {
        title: 'Query database',
        description: 'Query a Notion database',
        command: 'query database for tasks where status is "Todo"',
        expectedResult: 'Returns matching database entries'
      },
      {
        title: 'Update page',
        description: 'Update an existing page',
        command: 'update page "Project Status" with new content',
        expectedResult: 'Updates page content successfully'
      }
    ],
    tags: ['notion', 'productivity', 'notes', 'database', 'workspace']
  },

  {
    id: 'google-drive-template',
    name: 'Google Drive',
    description: 'Access, create, and manage files in Google Drive',
    category: 'Cloud Storage',
    difficulty: 'intermediate',
    server: {
      id: 'google-drive-mcp',
      name: 'Google Drive',
      type: 'custom',
      config: {
        features: ['files', 'folders', 'sharing', 'search'],
        pricing: 'freemium'
      },
      requiredAuth: [
        { type: 'oauth', name: 'GOOGLE_OAUTH', required: true }
      ]
    },
    configFields: [
      {
        name: 'clientId',
        label: 'Google Client ID',
        type: 'text',
        required: true,
        description: 'Client ID from Google Cloud Console',
        placeholder: 'xxxxxxxxxxxx.apps.googleusercontent.com'
      },
      {
        name: 'clientSecret',
        label: 'Google Client Secret',
        type: 'password',
        required: true,
        description: 'Client secret from Google Cloud Console',
        placeholder: 'GOCSPX-xxxxxxxxxxxxxxxxxxxx'
      },
      {
        name: 'defaultFolder',
        label: 'Default Folder',
        type: 'text',
        required: false,
        description: 'Default folder name for operations',
        placeholder: 'Asmbli Files'
      }
    ],
    setupInstructions: [
      'Go to Google Cloud Console and create a new project',
      'Enable the Google Drive API',
      'Create OAuth 2.0 credentials',
      'Add authorized redirect URIs',
      'Complete OAuth flow for initial setup'
    ],
    prerequisites: [
      'Google account',
      'Google Cloud project',
      'Drive API enabled',
      'OAuth credentials configured'
    ],
    examples: [
      {
        title: 'List files',
        description: 'List files in Google Drive',
        command: 'list files in Google Drive',
        expectedResult: 'Returns array of files with names and IDs'
      },
      {
        title: 'Upload file',
        description: 'Upload a file to Google Drive',
        command: 'upload file "document.pdf" to Drive',
        expectedResult: 'Uploads file and returns Drive link'
      },
      {
        title: 'Share file',
        description: 'Share a file with others',
        command: 'share file "presentation.pptx" with "user@example.com"',
        expectedResult: 'Grants access and returns sharing link'
      }
    ],
    tags: ['google-drive', 'cloud', 'storage', 'files', 'sharing']
  },

  {
    id: 'microsoft-teams-template',
    name: 'Microsoft Teams',
    description: 'Send messages and manage Microsoft Teams communications',
    category: 'Communication',
    difficulty: 'advanced',
    server: {
      id: 'teams-mcp',
      name: 'Microsoft Teams',
      type: 'custom',
      config: {
        features: ['messaging', 'channels', 'meetings', 'files'],
        pricing: 'enterprise'
      },
      requiredAuth: [
        { type: 'oauth', name: 'MICROSOFT_OAUTH', required: true }
      ]
    },
    configFields: [
      {
        name: 'tenantId',
        label: 'Azure Tenant ID',
        type: 'text',
        required: true,
        description: 'Your Azure AD tenant ID',
        placeholder: '12345678-1234-1234-1234-123456789012'
      },
      {
        name: 'clientId',
        label: 'Application Client ID',
        type: 'text',
        required: true,
        description: 'Client ID from Azure app registration',
        placeholder: '12345678-1234-1234-1234-123456789012'
      },
      {
        name: 'clientSecret',
        label: 'Client Secret',
        type: 'password',
        required: true,
        description: 'Client secret from Azure app registration',
        placeholder: 'xxxxxxxxxxxxxxxxxxxx'
      },
      {
        name: 'defaultTeam',
        label: 'Default Team ID',
        type: 'text',
        required: false,
        description: 'Default team ID for operations',
        placeholder: '12345678-1234-1234-1234-123456789012'
      }
    ],
    setupInstructions: [
      'Register an app in Azure AD',
      'Grant Microsoft Graph permissions for Teams',
      'Configure authentication and get client secret',
      'Get admin consent for organization-wide permissions'
    ],
    prerequisites: [
      'Microsoft 365 subscription',
      'Azure AD admin access',
      'Teams application permissions',
      'Organization admin consent'
    ],
    examples: [
      {
        title: 'Send team message',
        description: 'Send a message to a Teams channel',
        command: 'send message "Project update" to Teams channel',
        expectedResult: 'Message posted to the specified channel'
      },
      {
        title: 'List teams',
        description: 'Get list of available teams',
        command: 'list my teams',
        expectedResult: 'Returns array of teams you have access to'
      },
      {
        title: 'Schedule meeting',
        description: 'Schedule a Teams meeting',
        command: 'schedule meeting "Weekly Standup" for tomorrow 2PM',
        expectedResult: 'Creates meeting and returns invitation link'
      }
    ],
    tags: ['microsoft-teams', 'communication', 'enterprise', 'meetings', 'collaboration']
  },

  {
    id: 'salesforce-template',
    name: 'Salesforce CRM',
    description: 'Access and manage Salesforce data, leads, and opportunities',
    category: 'CRM',
    difficulty: 'advanced',
    server: {
      id: 'salesforce-mcp',
      name: 'Salesforce CRM',
      type: 'custom',
      config: {
        features: ['soql', 'leads', 'opportunities', 'accounts', 'contacts'],
        pricing: 'enterprise'
      },
      requiredAuth: [
        { type: 'oauth', name: 'SALESFORCE_OAUTH', required: true }
      ]
    },
    configFields: [
      {
        name: 'instanceUrl',
        label: 'Salesforce Instance URL',
        type: 'url',
        required: true,
        description: 'Your Salesforce instance URL',
        placeholder: 'https://yourorg.my.salesforce.com'
      },
      {
        name: 'clientId',
        label: 'Connected App Client ID',
        type: 'text',
        required: true,
        description: 'Client ID from Salesforce Connected App',
        placeholder: '3MVG9xxxxxxxxxxxxxxxxxxxx'
      },
      {
        name: 'clientSecret',
        label: 'Connected App Client Secret',
        type: 'password',
        required: true,
        description: 'Client secret from Salesforce Connected App',
        placeholder: 'xxxxxxxxxxxxxxxxxxxx'
      },
      {
        name: 'apiVersion',
        label: 'API Version',
        type: 'select',
        required: false,
        description: 'Salesforce API version to use',
        defaultValue: '58.0',
        options: [
          { label: 'v58.0 (Winter \'24)', value: '58.0' },
          { label: 'v57.0 (Summer \'23)', value: '57.0' },
          { label: 'v56.0 (Spring \'23)', value: '56.0' }
        ]
      }
    ],
    setupInstructions: [
      'Create a Connected App in Salesforce Setup',
      'Enable OAuth settings and configure callback URL',
      'Set appropriate OAuth scopes (api, refresh_token)',
      'Note down Client ID and Client Secret',
      'Complete OAuth flow for initial authentication'
    ],
    prerequisites: [
      'Salesforce org with API access',
      'System Administrator permissions',
      'Connected App configuration',
      'OAuth authentication setup'
    ],
    examples: [
      {
        title: 'Query leads',
        description: 'Query recent leads from Salesforce',
        command: 'query leads created this week',
        expectedResult: 'Returns array of recent lead records'
      },
      {
        title: 'Create opportunity',
        description: 'Create a new sales opportunity',
        command: 'create opportunity "New Deal" for account "Acme Corp"',
        expectedResult: 'Creates opportunity and returns record ID'
      },
      {
        title: 'Update contact',
        description: 'Update contact information',
        command: 'update contact "John Smith" with phone "555-1234"',
        expectedResult: 'Updates contact record successfully'
      }
    ],
    tags: ['salesforce', 'crm', 'sales', 'leads', 'enterprise', 'soql']
  },

  {
    id: 'jira-template',
    name: 'Jira Project Management',
    description: 'Create, update, and track issues in Atlassian Jira',
    category: 'Project Management',
    difficulty: 'intermediate',
    server: {
      id: 'jira-mcp',
      name: 'Jira Project Management',
      type: 'custom',
      config: {
        features: ['issues', 'projects', 'workflows', 'comments'],
        pricing: 'freemium'
      },
      requiredAuth: [
        { type: 'api_key', name: 'JIRA_API_TOKEN', required: true }
      ]
    },
    configFields: [
      {
        name: 'jiraUrl',
        label: 'Jira Instance URL',
        type: 'url',
        required: true,
        description: 'Your Jira instance URL',
        placeholder: 'https://yourorg.atlassian.net'
      },
      {
        name: 'email',
        label: 'Email Address',
        type: 'text',
        required: true,
        description: 'Your Jira account email',
        placeholder: 'user@example.com'
      },
      {
        name: 'JIRA_API_TOKEN',
        label: 'API Token',
        type: 'password',
        required: true,
        description: 'API token from Atlassian account settings',
        placeholder: 'ATATTxxxxxxxxxxxxxxxxxx'
      },
      {
        name: 'defaultProject',
        label: 'Default Project Key',
        type: 'text',
        required: false,
        description: 'Default project key for operations',
        placeholder: 'PROJ'
      }
    ],
    setupInstructions: [
      'Go to id.atlassian.com and manage your account',
      'Create an API token in Security settings',
      'Note your Jira instance URL',
      'Test connection with a simple issue query'
    ],
    prerequisites: [
      'Jira account with project access',
      'API token generation permissions',
      'Project permissions for issue management'
    ],
    examples: [
      {
        title: 'Create issue',
        description: 'Create a new Jira issue',
        command: 'create bug "Login page not working" in project PROJ',
        expectedResult: 'Creates issue and returns issue key (PROJ-123)'
      },
      {
        title: 'Search issues',
        description: 'Search for issues using JQL',
        command: 'search for issues assigned to me',
        expectedResult: 'Returns array of matching issues'
      },
      {
        title: 'Update issue',
        description: 'Update an existing issue',
        command: 'update issue PROJ-123 status to "In Progress"',
        expectedResult: 'Updates issue status successfully'
      }
    ],
    tags: ['jira', 'project-management', 'issues', 'tracking', 'atlassian']
  }
];

// Template utilities for enterprise
export function getEnterpriseTemplatesByCategory(category: string): MCPServerTemplate[] {
  return ENTERPRISE_TEMPLATES.filter(template => template.category === category);
}

export function getEnterpriseCategories(): string[] {
  return [...new Set(ENTERPRISE_TEMPLATES.map(template => template.category))];
}