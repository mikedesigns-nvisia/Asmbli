// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_server.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MCPServer _$MCPServerFromJson(Map<String, dynamic> json) => MCPServer(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      command: json['command'] as String,
      args:
          (json['args'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      isRunning: json['isRunning'] as bool? ?? false,
      autoStart: json['autoStart'] as bool? ?? false,
      category: json['category'] as String? ?? 'custom',
      isOfficial: json['isOfficial'] as bool? ?? false,
      iconUrl: json['iconUrl'] as String?,
      version: json['version'] as String?,
      lastStarted: json['lastStarted'] == null
          ? null
          : DateTime.parse(json['lastStarted'] as String),
      installedAt: json['installedAt'] == null
          ? null
          : DateTime.parse(json['installedAt'] as String),
    );

Map<String, dynamic> _$MCPServerToJson(MCPServer instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'command': instance.command,
      'args': instance.args,
      'isRunning': instance.isRunning,
      'autoStart': instance.autoStart,
      'category': instance.category,
      'isOfficial': instance.isOfficial,
      'iconUrl': instance.iconUrl,
      'version': instance.version,
      'lastStarted': instance.lastStarted?.toIso8601String(),
      'installedAt': instance.installedAt?.toIso8601String(),
    };

AgentConnection _$AgentConnectionFromJson(Map<String, dynamic> json) =>
    AgentConnection(
      agentId: json['agentId'] as String,
      agentName: json['agentName'] as String,
      connectedServerIds: (json['connectedServerIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      lastUpdated: json['lastUpdated'] == null
          ? null
          : DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$AgentConnectionToJson(AgentConnection instance) =>
    <String, dynamic>{
      'agentId': instance.agentId,
      'agentName': instance.agentName,
      'connectedServerIds': instance.connectedServerIds,
      'lastUpdated': instance.lastUpdated?.toIso8601String(),
    };
