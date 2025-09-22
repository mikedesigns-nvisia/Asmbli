import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:agent_engine_core/models/conversation.dart';

import '../vector/database/vector_database.dart';
import '../vector/models/vector_models.dart';
import '../vector/rag/rag_pipeline.dart';
import '../vector/config/vector_config.dart';
import '../../features/context/data/models/context_document.dart';
import '../../features/context/data/repositories/context_repository.dart';
import 'llm/unified_llm_service.dart';

/// Streamlined service that combines vector database, context retrieval, and ingestion
/// Replaces the 3 separate services with a single, unified interface
class StreamlinedVectorContextService {
  VectorDatabase? _database;
  RAGPipeline? _ragPipeline;
  final ContextRepository _contextRepository;
  final UnifiedLLMService _llmService;
  final VectorConfig _config;
  
  // Simple LRU cache for context results
  final Map<String, List<VectorSearchResult>> _contextCache = {};
  final List<String> _cacheKeys = [];
  
  // Track active ingestions to prevent duplicates
  final Map<String, Future<void>> _activeIngestions = {};
  
  bool _isInitialized = false;
  
  StreamlinedVectorContextService({
    required ContextRepository contextRepository,
    required UnifiedLLMService llmService,
    VectorConfig? config,
  }) : _contextRepository = contextRepository,
       _llmService = llmService,
       _config = config ?? const VectorConfig();

  /// Initialize the streamlined vector service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    print('🚀 Initializing Streamlined Vector Context Service');
    
