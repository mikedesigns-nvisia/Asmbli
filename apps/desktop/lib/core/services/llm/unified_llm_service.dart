import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'llm_provider.dart';
import 'local_llm_provider.dart';
import 'api_llm_provider.dart';
import '../model_config_service.dart';
import '../claude_api_service.dart';
import '../ollama_service.dart';
import '../../models/model_config.dart';

/// Unified LLM service that routes requests to appropriate providers
class UnifiedLLMService {
  final ModelConfigService _modelConfigService;
  final ClaudeApiService _claudeApiService;
  final OllamaService _ollamaService;
  final Map<String, LLMProvider> _providers = {};
  
  UnifiedLLMService(
    this._modelConfigService,
    this._claudeApiService,
    this._ollamaService,
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
        provider = ApiLLMProvider(modelConfig, _claudeApiService);
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
      throw LLMProviderException('No LLM provider available');
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
}

// Riverpod provider for unified LLM service
final unifiedLLMServiceProvider = Provider<UnifiedLLMService>((ref) {
  final modelConfigService = ref.read(modelConfigServiceProvider);
  final claudeApiService = ref.read(claudeApiServiceProvider);
  final ollamaService = ref.read(ollamaServiceProvider);
  
  final service = UnifiedLLMService(
    modelConfigService,
    claudeApiService,
    ollamaService,
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