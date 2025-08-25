import 'package:flutter/material.dart';
import '../design_system/components/oauth_fields.dart';
import '../design_system/components/service_detection_fields.dart';
import '../design_system/components/mcp_field_types.dart';

/// Enhanced MCP template system that supports all field types
/// Auto-generates forms for any MCP server configuration

/// Enhanced MCP server template with rich field definitions
class EnhancedMCPTemplate {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String category;
  final String difficulty; // 'Easy', 'Medium', 'Hard'
  final List<String> tags;
  final Color? brandColor;
  
  // Command configuration
  final String command;
  final List<String> args;
  final String? workingDirectory;
  
  // Field definitions for smart form generation
  final List<MCPFieldDefinition> fields;
  
  // Prerequisites and setup requirements
  final List<String> prerequisites;
  final List<SetupInstruction> setupInstructions;
  final String? documentationUrl;
  
  // Platform and feature support
  final List<String> supportedPlatforms;
  final List<String> capabilities;
  final bool isPopular;
  final bool isRecommended;

  const EnhancedMCPTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.difficulty,
    this.tags = const [],
    this.brandColor,
    required this.command,
    this.args = const [],
    this.workingDirectory,
    this.fields = const [],
    this.prerequisites = const [],
    this.setupInstructions = const [],
    this.documentationUrl,
    this.supportedPlatforms = const ['desktop'],
    this.capabilities = const [],
    this.isPopular = false,
    this.isRecommended = false,
  });
}

/// Field definition for automatic form generation
class MCPFieldDefinition {
  final String id;
  final String label;
  final String? description;
  final String? placeholder;
  final bool required;
  final MCPFieldType fieldType;
  final Map<String, dynamic> options;
  final String? validationPattern;
  final String? validationMessage;
  final dynamic defaultValue;

  const MCPFieldDefinition({
    required this.id,
    required this.label,
    this.description,
    this.placeholder,
    this.required = false,
    required this.fieldType,
    this.options = const {},
    this.validationPattern,
    this.validationMessage,
    this.defaultValue,
  });
}

/// Supported field types for automatic form generation
enum MCPFieldType {
  text,
  password,
  email,
  url,
  number,
  boolean,
  select,
  multiSelect,
  path,
  file,
  directory,
  apiToken,
  oauth,
  database,
  serviceDetection,
  permissionScope,
}

/// Setup instruction for user guidance
class SetupInstruction {
  final int step;
  final String title;
  final String description;
  final String? imageUrl;
  final String? actionUrl;
  final String? actionText;

  const SetupInstruction({
    required this.step,
    required this.title,
    required this.description,
    this.imageUrl,
    this.actionUrl,
    this.actionText,
  });
}

/// Comprehensive template definitions for all MCP server types
class EnhancedMCPTemplates {
  
  // ==================== LOCAL/FILESYSTEM SERVERS ====================
  
  static const filesystem = EnhancedMCPTemplate(
    id: 'filesystem',
    name: 'Filesystem',
    description: 'Access local files and directories for reading and writing',
    icon: Icons.folder,
    category: 'Local',
    difficulty: 'Easy',
    tags: ['local', 'files', 'storage'],
    command: 'uvx',
    args: ['@modelcontextprotocol/server-filesystem'],
    fields: [
      MCPFieldDefinition(
        id: 'rootPath',
        label: 'Root Directory',
        description: 'Choose the root directory for file access',
        required: true,
        fieldType: MCPFieldType.directory,
        options: {
          'showPreview': true,
          'suggestedPaths': [
            '~/Documents',
            '~/Desktop', 
            '~/Projects',
          ],
        },
      ),
      MCPFieldDefinition(
        id: 'readOnly',
        label: 'Read-Only Mode',
        description: 'Restrict access to read-only operations for safety',
        fieldType: MCPFieldType.boolean,
        defaultValue: true,
      ),
      MCPFieldDefinition(
        id: 'allowedExtensions',
        label: 'Allowed File Types',
        description: 'Comma-separated list of allowed file extensions (optional)',
        fieldType: MCPFieldType.text,
        placeholder: 'txt,md,json,py',
      ),
    ],
    capabilities: ['Read files', 'Write files', 'List directories', 'File metadata'],
    isPopular: true,
  );

