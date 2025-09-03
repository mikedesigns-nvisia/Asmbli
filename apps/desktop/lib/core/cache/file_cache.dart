import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

/// File-based cache for persistent storage
class FileCache {
  final Directory directory;
  final int maxSizeBytes;
  final Duration defaultTTL;
  
  // Cache metadata for tracking
  final Map<String, FileCacheEntry> _metadata = {};
  Timer? _cleanupTimer;
  
  bool _isInitialized = false;

  FileCache({
    required this.directory,
    int maxSizeGB = 5,
    this.defaultTTL = const Duration(days: 7),
    Duration cleanupInterval = const Duration(hours: 1),
  }) : maxSizeBytes = maxSizeGB * 1024 * 1024 * 1024 {
    // Start automatic cleanup
    _cleanupTimer = Timer.periodic(cleanupInterval, (_) {
      _performCleanup();
    });
  }

  /// Initialize the cache directory
  Future<void> initialize() async {
    if (_isInitialized) return;

    print('📁 Initializing file cache at: ${directory.path}');
    
    try {
      // Create directory if it doesn't exist
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Load existing metadata
      await _loadMetadata();
      
      // Perform initial cleanup
      await _performCleanup();
      
      _isInitialized = true;
      print('✅ File cache initialized with ${_metadata.length} entries');
    } catch (e) {
      throw CacheException('Failed to initialize file cache: $e');
    }
  }

  /// Store data in cache
  Future<void> put(
    String key,
    dynamic data, {
    Duration? ttl,
    CacheDataType type = CacheDataType.json,
  }) async {
    await _ensureInitialized();
    
    try {
      final fileName = _generateFileName(key);
      final filePath = path.join(directory.path, fileName);
      final file = File(filePath);
      
      // Serialize data based on type
      final bytes = _serializeData(data, type);
      
      // Write to disk
      await file.writeAsBytes(bytes);
      
      // Update metadata
      final entry = FileCacheEntry(
        key: key,
        fileName: fileName,
        size: bytes.length,
        type: type,
        createdAt: DateTime.now(),
        ttl: ttl ?? defaultTTL,
      );
      
      _metadata[key] = entry;
      await _saveMetadata();
      
      // Check if cleanup is needed
      await _ensureSizeLimit();
      
      print('💾 Cached: $key (${_formatBytes(bytes.length)})');
    } catch (e) {
      throw CacheException('Failed to cache data for key $key: $e');
    }
  }

  /// Retrieve data from cache
  Future<T?> get<T>(String key) async {
    await _ensureInitialized();
    
    final entry = _metadata[key];
    if (entry == null) {
      return null; // Cache miss
    }
    
    // Check if expired
    if (entry.isExpired) {
      await remove(key);
      return null;
    }
    
    try {
      final filePath = path.join(directory.path, entry.fileName);
      final file = File(filePath);
      
      if (!await file.exists()) {
        // File was deleted externally
        _metadata.remove(key);
        await _saveMetadata();
        return null;
      }
      
      // Read and deserialize
      final bytes = await file.readAsBytes();
      final data = _deserializeData(bytes, entry.type);
      
      // Update access time
      _metadata[key] = entry.touch();
      await _saveMetadata();
      
      return data as T?;
    } catch (e) {
      print('⚠️ Failed to read cached data for key $key: $e');
      await remove(key); // Remove corrupted entry
      return null;
    }
  }

  /// Check if key exists in cache
  Future<bool> containsKey(String key) async {
    await _ensureInitialized();
    
    final entry = _metadata[key];
    if (entry == null) return false;
    
    if (entry.isExpired) {
      await remove(key);
      return false;
    }
    
    return true;
  }

  /// Remove entry from cache
  Future<bool> remove(String key) async {
    await _ensureInitialized();
    
    final entry = _metadata.remove(key);
    if (entry == null) return false;
    
    try {
      final filePath = path.join(directory.path, entry.fileName);
      final file = File(filePath);
      
      if (await file.exists()) {
        await file.delete();
      }
      
      await _saveMetadata();
      print('🗑️ Removed from cache: $key');
      return true;
    } catch (e) {
      print('⚠️ Failed to remove cached file for key $key: $e');
      return false;
    }
  }

