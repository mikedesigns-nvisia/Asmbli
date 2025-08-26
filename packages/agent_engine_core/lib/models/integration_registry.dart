import 'package:flutter/material.dart';

/// Unified integration registry that serves as single source of truth
/// for all available integrations across web and desktop platforms
class IntegrationRegistry {
  
  /// All available integrations organized by category
  static const Map<IntegrationCategory, List<IntegrationDefinition>> integrations = {
    IntegrationCategory.local: [
      filesystem,
      git,
      terminal,
      memory,
    ],
    IntegrationCategory.cloudAPIs: [
      github,
      figma,
      slack,
      notion,
      googleDrive,
      linearApp,
    ],
    IntegrationCategory.databases: [
      postgresql,
      mysql,
      mongodb,
    ],
    IntegrationCategory.utilities: [
      webSearch,
      httpClient,
      calendar,
      time,
      sequentialThinking,
    ],
    IntegrationCategory.aiML: [
      memory,
      sequentialThinking,
    ],
  };

  /// Get all integrations as a flat list
  static List<IntegrationDefinition> get allIntegrations {
    return integrations.values.expand((list) => list).toSet().toList();
  }

  /// Get integrations by category
  static List<IntegrationDefinition> getByCategory(IntegrationCategory category) {
    return integrations[category] ?? [];
  }

  /// Get integration by ID
  static IntegrationDefinition? getById(String id) {
    return allIntegrations.where((integration) => integration.id == id).firstOrNull;
  }

  /// Search integrations by name or description
  static List<IntegrationDefinition> search(String query) {
    final lowercaseQuery = query.toLowerCase();
    return allIntegrations.where((integration) =>
        integration.name.toLowerCase().contains(lowercaseQuery) ||
        integration.description.toLowerCase().contains(lowercaseQuery) ||
        integration.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery))
    ).toList();
  }
}

/// Integration categories for organization
enum IntegrationCategory {
  local('Local'),
  cloudAPIs('Cloud APIs'),
  databases('Databases'),
  utilities('Utilities'),
  aiML('AI/ML');

  const IntegrationCategory(this.displayName);
  final String displayName;
}

/// Unified integration definition
class IntegrationDefinition {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final IntegrationCategory category;
  final String difficulty; // 'Easy', 'Medium', 'Hard'
  final List<String> tags;
  final Color? brandColor;
  
  // MCP Server Configuration
  final String command;
  final List<String> args;
  final String? workingDirectory;
  
  // Field definitions for configuration
  final List<IntegrationField> configFields;
  
  // Prerequisites and setup
  final List<String> prerequisites;
  final List<String> capabilities;
  final String? documentationUrl;
  final bool isPopular;
  final bool isRecommended;
  final bool isAvailable; // Whether it's actually implemented

  const IntegrationDefinition({
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
    this.configFields = const [],
    this.prerequisites = const [],
    this.capabilities = const [],
    this.documentationUrl,
    this.isPopular = false,
    this.isRecommended = false,
    this.isAvailable = true,
  });
}

/// Configuration field for integrations
class IntegrationField {
  final String id;
  final String label;
  final String? description;
  final String? placeholder;
  final bool required;
  final IntegrationFieldType fieldType;
  final Map<String, dynamic> options;
  final dynamic defaultValue;

  const IntegrationField({
    required this.id,
    required this.label,
    this.description,
    this.placeholder,
    this.required = false,
    required this.fieldType,
    this.options = const {},
    this.defaultValue,
  });
}

/// Field types for integration configuration
enum IntegrationFieldType {
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
}

// ==================== INTEGRATION DEFINITIONS ====================

