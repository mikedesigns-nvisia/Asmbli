import 'dart:async';
import 'dart:convert';
import '../models/model_interfaces.dart';
import 'cache_manager.dart';

/// Cached model provider decorator that adds caching capabilities
/// to any model provider, implementing response caching with configurable TTL
class CachedModelProvider implements ModelProvider {
  final ModelProvider _inner;
  final CacheManager _cache;
  final Duration _defaultCacheTTL;
  final bool _enableStreaming;
  
  // Cache configuration
  final Set<String> _cacheableModels;
  final int _maxTokensToCache;
  
  // Performance tracking
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _streamingRequests = 0;

  CachedModelProvider(
    this._inner,
    this._cache, {
    Duration defaultCacheTTL = const Duration(hours: 2),
    bool enableStreaming = false,
    Set<String>? cacheableModels,
    int maxTokensToCache = 4000,
  }) : _defaultCacheTTL = defaultCacheTTL,
       _enableStreaming = enableStreaming,
       _cacheableModels = cacheableModels ?? {},
       _maxTokensToCache = maxTokensToCache;

  @override
  String get id => '${_inner.id}_cached';

  @override
  String get name => '${_inner.name} (Cached)';

  @override
  ModelCapabilities get capabilities => _inner.capabilities;

  @override
  List<ModelInfo> get availableModels => _inner.availableModels;

  @override
  Future<bool> get isAvailable => _inner.isAvailable;

  @override
  Future<ModelResponse> complete(ModelRequest request) async {
    // Check if request is cacheable
    if (!_isCacheable(request)) {
      print('🚫 Request not cacheable: ${request.model}');
      _cacheMisses++;
      return await _inner.complete(request);
    }

    // Generate cache key
    final cacheKey = _generateRequestCacheKey(request);
    
    // Try to get from cache
    final cachedResponse = await _cache.get<Map<String, dynamic>>(cacheKey);
    if (cachedResponse != null) {
      print('💰 Cache hit for ${request.model}: ${cacheKey.substring(0, 16)}...');
      _cacheHits++;
      return ModelResponse.fromJson(cachedResponse);
    }

    print('🔍 Cache miss for ${request.model}: ${cacheKey.substring(0, 16)}...');
    _cacheMisses++;

    // Get response from inner provider
    final response = await _inner.complete(request);
    
    // Cache the response if successful and within token limits
    if (_shouldCacheResponse(response)) {
      await _cacheResponse(cacheKey, response, request);
    }
    
    return response;
  }

  @override
  Stream<String> stream(ModelRequest request) async* {
    // Streaming responses are generally not cached due to their nature
    // However, we can cache the final accumulated result
    if (!_enableStreaming) {
      yield* _inner.stream(request);
      return;
    }

    _streamingRequests++;
    final buffer = StringBuffer();
    
    await for (final chunk in _inner.stream(request)) {
      buffer.write(chunk);
      yield chunk;
    }

    // Cache the complete response for future non-streaming requests
    if (_isCacheable(request)) {
      final completeResponse = ModelResponse(
        content: buffer.toString(),
        model: request.model,
        usage: TokenUsage(promptTokens: 0, completionTokens: 0, totalTokens: 0),
        finishReason: 'stop',
        metadata: {'cached_from_stream': true},
      );
      
      if (_shouldCacheResponse(completeResponse)) {
        final cacheKey = _generateRequestCacheKey(request);
        await _cacheResponse(cacheKey, completeResponse, request);
      }
    }
  }

  @override
  Future<List<ModelInfo>> listModels() => _inner.listModels();

  @override
  Future<ProviderHealth> checkHealth() async {
    final innerHealth = await _inner.checkHealth();
    
    // Add cache statistics to health check
    final cacheStats = await _getCacheStatistics();
    
    return ProviderHealth(
      providerId: id,
      isHealthy: innerHealth.isHealthy,
      latency: innerHealth.latency,
      errorRate: innerHealth.errorRate,
      metadata: {
        ...innerHealth.metadata,
        'cache_hit_rate': _getCacheHitRate(),
        'cache_stats': cacheStats,
        'streaming_requests': _streamingRequests,
      },
    );
  }