  static const git = EnhancedMCPTemplate(
    id: 'git',
    name: 'Git Repository',
    description: 'Git version control operations and repository management',
    icon: Icons.source,
    category: 'Development',
    difficulty: 'Medium',
    tags: ['git', 'version-control', 'development'],
    command: 'uvx',
    args: ['@modelcontextprotocol/server-git'],
    fields: [
      MCPFieldDefinition(
        id: 'repositoryPath',
        label: 'Repository Path',
        description: 'Path to your Git repository',
        required: true,
        fieldType: MCPFieldType.directory,
        options: {
          'autoDetectGit': true,
          'showGitStatus': true,
        },
      ),
      MCPFieldDefinition(
        id: 'allowDestructive',
        label: 'Allow Destructive Operations',
        description: 'Enable operations like reset, rebase, force push (use with caution)',
        fieldType: MCPFieldType.boolean,
        defaultValue: false,
      ),
    ],
    prerequisites: ['Git installed and configured'],
    capabilities: ['Read commits', 'Branch operations', 'File history', 'Diff generation'],
  );

  // ==================== CLOUD API SERVERS ====================
  
  static const github = EnhancedMCPTemplate(
    id: 'github',
    name: 'GitHub',
    description: 'GitHub repository access and management',
    icon: Icons.code,
    category: 'Cloud',
    difficulty: 'Medium',
    tags: ['github', 'git', 'cloud', 'api'],
    brandColor: Color(0xFF333333),
    command: 'uvx',
    args: ['@modelcontextprotocol/server-github'],
    fields: [
      MCPFieldDefinition(
        id: 'auth',
        label: 'GitHub Authentication',
        description: 'Connect your GitHub account',
        required: true,
        fieldType: MCPFieldType.oauth,
        options: {
          'provider': OAuthProvider.github,
          'scopes': ['repo', 'read:org'],
        },
      ),
    ],
    setupInstructions: [
      SetupInstruction(
        step: 1,
        title: 'OAuth Setup (Recommended)',
        description: 'Click "Connect" to authenticate with GitHub OAuth',
      ),
      SetupInstruction(
        step: 2,
        title: 'Or use Personal Access Token',
        description: 'Go to GitHub → Settings → Developer settings → Personal access tokens',
        actionUrl: 'https://github.com/settings/tokens',
        actionText: 'Generate Token',
      ),
    ],
    capabilities: ['Repository access', 'Issues management', 'Pull requests', 'Code search'],
    isPopular: true,
  );

  static const figma = EnhancedMCPTemplate(
    id: 'figma',
    name: 'Figma',
    description: 'Design file access and component management',
    icon: Icons.design_services,
    category: 'Design',
    difficulty: 'Medium',
    tags: ['figma', 'design', 'ui', 'components'],
    brandColor: Color(0xFFF24E1E),
    command: 'uvx',
    args: ['@modelcontextprotocol/server-figma'],
    fields: [
      MCPFieldDefinition(
        id: 'auth',
        label: 'Figma Authentication',
        description: 'Connect your Figma account',
        required: true,
        fieldType: MCPFieldType.oauth,
        options: {
          'provider': OAuthProvider.figma,
        },
      ),
    ],
    capabilities: ['File access', 'Component library', 'Design tokens', 'Asset export'],
    isRecommended: true,
  );

  // ==================== DATABASE SERVERS ====================
  
  static const postgresql = EnhancedMCPTemplate(
    id: 'postgresql',
    name: 'PostgreSQL',
    description: 'PostgreSQL database access and management',
    icon: Icons.storage,
    category: 'Database',
    difficulty: 'Medium',
    tags: ['postgresql', 'database', 'sql'],
    command: 'uvx',
    args: ['@modelcontextprotocol/server-postgres'],
    fields: [
      MCPFieldDefinition(
        id: 'detection',
        label: 'Auto-Detect PostgreSQL',
        description: 'Automatically detect running PostgreSQL instances',
        fieldType: MCPFieldType.serviceDetection,
        options: {
          'serviceType': ServiceType.postgresql,
        },
      ),
      MCPFieldDefinition(
        id: 'connection',
        label: 'Database Connection',
        description: 'Configure your PostgreSQL connection',
        required: true,
        fieldType: MCPFieldType.database,
        options: {
          'dbType': 'postgresql',
          'showAdvanced': true,
        },
      ),
    ],
    prerequisites: ['PostgreSQL server running'],
    capabilities: ['Query execution', 'Schema inspection', 'Data manipulation', 'Transaction support'],
  );

