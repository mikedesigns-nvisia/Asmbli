import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/models/agent.dart';
import 'business/base_business_service.dart';
import '../models/enhanced_agent.dart';
import '../models/mcp_catalog_entry.dart';
import 'agent_mcp_configuration_service.dart';
import 'dynamic_mcp_server_manager.dart';
import 'enhanced_conversation_service.dart';
import 'llm_tool_call_parser.dart';
import 'mcp_bridge_service.dart';
import 'context_mcp_resource_service.dart';
import 'agent_context_prompt_service.dart';
import 'llm/unified_llm_service.dart';

/// Centralized provider for MCP integration services
/// Provides a single entry point for all MCP-related functionality
class MCPIntegrationProvider {
  final AgentMCPConfigurationService _configService;
  final DynamicMCPServerManager _serverManager;
  final EnhancedConversationService _conversationService;
  final EnhancedAgentService _agentService;

  MCPIntegrationProvider(
    this._configService,
    this._serverManager,
    this._conversationService,
    this._agentService,
  );

  /// Get enhanced agent with MCP configurations
  Future<EnhancedAgent> getEnhancedAgent(Agent baseAgent) async {
    final mcpConfigs = await _configService.getAgentMCPConfigs(baseAgent.id);
    return _agentService.getEnhancedAgent(baseAgent, mcpConfigs);
  }

  /// Enable GitHub MCP tool for agent
  Future<void> enableGitHubMCPTool({
    required String agentId,
    required String catalogEntryId,
    Map<String, String> environmentVars = const {},
    List<String> requiredCapabilities = const [],
    int priority = 0,
  }) async {
    await _configService.enableGitHubMCPToolForAgent(
      agentId,
      catalogEntryId,
      environmentVars: environmentVars,
      requiredCapabilities: requiredCapabilities,
      priority: priority,
    );

    // Clear agent cache to force refresh
    _agentService.clearCache();
  }

  /// Disable MCP tool for agent
  Future<void> disableMCPTool(String agentId, String serverId) async {
    await _configService.disableMCPToolForAgent(agentId, serverId);
    await _serverManager.stopMCPServer(serverId);
    _agentService.clearCache();
  }

  /// Get available GitHub MCP tools
  Future<List<MCPCatalogEntry>> getAvailableGitHubMCPTools({
    String? searchQuery,
    List<String>? tags,
    bool featuredOnly = false,
  }) async {
    return _configService.getAvailableGitHubMCPTools(
      searchQuery: searchQuery,
      tags: tags,
      featuredOnly: featuredOnly,
    );
  }

  /// Get installation status for MCP tools
  Future<Map<String, bool>> getMCPToolInstallationStatus(
    List<MCPCatalogEntry> catalogEntries,
  ) async {
    return _serverManager.getInstallationStatus(catalogEntries);
  }

  /// Install MCP tool
  Future<bool> installMCPTool(MCPCatalogEntry catalogEntry) async {
    return _serverManager.installMCPTool(catalogEntry);
  }

  /// Start MCP servers for agent
  Future<void> startAgentMCPServers(String agentId) async {
    await _serverManager.startAgentMCPServers(agentId);
  }

  /// Stop MCP servers for agent
  Future<void> stopAgentMCPServers(String agentId) async {
    await _serverManager.stopAgentMCPServers(agentId);
  }

  /// Get available MCP tools for agent
  Future<List<AvailableMCPTool>> getAgentMCPTools(String agentId) async {
    return _conversationService.getAvailableMCPTools(agentId);
  }

  /// Process message with MCP tools
  Future<BusinessResult<EnhancedMessage>> processMessageWithMCPTools({
    required String conversationId,
    required String content,
    required String modelId,
    required Agent agent,
    List<String> contextDocs = const [],
    Map<String, dynamic> metadata = const {},
  }) async {
    return _conversationService.processMessageWithMCPTools(
      conversationId: conversationId,
      content: content,
      modelId: modelId,
      agent: agent,
      contextDocs: contextDocs,
      metadata: metadata,
    );
  }

  /// Stream message processing with MCP tools
  Stream<EnhancedMessageChunk> streamMessageWithMCPTools({
    required String conversationId,
    required String content,
    required String modelId,
    required Agent agent,
    List<String> contextDocs = const [],
    Map<String, dynamic> metadata = const {},
  }) {
    return _conversationService.processMessageStreamWithMCPTools(
      conversationId: conversationId,
      content: content,
      modelId: modelId,
      agent: agent,
      contextDocs: contextDocs,
      metadata: metadata,
    );
  }

  /// Update agent MCP environment variables
  Future<void> updateAgentMCPEnvironment(
    String agentId,
    String serverId,
    Map<String, String> environmentVars,
  ) async {
    await _configService.updateAgentMCPEnvironment(
      agentId,
      serverId,
      environmentVars,
    );
    _agentService.clearCache();
  }

