// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reasoning_capabilities.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReasoningCapabilities _$ReasoningCapabilitiesFromJson(
        Map<String, dynamic> json) =>
    ReasoningCapabilities(
      reasoning: json['reasoning'] as bool? ?? false,
      functionCalling: json['functionCalling'] as bool? ?? false,
      structuredOutput: json['structuredOutput'] as bool? ?? false,
      contextLength: json['contextLength'] as bool? ?? false,
      streaming: json['streaming'] as bool? ?? true,
      maxTokens: json['maxTokens'] as int? ?? 4096,
      confidenceSupport: (json['confidenceSupport'] as num?)?.toDouble() ?? 0.5,
      reasoningPatterns: (json['reasoningPatterns'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ReasoningCapabilitiesToJson(
        ReasoningCapabilities instance) =>
    <String, dynamic>{
      'reasoning': instance.reasoning,
      'functionCalling': instance.functionCalling,
      'structuredOutput': instance.structuredOutput,
      'contextLength': instance.contextLength,
      'streaming': instance.streaming,
      'maxTokens': instance.maxTokens,
      'confidenceSupport': instance.confidenceSupport,
      'reasoningPatterns': instance.reasoningPatterns,
    };

CapabilityDetectionResult _$CapabilityDetectionResultFromJson(
        Map<String, dynamic> json) =>
    CapabilityDetectionResult(
      modelName: json['modelName'] as String,
      capabilities: ReasoningCapabilities.fromJson(
          json['capabilities'] as Map<String, dynamic>),
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      detectedAt: DateTime.parse(json['detectedAt'] as String),
      testResults: json['testResults'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$CapabilityDetectionResultToJson(
        CapabilityDetectionResult instance) =>
    <String, dynamic>{
      'modelName': instance.modelName,
      'capabilities': instance.capabilities.toJson(),
      'confidenceScore': instance.confidenceScore,
      'detectedAt': instance.detectedAt.toIso8601String(),
      'testResults': instance.testResults,
    };