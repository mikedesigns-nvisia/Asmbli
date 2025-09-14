import 'package:json_annotation/json_annotation.dart';

part 'mcp_server.g.dart';

@JsonSerializable()
class MCPServer {
  final String id;
  final String name;
  final String description;
  final String command;
  final List<String> args;
  final bool isRunning;
  final bool autoStart;
  final String category;
  final bool isOfficial;
  final String? iconUrl;
  final String? version;
  final List<String> capabilities;
  final DateTime? lastStarted;
  final DateTime? installedAt;

  const MCPServer({
    required this.id,
    required this.name,
    required this.description,
    required this.command,
    this.args = const [],
    this.isRunning = false,
    this.autoStart = false,
    this.category = 'custom',
    this.isOfficial = false,
    this.iconUrl,
    this.version,
    this.capabilities = const [],
    this.lastStarted,
    this.installedAt,
  });

  factory MCPServer.fromJson(Map<String, dynamic> json) =>
      _$MCPServerFromJson(json);

  Map<String, dynamic> toJson() => _$MCPServerToJson(this);

  MCPServer copyWith({
    String? id,
    String? name,
    String? description,
    String? command,
    List<String>? args,
    bool? isRunning,
    bool? autoStart,
    String? category,
    bool? isOfficial,
    String? iconUrl,
    String? version,
    List<String>? capabilities,
    DateTime? lastStarted,
    DateTime? installedAt,
  }) {
    return MCPServer(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      command: command ?? this.command,
      args: args ?? this.args,
      isRunning: isRunning ?? this.isRunning,
      autoStart: autoStart ?? this.autoStart,
      category: category ?? this.category,
      isOfficial: isOfficial ?? this.isOfficial,
      iconUrl: iconUrl ?? this.iconUrl,
      version: version ?? this.version,
      capabilities: capabilities ?? this.capabilities,
      lastStarted: lastStarted ?? this.lastStarted,
      installedAt: installedAt ?? this.installedAt,
    );
  }
}

@JsonSerializable()
class AgentConnection {
  final String agentId;
  final String agentName;
  final List<String> connectedServerIds;
  final DateTime? lastUpdated;

  const AgentConnection({
    required this.agentId,
    required this.agentName,
    required this.connectedServerIds,
    this.lastUpdated,
  });

  factory AgentConnection.fromJson(Map<String, dynamic> json) =>
      _$AgentConnectionFromJson(json);

  Map<String, dynamic> toJson() => _$AgentConnectionToJson(this);

  AgentConnection copyWith({
    String? agentId,
    String? agentName,
    List<String>? connectedServerIds,
    DateTime? lastUpdated,
  }) {
    return AgentConnection(
      agentId: agentId ?? this.agentId,
      agentName: agentName ?? this.agentName,
      connectedServerIds: connectedServerIds ?? this.connectedServerIds,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

enum MCPServerStatus {
  stopped,
  starting,
  running,
  stopping,
  error,
}

enum MCPServerCategory {
  official,
  community,
  custom,
}