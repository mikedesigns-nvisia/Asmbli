import 'dart:async';
import 'dart:math' as math;
import 'model_interfaces.dart';

/// Intelligent model router that selects the best provider for each request
class ModelRouter {
  final Map<String, ModelProvider> _providers = {};
  final CostTracker _costTracker;
  final PerformanceMonitor _monitor;
  final ModelSelectionStrategy _defaultStrategy;
  final List<FallbackRule> _fallbackChain;
  
  // Provider health cache
  final Map<String, ProviderHealth> _healthCache = {};
  Timer? _healthCheckTimer;

  ModelRouter({
    required CostTracker costTracker,
    required PerformanceMonitor monitor,
    ModelSelectionStrategy defaultStrategy = ModelSelectionStrategy.cheapest,
    List<FallbackRule>? fallbackChain,
  }) : _costTracker = costTracker,
       _monitor = monitor,
       _defaultStrategy = defaultStrategy,
       _fallbackChain = fallbackChain ?? _createDefaultFallbackChain();

  /// Register a model provider
  void registerProvider(ModelProvider provider) {
    print('📝 Registering provider: ${provider.name} (${provider.id})');
    _providers[provider.id] = provider;
  }

  /// Unregister a model provider
  void unregisterProvider(String providerId) {
    print('🗑️ Unregistering provider: $providerId');
    _providers.remove(providerId);
    _healthCache.remove(providerId);
  }

  /// Get all registered providers
  List<ModelProvider> get providers => _providers.values.toList();

  /// Get a specific provider by ID
  ModelProvider? getProvider(String providerId) => _providers[providerId];

  /// Initialize the router and all providers
  Future<void> initialize() async {
    print('🚀 Initializing model router with ${_providers.length} providers');

    // Initialize all providers
    for (final provider in _providers.values) {
      try {
        await provider.initialize();
        print('✅ Provider ${provider.id} initialized successfully');
      } catch (e) {
        print('⚠️ Provider ${provider.id} initialization failed: $e');
      }
    }

    // Start health monitoring
    _startHealthMonitoring();
    
    print('✅ Model router initialization completed');
  }

  /// Route a request to the best available provider
  Future<ModelResponse> route(
    ModelRequest request, {
    ModelSelectionStrategy? strategy,
    List<String>? preferredProviders,
    bool enableFallback = true,
  }) async {
    final routingStrategy = strategy ?? _defaultStrategy;
    final startTime = DateTime.now();

    try {
      print('🎯 Routing request with strategy: ${routingStrategy.name}');
      
      // Select the best provider
      final provider = await _selectProvider(
        request,
        strategy: routingStrategy,
        preferredProviders: preferredProviders,
      );

      if (provider == null) {
        throw ModelException(
          'No suitable provider available for request',
          modelId: request.model,
        );
      }

      print('📡 Selected provider: ${provider.name} (${provider.id})');

      // Execute with monitoring
      final response = await _executeWithMonitoring(provider, request);

      // Track usage and costs
      await _trackUsage(provider, request, response);

      final routingTime = DateTime.now().difference(startTime);
      print('✅ Request completed in ${routingTime.inMilliseconds}ms');

      return response;
    } catch (e) {
      if (enableFallback && e is ModelException) {
        print('⚠️ Primary provider failed, attempting fallback: $e');
        return await _attemptFallback(request, e, preferredProviders);
      }
      rethrow;
    }
  }

  /// Stream a request to the best available provider
  Stream<String> routeStream(
    ModelRequest request, {
    ModelSelectionStrategy? strategy,
    List<String>? preferredProviders,
  }) async* {
    final routingStrategy = strategy ?? _defaultStrategy;
    
    try {
      print('🌊 Routing streaming request with strategy: ${routingStrategy.name}');
      
      // Select the best provider
      final provider = await _selectProvider(
        request,
        strategy: routingStrategy,
        preferredProviders: preferredProviders,
      );

      if (provider == null) {
        throw ModelException(
          'No suitable provider available for streaming request',
          modelId: request.model,
        );
      }

      if (!provider.capabilities.supportsStreaming) {
        throw ModelException(
          'Selected provider ${provider.id} does not support streaming',
          providerId: provider.id,
        );
      }

      print('📡 Selected streaming provider: ${provider.name} (${provider.id})');

      // Stream with monitoring
      await for (final chunk in _streamWithMonitoring(provider, request)) {
        yield chunk;
      }
    } catch (e) {
      print('❌ Streaming request failed: $e');
      rethrow;
    }
  }

