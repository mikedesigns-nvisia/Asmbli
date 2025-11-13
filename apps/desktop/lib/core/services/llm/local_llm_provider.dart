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
          'hasMCPCapabilities': context.hasMCPCapabilities,
          'hasContextDocuments': context.hasContextDocuments,
          'mcpServersAvailable': context.mcpServers,
          'contextDocumentsCount': context.contextDocuments.length,
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

  /// Send a vision message with image (LLaVA models)
  Future<LLMResponse> visionChat(String message, String base64Image, ChatContext context) async {
    if (_modelConfig.ollamaModelId == null) {
      throw LLMProviderException(
        'Model ID not configured for local model',
        providerName: name,
      );
    }

    // Check if model supports vision
    if (!_supportsVision()) {
      throw LLMProviderException(
        'Model ${_modelConfig.ollamaModelId} does not support vision capabilities',
        providerName: name,
      );
    }

    try {
      // For LLaVA models, we need to use Ollama's vision API
      final response = await _ollamaService.generateVisionResponse(
        model: _modelConfig.ollamaModelId!,
        prompt: message,
        base64Image: base64Image,
        systemPrompt: context.systemPrompt,
      );

      return LLMResponse(
        content: response,
        modelUsed: _modelConfig.ollamaModelId!,
        usage: null, // Local models don't report token usage
        metadata: {
          'provider': 'local',
          'visionEnabled': true,
          'hasImage': true,
          'hasMCPCapabilities': context.hasMCPCapabilities,
          'hasContextDocuments': context.hasContextDocuments,
          'mcpServersAvailable': context.mcpServers,
          'contextDocumentsCount': context.contextDocuments.length,
        },
      );
    } catch (e) {
      throw LLMProviderException(
        'Failed to get vision response from local model: $e',
        providerName: name,
        originalError: e,
      );
    }
  }

  /// Check if the current model supports vision
  bool _supportsVision() {
    final modelId = _modelConfig.ollamaModelId?.toLowerCase() ?? '';
    
    // LLaVA models support vision
    final isLLaVA = modelId.contains('llava') || 
                    modelId.contains('llama-vision') ||
                    modelId.contains('bakllava');
    
    // Check capabilities list
    final hasVisionCapability = _modelConfig.capabilities.contains('vision');
    
    return isLLaVA || hasVisionCapability;
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