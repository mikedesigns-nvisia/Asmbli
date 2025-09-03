import 'package:test/test.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:agentengine_desktop/core/cache/lru_cache.dart';
import 'package:agentengine_desktop/core/cache/file_cache.dart';
import 'package:agentengine_desktop/core/cache/cache_manager.dart';
import 'package:agentengine_desktop/core/cache/cached_model_provider.dart';
import 'package:agentengine_desktop/core/models/model_interfaces.dart';

void main() {
  group('LRU Cache', () {
    late LRUCache<String, String> cache;
    
    setUp(() {
      cache = LRUCache<String, String>(
        maxSize: 3,
        defaultTTL: const Duration(seconds: 1),
      );
    });
    
    test('stores and retrieves values', () {
      cache.put('key1', 'value1');
      cache.put('key2', 'value2');
      
      expect(cache.get('key1'), equals('value1'));
      expect(cache.get('key2'), equals('value2'));
      expect(cache.length, equals(2));
    });
    
    test('evicts least recently used items when full', () {
      cache.put('key1', 'value1');
      cache.put('key2', 'value2');
      cache.put('key3', 'value3');
      
      // Access key1 to make it recently used
      cache.get('key1');
      
      // Add another item, should evict key2 (least recently used)
      cache.put('key4', 'value4');
      
      expect(cache.get('key1'), equals('value1')); // Still there
      expect(cache.get('key2'), isNull); // Evicted
      expect(cache.get('key3'), equals('value3')); // Still there
      expect(cache.get('key4'), equals('value4')); // New item
      expect(cache.length, equals(3));
    });
    
    test('respects TTL expiration', () async {
      cache.put('key1', 'value1', ttl: const Duration(milliseconds: 100));
      
      expect(cache.get('key1'), equals('value1'));
      
      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 150));
      
      expect(cache.get('key1'), isNull);
      expect(cache.length, equals(0));
    });
    
    test('updates access time on get', () {
      cache.put('key1', 'value1');
      cache.put('key2', 'value2');
      cache.put('key3', 'value3');
      
      // Access key1 to make it recently used
      cache.get('key1');
      
      // Add key4, should evict key2 (oldest unaccessed)
      cache.put('key4', 'value4');
      
      expect(cache.get('key1'), equals('value1'));
      expect(cache.get('key2'), isNull);
    });
    
    test('handles containsKey correctly', () {
      cache.put('key1', 'value1');
      
      expect(cache.containsKey('key1'), isTrue);
      expect(cache.containsKey('nonexistent'), isFalse);
    });
    
    test('removes items correctly', () {
      cache.put('key1', 'value1');
      cache.put('key2', 'value2');
      
      final removed = cache.remove('key1');
      
      expect(removed, equals('value1'));
      expect(cache.get('key1'), isNull);
      expect(cache.length, equals(1));
    });
    
    test('clears all items', () {
      cache.put('key1', 'value1');
      cache.put('key2', 'value2');
      
      cache.clear();
      
      expect(cache.length, equals(0));
      expect(cache.isEmpty, isTrue);
    });
    
    test('tracks hit ratio correctly', () {
      cache.put('key1', 'value1');
      
      // Hits
      cache.get('key1');
      cache.get('key1');
      
      // Misses
      cache.get('nonexistent1');
      cache.get('nonexistent2');
      
      expect(cache.hitRatio, equals(0.5)); // 2 hits, 2 misses
    });
    
    test('evicts expired items automatically', () {
      cache.put('key1', 'value1', ttl: const Duration(milliseconds: 50));
      cache.put('key2', 'value2', ttl: const Duration(seconds: 10));
      
      expect(cache.length, equals(2));
      
      // Wait for key1 to expire
      Future.delayed(const Duration(milliseconds: 100), () {
        cache.evictExpired();
        
        expect(cache.length, equals(1));
        expect(cache.get('key1'), isNull);
        expect(cache.get('key2'), equals('value2'));
      });
    });
  });
  
  group('File Cache', () {
    late FileCache fileCache;
    late Directory tempDir;
    
    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('file_cache_test_');
      fileCache = FileCache(
        directory: tempDir,
        maxSizeGB: 1, // 1GB limit for tests
        defaultTTL: const Duration(hours: 1),
      );
      await fileCache.initialize();
    });
    
    tearDown(() async {
      await fileCache.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });
    
    test('stores and retrieves JSON data', () async {
      final testData = {'name': 'test', 'value': 123, 'list': [1, 2, 3]};
      
      await fileCache.put('json_test', testData, type: CacheDataType.json);
      
      final retrieved = await fileCache.get<Map<String, dynamic>>('json_test');
      
      expect(retrieved, isNotNull);
      expect(retrieved!['name'], equals('test'));
      expect(retrieved['value'], equals(123));
      expect(retrieved['list'], equals([1, 2, 3]));
    });
    
    test('stores and retrieves string data', () async {
      const testString = 'This is a test string with unicode: 🚀';
      
      await fileCache.put('string_test', testString, type: CacheDataType.string);
      
      final retrieved = await fileCache.get<String>('string_test');
      
      expect(retrieved, equals(testString));
    });
    
    test('stores and retrieves binary data', () async {
      final testBytes = Uint8List.fromList([1, 2, 3, 4, 5, 255, 128, 0]);
      
      await fileCache.put('binary_test', testBytes, type: CacheDataType.binary);
      
      final retrieved = await fileCache.get<Uint8List>('binary_test');
      
      expect(retrieved, isNotNull);
      expect(retrieved, equals(testBytes));
    });
    
    test('respects TTL for cache expiration', () async {
      await fileCache.put(
        'ttl_test',
        'expire me',
        ttl: const Duration(milliseconds: 100),
        type: CacheDataType.string,
      );
      
      // Should be available immediately
      expect(await fileCache.containsKey('ttl_test'), isTrue);
      
      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 150));
      
      // Should be expired
      expect(await fileCache.containsKey('ttl_test'), isFalse);
      expect(await fileCache.get('ttl_test'), isNull);
    });
    
    test('removes entries correctly', () async {
      await fileCache.put('remove_test', 'data', type: CacheDataType.string);
      
      expect(await fileCache.containsKey('remove_test'), isTrue);
      
      final removed = await fileCache.remove('remove_test');
      
      expect(removed, isTrue);
      expect(await fileCache.containsKey('remove_test'), isFalse);
    });
    
    test('clears all entries', () async {
      await fileCache.put('clear_test_1', 'data1', type: CacheDataType.string);
      await fileCache.put('clear_test_2', 'data2', type: CacheDataType.string);
      
      await fileCache.clear();
      
      expect(await fileCache.containsKey('clear_test_1'), isFalse);
      expect(await fileCache.containsKey('clear_test_2'), isFalse);
    });
    
    test('provides accurate statistics', () async {
      await fileCache.put('stats_1', 'small data', type: CacheDataType.string);
      await fileCache.put('stats_2', List.generate(1000, (i) => i), type: CacheDataType.json);
      
      final stats = fileCache.stats;
      
      expect(stats.entryCount, equals(2));
      expect(stats.totalSizeBytes, greaterThan(0));
      expect(stats.usagePercent, greaterThan(0));
      expect(stats.expiredEntries, equals(0));
    });
    
    test('handles corrupted cache files gracefully', () async {
      // Put valid data first
      await fileCache.put('valid', 'good data', type: CacheDataType.string);
      
      // Manually corrupt a cache file
      final cacheFiles = await tempDir.list().toList();
      final dataFile = cacheFiles.firstWhere(
        (f) => f.path.endsWith('.cache'),
        orElse: () => throw StateError('No cache file found'),
      ) as File;
      
      // Write invalid data
      await dataFile.writeAsString('corrupted data');
      
      // Should handle corruption gracefully
      final result = await fileCache.get('valid');
      expect(result, isNull); // Corrupted file should return null
    });
    
    test('enforces size limits with LRU eviction', () async {
      // Create a small cache for testing
      final smallCache = FileCache(
        directory: tempDir,
        maxSizeGB: 0.001, // Very small limit
        defaultTTL: const Duration(hours: 1),
      );
      await smallCache.initialize();
      
      try {
        // Add data that exceeds the limit
        final largeData = List.generate(10000, (i) => 'large_data_$i');
        
        await smallCache.put('large1', largeData, type: CacheDataType.json);
        await smallCache.put('large2', largeData, type: CacheDataType.json);
        await smallCache.put('large3', largeData, type: CacheDataType.json);
        
        // Should have evicted some entries
        final stats = smallCache.stats;
        expect(stats.totalSizeBytes, lessThanOrEqualTo(smallCache.maxSizeBytes));
        
      } finally {
        await smallCache.dispose();
      }
    });
    
    test('persists data across restarts', () async {
      const testKey = 'persistence_test';
      const testData = 'persistent data';
      
      await fileCache.put(testKey, testData, type: CacheDataType.string);
      await fileCache.dispose();
      
      // Create new cache instance with same directory
      final newCache = FileCache(directory: tempDir);
      await newCache.initialize();
      
      try {
        final retrieved = await newCache.get<String>(testKey);
        expect(retrieved, equals(testData));
      } finally {
        await newCache.dispose();
      }
    });
  });
  
  group('Cache Manager', () {
    late CacheManager cacheManager;
    late Directory tempDir;
    
    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cache_manager_test_');
      final fileCache = FileCache(directory: tempDir);
      await fileCache.initialize();
      
      cacheManager = CacheManager(
        diskCache: fileCache,
        memoryMaxSize: 10,
        enableRedis: false, // Disabled for tests
      );
      await cacheManager.initialize();
    });
    
    tearDown(() async {
      await cacheManager.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });
    
    test('stores data in appropriate cache levels', () async {
      // Memory cache
      await cacheManager.put(
        'memory_test',
        'memory data',
        level: CacheLevel.memory,
      );
      
      // Disk cache
      await cacheManager.put(
        'disk_test',
        'disk data',
        level: CacheLevel.disk,
      );
      
      // All levels
      await cacheManager.put(
        'all_test',
        'all levels data',
        level: CacheLevel.all,
      );
      
      final memoryResult = await cacheManager.get('memory_test');
      final diskResult = await cacheManager.get('disk_test');
      final allResult = await cacheManager.get('all_test');
      
      expect(memoryResult, equals('memory data'));
      expect(diskResult, equals('disk data'));
      expect(allResult, equals('all levels data'));
    });
    
    test('implements cache hierarchy correctly', () async {
      // Put in all levels
      await cacheManager.put('hierarchy_test', 'test data', level: CacheLevel.all);
      
      // Remove from memory cache only
      cacheManager.invalidate('hierarchy_test', level: CacheLevel.memory);
      
      // Should still be available from disk
      final result = await cacheManager.get('hierarchy_test');
      expect(result, equals('test data'));
      
      final stats = await cacheManager.getStatistics();
      expect(stats['memory_cache']['hit_ratio'], lessThan(1.0));
    });
    
    test('generates consistent cache keys', () {
      final key1 = cacheManager.generateKey('test', {'b': 2, 'a': 1});
      final key2 = cacheManager.generateKey('test', {'a': 1, 'b': 2});
      
      // Should be the same despite different parameter order
      expect(key1, equals(key2));
      
      final key3 = cacheManager.generateKey('test', {'a': 1, 'b': 3});
      expect(key3, isNot(equals(key1)));
    });
    
    test('tracks cache statistics across levels', () async {
      await cacheManager.put('stats_1', 'data1', level: CacheLevel.memory);
      await cacheManager.put('stats_2', 'data2', level: CacheLevel.disk);
      await cacheManager.put('stats_3', 'data3', level: CacheLevel.all);
      
      // Generate some hits and misses
      await cacheManager.get('stats_1');
      await cacheManager.get('stats_2');
      await cacheManager.get('nonexistent');
      
      final stats = await cacheManager.getStatistics();
      
      expect(stats['memory_cache'], isNotNull);
      expect(stats['disk_cache'], isNotNull);
      expect(stats['overall_hit_rate'], greaterThan(0.0));
    });
    
    test('handles cache misses gracefully', () async {
      final result = await cacheManager.get('nonexistent_key');
      expect(result, isNull);
    });
    
    test('respects TTL settings', () async {
      await cacheManager.put(
        'ttl_test',
        'expire me',
        ttl: const Duration(milliseconds: 100),
        level: CacheLevel.memory,
      );
      
      expect(await cacheManager.get('ttl_test'), equals('expire me'));
      
      await Future.delayed(const Duration(milliseconds: 150));
      
      expect(await cacheManager.get('ttl_test'), isNull);
    });
    
    test('invalidates cache correctly', () async {
      await cacheManager.put('invalidate_test', 'data', level: CacheLevel.all);
      
      expect(await cacheManager.get('invalidate_test'), equals('data'));
      
      cacheManager.invalidate('invalidate_test', level: CacheLevel.all);
      
      expect(await cacheManager.get('invalidate_test'), isNull);
    });
    
    test('clears cache levels correctly', () async {
      await cacheManager.put('clear_1', 'data1', level: CacheLevel.memory);
      await cacheManager.put('clear_2', 'data2', level: CacheLevel.disk);
      
      await cacheManager.clear(level: CacheLevel.memory);
      
      expect(await cacheManager.get('clear_1'), isNull);
      expect(await cacheManager.get('clear_2'), equals('data2'));
      
      await cacheManager.clear(level: CacheLevel.all);
      
      expect(await cacheManager.get('clear_2'), isNull);
    });
  });
  
  group('Cached Model Provider', () {
    late CachedModelProvider cachedProvider;
    late MockModelProvider mockProvider;
    late CacheManager cacheManager;
    late Directory tempDir;
    
    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cached_provider_test_');
      final fileCache = FileCache(directory: tempDir);
      await fileCache.initialize();
      
      cacheManager = CacheManager(
        diskCache: fileCache,
        memoryMaxSize: 50,
        enableRedis: false,
      );
      await cacheManager.initialize();
      
      mockProvider = MockModelProvider();
      cachedProvider = CachedModelProvider(
        mockProvider,
        cacheManager,
        defaultCacheTTL: const Duration(minutes: 30),
        enableStreaming: false,
        maxTokensToCache: 4000,
      );
    });
    
    tearDown(() async {
      await cacheManager.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });
    
    test('caches model responses correctly', () async {
      final request = ModelRequest(
        model: 'test-model',
        messages: [Message.user('What is AI?')],
        temperature: 0.1, // Low temperature for caching
      );
      
      // First request - should call underlying provider
      final response1 = await cachedProvider.complete(request);
      expect(mockProvider.callCount, equals(1));
      
      // Second identical request - should hit cache
      final response2 = await cachedProvider.complete(request);
      expect(mockProvider.callCount, equals(1)); // No additional calls
      
      expect(response1.content, equals(response2.content));
    });
    
    test('respects caching rules', () async {
      // High temperature request - should not cache
      final highTempRequest = ModelRequest(
        model: 'test-model',
        messages: [Message.user('Random question')],
        temperature: 0.9,
      );
      
      await cachedProvider.complete(highTempRequest);
      await cachedProvider.complete(highTempRequest);
      
      // Should call provider twice (not cached)
      expect(mockProvider.callCount, equals(2));
      
      mockProvider.resetCalls();
      
      // Low temperature request - should cache
      final lowTempRequest = ModelRequest(
        model: 'test-model',
        messages: [Message.user('Deterministic question')],
        temperature: 0.1,
      );
      
      await cachedProvider.complete(lowTempRequest);
      await cachedProvider.complete(lowTempRequest);
      
      // Should call provider once (cached on second call)
      expect(mockProvider.callCount, equals(1));
    });
    
    test('excludes large responses from caching', () async {
      mockProvider.mockLargeResponse = true;
      
      final request = ModelRequest(
        model: 'test-model',
        messages: [Message.user('Generate large response')],
        temperature: 0.0,
      );
      
      await cachedProvider.complete(request);
      await cachedProvider.complete(request);
      
      // Should not cache large responses
      expect(mockProvider.callCount, equals(2));
    });
    
    test('provides cache statistics', () async {
      final request = ModelRequest(
        model: 'test-model',
        messages: [Message.user('Test caching')],
        temperature: 0.0,
      );
      
      // Generate cache hit and miss
      await cachedProvider.complete(request);
      await cachedProvider.complete(request);
      
      final health = await cachedProvider.checkHealth();
      final cacheStats = health.metadata['cache_stats'] as Map<String, dynamic>?;
      
      expect(cacheStats, isNotNull);
      expect(cacheStats!['provider_cache_hits'], equals(1));
      expect(cacheStats['provider_cache_misses'], equals(1));
      expect(cacheStats['provider_hit_rate'], equals(0.5));
    });
    
    test('handles streaming responses appropriately', () async {
      final streamingProvider = CachedModelProvider(
        mockProvider,
        cacheManager,
        enableStreaming: true,
      );
      
      final request = ModelRequest(
        model: 'test-model',
        messages: [Message.user('Stream test')],
        stream: true,
      );
      
      final chunks = <String>[];
      await for (final chunk in streamingProvider.stream(request)) {
        chunks.add(chunk);
      }
      
      expect(chunks.isNotEmpty, isTrue);
      expect(chunks.join().trim(), equals('Mock streaming response'));
    });
    
    test('clears cache correctly', () async {
      final request = ModelRequest(
        model: 'test-model',
        messages: [Message.user('Clear test')],
        temperature: 0.0,
      );
      
      // Cache a response
      await cachedProvider.complete(request);
      await cachedProvider.complete(request);
      expect(mockProvider.callCount, equals(1));
      
      // Clear cache
      await cachedProvider.clearCache();
      
      // Should hit provider again
      await cachedProvider.complete(request);
      expect(mockProvider.callCount, equals(2));
    });
    
    test('warms up cache correctly', () async {
      final requests = [
        ModelRequest(
          model: 'test-model',
          messages: [Message.user('Warmup 1')],
          temperature: 0.0,
        ),
        ModelRequest(
          model: 'test-model',
          messages: [Message.user('Warmup 2')],
          temperature: 0.0,
        ),
      ];
      
      await cachedProvider.warmupCache(requests);
      
      // Subsequent requests should hit cache
      for (final request in requests) {
        await cachedProvider.complete(request);
      }
      
      // Should only call provider during warmup (2 calls)
      expect(mockProvider.callCount, equals(2));
    });
  });
}

