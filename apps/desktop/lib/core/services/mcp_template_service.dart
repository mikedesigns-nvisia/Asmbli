import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../models/mcp_server_config.dart';

/// MCP Server Template for easy configuration
class MCPServerTemplate {
  final String id;
  final String name;
  final String description;
  final String category;
  final String difficulty; // 'beginner', 'intermediate', 'advanced'
  final List<MCPConfigField> configFields;
  final List<String> setupInstructions;
  final List<String> prerequisites;
  final List<MCPExample> examples;
  final List<String> tags;
  final Map<String, dynamic> serverDefaults;

  const MCPServerTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.configFields,
    required this.setupInstructions,
    required this.prerequisites,
    required this.examples,
    required this.tags,
    required this.serverDefaults,
  });

  factory MCPServerTemplate.fromJson(Map<String, dynamic> json) {
    return MCPServerTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      difficulty: json['difficulty'] as String,
      configFields: (json['configFields'] as List<dynamic>)
          .map((e) => MCPConfigField.fromJson(e as Map<String, dynamic>))
          .toList(),
      setupInstructions: List<String>.from(json['setupInstructions'] as List),
      prerequisites: List<String>.from(json['prerequisites'] as List),
      examples: (json['examples'] as List<dynamic>)
          .map((e) => MCPExample.fromJson(e as Map<String, dynamic>))
          .toList(),
      tags: List<String>.from(json['tags'] as List),
      serverDefaults: Map<String, dynamic>.from(json['server'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'configFields': configFields.map((e) => e.toJson()).toList(),
      'setupInstructions': setupInstructions,
      'prerequisites': prerequisites,
      'examples': examples.map((e) => e.toJson()).toList(),
      'tags': tags,
      'server': serverDefaults,
    };
  }
}

/// Configuration field for MCP template
class MCPConfigField {
  final String name;
  final String label;
  final String type; // 'text', 'password', 'number', 'boolean', 'select', 'path', 'url'
  final bool required;
  final String description;
  final String? placeholder;
  final dynamic defaultValue;
  final List<MCPSelectOption>? options;
  final MCPFieldValidation? validation;

  const MCPConfigField({
    required this.name,
    required this.label,
    required this.type,
    required this.required,
    required this.description,
    this.placeholder,
    this.defaultValue,
    this.options,
    this.validation,
  });

