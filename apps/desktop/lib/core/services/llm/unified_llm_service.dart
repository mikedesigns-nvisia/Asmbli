import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'llm_provider.dart';
import 'local_llm_provider.dart';
import 'api_llm_provider.dart';
import '../model_config_service.dart';
import '../claude_api_service.dart';
import '../openai_api_service.dart';
import '../google_api_service.dart';
import '../kimi_api_service.dart';
import '../ollama_service.dart';

/// Unified LLM service that routes requests to appropriate providers
class UnifiedLLMService {
  final ModelConfigService _modelConfigService;
  final ClaudeApiService _claudeApiService;
  final OllamaService _ollamaService;
  final OpenAIApiService _openaiApiService;
  final GoogleApiService _googleApiService;
  final KimiApiService _kimiApiService;
  final Map<String, LLMProvider> _providers = {};
  
  UnifiedLLMService(
    this._modelConfigService,
    this._claudeApiService,
    this._ollamaService,
    this._openaiApiService,
    this._googleApiService,
    this._kimiApiService,
  );

  /// Initialize the service and register providers
  Future<void> initialize() async {
    await _modelConfigService.initialize();
    await _refreshProviders();
  }

  /// Refresh provider registry based on current model configurations
  Future<void> _refreshProviders() async {
    _providers.clear();
    
    final allModels = _modelConfigService.allModelConfigs;
    
    for (final modelConfig in allModels.values) {
      LLMProvider provider;
      
      if (modelConfig.isLocal) {
        provider = LocalLLMProvider(modelConfig, _ollamaService);
      } else {
        provider = ApiLLMProvider(modelConfig, _claudeApiService, _openaiApiService, _googleApiService, _kimiApiService);
      }
      
      _providers[modelConfig.id] = provider;
      
      // Initialize the provider
      try {
        await provider.initialize();
      } catch (e) {
        print('Failed to initialize provider ${provider.name}: $e');
      }
    }
  }

  /// Get provider by model ID
  LLMProvider? getProvider(String modelId) {
    return _providers[modelId];
  }

  /// Get all available providers
  List<LLMProvider> getAvailableProviders() {
    return _providers.values.toList();
  }

  /// Get default provider based on current default model
  LLMProvider? getDefaultProvider() {
    final defaultModel = _modelConfigService.defaultModelConfig;
    if (defaultModel == null) return null;
    
    return getProvider(defaultModel.id);
  }

  /// Send a chat message using the specified model
  Future<LLMResponse> chat({
    required String message,
    String? modelId,
    ChatContext? context,
  }) async {
    final provider = await _getProviderForRequest(modelId);
    final chatContext = context ?? const ChatContext();
    
    return await provider.chat(message, chatContext);
  }

  /// Send a streaming chat message using the specified model
  Stream<String> chatStream({
    required String message,
    String? modelId,
    ChatContext? context,
  }) async* {
    final provider = await _getProviderForRequest(modelId);
    final chatContext = context ?? const ChatContext();
    
    yield* provider.chatStream(message, chatContext);
  }

  /// Send a vision message with image using a vision-capable model
  Future<LLMResponse> visionChat({
    required String message,
    required String base64Image,
    String? modelId,
    ChatContext? context,
  }) async {
    // Get a vision-capable provider
    final provider = await _getVisionProviderForRequest(modelId);
    
    final chatContext = context ?? const ChatContext();
    
    // Support vision for both API and local providers
    if (provider is ApiLLMProvider) {
      return await provider.visionChat(message, base64Image, chatContext);
    } else if (provider is LocalLLMProvider) {
      return await provider.visionChat(message, base64Image, chatContext);
    } else {
      throw UnsupportedError('Vision chat is not supported by this provider type');
    }
  }

  /// Get a vision-capable provider for the request
  Future<LLMProvider> _getVisionProviderForRequest(String? modelId) async {
    LLMProvider? provider;
    
    if (modelId != null) {
      provider = getProvider(modelId);
      if (provider == null) {
        throw Exception('Model $modelId not found');
      }
    } else {
      // Find a vision-capable provider
      provider = _findVisionCapableProvider();
      if (provider == null) {
        throw Exception('No vision-capable models available');
      }
    }
    
    // Verify the provider supports vision
    if (!_providerSupportsVision(provider)) {
      throw Exception('Model ${provider.name} does not support vision capabilities');
    }
    
    return provider;
  }

  /// Find a vision-capable provider from available providers
  LLMProvider? _findVisionCapableProvider() {
    // Look for Claude models first (they support vision)
    for (final provider in _providers.values) {
      if (_providerSupportsVision(provider)) {
        return provider;
      }
    }
    return null;
  }

  /// Check if a provider supports vision capabilities
  bool _providerSupportsVision(LLMProvider provider) {
    final modelConfig = provider.modelConfig;
    
    // Check API providers (Claude, OpenAI)
    if (provider is ApiLLMProvider) {
      // Check if model has vision capability or is a known vision model
      final hasVisionCapability = modelConfig.capabilities.contains('vision');
      final isClaudeVision = modelConfig.model.contains('claude-3');
      final isGPTVision = modelConfig.model.contains('gpt-4') && 
                         (modelConfig.model.contains('vision') || modelConfig.model.contains('turbo'));
      
      return hasVisionCapability || isClaudeVision || isGPTVision;
    }
    
    // Check local providers (LLaVA models)
    if (provider is LocalLLMProvider) {
      return modelConfig.capabilities.contains('vision') ||
             modelConfig.ollamaModelId?.toLowerCase().contains('llava') == true;
    }
    
    return false;
  }

