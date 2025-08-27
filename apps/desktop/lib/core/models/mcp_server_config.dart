/// MCP Server Configuration Model
class MCPServerConfig {
  final String id;
  final String name;
  final String command;
  final List<String> args;
  final Map<String, String>? env;
  final bool enabled;
  final DateTime? lastUsed;
  final String? description;
  final List<String> capabilities;

  const MCPServerConfig({
    required this.id,
    required this.name,
    required this.command,
    required this.args,
    this.env,
    this.enabled = true,
    this.lastUsed,
    this.description,
    this.capabilities = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'command': command,
      'args': args,
      'env': env,
      'enabled': enabled,
      'lastUsed': lastUsed?.toIso8601String(),
      'description': description,
      'capabilities': capabilities,
    };
  }

  factory MCPServerConfig.fromJson(Map<String, dynamic> json) {
    return MCPServerConfig(
      id: json['id'],
      name: json['name'],
      command: json['command'],
      args: List<String>.from(json['args']),
      env: json['env']?.cast<String, String>(),
      enabled: json['enabled'] ?? true,
      lastUsed: json['lastUsed'] != null ? DateTime.parse(json['lastUsed']) : null,
      description: json['description'],
      capabilities: List<String>.from(json['capabilities'] ?? []),
    );
  }
}