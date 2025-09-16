import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mcp_catalog_entry.dart';
import '../models/agent_mcp_server_config.dart';

/// Provider for MCP catalog service
final mcpCatalogServiceProvider = Provider<MCPCatalogService>((ref) {
  final service = MCPCatalogService();
  service.initializeDefaults();
  return service;
});

/// Provider for MCP catalog entries
final mcpCatalogEntriesProvider = Provider<List<MCPCatalogEntry>>((ref) {
  final service = ref.watch(mcpCatalogServiceProvider);
  return service.getAllEntries();
});

/// Provider for featured MCP entries
final mcpFeaturedEntriesProvider = Provider<List<MCPCatalogEntry>>((ref) {
  final entries = ref.watch(mcpCatalogEntriesProvider);
  return entries.where((entry) => entry.isFeatured).toList();
});

/// Provider for agent MCP configurations
final agentMCPConfigsProvider = Provider.family<Map<String, AgentMCPServerConfig>, String>((ref, agentId) {
  // Return empty map for now - this would be implemented with actual agent config logic
  return <String, AgentMCPServerConfig>{};
});

/// Service for managing MCP server catalog entries
class MCPCatalogService {
  final Map<String, MCPCatalogEntry> _catalog = {};

  /// Get catalog entry by ID
  MCPCatalogEntry? getCatalogEntry(String serverId) {
    return _catalog[serverId];
  }

  /// Add catalog entry
  void addCatalogEntry(MCPCatalogEntry entry) {
    _catalog[entry.id] = entry;
  }

  /// Remove catalog entry
  void removeCatalogEntry(String serverId) {
    _catalog.remove(serverId);
  }

  /// Get all catalog entries
  List<MCPCatalogEntry> getAllEntries() {
    return _catalog.values.toList();
  }

  /// Search catalog entries by name or description
  List<MCPCatalogEntry> searchEntries(String query) {
    final lowerQuery = query.toLowerCase();
    return _catalog.values.where((entry) =>
      entry.name.toLowerCase().contains(lowerQuery) ||
      entry.description.toLowerCase().contains(lowerQuery) ||
      entry.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))
    ).toList();
  }

  /// Get entries by transport type
  List<MCPCatalogEntry> getEntriesByTransport(MCPTransportType transport) {
    return _catalog.values.where((entry) => entry.transport == transport).toList();
  }

  /// Alias for getAllEntries (for compatibility)
  List<MCPCatalogEntry> getAllCatalogEntries() {
    return getAllEntries();
  }

  /// Get enabled server IDs (for compatibility)
  List<String> getEnabledServerIds() {
    return _catalog.keys.toList();
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

  /// Initialize with default entries
  void initializeDefaults() {
    // Add some default MCP servers
    addCatalogEntry(const MCPCatalogEntry(
      id: 'filesystem',
      name: 'Filesystem MCP Server',
      description: 'Provides file system access capabilities',
      command: 'uvx',
      args: ['mcp-server-filesystem'],
      transport: MCPTransportType.stdio,
      capabilities: ['read_file', 'write_file', 'list_directory'],
      tags: ['filesystem', 'files'],
    ));

    addCatalogEntry(const MCPCatalogEntry(
      id: 'git',
      name: 'Git MCP Server',
      description: 'Provides Git repository management capabilities',
      command: 'uvx',
      args: ['mcp-server-git'],
      transport: MCPTransportType.stdio,
      capabilities: ['git_status', 'git_commit', 'git_push', 'git_pull'],
      tags: ['git', 'version-control'],
    ));

    addCatalogEntry(const MCPCatalogEntry(
      id: 'sqlite',
      name: 'SQLite MCP Server',
      description: 'Provides SQLite database access capabilities',
      command: 'uvx',
      args: ['mcp-server-sqlite'],
      transport: MCPTransportType.stdio,
      capabilities: ['query', 'execute', 'schema'],
      tags: ['database', 'sqlite'],
    ));
  }
}

// The provider is already defined at the top of the file