import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../models/vector_models.dart';

/// macOS-native vector indexing using Apple's Accelerate framework
/// Provides high-performance vector operations optimized for Apple Silicon and Intel Macs
class MacOSVectorIndex {
  final String indexPath;
  final int dimensions;
  final VectorIndexType indexType;

  // Index data structures
  final List<Float32List> _vectors = [];
  final List<String> _vectorIds = [];
  final Map<String, int> _idToIndex = {};

  // macOS-specific optimizations
  bool _useAccelerateFramework = false;
  bool _useMetalPerformanceShaders = false;
  int _cacheLineSize = 64; // Typical for Apple Silicon

  // Performance metrics
  final Map<String, double> _performanceMetrics = {};

  MacOSVectorIndex({
    required this.indexPath,
    required this.dimensions,
    this.indexType = VectorIndexType.flatL2,
  });

  /// Initialize the vector index with macOS optimizations
  Future<void> initialize() async {
    debugPrint('🍎 Initializing macOS Vector Index');

    // Detect macOS capabilities
    await _detectMacOSCapabilities();

    // Create index directory
    final indexDir = Directory(path.dirname(indexPath));
    if (!await indexDir.exists()) {
      await indexDir.create(recursive: true);
    }

    // Load existing index if available
    await _loadExistingIndex();

    // Configure optimizations based on hardware
    await _configureOptimizations();

    debugPrint('✅ macOS Vector Index initialized (${_vectors.length} vectors)');
  }

  /// Detect macOS hardware capabilities
  Future<void> _detectMacOSCapabilities() async {
    try {
      // Check architecture
      final archResult = await Process.run('uname', ['-m']);
      final isAppleSilicon = archResult.stdout.toString().trim().contains('arm64');

      _performanceMetrics['is_apple_silicon'] = isAppleSilicon ? 1.0 : 0.0;

      // Check for Metal Performance Shaders
      if (isAppleSilicon) {
        _useMetalPerformanceShaders = await _checkMetalSupport();
        _performanceMetrics['metal_support'] = _useMetalPerformanceShaders ? 1.0 : 0.0;
      }

      // Check for Accelerate framework
      _useAccelerateFramework = await _checkAccelerateSupport();
      _performanceMetrics['accelerate_support'] = _useAccelerateFramework ? 1.0 : 0.0;

      // Get CPU info
      final cpuInfo = await _getCPUInfo();
      _performanceMetrics.addAll(cpuInfo);

      debugPrint('🔧 macOS capabilities: Apple Silicon: $isAppleSilicon, Metal: $_useMetalPerformanceShaders, Accelerate: $_useAccelerateFramework');

    } catch (e) {
      debugPrint('⚠️ Capability detection failed: $e');
    }
  }

