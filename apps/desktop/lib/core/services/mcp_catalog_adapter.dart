import '../models/mcp_catalog_entry.dart';
import '../models/github_mcp_registry_models.dart';

/// Adapter to convert GitHub MCP Registry entries to MCPCatalogEntry format
class MCPCatalogAdapter {
  /// Convert GitHub MCP Registry entry to MCPCatalogEntry
  static MCPCatalogEntry fromGitHubEntry(GitHubMCPRegistryEntry githubEntry) {
    final primaryPackage = githubEntry.primaryPackage;

    // Determine command and args based on package type
    String command = 'uvx';
    List<String> args = [];

    if (primaryPackage != null) {
      switch (primaryPackage.registryType) {
        case PackageRegistryType.npm:
          command = 'npx';
          args = [primaryPackage.identifier];
          break;
        case PackageRegistryType.pypi:
          command = 'uvx';
          args = [primaryPackage.identifier];
          break;
        case PackageRegistryType.docker:
          command = 'docker';
          args = ['run', primaryPackage.identifier];
          break;
        case PackageRegistryType.github:
          command = 'git';
          args = ['clone', primaryPackage.url ?? 'https://github.com/${primaryPackage.identifier}'];
          break;
        case PackageRegistryType.custom:
          command = primaryPackage.identifier;
          args = [];
          break;
      }
    }

    // Determine capabilities from meta or package info
    List<String> capabilities = [];
    if (githubEntry.meta?.containsKey('capabilities') == true) {
      final caps = githubEntry.meta!['capabilities'];
      if (caps is List) {
        capabilities = caps.cast<String>();
      }
    }

    // Generate default capabilities based on server type
    if (capabilities.isEmpty) {
      capabilities = _generateDefaultCapabilities(githubEntry.name, githubEntry.tags);
    }

    return MCPCatalogEntry(
      id: githubEntry.id,
      name: githubEntry.name,
      description: githubEntry.description,
      command: command,
      args: args,
      transport: MCPTransportType.stdio, // Default to stdio
      version: githubEntry.version,
      capabilities: capabilities,
      requiredEnvVars: _extractEnvVars(githubEntry.meta, 'required'),
      optionalEnvVars: _extractEnvVars(githubEntry.meta, 'optional'),
      defaultEnvVars: _extractEnvVars(githubEntry.meta, 'default'),
      remoteUrl: githubEntry.repositoryUrl,
      setupInstructions: _extractSetupInstructions(githubEntry.meta),
      isFeatured: _isFeatured(githubEntry),
      isOfficial: _isOfficial(githubEntry),
      tags: githubEntry.tags,
      author: _extractAuthor(githubEntry.meta),
      homepage: githubEntry.repositoryUrl,
      repository: githubEntry.repositoryUrl,
      documentationUrl: _extractDocumentationUrl(githubEntry.meta),
      lastUpdated: githubEntry.updatedAt,
      createdAt: githubEntry.createdAt,
      updatedAt: githubEntry.updatedAt,
    );
  }

  /// Convert multiple GitHub entries to MCPCatalogEntry list
  static List<MCPCatalogEntry> fromGitHubEntries(List<GitHubMCPRegistryEntry> githubEntries) {
    return githubEntries.map(fromGitHubEntry).toList();
  }

  /// Extract environment variables from meta data
  static Map<String, String> _extractEnvVars(Map<String, dynamic>? meta, String type) {
    if (meta == null) return {};

    final envVars = meta['${type}_env_vars'] ?? meta['env_vars']?[type];
    if (envVars is Map) {
      return Map<String, String>.from(envVars);
    }

    return {};
  }

  /// Extract setup instructions from meta data
  static String? _extractSetupInstructions(Map<String, dynamic>? meta) {
    if (meta == null) return null;

    return meta['setup_instructions'] as String? ??
           meta['installation'] as String? ??
           meta['instructions'] as String?;
  }

  /// Determine if server is featured
  static bool _isFeatured(GitHubMCPRegistryEntry entry) {
    if (entry.meta?.containsKey('featured') == true) {
      return entry.meta!['featured'] as bool? ?? false;
    }

    // Consider servers with many packages or recent updates as featured
    return entry.packages.length > 1 ||
           (entry.updatedAt != null &&
            DateTime.now().difference(entry.updatedAt!).inDays < 30);
  }

  /// Determine if server is official
  static bool _isOfficial(GitHubMCPRegistryEntry entry) {
    if (entry.meta?.containsKey('official') == true) {
      return entry.meta!['official'] as bool? ?? false;
    }

    // Check if it's from official organizations
    final name = entry.name.toLowerCase();
    return name.startsWith('io.github.modelcontextprotocol/') ||
           name.startsWith('io.github.anthropics/') ||
           name.startsWith('io.github.openai/');
  }

  /// Extract author from meta data
  static String? _extractAuthor(Map<String, dynamic>? meta) {
    if (meta == null) return null;

    return meta['author'] as String? ??
           meta['maintainer'] as String? ??
           meta['creator'] as String?;
  }

  /// Extract documentation URL from meta data
  static String? _extractDocumentationUrl(Map<String, dynamic>? meta) {
    if (meta == null) return null;

    return meta['documentation_url'] as String? ??
           meta['docs_url'] as String? ??
           meta['readme_url'] as String?;
  }

  /// Generate default capabilities based on server name and tags
  static List<String> _generateDefaultCapabilities(String name, List<String> tags) {
    final capabilities = <String>[];
    final lowerName = name.toLowerCase();

    // Common capability mappings
    if (lowerName.contains('filesystem') || tags.contains('filesystem')) {
      capabilities.addAll(['read_file', 'write_file', 'list_directory']);
    }

    if (lowerName.contains('git') || tags.contains('git')) {
      capabilities.addAll(['git_status', 'git_commit', 'git_push', 'git_pull']);
    }

    if (lowerName.contains('database') || lowerName.contains('sql') || tags.contains('database')) {
      capabilities.addAll(['query', 'execute', 'schema']);
    }

    if (lowerName.contains('api') || lowerName.contains('http') || tags.contains('api')) {
      capabilities.addAll(['http_request', 'api_call']);
    }

    if (lowerName.contains('search') || tags.contains('search')) {
      capabilities.addAll(['search', 'query']);
    }

    // If no specific capabilities found, add generic ones
    if (capabilities.isEmpty) {
      capabilities.addAll(['execute', 'query']);
    }

    return capabilities;
  }
}