  /// Route an embedding request
  Future<List<double>> routeEmbed(
    String text, {
    List<String>? preferredProviders,
  }) async {
    try {
      print('🔢 Routing embedding request');
      
      // Find providers that support embeddings
      final embeddingProviders = _providers.values
          .where((p) => p.capabilities.supportsEmbeddings && p.isAvailable)
          .toList();

      if (embeddingProviders.isEmpty) {
        throw ModelException('No providers available for embeddings');
      }

      // Prefer specified providers
      ModelProvider? provider;
      if (preferredProviders != null) {
        for (final providerId in preferredProviders) {
          final p = _providers[providerId];
          if (p != null && p.capabilities.supportsEmbeddings && p.isAvailable) {
            provider = p;
            break;
          }
        }
      }

      // Fallback to first available embedding provider
      provider ??= embeddingProviders.first;

      print('📡 Selected embedding provider: ${provider.name} (${provider.id})');

      return await provider.embed(text);
    } catch (e) {
      print('❌ Embedding request failed: $e');
      rethrow;
    }
  }

  /// Get health status of all providers
  Future<Map<String, ProviderHealth>> getProvidersHealth() async {
    final healthMap = <String, ProviderHealth>{};
    
    for (final provider in _providers.values) {
      try {
        final health = await provider.healthCheck();
        healthMap[provider.id] = health;
        _healthCache[provider.id] = health;
      } catch (e) {
        healthMap[provider.id] = ProviderHealth.unhealthy(e.toString());
      }
    }
    
    return healthMap;
  }

  /// Get performance statistics
  PerformanceStats getPerformanceStats() {
    return _monitor.getStats();
  }

  /// Get cost tracking report
  Future<CostReport> getCostReport(DateTimeRange? range) async {
    return await _costTracker.generateReport(range);
  }

  /// Select the best provider for a request
  Future<ModelProvider?> _selectProvider(
    ModelRequest request, {
    required ModelSelectionStrategy strategy,
    List<String>? preferredProviders,
  }) async {
    // Get available providers
    final availableProviders = _providers.values
        .where((p) => p.isAvailable)
        .toList();

    if (availableProviders.isEmpty) {
      return null;
    }

    // Filter by preferred providers if specified
    List<ModelProvider> candidates = availableProviders;
    if (preferredProviders != null && preferredProviders.isNotEmpty) {
      final preferred = availableProviders
          .where((p) => preferredProviders.contains(p.id))
          .toList();
      if (preferred.isNotEmpty) {
        candidates = preferred;
      }
    }

    // Filter by model availability
    if (request.model != null) {
      final modelCandidates = <ModelProvider>[];
      for (final provider in candidates) {
        final models = await provider.getAvailableModels();
        if (models.any((m) => m.id == request.model)) {
          modelCandidates.add(provider);
        }
      }
      if (modelCandidates.isNotEmpty) {
        candidates = modelCandidates;
      }
    }

    // Apply selection strategy
    switch (strategy) {
      case ModelSelectionStrategy.cheapest:
        return _selectCheapest(candidates, request);
      case ModelSelectionStrategy.fastest:
        return _selectFastest(candidates);
      case ModelSelectionStrategy.mostCapable:
        return _selectMostCapable(candidates);
      case ModelSelectionStrategy.roundRobin:
        return _selectRoundRobin(candidates);
      case ModelSelectionStrategy.custom:
        return _selectCustom(candidates, request);
    }
  }

  /// Select the cheapest provider
  ModelProvider? _selectCheapest(List<ModelProvider> candidates, ModelRequest request) {
    if (candidates.isEmpty) return null;

    ModelProvider? cheapest;
    double lowestCost = double.infinity;

    for (final provider in candidates) {
      final estimatedCost = _estimateRequestCost(provider, request);
      if (estimatedCost < lowestCost) {
        lowestCost = estimatedCost;
        cheapest = provider;
      }
    }

    return cheapest;
  }

  /// Select the fastest provider based on recent performance
  ModelProvider? _selectFastest(List<ModelProvider> candidates) {
    if (candidates.isEmpty) return null;

    ModelProvider? fastest;
    double lowestLatency = double.infinity;

    for (final provider in candidates) {
      final health = _healthCache[provider.id];
      final latency = health?.latency ?? double.infinity;
      
      if (latency < lowestLatency) {
        lowestLatency = latency;
        fastest = provider;
      }
    }

    return fastest ?? candidates.first;
  }

