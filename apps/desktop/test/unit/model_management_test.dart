import 'package:test/test.dart';
import 'dart:async';
import 'dart:math';
import '../../lib/core/models/model_interfaces.dart';
import '../../lib/core/models/model_router.dart';
import '../../lib/core/models/model_manager.dart';
import '../../lib/core/models/providers/openai_provider.dart';
import '../../lib/core/models/providers/anthropic_provider.dart';
import '../../lib/core/models/providers/ollama_provider.dart';

void main() {
  group('Model Interfaces', () {
    late MockModelProvider mockProvider;
    
    setUp(() {
      mockProvider = MockModelProvider('test_provider', 'Test Provider');
    });
    
    test('ModelRequest validates required fields', () {
      expect(
        () => ModelRequest(
          model: '',
          messages: [],
        ),
        throwsA(isA<ArgumentError>()),
      );
      
      expect(
        () => ModelRequest(
          model: 'gpt-3.5-turbo',
          messages: [],
        ),
        throwsA(isA<ArgumentError>()),
      );
      
      // Valid request should not throw
      final validRequest = ModelRequest(
        model: 'gpt-3.5-turbo',
        messages: [Message.user('Hello')],
      );
      
      expect(validRequest.model, equals('gpt-3.5-turbo'));
      expect(validRequest.messages.length, equals(1));
    });
    
    test('Message types are created correctly', () {
      final userMessage = Message.user('User input');
      expect(userMessage.role, equals('user'));
      expect(userMessage.content, equals('User input'));
      
      final assistantMessage = Message.assistant('Assistant response');
      expect(assistantMessage.role, equals('assistant'));
      expect(assistantMessage.content, equals('Assistant response'));
      
      final systemMessage = Message.system('System prompt');
      expect(systemMessage.role, equals('system'));
      expect(systemMessage.content, equals('System prompt'));
    });
    
    test('ModelResponse includes required metadata', () {
      final response = ModelResponse(
        content: 'Test response',
        model: 'test-model',
        usage: TokenUsage(
          promptTokens: 10,
          completionTokens: 20,
          totalTokens: 30,
        ),
        finishReason: 'stop',
      );
      
      expect(response.content, equals('Test response'));
      expect(response.usage?.totalTokens, equals(30));
      expect(response.finishReason, equals('stop'));
    });
    
    test('TokenUsage calculations are correct', () {
      final usage = TokenUsage(
        promptTokens: 15,
        completionTokens: 25,
        totalTokens: 40,
      );
      
      expect(usage.totalTokens, equals(40));
      expect(usage.promptTokens + usage.completionTokens, equals(40));
    });
    
    test('ModelCapabilities define provider features', () {
      const capabilities = ModelCapabilities(
        supportsChat: true,
        supportsCompletion: true,
        supportsStreaming: false,
        maxTokens: 4000,
        supportsFunctions: true,
      );
      
      expect(capabilities.supportsChat, isTrue);
      expect(capabilities.supportsStreaming, isFalse);
      expect(capabilities.maxTokens, equals(4000));
    });
  });
  
  group('Model Router', () {
    late ModelRouter router;
    late MockModelProvider openaiProvider;
    late MockModelProvider anthropicProvider;
    late MockModelProvider ollamaProvider;
    
    setUp(() {
      openaiProvider = MockModelProvider('openai', 'OpenAI');
      anthropicProvider = MockModelProvider('anthropic', 'Anthropic');
      ollamaProvider = MockModelProvider('ollama', 'Ollama');
      
      router = ModelRouter([
        openaiProvider,
        anthropicProvider,
        ollamaProvider,
      ]);
    });
    
    test('routes to preferred provider when available', () async {
      final request = ModelRequest(
        model: 'gpt-3.5-turbo',
        messages: [Message.user('Test')],
        preferredProviders: ['openai'],
      );
      
      final response = await router.route(request);
      
      expect(response.metadata['provider_id'], equals('openai'));
      expect(openaiProvider.lastRequest?.model, equals('gpt-3.5-turbo'));
    });
    
    test('falls back to alternative provider when preferred unavailable', () async {
      openaiProvider.isHealthy = false;
      
      final request = ModelRequest(
        model: 'gpt-3.5-turbo',
        messages: [Message.user('Test')],
        preferredProviders: ['openai', 'anthropic'],
      );
      
      final response = await router.route(request);
      
      expect(response.metadata['provider_id'], equals('anthropic'));
      expect(response.metadata['fallback_used'], isTrue);
    });
    
    test('selects cheapest provider when strategy is cost-optimized', () async {
      openaiProvider.costPer1kTokens = 0.002;
      anthropicProvider.costPer1kTokens = 0.001;
      ollamaProvider.costPer1kTokens = 0.0; // Local model - free
      
      router.setSelectionStrategy(ModelSelectionStrategy.cheapest);
      
      final request = ModelRequest(
        model: 'any-model',
        messages: [Message.user('Cost test')],
      );
      
      final response = await router.route(request);
      
      expect(response.metadata['provider_id'], equals('ollama'));
    });
    
    test('selects fastest provider when strategy is performance', () async {
      openaiProvider.avgLatency = Duration(milliseconds: 500);
      anthropicProvider.avgLatency = Duration(milliseconds: 300);
      ollamaProvider.avgLatency = Duration(milliseconds: 100);
      
      router.setSelectionStrategy(ModelSelectionStrategy.fastest);
      
      final request = ModelRequest(
        model: 'any-model',
        messages: [Message.user('Speed test')],
      );
      
      final response = await router.route(request);
      
      expect(response.metadata['provider_id'], equals('ollama'));
    });
    
    test('tracks cost across multiple requests', () async {
      final requests = [
        ModelRequest(model: 'gpt-3.5-turbo', messages: [Message.user('Request 1')]),
        ModelRequest(model: 'claude-3-haiku', messages: [Message.user('Request 2')]),
        ModelRequest(model: 'llama2', messages: [Message.user('Request 3')]),
      ];
      
      for (final request in requests) {
        await router.route(request);
      }
      
      final costReport = router.getCostReport();
      
      expect(costReport.totalRequests, equals(3));
      expect(costReport.totalCost, greaterThan(0));
      expect(costReport.providerCosts.keys.length, greaterThan(0));
    });
    
    test('respects rate limits', () async {
      openaiProvider.rateLimit = 2; // 2 requests per minute
      
      // First two requests should succeed
      await router.route(ModelRequest(
        model: 'gpt-3.5-turbo',
        messages: [Message.user('Request 1')],
      ));
      
      await router.route(ModelRequest(
        model: 'gpt-3.5-turbo', 
        messages: [Message.user('Request 2')],
      ));
      
      // Third request should be rate limited and fall back
      final response = await router.route(ModelRequest(
        model: 'gpt-3.5-turbo',
        messages: [Message.user('Request 3')],
      ));
      
      // Should fallback to different provider
      expect(response.metadata['provider_id'], isNot(equals('openai')));
      expect(response.metadata['rate_limited'], isTrue);
    });
    
    test('handles provider failures gracefully', () async {
      openaiProvider.shouldFail = true;
      anthropicProvider.shouldFail = true;
      
      final request = ModelRequest(
        model: 'any-model',
        messages: [Message.user('Failure test')],
      );
      
      final response = await router.route(request);
      
      // Should fallback to ollama (the only healthy provider)
      expect(response.metadata['provider_id'], equals('ollama'));
      expect(response.metadata['fallback_count'], equals(2));
    });
  });
  
  group('Model Manager', () {
    late ModelManager manager;
    late MockModelProvider mockProvider;
    
    setUp(() async {
      mockProvider = MockModelProvider('test', 'Test Provider');
      manager = ModelManager();
      manager.registerProvider(mockProvider);
      await manager.initialize();
    });
    
    tearDown(() async {
      await manager.dispose();
    });
    
    test('completes requests successfully', () async {
      final request = ModelRequest(
        model: 'test-model',
        messages: [Message.user('Hello, world!')],
        maxTokens: 100,
      );
      
      final response = await manager.complete(request);
      
      expect(response.success, isTrue);
      expect(response.content, isNotEmpty);
      expect(response.usage?.totalTokens, greaterThan(0));
    });
    
    test('streams responses correctly', () async {
      final request = ModelRequest(
        model: 'test-model',
        messages: [Message.user('Stream test')],
        stream: true,
      );
      
      final chunks = <String>[];
      
      await for (final chunk in manager.stream(request)) {
        chunks.add(chunk);
      }
      
      expect(chunks.isNotEmpty, isTrue);
      expect(chunks.join(), isNotEmpty);
    });
    
    test('validates requests before processing', () async {
      final invalidRequest = ModelRequest(
        model: '',
        messages: [],
      );
      
      expect(
        () => manager.complete(invalidRequest),
        throwsA(isA<ModelValidationException>()),
      );
    });
    
    test('tracks usage statistics', () async {
      final requests = List.generate(5, (i) => ModelRequest(
        model: 'test-model',
        messages: [Message.user('Test message $i')],
      ));
      
      for (final request in requests) {
        await manager.complete(request);
      }
      
      final stats = manager.getUsageStatistics();
      
      expect(stats.totalRequests, equals(5));
      expect(stats.totalTokens, greaterThan(0));
      expect(stats.avgLatency.inMilliseconds, greaterThan(0));
    });
    
    test('handles concurrent requests', () async {
      final futures = List.generate(10, (i) => manager.complete(
        ModelRequest(
          model: 'test-model',
          messages: [Message.user('Concurrent request $i')],
        ),
      ));
      
      final results = await Future.wait(futures);
      
      expect(results.length, equals(10));
      expect(results.every((r) => r.success), isTrue);
    });
    
    test('caches responses when enabled', () async {
      manager.enableCaching(Duration(minutes: 5));
      
      final request = ModelRequest(
        model: 'test-model',
        messages: [Message.user('Cacheable request')],
        temperature: 0.0, // Deterministic
      );
      
      // First request
      final response1 = await manager.complete(request);
      final firstLatency = response1.metadata['latency'] as Duration?;
      
      // Second request (should be cached)
      final response2 = await manager.complete(request);
      final secondLatency = response2.metadata['latency'] as Duration?;
      
      expect(response1.content, equals(response2.content));
      expect(response2.metadata['cached'], isTrue);
      expect(secondLatency!.inMilliseconds, lessThan(firstLatency!.inMilliseconds));
    });
    
    test('respects timeout settings', () async {
      mockProvider.delay = Duration(seconds: 5);
      
      final request = ModelRequest(
        model: 'test-model',
        messages: [Message.user('Timeout test')],
        timeout: Duration(seconds: 1),
      );
      
      expect(
        () => manager.complete(request),
        throwsA(isA<TimeoutException>()),
      );
    });
  });
  
  group('Provider Health Monitoring', () {
    late ProviderHealthMonitor monitor;
    late MockModelProvider provider1;
    late MockModelProvider provider2;
    
    setUp(() {
      provider1 = MockModelProvider('provider1', 'Provider 1');
      provider2 = MockModelProvider('provider2', 'Provider 2');
      
      monitor = ProviderHealthMonitor([provider1, provider2]);
    });
    
    tearDown(() async {
      await monitor.dispose();
    });
    
    test('monitors provider health continuously', () async {
      await monitor.startMonitoring(Duration(milliseconds: 100));
      
      // Wait for a few health checks
      await Future.delayed(Duration(milliseconds: 350));
      
      final health1 = monitor.getProviderHealth('provider1');
      final health2 = monitor.getProviderHealth('provider2');
      
      expect(health1, isNotNull);
      expect(health2, isNotNull);
      expect(health1!.isHealthy, isTrue);
      expect(health2!.isHealthy, isTrue);
    });
    
    test('detects unhealthy providers', () async {
      provider1.shouldFail = true;
      
      await monitor.startMonitoring(Duration(milliseconds: 100));
      
      // Wait for health checks to detect failure
      await Future.delayed(Duration(milliseconds: 350));
      
      final health1 = monitor.getProviderHealth('provider1');
      final health2 = monitor.getProviderHealth('provider2');
      
      expect(health1?.isHealthy, isFalse);
      expect(health2?.isHealthy, isTrue);
      expect(health1?.errorRate, greaterThan(0.5));
    });
    
    test('tracks latency trends', () async {
      provider1.delay = Duration(milliseconds: 100);
      provider2.delay = Duration(milliseconds: 200);
      
      await monitor.startMonitoring(Duration(milliseconds: 50));
      await Future.delayed(Duration(milliseconds: 300));
      
      final health1 = monitor.getProviderHealth('provider1');
      final health2 = monitor.getProviderHealth('provider2');
      
      expect(health1?.latency.inMilliseconds, lessThan(health2!.latency.inMilliseconds));
    });
    
    test('triggers alerts for degraded performance', () async {
      final alerts = <ProviderAlert>[];
      
      monitor.onAlert.listen((alert) {
        alerts.add(alert);
      });
      
      await monitor.startMonitoring(Duration(milliseconds: 100));
      
      // Simulate degraded performance
      provider1.errorRate = 0.6; // High error rate
      
      await Future.delayed(Duration(milliseconds: 350));
      
      expect(alerts, isNotEmpty);
      expect(alerts.any((a) => a.type == AlertType.highErrorRate), isTrue);
    });
  });
  
  group('Cost Tracking', () {
    late CostTracker costTracker;
    
    setUp(() {
      costTracker = CostTracker();
    });
    
    test('calculates costs correctly for different providers', () {
      // OpenAI pricing
      costTracker.recordUsage(
        providerId: 'openai',
        model: 'gpt-3.5-turbo',
        promptTokens: 1000,
        completionTokens: 500,
        costPer1kTokens: 0.002,
      );
      
      // Anthropic pricing
      costTracker.recordUsage(
        providerId: 'anthropic',
        model: 'claude-3-haiku',
        promptTokens: 800,
        completionTokens: 600,
        costPer1kTokens: 0.00025,
      );
      
      final report = costTracker.generateReport();
      
      expect(report.totalCost, closeTo(0.0035, 0.0001)); // 0.003 + 0.00035
      expect(report.providerCosts['openai'], closeTo(0.003, 0.0001));
      expect(report.providerCosts['anthropic'], closeTo(0.00035, 0.0001));
    });
    
    test('tracks usage over time', () {
      final now = DateTime.now();
      
      // Add usage for different time periods
      costTracker.recordUsage(
        providerId: 'test',
        model: 'test-model',
        promptTokens: 1000,
        completionTokens: 500,
        costPer1kTokens: 0.002,
        timestamp: now.subtract(Duration(hours: 2)),
      );
      
      costTracker.recordUsage(
        providerId: 'test',
        model: 'test-model',
        promptTokens: 2000,
        completionTokens: 1000,
        costPer1kTokens: 0.002,
        timestamp: now,
      );
      
      final hourlyReport = costTracker.getUsageByTimeRange(
        start: now.subtract(Duration(hours: 1)),
        end: now.add(Duration(minutes: 1)),
      );
      
      final totalReport = costTracker.generateReport();
      
      expect(hourlyReport.totalTokens, equals(3000));
      expect(totalReport.totalTokens, equals(4500)); // 1500 + 3000
    });
    
    test('provides cost breakdown by model', () {
      costTracker.recordUsage(
        providerId: 'openai',
        model: 'gpt-3.5-turbo',
        promptTokens: 1000,
        completionTokens: 500,
        costPer1kTokens: 0.002,
      );
      
      costTracker.recordUsage(
        providerId: 'openai',
        model: 'gpt-4',
        promptTokens: 500,
        completionTokens: 250,
        costPer1kTokens: 0.06,
      );
      
      final report = costTracker.generateReport();
      
      expect(report.modelCosts['gpt-3.5-turbo'], closeTo(0.003, 0.0001));
      expect(report.modelCosts['gpt-4'], closeTo(0.045, 0.001));
    });
    
    test('handles free local models correctly', () {
      costTracker.recordUsage(
        providerId: 'ollama',
        model: 'llama2',
        promptTokens: 10000,
        completionTokens: 5000,
        costPer1kTokens: 0.0, // Free
      );
      
      final report = costTracker.generateReport();
      
      expect(report.totalCost, equals(0.0));
      expect(report.providerCosts['ollama'], equals(0.0));
      expect(report.totalTokens, equals(15000));
    });
  });
}

