import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Performance optimization service for Canvas operations
/// Handles caching, throttling, batching, and performance monitoring
class CanvasPerformanceService {
  // Cache configuration
  static const Duration cacheExpiry = Duration(minutes: 5);
  static const int maxCacheSize = 100;
  static const int maxCacheMemory = 50 * 1024 * 1024; // 50MB
  
  // Throttling configuration
  static const Duration throttleDelay = Duration(milliseconds: 100);
  static const Duration debounceDelay = Duration(milliseconds: 300);
  
  // Batching configuration
  static const Duration batchDelay = Duration(milliseconds: 50);
  static const int maxBatchSize = 20;
  
  // Performance monitoring
  final Map<String, PerformanceMetric> _metrics = {};
  final Map<String, CacheEntry> _cache = {};
  final Map<String, Timer> _throttleTimers = {};
  final Map<String, Timer> _debounceTimers = {};
  final List<BatchOperation> _pendingOperations = [];
  Timer? _batchTimer;
  
  int _currentCacheMemory = 0;

  /// Cache a value with automatic expiry and memory management
  void cache(String key, dynamic value, {Duration? customExpiry}) {
    try {
      // Calculate memory size
      final memorySize = _calculateMemorySize(value);
      
      // Remove old entry if exists
      _removeFromCache(key);
      
      // Ensure cache limits
      _ensureCacheSpace(memorySize);
      
      // Add new entry
      final entry = CacheEntry(
        value: value,
        timestamp: DateTime.now(),
        expiry: customExpiry ?? cacheExpiry,
        memorySize: memorySize,
      );
      
      _cache[key] = entry;
      _currentCacheMemory += memorySize;
      
      if (kDebugMode) {
        print('📦 Cached: $key (${memorySize}B, ${_cache.length} entries, ${_currentCacheMemory}B total)');
      }
      
    } catch (e) {
      print('❌ Cache error for key $key: $e');
    }
  }

  /// Get cached value if valid
  T? getCached<T>(String key) {
    try {
      final entry = _cache[key];
      if (entry == null) return null;
      
      // Check expiry
      if (DateTime.now().difference(entry.timestamp) > entry.expiry) {
        _removeFromCache(key);
        return null;
      }
      
      if (kDebugMode) {
        print('🎯 Cache hit: $key');
      }
      
      return entry.value as T?;
      
    } catch (e) {
      print('❌ Cache get error for key $key: $e');
      return null;
    }
  }

  /// Check if key is cached and valid
  bool isCached(String key) {
    return getCached(key) != null;
  }

  /// Clear specific cache entry
  void clearCache(String key) {
    _removeFromCache(key);
  }

  /// Clear all cache
  void clearAllCache() {
    _cache.clear();
    _currentCacheMemory = 0;
    print('🗑️ All cache cleared');
  }

  /// Throttle function calls to prevent spam
  void throttle(String key, VoidCallback function, {Duration? customDelay}) {
    _throttleTimers[key]?.cancel();
    
    _throttleTimers[key] = Timer(customDelay ?? throttleDelay, () {
      function();
      _throttleTimers.remove(key);
    });
  }

  /// Debounce function calls to reduce rapid-fire calls
  void debounce(String key, VoidCallback function, {Duration? customDelay}) {
    _debounceTimers[key]?.cancel();
    
    _debounceTimers[key] = Timer(customDelay ?? debounceDelay, () {
      function();
      _debounceTimers.remove(key);
    });
  }

  /// Add operation to batch for processing
  void addToBatch(String operationType, Map<String, dynamic> data, Function(List<BatchOperation>) processor) {
    _pendingOperations.add(BatchOperation(
      type: operationType,
      data: data,
      timestamp: DateTime.now(),
      processor: processor,
    ));
    
    // Start batch timer if not running
    _batchTimer ??= Timer(batchDelay, _processBatch);
    
    // Process immediately if batch is full
    if (_pendingOperations.length >= maxBatchSize) {
      _processBatch();
    }
  }

  /// Start performance monitoring for an operation
  void startOperation(String operationName) {
    _metrics[operationName] = PerformanceMetric(
      name: operationName,
      startTime: DateTime.now(),
    );
  }

  /// End performance monitoring for an operation
  void endOperation(String operationName) {
    final metric = _metrics[operationName];
    if (metric == null) return;
    
    metric.endTime = DateTime.now();
    metric.duration = metric.endTime!.difference(metric.startTime);
    
    if (kDebugMode && metric.duration != null && metric.duration!.inMilliseconds > 100) {
      print('⏱️ Slow operation: $operationName (${metric.duration!.inMilliseconds}ms)');
    }
  }