  /// Select the most capable provider
  ModelProvider? _selectMostCapable(List<ModelProvider> candidates) {
    if (candidates.isEmpty) return null;

    ModelProvider? mostCapable;
    int highestScore = 0;

    for (final provider in candidates) {
      final capabilities = provider.capabilities;
      int score = 0;
      
      if (capabilities.supportsStreaming) score += 1;
      if (capabilities.supportsTools) score += 2;
      if (capabilities.supportsVision) score += 2;
      if (capabilities.supportsEmbeddings) score += 1;
      score += (capabilities.contextWindow / 1000).floor();
      
      if (score > highestScore) {
        highestScore = score;
        mostCapable = provider;
      }
    }

    return mostCapable ?? candidates.first;
  }

  /// Select provider using round-robin strategy
  static int _roundRobinIndex = 0;
  ModelProvider? _selectRoundRobin(List<ModelProvider> candidates) {
    if (candidates.isEmpty) return null;

    final provider = candidates[_roundRobinIndex % candidates.length];
    _roundRobinIndex++;
    return provider;
  }

  /// Custom selection logic (can be overridden)
  ModelProvider? _selectCustom(List<ModelProvider> candidates, ModelRequest request) {
    // Default to cheapest for custom strategy
    return _selectCheapest(candidates, request);
  }

  /// Execute request with performance monitoring
  Future<ModelResponse> _executeWithMonitoring(
    ModelProvider provider,
    ModelRequest request,
  ) async {
    final startTime = DateTime.now();
    
    try {
      final response = await provider.complete(request);
      final responseTime = DateTime.now().difference(startTime);
      
      // Record performance metrics
      await _monitor.record(
        provider: provider.id,
        responseTime: responseTime,
        tokens: response.usage.totalTokens,
        cost: response.usage.totalCost,
        success: true,
      );
      
      return response;
    } catch (e) {
      final responseTime = DateTime.now().difference(startTime);
      
      // Record failure metrics
      await _monitor.record(
        provider: provider.id,
        responseTime: responseTime,
        tokens: 0,
        cost: 0.0,
        success: false,
        error: e.toString(),
      );
      
      rethrow;
    }
  }

  /// Stream request with performance monitoring
  Stream<String> _streamWithMonitoring(
    ModelProvider provider,
    ModelRequest request,
  ) async* {
    final startTime = DateTime.now();
    int tokenCount = 0;
    
    try {
      await for (final chunk in provider.stream(request)) {
        tokenCount += _estimateTokens(chunk);
        yield chunk;
      }
      
      final responseTime = DateTime.now().difference(startTime);
      
      // Record streaming performance metrics
      await _monitor.record(
        provider: provider.id,
        responseTime: responseTime,
        tokens: tokenCount,
        cost: _estimateStreamingCost(provider, tokenCount),
        success: true,
      );
    } catch (e) {
      final responseTime = DateTime.now().difference(startTime);
      
      // Record failure metrics
      await _monitor.record(
        provider: provider.id,
        responseTime: responseTime,
        tokens: tokenCount,
        cost: 0.0,
        success: false,
        error: e.toString(),
      );
      
      rethrow;
    }
  }

  /// Track usage and costs
  Future<void> _trackUsage(
    ModelProvider provider,
    ModelRequest request,
    ModelResponse response,
  ) async {
    await _costTracker.trackUsage(
      provider: provider.id,
      model: response.model ?? request.model ?? 'unknown',
      usage: response.usage,
      request: request,
      response: response,
    );
  }

  /// Attempt fallback on failure
  Future<ModelResponse> _attemptFallback(
    ModelRequest request,
    ModelException originalError,
    List<String>? preferredProviders,
  ) async {
    for (final rule in _fallbackChain) {
      if (rule.shouldTrigger(originalError)) {
        try {
          print('🔄 Attempting fallback: ${rule.name}');
          
          final fallbackProvider = await _selectProvider(
            request,
            strategy: rule.strategy,
            preferredProviders: rule.providers ?? preferredProviders,
          );
          
          if (fallbackProvider != null) {
            return await _executeWithMonitoring(fallbackProvider, request);
          }
        } catch (e) {
          print('⚠️ Fallback ${rule.name} failed: $e');
          continue;
        }
      }
    }
    
    // All fallbacks failed, throw original error
    throw originalError;
  }

  /// Estimate request cost
  double _estimateRequestCost(ModelProvider provider, ModelRequest request) {
    final capabilities = provider.capabilities;
    final promptTokens = _estimatePromptTokens(request);
    final completionTokens = request.maxTokens;
    
    final inputCost = promptTokens * capabilities.costPerInputToken / 1000;
    final outputCost = completionTokens * capabilities.costPerOutputToken / 1000;
    
    return inputCost + outputCost;
  }