// LOCAL INTEGRATIONS
const filesystem = IntegrationDefinition(
  id: 'filesystem',
  name: 'Filesystem',
  description: 'Access local files and directories for reading and writing',
  icon: Icons.folder,
  category: IntegrationCategory.local,
  difficulty: 'Easy',
  tags: ['local', 'files', 'storage'],
  command: 'uvx',
  args: ['@modelcontextprotocol/server-filesystem'],
  configFields: [
    IntegrationField(
      id: 'rootPath',
      label: 'Root Directory',
      description: 'Choose the root directory for file access',
      required: true,
      fieldType: IntegrationFieldType.directory,
    ),
    IntegrationField(
      id: 'readOnly',
      label: 'Read-Only Mode',
      description: 'Restrict access to read-only operations for safety',
      fieldType: IntegrationFieldType.boolean,
      defaultValue: true,
    ),
  ],
  capabilities: ['Read files', 'Write files', 'List directories', 'File metadata'],
  isPopular: true,
  isAvailable: true,
);

const git = IntegrationDefinition(
  id: 'git',
  name: 'Git Repository',
  description: 'Git version control operations and repository management',
  icon: Icons.source,
  category: IntegrationCategory.local,
  difficulty: 'Medium',
  tags: ['git', 'version-control', 'development'],
  command: 'uvx',
  args: ['@modelcontextprotocol/server-git'],
  configFields: [
    IntegrationField(
      id: 'repositoryPath',
      label: 'Repository Path',
      description: 'Path to your Git repository',
      required: true,
      fieldType: IntegrationFieldType.directory,
    ),
  ],
  prerequisites: ['Git installed and configured'],
  capabilities: ['Read commits', 'Branch operations', 'File history', 'Diff generation'],
  isAvailable: true,
);

const terminal = IntegrationDefinition(
  id: 'terminal',
  name: 'Terminal',
  description: 'Execute shell commands and terminal operations',
  icon: Icons.terminal,
  category: IntegrationCategory.local,
  difficulty: 'Hard',
  tags: ['terminal', 'shell', 'commands'],
  command: 'uvx',
  args: ['@modelcontextprotocol/server-shell'],
  configFields: [
    IntegrationField(
      id: 'workingDirectory',
      label: 'Working Directory',
      description: 'Default directory for command execution',
      fieldType: IntegrationFieldType.directory,
    ),
    IntegrationField(
      id: 'allowDangerous',
      label: 'Allow Dangerous Commands',
      description: 'Allow potentially destructive commands (use with caution)',
      fieldType: IntegrationFieldType.boolean,
      defaultValue: false,
    ),
  ],
  capabilities: ['Command execution', 'Environment access', 'Process management'],
  prerequisites: ['System shell access'],
  isAvailable: true, // Terminal access implemented
);

const memory = IntegrationDefinition(
  id: 'memory',
  name: 'Memory',
  description: 'Persistent memory and knowledge base management for AI agents',
  icon: Icons.psychology,
  category: IntegrationCategory.aiML,
  difficulty: 'Medium',
  tags: ['memory', 'knowledge', 'persistence', 'ai'],
  brandColor: Colors.purple,
  command: 'uvx',
  args: ['@modelcontextprotocol/server-memory'],
  configFields: [
    IntegrationField(
      id: 'storageType',
      label: 'Storage Type',
      description: 'Choose how memory is stored',
      required: true,
      fieldType: IntegrationFieldType.select,
      options: {
        'options': ['local', 'cloud', 'hybrid'],
        'labels': ['Local Files', 'Cloud Storage', 'Hybrid'],
      },
      defaultValue: 'local',
    ),
  ],
  capabilities: ['Long-term memory', 'Context persistence', 'Knowledge synthesis'],
  isRecommended: true,
  isAvailable: true, // Memory system implemented
);

