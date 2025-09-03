import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'lru_cache.dart';
import 'file_cache.dart';

/// Multi-level cache manager with L1 (memory), L2 (Redis), and L3 (disk) caches
class CacheManager {
  // L1: In-memory cache
  late final LRUCache<String, dynamic> _memoryCache;
  
  // L2: Redis cache (optional, fallback to memory if not available)
  RedisClient? _redis;
  bool _redisAvailable = false;
  
  // L3: Disk cache
  late final FileCache _diskCache;
  
  final CacheManagerConfig _config;
  bool _isInitialized = false;
  
  // Cache statistics
  final CacheStatistics _stats = CacheStatistics();
  Timer? _statsTimer;

  CacheManager({
    CacheManagerConfig? config,
  }) : _config = config ?? const CacheManagerConfig();

  /// Initialize all cache levels
  Future<void> initialize() async {
    if (_isInitialized) return;


    try {
      // Initialize L1: Memory cache
      _memoryCache = LRUCache<String, dynamic>(
        maxSize: _config.memoryMaxSize,
        defaultTTL: _config.defaultTTL,
      );

      // Initialize L2: Redis cache (optional)
      if (_config.enableRedis) {
        await _initializeRedis();
      }

      // Initialize L3: Disk cache
      await _initializeDiskCache();

      // Start statistics collection
      _startStatsCollection();

      _isInitialized = true;
      
      await _printCacheStatus();
    } catch (e) {
      throw CacheException('Failed to initialize cache manager: $e');
    }
  }

  /// Get value from cache (L1 -> L2 -> L3)
  Future<T?> get<T>(String key, {CacheLevel? level}) async {
    _ensureInitialized();
    
    final startTime = DateTime.now();
    T? value;
    CacheLevel hitLevel = CacheLevel.miss;

    try {
      // Check specific level if requested
      if (level != null) {
        value = await _getFromLevel<T>(key, level);
        if (value != null) hitLevel = level;
      } else {
        // Check L1: Memory cache
        value = _memoryCache.get(key) as T?;
        if (value != null) {
          hitLevel = CacheLevel.memory;
        } else {
          // Check L2: Redis cache
          if (_redisAvailable) {
            value = await _getFromRedis<T>(key);
            if (value != null) {
              // Promote to L1
              _memoryCache.put(key, value);
              hitLevel = CacheLevel.redis;
            }
          }
          
          if (value == null) {
            // Check L3: Disk cache
            value = await _diskCache.get<T>(key);
            if (value != null) {
              // Promote to higher levels
              _memoryCache.put(key, value);
              if (_redisAvailable) {
                await _setToRedis(key, value);
              }
              hitLevel = CacheLevel.disk;
            }
          }
        }
      }

      // Update statistics
      final latency = DateTime.now().difference(startTime);
      if (value != null) {
        _stats.recordHit(hitLevel, latency);
      } else {
        _stats.recordMiss(latency);
      }

      return value;
    } catch (e) {
      debugPrint('Cache get error for key $key: $e');
      _stats.recordError();
      return null;
    }
  }

  /// Set value in cache (all levels by default)
  Future<void> set(
    String key,
    dynamic value, {
    Duration? ttl,
    Set<CacheLevel>? levels,
  }) async {
    _ensureInitialized();
    
    final cacheLevels = levels ?? _config.defaultLevels;
    final cacheTTL = ttl ?? _config.defaultTTL;

    try {
      // Set to requested levels
      final futures = <Future<void>>[];

      if (cacheLevels.contains(CacheLevel.memory)) {
        _memoryCache.put(key, value, ttl: cacheTTL);
      }

      if (cacheLevels.contains(CacheLevel.redis) && _redisAvailable) {
        futures.add(_setToRedis(key, value, ttl: cacheTTL));
      }

      if (cacheLevels.contains(CacheLevel.disk)) {
        futures.add(_diskCache.put(key, value, ttl: cacheTTL));
      }

      // Wait for all async operations
      await Future.wait(futures);

      _stats.recordSet();
    } catch (e) {
      debugPrint('Cache set error for key $key: $e');
      _stats.recordError();
      rethrow;
    }
  }