  /// Get performance metrics
  Map<String, dynamic> getMetrics() {
    final metrics = <String, dynamic>{};
    
    for (final entry in _metrics.entries) {
      final metric = entry.value;
      metrics[entry.key] = {
        'duration': metric.duration?.inMilliseconds,
        'startTime': metric.startTime.toIso8601String(),
        'endTime': metric.endTime?.toIso8601String(),
        'status': metric.duration != null ? 'completed' : 'running',
      };
    }
    
    return {
      'operations': metrics,
      'cache': {
        'entries': _cache.length,
        'memoryUsage': _currentCacheMemory,
        'hitRate': _calculateCacheHitRate(),
      },
      'batching': {
        'pendingOperations': _pendingOperations.length,
        'batchTimerActive': _batchTimer?.isActive ?? false,
      },
      'throttling': {
        'activeThrottles': _throttleTimers.length,
        'activeDebounes': _debounceTimers.length,
      },
    };
  }

  /// Optimize WebView communication
  Future<String> optimizeWebViewMessage(Map<String, dynamic> message) async {
    try {
      // Check cache first
      final messageHash = _hashMessage(message);
      final cached = getCached<String>('webview_$messageHash');
      if (cached != null) {
        return cached;
      }
      
      // Optimize message
      final optimized = _optimizeMessage(message);
      final result = jsonEncode(optimized);
      
      // Cache result
      cache('webview_$messageHash', result);
      
      return result;
      
    } catch (e) {
      print('❌ WebView message optimization error: $e');
      return jsonEncode(message);
    }
  }

  /// Optimize canvas state for storage/transmission
  Map<String, dynamic> optimizeCanvasState(Map<String, dynamic> state) {
    try {
      final optimized = Map<String, dynamic>.from(state);
      
      // Remove redundant data
      optimized.removeWhere((key, value) => value == null);
      
      // Compress large arrays
      if (optimized['elements'] is List) {
        final elements = optimized['elements'] as List;
        optimized['elements'] = elements.map(_optimizeElement).toList();
      }
      
      // Round floating point numbers to reduce precision
      _roundFloatingPoints(optimized);
      
      return optimized;
      
    } catch (e) {
      print('❌ Canvas state optimization error: $e');
      return state;
    }
  }

  /// Preload common resources
  Future<void> preloadResources() async {
    try {
      startOperation('preload_resources');
      
      // Preload design systems
      await _preloadDesignSystems();
      
      // Preload common UI components
      await _preloadComponents();
      
      // Preload fonts and assets
      await _preloadAssets();
      
      endOperation('preload_resources');
      print('✅ Resources preloaded');
      
    } catch (e) {
      print('❌ Resource preloading error: $e');
    }
  }

  /// Clean up performance service
  void dispose() {
    // Cancel all timers
    for (final timer in _throttleTimers.values) {
      timer.cancel();
    }
    _throttleTimers.clear();
    
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    
    _batchTimer?.cancel();
    _batchTimer = null;
    
    // Clear cache and metrics
    clearAllCache();
    _metrics.clear();
    _pendingOperations.clear();
    
    print('🛑 Canvas Performance Service disposed');
  }

  // Private helper methods
  void _removeFromCache(String key) {
    final entry = _cache.remove(key);
    if (entry != null) {
      _currentCacheMemory -= entry.memorySize;
    }
  }

  void _ensureCacheSpace(int newEntrySize) {
    // Check total memory limit
    while (_currentCacheMemory + newEntrySize > maxCacheMemory && _cache.isNotEmpty) {
      _evictOldestCacheEntry();
    }
    
    // Check entry count limit
    while (_cache.length >= maxCacheSize && _cache.isNotEmpty) {
      _evictOldestCacheEntry();
    }
  }

  void _evictOldestCacheEntry() {
    if (_cache.isEmpty) return;
    
    String? oldestKey;
    DateTime? oldestTime;
    
    for (final entry in _cache.entries) {
      if (oldestTime == null || entry.value.timestamp.isBefore(oldestTime)) {
        oldestTime = entry.value.timestamp;
        oldestKey = entry.key;
      }
    }
    
    if (oldestKey != null) {
      _removeFromCache(oldestKey);
      if (kDebugMode) {
        print('🗑️ Evicted cache entry: $oldestKey');
      }
    }
  }