/// Mock model provider for testing
class MockModelProvider implements ModelProvider {
  @override
  String get id => 'mock_provider';
  
  @override
  String get name => 'Mock Provider';
  
  @override
  ModelCapabilities get capabilities => const ModelCapabilities(
    supportsChat: true,
    supportsCompletion: true,
    supportsStreaming: true,
    maxTokens: 4000,
    supportsFunctions: false,
  );
  
  @override
  List<ModelInfo> get availableModels => [
    const ModelInfo(
      id: 'test-model',
      name: 'Test Model',
      maxTokens: 4000,
      costPer1kTokens: 0.002,
    ),
  ];
  
  @override
  bool get isAvailable => true;
  
  int callCount = 0;
  bool mockLargeResponse = false;
  
  void resetCalls() {
    callCount = 0;
  }
  
  @override
  Future<ModelResponse> complete(ModelRequest request) async {
    callCount++;
    
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 100));
    
    final content = mockLargeResponse 
        ? 'Large response: ${'Very long content ' * 1000}'
        : 'Mock response for: ${request.messages.last.content}';
    
    final promptTokens = _estimateTokens(request.messages.map((m) => m.content).join(' '));
    final completionTokens = _estimateTokens(content);
    
    return ModelResponse(
      content: content,
      model: request.model,
      usage: TokenUsage(
        promptTokens: promptTokens,
        completionTokens: completionTokens,
        totalTokens: promptTokens + completionTokens,
      ),
      finishReason: 'stop',
      metadata: {
        'mock': true,
        'call_count': callCount,
      },
    );
  }
  
  @override
  Stream<String> stream(ModelRequest request) async* {
    callCount++;
    
    final words = 'Mock streaming response'.split(' ');
    for (final word in words) {
      await Future.delayed(const Duration(milliseconds: 50));
      yield '$word ';
    }
  }
  
  @override
  Future<List<ModelInfo>> listModels() async => availableModels;
  
  @override
  Future<ProviderHealth> checkHealth() async {
    return const ProviderHealth(
      providerId: 'mock_provider',
      isHealthy: true,
      latency: Duration(milliseconds: 100),
      errorRate: 0.0,
      metadata: {'mock': true},
    );
  }
  
  int _estimateTokens(String text) {
    return (text.length / 4).ceil();
  }
}