  /// Check if key exists in any cache level
  Future<bool> containsKey(String key, {CacheLevel? level}) async {
    _ensureInitialized();

    try {
      if (level != null) {
        return await _containsKeyInLevel(key, level);
      }

      // Check all levels
      if (_memoryCache.containsKey(key)) return true;
      
      if (_redisAvailable && await _containsKeyInRedis(key)) return true;
      
      return await _diskCache.containsKey(key);
    } catch (e) {
      debugPrint('Cache containsKey error for key $key: $e');
      return false;
    }
  }

  /// Remove key from all cache levels
  Future<bool> remove(String key, {Set<CacheLevel>? levels}) async {
    _ensureInitialized();

    final removeLevels = levels ?? CacheLevel.values.toSet();
    bool removed = false;

    try {
      if (removeLevels.contains(CacheLevel.memory)) {
        removed = _memoryCache.remove(key) != null || removed;
      }

      if (removeLevels.contains(CacheLevel.redis) && _redisAvailable) {
        removed = await _removeFromRedis(key) || removed;
      }

      if (removeLevels.contains(CacheLevel.disk)) {
        removed = await _diskCache.remove(key) || removed;
      }

      if (removed) {
        _stats.recordDelete();
      }

      return removed;
    } catch (e) {
      debugPrint('Cache remove error for key $key: $e');
      return false;
    }
  }

  /// Clear all cache levels
  Future<void> clear({Set<CacheLevel>? levels}) async {
    _ensureInitialized();

    final clearLevels = levels ?? CacheLevel.values.toSet();

    try {
      final futures = <Future<void>>[];

      if (clearLevels.contains(CacheLevel.memory)) {
        _memoryCache.clear();
      }

      if (clearLevels.contains(CacheLevel.redis) && _redisAvailable) {
        futures.add(_clearRedis());
      }

      if (clearLevels.contains(CacheLevel.disk)) {
        futures.add(_diskCache.clear());
      }

      await Future.wait(futures);

    } catch (e) {
      debugPrint('Cache clear error: $e');
      rethrow;
    }
  }

  /// Generate intelligent cache key
  String generateKey(String prefix, Map<String, dynamic> params) {
    // Sort parameters for consistent key generation
    final sorted = SplayTreeMap<String, dynamic>.from(params);
    
    // Remove null values and normalize
    final normalized = <String, dynamic>{};
    for (final entry in sorted.entries) {
      if (entry.value != null) {
        normalized[entry.key] = entry.value;
      }
    }

    // Generate hash
    final hash = sha256.convert(
      utf8.encode(jsonEncode(normalized)),
    ).toString();

    return '$prefix:${hash.substring(0, 16)}';
  }

  /// Get cache statistics
  CacheManagerStats getStats() {
    return CacheManagerStats(
      statistics: _stats,
      memoryStats: _memoryCache.stats,
      diskStats: _diskCache.stats,
      redisAvailable: _redisAvailable,
    );
  }

  /// Perform cache maintenance
  Future<void> performMaintenance() async {
    _ensureInitialized();


    try {
      // Memory cache cleanup
      _memoryCache.evictExpired();

      // Disk cache cleanup is automatic via FileCache
      
      // Redis cleanup (if available)
      if (_redisAvailable) {
        await _performRedisCleanup();
      }

    } catch (e) {
      debugPrint('Cache maintenance error: $e');
    }
  }

  /// Initialize Redis connection
  Future<void> _initializeRedis() async {
    try {
      
      _redis = await RedisClient.connect(
        _config.redisHost,
        _config.redisPort,
        password: _config.redisPassword,
        timeout: _config.redisTimeout,
      );

      // Test connection
      await _redis!.ping();
      
      _redisAvailable = true;
    } catch (e) {
      debugPrint('Redis connection failed, using memory fallback: $e');
      _redisAvailable = false;
    }
  }

