import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/context_document.dart';
import '../../data/models/context_assignment.dart';
import '../../data/repositories/context_repository.dart';
import '../../../../core/services/business/context_business_service.dart';
import '../../../../core/services/context_vector_ingestion_service.dart';
import '../../../../core/services/vector_database_service.dart';
import '../../../../core/vector/models/vector_models.dart';

/// Provider for context documents
final contextDocumentsProvider = FutureProvider<List<ContextDocument>>((ref) async {
 final repository = ref.read(contextRepositoryProvider);
 return repository.getDocuments();
});

/// Provider for context documents filtered by type
final contextDocumentsByTypeProvider = FutureProvider.family<List<ContextDocument>, ContextType>((ref, type) async {
 final repository = ref.read(contextRepositoryProvider);
 return repository.getDocumentsByType(type);
});

/// Provider for context assignments
final contextAssignmentsProvider = FutureProvider<List<ContextAssignment>>((ref) async {
 final repository = ref.read(contextRepositoryProvider);
 return repository.getAssignments();
});

/// Provider for context assignments for a specific agent
final contextAssignmentsForAgentProvider = FutureProvider.family<List<ContextAssignment>, String>((ref, agentId) async {
 final repository = ref.read(contextRepositoryProvider);
 return repository.getAssignmentsForAgent(agentId);
});

/// Provider for context documents assigned to a specific agent
final contextForAgentProvider = FutureProvider.family<List<ContextDocument>, String>((ref, agentId) async {
 final repository = ref.read(contextRepositoryProvider);
 return repository.getContextForAgent(agentId);
});

/// Provider for searching context documents
final searchContextDocumentsProvider = FutureProvider.family<List<ContextDocument>, String>((ref, query) async {
 if (query.isEmpty) {
 return ref.read(contextDocumentsProvider.future);
 }
 
 final repository = ref.read(contextRepositoryProvider);
 return repository.searchDocuments(query);
});

/// Business service provider for context operations
final contextBusinessServiceProvider = Provider<ContextBusinessService>((ref) {
  final repository = ref.read(contextRepositoryProvider);
  
  // Get vector service (might be null during initialization)
  final vectorService = ref.read(contextVectorIngestionServiceProvider);
  
  return ContextBusinessService(
    repository: repository,
    vectorService: vectorService,
  );
});

/// Enhanced provider for context documents with vector database integration
final contextDocumentsWithVectorProvider = FutureProvider<List<ContextDocument>>((ref) async {
  try {
    // DEBUG: Sync missing vector database document (one-time fix)
    final repository = ref.read(contextRepositoryProvider);
    final currentDocs = await repository.getDocuments();
    if (currentDocs.isEmpty) {
      print('🔧 DEBUG: Context repository is empty, syncing vector database document...');
      await repository.syncVectorDatabaseDocument();
    }
    
    final businessService = ref.read(contextBusinessServiceProvider);
    final result = await businessService.getDocuments();
    
    if (result.isSuccess) {
      return result.data!;
    } else {
      throw Exception(result.error);
    }
  } catch (e) {
    print('❌ Failed to load context documents: $e');
    rethrow;
  }
});

/// Provider for vector search within context documents
final vectorSearchContextProvider = FutureProvider.family<List<VectorSearchResult>, VectorSearchParams>((ref, params) async {
  try {
    final vectorDB = await ref.read(vectorDatabaseProvider.future);
    
    final searchQuery = VectorSearchQuery(
      query: params.query,
      limit: params.limit,
      documentIds: params.documentIds,
      filter: params.filter,
      minSimilarity: params.minSimilarity,
      enableReranking: params.enableReranking,
    );
    
    return await vectorDB.search(searchQuery);
  } catch (e) {
    print('❌ Vector search failed: $e');
    return [];
  }
});

/// Provider for context document ingestion status
final contextIngestionStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final ingestionService = ref.read(contextVectorIngestionServiceProvider);
    if (ingestionService != null) {
      return await ingestionService.getIngestionStats();
    } else {
      return {
        'error': 'Vector ingestion service not available',
        'status': 'unavailable',
      };
    }
  } catch (e) {
    return {
      'error': e.toString(),
      'status': 'failed',
    };
  }
});