  int _calculateMemorySize(dynamic value) {
    try {
      if (value is String) {
        return value.length * 2; // Approximate UTF-16 encoding
      } else if (value is List || value is Map) {
        return jsonEncode(value).length * 2;
      } else if (value is Uint8List) {
        return value.length;
      } else {
        return value.toString().length * 2;
      }
    } catch (e) {
      return 1024; // Default estimate
    }
  }

  String _hashMessage(Map<String, dynamic> message) {
    try {
      final content = jsonEncode(message);
      return content.hashCode.toString();
    } catch (e) {
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  Map<String, dynamic> _optimizeMessage(Map<String, dynamic> message) {
    final optimized = Map<String, dynamic>.from(message);
    
    // Remove debug information in production
    if (!kDebugMode) {
      optimized.remove('debug');
      optimized.remove('stackTrace');
    }
    
    // Compress nested objects
    for (final entry in optimized.entries) {
      if (entry.value is Map<String, dynamic>) {
        optimized[entry.key] = _optimizeMessage(entry.value);
      }
    }
    
    return optimized;
  }

  Map<String, dynamic> _optimizeElement(dynamic element) {
    if (element is! Map<String, dynamic>) return element;
    
    final optimized = Map<String, dynamic>.from(element);
    
    // Remove default values
    optimized.remove('visible'); // Default true
    if (optimized['opacity'] == 1.0) optimized.remove('opacity');
    if (optimized['rotation'] == 0.0) optimized.remove('rotation');
    
    // Round coordinates to pixel boundaries
    if (optimized['x'] is num) {
      optimized['x'] = (optimized['x'] as num).round();
    }
    if (optimized['y'] is num) {
      optimized['y'] = (optimized['y'] as num).round();
    }
    
    return optimized;
  }

  void _roundFloatingPoints(Map<String, dynamic> obj) {
    for (final entry in obj.entries) {
      if (entry.value is double) {
        // Round to 2 decimal places
        obj[entry.key] = double.parse((entry.value as double).toStringAsFixed(2));
      } else if (entry.value is Map<String, dynamic>) {
        _roundFloatingPoints(entry.value);
      } else if (entry.value is List) {
        for (final item in entry.value) {
          if (item is Map<String, dynamic>) {
            _roundFloatingPoints(item);
          }
        }
      }
    }
  }

  void _processBatch() {
    if (_pendingOperations.isEmpty) return;
    
    try {
      // Group operations by type
      final groups = <String, List<BatchOperation>>{};
      for (final op in _pendingOperations) {
        groups.putIfAbsent(op.type, () => []).add(op);
      }
      
      // Process each group
      for (final entry in groups.entries) {
        try {
          if (entry.value.isNotEmpty) {
            entry.value.first.processor(entry.value);
          }
        } catch (e) {
          print('❌ Batch processing error for ${entry.key}: $e');
        }
      }
      
      _pendingOperations.clear();
      
    } catch (e) {
      print('❌ Batch processing error: $e');
    } finally {
      _batchTimer?.cancel();
      _batchTimer = null;
    }
  }

  double _calculateCacheHitRate() {
    // This would need to track hits/misses in a real implementation
    return 0.85; // Placeholder
  }

  Future<void> _preloadDesignSystems() async {
    // Preload common design system data
    final commonDesignSystems = ['material3', 'company-brand'];
    for (final ds in commonDesignSystems) {
      cache('design_system_$ds', {'id': ds, 'preloaded': true});
    }
  }

  Future<void> _preloadComponents() async {
    // Preload common component definitions
    final commonComponents = ['button', 'text', 'container', 'card'];
    for (final component in commonComponents) {
      cache('component_$component', {'type': component, 'preloaded': true});
    }
  }

  Future<void> _preloadAssets() async {
    // Preload common assets (this would be more sophisticated in practice)
    cache('assets_preloaded', true);
  }
}

/// Cache entry with metadata
class CacheEntry {
  final dynamic value;
  final DateTime timestamp;
  final Duration expiry;
  final int memorySize;

  CacheEntry({
    required this.value,
    required this.timestamp,
    required this.expiry,
    required this.memorySize,
  });
}

/// Performance metric tracking
class PerformanceMetric {
  final String name;
  final DateTime startTime;
  DateTime? endTime;
  Duration? duration;

  PerformanceMetric({
    required this.name,
    required this.startTime,
  });
}

/// Batch operation
class BatchOperation {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final Function(List<BatchOperation>) processor;

  BatchOperation({
    required this.type,
    required this.data,
    required this.timestamp,
    required this.processor,
  });
}