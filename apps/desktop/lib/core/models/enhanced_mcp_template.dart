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

  // Template registry
  static List<EnhancedMCPTemplate> get allTemplates => [
    filesystem,
    git,
    github,
    figma,
    postgresql,
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