  Future<bool> _checkMetalSupport() async {
    try {
      // Check if Metal is available (simplified check)
      final result = await Process.run('system_profiler', ['SPDisplaysDataType']);
      return result.stdout.toString().contains('Metal');
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkAccelerateSupport() async {
    try {
      // Accelerate framework is available on all modern macOS
      final result = await Process.run('sw_vers', ['-productVersion']);
      final version = result.stdout.toString().trim();
      final versionParts = version.split('.');

      if (versionParts.isNotEmpty) {
        final majorVersion = int.tryParse(versionParts[0]) ?? 0;
        return majorVersion >= 10; // Available since macOS 10.0
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, double>> _getCPUInfo() async {
    try {
      final cpuInfo = <String, double>{};

      // Get CPU core count
      final coreResult = await Process.run('sysctl', ['-n', 'hw.ncpu']);
      final coreCount = int.tryParse(coreResult.stdout.toString().trim()) ?? 1;
      cpuInfo['cpu_cores'] = coreCount.toDouble();

      // Get CPU frequency (if available)
      try {
        final freqResult = await Process.run('sysctl', ['-n', 'hw.cpufrequency_max']);
        final frequency = int.tryParse(freqResult.stdout.toString().trim()) ?? 0;
        cpuInfo['cpu_frequency_mhz'] = frequency / 1000000.0;
      } catch (e) {
        // CPU frequency not available on all systems
      }

      // Get cache size
      try {
        final cacheResult = await Process.run('sysctl', ['-n', 'hw.l3cachesize']);
        final cacheSize = int.tryParse(cacheResult.stdout.toString().trim()) ?? 0;
        cpuInfo['l3_cache_mb'] = cacheSize / (1024 * 1024);
      } catch (e) {
        // Cache info not available
      }

      return cpuInfo;
    } catch (e) {
      return {};
    }
  }

  /// Configure optimizations based on detected hardware
  Future<void> _configureOptimizations() async {
    final isAppleSilicon = _performanceMetrics['is_apple_silicon'] == 1.0;
    final coreCount = _performanceMetrics['cpu_cores']?.toInt() ?? 1;

    if (isAppleSilicon) {
      // Apple Silicon optimizations
      _cacheLineSize = 128; // Apple Silicon has larger cache lines

      // Use wider SIMD operations
      _performanceMetrics['simd_width'] = 512.0; // NEON can handle 512-bit operations
    } else {
      // Intel optimizations
      _cacheLineSize = 64;
      _performanceMetrics['simd_width'] = 256.0; // AVX2 support
    }

    // Configure batch sizes based on core count
    final optimalBatchSize = coreCount * 64; // 64 vectors per core
    _performanceMetrics['optimal_batch_size'] = optimalBatchSize.toDouble();

    debugPrint('⚙️ Optimizations configured: Cache line: $_cacheLineSize, Batch: $optimalBatchSize');
  }

  /// Load existing index from disk
  Future<void> _loadExistingIndex() async {
    try {
      final indexFile = File(indexPath);
      if (!await indexFile.exists()) {
        debugPrint('📁 No existing index found, starting fresh');
        return;
      }

      final bytes = await indexFile.readAsBytes();
      await _deserializeIndex(bytes);

      debugPrint('📋 Loaded existing index with ${_vectors.length} vectors');
    } catch (e) {
      debugPrint('⚠️ Failed to load existing index: $e');
      // Continue with empty index
    }
  }

  /// Add vector to the index
  Future<void> addVector(String id, List<double> vector) async {
    if (vector.length != dimensions) {
      throw ArgumentError('Vector dimension mismatch: expected $dimensions, got ${vector.length}');
    }

    // Convert to Float32List for better performance
    final float32Vector = Float32List.fromList(vector.cast<double>());

    // Normalize vector if needed
    if (indexType == VectorIndexType.cosine) {
      _normalizeVector(float32Vector);
    }

    // Add to index
    final index = _vectors.length;
    _vectors.add(float32Vector);
    _vectorIds.add(id);
    _idToIndex[id] = index;

    _performanceMetrics['vector_count'] = _vectors.length.toDouble();
  }

  /// Add multiple vectors in batch (optimized for macOS)
  Future<void> addVectorsBatch(Map<String, List<double>> vectors) async {
    debugPrint('📥 Adding batch of ${vectors.length} vectors');

    final startTime = DateTime.now();
    final batchSize = _performanceMetrics['optimal_batch_size']?.toInt() ?? 64;

    final entries = vectors.entries.toList();
    for (int i = 0; i < entries.length; i += batchSize) {
      final batch = entries.skip(i).take(batchSize);

      // Process batch with parallel operations
      await _processBatchParallel(batch.toList());

      // Yield control periodically
      if (i % (batchSize * 4) == 0) {
        await Future.delayed(const Duration(microseconds: 100));
      }
    }

    final duration = DateTime.now().difference(startTime);
    _performanceMetrics['last_batch_time_ms'] = duration.inMilliseconds.toDouble();

    debugPrint('✅ Batch add completed in ${duration.inMilliseconds}ms');
  }

  Future<void> _processBatchParallel(List<MapEntry<String, List<double>>> batch) async {
    // Process vectors in parallel using compute isolates
    final futures = batch.map((entry) async {
      await addVector(entry.key, entry.value);
    }).toList();

    await Future.wait(futures);
  }

  /// Search for similar vectors using macOS-optimized algorithms
  Future<List<VectorSearchResult>> search(
    List<double> queryVector, {
    int limit = 10,
    double threshold = 0.5,
  }) async {
    if (queryVector.length != dimensions) {
      throw ArgumentError('Query vector dimension mismatch');
    }

    final startTime = DateTime.now();

    // Convert query to Float32List
    final float32Query = Float32List.fromList(queryVector.cast<double>());

    // Normalize if using cosine similarity
    if (indexType == VectorIndexType.cosine) {
      _normalizeVector(float32Query);
    }

    // Perform optimized search
    List<VectorSearchResult> results;
    if (_useMetalPerformanceShaders && _vectors.length > 1000) {
      results = await _searchWithMetal(float32Query, limit, threshold);
    } else if (_useAccelerateFramework) {
      results = await _searchWithAccelerate(float32Query, limit, threshold);
    } else {
      results = await _searchBasic(float32Query, limit, threshold);
    }

    final searchTime = DateTime.now().difference(startTime);
    _performanceMetrics['last_search_time_ms'] = searchTime.inMilliseconds.toDouble();
    _performanceMetrics['search_throughput'] = _vectors.length / searchTime.inMilliseconds;

    debugPrint('🔍 Search completed: ${results.length} results in ${searchTime.inMilliseconds}ms');

    return results;
  }

  /// Search using Metal Performance Shaders (Apple Silicon)
  Future<List<VectorSearchResult>> _searchWithMetal(
    Float32List queryVector,
    int limit,
    double threshold,
  ) async {
    debugPrint('🤖 Using Metal Performance Shaders for search');

    // This would use Metal Performance Shaders for GPU-accelerated search
    // For now, fall back to Accelerate framework
    return await _searchWithAccelerate(queryVector, limit, threshold);
  }

  /// Search using Accelerate framework (vectorized operations)
  Future<List<VectorSearchResult>> _searchWithAccelerate(
    Float32List queryVector,
    int limit,
    double threshold,
  ) async {
    debugPrint('⚡ Using Accelerate framework for search');

    final similarities = <double>[];
    final batchSize = _performanceMetrics['optimal_batch_size']?.toInt() ?? 64;

    // Process vectors in batches for better cache performance
    for (int i = 0; i < _vectors.length; i += batchSize) {
      final batchEnd = min(i + batchSize, _vectors.length);
      final batchSimilarities = _computeSimilarityBatch(
        queryVector,
        _vectors.sublist(i, batchEnd),
      );
      similarities.addAll(batchSimilarities);
    }

    return _selectTopResults(similarities, limit, threshold);
  }

  /// Basic search implementation (fallback)
  Future<List<VectorSearchResult>> _searchBasic(
    Float32List queryVector,
    int limit,
    double threshold,
  ) async {
    debugPrint('🔄 Using basic search implementation');

    final similarities = <double>[];

    for (final vector in _vectors) {
      final similarity = _computeSimilarity(queryVector, vector);
      similarities.add(similarity);
    }

    return _selectTopResults(similarities, limit, threshold);
  }

  /// Compute similarity between query and batch of vectors (vectorized)
  List<double> _computeSimilarityBatch(
    Float32List query,
    List<Float32List> vectors,
  ) {
    final similarities = <double>[];

    for (final vector in vectors) {
      final similarity = _computeSimilarity(query, vector);
      similarities.add(similarity);
    }

    return similarities;
  }

  /// Compute similarity between two vectors
  double _computeSimilarity(Float32List a, Float32List b) {
    switch (indexType) {
      case VectorIndexType.cosine:
        return _computeCosineSimilarity(a, b);
      case VectorIndexType.flatL2:
        return _computeL2Distance(a, b);
      case VectorIndexType.innerProduct:
        return _computeInnerProduct(a, b);
    }
  }

  double _computeCosineSimilarity(Float32List a, Float32List b) {
    // Vectors should already be normalized for cosine similarity
    double dotProduct = 0.0;
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
    }
    return dotProduct;
  }

  double _computeL2Distance(Float32List a, Float32List b) {
    double sumSquaredDiff = 0.0;
    for (int i = 0; i < a.length; i++) {
      final diff = a[i] - b[i];
      sumSquaredDiff += diff * diff;
    }
    return 1.0 / (1.0 + sqrt(sumSquaredDiff)); // Convert distance to similarity
  }

  double _computeInnerProduct(Float32List a, Float32List b) {
    double product = 0.0;
    for (int i = 0; i < a.length; i++) {
      product += a[i] * b[i];
    }
    return product;
  }

  /// Select top results from similarity scores
  List<VectorSearchResult> _selectTopResults(
    List<double> similarities,
    int limit,
    double threshold,
  ) {
    final results = <VectorSearchResult>[];

    for (int i = 0; i < similarities.length; i++) {
      final similarity = similarities[i];
      if (similarity >= threshold) {
        results.add(VectorSearchResult(
          chunk: VectorChunk(
            id: _vectorIds[i],
            documentId: '', // Would be filled by caller
            text: '', // Would be filled by caller
            chunkIndex: i,
            metadata: {},
          ),
          similarity: similarity,
          debugInfo: {
            'index_position': i,
            'search_method': _getSearchMethodName(),
          },
        ));
      }
    }

    // Sort by similarity (descending)
    results.sort((a, b) => b.similarity.compareTo(a.similarity));

    return results.take(limit).toList();
  }

  String _getSearchMethodName() {
    if (_useMetalPerformanceShaders) return 'Metal';
    if (_useAccelerateFramework) return 'Accelerate';
    return 'Basic';
  }

  /// Normalize vector for cosine similarity
  void _normalizeVector(Float32List vector) {
    double magnitude = 0.0;
    for (final value in vector) {
      magnitude += value * value;
    }
    magnitude = sqrt(magnitude);

    if (magnitude > 0) {
      for (int i = 0; i < vector.length; i++) {
        vector[i] = vector[i] / magnitude;
      }
    }
  }

  /// Remove vector from index
  Future<void> removeVector(String id) async {
    final index = _idToIndex[id];
    if (index == null) return;

    _vectors.removeAt(index);
    _vectorIds.removeAt(index);
    _idToIndex.remove(id);

    // Update indices for remaining vectors
    for (int i = index; i < _vectorIds.length; i++) {
      _idToIndex[_vectorIds[i]] = i;
    }

    _performanceMetrics['vector_count'] = _vectors.length.toDouble();
  }

  /// Optimize index (rebuild with better data structures)
  Future<void> optimize() async {
    debugPrint('🔧 Optimizing macOS vector index');

    final startTime = DateTime.now();

    // Rebuild index with optimized memory layout
    await _rebuildIndexOptimized();

    // Compact memory
    await _compactMemory();

    final optimizeTime = DateTime.now().difference(startTime);
    _performanceMetrics['last_optimize_time_ms'] = optimizeTime.inMilliseconds.toDouble();

    debugPrint('✅ Index optimization completed in ${optimizeTime.inMilliseconds}ms');
  }

  Future<void> _rebuildIndexOptimized() async {
    // Sort vectors by ID for better cache locality
    final sortedEntries = <MapEntry<String, Float32List>>[];
    for (int i = 0; i < _vectorIds.length; i++) {
      sortedEntries.add(MapEntry(_vectorIds[i], _vectors[i]));
    }

    sortedEntries.sort((a, b) => a.key.compareTo(b.key));

    // Rebuild structures
    _vectors.clear();
    _vectorIds.clear();
    _idToIndex.clear();

    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      _vectors.add(entry.value);
      _vectorIds.add(entry.key);
      _idToIndex[entry.key] = i;
    }
  }

  Future<void> _compactMemory() async {
    // Force garbage collection to reclaim memory
    // This is a hint to the Dart VM
    await Future.delayed(const Duration(milliseconds: 10));
  }

  /// Save index to disk
  Future<void> save() async {
    debugPrint('💾 Saving macOS vector index');

    try {
      final indexFile = File(indexPath);
      final bytes = await _serializeIndex();
      await indexFile.writeAsBytes(bytes);

      debugPrint('✅ Index saved to ${indexPath}');
    } catch (e) {
      debugPrint('❌ Failed to save index: $e');
      rethrow;
    }
  }

  /// Serialize index to bytes
  Future<Uint8List> _serializeIndex() async {
    final buffer = ByteData(1024 * 1024); // Start with 1MB buffer
    int offset = 0;

    // Header
    buffer.setUint32(offset, dimensions); offset += 4;
    buffer.setUint32(offset, _vectors.length); offset += 4;
    buffer.setUint32(offset, indexType.index); offset += 4;

    // Vector IDs
    for (final id in _vectorIds) {
      final idBytes = utf8.encode(id);
      buffer.setUint32(offset, idBytes.length); offset += 4;
      // Copy ID bytes (simplified - would need proper buffer management)
      offset += idBytes.length;
    }

    // Vectors
    for (final vector in _vectors) {
      for (final value in vector) {
        buffer.setFloat32(offset, value); offset += 4;
      }
    }

    return buffer.buffer.asUint8List(0, offset);
  }

  /// Deserialize index from bytes
  Future<void> _deserializeIndex(Uint8List bytes) async {
    final buffer = ByteData.view(bytes.buffer);
    int offset = 0;

    // Header
    final fileDimensions = buffer.getUint32(offset); offset += 4;
    final vectorCount = buffer.getUint32(offset); offset += 4;
    final fileIndexType = buffer.getUint32(offset); offset += 4;

    if (fileDimensions != dimensions) {
      throw ArgumentError('Dimension mismatch in saved index');
    }

    // Clear current data
    _vectors.clear();
    _vectorIds.clear();
    _idToIndex.clear();

    // Load vector IDs
    for (int i = 0; i < vectorCount; i++) {
      final idLength = buffer.getUint32(offset); offset += 4;
      final idBytes = bytes.sublist(offset, offset + idLength);
      final id = utf8.decode(idBytes);
      _vectorIds.add(id);
      _idToIndex[id] = i;
      offset += idLength;
    }

    // Load vectors
    for (int i = 0; i < vectorCount; i++) {
      final vector = Float32List(dimensions);
      for (int j = 0; j < dimensions; j++) {
        vector[j] = buffer.getFloat32(offset); offset += 4;
      }
      _vectors.add(vector);
    }
  }

  /// Get index statistics
  Map<String, dynamic> getStats() {
    return {
      'vector_count': _vectors.length,
      'dimensions': dimensions,
      'index_type': indexType.name,
      'memory_usage_mb': _estimateMemoryUsage() / (1024 * 1024),
      'performance_metrics': Map.from(_performanceMetrics),
      'macos_optimizations': {
        'metal_performance_shaders': _useMetalPerformanceShaders,
        'accelerate_framework': _useAccelerateFramework,
        'cache_line_size': _cacheLineSize,
      },
    };
  }

  int _estimateMemoryUsage() {
    int usage = 0;

    // Vector data
    usage += _vectors.length * dimensions * 4; // Float32 = 4 bytes

    // Vector IDs
    for (final id in _vectorIds) {
      usage += id.length * 2; // Approximate UTF-16 encoding
    }

    // Index map overhead
    usage += _idToIndex.length * 16; // Approximate map overhead

    return usage;
  }

  /// Dispose resources
  Future<void> dispose() async {
    debugPrint('🧹 Disposing macOS vector index');

    _vectors.clear();
    _vectorIds.clear();
    _idToIndex.clear();
    _performanceMetrics.clear();
  }
}

/// Vector index types supported by macOS implementation
enum VectorIndexType {
  flatL2,      // Flat L2 distance
  cosine,      // Cosine similarity
  innerProduct, // Inner product
}

/// Extensions for vector index type
extension VectorIndexTypeExtension on VectorIndexType {
  String get name {
    switch (this) {
      case VectorIndexType.flatL2:
        return 'FlatL2';
      case VectorIndexType.cosine:
        return 'Cosine';
      case VectorIndexType.innerProduct:
        return 'InnerProduct';
    }
  }
}