  /// Get agent's MCP configuration status
  Future<AgentMCPStatus> getAgentMCPStatus(String agentId) async {
    final configs = await _configService.getAgentMCPConfigs(agentId);
    final enabledConfigs = configs.where((c) => c.isEnabled).toList();
    final runningServers = _serverManager.getRunningServers();

    final enabledServerIds = enabledConfigs.map((c) => c.serverId).toSet();
    final runningServerIds = runningServers.map((s) => s.id).toSet();
    final activeServerIds = enabledServerIds.intersection(runningServerIds);

    return AgentMCPStatus(
      agentId: agentId,
      totalMCPTools: configs.length,
      enabledMCPTools: enabledConfigs.length,
      runningMCPTools: activeServerIds.length,
      mcpToolsHealthy: runningServers
          .where((s) => enabledServerIds.contains(s.id) && s.isHealthy)
          .length,
      lastMCPActivity: configs
          .map((c) => c.lastUsed)
          .where((date) => date != null)
          .cast<DateTime>()
          .fold<DateTime?>(null, (latest, date) =>
              latest == null || date.isAfter(latest) ? date : latest),
    );
  }

  /// Cleanup resources
  void dispose() {
    _serverManager.cleanup();
    _agentService.clearCache();
  }
}

/// Status information for agent's MCP configuration
class AgentMCPStatus {
  final String agentId;
  final int totalMCPTools;
  final int enabledMCPTools;
  final int runningMCPTools;
  final int mcpToolsHealthy;
  final DateTime? lastMCPActivity;

  const AgentMCPStatus({
    required this.agentId,
    required this.totalMCPTools,
    required this.enabledMCPTools,
    required this.runningMCPTools,
    required this.mcpToolsHealthy,
    this.lastMCPActivity,
  });

  bool get allMCPToolsHealthy => mcpToolsHealthy == enabledMCPTools;
  bool get hasMCPTools => totalMCPTools > 0;
  bool get hasEnabledMCPTools => enabledMCPTools > 0;
  bool get hasRunningMCPTools => runningMCPTools > 0;

  double get mcpHealthPercentage {
    if (enabledMCPTools == 0) return 1.0;
    return mcpToolsHealthy / enabledMCPTools;
  }

  @override
  String toString() => 'AgentMCPStatus($agentId: $runningMCPTools/$enabledMCPTools tools running)';
}

// Riverpod Providers

final enhancedAgentServiceProvider = Provider<EnhancedAgentService>((ref) {
  return EnhancedAgentService();
});

final mcpIntegrationProvider = Provider<MCPIntegrationProvider>((ref) {
  final configService = ref.read(agentMCPConfigurationServiceProvider);
  final serverManager = ref.read(dynamicMCPServerManagerProvider);
  final agentService = ref.read(enhancedAgentServiceProvider);

  // Create enhanced conversation service
  final llmService = ref.read(unifiedLLMServiceProvider);
  final toolCallParser = LLMToolCallParser();
  final mcpBridge = ref.read(mcpBridgeServiceProvider);
  final contextService = ref.read(contextMCPResourceServiceProvider);
  final promptService = ref.read(agentContextPromptServiceProvider);

  final conversationService = EnhancedConversationService(
    llmService: llmService,
    agentMCPService: configService,
    mcpServerManager: serverManager,
    toolCallParser: toolCallParser,
    mcpBridge: mcpBridge,
    contextService: contextService,
    promptService: promptService,
  );

  final provider = MCPIntegrationProvider(
    configService,
    serverManager,
    conversationService,
    agentService,
  );

  ref.onDispose(() => provider.dispose());
  return provider;
});

/// Provider for enhanced agent
final enhancedAgentProvider = FutureProvider.family<EnhancedAgent, Agent>((ref, agent) async {
  final integrationProvider = ref.read(mcpIntegrationProvider);
  return integrationProvider.getEnhancedAgent(agent);
});

/// Provider for agent MCP status
final agentMCPStatusProvider = FutureProvider.family<AgentMCPStatus, String>((ref, agentId) async {
  final integrationProvider = ref.read(mcpIntegrationProvider);
  return integrationProvider.getAgentMCPStatus(agentId);
});

/// Provider for available GitHub MCP tools
final availableGitHubMCPToolsWithSearchProvider = FutureProvider.family<List<MCPCatalogEntry>, String?>((ref, searchQuery) async {
  final integrationProvider = ref.read(mcpIntegrationProvider);
  return integrationProvider.getAvailableGitHubMCPTools(searchQuery: searchQuery);
});

/// Provider for agent's available MCP tools
final agentAvailableMCPToolsProvider = FutureProvider.family<List<AvailableMCPTool>, String>((ref, agentId) async {
  final integrationProvider = ref.read(mcpIntegrationProvider);
  return integrationProvider.getAgentMCPTools(agentId);
});