import 'package:equatable/equatable.dart';
import 'mcp_server_process.dart';

/// Configuration for MCP server specific to an agent
class AgentMCPServerConfig extends Equatable {
  final String agentId;
  final String serverId;
  final MCPServerConfig serverConfig;
  final bool isEnabled;
  final DateTime? lastUsed;
  final Map<String, String> agentSpecificEnv;
  final List<String> requiredCapabilities;
  final int priority;
  final bool autoStart;

  const AgentMCPServerConfig({
    required this.agentId,
    required this.serverId,
    required this.serverConfig,
    this.isEnabled = true,
    this.lastUsed,
    this.agentSpecificEnv = const {},
    this.requiredCapabilities = const [],
    this.priority = 0,
    this.autoStart = true,
  });

  AgentMCPServerConfig copyWith({
    String? agentId,
    String? serverId,
    MCPServerConfig? serverConfig,
    bool? isEnabled,
    DateTime? lastUsed,
    Map<String, String>? agentSpecificEnv,
    List<String>? requiredCapabilities,
    int? priority,
    bool? autoStart,
  }) {
    return AgentMCPServerConfig(
      agentId: agentId ?? this.agentId,
      serverId: serverId ?? this.serverId,
      serverConfig: serverConfig ?? this.serverConfig,
      isEnabled: isEnabled ?? this.isEnabled,
      lastUsed: lastUsed ?? this.lastUsed,
      agentSpecificEnv: agentSpecificEnv ?? this.agentSpecificEnv,
      requiredCapabilities: requiredCapabilities ?? this.requiredCapabilities,
      priority: priority ?? this.priority,
      autoStart: autoStart ?? this.autoStart,
    );
  }

  /// Alias for isEnabled (for backward compatibility)
  bool get enabled => isEnabled;

  /// Check if the configuration is complete and valid
  bool get isConfigured => serverConfig.command.isNotEmpty &&
                          (serverConfig.requiredEnvVars?.isEmpty ?? true ||
                           (serverConfig.requiredEnvVars?.keys.every((key) =>
                             (agentSpecificEnv?.containsKey(key) ?? false)) ?? true));

  @override
  List<Object?> get props => [
        agentId,
        serverId,
        serverConfig,
        isEnabled,
        lastUsed,
        agentSpecificEnv,
        requiredCapabilities,
        priority,
        autoStart,
      ];

  @override
  String toString() => 'AgentMCPServerConfig(agentId: $agentId, serverId: $serverId)';
}