  /// Initialize disk cache
  Future<void> _initializeDiskCache() async {
    final cacheDir = Directory.fromUri(
      (await getApplicationCacheDirectory()).uri.resolve('app_cache'),
    );

    _diskCache = FileCache(
      directory: cacheDir,
      maxSizeGB: _config.diskMaxSizeGB,
      defaultTTL: _config.defaultTTL,
    );

    await _diskCache.initialize();
  }

  /// Get value from specific cache level
  Future<T?> _getFromLevel<T>(String key, CacheLevel level) async {
    switch (level) {
      case CacheLevel.memory:
        return _memoryCache.get(key) as T?;
      case CacheLevel.redis:
        return _redisAvailable ? await _getFromRedis<T>(key) : null;
      case CacheLevel.disk:
        return await _diskCache.get<T>(key);
      case CacheLevel.miss:
        return null;
    }
  }

  /// Check if key exists in specific level
  Future<bool> _containsKeyInLevel(String key, CacheLevel level) async {
    switch (level) {
      case CacheLevel.memory:
        return _memoryCache.containsKey(key);
      case CacheLevel.redis:
        return _redisAvailable ? await _containsKeyInRedis(key) : false;
      case CacheLevel.disk:
        return await _diskCache.containsKey(key);
      case CacheLevel.miss:
        return false;
    }
  }

  /// Redis operations
  Future<T?> _getFromRedis<T>(String key) async {
    try {
      final value = await _redis!.get(key);
      if (value == null) return null;
      
      return jsonDecode(value) as T;
    } catch (e) {
      return null;
    }
  }

  Future<void> _setToRedis(String key, dynamic value, {Duration? ttl}) async {
    try {
      final serialized = jsonEncode(value);
      if (ttl != null) {
        await _redis!.setex(key, ttl.inSeconds, serialized);
      } else {
        await _redis!.set(key, serialized);
      }
    } catch (e) {
    }
  }

  Future<bool> _containsKeyInRedis(String key) async {
    try {
      return await _redis!.exists(key) > 0;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _removeFromRedis(String key) async {
    try {
      return await _redis!.del([key]) > 0;
    } catch (e) {
      return false;
    }
  }

  Future<void> _clearRedis() async {
    try {
      await _redis!.flushdb();
    } catch (e) {
    }
  }

  Future<void> _performRedisCleanup() async {
    // Redis handles expiration automatically, but we could implement
    // custom cleanup logic here if needed
  }

  /// Start statistics collection
  void _startStatsCollection() {
    _statsTimer = Timer.periodic(_config.statsInterval, (_) {
      // Could implement periodic stats reporting here
    });
  }

  /// Print current cache status
  Future<void> _printCacheStatus() async {
    // Removed verbose cache status logging
  }

  /// Ensure cache manager is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw const CacheException('Cache manager not initialized. Call initialize() first.');
    }
  }

  /// Dispose of all resources
  Future<void> dispose() async {
    if (!_isInitialized) return;


    _statsTimer?.cancel();
    
    if (_redisAvailable) {
      await _redis?.disconnect();
    }
    
    await _diskCache.dispose();
    
    _isInitialized = false;
  }
}

/// Cache levels in order of preference
enum CacheLevel {
  memory,
  redis,
  disk,
  miss, // Used for statistics
}

/// Cache manager configuration
class CacheManagerConfig {
  final int memoryMaxSize;
  final bool enableRedis;
  final String redisHost;
  final int redisPort;
  final String? redisPassword;
  final Duration redisTimeout;
  final int diskMaxSizeGB;
  final Duration defaultTTL;
  final Set<CacheLevel> defaultLevels;
  final Duration statsInterval;

  const CacheManagerConfig({
    this.memoryMaxSize = 1000,
    this.enableRedis = false, // Disabled by default since Redis might not be available
    this.redisHost = 'localhost',
    this.redisPort = 6379,
    this.redisPassword,
    this.redisTimeout = const Duration(seconds: 5),
    this.diskMaxSizeGB = 5,
    this.defaultTTL = const Duration(hours: 24),
    this.defaultLevels = const {CacheLevel.memory, CacheLevel.disk},
    this.statsInterval = const Duration(minutes: 5),
  });
}

