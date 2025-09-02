import '../claude_api_service.dart';
import '../../models/model_config.dart';

/// Chat context for LLM interactions
class ChatContext {
  final List<Map<String, String>> messages;
  final String? systemPrompt;
  final Map<String, dynamic> metadata;

  const ChatContext({
    this.messages = const [],
    this.systemPrompt,
    this.metadata = const {},
  });

  factory ChatContext.fromMessages(List<dynamic> messages, {String? systemPrompt}) {
    final chatMessages = messages.map((msg) {
      return {
        'role': msg.role == 'user' ? 'user' : 'assistant',
        'content': msg.content.toString(),
      };
    }).toList();

    return ChatContext(
      messages: chatMessages,
      systemPrompt: systemPrompt,
    );
  }

  ChatContext copyWith({
    List<Map<String, String>>? messages,
    String? systemPrompt,
    Map<String, dynamic>? metadata,
  }) {
    return ChatContext(
      messages: messages ?? this.messages,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Response from LLM providers
class LLMResponse {
  final String content;
  final String modelUsed;
  final Map<String, dynamic> metadata;
  final TokenUsage? usage;

  const LLMResponse({
    required this.content,
    required this.modelUsed,
    this.metadata = const {},
    this.usage,
  });

  factory LLMResponse.fromClaudeResponse(ClaudeResponse claudeResponse) {
    return LLMResponse(
      content: claudeResponse.text,
      modelUsed: claudeResponse.model,
      usage: TokenUsage(
        inputTokens: claudeResponse.usage.inputTokens,
        outputTokens: claudeResponse.usage.outputTokens,
      ),
      metadata: {
        'stopReason': claudeResponse.stopReason,
        'id': claudeResponse.id,
      },
    );
  }
}

/// Token usage information
class TokenUsage {
  final int inputTokens;
  final int outputTokens;

  const TokenUsage({
    required this.inputTokens,
    required this.outputTokens,
  });

  int get totalTokens => inputTokens + outputTokens;

  double get estimatedCost {
    // Rough cost estimation (varies by model)
    return (inputTokens * 0.00001) + (outputTokens * 0.00003);
  }
}

/// Model capabilities and metadata
class ModelCapabilities {
  final bool supportsStreaming;
  final bool supportsSystemPrompts;
  final int maxContextLength;
  final List<String> capabilities;
  final bool isLocal;

  const ModelCapabilities({
    this.supportsStreaming = true,
    this.supportsSystemPrompts = true,
    this.maxContextLength = 4096,
    this.capabilities = const [],
    this.isLocal = false,
  });
}

/// Abstract LLM provider interface
abstract class LLMProvider {
  /// Get provider name
  String get name;
  
  /// Get model configuration
  ModelConfig get modelConfig;
  
  /// Check if the provider is available and ready
  Future<bool> get isAvailable;
  
  /// Get model capabilities
  ModelCapabilities get capabilities;

  /// Send a chat message and get response
  Future<LLMResponse> chat(String message, ChatContext context);

  /// Send a chat message and get streaming response
  Stream<String> chatStream(String message, ChatContext context);

  /// Test the provider connection
  Future<bool> testConnection();

  /// Initialize the provider
  Future<void> initialize();

  /// Dispose resources
  Future<void> dispose();
}

/// Exception thrown by LLM providers
class LLMProviderException implements Exception {
  final String message;
  final String? providerName;
  final dynamic originalError;

  const LLMProviderException(
    this.message, {
    this.providerName,
    this.originalError,
  });

  @override
  String toString() {
    final prefix = providerName != null ? '[$providerName] ' : '';
    return 'LLMProviderException: $prefix$message';
  }
}