  /// Check if a request is cacheable
  bool _isCacheable(ModelRequest request) {
    // Don't cache if model is not in cacheable set (if specified)
    if (_cacheableModels.isNotEmpty && !_cacheableModels.contains(request.model)) {
      return false;
    }

    // Don't cache streaming requests by default
    if (request.stream == true && !_enableStreaming) {
      return false;
    }

    // Don't cache requests with high randomness
    if (request.temperature != null && request.temperature! > 0.8) {
      return false;
    }

    // Don't cache very large requests
    final totalTokenEstimate = _estimateTokens(request);
    if (totalTokenEstimate > _maxTokensToCache) {
      return false;
    }

    return true;
  }

  /// Check if a response should be cached
  bool _shouldCacheResponse(ModelResponse response) {
    // Don't cache error responses
    if (response.finishReason == 'error') {
      return false;
    }

    // Don't cache very large responses
    final responseTokens = response.usage?.completionTokens ?? 0;
    if (responseTokens > _maxTokensToCache) {
      return false;
    }

    return true;
  }

  /// Generate cache key for a request
  String _generateRequestCacheKey(ModelRequest request) {
    final keyData = {
      'provider': _inner.id,
      'model': request.model,
      'messages': request.messages.map((m) => {
        'role': m.role,
        'content': m.content,
        'name': m.name,
      }).toList(),
      'max_tokens': request.maxTokens,
      'temperature': request.temperature,
      'top_p': request.topP,
      'frequency_penalty': request.frequencyPenalty,
      'presence_penalty': request.presencePenalty,
      'stop': request.stop,
      'tools': request.tools?.map((t) => t.toJson()).toList(),
    };
    
    return _cache.generateKey('model_response', keyData);
  }

  /// Cache a response with appropriate TTL
  Future<void> _cacheResponse(
    String cacheKey, 
    ModelResponse response, 
    ModelRequest request,
  ) async {
    try {
      // Determine cache TTL based on request characteristics
      Duration cacheTTL = _defaultCacheTTL;
      
      // Longer TTL for deterministic requests (low temperature)
      if (request.temperature != null && request.temperature! < 0.3) {
        cacheTTL = _defaultCacheTTL * 2;
      }
      
      // Shorter TTL for high token usage (likely more specific/contextual)
      if (response.usage != null && response.usage!.totalTokens > 2000) {
        cacheTTL = _defaultCacheTTL ~/ 2;
      }

      await _cache.put(
        cacheKey, 
        response.toJson(),
        ttl: cacheTTL,
        level: CacheLevel.all, // Store in all cache levels
      );
      
      print('💾 Cached response: ${response.usage?.totalTokens ?? 0} tokens, TTL: ${cacheTTL.inHours}h');
    } catch (e) {
      print('⚠️ Failed to cache response: $e');
    }
  }

  /// Estimate token count for a request
  int _estimateTokens(ModelRequest request) {
    // Simple estimation: ~4 characters per token
    int totalChars = 0;
    
    for (final message in request.messages) {
      totalChars += message.content.length;
    }
    
    return (totalChars / 4).ceil();
  }

  /// Get cache hit rate
  double _getCacheHitRate() {
    final total = _cacheHits + _cacheMisses;
    return total > 0 ? _cacheHits / total : 0.0;
  }

  /// Get detailed cache statistics
  Future<Map<String, dynamic>> _getCacheStatistics() async {
    try {
      final stats = await _cache.getStatistics();
      return {
        'provider_cache_hits': _cacheHits,
        'provider_cache_misses': _cacheMisses,
        'provider_hit_rate': _getCacheHitRate(),
        'streaming_requests': _streamingRequests,
        'cache_manager_stats': stats,
      };
    } catch (e) {
      return {
        'provider_cache_hits': _cacheHits,
        'provider_cache_misses': _cacheMisses,
        'provider_hit_rate': _getCacheHitRate(),
        'streaming_requests': _streamingRequests,
        'error': e.toString(),
      };
    }
  }

