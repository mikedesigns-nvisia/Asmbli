import 'dart:async';
import 'dart:math';
import '../models/vector_models.dart';
import '../processing/document_chunker.dart';
import '../embeddings/embedding_service.dart';
import '../storage/vector_storage.dart';

/// Main vector database class that provides semantic search capabilities
class VectorDatabase {
  final EmbeddingService _embeddingService;
  final VectorStorage _storage;
  final DocumentChunker _chunker;
  
  bool _isInitialized = false;
  Timer? _maintenanceTimer;
  
  VectorDatabase({
    required EmbeddingService embeddingService,
    required VectorStorage storage,
    DocumentChunker? chunker,
  }) : _embeddingService = embeddingService,
       _storage = storage,
       _chunker = chunker ?? const DocumentChunker();

  /// Initialize the vector database
  Future<void> initialize() async {
    if (_isInitialized) return;

    print('🚀 Initializing Vector Database');

    try {
      // Initialize storage
      await _storage.initialize();
      
      // Initialize embedding service
      if (_embeddingService is LocalEmbeddingService) {
        await (_embeddingService as LocalEmbeddingService).initialize();
      }
      
      // Start maintenance tasks
      _startMaintenanceTasks();
      
      _isInitialized = true;
      
      final stats = await getStats();
      print('✅ Vector Database initialized');
      print('📊 Current stats: ${stats.totalDocuments} docs, ${stats.totalChunks} chunks');
      
    } catch (e) {
      throw VectorDatabaseException('Failed to initialize vector database: $e');
    }
  }

  /// Add a document to the vector database
  Future<void> addDocument(VectorDocument document) async {
    if (!_isInitialized) {
      await initialize();
    }

    print('📄 Adding document: ${document.title}');
    final startTime = DateTime.now();

    try {
      // Check if document already exists
      final existingDoc = await _storage.getDocument(document.id);
      if (existingDoc != null) {
        print('⚠️ Document ${document.id} already exists, updating...');
        await updateDocument(document);
        return;
      }

      // Chunk the document
      final chunks = _chunker.chunkDocument(document);
      print('🔧 Created ${chunks.length} chunks');

      // Generate embeddings for all chunks
      final texts = chunks.map((chunk) => chunk.text).toList();
      final embeddings = await _embeddingService.generateEmbeddings(texts);
      
      // Add embeddings to chunks
      final chunksWithEmbeddings = <VectorChunk>[];
      for (int i = 0; i < chunks.length; i++) {
        chunksWithEmbeddings.add(chunks[i].copyWith(embedding: embeddings[i]));
      }

      // Store document and chunks
      await _storage.storeDocument(document);
      await _storage.storeChunks(chunksWithEmbeddings);

      final duration = DateTime.now().difference(startTime);
      print('✅ Added document ${document.title} in ${duration.inMilliseconds}ms');
      
    } catch (e) {
      throw VectorDatabaseException('Failed to add document ${document.id}: $e');
    }
  }

  /// Update an existing document
  Future<void> updateDocument(VectorDocument document) async {
    if (!_isInitialized) {
      await initialize();
    }

    print('🔄 Updating document: ${document.title}');
    final startTime = DateTime.now();

    try {
      // Remove existing chunks
      await _storage.deleteChunks(document.id);
      
      // Process the updated document directly (avoid addDocument to prevent infinite loop)
      // Chunk the document
      final chunks = _chunker.chunkDocument(document);
      print('🔧 Created ${chunks.length} chunks');

      // Generate embeddings for all chunks
      final texts = chunks.map((chunk) => chunk.text).toList();
      final embeddings = await _embeddingService.generateEmbeddings(texts);
      
      // Add embeddings to chunks
      final chunksWithEmbeddings = <VectorChunk>[];
      for (int i = 0; i < chunks.length; i++) {
        chunksWithEmbeddings.add(chunks[i].copyWith(embedding: embeddings[i]));
      }

      // Store document and chunks
      await _storage.storeDocument(document);
      await _storage.storeChunks(chunksWithEmbeddings);

      final duration = DateTime.now().difference(startTime);
      print('✅ Updated document ${document.title} in ${duration.inMilliseconds}ms');
      
    } catch (e) {
      throw VectorDatabaseException('Failed to update document ${document.id}: $e');
    }
  }

  /// Remove a document from the vector database
  Future<void> removeDocument(String documentId) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _storage.deleteDocument(documentId);
      await _storage.deleteChunks(documentId);
      
