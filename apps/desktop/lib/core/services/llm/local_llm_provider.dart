import 'llm_provider.dart';
import '../ollama_service.dart';
import '../../models/model_config.dart';

/// Local LLM provider using Ollama
class LocalLLMProvider extends LLMProvider {
  final ModelConfig _modelConfig;
  final OllamaService _ollamaService;

  LocalLLMProvider(this._modelConfig, this._ollamaService);

  @override
  String get name => 'Local (${_modelConfig.name})';

  @override
  ModelConfig get modelConfig => _modelConfig;

  @override
  Future<bool> get isAvailable async {
    try {
      if (_modelConfig.status != ModelStatus.ready) {
        return false;
      }
      return await _ollamaService.isAvailable;
    } catch (e) {
      return false;
    }
  }

  @override
  ModelCapabilities get capabilities {
    return ModelCapabilities(
      supportsStreaming: true,
      supportsSystemPrompts: true,
      maxContextLength: 32768, // Most local models support decent context
      capabilities: _modelConfig.capabilities,
      isLocal: true,
    );
  }

  @override
  Future<void> initialize() async {
    // Ensure Ollama service is initialized
    await _ollamaService.initialize();
  }

  @override
  Future<LLMResponse> chat(String message, ChatContext context) async {
    if (_modelConfig.ollamaModelId == null) {
      throw LLMProviderException(
        'Model ID not configured for local model',
        providerName: name,
      );
    }

    try {
      final response = await _ollamaService.generateResponse(
        model: _modelConfig.ollamaModelId!,
        prompt: message,
        messages: context.messages,
        systemPrompt: context.systemPrompt,
      );

      return LLMResponse(
        content: response,
        modelUsed: _modelConfig.ollamaModelId!,
        metadata: {
          'provider': 'local',
          'modelName': _modelConfig.name,
        },
      );
    } catch (e) {
      throw LLMProviderException(
        'Failed to get response from local model: $e',
        providerName: name,
        originalError: e,
      );
    }
  }

  @override
  Stream<String> chatStream(String message, ChatContext context) async* {
    if (_modelConfig.ollamaModelId == null) {
      throw LLMProviderException(
        'Model ID not configured for local model',
        providerName: name,
      );
    }

    try {
      yield* _ollamaService.generateStreamingResponse(
        model: _modelConfig.ollamaModelId!,
        prompt: message,
        messages: context.messages,
        systemPrompt: context.systemPrompt,
      );
    } catch (e) {
      throw LLMProviderException(
        'Failed to get streaming response from local model: $e',
        providerName: name,
        originalError: e,
      );
    }
  }

  @override
  Future<bool> testConnection() async {
    try {
      if (!await isAvailable) {
        return false;
      }

      // Test with a simple prompt
      final response = await _ollamaService.generateResponse(
        model: _modelConfig.ollamaModelId!,
        prompt: 'Hello',
        systemPrompt: 'Respond with just "Hi" and nothing else.',
      );

      return response.trim().isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    // Local providers don't need explicit disposal
    // Ollama service manages its own lifecycle
  }
}