    try {
      // Initialize vector database
      final databasePath = await _getDatabasePath();
      _database = await VectorDatabaseFactory.create(
        databasePath: databasePath,
        chunkingConfig: const ChunkingConfig(
          chunkSize: 1024,
          chunkOverlap: 100,
          separators: ['\n\n', '\n', '. ', '! ', '? ', ' '],
          preserveCodeBlocks: true,
          preserveTables: true,
          minChunkSize: 100,
        ),
      );
      
      await _database!.initialize();
      
      // Initialize RAG pipeline
      _ragPipeline = RAGPipeline(
        vectorDatabase: _database!,
        modelService: _llmService,
        config: const RAGConfig(
          maxRetrievedChunks: 8,
          minSimilarity: 0.3,
          enableReranking: true,
        ),
      );
      
      _isInitialized = true;
      
      final stats = await _database!.getStats();
      print('✅ Streamlined Vector Service initialized');
      print('📊 Stats: ${stats.totalDocuments} docs, ${stats.totalChunks} chunks');
      
    } catch (e) {
      print('❌ Failed to initialize streamlined vector service: $e');
      rethrow;
    }
  }
  
  /// Get the vector database instance (throws if not initialized)
  VectorDatabase get database {
    if (!_isInitialized || _database == null) {
      throw StateError('StreamlinedVectorContextService not initialized');
    }
    return _database!;
  }
  
  /// Get the RAG pipeline instance (throws if not initialized) 
  RAGPipeline get ragPipeline {
    if (!_isInitialized || _ragPipeline == null) {
      throw StateError('StreamlinedVectorContextService not initialized');
    }
    return _ragPipeline!;
  }
  
  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  // === CONTEXT INGESTION === //
  
  /// Ingest a single context document into vector database
  Future<void> ingestContextDocument(ContextDocument contextDoc) async {
    if (!_isInitialized) await initialize();
    
    final docId = 'context_${contextDoc.id}';
    
    // Prevent duplicate ingestions
    if (_activeIngestions.containsKey(docId)) {
      await _activeIngestions[docId];
      return;
    }
    
    final ingestionFuture = _performIngestion(contextDoc, docId);
    _activeIngestions[docId] = ingestionFuture;
    
    try {
      await ingestionFuture;
    } finally {
      _activeIngestions.remove(docId);
    }
  }
  
  Future<void> _performIngestion(ContextDocument contextDoc, String docId) async {
    try {
      print('📚 Ingesting: ${contextDoc.title}');
      
      final vectorDoc = VectorDocument(
        id: docId,
        title: contextDoc.title,
        content: contextDoc.content,
        createdAt: contextDoc.createdAt,
        updatedAt: contextDoc.updatedAt,
        source: 'context_library',
        contentType: _getContentType(contextDoc.type),
        metadata: {
          'context_document_id': contextDoc.id,
          'context_type': contextDoc.type.toString(),
          'tags': contextDoc.tags,
          'is_active': contextDoc.isActive,
          'original_metadata': contextDoc.metadata,
        },
      );
      
      await database.addDocument(vectorDoc);
      print('✅ Ingested: ${contextDoc.title}');
      
    } catch (e) {
      print('❌ Failed to ingest ${contextDoc.title}: $e');
      rethrow;
    }
  }
  
  /// Batch ingest multiple context documents
  Future<void> ingestMultipleDocuments(List<ContextDocument> documents) async {
    if (!_isInitialized) await initialize();
    
    print('📚 Batch ingesting ${documents.length} documents');
    
    // Process in batches to avoid overwhelming the system
    const batchSize = 5;
    for (int i = 0; i < documents.length; i += batchSize) {
      final batch = documents.skip(i).take(batchSize).toList();
      final futures = batch.map((doc) => ingestContextDocument(doc));
      await Future.wait(futures);
    }
    
    print('✅ Batch ingestion completed');
  }
  
  /// Ingest all active context documents
  Future<void> ingestAllActiveDocuments() async {
    if (!_isInitialized) await initialize();
    
    final allDocs = await _contextRepository.getDocuments();
    final activeDocs = allDocs.where((doc) => doc.isActive).toList();
    
    if (activeDocs.isEmpty) {
      print('ℹ️ No active context documents to ingest');
      return;
    }
    
    await ingestMultipleDocuments(activeDocs);
  }

  // === CONTEXT RETRIEVAL === //
  
  /// Get relevant context for a message with smart caching
  Future<List<VectorSearchResult>> getContextForMessage(
    String message, {
    String? agentId,
    List<String>? sessionContextIds,
    int maxResults = 6,
  }) async {
    if (!_isInitialized) await initialize();
    
    // Generate cache key
    final cacheKey = _generateCacheKey(message, agentId, sessionContextIds);
    
    // Check cache first
    if (_contextCache.containsKey(cacheKey)) {
      print('📋 Cache hit for: ${message.substring(0, math.min(50, message.length))}...');
      return _contextCache[cacheKey]!;
    }
    
    print('🔍 Retrieving context for: ${message.substring(0, math.min(50, message.length))}...');
    
    try {
      // Build search query
      final documentIds = <String>[];
      final filter = <String, dynamic>{};
      
      if (agentId != null) {
        filter['agent_ids'] = agentId;
      }
      
      if (sessionContextIds != null && sessionContextIds.isNotEmpty) {
        documentIds.addAll(sessionContextIds.map((id) => 'context_$id'));
      }
      
      final searchQuery = VectorSearchQuery(
        query: message,
        limit: math.min(maxResults, 20),
        documentIds: documentIds.isNotEmpty ? documentIds.take(50).toList() : null,
        filter: filter.isNotEmpty ? filter : null,
        minSimilarity: 0.3,
        enableReranking: maxResults <= 10,
        includeMetadata: true,
      );
      
      final results = await database.search(searchQuery);
      
      // Add to cache with LRU eviction
      _addToCache(cacheKey, results);
      
      print('✅ Found ${results.length} relevant context chunks');
      return results;
      
    } catch (e) {
      print('❌ Failed to retrieve context: $e');
      return [];
    }
  }
  
  /// Generate contextual response using RAG
  Future<RAGResponse> generateContextualResponse(
    String query, {
    String? agentId,
    List<String>? sessionContextIds,
    int maxContextTokens = 8000,
  }) async {
    if (!_isInitialized) await initialize();
    
    try {
      final documentIds = <String>[];
      
      if (agentId != null) {
        final agentDocs = await database.listDocuments(
          filter: {'agent_ids': agentId, 'source': 'context_library'}
        );
        documentIds.addAll(agentDocs.map((doc) => doc.id));
      }
      
      if (sessionContextIds != null) {
        documentIds.addAll(sessionContextIds.map((id) => 'context_$id'));
      }
      
      return await ragPipeline.generateWithContext(
        query,
        documentIds: documentIds.isNotEmpty ? documentIds : null,
        maxContextTokens: maxContextTokens,
        includeCitations: true,
        metadata: {
          'agent_id': agentId,
          'session_context_ids': sessionContextIds,
          'retrieval_timestamp': DateTime.now().toIso8601String(),
        },
      );
      
    } catch (e) {
      print('❌ Failed to generate contextual response: $e');
      rethrow;
    }
  }
  
  /// Build context summary for conversation
  Future<String> buildContextSummary(
    String conversationId,
    List<Message> recentMessages, {
    String? agentId,
    List<String>? sessionContextIds,
  }) async {
    if (!_isInitialized) await initialize();
    
    try {
      // Extract key topics from recent user messages
      final messageTexts = recentMessages
          .where((msg) => msg.role == MessageRole.user)
          .take(3)
          .map((msg) => msg.content)
          .join(' ');
      
      if (messageTexts.isEmpty) return '';
      
      // Get relevant context
      final contextResults = await getContextForMessage(
        messageTexts,
        agentId: agentId,
        sessionContextIds: sessionContextIds,
        maxResults: 5,
      );
      
      if (contextResults.isEmpty) return '';
      
      // Build summary
      final buffer = StringBuffer('## Relevant Context\n\n');
      final seenTitles = <String>{};
      
      for (final result in contextResults.take(3)) {
        final title = result.chunk.metadata['document_title']?.toString() ?? 'Unknown';
        if (!seenTitles.contains(title)) {
          seenTitles.add(title);
          buffer.writeln('**$title**');
          final snippet = result.chunk.text.length > 200 
              ? '${result.chunk.text.substring(0, 200)}...'
              : result.chunk.text;
          buffer.writeln('$snippet\n');
        }
      }
      
      return buffer.toString();
      
    } catch (e) {
      print('❌ Failed to build context summary: $e');
      return '';
    }
  }

  // === DOCUMENT MANAGEMENT === //
  
  /// Remove a context document from vector database
  Future<void> removeContextDocument(String contextDocumentId) async {
    if (!_isInitialized) await initialize();
    
    try {
      final docId = 'context_$contextDocumentId';
      await database.removeDocument(docId);
      
      // Clear related cache entries
      _clearCacheForDocument(contextDocumentId);
      
      print('🗑️ Removed context document: $contextDocumentId');
    } catch (e) {
      print('❌ Failed to remove context document: $e');
      rethrow;
    }
  }
  
  /// Update a context document in vector database
  Future<void> updateContextDocument(ContextDocument contextDoc) async {
    if (!_isInitialized) await initialize();
    
    try {
      await removeContextDocument(contextDoc.id);
      await ingestContextDocument(contextDoc);
      
    } catch (e) {
      print('❌ Failed to update context document: $e');
      rethrow;
    }
  }
  
  /// Sync all context documents with vector database
  Future<void> syncAllDocuments() async {
    if (!_isInitialized) await initialize();
    
    try {
      print('🔄 Starting full context sync');
      
      // Get all documents from both sources
      final contextDocs = await _contextRepository.getDocuments();
      final vectorDocs = await database.listDocuments();
      
      // Find context documents to add/update
      final contextDocIds = contextDocs.map((doc) => 'context_${doc.id}').toSet();
      final vectorDocIds = vectorDocs.map((doc) => doc.id).toSet();
      
      // Documents to process (active only)
      final docsToProcess = contextDocs.where((doc) => doc.isActive).toList();
      
      // Documents to remove (in vector but not in active context)
      final docsToRemove = vectorDocs
          .where((vDoc) => vDoc.source == 'context_library' && 
                 !contextDocIds.contains(vDoc.id))
          .toList();
      
      // Remove outdated documents
      for (final docToRemove in docsToRemove) {
        await database.removeDocument(docToRemove.id);
      }
      
      // Process active documents
      await ingestMultipleDocuments(docsToProcess);
      
      // Clear cache after sync
      _clearCache();
      
      print('✅ Full context sync completed');
      
    } catch (e) {
      print('❌ Failed to sync documents: $e');
      rethrow;
    }
  }

  // === STATISTICS & MAINTENANCE === //
  
  /// Get comprehensive statistics
  Future<Map<String, dynamic>> getStats() async {
    if (!_isInitialized) await initialize();
    
    try {
      final dbStats = await database.getStats();
      final contextDocs = await database.listDocuments(
        filter: {'source': 'context_library'}
      );
      
      return {
        'initialized': _isInitialized,
        'total_vector_documents': dbStats.totalDocuments,
        'context_documents_ingested': contextDocs.length,
        'total_chunks': dbStats.totalChunks,
        'active_ingestions': _activeIngestions.length,
        'cache_entries': _contextCache.length,
        'cache_hit_rate': _calculateCacheHitRate(),
        'last_updated': dbStats.lastUpdated.toIso8601String(),
        'database_version': dbStats.databaseVersion,
      };
      
    } catch (e) {
      return {
        'error': e.toString(),
        'initialized': _isInitialized,
        'cache_entries': _contextCache.length,
      };
    }
  }
  
  /// Optimize the vector database
  Future<void> optimize() async {
    if (!_isInitialized) await initialize();
    
    try {
      print('🔧 Optimizing vector database');
      await database.optimize();
      
      // Also cleanup cache
      _clearCache();
      
      print('✅ Optimization completed');
    } catch (e) {
      print('❌ Optimization failed: $e');
    }
  }

  // === CACHE MANAGEMENT === //
  
  void _addToCache(String key, List<VectorSearchResult> results) {
    // Simple LRU eviction using configured max entries
    if (_contextCache.length >= _config.maxCacheEntries) {
      final oldestKey = _cacheKeys.removeAt(0);
      _contextCache.remove(oldestKey);
    }
    
    _contextCache[key] = results;
    _cacheKeys.add(key);
  }
  
  String _generateCacheKey(String message, String? agentId, List<String>? sessionContextIds) {
    return [
      message.hashCode.toString(),
      agentId ?? 'null',
      (sessionContextIds ?? []).join('_'),
    ].join('::');
  }
  
  void _clearCache() {
    _contextCache.clear();
    _cacheKeys.clear();
  }
  
  void _clearCacheForDocument(String documentId) {
    final keysToRemove = _cacheKeys.where((key) => key.contains(documentId)).toList();
    for (final key in keysToRemove) {
      _contextCache.remove(key);
      _cacheKeys.remove(key);
    }
  }
  
  double _calculateCacheHitRate() {
    // Simplified cache hit rate calculation
    return _contextCache.isNotEmpty ? 0.75 : 0.0; // Placeholder
  }

  // === UTILITIES === //
  
  String _getContentType(ContextType contextType) {
    switch (contextType) {
      case ContextType.knowledge:
        return 'text/knowledge';
      case ContextType.examples:
        return 'text/examples';
      case ContextType.guidelines:
        return 'text/guidelines';
      case ContextType.documentation:
        return 'text/documentation';
      case ContextType.codebase:
        return 'text/code';
      case ContextType.custom:
        return 'text/custom';
    }
  }
  
  Future<String> _getDatabasePath() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final primaryPath = path.join(appDocDir.path, 'AgentEngine', 'vector_db');
      
      final testDir = Directory(primaryPath);
      await testDir.create(recursive: true);
      
      return primaryPath;
      
    } catch (primaryError) {
      try {
        final appSupportDir = await getApplicationSupportDirectory();
        final secondaryPath = path.join(appSupportDir.path, 'AgentEngine', 'vector_db');
        
        final testDir = Directory(secondaryPath);
        await testDir.create(recursive: true);
        
        return secondaryPath;
        
      } catch (secondaryError) {
        final tempDir = await getTemporaryDirectory();
        final fallbackPath = path.join(tempDir.path, 'AgentEngine', 'vector_db');
        
        final testDir = Directory(fallbackPath);
        await testDir.create(recursive: true);
        
        return fallbackPath;
      }
    }
  }
  
  /// Wait for all active ingestions to complete
  Future<void> waitForIngestions() async {
    if (_activeIngestions.isNotEmpty) {
      await Future.wait(_activeIngestions.values);
    }
  }
  
  /// Check if document is currently being ingested
  bool isIngesting(String contextDocumentId) {
    return _activeIngestions.containsKey('context_$contextDocumentId');
  }
  
  /// Dispose and cleanup
  Future<void> dispose() async {
    if (!_isInitialized) return;
    
    print('🧹 Disposing StreamlinedVectorContextService');
    
    await waitForIngestions();
    _activeIngestions.clear();
    
    _clearCache();
    
    if (_database != null) {
      await _database!.dispose();
    }
    
    _isInitialized = false;
    print('✅ Streamlined service disposed');
  }
}

