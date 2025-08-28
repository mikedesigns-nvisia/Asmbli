// Core integration registry without UI dependencies

/// Unified integration registry that serves as single source of truth
/// for all available integrations across web and desktop platforms
class IntegrationRegistry {
  
  /// All available integration definitions
  static final Map<String, IntegrationDefinition> _definitions = _createIntegrationDefinitions();
  
  /// All available integration IDs organized by category
  static const Map<IntegrationCategory, List<String>> integrations = {
    IntegrationCategory.local: [
      'filesystem',
      'git', 
      'terminal',
      'memory',
    ],
    IntegrationCategory.cloudAPIs: [
      // Official MCP Servers - Cloud APIs
      'github',
      'figma',
      'slack',
      'notion',
      'google-drive',
      'linear',
      'stripe',
      'supabase',
      'bigquery',
      'cloudflare',
      'vercel',
      'netlify',
      'azure',
      'aws-bedrock',
      'aws-cdk',
      'aws-cost-analysis',
      'twilio',
      'discord',
      'zapier',
      'box',
      'buildable',
      'glean',
      'atlassian-remote',
      'boost-space',
      'caldav',
    ],
    IntegrationCategory.databases: [
      'postgresql',
      'mysql',
      'mongodb',
      'redis',
      'clickhouse',
      'tako',
      'supadata',
    ],
    IntegrationCategory.utilities: [
      'web-search',
      'http-client',
      'calendar',
      'time',
      'sequential-thinking',
      'everything',
      'fetch',
      'puppeteer',
    ],
    IntegrationCategory.devops: [
      'docker',
      'kubernetes',
      'gitguardian',
      'sentry',
      'circleci',
      'buildkite',
      'gremlin',
      'continue-dev',
    ],
    IntegrationCategory.aiML: [
      'memory',
      'sequential-thinking',
    ],
  };

  /// Get all integration IDs as a flat list
  static List<String> get allIntegrationIds {
    return integrations.values.expand((list) => list).toSet().toList();
  }

  /// Get integration IDs by category
  static List<String> getIdsByCategory(IntegrationCategory category) {
    return integrations[category] ?? [];
  }
  
  /// Get integration definitions by category
  static List<IntegrationDefinition> getByCategory(IntegrationCategory category) {
    final ids = integrations[category] ?? [];
    return ids.map((id) => _definitions[id]).where((def) => def != null).cast<IntegrationDefinition>().toList();
  }
  
  /// Get integration definition by ID
  static IntegrationDefinition? getById(String id) {
    return _definitions[id];
  }
  
  /// Get all integration definitions
  static List<IntegrationDefinition> get allIntegrations {
    return _definitions.values.toList();
  }

  /// Check if integration ID exists
  static bool hasIntegration(String id) {
    return allIntegrationIds.contains(id);
  }

  /// Search integration IDs by query
  static List<String> search(String query) {
    final lowercaseQuery = query.toLowerCase();
    return allIntegrationIds.where((id) => 
        id.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }
  
  /// Create integration definitions map
  static Map<String, IntegrationDefinition> _createIntegrationDefinitions() {
    // Basic definitions without Flutter dependencies
    // Platform-specific implementations can override these
    return {
      // Local integrations
      'filesystem': const IntegrationDefinition(
        id: 'filesystem',
        name: 'File System',
        description: 'Access and manipulate local files and directories',
        category: IntegrationCategory.local,
        difficulty: 'Easy',
        icon: null, // Will be set by platform-specific code
        command: 'uvx',
        args: ['@modelcontextprotocol/server-filesystem'],
        capabilities: ['Read files', 'Write files', 'List directories'],
      ),
      'git': const IntegrationDefinition(
        id: 'git',
        name: 'Git',
        description: 'Git version control integration',
        category: IntegrationCategory.local,
        difficulty: 'Easy', 
        icon: null,
        command: 'uvx',
        args: ['@modelcontextprotocol/server-git'],
        capabilities: ['Git status', 'Commit history', 'Branch management'],
      ),
      'terminal': const IntegrationDefinition(
        id: 'terminal',
        name: 'Terminal',
        description: 'Execute terminal commands and scripts',
        category: IntegrationCategory.local,
        difficulty: 'Medium',
        icon: null,
        command: 'uvx', 
        args: ['@modelcontextprotocol/server-terminal'],
        capabilities: ['Execute commands', 'Shell access', 'Script running'],
      ),
      'memory': const IntegrationDefinition(
        id: 'memory',
        name: 'Memory',
        description: 'Persistent memory for context and knowledge storage',
        category: IntegrationCategory.aiML,
        difficulty: 'Easy',
        icon: null,
        command: 'uvx',
        args: ['@modelcontextprotocol/server-memory'],
        capabilities: ['Store context', 'Retrieve memories', 'Knowledge management'],
      ),
      // Cloud APIs
      'github': const IntegrationDefinition(
        id: 'github',
        name: 'GitHub',
        description: 'GitHub API integration for repositories, issues, and pull requests',
        category: IntegrationCategory.cloudAPIs,
        difficulty: 'Easy',
        icon: null,
        command: 'uvx',
        args: ['@modelcontextprotocol/server-github'],
        capabilities: ['Repository access', 'Issue management', 'Pull requests'],
        configFields: [
          IntegrationField(
            id: 'token',
            label: 'GitHub Token',
            fieldType: IntegrationFieldType.apiToken,
            required: true,
          ),
        ],
      ),
      'figma': const IntegrationDefinition(
        id: 'figma',
        name: 'Figma',
        description: 'Figma design file access and manipulation',
        category: IntegrationCategory.cloudAPIs,
        difficulty: 'Medium',
        icon: null,
        command: 'uvx',
        args: ['@modelcontextprotocol/server-figma'],
        capabilities: ['Design file access', 'Component libraries', 'Asset export'],
        configFields: [
          IntegrationField(
            id: 'token',
            label: 'Figma Token',
            fieldType: IntegrationFieldType.apiToken,
            required: true,
          ),
        ],
      ),
      // Add more basic definitions as needed...
    };
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

/// Unified integration definition (lightweight for core package)
class IntegrationDefinition {
  final String id;
  final String name;
  final String description;
  final IntegrationCategory category;
  final String difficulty; // 'Easy', 'Medium', 'Hard'
  final List<String> tags;
  
  // UI Properties
  final dynamic icon; // IconData for Flutter, will be cast appropriately
  final dynamic brandColor; // Color for Flutter, will be cast appropriately
  
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
    required this.category,
    required this.difficulty,
    this.tags = const [],
    required this.icon,
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

// Integration definitions should be provided by platform-specific implementations
// Desktop apps can extend with Flutter-specific IntegrationDefinition instances
// Web apps can use JSON configurations