/// Provider to trigger full context sync
final syncAllContextProvider = FutureProvider<void>((ref) async {
  try {
    final ingestionService = ref.read(contextVectorIngestionServiceProvider);
    if (ingestionService != null) {
      await ingestionService.syncAllDocuments();
    } else {
      print('⚠️ Vector ingestion service not available for sync');
    }
    
    // Invalidate related providers to refresh UI
    ref.invalidate(contextDocumentsProvider);
    ref.invalidate(contextIngestionStatusProvider);
  } catch (e) {
    print('❌ Context sync failed: $e');
    rethrow;
  }
});

/// Notifier for managing context document operations using business service
class ContextDocumentNotifier extends AsyncNotifier<List<ContextDocument>> {
  @override
  Future<List<ContextDocument>> build() async {
    return ref.read(contextDocumentsWithVectorProvider.future);
  }

  /// Create a new context document
  Future<void> createDocument({
    required String title,
    required String content,
    required ContextType type,
    List<String> tags = const [],
    Map<String, dynamic> metadata = const {},
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final businessService = ref.read(contextBusinessServiceProvider);
      
      final result = await businessService.createDocument(
        title: title,
        content: content,
        type: type,
        tags: tags,
        metadata: metadata,
      );
      
      if (!result.isSuccess) {
        throw Exception(result.error);
      }
      
      // Refresh the state
      await _refreshState();
      
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Update a context document
  Future<void> updateDocument(ContextDocument document) async {
    state = const AsyncValue.loading();
    
    try {
      final businessService = ref.read(contextBusinessServiceProvider);
      
      final result = await businessService.updateDocument(document);
      
      if (!result.isSuccess) {
        throw Exception(result.error);
      }
      
      // Refresh the state
      await _refreshState();
      
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Delete a context document
  Future<void> deleteDocument(String documentId) async {
    state = const AsyncValue.loading();
    
    try {
      final businessService = ref.read(contextBusinessServiceProvider);
      
      final result = await businessService.deleteDocument(documentId);
      
      if (!result.isSuccess) {
        throw Exception(result.error);
      }
      
      // Refresh the state
      await _refreshState();
      
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Force sync with vector database
  Future<void> syncWithVectorDatabase() async {
    try {
      final businessService = ref.read(contextBusinessServiceProvider);
      final result = await businessService.syncWithVectorDatabase();
      
      if (!result.isSuccess) {
        throw Exception(result.error);
      }
    } catch (e) {
      print('❌ Vector sync failed: $e');
      rethrow;
    }
  }

  /// Refresh the state from business service
  Future<void> _refreshState() async {
    final businessService = ref.read(contextBusinessServiceProvider);
    final result = await businessService.getDocuments();
    
    if (result.isSuccess) {
      state = AsyncValue.data(result.data!);
    } else {
      state = AsyncValue.error(Exception(result.error), StackTrace.current);
    }
  }
}

/// Provider for context document notifier
final contextDocumentNotifierProvider = AsyncNotifierProvider<ContextDocumentNotifier, List<ContextDocument>>(() {
  return ContextDocumentNotifier();
});

/// Parameters for vector search
class VectorSearchParams {
  final String query;
  final int limit;
  final List<String>? documentIds;
  final Map<String, dynamic>? filter;
  final double minSimilarity;
  final bool enableReranking;

  const VectorSearchParams({
    required this.query,
    this.limit = 10,
    this.documentIds,
    this.filter,
    this.minSimilarity = 0.3,
    this.enableReranking = true,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VectorSearchParams &&
           other.query == query &&
           other.limit == limit &&
           other.documentIds == documentIds &&
           other.filter == filter &&
           other.minSimilarity == minSimilarity &&
           other.enableReranking == enableReranking;
  }

  @override
  int get hashCode {
    return Object.hash(query, limit, documentIds, filter, minSimilarity, enableReranking);
  }
}