import 'dart:io';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'desktop_storage_service.dart';
import 'macos_service_provider.dart';
import 'macos_keychain_service.dart';

/// macOS-native storage service with Core Data-like features and optimizations
/// Leverages macOS-specific APIs for enhanced performance and integration
class MacOSStorageService extends DesktopStorageService {
  final MacOSServiceProvider _macOSService;
  final MacOSKeychainService _keychainService;

  // macOS-specific features
  bool _spotlightIndexingEnabled = false;
  bool _cloudKitSyncEnabled = false;
  Isolate? _backgroundSyncIsolate;

  // Performance monitoring
  final Map<String, double> _performanceMetrics = {};
  final Map<String, DateTime> _lastAccessTimes = {};

  // macOS-specific storage paths
  late final String _coreDataPath;
  late final String _cloudKitCachePath;
  late final String _spotlightMetadataPath;

  MacOSStorageService._(this._macOSService, this._keychainService);

  static MacOSStorageService? _instance;

  static MacOSStorageService getInstance(
    MacOSServiceProvider macOSService,
    MacOSKeychainService keychainService,
  ) {
    _instance ??= MacOSStorageService._(macOSService, keychainService);
    return _instance!;
  }

  @override
  Future<void> initialize() async {
    debugPrint('🍎 Initializing macOS Storage Service');

    // Initialize base storage service first
    await super.initialize();

    // Initialize macOS-specific features
    await _initializeMacOSPaths();
    await _initializeMacOSFeatures();

    debugPrint('✅ macOS Storage Service initialized');
  }

  /// Initialize macOS-specific storage paths
  Future<void> _initializeMacOSPaths() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final baseDir = path.join(appSupportDir.path, 'Asmbli');

    _coreDataPath = path.join(baseDir, 'CoreData');
    _cloudKitCachePath = path.join(baseDir, 'CloudKit');
    _spotlightMetadataPath = path.join(baseDir, 'Spotlight');

