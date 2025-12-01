import 'llm_provider.dart';
import '../claude_api_service.dart';
import '../openai_api_service.dart';
import '../google_api_service.dart';
import '../kimi_api_service.dart';
import '../../models/model_config.dart';

/// API-based LLM provider (Claude, GPT, etc.)
class ApiLLMProvider extends LLMProvider {
  final ModelConfig _modelConfig;
  final ClaudeApiService? _claudeApiService;
  final OpenAIApiService? _openaiApiService;
  final GoogleApiService? _googleApiService;
  final KimiApiService? _kimiApiService;

  ApiLLMProvider(
    this._modelConfig, 
    this._claudeApiService, [
    this._openaiApiService,
    this._googleApiService,
    this._kimiApiService,
  ]);

  @override
  String get name => '${_modelConfig.provider} (${_modelConfig.name})';

  @override
  ModelConfig get modelConfig => _modelConfig;

  String get modelId => _modelConfig.id;

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
      LLMResponse llmResponse;
      
      if (_isClaudeModel() && _claudeApiService != null) {
        final response = await _claudeApiService!.sendMessage(
          message: message,
          apiKey: _modelConfig.apiKey,
          model: _modelConfig.model,
          systemPrompt: context.systemPrompt,
          conversationHistory: context.messages,
          temperature: 0.7,
          maxTokens: 4096,
        );
        llmResponse = LLMResponse.fromClaudeResponse(response);
      } else if (_isOpenAIModel() && _openaiApiService != null) {
        final response = await _openaiApiService!.sendMessage(
          message: message,
          apiKey: _modelConfig.apiKey,
          model: _modelConfig.model,
          systemPrompt: context.systemPrompt,
          conversationHistory: context.messages,
          temperature: 0.7,
          maxTokens: 4096,
        );
        llmResponse = LLMResponse(
          content: response.content,
          modelUsed: response.model,
          usage: TokenUsage(
            inputTokens: response.usage.promptTokens,
            outputTokens: response.usage.completionTokens,
          ),
          metadata: {'provider': 'openai'},
        );
      } else if (_isGoogleModel() && _googleApiService != null) {
        final response = await _googleApiService!.sendMessage(
          message: message,
          apiKey: _modelConfig.apiKey,
          model: _modelConfig.model,
          systemPrompt: context.systemPrompt,
          conversationHistory: context.messages,
          temperature: 0.7,
          maxTokens: 4096,
        );
        llmResponse = LLMResponse(
          content: response.content,
          modelUsed: response.model,
          usage: response.usageMetadata != null 
              ? TokenUsage(
                  inputTokens: response.usageMetadata!.promptTokenCount,
                  outputTokens: response.usageMetadata!.candidatesTokenCount,
                )
              : null,
          metadata: {'provider': 'google'},
        );
      } else if (_isKimiModel() && _kimiApiService != null) {
        final response = await _kimiApiService!.sendMessage(
          message: message,
          apiKey: _modelConfig.apiKey,
          model: _modelConfig.model,
          systemPrompt: context.systemPrompt,
          conversationHistory: context.messages,
          temperature: 0.7,
          maxTokens: 4096,
        );
        llmResponse = LLMResponse(
          content: response.content,
          modelUsed: response.model,
          usage: TokenUsage(
            inputTokens: response.usage.promptTokens,
            outputTokens: response.usage.completionTokens,
          ),
          metadata: {'provider': 'kimi'},
        );
      } else {
        throw LLMProviderException(
          'Unsupported model provider: ${_modelConfig.provider}',
          providerName: name,
        );
      }
      
