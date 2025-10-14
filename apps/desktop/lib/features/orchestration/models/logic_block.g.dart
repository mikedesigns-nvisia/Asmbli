// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logic_block.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Position _$PositionFromJson(Map<String, dynamic> json) => Position(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );

Map<String, dynamic> _$PositionToJson(Position instance) => <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
    };

BlockConnection _$BlockConnectionFromJson(Map<String, dynamic> json) =>
    BlockConnection(
      id: json['id'] as String,
      sourceBlockId: json['sourceBlockId'] as String,
      targetBlockId: json['targetBlockId'] as String,
      sourcePin: json['sourcePin'] as String,
      targetPin: json['targetPin'] as String,
      type: $enumDecode(_$ConnectionTypeEnumMap, json['type']),
    );

Map<String, dynamic> _$BlockConnectionToJson(BlockConnection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sourceBlockId': instance.sourceBlockId,
      'targetBlockId': instance.targetBlockId,
      'sourcePin': instance.sourcePin,
      'targetPin': instance.targetPin,
      'type': _$ConnectionTypeEnumMap[instance.type]!,
    };

const _$ConnectionTypeEnumMap = {
  ConnectionType.execution: 'execution',
  ConnectionType.data: 'data',
};

LogicBlock _$LogicBlockFromJson(Map<String, dynamic> json) => LogicBlock(
      id: json['id'] as String,
      type: $enumDecode(_$LogicBlockTypeEnumMap, json['type']),
      label: json['label'] as String,
      position: Position.fromJson(json['position'] as Map<String, dynamic>),
      properties: json['properties'] as Map<String, dynamic>? ?? const {},
      mcpToolIds: (json['mcpToolIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$LogicBlockToJson(LogicBlock instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$LogicBlockTypeEnumMap[instance.type]!,
      'label': instance.label,
      'position': instance.position.toJson(),
      'properties': instance.properties,
      'mcpToolIds': instance.mcpToolIds,
    };

const _$LogicBlockTypeEnumMap = {
  LogicBlockType.goal: 'goal',
  LogicBlockType.context: 'context',
  LogicBlockType.gateway: 'gateway',
  LogicBlockType.reasoning: 'reasoning',
  LogicBlockType.fallback: 'fallback',
  LogicBlockType.trace: 'trace',
  LogicBlockType.exit: 'exit',
};

T $enumDecode<T>(
  Map<T, Object> enumValues,
  Object? source, {
  T? unknownValue,
}) {
  if (source == null) {
    throw ArgumentError(
      'A value must be provided. Supported values: '
      '${enumValues.values.join(', ')}',
    );
  }

  return enumValues.entries.singleWhere(
    (e) => e.value == source,
    orElse: () {
      if (unknownValue == null) {
        throw ArgumentError(
          '`$source` is not one of the supported values: '
          '${enumValues.values.join(', ')}',
        );
      }
      return MapEntry(unknownValue, enumValues.values.first);
    },
  ).key;
}