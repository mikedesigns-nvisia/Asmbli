import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/vector_models.dart';

/// Abstract base class for vector storage implementations
abstract class VectorStorage {
  /// Initialize the storage system
  Future<void> initialize();
  
  /// Store a document
  Future<void> storeDocument(VectorDocument document);
  
  /// Get a document by ID
  Future<VectorDocument?> getDocument(String documentId);
  
  /// Delete a document
  Future<void> deleteDocument(String documentId);
  
  /// List documents with optional filtering
  Future<List<VectorDocument>> listDocuments({
    int? limit,
    int? offset,
    Map<String, dynamic>? filter,
  });
  
  /// Store chunks with embeddings
  Future<void> storeChunks(List<VectorChunk> chunks);
  
  /// Get chunks by criteria
  Future<List<VectorChunk>> getChunks({
    List<String>? documentIds,
    Map<String, dynamic>? filter,
    int? limit,
    int? offset,
  });
  
  /// Delete chunks for a document
  Future<void> deleteChunks(String documentId);
  
  /// Get database statistics
  Future<VectorDatabaseStats> getStats();
  
  /// Optimize storage
  Future<void> optimize();
  
  /// Clean up orphaned data
  Future<void> cleanup();
  
  /// Dispose of storage resources
  Future<void> dispose();
}

/// File-based vector storage implementation
class FileVectorStorage extends VectorStorage {
  final String databasePath;
  late final String _documentsPath;
  late final String _chunksPath;
  late final String _indexPath;
  
  bool _isInitialized = false;
  final Map<String, VectorDocument> _documentCache = {};
  final Map<String, List<VectorChunk>> _chunkCache = {};

  FileVectorStorage(this.databasePath);

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    print('📁 Initializing file vector storage at: $databasePath');