// CLOUD API INTEGRATIONS
const github = IntegrationDefinition(
  id: 'github',
  name: 'GitHub',
  description: 'GitHub repository access and management',
  icon: Icons.code,
  category: IntegrationCategory.cloudAPIs,
  difficulty: 'Medium',
  tags: ['github', 'git', 'cloud', 'api'],
  brandColor: Color(0xFF333333),
  command: 'uvx',
  args: ['@modelcontextprotocol/server-github'],
  configFields: [
    IntegrationField(
      id: 'token',
      label: 'GitHub Token',
      description: 'Your GitHub personal access token',
      required: true,
      fieldType: IntegrationFieldType.apiToken,
    ),
  ],
  capabilities: ['Repository access', 'Issues management', 'Pull requests', 'Code search'],
  documentationUrl: 'https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token',
  isPopular: true,
  isAvailable: true,
);

const figma = IntegrationDefinition(
  id: 'figma',
  name: 'Figma',
  description: 'Design file access and component management',
  icon: Icons.design_services,
  category: IntegrationCategory.cloudAPIs,
  difficulty: 'Medium',
  tags: ['figma', 'design', 'ui', 'components'],
  brandColor: Color(0xFFF24E1E),
  command: 'uvx',
  args: ['@modelcontextprotocol/server-figma'],
  configFields: [
    IntegrationField(
      id: 'accessToken',
      label: 'Figma Access Token',
      description: 'Your Figma personal access token',
      required: true,
      fieldType: IntegrationFieldType.apiToken,
    ),
  ],
  capabilities: ['File access', 'Component library', 'Design tokens', 'Asset export'],
  documentationUrl: 'https://www.figma.com/developers/api#access-tokens',
  isRecommended: true,
  isAvailable: true,
);

const slack = IntegrationDefinition(
  id: 'slack',
  name: 'Slack',
  description: 'Team communication and notifications',
  icon: Icons.chat,
  category: IntegrationCategory.cloudAPIs,
  difficulty: 'Medium',
  tags: ['slack', 'communication', 'team', 'notifications'],
  brandColor: Color(0xFF4A154B),
  command: 'uvx',
  args: ['@modelcontextprotocol/server-slack'],
  configFields: [
    IntegrationField(
      id: 'botToken',
      label: 'Bot Token',
      description: 'Slack Bot User OAuth Token',
      required: true,
      fieldType: IntegrationFieldType.apiToken,
    ),
    IntegrationField(
      id: 'workspace',
      label: 'Workspace',
      description: 'Slack workspace URL',
      required: true,
      fieldType: IntegrationFieldType.url,
      placeholder: 'https://your-workspace.slack.com',
    ),
  ],
  capabilities: ['Send messages', 'Channel management', 'File sharing', 'Notifications'],
  documentationUrl: 'https://api.slack.com/authentication/token-types#bot',
  isAvailable: false, // Not yet implemented
);

const notion = IntegrationDefinition(
  id: 'notion',
  name: 'Notion',
  description: 'Documentation and knowledge management',
  icon: Icons.note,
  category: IntegrationCategory.cloudAPIs,
  difficulty: 'Medium',
  tags: ['notion', 'documentation', 'knowledge', 'productivity'],
  brandColor: Colors.black87,
  command: 'uvx',
  args: ['@modelcontextprotocol/server-notion'],
  configFields: [
    IntegrationField(
      id: 'integrationToken',
      label: 'Integration Token',
      description: 'Notion integration secret token',
      required: true,
      fieldType: IntegrationFieldType.apiToken,
    ),
  ],
  capabilities: ['Page management', 'Database queries', 'Content creation', 'Search'],
  documentationUrl: 'https://developers.notion.com/docs/create-a-notion-integration',
  isPopular: true,
  isAvailable: false, // Not yet implemented
);

const googleDrive = IntegrationDefinition(
  id: 'google-drive',
  name: 'Google Drive',
  description: 'Cloud file storage and document management',
  icon: Icons.cloud,
  category: IntegrationCategory.cloudAPIs,
  difficulty: 'Hard',
  tags: ['google', 'drive', 'cloud', 'documents'],
  brandColor: Colors.blue,
  command: 'uvx',
  args: ['@modelcontextprotocol/server-google-drive'],
  configFields: [
    IntegrationField(
      id: 'credentials',
      label: 'Service Account Credentials',
      description: 'Google service account JSON credentials',
      required: true,
      fieldType: IntegrationFieldType.file,
    ),
  ],
  capabilities: ['File management', 'Document access', 'Sharing', 'Search'],
  documentationUrl: 'https://developers.google.com/drive/api/quickstart/python',
  isAvailable: false, // Not yet implemented
);

