import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'model_interfaces.dart';
import 'model_router.dart';
import 'providers/openai_provider.dart';
import 'providers/anthropic_provider.dart';
import 'providers/ollama_provider.dart';

/// Universal model management system with fallbacks and analytics
class ModelManager {
  late final ModelRouter _router;
  late final CostTracker _costTracker;
  late final PerformanceMonitor _performanceMonitor;
  late final UsageAnalytics _analytics;
  
  final Map<String, ModelProvider> _providers = {};
  final ModelManagerConfig _config;
  String? _configPath;
  
  bool _isInitialized = false;

  ModelManager({
    ModelManagerConfig? config,
  }) : _config = config ?? const ModelManagerConfig();

  /// Initialize the model management system
  Future<void> initialize({String? configPath}) async {
    if (_isInitialized) return;

    _configPath = configPath;

    try {
      // Initialize core services
      _costTracker = CostTracker();
      _performanceMonitor = PerformanceMonitor();
      _analytics = UsageAnalytics();
      
      // Create router with monitoring
      _router = ModelRouter(
        costTracker: _costTracker,
        monitor: _performanceMonitor,
        defaultStrategy: _config.defaultStrategy,
        fallbackChain: _config.fallbackRules,
      );

      // Load configuration if provided
      if (_configPath != null) {
        await _loadConfiguration(_configPath!);
      }

      // Initialize providers from configuration
      await _initializeProvidersFromConfig();

      // Initialize router
      await _router.initialize();

      _isInitialized = true;
      
      // Print system status
      await _printSystemStatus();
    } catch (e) {
      throw ProviderInitializationException(
        'Failed to initialize model management system: $e',
        originalError: e,
      );
    }
  }

  /// Register a model provider
  void registerProvider(ModelProvider provider) {
    _providers[provider.id] = provider;
    _router.registerProvider(provider);
  }

  /// Unregister a model provider
  void unregisterProvider(String providerId) {
    _providers.remove(providerId);
    _router.unregisterProvider(providerId);
  }

  /// Get all available providers
  List<ModelProvider> get providers => _providers.values.toList();

  /// Get all available models across all providers
  Future<List<ModelInfo>> getAllAvailableModels() async {
    _ensureInitialized();
    
    final allModels = <ModelInfo>[];
    
    for (final provider in _providers.values) {
      if (provider.isAvailable) {
        try {
          final models = await provider.getAvailableModels();
          allModels.addAll(models);
        } catch (e) {
          debugPrint('Failed to get models from ${provider.id}: $e');
        }
      }
    }
    
    // Sort by provider and name
    allModels.sort((a, b) {
      final providerCompare = a.providerId.compareTo(b.providerId);
      return providerCompare != 0 ? providerCompare : a.name.compareTo(b.name);
    });
    
    return allModels;
  }

  /// Complete a text generation request
  Future<ModelResponse> complete(
    ModelRequest request, {
    ModelSelectionStrategy? strategy,
    List<String>? preferredProviders,
    bool enableFallback = true,
  }) async {
    _ensureInitialized();
    
    final response = await _router.route(
      request,
      strategy: strategy,
      preferredProviders: preferredProviders,
      enableFallback: enableFallback,
    );

    // Track usage in analytics
    await _analytics.recordCompletion(request, response);
    
    return response;
  }

  /// Stream a text generation request
  Stream<String> stream(
    ModelRequest request, {
    ModelSelectionStrategy? strategy,
    List<String>? preferredProviders,
  }) async* {
    _ensureInitialized();
    
    await for (final chunk in _router.routeStream(
      request,
      strategy: strategy,
      preferredProviders: preferredProviders,
    )) {
      yield chunk;
    }

    // Track streaming usage in analytics (approximate)
    await _analytics.recordStreaming(request);
  }