  // ==================== MICROSOFT 365 SUITE ====================
  
  static const microsoftGraph = EnhancedMCPTemplate(
    id: 'microsoft-graph',
    name: 'Microsoft 365',
    description: 'Unified access to Microsoft 365 services',
    icon: Icons.business,
    category: 'Enterprise',
    difficulty: 'Hard',
    tags: ['microsoft', 'office365', 'enterprise', 'oauth'],
    brandColor: Color(0xFF0078D4),
    command: 'uvx',
    args: ['@modelcontextprotocol/server-microsoft-graph'],
    fields: [
      MCPFieldDefinition(
        id: 'auth',
        label: 'Microsoft Authentication',
        description: 'Connect your Microsoft 365 account',
        required: true,
        fieldType: MCPFieldType.oauth,
        options: {
          'provider': OAuthProvider.microsoft,
        },
      ),
      MCPFieldDefinition(
        id: 'scopes',
        label: 'Service Permissions',
        description: 'Choose which Microsoft 365 services to access',
        fieldType: MCPFieldType.permissionScope,
        options: {
          'provider': OAuthProvider.microsoft,
        },
      ),
    ],
    setupInstructions: [
      SetupInstruction(
        step: 1,
        title: 'Azure App Registration',
        description: 'Register your application in Azure Active Directory',
        actionUrl: 'https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationsListBlade',
        actionText: 'Open Azure Portal',
      ),
      SetupInstruction(
        step: 2,
        title: 'Configure OAuth',
        description: 'Set up OAuth 2.0 authentication flow',
      ),
    ],
    capabilities: ['OneDrive', 'Outlook', 'Teams', 'SharePoint', 'Calendar'],
    prerequisites: ['Microsoft 365 account', 'Azure AD permissions'],
  );

  // ==================== AI/ML SERVICES ====================
  
  static const openai = EnhancedMCPTemplate(
    id: 'openai',
    name: 'OpenAI',
    description: 'OpenAI API integration for GPT models',
    icon: Icons.smart_toy,
    category: 'AI',
    difficulty: 'Easy',
    tags: ['openai', 'gpt', 'ai', 'api'],
    command: 'uvx',
    args: ['@modelcontextprotocol/server-openai'],
    fields: [
      MCPFieldDefinition(
        id: 'apiKey',
        label: 'OpenAI API Key',
        description: 'Your OpenAI API key for authentication',
        required: true,
        fieldType: MCPFieldType.apiToken,
        options: {
          'tokenFormat': 'openai_key',
          'showValidation': true,
        },
      ),
      MCPFieldDefinition(
        id: 'model',
        label: 'Default Model',
        description: 'Choose your preferred GPT model',
        fieldType: MCPFieldType.select,
        options: {
          'options': [
            SelectOption(value: 'gpt-4', label: 'GPT-4', badge: 'Recommended'),
            SelectOption(value: 'gpt-4-turbo', label: 'GPT-4 Turbo', badge: 'Fast'),
            SelectOption(value: 'gpt-3.5-turbo', label: 'GPT-3.5 Turbo', badge: 'Affordable'),
          ],
        },
        defaultValue: 'gpt-4',
      ),
    ],
    setupInstructions: [
      SetupInstruction(
        step: 1,
        title: 'Get API Key',
        description: 'Sign up for OpenAI and generate an API key',
        actionUrl: 'https://platform.openai.com/api-keys',
        actionText: 'Get API Key',
      ),
    ],
    capabilities: ['Text generation', 'Chat completion', 'Function calling', 'Embeddings'],
    isPopular: true,
  );

  // ==================== MISSING TEMPLATES ====================