  /// Clear cache for this provider
  Future<void> clearCache() async {
    try {
      // Clear provider-specific cache entries
      // This would require cache manager to support pattern-based clearing
      print('🧹 Clearing cache for provider: ${_inner.id}');
      
      // Reset statistics
      _cacheHits = 0;
      _cacheMisses = 0;
      _streamingRequests = 0;
      
      print('✅ Cache cleared for provider: ${_inner.id}');
    } catch (e) {
      print('⚠️ Failed to clear cache: $e');
    }
  }

  /// Warm up cache with common requests
  Future<void> warmupCache(List<ModelRequest> commonRequests) async {
    print('🔥 Warming up cache with ${commonRequests.length} requests...');
    
    int warmedUp = 0;
    for (final request in commonRequests) {
      try {
        await complete(request);
        warmedUp++;
      } catch (e) {
        print('⚠️ Failed to warm up cache for request: $e');
      }
    }
    
    print('✅ Cache warmed up: $warmedUp/${commonRequests.length} requests');
  }

  /// Update cache configuration
  void updateCacheConfig({
    Duration? defaultCacheTTL,
    Set<String>? cacheableModels,
    int? maxTokensToCache,
  }) {
    if (defaultCacheTTL != null) {
      print('🔧 Updated cache TTL: ${defaultCacheTTL.inHours}h');
    }
    
    if (cacheableModels != null) {
      _cacheableModels.clear();
      _cacheableModels.addAll(cacheableModels);
      print('🔧 Updated cacheable models: ${cacheableModels.length}');
    }
    
    if (maxTokensToCache != null) {
      print('🔧 Updated max tokens to cache: $maxTokensToCache');
    }
  }

  @override
  String toString() {
    return 'CachedModelProvider(${_inner.name}, hitRate: ${(_getCacheHitRate() * 100).toStringAsFixed(1)}%)';
  }
}

/// Cache configuration for different model types
class ModelCacheConfig {
  final Duration ttl;
  final bool enableCaching;
  final int maxTokens;
  final double maxTemperature;

  const ModelCacheConfig({
    required this.ttl,
    this.enableCaching = true,
    this.maxTokens = 4000,
    this.maxTemperature = 0.8,
  });

  static const Map<String, ModelCacheConfig> defaultConfigs = {
    'gpt-3.5-turbo': ModelCacheConfig(
      ttl: Duration(hours: 4),
      maxTokens: 3000,
    ),
    'gpt-4': ModelCacheConfig(
      ttl: Duration(hours: 6),
      maxTokens: 6000,
    ),
    'claude-3-haiku': ModelCacheConfig(
      ttl: Duration(hours: 3),
      maxTokens: 4000,
    ),
    'claude-3-sonnet': ModelCacheConfig(
      ttl: Duration(hours: 8),
      maxTokens: 8000,
    ),
    'llama2': ModelCacheConfig(
      ttl: Duration(hours: 12), // Local models can be cached longer
      maxTokens: 4000,
    ),
  };
}

/// Utility for creating cached providers
class CachedProviderFactory {
  static CachedModelProvider wrap(
    ModelProvider provider,
    CacheManager cacheManager, {
    Duration? defaultCacheTTL,
    ModelCacheConfig? config,
  }) {
    final effectiveConfig = config ?? ModelCacheConfig.defaultConfigs[provider.id];
    
    return CachedModelProvider(
      provider,
      cacheManager,
      defaultCacheTTL: effectiveConfig?.ttl ?? defaultCacheTTL ?? const Duration(hours: 2),
      maxTokensToCache: effectiveConfig?.maxTokens ?? 4000,
    );
  }

  /// Create cached versions of multiple providers
  static Map<String, CachedModelProvider> wrapProviders(
    Map<String, ModelProvider> providers,
    CacheManager cacheManager, {
    Duration? defaultCacheTTL,
  }) {
    return providers.map((key, provider) => MapEntry(
      key,
      wrap(provider, cacheManager, defaultCacheTTL: defaultCacheTTL),
    ));
  }
}