/// Mock implementations for testing
class MockModelProvider implements ModelProvider {
  @override
  final String id;
  
  @override
  final String name;
  
  @override
  ModelCapabilities capabilities;
  
  @override
  List<ModelInfo> availableModels;
  
  bool isHealthy = true;
  bool shouldFail = false;
  Duration delay = Duration(milliseconds: 100);
  Duration avgLatency = Duration(milliseconds: 200);
  double costPer1kTokens = 0.002;
  double errorRate = 0.0;
  int rateLimit = 1000; // requests per minute
  int currentRequests = 0;
  
  ModelRequest? lastRequest;
  
  MockModelProvider(this.id, this.name) : 
    capabilities = const ModelCapabilities(
      supportsChat: true,
      supportsCompletion: true,
      supportsStreaming: true,
      maxTokens: 4000,
      supportsFunctions: false,
    ),
    availableModels = [
      const ModelInfo(
        id: 'test-model',
        name: 'Test Model',
        maxTokens: 4000,
        costPer1kTokens: 0.002,
      ),
    ];
  
  @override
  Future<bool> get isAvailable async {
    await Future.delayed(Duration(milliseconds: 10));
    return isHealthy && !shouldFail;
  }
  
  @override
  Future<ModelResponse> complete(ModelRequest request) async {
    lastRequest = request;
    currentRequests++;
    
    // Simulate rate limiting
    if (currentRequests > rateLimit) {
      throw RateLimitException('Rate limit exceeded for provider $id');
    }
    
    if (delay.inMilliseconds > 0) {
      await Future.delayed(delay);
    }
    
    if (shouldFail || Random().nextDouble() < errorRate) {
      throw ModelException('Mock provider failure: $id');
    }
    
    final responseContent = 'Mock response from $name for model ${request.model}';
    final promptTokens = _estimateTokens(request.messages.map((m) => m.content).join(' '));
    final completionTokens = _estimateTokens(responseContent);
    
    return ModelResponse(
      content: responseContent,
      model: request.model,
      usage: TokenUsage(
        promptTokens: promptTokens,
        completionTokens: completionTokens,
        totalTokens: promptTokens + completionTokens,
      ),
      finishReason: 'stop',
      metadata: {
        'provider_id': id,
        'latency': delay,
        'mock': true,
      },
    );
  }
  
