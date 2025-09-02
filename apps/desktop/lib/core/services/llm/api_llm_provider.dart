import 'llm_provider.dart';
import '../claude_api_service.dart';
import '../../models/model_config.dart';

/// API-based LLM provider (Claude, GPT, etc.)
class ApiLLMProvider extends LLMProvider {
  final ModelConfig _modelConfig;
  final ClaudeApiService _apiService;

  ApiLLMProvider(this._modelConfig, this._apiService);

  @override
  String get name => '${_modelConfig.provider} (${_modelConfig.name})';

  @override
  ModelConfig get modelConfig => _modelConfig;

  @override
  Future<bool> get isAvailable async {
    return _modelConfig.isConfigured && _modelConfig.apiKey.isNotEmpty;
  }

  @override
  ModelCapabilities get capabilities {
    return ModelCapabilities(
      supportsStreaming: true,
      supportsSystemPrompts: true,
      maxContextLength: _getContextLength(),
      capabilities: ['reasoning', 'code', 'general', 'analysis'],
      isLocal: false,
    );
  }

  int _getContextLength() {
    final model = _modelConfig.model.toLowerCase();
    
    if (model.contains('claude-3-5-sonnet')) {
      return 200000; // 200K context
    } else if (model.contains('claude-3')) {
      return 100000; // 100K context  
    } else if (model.contains('gpt-4')) {
      return 128000; // 128K context
    } else {
      return 8192; // Default fallback
    }
  }

  @override
  Future<void> initialize() async {
    // API providers don't need initialization
    // Connection is established per request
  }

  @override
  Future<LLMResponse> chat(String message, ChatContext context) async {
    if (!await isAvailable) {
      throw LLMProviderException(
        'API provider not available. Check API key configuration.',
        providerName: name,
      );
    }

    try {
      final response = await _apiService.sendMessage(
        message: message,
        apiKey: _modelConfig.apiKey,
        model: _modelConfig.model,
        systemPrompt: context.systemPrompt,
        conversationHistory: context.messages,
        temperature: 0.7,
        maxTokens: 4096,
      );

      return LLMResponse.fromClaudeResponse(response);
    } catch (e) {
      if (e is ClaudeApiException) {
        throw LLMProviderException(
          'API request failed: ${e.message}',
          providerName: name,
          originalError: e,
        );
      } else {
        throw LLMProviderException(
          'Unexpected error: $e',
          providerName: name,
          originalError: e,
        );
      }
    }
  }

  @override
  Stream<String> chatStream(String message, ChatContext context) async* {
    if (!await isAvailable) {
      throw LLMProviderException(
        'API provider not available. Check API key configuration.',
        providerName: name,
      );
    }

    try {
      yield* _apiService.streamMessage(
        message: message,
        apiKey: _modelConfig.apiKey,
        model: _modelConfig.model,
        systemPrompt: context.systemPrompt,
        conversationHistory: context.messages,
        temperature: 0.7,
        maxTokens: 4096,
      );
    } catch (e) {
      if (e is ClaudeApiException) {
        throw LLMProviderException(
          'API streaming request failed: ${e.message}',
          providerName: name,
          originalError: e,
        );
      } else {
        throw LLMProviderException(
          'Unexpected streaming error: $e',
          providerName: name,
          originalError: e,
        );
      }
    }
  }

  @override
  Future<bool> testConnection() async {
    try {
      if (!await isAvailable) {
        return false;
      }

      // Use existing API key test method
      return await _apiService.testApiKey(_modelConfig.apiKey);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    // API providers don't need explicit disposal
    // HTTP connections are managed by Dio
  }
}