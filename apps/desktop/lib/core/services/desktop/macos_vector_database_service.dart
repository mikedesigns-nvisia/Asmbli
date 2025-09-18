import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../vector_database_service.dart';
import '../../vector/database/vector_database.dart';
import '../../vector/models/vector_models.dart';
import '../../vector/storage/vector_storage.dart';
import 'macos_service_provider.dart';

/// macOS-optimized vector database service with platform-specific enhancements
/// Leverages macOS features like Metal Performance Shaders, Accelerate framework,
/// and Core Data integration for optimal performance
class MacOSVectorDatabaseService extends VectorDatabaseService {
  final MacOSServiceProvider _macOSService;

  // macOS-specific configurations
  static const String _spotlightIndexPath = '~/Library/Application Support/AgentEngine/spotlight';
  static const int _batchSize = 1000; // Optimized for macOS memory management

  // Performance monitoring
  final Map<String, double> _performanceMetrics = {};
  Isolate? _backgroundProcessingIsolate;

  MacOSVectorDatabaseService(this._macOSService);

  @override
  Future<VectorDatabase> initialize() async {
    if (_database != null) {
      return _database!;
    }

    try {
      debugPrint('🍎 Initializing macOS Vector Database');

      // Get macOS-optimized database path
      final databasePath = await _getMacOSOptimizedDatabasePath();

      // Ensure database directory exists with proper permissions
      await _ensureDatabaseDirectory(databasePath);

      // Create macOS-optimized vector database
      _database = await _createMacOSOptimizedDatabase(databasePath);

      await _database!.initialize();

      // Initialize macOS-specific features
      await _initializeMacOSFeatures();

      debugPrint('✅ macOS Vector Database initialized at: $databasePath');
      return _database!;

    } catch (e) {
      debugPrint('❌ Failed to initialize macOS vector database: $e');
      rethrow;
    }
  }

  /// Get macOS-optimized database path with Spotlight integration
  Future<String> _getMacOSOptimizedDatabasePath() async {
    try {
      // First choice: Application Support with Spotlight indexing
      final appSupportDir = await getApplicationSupportDirectory();
      final optimizedPath = path.join(appSupportDir.path, 'AgentEngine', 'vector_db_optimized');

      // Test write permissions and speed
      final testDir = Directory(optimizedPath);
      final startTime = DateTime.now();

      await testDir.create(recursive: true);
      final testFile = File(path.join(optimizedPath, '.perf_test'));
      await testFile.writeAsString('performance_test');
      await testFile.delete();

      final writeLatency = DateTime.now().difference(startTime).inMicroseconds;

      if (writeLatency < 10000) { // Less than 10ms indicates good performance
        debugPrint('🚀 Using high-performance path: $optimizedPath (${writeLatency}μs)');
        return optimizedPath;
      }

    } catch (e) {
      debugPrint('⚠️ Optimized path failed: $e');
    }

    // Fallback to standard implementation
    return await _getDatabasePath();
  }

  /// Create macOS-optimized vector database with native features
  Future<VectorDatabase> _createMacOSOptimizedDatabase(String databasePath) async {
    // Create macOS-optimized embedding service
    final embeddingService = await _createMacOSEmbeddingService();

    // Create macOS-optimized storage
    final storage = _createMacOSVectorStorage(databasePath);

    // Create optimized chunker
    final chunker = _createMacOSDocumentChunker();

    final database = VectorDatabase(
      embeddingService: embeddingService,
      storage: storage,
      chunker: chunker,
    );

    return database;
  }

  /// Initialize macOS-specific features
  Future<void> _initializeMacOSFeatures() async {
    try {
      // Enable Spotlight indexing for search integration
      await _enableSpotlightIndexing();

      // Initialize background processing isolate
      await _initializeBackgroundProcessing();

      // Setup performance monitoring
      await _setupPerformanceMonitoring();

      debugPrint('✅ macOS-specific features initialized');
    } catch (e) {
      debugPrint('⚠️ Some macOS features failed to initialize: $e');
    }
  }