const linearApp = IntegrationDefinition(
  id: 'linear',
  name: 'Linear',
  description: 'Issue tracking and project management',
  icon: Icons.linear_scale,
  category: IntegrationCategory.cloudAPIs,
  difficulty: 'Medium',
  tags: ['linear', 'project-management', 'issues', 'tracking'],
  brandColor: Color(0xFF5E6AD2),
  command: 'uvx',
  args: ['@modelcontextprotocol/server-linear'],
  configFields: [
    IntegrationField(
      id: 'apiKey',
      label: 'API Key',
      description: 'Linear personal API key',
      required: true,
      fieldType: IntegrationFieldType.apiToken,
    ),
  ],
  capabilities: ['Issue management', 'Project tracking', 'Team coordination', 'Reporting'],
  documentationUrl: 'https://developers.linear.app/docs/graphql/working-with-the-graphql-api',
  isAvailable: false, // Not yet implemented
);

// DATABASE INTEGRATIONS
const postgresql = IntegrationDefinition(
  id: 'postgresql',
  name: 'PostgreSQL',
  description: 'PostgreSQL database access and management',
  icon: Icons.storage,
  category: IntegrationCategory.databases,
  difficulty: 'Medium',
  tags: ['postgresql', 'database', 'sql'],
  command: 'uvx',
  args: ['@modelcontextprotocol/server-postgres'],
  configFields: [
    IntegrationField(
      id: 'connectionString',
      label: 'Connection String',
      description: 'PostgreSQL connection string',
      required: true,
      fieldType: IntegrationFieldType.text,
      placeholder: 'postgresql://user:password@localhost:5432/database',
    ),
  ],
  capabilities: ['SQL queries', 'Schema operations', 'Data management', 'Transactions'],
  prerequisites: ['PostgreSQL server running'],
  isAvailable: true,
);

const mysql = IntegrationDefinition(
  id: 'mysql',
  name: 'MySQL',
  description: 'MySQL database access and management',
  icon: Icons.storage,
  category: IntegrationCategory.databases,
  difficulty: 'Medium',
  tags: ['mysql', 'database', 'sql'],
  command: 'uvx',
  args: ['@modelcontextprotocol/server-mysql'],
  configFields: [
    IntegrationField(
      id: 'host',
      label: 'Host',
      required: true,
      fieldType: IntegrationFieldType.text,
      defaultValue: 'localhost',
    ),
    IntegrationField(
      id: 'port',
      label: 'Port',
      required: true,
      fieldType: IntegrationFieldType.number,
      defaultValue: 3306,
    ),
    IntegrationField(
      id: 'database',
      label: 'Database Name',
      required: true,
      fieldType: IntegrationFieldType.text,
    ),
    IntegrationField(
      id: 'username',
      label: 'Username',
      required: true,
      fieldType: IntegrationFieldType.text,
    ),
    IntegrationField(
      id: 'password',
      label: 'Password',
      required: true,
      fieldType: IntegrationFieldType.password,
    ),
  ],
  capabilities: ['SQL queries', 'Schema operations', 'Data management', 'Transactions'],
  prerequisites: ['MySQL server running'],
  isAvailable: false, // Not yet implemented
);