  /// Generate embeddings
  Future<List<double>> embed(
    String text, {
    List<String>? preferredProviders,
  }) async {
    _ensureInitialized();
    
    final embeddings = await _router.routeEmbed(
      text,
      preferredProviders: preferredProviders,
    );

    // Track embedding usage in analytics
    await _analytics.recordEmbedding(text);
    
    return embeddings;
  }

  /// Get system health status
  Future<SystemHealth> getSystemHealth() async {
    _ensureInitialized();
    
    final providersHealth = await _router.getProvidersHealth();
    final performanceStats = _router.getPerformanceStats();
    
    final healthyProviders = providersHealth.values
        .where((h) => h.isHealthy)
        .length;
    
    return SystemHealth(
      isHealthy: healthyProviders > 0,
      totalProviders: _providers.length,
      healthyProviders: healthyProviders,
      providersHealth: providersHealth,
      performanceStats: performanceStats,
      lastChecked: DateTime.now(),
    );
  }

  /// Get cost report
  Future<CostReport> getCostReport([DateTimeRange? range]) async {
    _ensureInitialized();
    return await _router.getCostReport(range);
  }

  /// Get usage analytics
  Future<UsageReport> getUsageReport([DateTimeRange? range]) async {
    _ensureInitialized();
    return await _analytics.generateReport(range);
  }

  /// Get performance statistics
  PerformanceStats getPerformanceStats() {
    _ensureInitialized();
    return _router.getPerformanceStats();
  }

  /// Test all providers
  Future<Map<String, bool>> testAllProviders() async {
    _ensureInitialized();
    
    final results = <String, bool>{};
    
    
    for (final provider in _providers.values) {
      try {
        final isHealthy = await provider.testConnection();
        results[provider.id] = isHealthy;
        debugPrint('${provider.name}: ${isHealthy ? "SUCCESS" : "FAILED"}');
      } catch (e) {
        results[provider.id] = false;
        debugPrint('${provider.name}: ERROR - $e');
      }
    }
    
    return results;
  }

  /// Save current configuration
  Future<void> saveConfiguration(String filePath) async {
    _ensureInitialized();
    
    
    final config = {
      'version': '1.0.0',
      'default_strategy': _config.defaultStrategy.name,
      'providers': _providers.map((id, provider) => MapEntry(id, {
        'id': provider.id,
        'name': provider.name,
        'config': provider.config,
        'enabled': provider.isAvailable,
      })),
      'fallback_rules': _config.fallbackRules.map((rule) => {
        'name': rule.name,
        'strategy': rule.strategy.name,
        'providers': rule.providers,
      }).toList(),
      'saved_at': DateTime.now().toIso8601String(),
    };
    
    final file = File(filePath);
    await file.writeAsString(jsonEncode(config));
    
  }

  /// Load configuration from file
  Future<void> _loadConfiguration(String filePath) async {
    try {
      
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('Configuration file not found, using defaults');
        return;
      }

      final content = await file.readAsString();
      final config = jsonDecode(content) as Map<String, dynamic>;
      
    } catch (e) {
      debugPrint('Failed to load configuration: $e');
    }
  }

  /// Initialize providers from configuration
  Future<void> _initializeProvidersFromConfig() async {
    // Initialize default providers based on environment
    
    // OpenAI provider (if API key is available)
    final openAIKey = Platform.environment['OPENAI_API_KEY'] ?? _config.openAIApiKey;
    if (openAIKey != null && openAIKey.isNotEmpty) {
      registerProvider(OpenAIProvider(apiKey: openAIKey));
    }
    
    // Anthropic provider (if API key is available)
    final anthropicKey = Platform.environment['ANTHROPIC_API_KEY'] ?? _config.anthropicApiKey;
    if (anthropicKey != null && anthropicKey.isNotEmpty) {
      registerProvider(AnthropicProvider(apiKey: anthropicKey));
    }
    
    // Ollama provider (always available, might not be running)
    registerProvider(OllamaProvider(
      baseUrl: _config.ollamaBaseUrl,
    ));
    
  }

  /// Print system status
  Future<void> _printSystemStatus() async {
    // Removed verbose system status logging
  }

  /// Ensure the system is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw const ProviderInitializationException('Model management system not initialized. Call initialize() first.');
    }
  }

  /// Dispose of all resources
  Future<void> dispose() async {
    if (!_isInitialized) return;
    
    
    await _router.dispose();
    _providers.clear();
    _isInitialized = false;
    
  }
}