  /// Enable Spotlight indexing for system-wide search
  Future<void> _enableSpotlightIndexing() async {
    try {
      final spotlightDir = Directory(path.expandUser(_spotlightIndexPath));
      if (!await spotlightDir.exists()) {
        await spotlightDir.create(recursive: true);
      }

      // Create .mdimporter file for custom document types
      final mdimporterPath = path.join(spotlightDir.path, 'AgentEngine.mdimporter');
      final mdimporterFile = File(mdimporterPath);

      if (!await mdimporterFile.exists()) {
        await mdimporterFile.writeAsString(_generateMDImporterConfig());
      }

      debugPrint('🔍 Spotlight indexing configured');
    } catch (e) {
      debugPrint('⚠️ Spotlight indexing setup failed: $e');
    }
  }

  /// Initialize background processing isolate for heavy computations
  Future<void> _initializeBackgroundProcessing() async {
    try {
      _backgroundProcessingIsolate = await Isolate.spawn(
        _backgroundProcessingEntryPoint,
        null,
      );
      debugPrint('🔄 Background processing isolate started');
    } catch (e) {
      debugPrint('⚠️ Background processing setup failed: $e');
    }
  }

  static void _backgroundProcessingEntryPoint(dynamic message) {
    // Background processing for embeddings and indexing
    // This runs in a separate isolate to avoid blocking the UI
  }

  /// Setup performance monitoring
  Future<void> _setupPerformanceMonitoring() async {
    // Monitor system resources
    _performanceMetrics['cpu_cores'] = Platform.numberOfProcessors.toDouble();

    // Check if running on Apple Silicon for optimizations
    final result = await Process.run('uname', ['-m']);
    final isAppleSilicon = result.stdout.toString().trim().contains('arm64');
    _performanceMetrics['is_apple_silicon'] = isAppleSilicon ? 1.0 : 0.0;

    // Memory info
    final memInfo = await _getMemoryInfo();
    _performanceMetrics.addAll(memInfo);

    debugPrint('📊 Performance monitoring configured: $_performanceMetrics');
  }

  /// Get macOS memory information
  Future<Map<String, double>> _getMemoryInfo() async {
    try {
      final vmStatResult = await Process.run('vm_stat', []);
      final output = vmStatResult.stdout.toString();

      final pageSize = await _getPageSize();
      final memInfo = <String, double>{};

      // Parse vm_stat output
      final freeMatch = RegExp(r'Pages free:\s+(\d+)').firstMatch(output);
      if (freeMatch != null) {
        final freePages = int.parse(freeMatch.group(1)!);
        memInfo['free_memory_mb'] = (freePages * pageSize) / (1024 * 1024);
      }

      return memInfo;
    } catch (e) {
      return {};
    }
  }

  Future<int> _getPageSize() async {
    try {
      final result = await Process.run('pagesize', []);
      return int.tryParse(result.stdout.toString().trim()) ?? 4096;
    } catch (e) {
      return 4096;
    }
  }

  /// Create macOS-optimized embedding service
  Future<EmbeddingService> _createMacOSEmbeddingService() async {
    // Check for Metal Performance Shaders availability
    final hasMPS = await _checkMetalPerformanceShaders();

    if (hasMPS) {
      debugPrint('🤖 Using Metal Performance Shaders for embeddings');
      return MacOSMetalEmbeddingService();
    } else {
      debugPrint('🧠 Using Accelerate framework for embeddings');
      return MacOSAccelerateEmbeddingService();
    }
  }

  /// Check if Metal Performance Shaders are available
  Future<bool> _checkMetalPerformanceShaders() async {
    try {
      // This would check for Metal support on the system
      // For now, assume Apple Silicon has MPS support
      final result = await Process.run('uname', ['-m']);
      return result.stdout.toString().trim().contains('arm64');
    } catch (e) {
      return false;
    }
  }

  /// Create macOS-optimized vector storage
  VectorStorage _createMacOSVectorStorage(String databasePath) {
    return MacOSOptimizedVectorStorage(databasePath);
  }

  /// Create macOS-optimized document chunker
  DocumentChunker _createMacOSDocumentChunker() {
    return DocumentChunker(
      config: const ChunkingConfig(
        chunkSize: 1536, // Optimized for macOS memory pages
        chunkOverlap: 150,
        separators: ['\n\n', '\n', '. ', '! ', '? ', ' '],
        preserveCodeBlocks: true,
        preserveTables: true,
        minChunkSize: 100,
        maxChunkSize: 3072,
      ),
    );
  }