  /// Estimate prompt tokens
  int _estimatePromptTokens(ModelRequest request) {
    int total = 0;
    
    for (final message in request.messages) {
      total += _estimateTokens(message.content);
    }
    
    if (request.systemPrompt != null) {
      total += _estimateTokens(request.systemPrompt!);
    }
    
    return total;
  }

  /// Estimate token count
  int _estimateTokens(String text) {
    // Rough estimate: 1 token ≈ 4 characters
    return (text.length / 4).ceil();
  }

  /// Estimate streaming cost
  double _estimateStreamingCost(ModelProvider provider, int tokens) {
    final capabilities = provider.capabilities;
    return tokens * capabilities.costPerOutputToken / 1000;
  }

  /// Start health monitoring
  void _startHealthMonitoring() {
    _healthCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      await _performHealthChecks();
    });
    
    // Initial health check
    _performHealthChecks();
  }

  /// Perform health checks on all providers
  Future<void> _performHealthChecks() async {
    print('🏥 Performing provider health checks');
    
    for (final provider in _providers.values) {
      try {
        final health = await provider.healthCheck();
        _healthCache[provider.id] = health;
        
        print('${health.isHealthy ? "✅" : "❌"} ${provider.id}: ${health.status} (${health.latency.toStringAsFixed(0)}ms)');
      } catch (e) {
        _healthCache[provider.id] = ProviderHealth.unhealthy(e.toString());
        print('❌ ${provider.id}: health check failed - $e');
      }
    }
  }

  /// Create default fallback chain
  static List<FallbackRule> _createDefaultFallbackChain() {
    return [
      FallbackRule(
        name: 'Connection Failure -> Local Model',
        shouldTrigger: (error) => error is ProviderConnectionException,
        strategy: ModelSelectionStrategy.fastest,
        providers: ['ollama'],
      ),
      FallbackRule(
        name: 'Quota Exceeded -> Alternative Provider',
        shouldTrigger: (error) => error is QuotaExceededException,
        strategy: ModelSelectionStrategy.cheapest,
      ),
      FallbackRule(
        name: 'General Failure -> Most Reliable',
        shouldTrigger: (error) => true,
        strategy: ModelSelectionStrategy.mostCapable,
      ),
    ];
  }

  /// Dispose of the router
  Future<void> dispose() async {
    print('🧹 Disposing model router');
    
    _healthCheckTimer?.cancel();
    
    for (final provider in _providers.values) {
      await provider.dispose();
    }
    
    _providers.clear();
    _healthCache.clear();
  }
}

/// Cost tracking service
class CostTracker {
  final List<UsageRecord> _records = [];
  
  /// Track usage for a request
  Future<void> trackUsage({
    required String provider,
    required String model,
    required Usage usage,
    required ModelRequest request,
    required ModelResponse response,
  }) async {
    final record = UsageRecord(
      timestamp: DateTime.now(),
      provider: provider,
      model: model,
      usage: usage,
      requestMetadata: request.metadata,
      responseMetadata: response.metadata,
    );
    
    _records.add(record);
    print('💰 Tracked usage: ${provider}/${model} - ${usage.totalTokens} tokens, \$${usage.totalCost.toStringAsFixed(4)}');
  }

  /// Generate cost report
  Future<CostReport> generateReport(DateTimeRange? range) async {
    final filteredRecords = range != null
        ? _records.where((r) => range.contains(r.timestamp)).toList()
        : _records;

    double totalCost = 0;
    int totalTokens = 0;
    final byProvider = <String, double>{};
    final byModel = <String, double>{};
    
    for (final record in filteredRecords) {
      totalCost += record.usage.totalCost;
      totalTokens += record.usage.totalTokens;
      
      byProvider[record.provider] = (byProvider[record.provider] ?? 0) + record.usage.totalCost;
      byModel[record.model] = (byModel[record.model] ?? 0) + record.usage.totalCost;
    }

    return CostReport(
      totalCost: totalCost,
      totalTokens: totalTokens,
      totalRequests: filteredRecords.length,
      byProvider: byProvider,
      byModel: byModel,
      period: range ?? DateTimeRange(
        start: _records.isEmpty ? DateTime.now() : _records.first.timestamp,
        end: DateTime.now(),
      ),
    );
  }

  /// Get recent usage records
  List<UsageRecord> getRecentUsage({int limit = 100}) {
    return _records.reversed.take(limit).toList();
  }
}

/// Performance monitoring service
class PerformanceMonitor {
  final List<PerformanceRecord> _records = [];
  