  /// Clear all cache entries
  Future<void> clear() async {
    await _ensureInitialized();
    
    print('🧹 Clearing file cache...');
    
    try {
      // Delete all cache files
      await for (final entity in directory.list()) {
        if (entity is File && entity.path != _metadataFilePath) {
          await entity.delete();
        }
      }
      
      // Clear metadata
      _metadata.clear();
      await _saveMetadata();
      
      print('✅ File cache cleared');
    } catch (e) {
      throw CacheException('Failed to clear cache: $e');
    }
  }

  /// Get cache statistics
  FileCacheStats get stats {
    final totalSize = _metadata.values.fold<int>(
      0, (sum, entry) => sum + entry.size,
    );
    
    final expiredCount = _metadata.values.where((e) => e.isExpired).length;
    
    return FileCacheStats(
      entryCount: _metadata.length,
      totalSizeBytes: totalSize,
      maxSizeBytes: maxSizeBytes,
      expiredEntries: expiredCount,
      usagePercent: maxSizeBytes > 0 ? (totalSize / maxSizeBytes) * 100 : 0,
      oldestEntry: _metadata.values.isNotEmpty
          ? _metadata.values.map((e) => e.createdAt).reduce(
              (a, b) => a.isBefore(b) ? a : b,
            )
          : null,
      newestEntry: _metadata.values.isNotEmpty
          ? _metadata.values.map((e) => e.createdAt).reduce(
              (a, b) => a.isAfter(b) ? a : b,
            )
          : null,
    );
  }

  /// Perform cleanup to remove expired entries and enforce size limits
  Future<void> _performCleanup() async {
    if (!_isInitialized) return;
    
    print('🧹 Performing file cache cleanup...');
    
    int removedCount = 0;
    int freedBytes = 0;
    
    // Remove expired entries
    final expiredKeys = <String>[];
    for (final entry in _metadata.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      final entry = _metadata[key]!;
      if (await remove(key)) {
        removedCount++;
        freedBytes += entry.size;
      }
    }
    
    // Enforce size limit
    await _ensureSizeLimit();
    
    if (removedCount > 0) {
      print('✅ Cleanup complete: removed $removedCount entries, freed ${_formatBytes(freedBytes)}');
    }
  }

  /// Ensure cache size is within limits
  Future<void> _ensureSizeLimit() async {
    final totalSize = _metadata.values.fold<int>(
      0, (sum, entry) => sum + entry.size,
    );
    
    if (totalSize <= maxSizeBytes) return;
    
    print('⚠️ Cache size limit exceeded, performing LRU eviction...');
    
    // Sort entries by last access time (LRU)
    final sortedEntries = _metadata.entries.toList()
      ..sort((a, b) => a.value.lastAccessedAt.compareTo(b.value.lastAccessedAt));
    
    int currentSize = totalSize;
    int removedCount = 0;
    
    for (final entry in sortedEntries) {
      if (currentSize <= maxSizeBytes) break;
      
      if (await remove(entry.key)) {
        currentSize -= entry.value.size;
        removedCount++;
      }
    }
    
    print('✅ LRU eviction complete: removed $removedCount entries');
  }

  /// Generate secure filename from key
  String _generateFileName(String key) {
    final hash = sha256.convert(utf8.encode(key));
    return '${hash.toString()}.cache';
  }

  /// Serialize data based on type
  Uint8List _serializeData(dynamic data, CacheDataType type) {
    switch (type) {
      case CacheDataType.json:
        return Uint8List.fromList(utf8.encode(jsonEncode(data)));
      case CacheDataType.string:
        return Uint8List.fromList(utf8.encode(data.toString()));
      case CacheDataType.binary:
        return data is Uint8List ? data : Uint8List.fromList(data as List<int>);
    }
  }

  /// Deserialize data based on type
  dynamic _deserializeData(Uint8List bytes, CacheDataType type) {
    switch (type) {
      case CacheDataType.json:
        return jsonDecode(utf8.decode(bytes));
      case CacheDataType.string:
        return utf8.decode(bytes);
      case CacheDataType.binary:
        return bytes;
    }
  }