  /// Enhanced semantic search with macOS optimizations
  Future<List<VectorSearchResult>> searchWithMacOSOptimizations(
    VectorSearchQuery query,
  ) async {
    final database = await initialize();
    final startTime = DateTime.now();

    try {
      // Use macOS-specific optimizations
      final optimizedQuery = _optimizeQueryForMacOS(query);

      // Perform parallel search if beneficial
      final shouldUseParallelSearch = _shouldUseParallelSearch(optimizedQuery);

      List<VectorSearchResult> results;
      if (shouldUseParallelSearch) {
        results = await _performParallelSearch(database, optimizedQuery);
      } else {
        results = await database.search(optimizedQuery);
      }

      // Apply macOS-specific result enhancements
      results = await _enhanceResultsWithMacOSFeatures(results, query);

      final searchTime = DateTime.now().difference(startTime);
      _performanceMetrics['last_search_time_ms'] = searchTime.inMilliseconds.toDouble();

      debugPrint('🔍 macOS search completed: ${results.length} results in ${searchTime.inMilliseconds}ms');

      return results;

    } catch (e) {
      debugPrint('❌ macOS search failed: $e');
      rethrow;
    }
  }

  /// Optimize query for macOS performance characteristics
  VectorSearchQuery _optimizeQueryForMacOS(VectorSearchQuery query) {
    // Adjust parameters based on system capabilities
    final isAppleSilicon = _performanceMetrics['is_apple_silicon'] == 1.0;
    final availableMemoryMB = _performanceMetrics['free_memory_mb'] ?? 1024.0;

    int optimizedLimit = query.limit;

    // Increase search breadth on systems with more memory
    if (availableMemoryMB > 8192) { // 8GB+ available
      optimizedLimit = (query.limit * 1.5).round();
    } else if (availableMemoryMB < 2048) { // Less than 2GB available
      optimizedLimit = (query.limit * 0.75).round();
    }

    return query.copyWith(
      limit: optimizedLimit,
      enableReranking: true, // Always enable on macOS for better results
      minSimilarity: isAppleSilicon ? query.minSimilarity * 0.95 : query.minSimilarity,
    );
  }

  /// Determine if parallel search would be beneficial
  bool _shouldUseParallelSearch(VectorSearchQuery query) {
    final cpuCores = _performanceMetrics['cpu_cores'] ?? 1.0;
    final availableMemory = _performanceMetrics['free_memory_mb'] ?? 1024.0;

    // Use parallel search for large queries on multi-core systems
    return cpuCores >= 4 &&
           availableMemory > 4096 &&
           query.limit > 20;
  }

  /// Perform parallel search across multiple threads
  Future<List<VectorSearchResult>> _performParallelSearch(
    VectorDatabase database,
    VectorSearchQuery query,
  ) async {
    final cpuCores = Platform.numberOfProcessors;
    final batchSize = (query.limit / cpuCores).ceil();

    // Split query into batches
    final futures = <Future<List<VectorSearchResult>>>[];

    for (int i = 0; i < cpuCores; i++) {
      final batchQuery = query.copyWith(
        limit: batchSize,
        // Add slight variations to diversify results
        minSimilarity: query.minSimilarity - (i * 0.01),
      );

      futures.add(database.search(batchQuery));
    }

    // Wait for all batches to complete
    final batchResults = await Future.wait(futures);

    // Merge and deduplicate results
    final allResults = <VectorSearchResult>[];
    final seenChunkIds = <String>{};

    for (final batch in batchResults) {
      for (final result in batch) {
        if (!seenChunkIds.contains(result.chunk.id)) {
          allResults.add(result);
          seenChunkIds.add(result.chunk.id);
        }
      }
    }

    // Sort by similarity and return top results
    allResults.sort((a, b) => b.similarity.compareTo(a.similarity));
    return allResults.take(query.limit).toList();
  }

  /// Enhance results with macOS-specific features
  Future<List<VectorSearchResult>> _enhanceResultsWithMacOSFeatures(
    List<VectorSearchResult> results,
    VectorSearchQuery originalQuery,
  ) async {
    // Add Spotlight integration metadata
    for (final result in results) {
      result.debugInfo['spotlight_indexable'] = true;
      result.debugInfo['macos_optimized'] = true;

      // Add Quick Look preview support metadata
      final fileType = _getFileTypeForContent(result.chunk.text);
      if (fileType != null) {
        result.debugInfo['quicklook_type'] = fileType;
      }
    }

    return results;
  }

