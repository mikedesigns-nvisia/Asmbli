import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/models/conversation.dart';
import '../vector/database/vector_database.dart';
import '../vector/models/vector_models.dart';
import '../vector/rag/rag_pipeline.dart';
import 'llm/unified_llm_service.dart';
import 'vector_database_service.dart';

/// Production service for retrieving relevant context for chat conversations
class VectorContextRetrievalService {
  final VectorDatabase _vectorDB;
  final RAGPipeline _ragPipeline;
  
  // Cache for frequently accessed contexts - with size limits to prevent memory leaks
  final Map<String, List<VectorSearchResult>> _contextCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);
  static const int _maxCacheEntries = 100; // Limit cache size to prevent unbounded growth
  
  VectorContextRetrievalService({
    required VectorDatabase vectorDatabase,
    required UnifiedLLMService llmService,
  }) : _vectorDB = vectorDatabase,
       _ragPipeline = RAGPipeline(
         vectorDatabase: vectorDatabase,
         modelService: llmService,
         config: const RAGConfig(
           maxRetrievedChunks: 8,
           minSimilarity: 0.3,
           enableReranking: true,
         ),
       );

  /// Retrieve relevant context for a user message
  Future<List<VectorSearchResult>> getContextForMessage(
    String message, {
    String? agentId,
    List<String>? sessionContextIds,
    int maxResults = 6,
  }) async {
    try {
      final cacheKey = _generateCacheKey(message, agentId, sessionContextIds);
      
      // Check cache first
      if (_isCacheValid(cacheKey)) {
        print('📋 Using cached context for: ${message.substring(0, 50)}...');
        return _contextCache[cacheKey]!;
      }
      
      print('🔍 Retrieving context for: ${message.substring(0, 50)}...');
      
      // Build document filter for agent-specific context
      final documentIds = <String>[];
      final filter = <String, dynamic>{};
      
      // Add agent-specific context if specified
      if (agentId != null) {
        filter['agent_ids'] = agentId;
      }
      
      // Add session context documents if specified
      if (sessionContextIds != null && sessionContextIds.isNotEmpty) {
        documentIds.addAll(sessionContextIds.map((id) => 'context_$id'));
      }
      
      // Create optimized search query with performance tuning
      final searchQuery = VectorSearchQuery(
        query: message,
        limit: math.min(maxResults, 20), // Cap results to prevent performance issues
        documentIds: documentIds?.take(50).toList(), // Limit document filter size
        filter: filter.isNotEmpty ? _optimizeFilter(filter) : null,
        minSimilarity: 0.3, // Higher threshold for better quality/performance
        enableReranking: maxResults <= 10, // Only rerank for small result sets
        includeMetadata: true,
      );
      
      final results = await _vectorDB.search(searchQuery);
      
      // Cache the results with size management
      _addToCache(cacheKey, results);
      
      print('✅ Found ${results.length} relevant context chunks');
      return results;
      
    } catch (e) {
      print('❌ Failed to retrieve context: $e');
      return [];
    }
  }

  /// Get context specifically for agent conversations
  Future<List<VectorSearchResult>> getAgentContext(
    String message,
    String agentId, {
    int maxResults = 8,
  }) async {
    return await getContextForMessage(
      message,
      agentId: agentId,
      maxResults: maxResults,
    );
  }

  /// Get session context for temporary context documents
  Future<List<VectorSearchResult>> getSessionContext(
    String message,
    List<String> sessionContextIds, {
    int maxResults = 5,
  }) async {
    return await getContextForMessage(
      message,
      sessionContextIds: sessionContextIds,
      maxResults: maxResults,
    );
  }

  /// Generate RAG response with retrieved context
  Future<RAGResponse> generateContextualResponse(
    String query, {
    String? agentId,
    List<String>? sessionContextIds,
    int maxContextTokens = 8000,
  }) async {
    try {
      // Build document filter
      final documentIds = <String>[];
      
      if (agentId != null) {
        // Get all documents for this agent
        final agentDocs = await _vectorDB.listDocuments(
          filter: {'agent_ids': agentId, 'source': 'context_library'}
        );
        documentIds.addAll(agentDocs.map((doc) => doc.id));
      }
      
      if (sessionContextIds != null) {
        documentIds.addAll(sessionContextIds.map((id) => 'context_$id'));
      }
      
      return await _ragPipeline.generateWithContext(
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
    try {
      // Extract key topics from recent messages
      final messageTexts = recentMessages
          .where((msg) => msg.role == MessageRole.user)
          .take(3)
          .map((msg) => msg.content)
          .join(' ');
      
      if (messageTexts.isEmpty) {
        return '';
      }
      
      // Get relevant context
      final contextResults = await getContextForMessage(
        messageTexts,
        agentId: agentId,
        sessionContextIds: sessionContextIds,
        maxResults: 5,
      );
      
      if (contextResults.isEmpty) {
        return '';
      }
      
      // Build summary
      final buffer = StringBuffer();
      buffer.writeln('## Relevant Context\n');
      
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

  /// Get context statistics for debugging
  Future<Map<String, dynamic>> getContextStats({
    String? agentId,
    List<String>? sessionContextIds,
  }) async {
    try {
      final filter = <String, dynamic>{};
      final documentIds = <String>[];
      
      if (agentId != null) {
        filter['agent_ids'] = agentId;
      }
      
      if (sessionContextIds != null) {
        documentIds.addAll(sessionContextIds.map((id) => 'context_$id'));
      }
      
      final relevantDocs = await _vectorDB.listDocuments(
        filter: filter.isNotEmpty ? filter : null,
      );
      
      final filteredDocs = documentIds.isEmpty 
          ? relevantDocs 
          : relevantDocs.where((doc) => documentIds.contains(doc.id)).toList();
      
      final totalChunks = await Future.wait(
        filteredDocs.map((doc) => _vectorDB.getDocumentChunks(doc.id))
      );
      
      return {
        'available_documents': filteredDocs.length,
        'total_chunks': totalChunks.fold(0, (sum, chunks) => sum + chunks.length),
        'cache_entries': _contextCache.length,
        'agent_id': agentId,
        'session_context_count': sessionContextIds?.length ?? 0,
      };
      
    } catch (e) {
      return {
        'error': e.toString(),
        'cache_entries': _contextCache.length,
      };
    }
  }

  /// Add entry to cache with size and expiry management
  void _addToCache(String key, List<VectorSearchResult> results) {
    // Clean up expired entries first
    _cleanupCache();
    
    // If cache is at max size, remove oldest entry
    if (_contextCache.length >= _maxCacheEntries) {
      final oldestKey = _cacheTimestamps.entries
          .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
          .key;
      _contextCache.remove(oldestKey);
      _cacheTimestamps.remove(oldestKey);
    }
    
    _contextCache[key] = results;
    _cacheTimestamps[key] = DateTime.now();
  }

  /// Optimize filter for better search performance
  Map<String, dynamic> _optimizeFilter(Map<String, dynamic> filter) {
    final optimized = <String, dynamic>{};
    
    // Only include most selective filters to improve performance
    if (filter.containsKey('agent_ids')) {
      optimized['agent_ids'] = filter['agent_ids'];
    }
    if (filter.containsKey('context_type')) {
      optimized['context_type'] = filter['context_type'];
    }
    if (filter.containsKey('is_active')) {
      optimized['is_active'] = filter['is_active'];
    }
    
    return optimized;
  }

  /// Clear expired cache entries
  void _cleanupCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheExpiry) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _contextCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  /// Generate cache key for context retrieval
  String _generateCacheKey(String message, String? agentId, List<String>? sessionContextIds) {
    final keyParts = [
      message.hashCode.toString(),
      agentId ?? 'null',
      (sessionContextIds ?? []).join('_'),
    ];
    return keyParts.join('::');
  }

  /// Check if cache entry is valid
  bool _isCacheValid(String key) {
    if (!_contextCache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }
    
    final timestamp = _cacheTimestamps[key]!;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  /// Clear all cached context
  void clearCache() {
    _contextCache.clear();
    _cacheTimestamps.clear();
  }

  /// Preload context for agent
  Future<void> preloadAgentContext(String agentId) async {
    try {
      // Get a few sample queries to warm the cache
      final sampleQueries = [
        'help',
        'how do I',
        'what is',
        'explain',
        'example',
      ];
      
      for (final query in sampleQueries) {
        await getAgentContext(query, agentId, maxResults: 3);
      }
      
      print('✅ Preloaded context for agent: $agentId');
      
    } catch (e) {
      print('⚠️ Failed to preload agent context: $e');
    }
  }

  /// Dispose and cleanup
  Future<void> dispose() async {
    clearCache();
  }
}

/// Riverpod provider for vector context retrieval service
final vectorContextRetrievalServiceProvider = Provider<VectorContextRetrievalService?>((ref) {
  final vectorDBAsync = ref.watch(vectorDatabaseProvider);
  final llmService = ref.read(unifiedLLMServiceProvider);
  
  return vectorDBAsync.when(
    data: (vectorDB) => VectorContextRetrievalService(
      vectorDatabase: vectorDB,
      llmService: llmService,
    ),
    loading: () => null, // Return null while loading instead of crashing
    error: (error, stack) {
      print('⚠️ Vector database initialization failed: $error');
      return null; // Return null on error instead of crashing  
    },
  );
});

/// Provider for contextual responses
final contextualResponseProvider = FutureProvider.family<RAGResponse, ContextualQueryParams>((ref, params) async {
  final service = ref.read(vectorContextRetrievalServiceProvider);
  
  if (service != null) {
    return await service.generateContextualResponse(
      params.query,
      agentId: params.agentId,
      sessionContextIds: params.sessionContextIds,
      maxContextTokens: params.maxContextTokens,
    );
  } else {
    throw Exception('Vector context retrieval service not available');
  }
});

/// Parameters for contextual query
class ContextualQueryParams {
  final String query;
  final String? agentId;
  final List<String>? sessionContextIds;
  final int maxContextTokens;
  
  const ContextualQueryParams({
    required this.query,
    this.agentId,
    this.sessionContextIds,
    this.maxContextTokens = 8000,
  });
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContextualQueryParams &&
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