  static const memory = EnhancedMCPTemplate(
    id: 'memory',
    name: 'Memory',
    description: 'Persistent memory and knowledge base management for AI agents',
    icon: Icons.psychology,
    category: 'AI',
    difficulty: 'Medium',
    tags: ['memory', 'knowledge', 'persistence', 'ai'],
    command: 'uvx',
    args: ['@modelcontextprotocol/server-memory'],
    fields: [
      MCPFieldDefinition(
        id: 'storageType',
        label: 'Storage Type',
        description: 'Choose how memory is stored',
        required: true,
        fieldType: MCPFieldType.select,
        options: {
          'options': ['local', 'cloud', 'hybrid'],
          'labels': ['Local Files', 'Cloud Storage', 'Hybrid'],
        },
        defaultValue: 'local',
      ),
      MCPFieldDefinition(
        id: 'maxMemorySize',
        label: 'Max Memory Size (MB)',
        description: 'Maximum memory storage size',
        fieldType: MCPFieldType.number,
        defaultValue: 100,
      ),
    ],
    capabilities: ['Long-term memory', 'Context persistence', 'Knowledge synthesis'],
    isRecommended: true,
  );

  static const webSearch = EnhancedMCPTemplate(
    id: 'web-search',
    name: 'Web Search',
    description: 'Web search and information retrieval',
    icon: Icons.search,
    category: 'Cloud',
    difficulty: 'Easy',
    tags: ['search', 'web', 'information', 'research'],
    command: 'uvx',
    args: ['@modelcontextprotocol/server-brave-search'],
    fields: [
      MCPFieldDefinition(
        id: 'apiKey',
        label: 'Brave Search API Key',
        description: 'Your Brave Search API key',
        required: true,
        fieldType: MCPFieldType.apiToken,
        placeholder: 'BSA...',
      ),
      MCPFieldDefinition(
        id: 'maxResults',
        label: 'Max Results',
        description: 'Maximum search results per query',
        fieldType: MCPFieldType.number,
        defaultValue: 10,
      ),
    ],
    setupInstructions: [
      SetupInstruction(
        step: 1,
        title: 'Get Brave Search API Key',
        description: 'Sign up for Brave Search API and get your API key',
        actionUrl: 'https://brave.com/search/api/',
        actionText: 'Get API Key',
      ),
    ],
    capabilities: ['Web search', 'Real-time information', 'News search', 'Image search'],
    isPopular: true,
  );

  static const terminal = EnhancedMCPTemplate(
    id: 'terminal',
    name: 'Terminal',
    description: 'Execute shell commands and terminal operations',
    icon: Icons.terminal,
    category: 'Local',
    difficulty: 'Hard',
    tags: ['terminal', 'shell', 'commands'],
    command: 'uvx',
    args: ['@modelcontextprotocol/server-shell'],
    fields: [
      MCPFieldDefinition(
        id: 'workingDirectory',
        label: 'Working Directory',
        description: 'Default directory for command execution',
        fieldType: MCPFieldType.directory,
      ),
      MCPFieldDefinition(
        id: 'allowDangerous',
        label: 'Allow Dangerous Commands',
        description: 'Allow potentially destructive commands (use with caution)',
        fieldType: MCPFieldType.boolean,
        defaultValue: false,
      ),
      MCPFieldDefinition(
        id: 'timeoutSeconds',
        label: 'Command Timeout (seconds)',
        description: 'Maximum time to wait for command execution',
        fieldType: MCPFieldType.number,
        defaultValue: 30,
      ),
    ],
    capabilities: ['Command execution', 'Environment access', 'Process management'],
    prerequisites: ['System shell access'],
  );

  static const httpClient = EnhancedMCPTemplate(
    id: 'http-client',
    name: 'HTTP Client',
    description: 'HTTP requests and API integration',
    icon: Icons.http,
    category: 'Development',
    difficulty: 'Medium',
    tags: ['http', 'api', 'requests', 'client'],
    command: 'uvx',
    args: ['@modelcontextprotocol/server-fetch'],
    fields: [
      MCPFieldDefinition(
        id: 'defaultHeaders',
        label: 'Default Headers',
        description: 'JSON object with default HTTP headers',
        fieldType: MCPFieldType.text,
        placeholder: '{"User-Agent": "MyApp/1.0"}',
      ),
      MCPFieldDefinition(
        id: 'timeoutMs',
        label: 'Request Timeout (ms)',
        description: 'Default timeout for HTTP requests',
        fieldType: MCPFieldType.number,
        defaultValue: 10000,
      ),
    ],
    capabilities: ['HTTP requests', 'API integration', 'Data fetching', 'Webhook handling'],
  );