  factory MCPConfigField.fromJson(Map<String, dynamic> json) {
    return MCPConfigField(
      name: json['name'] as String,
      label: json['label'] as String,
      type: json['type'] as String,
      required: json['required'] as bool,
      description: json['description'] as String,
      placeholder: json['placeholder'] as String?,
      defaultValue: json['defaultValue'],
      options: json['options'] != null
          ? (json['options'] as List<dynamic>)
              .map((e) => MCPSelectOption.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      validation: json['validation'] != null
          ? MCPFieldValidation.fromJson(json['validation'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'label': label,
      'type': type,
      'required': required,
      'description': description,
      if (placeholder != null) 'placeholder': placeholder,
      if (defaultValue != null) 'defaultValue': defaultValue,
      if (options != null) 'options': options!.map((e) => e.toJson()).toList(),
      if (validation != null) 'validation': validation!.toJson(),
    };
  }
}

/// Select option for dropdown fields
class MCPSelectOption {
  final String label;
  final dynamic value;

  const MCPSelectOption({
    required this.label,
    required this.value,
  });

  factory MCPSelectOption.fromJson(Map<String, dynamic> json) {
    return MCPSelectOption(
      label: json['label'] as String,
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
    };
  }
}

/// Field validation rules
class MCPFieldValidation {
  final String? pattern;
  final double? min;
  final double? max;
  final String? message;

  const MCPFieldValidation({
    this.pattern,
    this.min,
    this.max,
    this.message,
  });

  factory MCPFieldValidation.fromJson(Map<String, dynamic> json) {
    return MCPFieldValidation(
      pattern: json['pattern'] as String?,
      min: json['min']?.toDouble(),
      max: json['max']?.toDouble(),
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (pattern != null) 'pattern': pattern,
      if (min != null) 'min': min,
      if (max != null) 'max': max,
      if (message != null) 'message': message,
    };
  }
}

/// Example for template usage
class MCPExample {
  final String title;
  final String description;
  final String command;
  final String expectedResult;

  const MCPExample({
    required this.title,
    required this.description,
    required this.command,
    required this.expectedResult,
  });

  factory MCPExample.fromJson(Map<String, dynamic> json) {
    return MCPExample(
      title: json['title'] as String,
      description: json['description'] as String,
      command: json['command'] as String,
      expectedResult: json['expectedResult'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'command': command,
      'expectedResult': expectedResult,
    };
  }
}

/// Template validation result
class TemplateValidationResult {
  final bool valid;
  final List<TemplateValidationError> errors;
  final List<String> warnings;

  const TemplateValidationResult({
    required this.valid,
    required this.errors,
    required this.warnings,
  });

  factory TemplateValidationResult.fromJson(Map<String, dynamic> json) {
    return TemplateValidationResult(
      valid: json['valid'] as bool,
      errors: (json['errors'] as List<dynamic>)
          .map((e) => TemplateValidationError.fromJson(e as Map<String, dynamic>))
          .toList(),
      warnings: List<String>.from(json['warnings'] as List),
    );
  }
}

/// Template validation error
class TemplateValidationError {
  final String field;
  final String message;
  final String code;

  const TemplateValidationError({
    required this.field,
    required this.message,
    required this.code,
  });

  factory TemplateValidationError.fromJson(Map<String, dynamic> json) {
    return TemplateValidationError(
      field: json['field'] as String,
      message: json['message'] as String,
      code: json['code'] as String,
    );
  }
}

/// Service for managing MCP server templates
class MCPTemplateService {
  // Hard-coded templates (in production, these would come from the TypeScript layer)
  static final List<MCPServerTemplate> _coreTemplates = [
    // Filesystem Template
    const MCPServerTemplate(
      id: 'filesystem-template',
      name: 'Filesystem Access',
      description: 'Read, write, and manage files and directories on your local system',
      category: 'Development',
      difficulty: 'beginner',
      configFields: [
        MCPConfigField(
          name: 'rootPath',
          label: 'Root Directory',
          type: 'path',
          required: true,
          description: 'The root directory that the MCP server can access',
          placeholder: 'C:\\Users\\YourName\\Documents',
          defaultValue: '',
        ),
        MCPConfigField(
          name: 'readOnly',
          label: 'Read Only Mode',
          type: 'boolean',
          required: false,
          description: 'If enabled, only allow reading files (no writing/deleting)',
          defaultValue: false,
        ),
        MCPConfigField(
          name: 'allowedExtensions',
          label: 'Allowed File Extensions',
          type: 'text',
          required: false,
          description: 'Comma-separated list of allowed file extensions (leave empty for all)',
          placeholder: '.txt,.md,.json,.js,.ts',
        ),
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
        MCPExample(
          title: 'Read a file',
          description: 'Read the contents of a specific file',
          command: 'read file "README.md"',
          expectedResult: 'Returns the contents of README.md file',
        ),
        MCPExample(
          title: 'List directory',
          description: 'List files in the current directory',
          command: 'list files in current directory',
          expectedResult: 'Returns array of files and directories',
        ),
      ],
      tags: ['files', 'local', 'development', 'basic'],
      serverDefaults: {
        'id': 'filesystem-mcp',
        'name': 'Filesystem MCP Server',
        'type': 'filesystem',
        'config': {
          'features': ['read', 'write', 'list', 'create', 'delete'],
          'pricing': 'free'
        }
      },
    ),

    // GitHub Template
    const MCPServerTemplate(
      id: 'github-template',
      name: 'GitHub Integration',
      description: 'Access GitHub repositories, issues, pull requests, and more',
      category: 'Development',
      difficulty: 'intermediate',
      configFields: [
        MCPConfigField(
          name: 'GITHUB_TOKEN',
          label: 'GitHub Personal Access Token',
          type: 'password',
          required: true,
          description: 'GitHub PAT with appropriate permissions for your repositories',
          placeholder: 'ghp_xxxxxxxxxxxxxxxxxxxx',
        ),
        MCPConfigField(
          name: 'defaultOwner',
          label: 'Default Repository Owner',
          type: 'text',
          required: false,
          description: 'Default GitHub username/organization for repository operations',
          placeholder: 'your-username',
        ),
        MCPConfigField(
          name: 'includeForks',
          label: 'Include Forked Repositories',
          type: 'boolean',
          required: false,
          description: 'Include forked repositories in repository listings',
          defaultValue: false,
        ),
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
        MCPExample(
          title: 'List repositories',
          description: 'Get a list of your repositories',
          command: 'list my repositories',
          expectedResult: 'Returns array of repository objects',
        ),
        MCPExample(
          title: 'Create an issue',
          description: 'Create a new issue in a repository',
          command: 'create issue "Bug report" in repository "owner/repo"',
          expectedResult: 'Creates a new issue and returns the issue URL',
        ),
      ],
      tags: ['github', 'git', 'repositories', 'collaboration', 'api'],
      serverDefaults: {
        'id': 'github-mcp',
        'name': 'GitHub MCP Server',
        'type': 'github',
        'config': {
          'features': ['repositories', 'issues', 'pull-requests', 'commits'],
          'pricing': 'free'
        },
        'requiredAuth': [
          {'type': 'api_key', 'name': 'GITHUB_TOKEN', 'required': true}
        ]
      },
    ),

    // Memory Template
    const MCPServerTemplate(
      id: 'memory-template',
      name: 'Memory Storage',
      description: 'Persistent memory for storing and recalling information across conversations',
      category: 'Utility',
      difficulty: 'beginner',
      configFields: [
        MCPConfigField(
          name: 'storageType',
          label: 'Storage Type',
          type: 'select',
          required: true,
          description: 'Choose how memory data is stored',
          defaultValue: 'file',
          options: [
            MCPSelectOption(label: 'File System', value: 'file'),
            MCPSelectOption(label: 'In Memory (temporary)', value: 'memory'),
            MCPSelectOption(label: 'SQLite Database', value: 'sqlite'),
          ],
        ),
        MCPConfigField(
          name: 'storagePath',
          label: 'Storage Path',
          type: 'path',
          required: false,
          description: 'Path where memory data will be stored (for file/sqlite storage)',
          placeholder: './memory-data',
          defaultValue: './memory-data',
        ),
        MCPConfigField(
          name: 'maxEntries',
          label: 'Maximum Entries',
          type: 'number',
          required: false,
          description: 'Maximum number of memory entries to store',
          defaultValue: 1000,
          validation: MCPFieldValidation(
            min: 10,
            max: 10000,
            message: 'Must be between 10 and 10,000',
          ),
        ),
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
        MCPExample(
          title: 'Store information',
          description: 'Remember a piece of information',
          command: 'remember that John\'s favorite color is blue',
          expectedResult: 'Information stored successfully',
        ),
        MCPExample(
          title: 'Recall information',
          description: 'Retrieve stored information',
          command: 'what is John\'s favorite color?',
          expectedResult: 'Returns: John\'s favorite color is blue',
        ),
      ],
      tags: ['memory', 'storage', 'persistence', 'recall', 'utility'],
      serverDefaults: {
        'id': 'memory-mcp',
        'name': 'Memory MCP Server',
        'type': 'custom',
        'config': {
          'features': ['persistent-storage', 'key-value', 'search'],
          'pricing': 'free'
        }
      },
    ),

    // Web Search Template
    const MCPServerTemplate(
      id: 'search-template',
      name: 'Web Search',
      description: 'Search the web using Brave Search API for current information',
      category: 'Information',
      difficulty: 'beginner',
      configFields: [
        MCPConfigField(
          name: 'BRAVE_API_KEY',
          label: 'Brave Search API Key',
          type: 'password',
          required: true,
          description: 'API key from Brave Search API',
          placeholder: 'BSA-xxxxxxxxxxxxxxxxxxxx',
        ),
        MCPConfigField(
          name: 'defaultRegion',
          label: 'Default Search Region',
          type: 'select',
          required: false,
          description: 'Default region for search results',
          defaultValue: 'US',
          options: [
            MCPSelectOption(label: 'United States', value: 'US'),
            MCPSelectOption(label: 'United Kingdom', value: 'GB'),
            MCPSelectOption(label: 'Canada', value: 'CA'),
            MCPSelectOption(label: 'Australia', value: 'AU'),
            MCPSelectOption(label: 'Global', value: 'ALL'),
          ],
        ),
        MCPConfigField(
          name: 'maxResults',
          label: 'Maximum Results',
          type: 'number',
          required: false,
          description: 'Maximum number of search results to return',
          defaultValue: 10,
          validation: MCPFieldValidation(
            min: 1,
            max: 50,
            message: 'Must be between 1 and 50',
          ),
        ),
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
        MCPExample(
          title: 'Web search',
          description: 'Search for current information on the web',
          command: 'search for "latest AI developments 2024"',
          expectedResult: 'Returns current web search results about AI developments',
        ),
        MCPExample(
          title: 'News search',
          description: 'Find recent news articles',
          command: 'find recent news about climate change',
          expectedResult: 'Returns recent news articles about climate change',
        ),
      ],
      tags: ['search', 'web', 'information', 'current', 'brave'],
      serverDefaults: {
        'id': 'search-mcp',
        'name': 'Brave Search MCP Server',
        'type': 'web',
        'config': {
          'features': ['web-search', 'real-time', 'privacy-focused'],
          'pricing': 'freemium'
        },
        'requiredAuth': [
          {'type': 'api_key', 'name': 'BRAVE_API_KEY', 'required': true}
        ]
      },
    ),
  ];

  /// Get all available templates
  List<MCPServerTemplate> getAllTemplates() {
    return List.unmodifiable(_coreTemplates);
  }

  /// Get template by ID
  MCPServerTemplate? getTemplate(String id) {
    try {
      return _coreTemplates.firstWhere((template) => template.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get templates by category
  List<MCPServerTemplate> getTemplatesByCategory(String category) {
    return _coreTemplates.where((template) => template.category == category).toList();
  }

  /// Get all unique categories
  List<String> getCategories() {
    return _coreTemplates.map((template) => template.category).toSet().toList()..sort();
  }

  /// Search templates by query
  List<MCPServerTemplate> searchTemplates(String query) {
    final lowerQuery = query.toLowerCase();
    return _coreTemplates.where((template) {
      return template.name.toLowerCase().contains(lowerQuery) ||
          template.description.toLowerCase().contains(lowerQuery) ||
          template.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)) ||
          template.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get templates by difficulty level
  List<MCPServerTemplate> getTemplatesByDifficulty(String difficulty) {
    return _coreTemplates.where((template) => template.difficulty == difficulty).toList();
  }

  /// Get popular/recommended templates
  List<MCPServerTemplate> getPopularTemplates() {
    return _coreTemplates.where((template) => 
        template.difficulty == 'beginner' || 
        ['filesystem-template', 'github-template', 'memory-template', 'search-template'].contains(template.id)
    ).toList();
  }

  /// Validate template configuration
  TemplateValidationResult validateTemplateConfig(String templateId, Map<String, dynamic> config) {
    final template = getTemplate(templateId);
    if (template == null) {
      return const TemplateValidationResult(
        valid: false,
        errors: [
          TemplateValidationError(
            field: 'template',
            message: 'Template not found',
            code: 'TEMPLATE_NOT_FOUND',
          )
        ],
        warnings: [],
      );
    }

    final errors = <TemplateValidationError>[];
    final warnings = <String>[];

    // Validate each config field
    for (final field in template.configFields) {
      final value = config[field.name];

      // Required field validation
      if (field.required && (value == null || value == '')) {
        errors.add(TemplateValidationError(
          field: field.name,
          message: '${field.label} is required',
          code: 'REQUIRED_FIELD',
        ));
        continue;
      }

      // Skip validation if field is not provided and not required
      if (value == null || value == '') {
        continue;
      }

      // Type and validation checks
      final fieldErrors = _validateField(field, value);
      errors.addAll(fieldErrors);

      // Warnings
      final fieldWarnings = _getFieldWarnings(field, value);
      warnings.addAll(fieldWarnings);
    }

    return TemplateValidationResult(
      valid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Create MCP server config from template
  MCPServerConfig? instantiateTemplate(String templateId, Map<String, dynamic> config, {String? customId}) {
    final template = getTemplate(templateId);
    if (template == null) return null;

    // Validate configuration first
    final validation = validateTemplateConfig(templateId, config);
    if (!validation.valid) return null;

    // Create server config
    final serverDefaults = Map<String, dynamic>.from(template.serverDefaults);
    
    return MCPServerConfig(
      id: customId ?? serverDefaults['id'] as String,
      name: serverDefaults['name'] as String,
      url: serverDefaults['url'] as String? ?? 'stdio://', // Provide default URL
      type: template.category, // Use category as type
      command: 'npx', // Use npx instead of uvx for Windows compatibility
      args: _getArgsForServer(template, config),
      workingDirectory: null,
      env: _getEnvForServer(template, config),
      enabled: true,
      description: template.description,
      capabilities: [], // Templates don't have direct capabilities field
      requiredAuth: [],
    );
  }

  List<TemplateValidationError> _validateField(MCPConfigField field, dynamic value) {
    final errors = <TemplateValidationError>[];

    // Type validation
    switch (field.type) {
      case 'number':
        if (value is! num && double.tryParse(value.toString()) == null) {
          errors.add(TemplateValidationError(
            field: field.name,
            message: '${field.label} must be a number',
            code: 'INVALID_TYPE',
          ));
        }
        break;
      case 'boolean':
        if (value is! bool) {
          errors.add(TemplateValidationError(
            field: field.name,
            message: '${field.label} must be true or false',
            code: 'INVALID_TYPE',
          ));
        }
        break;
      case 'url':
        if (value is String && (Uri.tryParse(value)?.hasAbsolutePath != true)) {
          errors.add(TemplateValidationError(
            field: field.name,
            message: '${field.label} must be a valid URL',
            code: 'INVALID_URL',
          ));
        }
        break;
    }

    // Custom validation rules
    if (field.validation != null) {
      final validation = field.validation!;
      
      if (field.type == 'number' && value is num) {
        if (validation.min != null && value < validation.min!) {
          errors.add(TemplateValidationError(
            field: field.name,
            message: validation.message ?? '${field.label} must be at least ${validation.min}',
            code: 'MIN_VALUE',
          ));
        }
        if (validation.max != null && value > validation.max!) {
          errors.add(TemplateValidationError(
            field: field.name,
            message: validation.message ?? '${field.label} must not exceed ${validation.max}',
            code: 'MAX_VALUE',
          ));
        }
      }

      if (validation.pattern != null && value is String) {
        if (!RegExp(validation.pattern!).hasMatch(value)) {
          errors.add(TemplateValidationError(
            field: field.name,
            message: validation.message ?? '${field.label} format is invalid',
            code: 'PATTERN_MISMATCH',
          ));
        }
      }
    }

    return errors;
  }

  List<String> _getFieldWarnings(MCPConfigField field, dynamic value) {
    final warnings = <String>[];

    // API token warnings
    if (field.type == 'password' && field.name.contains('TOKEN')) {
      if (value is String && value.length < 20) {
        warnings.add('${field.label} seems short for an API token');
      }
    }

    // Path warnings
    if (field.type == 'path' && value is String) {
      if (value.contains(' ') && !value.contains('"')) {
        warnings.add('${field.label} contains spaces and should be quoted');
      }
    }

    // URL warnings
    if (field.type == 'url' && value is String) {
      if (value.startsWith('http://')) {
        warnings.add('${field.label} uses HTTP instead of HTTPS (less secure)');
      }
    }

    return warnings;
  }

  List<String> _getArgsForServer(MCPServerTemplate template, Map<String, dynamic> config) {
    final serverType = template.serverDefaults['type'] as String;
    
    switch (serverType) {
      case 'filesystem':
        return [
          '@modelcontextprotocol/server-filesystem',
          config['rootPath'] as String? ?? ''
        ];
      case 'github':
        return ['@modelcontextprotocol/server-github'];
      case 'database':
        if (template.id.contains('postgres')) {
          return [
            '@modelcontextprotocol/server-postgres',
            config['connectionString'] as String? ?? ''
          ];
        }
        break;
      case 'web':
        if (template.id.contains('search')) {
          return ['@modelcontextprotocol/server-brave-search'];
        }
        break;
      case 'api':
        return ['@modelcontextprotocol/server-fetch'];
    }
    
    return [];
  }

  Map<String, String> _getEnvForServer(MCPServerTemplate template, Map<String, dynamic> config) {
    final env = <String, String>{};
    
    // Add authentication environment variables
    final requiredAuth = template.serverDefaults['requiredAuth'] as List<dynamic>?;
    if (requiredAuth != null) {
      for (final auth in requiredAuth.cast<Map<String, dynamic>>()) {
        final authName = auth['name'] as String;
        if (config.containsKey(authName)) {
          env[authName] = config[authName].toString();
        }
      }
    }

    // Add other environment variables based on config
    for (final entry in config.entries) {
      if (entry.key.toUpperCase() == entry.key || entry.key.contains('_')) {
        env[entry.key] = entry.value.toString();
      }
    }

    return env;
  }
}

// Riverpod providers
final mcpTemplateServiceProvider = Provider<MCPTemplateService>((ref) {
  return MCPTemplateService();
});

final allMCPTemplatesProvider = Provider<List<MCPServerTemplate>>((ref) {
  final service = ref.read(mcpTemplateServiceProvider);
  return service.getAllTemplates();
});

final mcpTemplateCategoriesProvider = Provider<List<String>>((ref) {
  final service = ref.read(mcpTemplateServiceProvider);
  return service.getCategories();
});

final mcpTemplatesByCategoryProvider = Provider.family<List<MCPServerTemplate>, String>((ref, category) {
  final service = ref.read(mcpTemplateServiceProvider);
  return service.getTemplatesByCategory(category);
});

final popularMCPTemplatesProvider = Provider<List<MCPServerTemplate>>((ref) {
  final service = ref.read(mcpTemplateServiceProvider);
  return service.getPopularTemplates();
});

final mcpTemplateSearchProvider = Provider.family<List<MCPServerTemplate>, String>((ref, query) {
  final service = ref.read(mcpTemplateServiceProvider);
  return query.isEmpty ? service.getAllTemplates() : service.searchTemplates(query);
});