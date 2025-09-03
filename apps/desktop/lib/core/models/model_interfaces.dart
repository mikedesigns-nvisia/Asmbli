import 'dart:async';

/// Core model management interfaces and data structures
library model_interfaces;

/// Abstract base class for all model providers
abstract class ModelProvider {
  /// Unique identifier for this provider
  String get id;
  
  /// Human-readable name for this provider
  String get name;
  
  /// Provider capabilities and limitations
  ModelCapabilities get capabilities;
  
  /// Provider configuration
  Map<String, dynamic> get config;
  
  /// Whether the provider is currently available
  bool get isAvailable;
  
  /// Initialize the provider
  Future<void> initialize();
  
  /// Test connection to the provider
  Future<bool> testConnection();
  
  /// Complete a text generation request
  Future<ModelResponse> complete(ModelRequest request);
  
  /// Stream a text generation request for real-time responses
  Stream<String> stream(ModelRequest request);
  
  /// Generate embeddings for text
  Future<List<double>> embed(String text);
  
  /// Get available models from this provider
  Future<List<ModelInfo>> getAvailableModels();
  
  /// Health check for the provider
  Future<ProviderHealth> healthCheck();
  
  /// Dispose of any resources
  Future<void> dispose();
}

/// Request object for model completion
class ModelRequest {
  final List<Message> messages;
  final String? model;
  final double temperature;
  final int maxTokens;
  final double topP;
  final List<String>? stop;
  final Map<String, dynamic>? tools;
  final String? systemPrompt;
  final Map<String, dynamic> metadata;

  const ModelRequest({
    required this.messages,
    this.model,
    this.temperature = 0.7,
    this.maxTokens = 1000,
    this.topP = 1.0,
    this.stop,
    this.tools,
    this.systemPrompt,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'messages': messages.map((m) => m.toJson()).toList(),
      'model': model,
      'temperature': temperature,
      'max_tokens': maxTokens,
      'top_p': topP,
      'stop': stop,
      'tools': tools,
      'system_prompt': systemPrompt,
      'metadata': metadata,
    };
  }

  factory ModelRequest.fromJson(Map<String, dynamic> json) {
    return ModelRequest(
      messages: (json['messages'] as List)
          .map((m) => Message.fromJson(m))
          .toList(),
      model: json['model'],
      temperature: json['temperature']?.toDouble() ?? 0.7,
      maxTokens: json['max_tokens'] ?? 1000,
      topP: json['top_p']?.toDouble() ?? 1.0,
      stop: json['stop']?.cast<String>(),
      tools: json['tools'],
      systemPrompt: json['system_prompt'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  ModelRequest copyWith({
    List<Message>? messages,
    String? model,
    double? temperature,
    int? maxTokens,
    double? topP,
    List<String>? stop,
    Map<String, dynamic>? tools,
    String? systemPrompt,
    Map<String, dynamic>? metadata,
  }) {
    return ModelRequest(
      messages: messages ?? this.messages,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      topP: topP ?? this.topP,
      stop: stop ?? this.stop,
      tools: tools ?? this.tools,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Response from model completion
class ModelResponse {
  final String content;
  final Usage usage;
  final String? model;
  final String? finishReason;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final Duration responseTime;

  ModelResponse({
    required this.content,
    required this.usage,
    this.model,
    this.finishReason,
    this.metadata = const {},
    DateTime? timestamp,
    Duration? responseTime,
  }) : timestamp = timestamp ?? DateTime.now(),
       responseTime = responseTime ?? Duration.zero;

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'usage': usage.toJson(),
      'model': model,
      'finish_reason': finishReason,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'response_time': responseTime.inMilliseconds,
    };
  }

  factory ModelResponse.fromJson(Map<String, dynamic> json) {
    return ModelResponse(
      content: json['content'],
      usage: Usage.fromJson(json['usage']),
      model: json['model'],
      finishReason: json['finish_reason'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      timestamp: DateTime.parse(json['timestamp']),
      responseTime: Duration(milliseconds: json['response_time'] ?? 0),
    );
  }
}

/// Message in a conversation
class Message {
  final String role;
  final String content;
  final String? name;
  final Map<String, dynamic>? toolCalls;
  final String? toolCallId;

  const Message({
    required this.role,
    required this.content,
    this.name,
    this.toolCalls,
    this.toolCallId,
  });

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'name': name,
      'tool_calls': toolCalls,
      'tool_call_id': toolCallId,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      role: json['role'],
      content: json['content'],
      name: json['name'],
      toolCalls: json['tool_calls'],
      toolCallId: json['tool_call_id'],
    );
  }

  /// Create a user message
  factory Message.user(String content) {
    return Message(role: 'user', content: content);
  }

  /// Create an assistant message
  factory Message.assistant(String content) {
    return Message(role: 'assistant', content: content);
  }

  /// Create a system message
  factory Message.system(String content) {
    return Message(role: 'system', content: content);
  }
}

/// Token usage information
class Usage {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final double totalCost;
  final Map<String, dynamic> breakdown;

  Usage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalCost,
    this.breakdown = const {},
  }) : totalTokens = promptTokens + completionTokens;

  Map<String, dynamic> toJson() {
    return {
      'prompt_tokens': promptTokens,
      'completion_tokens': completionTokens,
      'total_tokens': totalTokens,
      'total_cost': totalCost,
      'breakdown': breakdown,
    };
  }

  factory Usage.fromJson(Map<String, dynamic> json) {
    return Usage(
      promptTokens: json['prompt_tokens'] ?? 0,
      completionTokens: json['completion_tokens'] ?? 0,
      totalCost: json['total_cost']?.toDouble() ?? 0.0,
      breakdown: Map<String, dynamic>.from(json['breakdown'] ?? {}),
    );
  }

  /// Create usage for free models
  factory Usage.free({int promptTokens = 0, int completionTokens = 0}) {
    return Usage(
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      totalCost: 0.0,
    );
  }
}

/// Model capabilities and limitations
class ModelCapabilities {
  final bool supportsStreaming;
  final bool supportsTools;
  final bool supportsVision;
  final bool supportsEmbeddings;
  final int maxTokens;
  final int contextWindow;
  final List<String> supportedLanguages;
  final ModelType type;
  final double costPerInputToken;
  final double costPerOutputToken;

