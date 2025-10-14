// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reasoning_workflow.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReasoningWorkflow _$ReasoningWorkflowFromJson(Map<String, dynamic> json) =>
    ReasoningWorkflow(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      blocks: (json['blocks'] as List<dynamic>)
          .map((e) => LogicBlock.fromJson(e as Map<String, dynamic>))
          .toList(),
      connections: (json['connections'] as List<dynamic>)
          .map((e) => BlockConnection.fromJson(e as Map<String, dynamic>))
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ReasoningWorkflowToJson(ReasoningWorkflow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'blocks': instance.blocks.map((e) => e.toJson()).toList(),
      'connections': instance.connections.map((e) => e.toJson()).toList(),
      'metadata': instance.metadata,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

ValidationResult _$ValidationResultFromJson(Map<String, dynamic> json) =>
    ValidationResult(
      isValid: json['isValid'] as bool,
      errors: (json['errors'] as List<dynamic>).map((e) => e as String).toList(),
      warnings:
          (json['warnings'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$ValidationResultToJson(ValidationResult instance) =>
    <String, dynamic>{
      'isValid': instance.isValid,
      'errors': instance.errors,
      'warnings': instance.warnings,
    };