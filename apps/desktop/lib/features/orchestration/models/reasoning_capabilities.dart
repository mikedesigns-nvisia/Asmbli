import 'package:json_annotation/json_annotation.dart';

part 'reasoning_capabilities.g.dart';

/// Enhanced model capabilities for reasoning workflows
@JsonSerializable()
class ReasoningCapabilities {
  final bool reasoning;           // Can follow complex reasoning prompts
  final bool functionCalling;     // Supports structured function calls
  final bool structuredOutput;   // Can generate valid JSON/structured data
  final bool contextLength;      // Supports long context windows
  final bool streaming;          // Supports token-by-token streaming
  final int maxTokens;           // Maximum context length
  final double confidenceSupport; // How well it estimates confidence (0-1)
  final List<String> reasoningPatterns; // Supported patterns (CoT, ReAct, etc.)
  
  const ReasoningCapabilities({
    this.reasoning = false,
    this.functionCalling = false,
    this.structuredOutput = false,
    this.contextLength = false,
    this.streaming = true,
    this.maxTokens = 4096,
    this.confidenceSupport = 0.5,
    this.reasoningPatterns = const [],
  });
  
  factory ReasoningCapabilities.fromJson(Map<String, dynamic> json) => 
      _$ReasoningCapabilitiesFromJson(json);
  Map<String, dynamic> toJson() => _$ReasoningCapabilitiesToJson(this);
  
  /// Check if model supports visual reasoning flows
  bool get supportsReasoningFlow => reasoning || functionCalling || structuredOutput;
  
  /// Get optimal reasoning strategy for this model
  ReasoningStrategy get optimalStrategy {
    if (functionCalling) return ReasoningStrategy.functionCalling;
    if (structuredOutput) return ReasoningStrategy.structuredPrompts;
    if (reasoning) return ReasoningStrategy.promptEngineering;
    return ReasoningStrategy.basicChat;
  }
  
  /// Create capabilities for known models
  factory ReasoningCapabilities.forModel(String modelName) {
    final normalizedName = modelName.toLowerCase();
    
    // API models with function calling
    if (normalizedName.contains('gpt-4') || normalizedName.contains('claude-3')) {
      return const ReasoningCapabilities(
        reasoning: true,
        functionCalling: true,
        structuredOutput: true,
        contextLength: true,
        streaming: true,
        maxTokens: 128000,
        confidenceSupport: 0.8,
        reasoningPatterns: ['cot', 'react', 'tot', 'self_consistency'],
      );
    }
    
    // Good local reasoning models
    if (normalizedName.contains('llama3.1') || 
        normalizedName.contains('qwen2.5') ||
        normalizedName.contains('mistral-nemo')) {
      return const ReasoningCapabilities(
        reasoning: true,
        functionCalling: false,
        structuredOutput: true,
        contextLength: true,
        streaming: true,
        maxTokens: 32768,
        confidenceSupport: 0.6,
        reasoningPatterns: ['cot', 'react'],
      );
    }
    
    // Function calling local models
    if (normalizedName.contains('firefunction') || 
        normalizedName.contains('llama3.2')) {
      return const ReasoningCapabilities(
        reasoning: false,
        functionCalling: true,
        structuredOutput: true,
        contextLength: false,
        streaming: true,
        maxTokens: 8192,
        confidenceSupport: 0.7,
        reasoningPatterns: ['function_calling'],
      );
    }
    
    // Basic models
    return const ReasoningCapabilities(
      reasoning: false,
      functionCalling: false,
      structuredOutput: false,
      contextLength: false,
      streaming: true,
      maxTokens: 4096,
      confidenceSupport: 0.3,
      reasoningPatterns: ['basic_chat'],
    );
  }
  
  ReasoningCapabilities copyWith({
    bool? reasoning,
    bool? functionCalling,
    bool? structuredOutput,
    bool? contextLength,
    bool? streaming,
    int? maxTokens,
    double? confidenceSupport,
    List<String>? reasoningPatterns,
  }) {
    return ReasoningCapabilities(
      reasoning: reasoning ?? this.reasoning,
      functionCalling: functionCalling ?? this.functionCalling,
      structuredOutput: structuredOutput ?? this.structuredOutput,
      contextLength: contextLength ?? this.contextLength,
      streaming: streaming ?? this.streaming,
      maxTokens: maxTokens ?? this.maxTokens,
      confidenceSupport: confidenceSupport ?? this.confidenceSupport,
      reasoningPatterns: reasoningPatterns ?? this.reasoningPatterns,
    );
  }
}

/// Reasoning execution strategies based on model capabilities
enum ReasoningStrategy {
  @JsonValue('function_calling')
  functionCalling,    // Use native function calling with structured schemas
  
  @JsonValue('structured_prompts')
  structuredPrompts,  // Use JSON mode with validation
  
  @JsonValue('prompt_engineering')
  promptEngineering,  // Use carefully crafted prompts with parsing
  
  @JsonValue('basic_chat')
  basicChat,          // Simple chat mode with minimal reasoning
}

/// Result from reasoning capability detection
@JsonSerializable()
class CapabilityDetectionResult {
  final String modelName;
  final ReasoningCapabilities capabilities;
  final double confidenceScore;  // How confident we are in the detection
  final DateTime detectedAt;
  final Map<String, dynamic> testResults;
  
  const CapabilityDetectionResult({
    required this.modelName,
    required this.capabilities,
    required this.confidenceScore,
    required this.detectedAt,
    this.testResults = const {},
  });
  
  factory CapabilityDetectionResult.fromJson(Map<String, dynamic> json) => 
      _$CapabilityDetectionResultFromJson(json);
  Map<String, dynamic> toJson() => _$CapabilityDetectionResultToJson(this);
  
  bool get isReliable => confidenceScore > 0.7;
}