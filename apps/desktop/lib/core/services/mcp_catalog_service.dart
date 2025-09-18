import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mcp_catalog_entry.dart';
import '../models/agent_mcp_server_config.dart';
import '../models/github_mcp_registry_models.dart';
import '../models/mcp_server_category.dart';
import 'github_mcp_registry_service.dart';
import 'mcp_catalog_adapter.dart';
import 'featured_mcp_servers_service.dart';

/// Provider for MCP catalog service
final mcpCatalogServiceProvider = Provider<MCPCatalogService>((ref) {
  final githubService = ref.read(githubMCPRegistryServiceProvider);
  final featuredService = FeaturedMCPServersService();
  return MCPCatalogService(githubService, featuredService);
});

/// Provider for MCP catalog entries
final mcpCatalogEntriesProvider = FutureProvider<List<MCPCatalogEntry>>((ref) async {
  final service = ref.read(mcpCatalogServiceProvider);
  return service.getAllEntries();
});

/// Provider for featured MCP entries
final mcpFeaturedEntriesProvider = FutureProvider<List<MCPCatalogEntry>>((ref) async {
  final entriesAsync = ref.watch(mcpCatalogEntriesProvider);
  return entriesAsync.when(
    data: (entries) => entries.where((entry) => entry.isFeatured).toList(),
    loading: () => <MCPCatalogEntry>[],
    error: (error, stack) => <MCPCatalogEntry>[],
  );
});

/// Provider for agent MCP configurations
final agentMCPConfigsProvider = Provider.family<Map<String, AgentMCPServerConfig>, String>((ref, agentId) {
  // Return empty map for now - this would be implemented with actual agent config logic
  return <String, AgentMCPServerConfig>{};
});

/// Service for managing MCP server catalog entries powered by GitHub MCP Registry
class MCPCatalogService {
  final GitHubMCPRegistryService _githubService;
  final FeaturedMCPServersService _featuredService;

  // Local cache
  List<MCPCatalogEntry>? _cachedEntries;
  DateTime? _lastCacheTime;
  static const Duration _cacheValidDuration = Duration(minutes: 30);

  MCPCatalogService(this._githubService, this._featuredService);

  /// Get catalog entry by ID
  Future<MCPCatalogEntry?> getCatalogEntry(String serverId) async {
    final entries = await getAllEntries();
    return entries.cast<MCPCatalogEntry?>().firstWhere(
      (entry) => entry?.id == serverId,
      orElse: () => null,
    );
  }

  /// Get all catalog entries from GitHub registry and featured servers
  /// Prioritizes featured servers and merges with GitHub registry results
  Future<List<MCPCatalogEntry>> getAllEntries() async {
    try {
      // Check cache first
      if (_cachedEntries != null && _lastCacheTime != null) {
        final cacheAge = DateTime.now().difference(_lastCacheTime!);
        if (cacheAge < _cacheValidDuration) {
          return _cachedEntries!;
        }
      }

      // Get featured servers with star counts (always available)
      List<MCPCatalogEntry> featuredServers;
      try {
        final githubApi = _githubService.api;
        featuredServers = await _featuredService.getFeaturedServersWithStarCounts(githubApi);
      } catch (e) {
        print('[MCPCatalogService] Error fetching star counts, using featured servers without stars: $e');
        featuredServers = _featuredService.getFeaturedServers();
      }
      final featuredServerIds = featuredServers.map((server) => server.id).toSet();

      List<MCPCatalogEntry> allEntries = [...featuredServers];

      try {
        // Fetch from GitHub registry
        final githubEntries = await _githubService.getAllActiveServers();
        final githubCatalogEntries = MCPCatalogAdapter.fromGitHubEntries(githubEntries);

        // Add GitHub entries that aren't already featured
        final uniqueGithubEntries = githubCatalogEntries
            .where((entry) => !featuredServerIds.contains(entry.id))
            .toList();

        allEntries.addAll(uniqueGithubEntries);

        print('[MCPCatalogService] Successfully loaded ${featuredServers.length} featured + ${uniqueGithubEntries.length} GitHub entries');
      } catch (githubError) {
        print('[MCPCatalogService] GitHub registry error: $githubError - using featured servers only');
        // Continue with just featured servers if GitHub fails
      }

      // Sort entries: featured first, then by name
      allEntries.sort((a, b) {
        // Featured servers come first
        if (a.isFeatured && !b.isFeatured) return -1;
        if (!a.isFeatured && b.isFeatured) return 1;

        // Within same category, sort by name
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      // Update cache
      _cachedEntries = allEntries;
      _lastCacheTime = DateTime.now();

      return allEntries;
    } catch (e) {
      print('[MCPCatalogService] Critical error: $e');

      // Return cached entries if available
      if (_cachedEntries != null) {
        return _cachedEntries!;
      }

      // Last resort: return just featured servers
      try {
        final fallbackServers = _featuredService.getFeaturedServers();
        print('[MCPCatalogService] Fallback: returning ${fallbackServers.length} featured servers');
        return fallbackServers;
      } catch (fallbackError) {
        print('[MCPCatalogService] Even fallback failed: $fallbackError');
        return [];
      }
    }
  }

  /// Search catalog entries by name or description
  Future<List<MCPCatalogEntry>> searchEntries(String query) async {
    if (query.trim().isEmpty) return [];

    final entries = await getAllEntries();
    final lowerQuery = query.toLowerCase();

    return entries.where((entry) =>
      entry.name.toLowerCase().contains(lowerQuery) ||
      entry.description.toLowerCase().contains(lowerQuery) ||
      entry.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))
    ).toList();
  }