/// Usage analytics service
class UsageAnalytics {
  final List<AnalyticsRecord> _records = [];
  
  /// Record a completion request
  Future<void> recordCompletion(ModelRequest request, ModelResponse response) async {
    _records.add(AnalyticsRecord(
      timestamp: DateTime.now(),
      type: RequestType.completion,
      provider: response.metadata['provider'] as String? ?? 'unknown',
      model: response.model ?? request.model ?? 'unknown',
      tokens: response.usage.totalTokens,
      cost: response.usage.totalCost,
      responseTime: response.responseTime,
      success: true,
    ));
  }

  /// Record a streaming request (estimated)
  Future<void> recordStreaming(ModelRequest request) async {
    _records.add(AnalyticsRecord(
      timestamp: DateTime.now(),
      type: RequestType.streaming,
      provider: 'unknown', // Will be updated by router
      model: request.model ?? 'unknown',
      tokens: request.maxTokens, // Estimated
      cost: 0.0, // Will be updated
      responseTime: Duration.zero, // Not applicable for streaming
      success: true,
    ));
  }

  /// Record an embedding request
  Future<void> recordEmbedding(String text) async {
    _records.add(AnalyticsRecord(
      timestamp: DateTime.now(),
      type: RequestType.embedding,
      provider: 'unknown', // Will be updated by router
      model: 'unknown',
      tokens: (text.length / 4).ceil(), // Estimated
      cost: 0.0,
      responseTime: Duration.zero,
      success: true,
    ));
  }

  /// Generate usage report
  Future<UsageReport> generateReport(DateTimeRange? range) async {
    final filteredRecords = range != null
        ? _records.where((r) => range.contains(r.timestamp)).toList()
        : _records;

    if (filteredRecords.isEmpty) {
      return UsageReport.empty(range ?? DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ));
    }

    final totalRequests = filteredRecords.length;
    final totalTokens = filteredRecords.map((r) => r.tokens).reduce((a, b) => a + b);
    final totalCost = filteredRecords.map((r) => r.cost).reduce((a, b) => a + b);

    final byType = <RequestType, int>{};
    final byProvider = <String, int>{};
    final byModel = <String, int>{};

    for (final record in filteredRecords) {
      byType[record.type] = (byType[record.type] ?? 0) + 1;
      byProvider[record.provider] = (byProvider[record.provider] ?? 0) + 1;
      byModel[record.model] = (byModel[record.model] ?? 0) + 1;
    }

    // Calculate trends (compare with previous period)
    final trends = _calculateTrends(filteredRecords, range);

