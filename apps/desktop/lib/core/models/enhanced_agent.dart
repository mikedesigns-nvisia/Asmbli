import 'package:agent_engine_core/models/agent.dart';
import 'package:equatable/equatable.dart';
import 'agent_mcp_server_config.dart';

/// Enhanced Agent model with MCP tool configuration
/// Extends the core Agent model with GitHub MCP registry integration
class EnhancedAgent extends Equatable {
  final Agent baseAgent;
  final List<AgentMCPServerConfig> mcpConfigurations;
  final Map<String, String> mcpEnvironmentVars;
  final List<String> preferredMCPTools;
  final bool autoStartMCPServers;
  final int maxConcurrentMCPTools;
  final Duration mcpToolTimeout;
  final Map<String, dynamic> mcpMetadata;

  const EnhancedAgent({
    required this.baseAgent,
    this.mcpConfigurations = const [],
    this.mcpEnvironmentVars = const {},
    this.preferredMCPTools = const [],
    this.autoStartMCPServers = true,
    this.maxConcurrentMCPTools = 5,
    this.mcpToolTimeout = const Duration(seconds: 30),
    this.mcpMetadata = const {},
  });

  // Delegate base agent properties
  String get id => baseAgent.id;
  String get name => baseAgent.name;
  String get description => baseAgent.description;
  List<String> get capabilities => baseAgent.capabilities;
  Map<String, dynamic> get configuration => baseAgent.configuration;
  AgentStatus get status => baseAgent.status;

  /// Get enabled MCP configurations
  List<AgentMCPServerConfig> get enabledMCPConfigs =>
      mcpConfigurations.where((config) => config.isEnabled).toList();

  /// Get MCP server IDs that are enabled
  List<String> get enabledMCPServerIds =>
      enabledMCPConfigs.map((config) => config.serverId).toList();

  /// Check if agent has MCP tools configured
  bool get hasMCPTools => mcpConfigurations.isNotEmpty;

  /// Check if agent has any enabled MCP tools
  bool get hasEnabledMCPTools => enabledMCPConfigs.isNotEmpty;

  /// Get MCP configuration for a specific server
  AgentMCPServerConfig? getMCPConfig(String serverId) {
    try {
      return mcpConfigurations.firstWhere((config) => config.serverId == serverId);
    } catch (e) {
      return null;
    }
  }

  /// Check if a specific MCP server is enabled
  bool isMCPServerEnabled(String serverId) {
    final config = getMCPConfig(serverId);
    return config?.isEnabled ?? false;
  }

  /// Get environment variables for MCP servers
  Map<String, String> getMCPEnvironment([String? serverId]) {
    final baseEnv = Map<String, String>.from(mcpEnvironmentVars);

    if (serverId != null) {
      final config = getMCPConfig(serverId);
      if (config != null) {
        baseEnv.addAll(config.agentSpecificEnv);
        baseEnv.addAll(config.serverConfig.env ?? {});
      }
    }

    return baseEnv;
  }

  /// Get MCP tools sorted by priority
  List<AgentMCPServerConfig> get prioritizedMCPConfigs {
    final configs = List<AgentMCPServerConfig>.from(enabledMCPConfigs);
    configs.sort((a, b) {
      // Sort by priority (higher first), then by last used (more recent first)
      if (a.priority != b.priority) {
        return b.priority.compareTo(a.priority);
      }
      if (a.lastUsed != null && b.lastUsed != null) {
        return b.lastUsed!.compareTo(a.lastUsed!);
      } else if (a.lastUsed != null) {
        return -1;
      } else if (b.lastUsed != null) {
        return 1;
      }
      return a.serverConfig.name.compareTo(b.serverConfig.name);
    });
    return configs;
  }

  /// Get all capabilities including MCP tool capabilities
  List<String> get allCapabilities {
    final allCaps = List<String>.from(capabilities);

    for (final config in enabledMCPConfigs) {
      allCaps.addAll(config.serverConfig.capabilities ?? []);
    }

    return allCaps.toSet().toList(); // Remove duplicates
  }

  /// Copy with updated MCP configurations
  EnhancedAgent copyWith({
    Agent? baseAgent,
    List<AgentMCPServerConfig>? mcpConfigurations,
    Map<String, String>? mcpEnvironmentVars,
    List<String>? preferredMCPTools,
    bool? autoStartMCPServers,
    int? maxConcurrentMCPTools,
    Duration? mcpToolTimeout,
    Map<String, dynamic>? mcpMetadata,
  }) {
    return EnhancedAgent(
      baseAgent: baseAgent ?? this.baseAgent,
      mcpConfigurations: mcpConfigurations ?? this.mcpConfigurations,
      mcpEnvironmentVars: mcpEnvironmentVars ?? this.mcpEnvironmentVars,
      preferredMCPTools: preferredMCPTools ?? this.preferredMCPTools,
      autoStartMCPServers: autoStartMCPServers ?? this.autoStartMCPServers,
      maxConcurrentMCPTools: maxConcurrentMCPTools ?? this.maxConcurrentMCPTools,
      mcpToolTimeout: mcpToolTimeout ?? this.mcpToolTimeout,
      mcpMetadata: mcpMetadata ?? this.mcpMetadata,
    );
  }