  /// Get entries by transport type
  Future<List<MCPCatalogEntry>> getEntriesByTransport(MCPTransportType transport) async {
    final entries = await getAllEntries();
    return entries.where((entry) => entry.transport == transport).toList();
  }

  /// Alias for getAllEntries (for compatibility)
  Future<List<MCPCatalogEntry>> getAllCatalogEntries() async {
    return getAllEntries();
  }

  /// Get enabled server IDs (for compatibility)
  Future<List<String>> getEnabledServerIds() async {
    final entries = await getAllEntries();
    return entries.map((entry) => entry.id).toList();
  }

  /// Get agent MCP configurations (for compatibility)
  Map<String, dynamic> getAgentMCPConfigs(String agentId) {
    return {};
  }

  /// Get agent server credentials (for compatibility)
  Map<String, String> getAgentServerCredentials(String agentId, String serverId) {
    return {};
  }

  /// Mark server as used (for compatibility)
  void markServerUsed(String serverId) {
    // Implementation for marking server as used
  }

  /// Check if agent server is configured (for compatibility)
  bool isAgentServerConfigured(String agentId, String serverId) {
    return true; // Default to true for now
  }

  /// Enable server for agent with authentication config
  Future<void> enableServerForAgent(String agentId, String serverId, Map<String, String> authConfig) async {
    // Implementation for enabling server for agent
    // This would typically save the configuration to persistent storage
  }

  /// Remove server from agent
  Future<void> removeServerFromAgent(String agentId, String serverId) async {
    // Implementation for removing server from agent
    // This would typically remove the configuration from persistent storage
  }

  /// Clear cache to force refresh on next request
  void clearCache() {
    _cachedEntries = null;
    _lastCacheTime = null;
  }

  /// Check if cache is valid
  bool get isCacheValid {
    if (_cachedEntries == null || _lastCacheTime == null) return false;
    final cacheAge = DateTime.now().difference(_lastCacheTime!);
    return cacheAge < _cacheValidDuration;
  }

  /// Get featured entries directly from featured service
  List<MCPCatalogEntry> getFeaturedEntries() {
    return _featuredService.getFeaturedServers();
  }

  /// Get featured entries by category
  List<MCPCatalogEntry> getFeaturedEntriesByCategory(MCPServerCategory category) {
    return _featuredService.getFeaturedServersByCategory(category);
  }

  /// Get official servers only
  List<MCPCatalogEntry> getOfficialServers() {
    return _featuredService.getOfficialServers();
  }

  /// Check if a server is featured
  bool isFeaturedServer(String serverId) {
    return _featuredService.isFeaturedServer(serverId);
  }

  /// Get installation difficulty for a server
  String getServerDifficulty(String serverId) {
    return _featuredService.getServerDifficulty(serverId);
  }

  /// Force refresh from GitHub registry
  Future<void> refreshCatalog() async {
    clearCache();
    _githubService.clearCache();
    await getAllEntries();
  }

  /// Convert GitHub MCP Registry entry to MCPCatalogEntry
  MCPCatalogEntry convertGitHubToCatalogEntry(GitHubMCPRegistryEntry githubEntry) {
    return MCPCatalogAdapter.fromGitHubEntry(githubEntry);
  }
}

// The provider is already defined at the top of the file