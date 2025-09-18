import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/context_document.dart';
import '../../data/models/context_assignment.dart';
import '../../data/repositories/context_repository.dart';
import '../../../../core/services/business/context_business_service.dart';
import '../../../../core/services/streamlined_vector_context_service.dart';
import '../../../../core/vector/models/vector_models.dart';
import '../../../chat/presentation/widgets/contextual_context_widget.dart';

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
  
  // Use streamlined vector service instead of separate ingestion service
  final vectorServiceAsync = ref.watch(streamlinedVectorContextInitializedProvider);
  
  return ContextBusinessService(
    repository: repository,
    vectorService: vectorServiceAsync.when(
      data: (service) => _VectorServiceAdapter(service),
      loading: () => null,
      error: (_, __) => null,
    ),
  );
});

/// Enhanced provider for context documents with vector database integration
final contextDocumentsWithVectorProvider = FutureProvider<List<ContextDocument>>((ref) async {
  try {
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

/// Provider for vector search within context documents using streamlined service
final vectorSearchContextProvider = FutureProvider.family<List<VectorSearchResult>, VectorSearchParams>((ref, params) async {
  try {
    final vectorService = await ref.read(streamlinedVectorContextInitializedProvider.future);
    
    return await vectorService.getContextForMessage(
      params.query,
      maxResults: params.limit,
    );
  } catch (e) {
    print('❌ Vector search failed: $e');
    return [];
  }
});

/// Provider for context document ingestion status using streamlined service
final contextIngestionStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final vectorService = await ref.read(streamlinedVectorContextInitializedProvider.future);
    return await vectorService.getStats();
  } catch (e) {
    return {
      'error': e.toString(),
      'status': 'failed',
    };
  }
});

/// Provider to trigger full context sync using streamlined service
final syncAllContextProvider = FutureProvider<void>((ref) async {
  try {
    final vectorService = await ref.read(streamlinedVectorContextInitializedProvider.future);
    await vectorService.syncAllDocuments();
    
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

/// Adapter to make StreamlinedVectorContextService compatible with ContextBusinessService
class _VectorServiceAdapter {
  final StreamlinedVectorContextService _service;
  
  _VectorServiceAdapter(this._service);
  
  Future<void> ingestContextDocument(ContextDocument contextDoc) async {
    await _service.ingestContextDocument(contextDoc);
  }
  
  Future<void> removeContextDocument(String contextDocumentId) async {
    await _service.removeContextDocument(contextDocumentId);
  }
  
  Future<void> updateContextDocument(ContextDocument contextDoc) async {
    await _service.updateContextDocument(contextDoc);
  }
  
  Future<void> syncAllDocuments() async {
    await _service.syncAllDocuments();
  }
  
  Future<Map<String, dynamic>> getIngestionStats() async {
    return await _service.getStats();
  }
  
  bool isIngesting(String contextDocumentId) {
    return _service.isIngesting(contextDocumentId);
  }
  
  Future<void> ingestMultipleDocuments(List<ContextDocument> documents) async {
    for (final doc in documents) {
      await _service.ingestContextDocument(doc);
    }
  }
}

/// Provider for deleting a context document - DIRECT REPOSITORY VERSION
final deleteContextDocumentProvider = FutureProvider.family<void, String>((ref, documentId) async {
  try {
    print('🗑️ [DIRECT] Starting delete for document: $documentId');
    final repository = ref.read(contextRepositoryProvider);
    
    // Get documents before deletion for debugging
    final beforeDocs = await repository.getDocuments();
    print('📊 [DIRECT] Documents before deletion: ${beforeDocs.length}');
    final targetDoc = beforeDocs.where((doc) => doc.id == documentId).toList();
    print('📊 [DIRECT] Target document found: ${targetDoc.isNotEmpty ? targetDoc.first.title : 'NOT FOUND'}');
    
    // Call repository delete directly (bypass business service)
    await repository.deleteDocument(documentId);
    
    // Get documents after deletion for debugging
    final afterDocs = await repository.getDocuments();
    print('📊 [DIRECT] Documents after deletion: ${afterDocs.length}');
    final stillExists = afterDocs.where((doc) => doc.id == documentId).toList();
    print('📊 [DIRECT] Document still exists after deletion: ${stillExists.isNotEmpty}');
    
    // Invalidate related providers to refresh UI
    ref.invalidate(contextDocumentsProvider);
    ref.invalidate(contextDocumentsByTypeProvider);
    ref.invalidate(searchContextDocumentsProvider);
    ref.invalidate(contextDocumentsWithVectorProvider); // This is the key missing invalidation!
    ref.invalidate(contextDocumentNotifierProvider);
    ref.invalidate(contextIngestionStatusProvider);
    
    print('✅ [DIRECT] Document deletion completed successfully');
  } catch (e, stackTrace) {
    print('❌ [DIRECT] Document deletion failed: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
});

/// Provider for deleting a context assignment
final deleteContextAssignmentProvider = FutureProvider.family<void, String>((ref, assignmentId) async {
  final repository = ref.read(contextRepositoryProvider);
  await repository.removeAssignment(assignmentId);
  
  // Invalidate related providers to refresh UI
  ref.invalidate(contextAssignmentsProvider);
  ref.invalidate(contextAssignmentsForAgentProvider);
  ref.invalidate(contextForAgentProvider);
});

/// Action provider for deleting context documents (for UI actions)
final deleteContextDocumentActionProvider = Provider.autoDispose((ref) {
  return (String documentId) async {
    try {
      print('🎯 Action provider called for document: $documentId');
      await ref.read(deleteContextDocumentProvider(documentId).future);
      print('🎯 Action provider completed successfully');
    } catch (e) {
      print('🎯 Action provider error: $e');
      rethrow;
    }
  };
});

/// Action provider for removing context from session
final removeSessionContextProvider = StateProvider.family<Function(String), String?>((ref, conversationId) {
  return (String contextId) {
    // This will be used to remove context from the current session
    final sessionContext = ref.read(sessionContextProvider(conversationId));
    final updatedContext = sessionContext.where((id) => id != contextId).toList();
    ref.read(sessionContextProvider(conversationId).notifier).state = updatedContext;
  };
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