      print('🗑️ Removed document: $documentId');
      
    } catch (e) {
      throw VectorDatabaseException('Failed to remove document $documentId: $e');
    }
  }

  /// Perform semantic search
  Future<List<VectorSearchResult>> search(VectorSearchQuery query) async {
    if (!_isInitialized) {
      await initialize();
    }

    print('🔍 Searching: "${query.query}" (limit: ${query.limit})');
    final startTime = DateTime.now();

    try {
      // Generate query embedding
      final queryEmbedding = await _embeddingService.generateEmbedding(query.query);
      
      // Search for similar chunks
      final candidateResults = await _searchSimilarChunks(
        queryEmbedding,
        query.limit * 2, // Get more candidates for reranking
        query.filter,
        query.documentIds,
        query.minSimilarity,
      );

      // Rerank if enabled and we have candidates
      List<VectorSearchResult> finalResults;
      if (query.enableReranking && candidateResults.isNotEmpty) {
        finalResults = await _rerankResults(query.query, candidateResults);
      } else {
        finalResults = candidateResults;
      }

      // Apply final limit
      finalResults = finalResults.take(query.limit).toList();

      final duration = DateTime.now().difference(startTime);
      print('✅ Found ${finalResults.length} results in ${duration.inMilliseconds}ms');

      return finalResults;
      
    } catch (e) {
      throw VectorDatabaseException('Search failed: $e');
    }
  }

  /// Search for similar chunks using vector similarity
  Future<List<VectorSearchResult>> _searchSimilarChunks(
    List<double> queryEmbedding,
    int limit,
    Map<String, dynamic>? filter,
    List<String>? documentIds,
    double minSimilarity,
  ) async {
    // Get all chunks (with optional filtering)
    final chunks = await _storage.getChunks(
      documentIds: documentIds,
      filter: filter,
    );

    // Calculate similarities
    final results = <VectorSearchResult>[];
    
    for (final chunk in chunks) {
      if (chunk.embedding == null) continue;
      
      final similarity = _embeddingService.calculateSimilarity(
        queryEmbedding,
        chunk.embedding!,
      );
      
      if (similarity >= minSimilarity) {
        results.add(VectorSearchResult(
          chunk: chunk,
          similarity: similarity,
          debugInfo: {
            'embedding_dimension': chunk.embedding!.length,
            'chunk_length': chunk.text.length,
          },
        ));
      }
    }

    // Sort by similarity (highest first)
    results.sort((a, b) => b.similarity.compareTo(a.similarity));
    
    return results.take(limit).toList();
  }

  /// Rerank search results using advanced scoring
  Future<List<VectorSearchResult>> _rerankResults(
    String query,
    List<VectorSearchResult> results,
  ) async {
    if (results.isEmpty) return results;

    print('🎯 Reranking ${results.length} results');

    // Simple reranking based on multiple factors
    final rerankedResults = <VectorSearchResult>[];
    
    for (final result in results) {
      final chunk = result.chunk;
      
      // Calculate various scoring factors
      final textLength = chunk.text.length;
      final wordCount = chunk.text.split(RegExp(r'\s+')).length;
      final hasTitle = chunk.metadata['document_title']?.toString().isNotEmpty == true;
      
      // BM25-like scoring factors
      final queryTerms = query.toLowerCase().split(RegExp(r'\s+'));
      final chunkText = chunk.text.toLowerCase();
      
      double termFrequencyScore = 0;
      for (final term in queryTerms) {
        final occurrences = term.allMatches(chunkText).length;
        if (occurrences > 0) {
          // TF component
          termFrequencyScore += occurrences / wordCount;
        }
      }
      
      // Position bonus (earlier chunks might be more important)
      final positionBonus = chunk.chunkIndex == 0 ? 0.1 : 
                           chunk.chunkIndex < 3 ? 0.05 : 0.0;
      
      // Length penalty for very short or very long chunks
      final lengthPenalty = textLength < 100 ? 0.9 : 
                           textLength > 1000 ? 0.95 : 1.0;
      
      // Combined rerank score
      final rerankScore = (
        result.similarity * 0.7 +           // Vector similarity weight
        termFrequencyScore * 0.2 +          // Term frequency weight
        positionBonus +                     // Position bonus
        (hasTitle ? 0.05 : 0.0)            // Title bonus
      ) * lengthPenalty;
      
      rerankedResults.add(result.copyWith(
        rerankScore: rerankScore,
        debugInfo: {
          ...result.debugInfo,
          'original_similarity': result.similarity,
          'term_frequency_score': termFrequencyScore,
          'position_bonus': positionBonus,
          'length_penalty': lengthPenalty,
        },
      ));
    }

    // Sort by rerank score
    rerankedResults.sort((a, b) => b.effectiveScore.compareTo(a.effectiveScore));
    
    return rerankedResults;
  }

  /// Get similar documents to a given document
  Future<List<VectorSearchResult>> findSimilarDocuments(
    String documentId, {
    int limit = 5,
    double minSimilarity = 0.5,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Get the document
      final document = await _storage.getDocument(documentId);
      if (document == null) {
        throw VectorDatabaseException('Document not found: $documentId');
      }

      // Use the document title and first part of content as query
      final query = '${document.title}\n${document.content.substring(0, min(500, document.content.length))}';
      
      final searchQuery = VectorSearchQuery(
        query: query,
        limit: limit + 5, // Get extra to filter out self
        minSimilarity: minSimilarity,
        enableReranking: true,
      );

      final results = await search(searchQuery);
      
      // Filter out chunks from the same document
      final filteredResults = results
          .where((result) => result.chunk.documentId != documentId)
          .take(limit)
          .toList();

      return filteredResults;
      
    } catch (e) {
      throw VectorDatabaseException('Failed to find similar documents: $e');
    }
  }

  /// Get database statistics
  Future<VectorDatabaseStats> getStats() async {
    if (!_isInitialized) {
      await initialize();
    }

    return await _storage.getStats();
  }

  /// Get a specific document by ID
  Future<VectorDocument?> getDocument(String documentId) async {
    if (!_isInitialized) {
      await initialize();
    }

    return await _storage.getDocument(documentId);
  }

  /// List all documents with optional filtering
  Future<List<VectorDocument>> listDocuments({
    int? limit,
    int? offset,
    Map<String, dynamic>? filter,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    return await _storage.listDocuments(
      limit: limit,
      offset: offset,
      filter: filter,
    );
  }

  /// Get chunks for a specific document
  Future<List<VectorChunk>> getDocumentChunks(String documentId) async {
    if (!_isInitialized) {
      await initialize();
    }

    return await _storage.getChunks(documentIds: [documentId]);
  }

  /// Optimize the database (cleanup, reindex, etc.)
  Future<void> optimize() async {
    if (!_isInitialized) {
      await initialize();
    }

    print('🔧 Optimizing vector database');
    
    try {
      await _storage.optimize();
      print('✅ Database optimization completed');
    } catch (e) {
      print('⚠️ Database optimization failed: $e');
    }
  }

  /// Start periodic maintenance tasks
  void _startMaintenanceTasks() {
    // Run maintenance every hour
    _maintenanceTimer = Timer.periodic(const Duration(hours: 1), (timer) async {
      try {
        await _runMaintenance();
      } catch (e) {
        print('⚠️ Maintenance task failed: $e');
      }
    });
  }

  /// Run maintenance tasks
  Future<void> _runMaintenance() async {
    print('🧹 Running database maintenance');
    
    // Cleanup orphaned data
    await _storage.cleanup();
    
    // Update statistics
    final stats = await getStats();
    print('📊 Maintenance complete - ${stats.totalDocuments} docs, ${stats.totalChunks} chunks');
  }

  /// Dispose of the vector database
  Future<void> dispose() async {
    if (!_isInitialized) return;

    print('🧹 Disposing vector database');
    
    _maintenanceTimer?.cancel();
    
    await _embeddingService.dispose();
    await _storage.dispose();
    
    _isInitialized = false;
    print('✅ Vector database disposed');
  }
}