  const ModelCapabilities({
    this.supportsStreaming = true,
    this.supportsTools = false,
    this.supportsVision = false,
    this.supportsEmbeddings = false,
    this.maxTokens = 4096,
    this.contextWindow = 4096,
    this.supportedLanguages = const ['en'],
    this.type = ModelType.text,
    this.costPerInputToken = 0.0,
    this.costPerOutputToken = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'supports_streaming': supportsStreaming,
      'supports_tools': supportsTools,
      'supports_vision': supportsVision,
      'supports_embeddings': supportsEmbeddings,
      'max_tokens': maxTokens,
      'context_window': contextWindow,
      'supported_languages': supportedLanguages,
      'type': type.name,
      'cost_per_input_token': costPerInputToken,
      'cost_per_output_token': costPerOutputToken,
    };
  }

  factory ModelCapabilities.fromJson(Map<String, dynamic> json) {
    return ModelCapabilities(
      supportsStreaming: json['supports_streaming'] ?? true,
      supportsTools: json['supports_tools'] ?? false,
      supportsVision: json['supports_vision'] ?? false,
      supportsEmbeddings: json['supports_embeddings'] ?? false,
      maxTokens: json['max_tokens'] ?? 4096,
      contextWindow: json['context_window'] ?? 4096,
      supportedLanguages: List<String>.from(json['supported_languages'] ?? ['en']),
      type: ModelType.values.byName(json['type'] ?? 'text'),
      costPerInputToken: json['cost_per_input_token']?.toDouble() ?? 0.0,
      costPerOutputToken: json['cost_per_output_token']?.toDouble() ?? 0.0,
    );
  }
}

/// Information about a specific model
class ModelInfo {
  final String id;
  final String name;
  final String description;
  final ModelCapabilities capabilities;
  final String providerId;
  final bool isLocal;
  final DateTime? lastUpdated;
  final Map<String, dynamic> metadata;

