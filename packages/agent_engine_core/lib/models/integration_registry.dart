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
      // Official MCP Servers - Cloud APIs
      github,
      figma,
      slack,
      notion,
      googleDrive,
      linearApp,
      stripe,
      supabase,
      bigquery,
      cloudflare,
      vercel,
      netlify,
      azure,
      awsBedrock,
      awsCdk,
      awsCostAnalysis,
      twilio,
      discord,
      zapier,
      box,
      buildable,
      glean,
      atlassianRemote,
      boostSpace,
      caldav,
    ],
    IntegrationCategory.databases: [
      postgresql,
      mysql,
      mongodb,
      redis,
      clickhouse,
      tako,
      supadata,
    ],
    IntegrationCategory.utilities: [
      webSearch,
      httpClient,
      calendar,
      time,
      sequentialThinking,
      everything,
      fetch,
      puppeteer,
    ],
    IntegrationCategory.devops: [
      docker,
      kubernetes,
      gitguardian,
      sentry,
      circleci,
      buildkite,
      gremlin,
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
  devops('DevOps & CI/CD'),
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

// ADDITIONAL OFFICIAL MCP SERVERS

// Everything Server - Reference implementation
const everything = IntegrationDefinition(
  id: 'everything',
  name: 'Everything',
  description: 'Reference MCP server with prompts, resources, and tools',
  icon: Icons.apps,
  category: IntegrationCategory.utilities,
  difficulty: 'Easy',
  tags: ['reference', 'testing', 'development'],
  command: 'uvx',
  args: ['@modelcontextprotocol/server-everything'],
  capabilities: ['Testing', 'Development', 'Reference implementation'],
  isAvailable: true,
  isRecommended: false,
);

// Fetch Server - Web content fetching
const fetch = IntegrationDefinition(
  id: 'fetch',
  name: 'Fetch',
  description: 'Web content fetching and conversion for efficient LLM usage',
  icon: Icons.public,
  category: IntegrationCategory.utilities,
  difficulty: 'Medium',
  tags: ['web', 'fetching', 'content', 'scraping'],
  command: 'uvx',
  args: ['@modelcontextprotocol/server-fetch'],
  capabilities: ['Web scraping', 'Content extraction', 'URL fetching'],
  isAvailable: true,
  isPopular: true,
);

// Puppeteer Server - Browser automation
const puppeteer = IntegrationDefinition(
  id: 'puppeteer',
  name: 'Puppeteer',
  description: 'Browser automation and web scraping with Puppeteer',
  icon: Icons.web,
  category: IntegrationCategory.utilities,
  difficulty: 'Hard',
  tags: ['puppeteer', 'browser', 'automation', 'scraping'],
  command: 'uvx',
  args: ['@modelcontextprotocol/server-puppeteer'],
  capabilities: ['Browser automation', 'Web scraping', 'PDF generation', 'Screenshots'],
  prerequisites: ['Chrome/Chromium installed'],
  isAvailable: true,
);

// CLOUD SERVICES

// Stripe - Payment processing
const stripe = IntegrationDefinition(
  id: 'stripe',
  name: 'Stripe',
  description: 'Payment processing and financial data management',
  icon: Icons.payment,
  category: IntegrationCategory.cloudAPIs,
  difficulty: 'Medium',
  tags: ['stripe', 'payments', 'finance', 'billing'],
  brandColor: Color(0xFF635BFF),
  command: 'uvx',
  args: ['@modelcontextprotocol/server-stripe'],
  configFields: [
    IntegrationField(
      id: 'apiKey',
      label: 'Stripe API Key',
      description: 'Your Stripe secret API key',
      required: true,
      fieldType: IntegrationFieldType.apiToken,
    ),
  ],
  capabilities: ['Payment processing', 'Customer management', 'Subscription handling', 'Analytics'],
  documentationUrl: 'https://stripe.com/docs/api',
  isAvailable: true,
  isPopular: true,
);

// Supabase - Backend as a Service
const supabase = IntegrationDefinition(
  id: 'supabase',
  name: 'Supabase',
  description: 'Backend as a Service with database and auth',
  icon: Icons.cloud_sync,
  category: IntegrationCategory.cloudAPIs,
  difficulty: 'Medium',
  tags: ['supabase', 'backend', 'database', 'auth'],
  brandColor: Color(0xFF3ECF8E),
  command: 'uvx',
  args: ['@modelcontextprotocol/server-supabase'],
  configFields: [
    IntegrationField(
      id: 'url',
      label: 'Project URL',
      description: 'Your Supabase project URL',
      required: true,
      fieldType: IntegrationFieldType.url,
    ),
    IntegrationField(
      id: 'serviceKey',
      label: 'Service Key',
      description: 'Supabase service role key',
      required: true,
      fieldType: IntegrationFieldType.apiToken,
    ),
  ],
  capabilities: ['Database operations', 'Authentication', 'Storage', 'Real-time subscriptions'],
  documentationUrl: 'https://supabase.com/docs',
  isAvailable: true,
);

// BigQuery - Data warehouse
const bigquery = IntegrationDefinition(
  id: 'bigquery',
  name: 'BigQuery',
  description: 'Google Cloud BigQuery data warehouse and analytics',
  icon: Icons.analytics,
  category: IntegrationCategory.databases,
  difficulty: 'Hard',
  tags: ['bigquery', 'google-cloud', 'data-warehouse', 'analytics'],
  brandColor: Color(0xFF4285F4),
  command: 'uvx',
  args: ['@modelcontextprotocol/server-bigquery'],
  configFields: [
    IntegrationField(
      id: 'credentials',
      label: 'Service Account Credentials',
      description: 'Google Cloud service account JSON',
      required: true,
      fieldType: IntegrationFieldType.file,
    ),
    IntegrationField(
      id: 'projectId',
      label: 'Project ID',
      description: 'Google Cloud project ID',
      required: true,
      fieldType: IntegrationFieldType.text,
    ),
  ],
  capabilities: ['SQL queries', 'Data analysis', 'Machine learning', 'Data export'],
  prerequisites: ['Google Cloud account', 'BigQuery API enabled'],
  isAvailable: true,
);

// AWS Services
const awsBedrock = IntegrationDefinition(
  id: 'aws-bedrock',
  name: 'AWS Bedrock',
  description: 'AWS Bedrock foundation models and AI services',
  icon: Icons.cloud,
  category: IntegrationCategory.cloudAPIs,
  difficulty: 'Hard',
  tags: ['aws', 'bedrock', 'ai', 'ml'],
  brandColor: Color(0xFFFF9900),
  command: 'uvx',
  args: ['@modelcontextprotocol/server-aws-bedrock'],
  configFields: [
    IntegrationField(
      id: 'accessKeyId',
      label: 'AWS Access Key ID',
      required: true,
      fieldType: IntegrationFieldType.apiToken,
    ),
    IntegrationField(
      id: 'secretAccessKey',
      label: 'AWS Secret Access Key',
      required: true,
      fieldType: IntegrationFieldType.password,
    ),
    IntegrationField(
      id: 'region',
      label: 'AWS Region',
      required: true,
      fieldType: IntegrationFieldType.select,
      options: {
        'options': ['us-east-1', 'us-west-2', 'eu-west-1'],
      },
      defaultValue: 'us-east-1',
    ),
  ],
  capabilities: ['Foundation models', 'Text generation', 'Image generation', 'Model fine-tuning'],
  prerequisites: ['AWS account', 'Bedrock access'],
  isAvailable: true,
);

const awsCdk = IntegrationDefinition(
  id: 'aws-cdk',
  name: 'AWS CDK',
  description: 'AWS Cloud Development Kit for infrastructure as code',
  icon: Icons.architecture,
  category: IntegrationCategory.devops,
  difficulty: 'Hard',
  tags: ['aws', 'cdk', 'infrastructure', 'iac'],
  brandColor: Color(0xFFFF9900),
  command: 'uvx',
  args: ['@modelcontextprotocol/server-aws-cdk'],
  capabilities: ['Infrastructure deployment', 'Cloud formation', 'Resource management'],
  prerequisites: ['AWS CLI', 'CDK installed'],
  isAvailable: true,
);

const awsCostAnalysis = IntegrationDefinition(
  id: 'aws-cost-analysis',
  name: 'AWS Cost Analysis',
  description: 'AWS cost optimization and billing analysis',
  icon: Icons.monetization_on,
  category: IntegrationCategory.cloudAPIs,
  difficulty: 'Medium',
  tags: ['aws', 'cost', 'billing', 'optimization'],
  brandColor: Color(0xFFFF9900),
  command: 'uvx',
  args: ['@modelcontextprotocol/server-aws-cost-analysis'],
  capabilities: ['Cost analysis', 'Budget tracking', 'Spend optimization'],
  isAvailable: true,
);

// Other Cloud Services
const cloudflare = IntegrationDefinition(
  id: 'cloudflare',
  name: 'Cloudflare',
  description: 'Cloudflare CDN and security services',
  icon: Icons.security,
  category: IntegrationCategory.cloudAPIs,
  difficulty: 'Medium',
  tags: ['cloudflare', 'cdn', 'security', 'performance'],
  brandColor: Color(0xFFF38020),
  command: 'uvx',
  args: ['@modelcontextprotocol/server-cloudflare'],
  configFields: [
    IntegrationField(
      id: 'apiToken',
      label: 'API Token',
      required: true,
      fieldType: IntegrationFieldType.apiToken,
    ),
  ],
  capabilities: ['DNS management', 'Cache control', 'Security rules', 'Analytics'],
  isAvailable: true,
);

const vercel = IntegrationDefinition(
  id: 'vercel',
  name: 'Vercel',
  description: 'Vercel deployment and hosting platform',
  icon: Icons.rocket_launch,
  category: IntegrationCategory.cloudAPIs,
  difficulty: 'Medium',
  tags: ['vercel', 'deployment', 'hosting', 'frontend'],
  brandColor: Colors.black,
  command: 'uvx',
  args: ['@modelcontextprotocol/server-vercel'],
  capabilities: ['Deployment management', 'Domain configuration', 'Analytics'],
  isAvailable: true,
);

const netlify = IntegrationDefinition(
  id: 'netlify',
  name: 'Netlify',
  description: 'Netlify hosting and deployment platform',
  icon: Icons.web_asset,
  category: IntegrationCategory.cloudAPIs,
  difficulty: 'Medium',
  tags: ['netlify', 'hosting', 'deployment', 'jamstack'],
  brandColor: Color(0xFF00C7B7),
  command: 'uvx',
  args: ['@modelcontextprotocol/server-netlify'],
  capabilities: ['Site deployment', 'Form handling', 'Function management'],
  isAvailable: true,
);

const azure = IntegrationDefinition(
  id: 'azure',
  name: 'Microsoft Azure',
  description: 'Microsoft Azure cloud platform integration',
  icon: Icons.cloud,
  category: IntegrationCategory.cloudAPIs,
  difficulty: 'Hard',
  tags: ['azure', 'microsoft', 'cloud', 'enterprise'],
  brandColor: Color(0xFF0078D4),
  command: 'uvx',
  args: ['@modelcontextprotocol/server-azure'],
  capabilities: ['Resource management', 'Virtual machines', 'Storage', 'Networking'],
  isAvailable: true,
);

// Communication & Productivity
const twilio = IntegrationDefinition(
  id: 'twilio',
  name: 'Twilio',
  description: 'SMS, voice, and communication APIs',
  icon: Icons.message,
  category: IntegrationCategory.cloudAPIs,
  difficulty: 'Medium',
  tags: ['twilio', 'sms', 'voice', 'communication'],
  brandColor: Color(0xFFF22F46),
  command: 'uvx',
  args: ['@modelcontextprotocol/server-twilio'],
  configFields: [
    IntegrationField(
      id: 'accountSid',
      label: 'Account SID',
      required: true,
      fieldType: IntegrationFieldType.text,
    ),
    IntegrationField(
      id: 'authToken',
      label: 'Auth Token',
      required: true,
      fieldType: IntegrationFieldType.password,
    ),
  ],
  capabilities: ['SMS messaging', 'Voice calls', 'Video calls', 'Chat'],
  isAvailable: true,
);

const discord = IntegrationDefinition(
  id: 'discord',
  name: 'Discord',
  description: 'Discord bot and community management',
  icon: Icons.forum,
  category: IntegrationCategory.cloudAPIs,
  difficulty: 'Medium',
  tags: ['discord', 'community', 'bot', 'gaming'],
  brandColor: Color(0xFF5865F2),
  command: 'uvx',
  args: ['@modelcontextprotocol/server-discord'],
  configFields: [
    IntegrationField(
      id: 'botToken',
      label: 'Bot Token',
      required: true,
      fieldType: IntegrationFieldType.apiToken,
    ),
  ],
  capabilities: ['Message sending', 'Server management', 'User interaction', 'Moderation'],
  isAvailable: true,
);

// Automation & Integration
const zapier = IntegrationDefinition(
  id: 'zapier',
  name: 'Zapier',
  description: 'Workflow automation and app integration',
  icon: Icons.auto_fix_high,
  category: IntegrationCategory.cloudAPIs,
  difficulty: 'Medium',
  tags: ['zapier', 'automation', 'workflow', 'integration'],
  brandColor: Color(0xFFFF4A00),
  command: 'uvx',
  args: ['@modelcontextprotocol/server-zapier'],
  capabilities: ['Workflow automation', 'App integration', 'Trigger management'],
  isAvailable: true,
);

// Storage & Data
const box = IntegrationDefinition(
  id: 'box',
  name: 'Box',
  description: 'Box cloud storage and collaboration',
  icon: Icons.folder_shared,
  category: IntegrationCategory.cloudAPIs,
  difficulty: 'Medium',
  tags: ['box', 'storage', 'collaboration', 'enterprise'],
  brandColor: Color(0xFF0061D5),
  command: 'uvx',
  args: ['@modelcontextprotocol/server-box'],
  capabilities: ['File management', 'Collaboration', 'Content management'],
  isAvailable: true,
);

// DevOps Tools
const docker = IntegrationDefinition(
  id: 'docker',
  name: 'Docker',
  description: 'Container management and deployment',
  icon: Icons.developer_board,
  category: IntegrationCategory.devops,
  difficulty: 'Hard',
  tags: ['docker', 'containers', 'deployment', 'devops'],
  brandColor: Color(0xFF2496ED),
  command: 'uvx',
  args: ['@modelcontextprotocol/server-docker'],
  capabilities: ['Container management', 'Image building', 'Service orchestration'],
  prerequisites: ['Docker installed'],
  isAvailable: true,
);

const kubernetes = IntegrationDefinition(
  id: 'kubernetes',
  name: 'Kubernetes',
  description: 'Kubernetes cluster management and orchestration',
  icon: Icons.settings_applications,
  category: IntegrationCategory.devops,
  difficulty: 'Hard',
  tags: ['kubernetes', 'k8s', 'orchestration', 'containers'],
  brandColor: Color(0xFF326CE5),
  command: 'uvx',
  args: ['@modelcontextprotocol/server-kubernetes'],
  capabilities: ['Cluster management', 'Pod orchestration', 'Service discovery'],
  prerequisites: ['kubectl configured'],
  isAvailable: true,
);

// Security & Monitoring
const gitguardian = IntegrationDefinition(
  id: 'gitguardian',
  name: 'GitGuardian',
  description: 'Code security and secrets detection',
  icon: Icons.shield,
  category: IntegrationCategory.devops,
  difficulty: 'Medium',
  tags: ['security', 'secrets', 'scanning', 'compliance'],
  brandColor: Color(0xFF3B1F8B),
  command: 'uvx',
  args: ['@modelcontextprotocol/server-gitguardian'],
  capabilities: ['Secret detection', 'Security scanning', 'Compliance monitoring'],
  isAvailable: true,
);

const sentry = IntegrationDefinition(
  id: 'sentry',
  name: 'Sentry',
  description: 'Error tracking and performance monitoring',
  icon: Icons.bug_report,
  category: IntegrationCategory.devops,
  difficulty: 'Medium',
  tags: ['sentry', 'monitoring', 'errors', 'performance'],
  brandColor: Color(0xFF362D59),
  command: 'uvx',
  args: ['@modelcontextprotocol/server-sentry'],
  capabilities: ['Error tracking', 'Performance monitoring', 'Release tracking'],
  isAvailable: true,
);

// CI/CD
const circleci = IntegrationDefinition(
  id: 'circleci',
  name: 'CircleCI',
  description: 'Continuous integration and deployment',
  icon: Icons.loop,
  category: IntegrationCategory.devops,
  difficulty: 'Medium',
  tags: ['circleci', 'ci-cd', 'deployment', 'automation'],
  brandColor: Color(0xFF343434),
  command: 'uvx',
  args: ['@modelcontextprotocol/server-circleci'],
  capabilities: ['Build management', 'Deployment automation', 'Pipeline orchestration'],
  isAvailable: true,
);

const buildkite = IntegrationDefinition(
  id: 'buildkite',
  name: 'Buildkite',
  description: 'CI/CD platform for development teams',
  icon: Icons.build,
  category: IntegrationCategory.devops,
  difficulty: 'Medium',
  tags: ['buildkite', 'ci-cd', 'builds', 'deployment'],
  brandColor: Color(0xFF14CC80),
  command: 'uvx',
  args: ['@modelcontextprotocol/server-buildkite'],
  capabilities: ['Build automation', 'Pipeline management', 'Agent coordination'],
  isAvailable: true,
);

const gremlin = IntegrationDefinition(
  id: 'gremlin',
  name: 'Gremlin',
  description: 'Chaos engineering and reliability testing',
  icon: Icons.science,
  category: IntegrationCategory.devops,
  difficulty: 'Hard',
  tags: ['gremlin', 'chaos-engineering', 'reliability', 'testing'],
  brandColor: Color(0xFF5F259F),
  command: 'uvx',
  args: ['@modelcontextprotocol/server-gremlin'],
  capabilities: ['Chaos experiments', 'Reliability testing', 'Failure injection'],
  isAvailable: true,
);

// Additional Database Services
const redis = IntegrationDefinition(
  id: 'redis',
  name: 'Redis',
  description: 'In-memory data structure store and cache',
  icon: Icons.memory,
  category: IntegrationCategory.databases,
  difficulty: 'Medium',
  tags: ['redis', 'cache', 'memory', 'key-value'],
  brandColor: Color(0xFFDC382D),
  command: 'uvx',
  args: ['@modelcontextprotocol/server-redis'],
  configFields: [
    IntegrationField(
      id: 'host',
      label: 'Redis Host',
      required: true,
      fieldType: IntegrationFieldType.text,
      defaultValue: 'localhost',
    ),
    IntegrationField(
      id: 'port',
      label: 'Redis Port',
      required: true,
      fieldType: IntegrationFieldType.number,
      defaultValue: 6379,
    ),
    IntegrationField(
      id: 'password',
      label: 'Password',
      fieldType: IntegrationFieldType.password,
    ),
  ],
  capabilities: ['Caching', 'Session storage', 'Pub/Sub messaging', 'Data structures'],
  isAvailable: true,
);

const clickhouse = IntegrationDefinition(
  id: 'clickhouse',
  name: 'ClickHouse',
  description: 'Columnar database for analytics and big data',
  icon: Icons.analytics,
  category: IntegrationCategory.databases,
  difficulty: 'Hard',
  tags: ['clickhouse', 'analytics', 'columnar', 'big-data'],
  brandColor: Color(0xFFFFCC02),
  command: 'uvx',
  args: ['@modelcontextprotocol/server-clickhouse'],
  capabilities: ['Real-time analytics', 'Big data processing', 'Time-series data'],
  isAvailable: true,
);

// Specialized Services
const tako = IntegrationDefinition(
  id: 'tako',
  name: 'Tako',
  description: 'AI-powered data analysis and insights platform',
  icon: Icons.insights,
  category: IntegrationCategory.cloudAPIs,
  difficulty: 'Medium',
  tags: ['tako', 'ai', 'data-analysis', 'insights'],
  command: 'uvx',
  args: ['@modelcontextprotocol/server-tako'],
  capabilities: ['Data analysis', 'AI insights', 'Pattern recognition'],
  isAvailable: true,
);

const supadata = IntegrationDefinition(
  id: 'supadata',
  name: 'Supadata',
  description: 'Advanced data processing and analytics',
  icon: Icons.data_usage,
  category: IntegrationCategory.databases,
  difficulty: 'Hard',
  tags: ['supadata', 'data-processing', 'analytics'],
  command: 'uvx',
  args: ['@modelcontextprotocol/server-supadata'],
  capabilities: ['Data processing', 'Advanced analytics', 'Data pipelines'],
  isAvailable: true,
);

const buildable = IntegrationDefinition(
  id: 'buildable',
  name: 'Buildable',
  description: 'No-code workflow automation platform',
  icon: Icons.build_circle,
  category: IntegrationCategory.cloudAPIs,
  difficulty: 'Easy',
  tags: ['buildable', 'no-code', 'automation', 'workflows'],
  command: 'uvx',
  args: ['@modelcontextprotocol/server-buildable'],
  capabilities: ['Workflow automation', 'No-code development', 'API integration'],
  isAvailable: true,
);

const glean = IntegrationDefinition(
  id: 'glean',
  name: 'Glean',
  description: 'Enterprise search and knowledge management',
  icon: Icons.search,
  category: IntegrationCategory.cloudAPIs,
  difficulty: 'Medium',
  tags: ['glean', 'enterprise-search', 'knowledge', 'ai'],
  command: 'uvx',
  args: ['@modelcontextprotocol/server-glean'],
  capabilities: ['Enterprise search', 'Knowledge discovery', 'Content indexing'],
  isAvailable: true,
);

const atlassianRemote = IntegrationDefinition(
  id: 'atlassian-remote',
  name: 'Atlassian Remote',
  description: 'Atlassian Jira and Confluence remote integration',
  icon: Icons.work,
  category: IntegrationCategory.cloudAPIs,
  difficulty: 'Medium',
  tags: ['atlassian', 'jira', 'confluence', 'project-management'],
  brandColor: Color(0xFF0052CC),
  command: 'uvx',
  args: ['@modelcontextprotocol/server-atlassian-remote'],
  capabilities: ['Issue tracking', 'Project management', 'Documentation', 'Team collaboration'],
  isAvailable: true,
);

const boostSpace = IntegrationDefinition(
  id: 'boost-space',
  name: 'Boost.space',
  description: 'Integration platform and workflow automation',
  icon: Icons.hub,
  category: IntegrationCategory.cloudAPIs,
  difficulty: 'Medium',
  tags: ['boost-space', 'integration', 'automation', 'workflows'],
  command: 'uvx',
  args: ['@modelcontextprotocol/server-boost-space'],
  capabilities: ['Integration management', 'Workflow automation', 'Data transformation'],
  isAvailable: true,
);

const caldav = IntegrationDefinition(
  id: 'caldav',
  name: 'CalDAV',
  description: 'Calendar synchronization and management via CalDAV protocol',
  icon: Icons.calendar_today,
  category: IntegrationCategory.cloudAPIs,
  difficulty: 'Medium',
  tags: ['caldav', 'calendar', 'scheduling', 'synchronization'],
  command: 'uvx',
  args: ['@modelcontextprotocol/server-caldav'],
  configFields: [
    IntegrationField(
      id: 'serverUrl',
      label: 'CalDAV Server URL',
      required: true,
      fieldType: IntegrationFieldType.url,
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
  capabilities: ['Calendar synchronization', 'Event management', 'Scheduling'],
  isAvailable: true,
);