/// Exception for vector database operations
class VectorDatabaseException implements Exception {
  final String message;
  final dynamic originalError;

  const VectorDatabaseException(this.message, [this.originalError]);

  @override
  String toString() {
    final buffer = StringBuffer('VectorDatabaseException: $message');
    if (originalError != null) {
      buffer.write(' (caused by: $originalError)');
    }
    return buffer.toString();
  }
}

/// Factory for creating vector database instances
class VectorDatabaseFactory {
  static Future<VectorDatabase> create({
    required String databasePath,
    EmbeddingService? embeddingService,
    ChunkingConfig? chunkingConfig,
  }) async {
    // Create default embedding service if not provided
    embeddingService ??= EmbeddingServiceFactory.createLocal();
    
    // Create storage
    final storage = VectorStorageFactory.createFile(databasePath);
    
    // Create chunker with config
    final chunker = DocumentChunker(
      config: chunkingConfig ?? const ChunkingConfig(),
    );
    
    final database = VectorDatabase(
      embeddingService: embeddingService,
      storage: storage,
      chunker: chunker,
    );
    
    return database;
  }

  static Future<VectorDatabase> createInMemory({
    EmbeddingService? embeddingService,
    ChunkingConfig? chunkingConfig,
  }) async {
    // Create default embedding service if not provided
    embeddingService ??= EmbeddingServiceFactory.createLocal();
    
    // Create in-memory storage
    final storage = VectorStorageFactory.createInMemory();
    
    // Create chunker with config
    final chunker = DocumentChunker(
      config: chunkingConfig ?? const ChunkingConfig(),
    );
    
    final database = VectorDatabase(
      embeddingService: embeddingService,
      storage: storage,
      chunker: chunker,
    );
    
    return database;
  }
}