    // Create directory structure
    final dbDir = Directory(databasePath);
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }

    _documentsPath = path.join(databasePath, 'documents');
    _chunksPath = path.join(databasePath, 'chunks');
    _indexPath = path.join(databasePath, 'indexes');

    for (final dirPath in [_documentsPath, _chunksPath, _indexPath]) {
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        await dir.create();
      }
    }

    // Load existing data into cache
    await _loadCache();

    _isInitialized = true;
    print('✅ File vector storage initialized');
  }

  /// Load existing data into memory cache
  Future<void> _loadCache() async {
    print('📦 Loading existing data into cache');
    
    // Load documents
    final docDir = Directory(_documentsPath);
    if (await docDir.exists()) {
      final docFiles = docDir.listSync().whereType<File>();
      for (final file in docFiles) {
        try {
          final content = await file.readAsString();
          final data = jsonDecode(content);
          final document = VectorDocument.fromJson(data);
          _documentCache[document.id] = document;
        } catch (e) {
          print('⚠️ Failed to load document from ${file.path}: $e');
        }
      }
    }

    // Load chunks
    final chunkDir = Directory(_chunksPath);
    if (await chunkDir.exists()) {
      final chunkFiles = chunkDir.listSync().whereType<File>();
      for (final file in chunkFiles) {
        try {
          final content = await file.readAsString();
          final data = jsonDecode(content);
          final chunks = (data as List).map((item) => VectorChunk.fromJson(item)).toList();
          
          if (chunks.isNotEmpty) {
            _chunkCache[chunks.first.documentId] = chunks;
          }
        } catch (e) {
          print('⚠️ Failed to load chunks from ${file.path}: $e');
        }
      }
    }

    print('📊 Loaded ${_documentCache.length} documents and ${_chunkCache.length} chunk groups');
  }

  @override
  Future<void> storeDocument(VectorDocument document) async {
    if (!_isInitialized) await initialize();

    try {
      final filePath = path.join(_documentsPath, '${document.id}.json');
      final file = File(filePath);
      
      final json = jsonEncode(document.toJson());
      await file.writeAsString(json);
      
      _documentCache[document.id] = document;
      
    } catch (e) {
      throw Exception('Failed to store document ${document.id}: $e');
    }
  }

  @override
  Future<VectorDocument?> getDocument(String documentId) async {
    if (!_isInitialized) await initialize();

    return _documentCache[documentId];
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    if (!_isInitialized) await initialize();

    try {
      final filePath = path.join(_documentsPath, '$documentId.json');
      final file = File(filePath);
      
      if (await file.exists()) {
        await file.delete();
      }
      
      _documentCache.remove(documentId);
      
    } catch (e) {
      throw Exception('Failed to delete document $documentId: $e');
    }
  }

  @override
  Future<List<VectorDocument>> listDocuments({
    int? limit,
    int? offset,
    Map<String, dynamic>? filter,
  }) async {
    if (!_isInitialized) await initialize();

    List<VectorDocument> documents = _documentCache.values.toList();
    
    // Apply filtering if specified
    if (filter != null) {
      documents = documents.where((doc) => _matchesFilter(doc, filter)).toList();
    }
    
    // Apply offset and limit
    if (offset != null) {
      documents = documents.skip(offset).toList();
    }
    if (limit != null) {
      documents = documents.take(limit).toList();
    }
    
    return documents;
  }

  @override
  Future<void> storeChunks(List<VectorChunk> chunks) async {
    if (!_isInitialized) await initialize();
    if (chunks.isEmpty) return;

    try {
      final documentId = chunks.first.documentId;
      final filePath = path.join(_chunksPath, '$documentId.json');
      final file = File(filePath);
      
      final json = jsonEncode(chunks.map((c) => c.toJson()).toList());
      await file.writeAsString(json);
      
      _chunkCache[documentId] = chunks;
      
    } catch (e) {
      throw Exception('Failed to store chunks: $e');
    }
  }

  @override
  Future<List<VectorChunk>> getChunks({
    List<String>? documentIds,
    Map<String, dynamic>? filter,
    int? limit,
    int? offset,
  }) async {
    if (!_isInitialized) await initialize();

    List<VectorChunk> allChunks = [];
    
    if (documentIds != null) {
      // Get chunks for specific documents
      for (final docId in documentIds) {
        final chunks = _chunkCache[docId];
        if (chunks != null) {
          allChunks.addAll(chunks);
        }
      }
    } else {
      // Get all chunks
      for (final chunks in _chunkCache.values) {
        allChunks.addAll(chunks);
      }
    }
    
    // Apply filtering if specified
    if (filter != null) {
      allChunks = allChunks.where((chunk) => _matchesChunkFilter(chunk, filter)).toList();
    }
    
    // Apply offset and limit
    if (offset != null) {
      allChunks = allChunks.skip(offset).toList();
    }
    if (limit != null) {
      allChunks = allChunks.take(limit).toList();
    }
    
    return allChunks;
  }

  @override
  Future<void> deleteChunks(String documentId) async {
    if (!_isInitialized) await initialize();

    try {
      final filePath = path.join(_chunksPath, '$documentId.json');
      final file = File(filePath);
      
      if (await file.exists()) {
        await file.delete();
      }
      
      _chunkCache.remove(documentId);
      
    } catch (e) {
      throw Exception('Failed to delete chunks for document $documentId: $e');
    }
  }

  @override
  Future<VectorDatabaseStats> getStats() async {
    if (!_isInitialized) await initialize();

    final totalDocuments = _documentCache.length;
    int totalChunks = 0;
    int totalEmbeddings = 0;
    final documentsByType = <String, int>{};

    // Count chunks and embeddings
    for (final chunks in _chunkCache.values) {
      totalChunks += chunks.length;
      for (final chunk in chunks) {
        if (chunk.embedding != null) {
          totalEmbeddings++;
        }
      }
    }

    // Count documents by type
    for (final document in _documentCache.values) {
      final type = document.contentType;
      documentsByType[type] = (documentsByType[type] ?? 0) + 1;
    }

    return VectorDatabaseStats(
      totalDocuments: totalDocuments,
      totalChunks: totalChunks,
      totalEmbeddings: totalEmbeddings,
      documentsByType: documentsByType,
      lastUpdated: DateTime.now(),
      databaseVersion: '1.0.0',
      performanceMetrics: {
        'cache_hit_ratio': 1.0, // File storage loads everything into cache
        'average_chunk_size': totalChunks > 0 
            ? _chunkCache.values.expand((c) => c).map((c) => c.text.length).reduce((a, b) => a + b) / totalChunks
            : 0,
      },
    );
  }

  @override
  Future<void> optimize() async {
    if (!_isInitialized) await initialize();

    print('🔧 Optimizing file vector storage');
    
    // Remove any orphaned files
    await cleanup();
    
    // Rebuild indexes if needed (placeholder for now)
    await _rebuildIndexes();
  }

  @override
  Future<void> cleanup() async {
    if (!_isInitialized) await initialize();

    print('🧹 Cleaning up vector storage');
    
    // Find orphaned chunk files (chunks without corresponding documents)
    final chunkDir = Directory(_chunksPath);
    if (await chunkDir.exists()) {
      final chunkFiles = chunkDir.listSync().whereType<File>();
      
      for (final file in chunkFiles) {
        final fileName = path.basenameWithoutExtension(file.path);
        if (!_documentCache.containsKey(fileName)) {
          print('🗑️ Removing orphaned chunk file: ${file.path}');
          await file.delete();
          _chunkCache.remove(fileName);
        }
      }
    }
  }

  Future<void> _rebuildIndexes() async {
    // Placeholder for index rebuilding logic
    print('🔨 Rebuilding indexes...');
    
    // In a real implementation, this might rebuild spatial indexes,
    // inverted indexes for metadata, etc.
  }

  /// Check if a document matches the given filter
  bool _matchesFilter(VectorDocument document, Map<String, dynamic> filter) {
    for (final entry in filter.entries) {
      final key = entry.key;
      final value = entry.value;
      
      dynamic documentValue;
      switch (key) {
        case 'contentType':
          documentValue = document.contentType;
          break;
        case 'source':
          documentValue = document.source;
          break;
        default:
          documentValue = document.metadata[key];
      }
      
      if (!_matchesValue(documentValue, value)) {
        return false;
      }
    }
    
    return true;
  }

  /// Check if a chunk matches the given filter
  bool _matchesChunkFilter(VectorChunk chunk, Map<String, dynamic> filter) {
    for (final entry in filter.entries) {
      final key = entry.key;
      final value = entry.value;
      
      dynamic chunkValue;
      switch (key) {
        case 'documentId':
          chunkValue = chunk.documentId;
          break;
        default:
          chunkValue = chunk.metadata[key];
      }
      
      if (!_matchesValue(chunkValue, value)) {
        return false;
      }
    }
    
    return true;
  }

  /// Check if a value matches the filter criteria
  bool _matchesValue(dynamic documentValue, dynamic filterValue) {
    if (filterValue is Map<String, dynamic>) {
      // Handle operators like $in, $gt, etc.
      for (final opEntry in filterValue.entries) {
        switch (opEntry.key) {
          case r'$in':
            if (opEntry.value is List && !opEntry.value.contains(documentValue)) {
              return false;
            }
            break;
          case r'$eq':
            if (documentValue != opEntry.value) {
              return false;
            }
            break;
          default:
            // Unknown operator, treat as equality
            if (documentValue != filterValue) {
              return false;
            }
        }
      }
      return true;
    } else {
      // Direct equality comparison
      return documentValue == filterValue;
    }
  }

  @override
  Future<void> dispose() async {
    if (!_isInitialized) return;

    print('🧹 Disposing file vector storage');
    
    // Clear caches
    _documentCache.clear();
    _chunkCache.clear();
    
    _isInitialized = false;
  }
}