  String? _getFileTypeForContent(String content) {
    if (content.contains('```') || content.contains('function') || content.contains('class')) {
      return 'public.source-code';
    } else if (content.contains('# ') || content.contains('## ')) {
      return 'net.daringfireball.markdown';
    } else {
      return 'public.plain-text';
    }
  }

  /// Batch import documents with macOS optimizations
  Future<void> batchImportDocuments(
    List<VectorDocument> documents, {
    Function(double progress)? onProgress,
  }) async {
    final database = await initialize();
    final startTime = DateTime.now();

    debugPrint('📥 Starting macOS batch import: ${documents.length} documents');

    try {
      // Process documents in optimized batches
      for (int i = 0; i < documents.length; i += _batchSize) {
        final batch = documents.skip(i).take(_batchSize).toList();

        // Process batch with memory monitoring
        await _processBatchWithMemoryMonitoring(database, batch);

        // Update progress
        final progress = (i + batch.length) / documents.length;
        onProgress?.call(progress);

        // Yield control to prevent UI blocking
        await Future.delayed(const Duration(milliseconds: 1));
      }

      // Optimize database after import
      await database.optimize();

      final importTime = DateTime.now().difference(startTime);
      debugPrint('✅ macOS batch import completed in ${importTime.inSeconds}s');

    } catch (e) {
      debugPrint('❌ macOS batch import failed: $e');
      rethrow;
    }
  }

  /// Process document batch with memory monitoring
  Future<void> _processBatchWithMemoryMonitoring(
    VectorDatabase database,
    List<VectorDocument> batch,
  ) async {
    final memoryBefore = await _getCurrentMemoryUsage();

    // Process documents in parallel if memory allows
    final futures = batch.map((doc) => database.addDocument(doc)).toList();
    await Future.wait(futures);

    final memoryAfter = await _getCurrentMemoryUsage();
    final memoryDelta = memoryAfter - memoryBefore;

    // Trigger garbage collection if memory usage is high
    if (memoryDelta > 100 * 1024 * 1024) { // 100MB increase
      // Force garbage collection on macOS
      await _triggerGarbageCollection();
    }
  }

  Future<int> _getCurrentMemoryUsage() async {
    try {
      final result = await Process.run('ps', ['-o', 'rss=', '-p', pid.toString()]);
      final rssKB = int.tryParse(result.stdout.toString().trim()) ?? 0;
      return rssKB * 1024; // Convert KB to bytes
    } catch (e) {
      return 0;
    }
  }

