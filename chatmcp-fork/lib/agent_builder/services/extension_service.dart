import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/extension.dart';
import '../models/agent_config.dart';

class ExtensionService {
  static List<Extension>? _cachedExtensions;
  static List<ExtensionCategory>? _cachedCategories;

  /// Load all available extensions from assets
  static Future<List<Extension>> loadExtensions() async {
    if (_cachedExtensions != null) {
      return _cachedExtensions!;
    }

    try {
      final jsonString = await rootBundle.loadString('assets/extensions_library.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _cachedExtensions = jsonList.map((json) => Extension.fromJson(json)).toList();
      return _cachedExtensions!;
    } catch (e) {
      throw Exception('Failed to load extensions: $e');
    }
  }

  /// Load extension categories from assets
  static Future<List<ExtensionCategory>> loadCategories() async {
    if (_cachedCategories != null) {
      return _cachedCategories!;
    }

    try {
      final jsonString = await rootBundle.loadString('assets/categories.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _cachedCategories = jsonList.map((json) => ExtensionCategory.fromJson(json)).toList();
      return _cachedCategories!;
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  /// Filter extensions by various criteria
  static List<Extension> filterExtensions(
    List<Extension> extensions, {
    String? category,
    ExtensionComplexity? maxComplexity,
    ConnectionType? connectionType,
    PricingTier? pricing,
    String? searchQuery,
    bool? enabledOnly,
  }) {
    return extensions.where((extension) {
      // Category filter
      if (category != null && extension.category != category) {
        return false;
      }

      // Complexity filter
      if (maxComplexity != null) {
        final complexityOrder = [
          ExtensionComplexity.low,
          ExtensionComplexity.medium,
          ExtensionComplexity.high
        ];
        if (complexityOrder.indexOf(extension.complexity) > complexityOrder.indexOf(maxComplexity)) {
          return false;
        }
      }

      // Connection type filter
      if (connectionType != null && extension.connectionType != connectionType) {
        return false;
      }

      // Pricing filter
      if (pricing != null && extension.pricing != pricing) {
        return false;
      }

      // Enabled filter
      if (enabledOnly == true && !extension.enabled) {
        return false;
      }

      // Search query filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        if (!extension.name.toLowerCase().contains(query) &&
            !extension.description.toLowerCase().contains(query) &&
            !extension.provider.toLowerCase().contains(query) &&
            !extension.features.any((feature) => feature.toLowerCase().contains(query))) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Get extensions grouped by category
  static Map<String, List<Extension>> groupExtensionsByCategory(List<Extension> extensions) {
    final Map<String, List<Extension>> grouped = {};
    
    for (final extension in extensions) {
      grouped.putIfAbsent(extension.category, () => []).add(extension);
    }
    
    return grouped;
  }

  /// Get recommended extensions for a specific role
  static List<Extension> getRecommendedExtensionsForRole(
    List<Extension> extensions,
    AgentRole role,
  ) {
    final Map<AgentRole, List<String>> roleRecommendations = {
      AgentRole.developer: [
        'filesystem-mcp',
        'github-mcp',
        'web-fetch-mcp',
        'postgres-mcp',
      ],
      AgentRole.analyst: [
        'postgres-mcp',
        'web-fetch-mcp',
        'memory-mcp',
      ],
      AgentRole.assistant: [
        'web-fetch-mcp',
        'memory-mcp',
        'filesystem-mcp',
      ],
      AgentRole.creative: [
        'web-fetch-mcp',
        'memory-mcp',
      ],
      AgentRole.specialist: [
        'filesystem-mcp',
        'memory-mcp',
      ],
    };

    final recommendedIds = roleRecommendations[role] ?? [];
    return extensions.where((ext) => recommendedIds.contains(ext.id)).toList();
  }

  /// Generate ChatMCP configuration from selected extensions
  static ChatMCPConfig generateChatMCPConfig(
    List<Extension> selectedExtensions,
    AgentConfig agentConfig,
  ) {
    final Map<String, MCPServerConfig> mcpServers = {};

    for (final extension in selectedExtensions.where((ext) => ext.connectionType == ConnectionType.mcp)) {
      mcpServers[_getMCPServerKey(extension)] = generateMCPServerConfig(extension);
    }

    final agentMetadata = AgentMetadata(
      name: agentConfig.agentName,
      description: agentConfig.agentDescription,
      role: agentConfig.role.name,
      createdAt: DateTime.now().toIso8601String(),
    );

    return ChatMCPConfig(
      mcpServers: mcpServers,
      agentMetadata: agentMetadata,
    );
  }

  /// Get MCP server configuration key for an extension
  static String _getMCPServerKey(Extension extension) {
    // Convert extension ID to MCP server key
    return extension.id.replaceAll('-mcp', '').replaceAll('-', '_');
  }

  /// Generate MCP server configuration for an extension
  static MCPServerConfig generateMCPServerConfig(Extension extension) {
    final Map<String, MCPServerMapping> mcpMappings = {
      'filesystem-mcp': MCPServerMapping(
        command: 'uvx',
        args: ['@modelcontextprotocol/server-filesystem'],
        envKeys: [],
      ),
      'github-mcp': MCPServerMapping(
        command: 'uvx',
        args: ['@modelcontextprotocol/server-github'],
        envKeys: ['GITHUB_PERSONAL_ACCESS_TOKEN'],
      ),
      'web-fetch-mcp': MCPServerMapping(
        command: 'uvx',
        args: ['@modelcontextprotocol/server-fetch'],
        envKeys: [],
      ),
      'postgres-mcp': MCPServerMapping(
        command: 'uvx',
        args: ['@modelcontextprotocol/server-postgres'],
        envKeys: ['POSTGRES_CONNECTION_STRING'],
      ),
      'memory-mcp': MCPServerMapping(
        command: 'uvx',
        args: ['@modelcontextprotocol/server-memory'],
        envKeys: [],
      ),
    };

    final mapping = mcpMappings[extension.id];
    if (mapping == null) {
      throw Exception('No MCP mapping found for extension: ${extension.id}');
    }

    final Map<String, String>? env = mapping.envKeys.isNotEmpty
        ? Map.fromEntries(mapping.envKeys.map((key) => MapEntry(key, '\${$key}')))
        : null;

    return MCPServerConfig(
      command: mapping.command,
      args: mapping.args,
      env: env,
      description: extension.description,
    );
  }

  /// Get setup instructions for an extension
  static String getSetupInstructions(Extension extension) {
    final Map<String, String> instructions = {
      'filesystem-mcp': '''
1. Ensure uvx is installed (comes with uv)
2. No additional configuration required
3. The server will have access to your filesystem
''',
      'github-mcp': '''
1. Create a GitHub Personal Access Token
2. Set the GITHUB_PERSONAL_ACCESS_TOKEN environment variable
3. Grant appropriate repository permissions
''',
      'web-fetch-mcp': '''
1. Ensure uvx is installed (comes with uv)
2. No additional configuration required
3. Internet connectivity required
''',
      'postgres-mcp': '''
1. Set up PostgreSQL database connection
2. Set the POSTGRES_CONNECTION_STRING environment variable
3. Format: postgresql://user:password@host:port/database
''',
      'memory-mcp': '''
1. Ensure uvx is installed (comes with uv)
2. No additional configuration required
3. Memory will be stored locally
''',
    };

    return instructions[extension.id] ?? 'Setup instructions not available for this extension.';
  }

  /// Clear cached data (useful for testing or forcing reload)
  static void clearCache() {
    _cachedExtensions = null;
    _cachedCategories = null;
  }
}

class ExtensionCategory {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String color;

  const ExtensionCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });

  factory ExtensionCategory.fromJson(Map<String, dynamic> json) {
    return ExtensionCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
    };
  }
}

class MCPServerMapping {
  final String command;
  final List<String> args;
  final List<String> envKeys;

  const MCPServerMapping({
    required this.command,
    required this.args,
    required this.envKeys,
  });
}