/// In-memory vector storage implementation (for testing/development)
class InMemoryVectorStorage extends VectorStorage {
  final Map<String, VectorDocument> _documents = {};
  final Map<String, List<VectorChunk>> _chunks = {};
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    print('🧠 Initializing in-memory vector storage');
    _isInitialized = true;
  }

  @override
  Future<void> storeDocument(VectorDocument document) async {
    if (!_isInitialized) await initialize();
    _documents[document.id] = document;
  }

  @override
  Future<VectorDocument?> getDocument(String documentId) async {
    if (!_isInitialized) await initialize();
    return _documents[documentId];
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    if (!_isInitialized) await initialize();
    _documents.remove(documentId);
  }

  @override
  Future<List<VectorDocument>> listDocuments({
    int? limit,
    int? offset,
    Map<String, dynamic>? filter,
  }) async {
    if (!_isInitialized) await initialize();
    
    List<VectorDocument> documents = _documents.values.toList();
    
    if (offset != null) documents = documents.skip(offset).toList();
    if (limit != null) documents = documents.take(limit).toList();
    
    return documents;
  }

  @override
  Future<void> storeChunks(List<VectorChunk> chunks) async {
    if (!_isInitialized) await initialize();
    if (chunks.isEmpty) return;
    
    final documentId = chunks.first.documentId;
    _chunks[documentId] = chunks;
  }

  @override
  Future<List<VectorChunk>> getChunks({
    List<String>? documentIds,
    Map<String, dynamic>? filter,
    int? limit,
    int? offset,
  }) async {
    if (!_isInitialized) await initialize();
    
    List<VectorChunk> allChunks = [];
    
    if (documentIds != null) {
      for (final docId in documentIds) {
        final chunks = _chunks[docId];
        if (chunks != null) allChunks.addAll(chunks);
      }
    } else {
      for (final chunks in _chunks.values) {
        allChunks.addAll(chunks);
      }
    }
    
    if (offset != null) allChunks = allChunks.skip(offset).toList();
    if (limit != null) allChunks = allChunks.take(limit).toList();
    
    return allChunks;
  }

  @override
  Future<void> deleteChunks(String documentId) async {
    if (!_isInitialized) await initialize();
    _chunks.remove(documentId);
  }

  @override
  Future<VectorDatabaseStats> getStats() async {
    if (!_isInitialized) await initialize();
    
    int totalChunks = 0;
    int totalEmbeddings = 0;
    
    for (final chunks in _chunks.values) {
      totalChunks += chunks.length;
      for (final chunk in chunks) {
        if (chunk.embedding != null) totalEmbeddings++;
      }
    }
    
    return VectorDatabaseStats(
      totalDocuments: _documents.length,
      totalChunks: totalChunks,
      totalEmbeddings: totalEmbeddings,
      lastUpdated: DateTime.now(),
      databaseVersion: '1.0.0',
    );
  }

  @override
  Future<void> optimize() async {
    // No-op for in-memory storage
  }

  @override
  Future<void> cleanup() async {
    // No-op for in-memory storage
  }

  @override
  Future<void> dispose() async {
    _documents.clear();
    _chunks.clear();
    _isInitialized = false;
  }
}

/// Factory for creating vector storage instances
class VectorStorageFactory {
  static VectorStorage createFile(String databasePath) {
    return FileVectorStorage(databasePath);
  }

  static VectorStorage createInMemory() {
    return InMemoryVectorStorage();
  }
}