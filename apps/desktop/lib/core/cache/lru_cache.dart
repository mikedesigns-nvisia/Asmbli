import 'dart:collection';

/// LRU (Least Recently Used) cache implementation
class LRUCache<K, V> {
  final int maxSize;
  final LinkedHashMap<K, CacheEntry<V>> _cache = LinkedHashMap();
  final Duration defaultTTL;
  
  int _hits = 0;
  int _misses = 0;

  LRUCache({
    required this.maxSize,
    this.defaultTTL = const Duration(hours: 1),
  }) {
    assert(maxSize > 0, 'Cache size must be positive');
  }

  /// Get value from cache
  V? get(K key) {
    final entry = _cache[key];
    
    if (entry == null) {
      _misses++;
      return null;
    }
    
    // Check if expired
    if (entry.isExpired) {
      _cache.remove(key);
      _misses++;
      return null;
    }
    
    // Move to end (mark as recently used)
    _cache.remove(key);
    _cache[key] = entry.touch();
    
    _hits++;
    return entry.value;
  }

  /// Put value in cache
  void put(K key, V value, {Duration? ttl}) {
    final entry = CacheEntry(
      value: value,
      createdAt: DateTime.now(),
      ttl: ttl ?? defaultTTL,
    );

    // If key exists, update it
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    }
    // If at capacity, remove least recently used
    else if (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first);
    }

    _cache[key] = entry;
  }

  /// Check if key exists and is not expired
  bool containsKey(K key) {
    final entry = _cache[key];
    if (entry == null) return false;
    
    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }
    
    return true;
  }

  /// Remove key from cache
  V? remove(K key) {
    final entry = _cache.remove(key);
    return entry?.value;
  }

  /// Clear all entries
  void clear() {
    _cache.clear();
    _hits = 0;
    _misses = 0;
  }

  /// Remove expired entries
  void evictExpired() {
    final expiredKeys = <K>[];
    
    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _cache.remove(key);
    }
  }

  /// Get all keys
  Iterable<K> get keys => _cache.keys;

  /// Get all values (non-expired)
  Iterable<V> get values {
    evictExpired();
    return _cache.values.map((entry) => entry.value);
  }

  /// Current cache size
  int get length => _cache.length;

  /// Check if cache is empty
  bool get isEmpty => _cache.isEmpty;

  /// Check if cache is full
  bool get isFull => _cache.length >= maxSize;

  /// Cache hit ratio
  double get hitRatio {
    final total = _hits + _misses;
    return total > 0 ? _hits / total : 0.0;
  }

  /// Cache statistics
  CacheStats get stats => CacheStats(
    size: _cache.length,
    maxSize: maxSize,
    hits: _hits,
    misses: _misses,
    hitRatio: hitRatio,
  );

  /// Reset statistics
  void resetStats() {
    _hits = 0;
    _misses = 0;
  }

  @override
  String toString() {
    return 'LRUCache(size: ${_cache.length}/$maxSize, hitRatio: ${(hitRatio * 100).toStringAsFixed(1)}%)';
  }
}

/// Cache entry with expiration support
class CacheEntry<V> {
  final V value;
  final DateTime createdAt;
  final DateTime lastAccessedAt;
  final Duration ttl;

  CacheEntry({
    required this.value,
    required this.createdAt,
    DateTime? lastAccessedAt,
    required this.ttl,
  }) : lastAccessedAt = lastAccessedAt ?? createdAt;

  /// Check if entry is expired
  bool get isExpired {
    return DateTime.now().difference(createdAt) > ttl;
  }

  /// Age of the entry
  Duration get age => DateTime.now().difference(createdAt);

  /// Time since last access
  Duration get timeSinceAccess => DateTime.now().difference(lastAccessedAt);

  /// Create a new entry with updated access time
  CacheEntry<V> touch() {
    return CacheEntry(
      value: value,
      createdAt: createdAt,
      lastAccessedAt: DateTime.now(),
      ttl: ttl,
    );
  }

  @override
  String toString() {
    return 'CacheEntry(value: $value, age: ${age.inMinutes}m, expired: $isExpired)';
  }
}

/// Cache statistics
class CacheStats {
  final int size;
  final int maxSize;
  final int hits;
  final int misses;
  final double hitRatio;