  /// Create enhanced agent from base agent
  factory EnhancedAgent.fromAgent(Agent agent) {
    return EnhancedAgent(baseAgent: agent);
  }

  /// Create enhanced agent with MCP configurations
  factory EnhancedAgent.withMCPTools({
    required Agent baseAgent,
    required List<AgentMCPServerConfig> mcpConfigurations,
    Map<String, String> mcpEnvironmentVars = const {},
    List<String> preferredMCPTools = const [],
    bool autoStartMCPServers = true,
  }) {
    return EnhancedAgent(
      baseAgent: baseAgent,
      mcpConfigurations: mcpConfigurations,
      mcpEnvironmentVars: mcpEnvironmentVars,
      preferredMCPTools: preferredMCPTools,
      autoStartMCPServers: autoStartMCPServers,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'baseAgent': baseAgent.toJson(),
      'mcpConfigurations': mcpConfigurations.map((config) => {
        'agentId': config.agentId,
        'serverId': config.serverId,
        'isEnabled': config.isEnabled,
        'priority': config.priority,
        'autoStart': config.autoStart,
        'lastUsed': config.lastUsed?.toIso8601String(),
        'agentSpecificEnv': config.agentSpecificEnv,
        'requiredCapabilities': config.requiredCapabilities,
      }).toList(),
      'mcpEnvironmentVars': mcpEnvironmentVars,
      'preferredMCPTools': preferredMCPTools,
      'autoStartMCPServers': autoStartMCPServers,
      'maxConcurrentMCPTools': maxConcurrentMCPTools,
      'mcpToolTimeout': mcpToolTimeout.inSeconds,
      'mcpMetadata': mcpMetadata,
    };
  }

  /// Create from JSON (simplified - would need full implementation)
  factory EnhancedAgent.fromJson(Map<String, dynamic> json) {
    return EnhancedAgent(
      baseAgent: Agent.fromJson(json['baseAgent'] as Map<String, dynamic>),
      mcpEnvironmentVars: Map<String, String>.from(
        json['mcpEnvironmentVars'] as Map<String, dynamic>? ?? {}
      ),
      preferredMCPTools: List<String>.from(
        json['preferredMCPTools'] as List<dynamic>? ?? []
      ),
      autoStartMCPServers: json['autoStartMCPServers'] as bool? ?? true,
      maxConcurrentMCPTools: json['maxConcurrentMCPTools'] as int? ?? 5,
      mcpToolTimeout: Duration(seconds: json['mcpToolTimeout'] as int? ?? 30),
      mcpMetadata: Map<String, dynamic>.from(
        json['mcpMetadata'] as Map<String, dynamic>? ?? {}
      ),
    );
  }

  @override
  List<Object?> get props => [
        baseAgent,
        mcpConfigurations,
        mcpEnvironmentVars,
        preferredMCPTools,
        autoStartMCPServers,
        maxConcurrentMCPTools,
        mcpToolTimeout,
        mcpMetadata,
      ];

  @override
  String toString() => 'EnhancedAgent(${baseAgent.name}, ${enabledMCPConfigs.length} MCP tools)';
}

/// Enhanced Agent service that manages MCP tool integration
class EnhancedAgentService {
  final Map<String, EnhancedAgent> _enhancedAgents = {};

  /// Get enhanced agent with MCP configurations
  Future<EnhancedAgent> getEnhancedAgent(
    Agent baseAgent,
    List<AgentMCPServerConfig> mcpConfigs,
  ) async {
    final cacheKey = baseAgent.id;

    if (_enhancedAgents.containsKey(cacheKey)) {
      // Update existing enhanced agent with new configurations
      return _enhancedAgents[cacheKey]!.copyWith(
        baseAgent: baseAgent,
        mcpConfigurations: mcpConfigs,
      );
    }

    // Create new enhanced agent
    final enhancedAgent = EnhancedAgent.withMCPTools(
      baseAgent: baseAgent,
      mcpConfigurations: mcpConfigs,
    );

    _enhancedAgents[cacheKey] = enhancedAgent;
    return enhancedAgent;
  }

  /// Update MCP configurations for an agent
  Future<EnhancedAgent> updateAgentMCPConfigs(
    String agentId,
    List<AgentMCPServerConfig> mcpConfigs,
  ) async {
    final existingAgent = _enhancedAgents[agentId];
    if (existingAgent != null) {
      final updatedAgent = existingAgent.copyWith(mcpConfigurations: mcpConfigs);
      _enhancedAgents[agentId] = updatedAgent;
      return updatedAgent;
    }

    throw Exception('Enhanced agent not found: $agentId');
  }

  /// Clear cache
  void clearCache() {
    _enhancedAgents.clear();
  }

  /// Get cached enhanced agent
  EnhancedAgent? getCachedEnhancedAgent(String agentId) {
    return _enhancedAgents[agentId];
  }
}