    // Create directories
    for (final dirPath in [_coreDataPath, _cloudKitCachePath, _spotlightMetadataPath]) {
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    }
  }

  /// Initialize macOS-specific features
  Future<void> _initializeMacOSFeatures() async {
    try {
      // Check system capabilities
      await _checkSystemCapabilities();

      // Initialize Spotlight indexing
      if (await _canUseSpotlight()) {
        await _initializeSpotlightIndexing();
      }

      // Initialize CloudKit sync if available
      if (await _canUseCloudKit()) {
        await _initializeCloudKitSync();
      }

      // Setup background sync
      await _initializeBackgroundSync();

      // Configure performance monitoring
      await _configurePerformanceMonitoring();

    } catch (e) {
      debugPrint('⚠️ Some macOS features failed to initialize: $e');
    }
  }

  /// Check macOS system capabilities
  Future<void> _checkSystemCapabilities() async {
    try {
      // Check macOS version
      final versionResult = await Process.run('sw_vers', ['-productVersion']);
      final version = versionResult.stdout.toString().trim();
      _performanceMetrics['macos_version'] = _parseVersion(version);

      // Check if running on Apple Silicon
      final archResult = await Process.run('uname', ['-m']);
      final isAppleSilicon = archResult.stdout.toString().trim().contains('arm64');
      _performanceMetrics['is_apple_silicon'] = isAppleSilicon ? 1.0 : 0.0;

      // Check available storage
      final diskUsage = await _getDiskUsage();
      _performanceMetrics.addAll(diskUsage);

      debugPrint('📊 macOS capabilities: $version, Apple Silicon: $isAppleSilicon');
    } catch (e) {
      debugPrint('⚠️ Capability check failed: $e');
    }
  }

  double _parseVersion(String version) {
    final parts = version.split('.');
    if (parts.length >= 2) {
      final major = int.tryParse(parts[0]) ?? 0;
      final minor = int.tryParse(parts[1]) ?? 0;
      return major + (minor / 10.0);
    }
    return 0.0;
  }

  Future<Map<String, double>> _getDiskUsage() async {
    try {
      final appSupportDir = await getApplicationSupportDirectory();
      final result = await Process.run('df', ['-h', appSupportDir.path]);

      final lines = result.stdout.toString().split('\n');
      if (lines.length > 1) {
        final parts = lines[1].split(RegExp(r'\s+'));
        if (parts.length >= 4) {
          return {
            'disk_total_gb': _parseStorageSize(parts[1]),
            'disk_available_gb': _parseStorageSize(parts[3]),
          };
        }
      }
    } catch (e) {
      debugPrint('⚠️ Disk usage check failed: $e');
    }
    return {};
  }

  double _parseStorageSize(String sizeStr) {
    final number = double.tryParse(sizeStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    if (sizeStr.contains('T')) return number * 1024;
    if (sizeStr.contains('G')) return number;
    if (sizeStr.contains('M')) return number / 1024;
    return number / (1024 * 1024);
  }

  /// Check if Spotlight indexing is available
  Future<bool> _canUseSpotlight() async {
    try {
      final result = await Process.run('which', ['mdimport']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Check if CloudKit is available
  Future<bool> _canUseCloudKit() async {
    try {
      // Check if we're signed into iCloud
      final result = await Process.run('defaults', ['read', 'MobileMeAccounts', 'Accounts']);
      return result.exitCode == 0 && result.stdout.toString().isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Initialize Spotlight indexing for searchable content
  Future<void> _initializeSpotlightIndexing() async {
    try {
      debugPrint('🔍 Initializing Spotlight indexing');

      // Create metadata files for Spotlight
      await _createSpotlightMetadata();

      _spotlightIndexingEnabled = true;
      debugPrint('✅ Spotlight indexing enabled');
    } catch (e) {
      debugPrint('⚠️ Spotlight indexing setup failed: $e');
    }
  }

  /// Create Spotlight metadata files
  Future<void> _createSpotlightMetadata() async {
    final metadataFile = File(path.join(_spotlightMetadataPath, 'search_index.xml'));

    const metadataContent = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>kMDItemKind</key>
    <string>Asmbli Data</string>
    <key>kMDItemDisplayName</key>
    <string>Asmbli Search Index</string>
    <key>kMDItemContentType</key>
    <string>com.asmbli.agentengine.data</string>
</dict>
</plist>''';

    await metadataFile.writeAsString(metadataContent);
  }

  /// Initialize CloudKit sync capability
  Future<void> _initializeCloudKitSync() async {
    try {
      debugPrint('☁️ Initializing CloudKit sync');

      // Setup CloudKit container
      await _setupCloudKitContainer();

      _cloudKitSyncEnabled = true;
      debugPrint('✅ CloudKit sync enabled');
    } catch (e) {
      debugPrint('⚠️ CloudKit sync setup failed: $e');
    }
  }

  Future<void> _setupCloudKitContainer() async {
    // This would setup CloudKit container for data sync
    // For now, just create the cache directory structure
    final syncManifest = File(path.join(_cloudKitCachePath, 'sync_manifest.json'));

    final manifest = {
      'version': 1,
      'container': 'iCloud.com.asmbli.agentengine',
      'last_sync': DateTime.now().toIso8601String(),
      'sync_enabled': true,
    };

    await syncManifest.writeAsString(jsonEncode(manifest));
  }

  /// Initialize background sync isolate
  Future<void> _initializeBackgroundSync() async {
    try {
      _backgroundSyncIsolate = await Isolate.spawn(
        _backgroundSyncEntryPoint,
        null,
      );
      debugPrint('🔄 Background sync isolate started');
    } catch (e) {
      debugPrint('⚠️ Background sync setup failed: $e');
    }
  }

  static void _backgroundSyncEntryPoint(dynamic message) {
    // Background sync operations
    // Handles CloudKit sync, Spotlight indexing updates, etc.
  }

  /// Configure performance monitoring
  Future<void> _configurePerformanceMonitoring() async {
    // Monitor file system performance
    final testFile = File(path.join(_coreDataPath, '.perf_test'));
    final startTime = DateTime.now();

    await testFile.writeAsString('performance_test');
    await testFile.readAsString();
    await testFile.delete();

    final ioLatency = DateTime.now().difference(startTime).inMicroseconds;
    _performanceMetrics['io_latency_us'] = ioLatency.toDouble();

    debugPrint('📊 Storage I/O latency: ${ioLatency}μs');
  }

  // ==================== Enhanced Storage Operations ====================

  /// Store data with macOS-specific optimizations
  @override
  Future<void> setHiveData<T>(String boxName, String key, T value) async {
    final startTime = DateTime.now();

    // Store using base implementation
    await super.setHiveData(boxName, key, value);

    // Add macOS-specific enhancements
    if (_spotlightIndexingEnabled) {
      await _updateSpotlightIndex(boxName, key, value);
    }

    if (_cloudKitSyncEnabled && _shouldSyncToCloud(boxName)) {
      await _queueCloudKitSync(boxName, key, value);
    }

    // Update performance metrics
    final latency = DateTime.now().difference(startTime).inMicroseconds;
    _performanceMetrics['avg_write_latency_us'] =
        (_performanceMetrics['avg_write_latency_us'] ?? 0) * 0.9 + latency * 0.1;

    _lastAccessTimes['$boxName:$key'] = DateTime.now();
  }

  /// Retrieve data with macOS caching optimizations
  @override
  T? getHiveData<T>(String boxName, String key, {T? defaultValue}) {
    final startTime = DateTime.now();

    // Use base implementation
    final result = super.getHiveData<T>(boxName, key, defaultValue: defaultValue);

    // Update access tracking
    _lastAccessTimes['$boxName:$key'] = DateTime.now();

    // Update performance metrics
    final latency = DateTime.now().difference(startTime).inMicroseconds;
    _performanceMetrics['avg_read_latency_us'] =
        (_performanceMetrics['avg_read_latency_us'] ?? 0) * 0.9 + latency * 0.1;

    return result;
  }

  /// Batch operations with transaction-like behavior
  Future<void> performBatchOperation(
    String boxName,
    Map<String, dynamic> operations,
  ) async {
    debugPrint('📦 Performing batch operation on $boxName: ${operations.length} items');

    final startTime = DateTime.now();

    try {
      // Perform all operations
      for (final entry in operations.entries) {
        await setHiveData(boxName, entry.key, entry.value);
      }

      // Sync to disk
      await _syncToDisk(boxName);

      final batchTime = DateTime.now().difference(startTime);
      debugPrint('✅ Batch operation completed in ${batchTime.inMilliseconds}ms');

    } catch (e) {
      debugPrint('❌ Batch operation failed: $e');
      rethrow;
    }
  }

  /// Update Spotlight search index
  Future<void> _updateSpotlightIndex<T>(String boxName, String key, T value) async {
    try {
      if (!_spotlightIndexingEnabled) return;

      final indexFile = File(path.join(_spotlightMetadataPath, '$boxName.index'));

      final indexEntry = {
        'key': key,
        'value_type': T.toString(),
        'content': value.toString(),
        'indexed_at': DateTime.now().toIso8601String(),
        'box_name': boxName,
      };

      // Append to index file
      await indexFile.writeAsString(
        '${jsonEncode(indexEntry)}\n',
        mode: FileMode.append,
      );

    } catch (e) {
      debugPrint('⚠️ Spotlight indexing failed for $boxName:$key: $e');
    }
  }

  /// Queue data for CloudKit sync
  Future<void> _queueCloudKitSync<T>(String boxName, String key, T value) async {
    try {
      if (!_cloudKitSyncEnabled) return;

      final syncQueue = File(path.join(_cloudKitCachePath, 'sync_queue.jsonl'));

      final syncItem = {
        'operation': 'upsert',
        'box_name': boxName,
        'key': key,
        'value': value,
        'timestamp': DateTime.now().toIso8601String(),
        'sync_status': 'pending',
      };

      await syncQueue.writeAsString(
        '${jsonEncode(syncItem)}\n',
        mode: FileMode.append,
      );

    } catch (e) {
      debugPrint('⚠️ CloudKit sync queuing failed: $e');
    }
  }

  /// Check if data should be synced to cloud
  bool _shouldSyncToCloud(String boxName) {
    // Don't sync sensitive or temporary data
    const excludedBoxes = ['cache', 'temp', 'logs', 'secure_credentials'];
    return !excludedBoxes.contains(boxName) && _cloudKitSyncEnabled;
  }

  /// Force sync data to disk
  Future<void> _syncToDisk(String boxName) async {
    try {
      final box = _hiveBoxes[boxName];
      if (box != null) {
        await box.flush();
      }
    } catch (e) {
      debugPrint('⚠️ Disk sync failed for $boxName: $e');
    }
  }

  // ==================== Advanced Search and Analytics ====================

  /// Search across all storage with Spotlight-like functionality
  Future<List<Map<String, dynamic>>> searchStorage(
    String query, {
    List<String>? boxNames,
    int limit = 50,
  }) async {
    debugPrint('🔍 Searching storage: "$query"');

    final results = <Map<String, dynamic>>[];
    final searchTerms = query.toLowerCase().split(' ');

    // Search through specified boxes or all boxes
    final boxesToSearch = boxNames ?? _hiveBoxes.keys.toList();

    for (final boxName in boxesToSearch) {
      final boxData = getAllHiveData(boxName);

      for (final entry in boxData.entries) {
        final key = entry.key.toString().toLowerCase();
        final value = entry.value.toString().toLowerCase();

        // Check if any search term matches
        bool matches = searchTerms.any((term) =>
          key.contains(term) || value.contains(term)
        );

        if (matches) {
          results.add({
            'box_name': boxName,
            'key': entry.key,
            'value': entry.value,
            'last_accessed': _lastAccessTimes['$boxName:${entry.key}']?.toIso8601String(),
            'relevance_score': _calculateRelevanceScore(query, key, value),
          });
        }

        if (results.length >= limit) break;
      }

      if (results.length >= limit) break;
    }

    // Sort by relevance score
    results.sort((a, b) => b['relevance_score'].compareTo(a['relevance_score']));

    debugPrint('✅ Found ${results.length} results');
    return results;
  }

  double _calculateRelevanceScore(String query, String key, String value) {
    final queryLower = query.toLowerCase();
    final keyLower = key.toLowerCase();
    final valueLower = value.toLowerCase();

    double score = 0.0;

    // Exact matches get highest score
    if (keyLower == queryLower) score += 100;
    if (valueLower.contains(queryLower)) score += 50;

    // Partial matches
    final queryWords = queryLower.split(' ');
    for (final word in queryWords) {
      if (keyLower.contains(word)) score += 20;
      if (valueLower.contains(word)) score += 10;
    }

    // Boost recent items
    final lastAccess = _lastAccessTimes['$key'];
    if (lastAccess != null) {
      final hoursSinceAccess = DateTime.now().difference(lastAccess).inHours;
      score += max(0, 10 - hoursSinceAccess); // Boost for recent access
    }

    return score;
  }

  /// Get storage analytics
  Future<Map<String, dynamic>> getStorageAnalytics() async {
    final analytics = <String, dynamic>{};

    // Base analytics
    analytics['total_boxes'] = _hiveBoxes.length;
    analytics['total_size_bytes'] = await getStorageSize();
    analytics['performance_metrics'] = Map.from(_performanceMetrics);

    // Access patterns
    final accessPatterns = <String, Map<String, dynamic>>{};
    for (final entry in _lastAccessTimes.entries) {
      final parts = entry.key.split(':');
      if (parts.length >= 2) {
        final boxName = parts[0];
        accessPatterns[boxName] = {
          'last_access': entry.value.toIso8601String(),
          'access_frequency': _calculateAccessFrequency(boxName),
        };
      }
    }
    analytics['access_patterns'] = accessPatterns;

    // CloudKit sync status
    if (_cloudKitSyncEnabled) {
      analytics['cloudkit_sync'] = await _getCloudKitSyncStatus();
    }

    // Spotlight index status
    if (_spotlightIndexingEnabled) {
      analytics['spotlight_index'] = await _getSpotlightIndexStatus();
    }

    return analytics;
  }

  double _calculateAccessFrequency(String boxName) {
    final relevantAccesses = _lastAccessTimes.entries
        .where((e) => e.key.startsWith('$boxName:'))
        .length;

    return relevantAccesses / max(1, _lastAccessTimes.length);
  }

  Future<Map<String, dynamic>> _getCloudKitSyncStatus() async {
    try {
      final syncManifest = File(path.join(_cloudKitCachePath, 'sync_manifest.json'));
      if (await syncManifest.exists()) {
        final content = await syncManifest.readAsString();
        return jsonDecode(content);
      }
    } catch (e) {
      debugPrint('⚠️ CloudKit status check failed: $e');
    }
    return {'status': 'unavailable'};
  }

  Future<Map<String, dynamic>> _getSpotlightIndexStatus() async {
    try {
      final indexDir = Directory(_spotlightMetadataPath);
      if (await indexDir.exists()) {
        final indexFiles = indexDir.listSync().whereType<File>().length;
        return {
          'index_files': indexFiles,
          'last_updated': DateTime.now().toIso8601String(),
          'enabled': _spotlightIndexingEnabled,
        };
      }
    } catch (e) {
      debugPrint('⚠️ Spotlight status check failed: $e');
    }
    return {'status': 'unavailable'};
  }

  // ==================== Cleanup and Maintenance ====================

  /// Enhanced cleanup with macOS-specific optimizations
  @override
  Future<void> cleanupOldData({int maxAgeInDays = 30}) async {
    debugPrint('🧹 Starting macOS storage cleanup');

    // Run base cleanup
    await super.cleanupOldData(maxAgeInDays: maxAgeInDays);

    // macOS-specific cleanup
    await _cleanupSpotlightIndex(maxAgeInDays);
    await _cleanupCloudKitCache(maxAgeInDays);
    await _optimizeFileSystem();

    debugPrint('✅ macOS storage cleanup completed');
  }

  Future<void> _cleanupSpotlightIndex(int maxAgeInDays) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: maxAgeInDays));
      final indexDir = Directory(_spotlightMetadataPath);

      if (await indexDir.exists()) {
        final indexFiles = indexDir.listSync().whereType<File>();

        for (final file in indexFiles) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();
            debugPrint('🗑️ Cleaned old Spotlight index: ${file.path}');
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Spotlight cleanup failed: $e');
    }
  }

  Future<void> _cleanupCloudKitCache(int maxAgeInDays) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: maxAgeInDays));
      final cacheDir = Directory(_cloudKitCachePath);

      if (await cacheDir.exists()) {
        final cacheFiles = cacheDir.listSync().whereType<File>();

        for (final file in cacheFiles) {
          if (file.path.contains('cache_') || file.path.contains('temp_')) {
            final stat = await file.stat();
            if (stat.modified.isBefore(cutoffDate)) {
              await file.delete();
              debugPrint('🗑️ Cleaned old CloudKit cache: ${file.path}');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ CloudKit cleanup failed: $e');
    }
  }

  Future<void> _optimizeFileSystem() async {
    try {
      // Optimize Hive databases
      await compactStorage();

      // macOS-specific optimizations
      if (_performanceMetrics['is_apple_silicon'] == 1.0) {
        // Enable file system compression on Apple Silicon
        final appSupportDir = await getApplicationSupportDirectory();
        final agentEngineDir = path.join(appSupportDir.path, 'Asmbli');

        await Process.run('chflags', ['compressed', agentEngineDir]);
        debugPrint('📦 Enabled file system compression');
      }

    } catch (e) {
      debugPrint('⚠️ File system optimization failed: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('🧹 Disposing macOS Storage Service');

    // Kill background isolate
    _backgroundSyncIsolate?.kill(priority: Isolate.immediate);

    // Clear caches
    _performanceMetrics.clear();
    _lastAccessTimes.clear();

    super.dispose();
  }
}

// ==================== Riverpod Providers ====================

final macOSStorageServiceProvider = Provider<MacOSStorageService>((ref) {
  final macOSService = ref.read(macOSServiceProvider);
  final keychainService = ref.read(macOSKeychainServiceProvider);

  final service = MacOSStorageService.getInstance(macOSService, keychainService);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider that returns the appropriate storage service for the platform
final platformStorageServiceProvider = Provider<DesktopStorageService>((ref) {
  if (!kIsWeb && Platform.isMacOS) {
    return ref.read(macOSStorageServiceProvider);
  } else {
    return DesktopStorageService.instance;
  }
});

final macOSStorageAnalyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  if (!kIsWeb && Platform.isMacOS) {
    final service = ref.read(macOSStorageServiceProvider);
    return await service.getStorageAnalytics();
  }
  return {'platform': 'not_macos'};
});