  const ModelInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.capabilities,
    required this.providerId,
    this.isLocal = false,
    this.lastUpdated,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'capabilities': capabilities.toJson(),
      'provider_id': providerId,
      'is_local': isLocal,
      'last_updated': lastUpdated?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    return ModelInfo(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      capabilities: ModelCapabilities.fromJson(json['capabilities']),
      providerId: json['provider_id'],
      isLocal: json['is_local'] ?? false,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'])
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

/// Health status of a model provider
class ProviderHealth {
  final bool isHealthy;
  final double latency;
  final String status;
  final String? error;
  final DateTime lastChecked;
  final Map<String, dynamic> details;

  ProviderHealth({
    required this.isHealthy,
    required this.latency,
    required this.status,
    this.error,
    DateTime? lastChecked,
    this.details = const {},
  }) : lastChecked = lastChecked ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'is_healthy': isHealthy,
      'latency': latency,
      'status': status,
      'error': error,
      'last_checked': lastChecked.toIso8601String(),
      'details': details,
    };
  }

  factory ProviderHealth.fromJson(Map<String, dynamic> json) {
    return ProviderHealth(
      isHealthy: json['is_healthy'],
      latency: json['latency']?.toDouble() ?? 0.0,
      status: json['status'],
      error: json['error'],
      lastChecked: DateTime.parse(json['last_checked']),
      details: Map<String, dynamic>.from(json['details'] ?? {}),
    );
  }

  /// Create healthy status
  factory ProviderHealth.healthy({double latency = 0.0}) {
    return ProviderHealth(
      isHealthy: true,
      latency: latency,
      status: 'healthy',
    );
  }

  /// Create unhealthy status
  factory ProviderHealth.unhealthy(String error, {double latency = 0.0}) {
    return ProviderHealth(
      isHealthy: false,
      latency: latency,
      status: 'unhealthy',
      error: error,
    );
  }
}

/// Types of models
enum ModelType {
  text,
  chat,
  code,
  embedding,
  multimodal,
  image,
  audio,
}

/// Provider types
enum ProviderType {
  openai,
  anthropic,
  ollama,
  huggingface,
  cohere,
  custom,
}

/// Model selection strategy
enum ModelSelectionStrategy {
  cheapest,
  fastest,
  mostCapable,
  roundRobin,
  custom,
}

/// Base exception for model-related errors
abstract class ModelException implements Exception {
  final String message;
  final String? providerId;
  final String? modelId;
  final dynamic originalError;

  const ModelException(
    this.message, {
    this.providerId,
    this.modelId,
    this.originalError,
  });

  @override
  String toString() {
    final buffer = StringBuffer('ModelException: $message');
    if (providerId != null) {
      buffer.write(' (provider: $providerId)');
    }
    if (modelId != null) {
      buffer.write(' (model: $modelId)');
    }
    if (originalError != null) {
      buffer.write(' (caused by: $originalError)');
    }
    return buffer.toString();
  }
}

/// Exception for provider initialization failures
class ProviderInitializationException extends ModelException {
  const ProviderInitializationException(
    super.message, {
    super.providerId,
    super.originalError,
  });
}

/// Exception for model completion failures
class ModelCompletionException extends ModelException {
  final ModelRequest? request;

  const ModelCompletionException(
    super.message, {
    super.providerId,
    super.modelId,
    super.originalError,
    this.request,
  });
}

/// Exception for connection failures
class ProviderConnectionException extends ModelException {
  const ProviderConnectionException(
    super.message, {
    super.providerId,
    super.originalError,
  });
}

/// Exception for quota/rate limit exceeded
class QuotaExceededException extends ModelException {
  final DateTime? retryAfter;

  const QuotaExceededException(
    super.message, {
    super.providerId,
    super.originalError,
    this.retryAfter,
  });
}

/// Constants for the model system
class ModelConstants {
  // Default model IDs
  static const String defaultGPTModel = 'gpt-3.5-turbo';
  static const String defaultClaudeModel = 'claude-3-haiku-20240307';
  static const String defaultOllamaModel = 'llama2';

  // Token limits
  static const int defaultMaxTokens = 1000;
  static const int maxContextWindow = 32000;

  // Pricing (per 1M tokens)
  static const double gpt35TurboInputPrice = 0.50;
  static const double gpt35TurboOutputPrice = 1.50;
  static const double gpt4InputPrice = 30.0;
  static const double gpt4OutputPrice = 60.0;
  static const double claudeHaikuInputPrice = 0.25;
  static const double claudeHaikuOutputPrice = 1.25;

  // Timeouts
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration streamTimeout = Duration(minutes: 5);
  static const Duration healthCheckTimeout = Duration(seconds: 10);

  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);
}