  /// Get recommended provider for a task type
  LLMProvider? getRecommendedProvider(String taskType) {
    final recommendedModel = _modelConfigService.getRecommendedModel(taskType);
    if (recommendedModel == null) return null;
    
    return getProvider(recommendedModel.id);
  }

  /// Test connection for a specific provider
  Future<bool> testProvider(String modelId) async {
    final provider = getProvider(modelId);
    if (provider == null) return false;
    
    return await provider.testConnection();
  }

  /// Get provider for a request, with fallback logic
  Future<LLMProvider> _getProviderForRequest(String? modelId) async {
    LLMProvider? provider;
    
    if (modelId != null) {
      provider = getProvider(modelId);
    }
    
    provider ??= getDefaultProvider();
    
    if (provider == null) {
      throw const LLMProviderException('No LLM provider available');
    }
    
    // Check if provider is available
    if (!await provider.isAvailable) {
      // Try to find an alternative
      provider = await _findFallbackProvider(provider);
    }
    
    return provider;
  }

  /// Find a fallback provider when the requested one is unavailable
  Future<LLMProvider> _findFallbackProvider(LLMProvider unavailableProvider) async {
    // If local model is unavailable, try API models
    if (unavailableProvider.modelConfig.isLocal) {
      for (final provider in _providers.values) {
        if (provider.modelConfig.isApi && await provider.isAvailable) {
          print('Falling back from local model to API: ${provider.name}');
          return provider;
        }
      }
    }
    
    // If API model is unavailable, try local models
    if (unavailableProvider.modelConfig.isApi) {
      for (final provider in _providers.values) {
        if (provider.modelConfig.isLocal && await provider.isAvailable) {
          print('Falling back from API to local model: ${provider.name}');
          return provider;
        }
      }
    }
    
    // No fallback available
    throw LLMProviderException(
      'Provider ${unavailableProvider.name} is unavailable and no fallback found',
    );
  }

  /// Refresh providers when models change
  Future<void> onModelsChanged() async {
    await _refreshProviders();
  }

  /// Get provider statistics
  Map<String, dynamic> getProviderStats() {
    final stats = <String, dynamic>{};
    
    int localCount = 0;
    int apiCount = 0;
    int availableCount = 0;
    
    for (final provider in _providers.values) {
      if (provider.modelConfig.isLocal) {
        localCount++;
      } else {
        apiCount++;
      }
    }
    
    stats['total'] = _providers.length;
    stats['local'] = localCount;
    stats['api'] = apiCount;
    stats['available'] = availableCount;
    
    return stats;
  }

  /// Dispose all providers
  Future<void> dispose() async {
    for (final provider in _providers.values) {
      try {
        await provider.dispose();
      } catch (e) {
        print('Error disposing provider ${provider.name}: $e');
      }
    }
    _providers.clear();
  }

  /// Generate response using specified model (business service compatibility)
  Future<LLMResponse> generate({
    required String prompt,
    String? modelId,
    Map<String, dynamic>? context,
  }) async {
    return await chat(
      message: prompt,
      modelId: modelId,
      context: context != null ? ChatContext(metadata: context) : null,
    );
  }

  /// Generate streaming response (business service compatibility)
  Stream<String> generateStream({
    required String prompt,
    String? modelId,
    Map<String, dynamic>? context,
  }) async* {
    yield* chatStream(
      message: prompt,
      modelId: modelId,
      context: context != null ? ChatContext(metadata: context) : null,
    );
  }

  /// Check if model is available (business service compatibility)
  bool isModelAvailable(String modelId) {
    final provider = getProvider(modelId);
    return provider != null;
  }

  /// Initialize model (business service compatibility) 
  Future<void> initializeModel(String modelId) async {
    final provider = getProvider(modelId);
    if (provider != null) {
      await provider.initialize();
    }
  }
}

// Riverpod provider for unified LLM service
final unifiedLLMServiceProvider = Provider<UnifiedLLMService>((ref) {
  final modelConfigService = ref.read(modelConfigServiceProvider);
  final claudeApiService = ref.read(claudeApiServiceProvider);
  final ollamaService = ref.read(ollamaServiceProvider);
  final openaiApiService = ref.read(openaiApiServiceProvider);
  final googleApiService = ref.read(googleApiServiceProvider);
  
  final kimiApiService = ref.read(kimiApiServiceProvider);
  
  final service = UnifiedLLMService(
    modelConfigService,
    claudeApiService,
    ollamaService,
    openaiApiService,
    googleApiService,
    kimiApiService,
  );
  
  // Initialize the service
  service.initialize().catchError((e) {
    print('Failed to initialize unified LLM service: $e');
  });
  
  // Listen for model config changes
  ref.listen(allModelConfigsProvider, (previous, next) {
    service.onModelsChanged().catchError((e) {
      print('Failed to refresh providers: $e');
    });
  });
  
  // Cleanup on disposal
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

// Provider for getting the currently selected model's provider
final selectedLLMProviderProvider = Provider<LLMProvider?>((ref) {
  final service = ref.watch(unifiedLLMServiceProvider);
  final defaultModel = ref.watch(defaultModelConfigProvider);
  
  if (defaultModel == null) return null;
  return service.getProvider(defaultModel.id);
});

// Provider for available providers
final availableLLMProvidersProvider = Provider<List<LLMProvider>>((ref) {
  final service = ref.watch(unifiedLLMServiceProvider);
  return service.getAvailableProviders();
});

// Provider for provider statistics
final llmProviderStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final service = ref.watch(unifiedLLMServiceProvider);
  return service.getProviderStats();
});