  const CacheStats({
    required this.size,
    required this.maxSize,
    required this.hits,
    required this.misses,
    required this.hitRatio,
  });

  Map<String, dynamic> toJson() {
    return {
      'size': size,
      'max_size': maxSize,
      'hits': hits,
      'misses': misses,
      'hit_ratio': hitRatio,
      'usage_percent': (size / maxSize) * 100,
    };
  }

  @override
  String toString() {
    return 'CacheStats(size: $size/$maxSize, hits: $hits, misses: $misses, hitRatio: ${(hitRatio * 100).toStringAsFixed(1)}%)';
  }
}

/// Cache with automatic cleanup
class AutoCleanupLRUCache<K, V> extends LRUCache<K, V> {
  Timer? _cleanupTimer;
  final Duration cleanupInterval;

  AutoCleanupLRUCache({
    required super.maxSize,
    super.defaultTTL,
    this.cleanupInterval = const Duration(minutes: 5),
  });

  /// Start automatic cleanup
  void startCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(cleanupInterval, (_) {
      evictExpired();
    });
  }

  /// Stop automatic cleanup
  void stopCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }

  @override
  void clear() {
    super.clear();
    stopCleanup();
  }
}

/// Specialized cache for different data types
class TypedCache {
  final LRUCache<String, String> _stringCache;
  final LRUCache<String, Map<String, dynamic>> _jsonCache;
  final LRUCache<String, List<int>> _binaryCache;

  TypedCache({
    int maxSize = 1000,
    Duration defaultTTL = const Duration(hours: 1),
  }) : _stringCache = LRUCache(maxSize: maxSize ~/ 3, defaultTTL: defaultTTL),
       _jsonCache = LRUCache(maxSize: maxSize ~/ 3, defaultTTL: defaultTTL),
       _binaryCache = LRUCache(maxSize: maxSize ~/ 3, defaultTTL: defaultTTL);

  /// Cache string data
  void putString(String key, String value, {Duration? ttl}) {
    _stringCache.put(key, value, ttl: ttl);
  }

  String? getString(String key) {
    return _stringCache.get(key);
  }

  /// Cache JSON data
  void putJson(String key, Map<String, dynamic> value, {Duration? ttl}) {
    _jsonCache.put(key, value, ttl: ttl);
  }

  Map<String, dynamic>? getJson(String key) {
    return _jsonCache.get(key);
  }

  /// Cache binary data
  void putBinary(String key, List<int> value, {Duration? ttl}) {
    _binaryCache.put(key, value, ttl: ttl);
  }

  List<int>? getBinary(String key) {
    return _binaryCache.get(key);
  }

  /// Get combined statistics
  CombinedCacheStats get stats => CombinedCacheStats(
    stringCache: _stringCache.stats,
    jsonCache: _jsonCache.stats,
    binaryCache: _binaryCache.stats,
  );

  /// Clear all caches
  void clear() {
    _stringCache.clear();
    _jsonCache.clear();
    _binaryCache.clear();
  }
}

/// Combined cache statistics
class CombinedCacheStats {
  final CacheStats stringCache;
  final CacheStats jsonCache;
  final CacheStats binaryCache;

  const CombinedCacheStats({
    required this.stringCache,
    required this.jsonCache,
    required this.binaryCache,
  });

  int get totalSize => stringCache.size + jsonCache.size + binaryCache.size;
  int get totalMaxSize => stringCache.maxSize + jsonCache.maxSize + binaryCache.maxSize;
  int get totalHits => stringCache.hits + jsonCache.hits + binaryCache.hits;
  int get totalMisses => stringCache.misses + jsonCache.misses + binaryCache.misses;
  double get overallHitRatio => totalHits + totalMisses > 0 ? totalHits / (totalHits + totalMisses) : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'total_size': totalSize,
      'total_max_size': totalMaxSize,
      'total_hits': totalHits,
      'total_misses': totalMisses,
      'overall_hit_ratio': overallHitRatio,
      'string_cache': stringCache.toJson(),
      'json_cache': jsonCache.toJson(),
      'binary_cache': binaryCache.toJson(),
    };
  }

  @override
  String toString() {
    return 'CombinedCacheStats(totalSize: $totalSize/$totalMaxSize, overallHitRatio: ${(overallHitRatio * 100).toStringAsFixed(1)}%)';
  }
}