  @override
  Stream<String> stream(ModelRequest request) async* {
    lastRequest = request;
    
    if (shouldFail) {
      throw ModelException('Mock provider stream failure: $id');
    }
    
    final words = 'Mock streaming response from $name'.split(' ');
    
    for (final word in words) {
      await Future.delayed(Duration(milliseconds: 50));
      yield '$word ';
    }
  }
  
  @override
  Future<List<ModelInfo>> listModels() async {
    await Future.delayed(Duration(milliseconds: 50));
    
    if (shouldFail) {
      throw ModelException('Failed to list models for provider $id');
    }
    
    return availableModels;
  }
  
  @override
  Future<ProviderHealth> checkHealth() async {
    await Future.delayed(Duration(milliseconds: 20));
    
    return ProviderHealth(
      providerId: id,
      isHealthy: isHealthy && !shouldFail,
      latency: avgLatency,
      errorRate: errorRate,
      metadata: {
        'mock': true,
        'current_requests': currentRequests,
      },
    );
  }
  
  int _estimateTokens(String text) {
    return (text.length / 4).ceil();
  }
}

/// Additional test utilities
class ModelException implements Exception {
  final String message;
  ModelException(this.message);
  
  @override
  String toString() => 'ModelException: $message';
}

class RateLimitException implements Exception {
  final String message;
  RateLimitException(this.message);
  
  @override
  String toString() => 'RateLimitException: $message';
}

class ModelValidationException implements Exception {
  final String message;
  ModelValidationException(this.message);
  
  @override
  String toString() => 'ModelValidationException: $message';
}