/// Cache statistics tracking
class CacheStatistics {
  int _hits = 0;
  int _misses = 0;
  int _sets = 0;
  int _deletes = 0;
  int _errors = 0;
  
  final Map<CacheLevel, int> _hitsByLevel = {};
  final Map<CacheLevel, Duration> _latencyByLevel = {};
  final Map<CacheLevel, int> _hitCountByLevel = {};

  void recordHit(CacheLevel level, Duration latency) {
    _hits++;
    _hitsByLevel[level] = (_hitsByLevel[level] ?? 0) + 1;
    
    // Update average latency
    final currentCount = _hitCountByLevel[level] ?? 0;
    final currentTotal = _latencyByLevel[level] ?? Duration.zero;
    _hitCountByLevel[level] = currentCount + 1;
    _latencyByLevel[level] = Duration(
      microseconds: ((currentTotal.inMicroseconds * currentCount) + latency.inMicroseconds) ~/ (currentCount + 1),
    );
  }

  void recordMiss(Duration latency) {
    _misses++;
  }

  void recordSet() {
    _sets++;
  }

  void recordDelete() {
    _deletes++;
  }

  void recordError() {
    _errors++;
  }

  int get hits => _hits;
  int get misses => _misses;
  int get sets => _sets;
  int get deletes => _deletes;
  int get errors => _errors;
  int get totalRequests => _hits + _misses;
  
  double get hitRatio => totalRequests > 0 ? _hits / totalRequests : 0.0;
  
  Map<CacheLevel, int> get hitsByLevel => Map.unmodifiable(_hitsByLevel);
  Map<CacheLevel, Duration> get averageLatencyByLevel => Map.unmodifiable(_latencyByLevel);
}

/// Combined cache manager statistics
class CacheManagerStats {
  final CacheStatistics statistics;
  final CacheStats memoryStats;
  final FileCacheStats diskStats;
  final bool redisAvailable;

  const CacheManagerStats({
    required this.statistics,
    required this.memoryStats,
    required this.diskStats,
    required this.redisAvailable,
  });

  Map<String, dynamic> toJson() {
    return {
      'hit_ratio': statistics.hitRatio,
      'total_requests': statistics.totalRequests,
      'hits': statistics.hits,
      'misses': statistics.misses,
      'sets': statistics.sets,
      'deletes': statistics.deletes,
      'errors': statistics.errors,
      'hits_by_level': statistics.hitsByLevel.map((k, v) => MapEntry(k.name, v)),
      'memory_stats': memoryStats.toJson(),
      'disk_stats': diskStats.toJson(),
      'redis_available': redisAvailable,
    };
  }

  @override
  String toString() {
    return 'CacheManagerStats(hitRatio: ${(statistics.hitRatio * 100).toStringAsFixed(1)}%, requests: ${statistics.totalRequests}, redis: $redisAvailable)';
  }
}

/// Mock Redis client for development (when Redis is not available)
class RedisClient {
  static Future<RedisClient> connect(
    String host,
    int port, {
    String? password,
    Duration? timeout,
  }) async {
    // In a real implementation, this would connect to Redis
    // For now, we'll throw an exception to simulate Redis being unavailable
    throw Exception('Redis not available in development mode');
  }

  Future<String> ping() async => 'PONG';
  Future<String?> get(String key) async => null;
  Future<void> set(String key, String value) async {}
  Future<void> setex(String key, int seconds, String value) async {}
  Future<int> exists(String key) async => 0;
  Future<int> del(List<String> keys) async => 0;
  Future<void> flushdb() async {}
  Future<void> disconnect() async {}
}

/// Cache exception
class CacheException implements Exception {
  final String message;
  final dynamic originalError;

  const CacheException(this.message, [this.originalError]);

  @override
  String toString() {
    final buffer = StringBuffer('CacheException: $message');
    if (originalError != null) {
      buffer.write(' (caused by: $originalError)');
    }
    return buffer.toString();
  }
}