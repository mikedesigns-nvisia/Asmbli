import 'dart:async';
import '../../../features/context/data/models/context_document.dart';
import '../../../features/context/data/repositories/context_repository.dart';
import '../context_vector_ingestion_service.dart';
import 'base_business_service.dart';

/// Business service for context operations - abstracts vector integration from UI
class ContextBusinessService extends BaseBusinessService {
  final ContextRepository _repository;
  final ContextVectorIngestionService? _vectorService;
  
  ContextBusinessService({
    required ContextRepository repository,
    ContextVectorIngestionService? vectorService,
  }) : _repository = repository, _vectorService = vectorService;

  /// Get all context documents
  Future<BusinessResult<List<ContextDocument>>> getDocuments() async {
    try {
      final documents = await _repository.getDocuments();
      
      // Trigger background vector sync if available
      if (_vectorService != null) {
        _backgroundSync();
      }
      
      return BusinessResult.success(documents);
    } catch (e) {
      return BusinessResult.failure('Failed to load context documents: $e');
    }
  }

  /// Search documents by query
  Future<BusinessResult<List<ContextDocument>>> searchDocuments(String query) async {
    try {
      final documents = await _repository.searchDocuments(query);
      return BusinessResult.success(documents);
    } catch (e) {
      return BusinessResult.failure('Search failed: $e');
    }
  }

  /// Create new context document
  Future<BusinessResult<ContextDocument>> createDocument({
    required String title,
    required String content,
    required ContextType type,
    List<String> tags = const [],
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      // Validate input
      if (title.trim().isEmpty) {
        return BusinessResult.failure('Title cannot be empty');
      }
      if (content.trim().isEmpty) {
        return BusinessResult.failure('Content cannot be empty');
      }

      // Create document through repository
      final document = await _repository.createDocument(
        title: title.trim(),
        content: content.trim(),
        type: type,
        tags: tags,
        metadata: metadata,
      );

      // Add to vector database if available and active
      if (_vectorService != null && document.isActive) {
        try {
          await _vectorService!.ingestContextDocument(document);
        } catch (e) {
          // Vector ingestion failed, but document was created - log warning
          print('⚠️ Vector ingestion failed for new document: $e');
        }
      }

      return BusinessResult.success(document);
    } catch (e) {
      return BusinessResult.failure('Failed to create document: $e');
    }
  }

  /// Update existing context document
  Future<BusinessResult<ContextDocument>> updateDocument(ContextDocument document) async {
    try {
      // Validate input
      if (document.title.trim().isEmpty) {
        return BusinessResult.failure('Title cannot be empty');
      }
      if (document.content.trim().isEmpty) {
        return BusinessResult.failure('Content cannot be empty');
      }

      // Update through repository
      final updatedDocument = await _repository.updateDocument(document);

      // Update vector database if available
      if (_vectorService != null) {
        try {
          if (updatedDocument.isActive) {
            await _vectorService!.updateContextDocument(updatedDocument);
          } else {
            // Remove from vector DB if deactivated
            await _vectorService!.removeContextDocument(updatedDocument.id);
          }
        } catch (e) {
          print('⚠️ Vector update failed: $e');
        }
      }

      return BusinessResult.success(updatedDocument);
    } catch (e) {
      return BusinessResult.failure('Failed to update document: $e');
    }
  }

  /// Delete context document
  Future<BusinessResult<void>> deleteDocument(String documentId) async {
    try {
      // Remove from vector database first if available
      if (_vectorService != null) {
        try {
          await _vectorService!.removeContextDocument(documentId);
        } catch (e) {
          print('⚠️ Vector removal failed: $e');
          // Continue with deletion even if vector removal fails
        }
      }

      // Delete from repository
      await _repository.deleteDocument(documentId);

      return BusinessResult.success(null);
    } catch (e) {
      return BusinessResult.failure('Failed to delete document: $e');
    }
  }

  /// Get documents by type
  Future<BusinessResult<List<ContextDocument>>> getDocumentsByType(ContextType type) async {
    try {
      final documents = await _repository.getDocumentsByType(type);
      return BusinessResult.success(documents);
    } catch (e) {
      return BusinessResult.failure('Failed to get documents by type: $e');
    }
  }

  /// Get context for specific agent
  Future<BusinessResult<List<ContextDocument>>> getContextForAgent(String agentId) async {
    try {
      final documents = await _repository.getContextForAgent(agentId);
      return BusinessResult.success(documents);
    } catch (e) {
      return BusinessResult.failure('Failed to get agent context: $e');
    }
  }

  /// Assign document to agent
  Future<BusinessResult<void>> assignDocumentToAgent({
    required String agentId,
    required String contextDocumentId,
    int priority = 0,
    Map<String, dynamic> settings = const {},
  }) async {
    try {
      await _repository.assignDocumentToAgent(
        agentId: agentId,
        contextDocumentId: contextDocumentId,
        priority: priority,
        settings: settings,
      );

      // Preload context for this agent if vector service is available
      if (_vectorService != null) {
        try {
          await _vectorService!.ingestAgentContextDocuments(agentId);
        } catch (e) {
          print('⚠️ Agent context preload failed: $e');
        }
      }

      return BusinessResult.success(null);
    } catch (e) {
      return BusinessResult.failure('Failed to assign document to agent: $e');
    }
  }

  /// Force sync all documents with vector database (admin operation)
  Future<BusinessResult<void>> syncWithVectorDatabase() async {
    if (_vectorService == null) {
      return BusinessResult.failure('Vector service not available');
    }

    try {
      await _vectorService!.syncAllDocuments();
      return BusinessResult.success(null);
    } catch (e) {
      return BusinessResult.failure('Vector sync failed: $e');
    }
  }

  /// Get system status including vector integration
  Future<BusinessResult<Map<String, dynamic>>> getSystemStatus() async {
    try {
      final documents = await _repository.getDocuments();
      final activeCount = documents.where((doc) => doc.isActive).length;
      
      final status = {
        'total_documents': documents.length,
        'active_documents': activeCount,
        'vector_enabled': _vectorService != null,
      };

      if (_vectorService != null) {
        try {
          final vectorStats = await _vectorService!.getIngestionStats();
          status['vector_stats'] = vectorStats;
        } catch (e) {
          status['vector_error'] = e.toString();
        }
      }

      return BusinessResult.success(status);
    } catch (e) {
      return BusinessResult.failure('Failed to get system status: $e');
    }
  }

  /// Background sync with vector database (non-blocking)
  void _backgroundSync() {
    if (_vectorService == null) return;

    // Run in microtask to avoid blocking
    Future.microtask(() async {
      try {
        final documents = await _repository.getDocuments();
        final activeDocuments = documents.where((doc) => doc.isActive).toList();
        
        // Only sync if we have documents
        if (activeDocuments.isNotEmpty) {
          await _vectorService!.ingestMultipleDocuments(activeDocuments);
        }
      } catch (e) {
        print('⚠️ Background vector sync failed: $e');
      }
    });
  }
}

/// Factory for creating context business service with proper dependencies
class ContextBusinessServiceFactory {
  static Future<ContextBusinessService> create({
    required ContextRepository repository,
    ContextVectorIngestionService? vectorService,
  }) async {
    return ContextBusinessService(
      repository: repository,
      vectorService: vectorService,
    );
  }
}