  static const calendar = EnhancedMCPTemplate(
    id: 'calendar',
    name: 'Calendar',
    description: 'Calendar and scheduling operations',
    icon: Icons.calendar_today,
    category: 'Cloud',
    difficulty: 'Medium',
    tags: ['calendar', 'scheduling', 'events', 'time'],
    command: 'uvx',
    args: ['@modelcontextprotocol/server-calendar'],
    fields: [
      MCPFieldDefinition(
        id: 'provider',
        label: 'Calendar Provider',
        description: 'Choose your calendar service',
        required: true,
        fieldType: MCPFieldType.select,
        options: {
          'options': ['google', 'outlook', 'apple'],
          'labels': ['Google Calendar', 'Outlook Calendar', 'Apple Calendar'],
        },
      ),
      MCPFieldDefinition(
        id: 'accessToken',
        label: 'Access Token',
        description: 'OAuth token for calendar access',
        required: true,
        fieldType: MCPFieldType.oauth,
      ),
    ],
    capabilities: ['Event management', 'Scheduling', 'Reminders', 'Availability'],
  );

  static const slack = EnhancedMCPTemplate(
    id: 'slack',
    name: 'Slack',
    description: 'Team communication and notifications',
    icon: Icons.chat,
    category: 'Communication',
    difficulty: 'Medium',
    tags: ['slack', 'communication', 'team', 'notifications'],
    command: 'uvx',
    args: ['@modelcontextprotocol/server-slack'],
    fields: [
      MCPFieldDefinition(
        id: 'botToken',
        label: 'Bot Token',
        description: 'Slack Bot User OAuth Token',
        required: true,
        fieldType: MCPFieldType.apiToken,
        placeholder: 'xoxb-...',
      ),
      MCPFieldDefinition(
        id: 'workspace',
        label: 'Workspace',
        description: 'Slack workspace URL',
        required: true,
        fieldType: MCPFieldType.url,
        placeholder: 'https://your-workspace.slack.com',
      ),
    ],
    setupInstructions: [
      SetupInstruction(
        step: 1,
        title: 'Create Slack App',
        description: 'Create a new Slack app in your workspace',
        actionUrl: 'https://api.slack.com/apps',
        actionText: 'Create App',
      ),
      SetupInstruction(
        step: 2,
        title: 'Add Bot Token Scopes',
        description: 'Add necessary bot token scopes like chat:write, channels:read',
      ),
    ],
    capabilities: ['Send messages', 'Channel management', 'File sharing', 'Notifications'],
  );

  static const notion = EnhancedMCPTemplate(
    id: 'notion',
    name: 'Notion',
    description: 'Documentation and knowledge management',
    icon: Icons.note,
    category: 'Cloud',
    difficulty: 'Medium',
    tags: ['notion', 'documentation', 'knowledge', 'productivity'],
    command: 'uvx',
    args: ['@modelcontextprotocol/server-notion'],
    fields: [
      MCPFieldDefinition(
        id: 'integrationToken',
        label: 'Integration Token',
        description: 'Notion integration secret token',
        required: true,
        fieldType: MCPFieldType.apiToken,
        placeholder: 'secret_...',
      ),
      MCPFieldDefinition(
        id: 'databaseId',
        label: 'Default Database ID',
        description: 'ID of the default database to use',
        fieldType: MCPFieldType.text,
      ),
    ],
    setupInstructions: [
      SetupInstruction(
        step: 1,
        title: 'Create Integration',
        description: 'Create a new integration in your Notion workspace',
        actionUrl: 'https://developers.notion.com/docs/create-a-notion-integration',
        actionText: 'Create Integration',
      ),
    ],
    capabilities: ['Page management', 'Database queries', 'Content creation', 'Search'],
    isPopular: true,
  );