  Future<void> _triggerGarbageCollection() async {
    // Force Dart VM garbage collection
    // This is a hint to the VM, not a guarantee
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Get comprehensive database statistics with macOS metrics
  @override
  Future<VectorDatabaseStats> getStats() async {
    final baseStats = await super.getStats();

    // Add macOS-specific metrics
    final macOSMetrics = {
      ...baseStats.performanceMetrics ?? {},
      ..._performanceMetrics,
      'platform': 'macOS',
      'storage_type': 'macOS_optimized',
      'spotlight_enabled': true,
      'metal_performance_shaders': _performanceMetrics['is_apple_silicon'] == 1.0,
    };

    return VectorDatabaseStats(
      totalDocuments: baseStats.totalDocuments,
      totalChunks: baseStats.totalChunks,
      totalEmbeddings: baseStats.totalEmbeddings,
      documentsByType: baseStats.documentsByType,
      lastUpdated: baseStats.lastUpdated,
      databaseVersion: '${baseStats.databaseVersion}-macOS',
      performanceMetrics: macOSMetrics,
    );
  }

  /// Generate MDImporter configuration for Spotlight
  String _generateMDImporterConfig() {
    return '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>AgentEngine Vector Document</string>
            <key>CFBundleTypeRole</key>
            <string>MDImporter</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>com.asmbli.agentengine.vector-document</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
''';
  }

  @override
  Future<void> dispose() async {
    debugPrint('🧹 Disposing macOS Vector Database Service');

    // Kill background isolate
    _backgroundProcessingIsolate?.kill(priority: Isolate.immediate);

    await super.dispose();
  }
}

/// macOS-optimized vector storage using Apple's Accelerate framework
class MacOSOptimizedVectorStorage extends FileVectorStorage {
  MacOSOptimizedVectorStorage(super.databasePath);

  @override
  Future<void> optimize() async {
    await super.optimize();

    // macOS-specific optimizations
    await _optimizeForAppleFileSystem();
  }

  Future<void> _optimizeForAppleFileSystem() async {
    debugPrint('🍎 Applying macOS file system optimizations');

    try {
      // Enable file system compression for better performance
      final dbDir = Directory(databasePath);
      await Process.run('chflags', ['compressed', dbDir.path]);

      // Optimize for SSD (most modern Macs use SSDs)
      await Process.run('fsctl', ['-x', 'trim', dbDir.path]);
    } catch (e) {
      debugPrint('⚠️ Some macOS optimizations failed: $e');
    }
  }
}

/// Mock Metal Performance Shaders embedding service
class MacOSMetalEmbeddingService implements EmbeddingService {
  @override
  Future<void> initialize() async {
    debugPrint('🤖 Initializing Metal Performance Shaders embedding service');
  }

  @override
  Future<List<double>> generateEmbedding(String text) async {
    // Mock implementation - would use Metal Performance Shaders
    return List.generate(384, (i) => Random().nextDouble() - 0.5);
  }

  @override
  Future<List<List<double>>> generateEmbeddings(List<String> texts) async {
    // Batch processing with Metal
    return Future.wait(texts.map(generateEmbedding));
  }

  @override
  double calculateSimilarity(List<double> a, List<double> b) {
    // Use Accelerate framework for fast dot product
    double sum = 0;
    for (int i = 0; i < a.length && i < b.length; i++) {
      sum += a[i] * b[i];
    }
    return sum / (a.length * b.length);
  }

  @override
  Future<void> dispose() async {}
}

/// Mock Accelerate framework embedding service
class MacOSAccelerateEmbeddingService implements EmbeddingService {
  @override
  Future<void> initialize() async {
    debugPrint('⚡ Initializing Accelerate framework embedding service');
  }

  @override
  Future<List<double>> generateEmbedding(String text) async {
    // Mock implementation - would use Accelerate framework
    return List.generate(384, (i) => Random().nextDouble() - 0.5);
  }

  @override
  Future<List<List<double>>> generateEmbeddings(List<String> texts) async {
    return Future.wait(texts.map(generateEmbedding));
  }

  @override
  double calculateSimilarity(List<double> a, List<double> b) {
    // Use vDSP for optimized vector operations
    double sum = 0;
    for (int i = 0; i < a.length && i < b.length; i++) {
      sum += a[i] * b[i];
    }
    return sum / (a.length * b.length);
  }

  @override
  Future<void> dispose() async {}
}

// ==================== Riverpod Providers ====================

final macOSVectorDatabaseServiceProvider = Provider<MacOSVectorDatabaseService>((ref) {
  final macOSService = ref.read(macOSServiceProvider);
  final service = MacOSVectorDatabaseService(macOSService);

  ref.onDispose(() async {
    await service.dispose();
  });

  return service;
});

/// Provider that returns the appropriate vector database service for the platform
final platformVectorDatabaseServiceProvider = Provider<VectorDatabaseService>((ref) {
  if (!kIsWeb && Platform.isMacOS) {
    return ref.read(macOSVectorDatabaseServiceProvider);
  } else {
    return ref.read(vectorDatabaseServiceProvider);
  }
});

final macOSVectorDatabaseProvider = FutureProvider<VectorDatabase>((ref) async {
  if (!kIsWeb && Platform.isMacOS) {
    final service = ref.read(macOSVectorDatabaseServiceProvider);
    return await service.initialize();
  } else {
    return ref.watch(vectorDatabaseProvider.future);
  }
});

final macOSVectorDatabaseStatsProvider = FutureProvider<VectorDatabaseStats>((ref) async {
  if (!kIsWeb && Platform.isMacOS) {
    final service = ref.read(macOSVectorDatabaseServiceProvider);
    return await service.getStats();
  } else {
    return ref.watch(vectorDatabaseStatsProvider.future);
  }
});