    return UsageReport(
      period: range ?? DateTimeRange(
        start: filteredRecords.first.timestamp,
        end: filteredRecords.last.timestamp,
      ),
      totalRequests: totalRequests,
      totalTokens: totalTokens,
      totalCost: totalCost,
      requestsByType: byType,
      requestsByProvider: byProvider,
      requestsByModel: byModel,
      trends: trends,
    );
  }

  /// Calculate usage trends
  UsageTrends _calculateTrends(List<AnalyticsRecord> currentRecords, DateTimeRange? range) {
    if (range == null || currentRecords.isEmpty) {
      return const UsageTrends(
        requestsChange: 0.0,
        tokensChange: 0.0,
        costChange: 0.0,
      );
    }

    // Get previous period records
    final periodDuration = range.duration;
    final previousPeriod = DateTimeRange(
      start: range.start.subtract(periodDuration),
      end: range.start,
    );

    final previousRecords = _records
        .where((r) => previousPeriod.contains(r.timestamp))
        .toList();

    if (previousRecords.isEmpty) {
      return const UsageTrends(
        requestsChange: 0.0,
        tokensChange: 0.0,
        costChange: 0.0,
      );
    }

    final currentRequests = currentRecords.length;
    final previousRequests = previousRecords.length;
    final requestsChange = _calculatePercentageChange(previousRequests, currentRequests);

    final currentTokens = currentRecords.map((r) => r.tokens).reduce((a, b) => a + b);
    final previousTokens = previousRecords.map((r) => r.tokens).reduce((a, b) => a + b);
    final tokensChange = _calculatePercentageChange(previousTokens, currentTokens);

    final currentCost = currentRecords.map((r) => r.cost).reduce((a, b) => a + b);
    final previousCost = previousRecords.map((r) => r.cost).reduce((a, b) => a + b);
    final costChange = _calculatePercentageChange(previousCost, currentCost);

    return UsageTrends(
      requestsChange: requestsChange,
      tokensChange: tokensChange,
      costChange: costChange,
    );
  }

  /// Calculate percentage change
  double _calculatePercentageChange(num previous, num current) {
    if (previous == 0) return current > 0 ? double.infinity : 0.0;
    return ((current - previous) / previous) * 100;
  }
}

/// Configuration for the model manager
class ModelManagerConfig {
  final ModelSelectionStrategy defaultStrategy;
  final List<FallbackRule> fallbackRules;
  final String? openAIApiKey;
  final String? anthropicApiKey;
  final String ollamaBaseUrl;

  const ModelManagerConfig({
    this.defaultStrategy = ModelSelectionStrategy.cheapest,
    this.fallbackRules = const [],
    this.openAIApiKey,
    this.anthropicApiKey,
    this.ollamaBaseUrl = 'http://localhost:11434',
  });
}

/// System health status
class SystemHealth {
  final bool isHealthy;
  final int totalProviders;
  final int healthyProviders;
  final Map<String, ProviderHealth> providersHealth;
  final PerformanceStats performanceStats;
  final DateTime lastChecked;

  const SystemHealth({
    required this.isHealthy,
    required this.totalProviders,
    required this.healthyProviders,
    required this.providersHealth,
    required this.performanceStats,
    required this.lastChecked,
  });
}

/// Usage report
class UsageReport {
  final DateTimeRange period;
  final int totalRequests;
  final int totalTokens;
  final double totalCost;
  final Map<RequestType, int> requestsByType;
  final Map<String, int> requestsByProvider;
  final Map<String, int> requestsByModel;
  final UsageTrends trends;

  const UsageReport({
    required this.period,
    required this.totalRequests,
    required this.totalTokens,
    required this.totalCost,
    required this.requestsByType,
    required this.requestsByProvider,
    required this.requestsByModel,
    required this.trends,
  });

  factory UsageReport.empty(DateTimeRange period) {
    return UsageReport(
      period: period,
      totalRequests: 0,
      totalTokens: 0,
      totalCost: 0.0,
      requestsByType: {},
      requestsByProvider: {},
      requestsByModel: {},
      trends: const UsageTrends(
        requestsChange: 0.0,
        tokensChange: 0.0,
        costChange: 0.0,
      ),
    );
  }
}

/// Usage trends
class UsageTrends {
  final double requestsChange;
  final double tokensChange;
  final double costChange;

  const UsageTrends({
    required this.requestsChange,
    required this.tokensChange,
    required this.costChange,
  });
}

/// Analytics record
class AnalyticsRecord {
  final DateTime timestamp;
  final RequestType type;
  final String provider;
  final String model;
  final int tokens;
  final double cost;
  final Duration responseTime;
  final bool success;

  const AnalyticsRecord({
    required this.timestamp,
    required this.type,
    required this.provider,
    required this.model,
    required this.tokens,
    required this.cost,
    required this.responseTime,
    required this.success,
  });
}

/// Request types for analytics
enum RequestType {
  completion,
  streaming,
  embedding,
}