  static const linearApp = EnhancedMCPTemplate(
    id: 'linear',
    name: 'Linear',
    description: 'Issue tracking and project management',
    icon: Icons.linear_scale,
    category: 'Cloud',
    difficulty: 'Medium',
    tags: ['linear', 'project-management', 'issues', 'tracking'],
    command: 'uvx',
    args: ['@modelcontextprotocol/server-linear'],
    fields: [
      MCPFieldDefinition(
        id: 'apiKey',
        label: 'API Key',
        description: 'Linear personal API key',
        required: true,
        fieldType: MCPFieldType.apiToken,
        placeholder: 'lin_api_...',
      ),
      MCPFieldDefinition(
        id: 'teamId',
        label: 'Team ID',
        description: 'ID of the team to work with',
        fieldType: MCPFieldType.text,
      ),
    ],
    setupInstructions: [
      SetupInstruction(
        step: 1,
        title: 'Generate API Key',
        description: 'Generate a personal API key in Linear settings',
        actionUrl: 'https://linear.app/settings/api',
        actionText: 'Generate Key',
      ),
    ],
    capabilities: ['Issue management', 'Project tracking', 'Team coordination', 'Reporting'],
  );

  static const time = EnhancedMCPTemplate(
    id: 'time',
    name: 'Time',
    description: 'Time and timezone operations',
    icon: Icons.access_time,
    category: 'Development',
    difficulty: 'Easy',
    tags: ['time', 'timezone', 'scheduling', 'temporal'],
    command: 'uvx',
    args: ['@modelcontextprotocol/server-time'],
    fields: [
      MCPFieldDefinition(
        id: 'defaultTimezone',
        label: 'Default Timezone',
        description: 'Default timezone for operations',
        fieldType: MCPFieldType.text,
        defaultValue: 'UTC',
        placeholder: 'America/New_York',
      ),
    ],
    capabilities: ['Time conversion', 'Timezone handling', 'Scheduling', 'Temporal operations'],
  );

  static const sequentialThinking = EnhancedMCPTemplate(
    id: 'sequential-thinking',
    name: 'Sequential Thinking',
    description: 'Dynamic problem-solving through thought sequences',
    icon: Icons.auto_awesome,
    category: 'AI',
    difficulty: 'Hard',
    tags: ['thinking', 'reasoning', 'problem-solving', 'ai'],
    command: 'uvx',
    args: ['@modelcontextprotocol/server-sequential-thinking'],
    fields: [
      MCPFieldDefinition(
        id: 'maxSteps',
        label: 'Max Thinking Steps',
        description: 'Maximum number of reasoning steps',
        fieldType: MCPFieldType.number,
        defaultValue: 10,
      ),
      MCPFieldDefinition(
        id: 'enableLogging',
        label: 'Enable Logging',
        description: 'Log thinking process for debugging',
        fieldType: MCPFieldType.boolean,
        defaultValue: false,
      ),
    ],
    capabilities: ['Structured reasoning', 'Problem decomposition', 'Thought chains'],
  );

  // Template registry
  static List<EnhancedMCPTemplate> get allTemplates => [
    // Local
    filesystem,
    git,
    terminal,
    
    // Cloud APIs
    github,
    figma,
    slack,
    notion,
    linearApp,
    webSearch,
    calendar,
    
    // Databases
    postgresql,
    
    // AI/ML
    memory,
    sequentialThinking,
    
    // Utilities
    httpClient,
    time,
    
    // Enterprise/Other
    microsoftGraph,
    openai,
  ];

  static List<EnhancedMCPTemplate> getByCategory(String category) {
    return allTemplates.where((t) => t.category == category).toList();
  }

  static List<EnhancedMCPTemplate> getPopular() {
    return allTemplates.where((t) => t.isPopular).toList();
  }

  static List<EnhancedMCPTemplate> getRecommended() {
    return allTemplates.where((t) => t.isRecommended).toList();
  }

  static List<EnhancedMCPTemplate> getByDifficulty(String difficulty) {
    return allTemplates.where((t) => t.difficulty == difficulty).toList();
  }

  static List<EnhancedMCPTemplate> searchByTags(List<String> tags) {
    return allTemplates.where((template) {
      return tags.any((tag) => template.tags.contains(tag.toLowerCase()));
    }).toList();
  }
}

/// Template categories for organization
class TemplateCategories {
  static const String local = 'Local';
  static const String cloud = 'Cloud';
  static const String database = 'Database';
  static const String development = 'Development';
  static const String enterprise = 'Enterprise';
  static const String ai = 'AI';
  static const String design = 'Design';
  static const String communication = 'Communication';

  static List<String> get all => [
    local,
    cloud,
    database,
    development,
    enterprise,
    ai,
    design,
    communication,
  ];
}