      // Enhance metadata with context information
      return LLMResponse(
        content: llmResponse.content,
        modelUsed: llmResponse.modelUsed,
        usage: llmResponse.usage,
        metadata: {
          ...llmResponse.metadata,
          'provider': 'api',
          'hasMCPCapabilities': context.hasMCPCapabilities,
          'hasContextDocuments': context.hasContextDocuments,
          'mcpServersAvailable': context.mcpServers,
          'contextDocumentsCount': context.contextDocuments.length,
        },
      );
    } catch (e) {
      if (e is ClaudeApiException || e is OpenAIApiException || e is GoogleApiException || e is KimiApiException) {
        throw LLMProviderException(
          'API request failed: ${e.toString()}',
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
      if (_isClaudeModel() && _claudeApiService != null) {
        yield* _claudeApiService!.streamMessage(
          message: message,
          apiKey: _modelConfig.apiKey,
          model: _modelConfig.model,
          systemPrompt: context.systemPrompt,
          conversationHistory: context.messages,
          temperature: 0.7,
          maxTokens: 4096,
        );
      } else if (_isOpenAIModel() && _openaiApiService != null) {
        yield* _openaiApiService!.streamMessage(
          message: message,
          apiKey: _modelConfig.apiKey,
          model: _modelConfig.model,
          systemPrompt: context.systemPrompt,
          conversationHistory: context.messages,
          temperature: 0.7,
          maxTokens: 4096,
        );
      } else if (_isGoogleModel() && _googleApiService != null) {
        yield* _googleApiService!.streamMessage(
          message: message,
          apiKey: _modelConfig.apiKey,
          model: _modelConfig.model,
          systemPrompt: context.systemPrompt,
          conversationHistory: context.messages,
          temperature: 0.7,
          maxTokens: 4096,
        );
      } else if (_isKimiModel() && _kimiApiService != null) {
        yield* _kimiApiService!.streamMessage(
          message: message,
          apiKey: _modelConfig.apiKey,
          model: _modelConfig.model,
          systemPrompt: context.systemPrompt,
          conversationHistory: context.messages,
          temperature: 0.7,
          maxTokens: 4096,
        );
      } else {
        throw LLMProviderException(
          'Unsupported streaming model provider: ${_modelConfig.provider}',
          providerName: name,
        );
      }
    } catch (e) {
      if (e is ClaudeApiException || e is OpenAIApiException || e is GoogleApiException || e is KimiApiException) {
        throw LLMProviderException(
          'API streaming request failed: ${e.toString()}',
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

  /// Send a vision message with image (Claude 3.5 Sonnet and GPT-4V)
  Future<LLMResponse> visionChat(String message, String base64Image, ChatContext context) async {
    if (!await isAvailable) {
      throw LLMProviderException(
        'API provider not available. Check API key configuration.',
        providerName: name,
      );
    }

    // Check if model supports vision
    if (!_supportsVision()) {
      throw LLMProviderException(
        'Model ${_modelConfig.model} does not support vision capabilities',
        providerName: name,
      );
    }

    try {
      if (_isClaudeModel()) {
        return await _handleClaudeVision(message, base64Image, context);
      } else if (_isOpenAIModel()) {
        return await _handleOpenAIVision(message, base64Image, context);
      } else if (_isGoogleModel()) {
        return await _handleGoogleVision(message, base64Image, context);
      } else {
        throw LLMProviderException(
          'Unsupported vision model: ${_modelConfig.model}',
          providerName: name,
        );
      }
    } catch (e) {
      if (e is ClaudeApiException || e is OpenAIApiException || e is GoogleApiException || e is KimiApiException) {
        throw LLMProviderException(
          'Vision API request failed: ${e.toString()}',
          providerName: name,
          originalError: e,
        );
      } else {
        throw LLMProviderException(
          'Unexpected vision error: $e',
          providerName: name,
          originalError: e,
        );
      }
    }
  }

  Future<LLMResponse> _handleClaudeVision(String message, String base64Image, ChatContext context) async {
    final response = await _claudeApiService!.sendVisionMessage(
      message: message,
      base64Image: base64Image,
      apiKey: _modelConfig.apiKey,
      model: _modelConfig.model,
      systemPrompt: context.systemPrompt,
      conversationHistory: context.messages,
      temperature: 0.7,
      maxTokens: 4096,
    );

    final llmResponse = LLMResponse.fromClaudeResponse(response);
    
    return LLMResponse(
      content: llmResponse.content,
      modelUsed: llmResponse.modelUsed,
      usage: llmResponse.usage,
      metadata: {
        ...llmResponse.metadata,
        'provider': 'claude',
        'visionEnabled': true,
        'hasImage': true,
        'hasMCPCapabilities': context.hasMCPCapabilities,
        'hasContextDocuments': context.hasContextDocuments,
        'mcpServersAvailable': context.mcpServers,
        'contextDocumentsCount': context.contextDocuments.length,
      },
    );
  }

  Future<LLMResponse> _handleOpenAIVision(String message, String base64Image, ChatContext context) async {
    final response = await _openaiApiService!.sendVisionMessage(
      message: message,
      base64Image: base64Image,
      apiKey: _modelConfig.apiKey,
      model: _modelConfig.model,
      systemPrompt: context.systemPrompt,
      conversationHistory: context.messages,
      temperature: 0.7,
      maxTokens: 4096,
    );

    return LLMResponse(
      content: response.content,
      modelUsed: response.model,
      usage: TokenUsage(
        inputTokens: response.usage.promptTokens,
        outputTokens: response.usage.completionTokens,
      ),
      metadata: {
        'provider': 'openai',
        'visionEnabled': true,
        'hasImage': true,
        'hasMCPCapabilities': context.hasMCPCapabilities,
        'hasContextDocuments': context.hasContextDocuments,
        'mcpServersAvailable': context.mcpServers,
        'contextDocumentsCount': context.contextDocuments.length,
      },
    );
  }

  Future<LLMResponse> _handleGoogleVision(String message, String base64Image, ChatContext context) async {
    final response = await _googleApiService!.sendVisionMessage(
      message: message,
      base64Image: base64Image,
      apiKey: _modelConfig.apiKey,
      model: _modelConfig.model,
      systemPrompt: context.systemPrompt,
      conversationHistory: context.messages,
      temperature: 0.7,
      maxTokens: 4096,
    );

    return LLMResponse(
      content: response.content,
      modelUsed: response.model,
      usage: response.usageMetadata != null 
          ? TokenUsage(
              inputTokens: response.usageMetadata!.promptTokenCount,
              outputTokens: response.usageMetadata!.candidatesTokenCount,
            )
          : null,
      metadata: {
        'provider': 'google',
        'visionEnabled': true,
        'hasImage': true,
        'hasMCPCapabilities': context.hasMCPCapabilities,
        'hasContextDocuments': context.hasContextDocuments,
        'mcpServersAvailable': context.mcpServers,
        'contextDocumentsCount': context.contextDocuments.length,
      },
    );
  }

  /// Check if the current model supports vision
  bool _supportsVision() {
    final model = _modelConfig.model.toLowerCase();
    
    // Claude 3.5 Sonnet and above support vision
    final claudeVision = model.contains('claude-3') && (
      model.contains('sonnet') || 
      model.contains('opus') ||
      model.contains('haiku')
    );
    
    // GPT-4 Vision models
    final gptVision = model.contains('gpt-4') && (
      model.contains('vision') ||
      model.contains('turbo') ||
      model.contains('preview')
    );
    
    // Google Gemini Vision models
    final geminiVision = model.contains('gemini') && (
      model.contains('vision') ||
      model.contains('pro-vision')
    );
    
    // Check capabilities list
    final hasVisionCapability = _modelConfig.capabilities.contains('vision');
    
    return claudeVision || gptVision || geminiVision || hasVisionCapability;
  }

  bool _isClaudeModel() {
    return _modelConfig.provider.toLowerCase().contains('claude') ||
           _modelConfig.model.toLowerCase().contains('claude');
  }

  bool _isOpenAIModel() {
    return _modelConfig.provider.toLowerCase().contains('openai') ||
           _modelConfig.model.toLowerCase().contains('gpt');
  }

  bool _isGoogleModel() {
    return _modelConfig.provider.toLowerCase().contains('google') ||
           _modelConfig.model.toLowerCase().contains('gemini');
  }

  bool _isKimiModel() {
    return _modelConfig.provider.toLowerCase().contains('kimi') ||
           _modelConfig.provider.toLowerCase().contains('moonshot') ||
           _modelConfig.model.toLowerCase().contains('moonshot');
  }

  @override
  Future<bool> testConnection() async {
    try {
      if (!await isAvailable) {
        return false;
      }

      if (_isClaudeModel() && _claudeApiService != null) {
        return await _claudeApiService!.testApiKey(_modelConfig.apiKey);
      } else if (_isOpenAIModel() && _openaiApiService != null) {
        return await _openaiApiService!.testApiKey(_modelConfig.apiKey);
      } else if (_isGoogleModel() && _googleApiService != null) {
        return await _googleApiService!.testApiKey(_modelConfig.apiKey);
      } else if (_isKimiModel() && _kimiApiService != null) {
        return await _kimiApiService!.testApiKey(_modelConfig.apiKey);
      } else {
        return false;
      }
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