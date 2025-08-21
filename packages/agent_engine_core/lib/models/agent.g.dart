// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AgentImpl _$$AgentImplFromJson(Map<String, dynamic> json) => _$AgentImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      capabilities: (json['capabilities'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      configuration: json['configuration'] as Map<String, dynamic>? ?? const {},
      status: $enumDecodeNullable(_$AgentStatusEnumMap, json['status']) ??
          AgentStatus.idle,
    );

Map<String, dynamic> _$$AgentImplToJson(_$AgentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'capabilities': instance.capabilities,
      'configuration': instance.configuration,
      'status': _$AgentStatusEnumMap[instance.status]!,
    };

const _$AgentStatusEnumMap = {
  AgentStatus.idle: 'idle',
  AgentStatus.active: 'active',
  AgentStatus.paused: 'paused',
  AgentStatus.error: 'error',
};