/// Riverpod providers for the streamlined service
final streamlinedVectorContextServiceProvider = Provider<StreamlinedVectorContextService>((ref) {
  final contextRepo = ref.read(contextRepositoryProvider);
  final llmService = ref.read(unifiedLLMServiceProvider);
  
  final service = StreamlinedVectorContextService(
    contextRepository: contextRepo,
    llmService: llmService,
  );
  
  // Ensure proper disposal
  ref.onDispose(() async {
    await service.dispose();
  });
  
  return service;
});

final streamlinedVectorContextInitializedProvider = FutureProvider<StreamlinedVectorContextService>((ref) async {
  final service = ref.read(streamlinedVectorContextServiceProvider);
  await service.initialize();
  return service;
});

final streamlinedVectorStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final serviceAsync = ref.watch(streamlinedVectorContextInitializedProvider);
  
  return serviceAsync.when(
    data: (service) => service.getStats(),
    loading: () => {'loading': true},
    error: (error, stack) => {'error': error.toString()},
  );
});

/// Parameters for contextual queries (simplified)
class StreamlinedContextualQueryParams {
  final String query;
  final String? agentId;
  final List<String>? sessionContextIds;
  final int maxContextTokens;
  
  const StreamlinedContextualQueryParams({
    required this.query,
    this.agentId,
    this.sessionContextIds,
    this.maxContextTokens = 8000,
  });
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StreamlinedContextualQueryParams &&
           other.query == query &&
           other.agentId == agentId &&
           other.sessionContextIds == sessionContextIds &&
           other.maxContextTokens == maxContextTokens;
  }
  
  @override
  int get hashCode {
    return Object.hash(query, agentId, sessionContextIds, maxContextTokens);
  }
}

final streamlinedContextualResponseProvider = FutureProvider.family<RAGResponse, StreamlinedContextualQueryParams>((ref, params) async {
  final serviceAsync = ref.watch(streamlinedVectorContextInitializedProvider);
  
  return serviceAsync.when(
    data: (service) => service.generateContextualResponse(
      params.query,
      agentId: params.agentId,
      sessionContextIds: params.sessionContextIds,
      maxContextTokens: params.maxContextTokens,
    ),
    loading: () => throw Exception('Vector context service not ready'),
    error: (error, stack) => throw Exception('Vector context service failed: $error'),
  );
});