  /// Load metadata from disk
  Future<void> _loadMetadata() async {
    final metadataFile = File(_metadataFilePath);
    
    if (!await metadataFile.exists()) {
      return; // No existing metadata
    }
    
    try {
      final content = await metadataFile.readAsString();
      final jsonData = jsonDecode(content) as Map<String, dynamic>;
      
      for (final entry in jsonData.entries) {
        _metadata[entry.key] = FileCacheEntry.fromJson(entry.value);
      }
      
      print('📋 Loaded metadata for ${_metadata.length} cache entries');
    } catch (e) {
      print('⚠️ Failed to load cache metadata: $e');
      // Continue with empty metadata
    }
  }

  /// Save metadata to disk
  Future<void> _saveMetadata() async {
    try {
      final metadataFile = File(_metadataFilePath);
      final jsonData = <String, dynamic>{};
      
      for (final entry in _metadata.entries) {
        jsonData[entry.key] = entry.value.toJson();
      }
      
      await metadataFile.writeAsString(jsonEncode(jsonData));
    } catch (e) {
      print('⚠️ Failed to save cache metadata: $e');
    }
  }

  /// Path to metadata file
  String get _metadataFilePath => path.join(directory.path, '.cache_metadata.json');

  /// Format bytes to human readable string
  String _formatBytes(int bytes) {
    if (bytes == 0) return '0 B';
    
    const units = ['B', 'KB', 'MB', 'GB'];
    int unitIndex = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    
    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  /// Ensure cache is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Dispose of the cache
  Future<void> dispose() async {
    _cleanupTimer?.cancel();
    await _saveMetadata();
    print('🧹 File cache disposed');
  }
}

/// Cache entry metadata
class FileCacheEntry {
  final String key;
  final String fileName;
  final int size;
  final CacheDataType type;
  final DateTime createdAt;
  final DateTime lastAccessedAt;
  final Duration ttl;

  FileCacheEntry({
    required this.key,
    required this.fileName,
    required this.size,
    required this.type,
    required this.createdAt,
    DateTime? lastAccessedAt,
    required this.ttl,
  }) : lastAccessedAt = lastAccessedAt ?? createdAt;

  bool get isExpired => DateTime.now().difference(createdAt) > ttl;
  Duration get age => DateTime.now().difference(createdAt);

  FileCacheEntry touch() {
    return FileCacheEntry(
      key: key,
      fileName: fileName,
      size: size,
      type: type,
      createdAt: createdAt,
      lastAccessedAt: DateTime.now(),
      ttl: ttl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'fileName': fileName,
      'size': size,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'lastAccessedAt': lastAccessedAt.toIso8601String(),
      'ttl': ttl.inMilliseconds,
    };
  }

  factory FileCacheEntry.fromJson(Map<String, dynamic> json) {
    return FileCacheEntry(
      key: json['key'],
      fileName: json['fileName'],
      size: json['size'],
      type: CacheDataType.values.byName(json['type']),
      createdAt: DateTime.parse(json['createdAt']),
      lastAccessedAt: DateTime.parse(json['lastAccessedAt']),
      ttl: Duration(milliseconds: json['ttl']),
    );
  }
}

/// File cache statistics
class FileCacheStats {
  final int entryCount;
  final int totalSizeBytes;
  final int maxSizeBytes;
  final int expiredEntries;
  final double usagePercent;
  final DateTime? oldestEntry;
  final DateTime? newestEntry;

  const FileCacheStats({
    required this.entryCount,
    required this.totalSizeBytes,
    required this.maxSizeBytes,
    required this.expiredEntries,
    required this.usagePercent,
    this.oldestEntry,
    this.newestEntry,
  });

  Map<String, dynamic> toJson() {
    return {
      'entry_count': entryCount,
      'total_size_bytes': totalSizeBytes,
      'max_size_bytes': maxSizeBytes,
      'expired_entries': expiredEntries,
      'usage_percent': usagePercent,
      'oldest_entry': oldestEntry?.toIso8601String(),
      'newest_entry': newestEntry?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'FileCacheStats(entries: $entryCount, usage: ${usagePercent.toStringAsFixed(1)}%, expired: $expiredEntries)';
  }
}

/// Types of data that can be cached
enum CacheDataType {
  json,
  string,
  binary,
}

/// Cache-related exceptions
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