  /// Record performance metrics
  Future<void> record({
    required String provider,
    required Duration responseTime,
    required int tokens,
    required double cost,
    required bool success,
    String? error,
  }) async {
    final record = PerformanceRecord(
      timestamp: DateTime.now(),
      provider: provider,
      responseTime: responseTime,
      tokens: tokens,
      cost: cost,
      success: success,
      error: error,
    );
    
    _records.add(record);
  }

  /// Get performance statistics
  PerformanceStats getStats() {
    if (_records.isEmpty) {
      return PerformanceStats(
        totalRequests: 0,
        successRate: 0.0,
        averageResponseTime: Duration.zero,
        byProvider: {},
      );
    }

    final totalRequests = _records.length;
    final successfulRequests = _records.where((r) => r.success).length;
    final successRate = successfulRequests / totalRequests;
    
    final averageResponseTime = Duration(
      milliseconds: _records
          .map((r) => r.responseTime.inMilliseconds)
          .reduce((a, b) => a + b) ~/ totalRequests,
    );

    final byProvider = <String, ProviderPerformance>{};
    
    for (final provider in _records.map((r) => r.provider).toSet()) {
      final providerRecords = _records.where((r) => r.provider == provider).toList();
      final providerSuccess = providerRecords.where((r) => r.success).length;
      
      byProvider[provider] = ProviderPerformance(
        totalRequests: providerRecords.length,
        successRate: providerSuccess / providerRecords.length,
        averageResponseTime: Duration(
          milliseconds: providerRecords
              .map((r) => r.responseTime.inMilliseconds)
              .reduce((a, b) => a + b) ~/ providerRecords.length,
        ),
        totalTokens: providerRecords.map((r) => r.tokens).reduce((a, b) => a + b),
        totalCost: providerRecords.map((r) => r.cost).reduce((a, b) => a + b),
      );
    }

    return PerformanceStats(
      totalRequests: totalRequests,
      successRate: successRate,
      averageResponseTime: averageResponseTime,
      byProvider: byProvider,
    );
  }
}

/// Fallback rule for provider selection
class FallbackRule {
  final String name;
  final bool Function(ModelException error) shouldTrigger;
  final ModelSelectionStrategy strategy;
  final List<String>? providers;

  const FallbackRule({
    required this.name,
    required this.shouldTrigger,
    required this.strategy,
    this.providers,
  });
}

/// Usage record for cost tracking
class UsageRecord {
  final DateTime timestamp;
  final String provider;
  final String model;
  final Usage usage;
  final Map<String, dynamic> requestMetadata;
  final Map<String, dynamic> responseMetadata;

  const UsageRecord({
    required this.timestamp,
    required this.provider,
    required this.model,
    required this.usage,
    required this.requestMetadata,
    required this.responseMetadata,
  });
}

/// Performance record for monitoring
class PerformanceRecord {
  final DateTime timestamp;
  final String provider;
  final Duration responseTime;
  final int tokens;
  final double cost;
  final bool success;
  final String? error;

  const PerformanceRecord({
    required this.timestamp,
    required this.provider,
    required this.responseTime,
    required this.tokens,
    required this.cost,
    required this.success,
    this.error,
  });
}

/// Cost report
class CostReport {
  final double totalCost;
  final int totalTokens;
  final int totalRequests;
  final Map<String, double> byProvider;
  final Map<String, double> byModel;
  final DateTimeRange period;

  const CostReport({
    required this.totalCost,
    required this.totalTokens,
    required this.totalRequests,
    required this.byProvider,
    required this.byModel,
    required this.period,
  });
}

/// Performance statistics
class PerformanceStats {
  final int totalRequests;
  final double successRate;
  final Duration averageResponseTime;
  final Map<String, ProviderPerformance> byProvider;

  const PerformanceStats({
    required this.totalRequests,
    required this.successRate,
    required this.averageResponseTime,
    required this.byProvider,
  });
}

/// Provider performance metrics
class ProviderPerformance {
  final int totalRequests;
  final double successRate;
  final Duration averageResponseTime;
  final int totalTokens;
  final double totalCost;

  const ProviderPerformance({
    required this.totalRequests,
    required this.successRate,
    required this.averageResponseTime,
    required this.totalTokens,
    required this.totalCost,
  });
}

/// Date-time range
class DateTimeRange {
  final DateTime start;
  final DateTime end;

  const DateTimeRange({
    required this.start,
    required this.end,
  });

  bool contains(DateTime dateTime) {
    return dateTime.isAfter(start) && dateTime.isBefore(end);
  }

  Duration get duration => end.difference(start);
}