const mongodb = IntegrationDefinition(
  id: 'mongodb',
  name: 'MongoDB',
  description: 'MongoDB document database access',
  icon: Icons.storage,
  category: IntegrationCategory.databases,
  difficulty: 'Medium',
  tags: ['mongodb', 'database', 'nosql', 'documents'],
  brandColor: Color(0xFF47A248),
  command: 'uvx',
  args: ['@modelcontextprotocol/server-mongodb'],
  configFields: [
    IntegrationField(
      id: 'connectionUri',
      label: 'Connection URI',
      description: 'MongoDB connection URI',
      required: true,
      fieldType: IntegrationFieldType.text,
      placeholder: 'mongodb://localhost:27017/database',
    ),
  ],
  capabilities: ['Document queries', 'Collection management', 'Aggregation', 'Indexing'],
  prerequisites: ['MongoDB server running'],
  isAvailable: false, // Not yet implemented
);

// UTILITY INTEGRATIONS
const webSearch = IntegrationDefinition(
  id: 'web-search',
  name: 'Web Search',
  description: 'Web search and information retrieval',
  icon: Icons.search,
  category: IntegrationCategory.utilities,
  difficulty: 'Easy',
  tags: ['search', 'web', 'information', 'research'],
  brandColor: Colors.green,
  command: 'uvx',
  args: ['@modelcontextprotocol/server-brave-search'],
  configFields: [
    IntegrationField(
      id: 'apiKey',
      label: 'Brave Search API Key',
      description: 'Your Brave Search API key',
      required: true,
      fieldType: IntegrationFieldType.apiToken,
    ),
  ],
  capabilities: ['Web search', 'Real-time information', 'News search', 'Image search'],
  documentationUrl: 'https://brave.com/search/api/',
  isPopular: true,
  isAvailable: true, // Web search implemented
);

const httpClient = IntegrationDefinition(
  id: 'http-client',
  name: 'HTTP Client',
  description: 'HTTP requests and API integration',
  icon: Icons.http,
  category: IntegrationCategory.utilities,
  difficulty: 'Medium',
  tags: ['http', 'api', 'requests', 'client'],
  command: 'uvx',
  args: ['@modelcontextprotocol/server-fetch'],
  capabilities: ['HTTP requests', 'API integration', 'Data fetching', 'Webhook handling'],
  isAvailable: true, // HTTP client implemented
);

const calendar = IntegrationDefinition(
  id: 'calendar',
  name: 'Calendar',
  description: 'Calendar and scheduling operations',
  icon: Icons.calendar_today,
  category: IntegrationCategory.utilities,
  difficulty: 'Medium',
  tags: ['calendar', 'scheduling', 'events', 'time'],
  brandColor: Colors.indigo,
  command: 'uvx',
  args: ['@modelcontextprotocol/server-calendar'],
  capabilities: ['Event management', 'Scheduling', 'Reminders', 'Availability'],
  isAvailable: false, // Not yet implemented
);

const time = IntegrationDefinition(
  id: 'time',
  name: 'Time',
  description: 'Time and timezone operations',
  icon: Icons.access_time,
  category: IntegrationCategory.utilities,
  difficulty: 'Easy',
  tags: ['time', 'timezone', 'scheduling', 'temporal'],
  brandColor: Colors.teal,
  command: 'uvx',
  args: ['@modelcontextprotocol/server-time'],
  capabilities: ['Time conversion', 'Timezone handling', 'Scheduling', 'Temporal operations'],
  isAvailable: true, // Time utilities implemented
);

const sequentialThinking = IntegrationDefinition(
  id: 'sequential-thinking',
  name: 'Sequential Thinking',
  description: 'Dynamic problem-solving through thought sequences',
  icon: Icons.auto_awesome,
  category: IntegrationCategory.aiML,
  difficulty: 'Hard',
  tags: ['thinking', 'reasoning', 'problem-solving', 'ai'],
  brandColor: Colors.deepPurple,
  command: 'uvx',
  args: ['@modelcontextprotocol/server-sequential-thinking'],
  capabilities: ['Structured reasoning', 'Problem decomposition', 'Thought chains'],
  isAvailable: true, // Sequential thinking implemented
);