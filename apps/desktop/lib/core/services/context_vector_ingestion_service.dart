import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../vector/database/vector_database.dart';
import '../vector/models/vector_models.dart';
import '../../features/context/data/models/context_document.dart';
import '../../features/context/data/repositories/context_repository.dart';
import 'vector_database_service.dart';

/// Production service for ingesting context documents into vector database
class ContextVectorIngestionService {
  final VectorDatabase _vectorDB;
  final ContextRepository _contextRepository;
  
  // Track ingestion jobs to prevent duplicates
  final Map<String, Future<void>> _activeIngestions = {};
  
  ContextVectorIngestionService({
    required VectorDatabase vectorDatabase,
    required ContextRepository contextRepository,
  }) : _vectorDB = vectorDatabase, _contextRepository = contextRepository;

  /// Ingest a single context document into vector database
  Future<void> ingestContextDocument(ContextDocument contextDoc) async {
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
      print('📚 Ingesting context document: ${contextDoc.title}');
      
      // Create vector document from context document
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

      // Add to vector database (will chunk and embed automatically)
      await _vectorDB.addDocument(vectorDoc);
      
      print('✅ Successfully ingested: ${contextDoc.title}');
      
    } catch (e) {
      print('❌ Failed to ingest context document ${contextDoc.title}: $e');
      rethrow;
    }
  }

  /// Batch ingest multiple context documents
  Future<void> ingestMultipleDocuments(List<ContextDocument> documents) async {
    print('📚 Starting batch ingestion of ${documents.length} documents');
    
    final futures = documents.map((doc) => ingestContextDocument(doc));
    
    try {
      await Future.wait(futures);
      print('✅ Batch ingestion completed successfully');
    } catch (e) {
      print('❌ Batch ingestion failed: $e');
      rethrow;
    }
  }

  /// Ingest all context documents for a specific agent
  Future<void> ingestAgentContextDocuments(String agentId) async {
    try {
      final contextDocs = await _contextRepository.getContextForAgent(agentId);
      
      if (contextDocs.isEmpty) {
        print('ℹ️ No context documents found for agent: $agentId');
        return;
      }
      
      await ingestMultipleDocuments(contextDocs);
      
    } catch (e) {
      print('❌ Failed to ingest agent context documents: $e');
      rethrow;
    }
  }

  /// Ingest all active context documents
  Future<void> ingestAllActiveDocuments() async {
    try {
      final allContextDocs = await _contextRepository.getDocuments();
      final activeDocuments = allContextDocs.where((doc) => doc.isActive).toList();
      
      if (activeDocuments.isEmpty) {
        print('ℹ️ No active context documents found');
        return;
      }
      
      await ingestMultipleDocuments(activeDocuments);
      
    } catch (e) {
      print('❌ Failed to ingest all active documents: $e');
      rethrow;
    }
  }

  /// Remove a context document from vector database
  Future<void> removeContextDocument(String contextDocumentId) async {
    try {
      final docId = 'context_$contextDocumentId';
      await _vectorDB.removeDocument(docId);
      print('🗑️ Removed context document from vector DB: $contextDocumentId');
    } catch (e) {
      print('❌ Failed to remove context document: $e');
      rethrow;
    }
  }

  /// Update a context document in vector database
  Future<void> updateContextDocument(ContextDocument contextDoc) async {
    try {
      // Remove old version first
      await removeContextDocument(contextDoc.id);
      
      // Re-ingest updated version
      await ingestContextDocument(contextDoc);
      
    } catch (e) {
      print('❌ Failed to update context document: $e');
      rethrow;
    }
  }

  /// Sync all context documents with vector database
  Future<void> syncAllDocuments() async {
    try {
      print('🔄 Starting full sync of context documents with vector database');
      
      // Get all documents from both sources
      final contextDocs = await _contextRepository.getDocuments();
      final vectorDocs = await _vectorDB.listDocuments();
      
      // Find context documents to add/update
      final contextDocIds = contextDocs.map((doc) => 'context_${doc.id}').toSet();
      final vectorDocIds = vectorDocs.map((doc) => doc.id).toSet();
      
      // Documents to add/update
      final docsToProcess = contextDocs.where((doc) => doc.isActive).toList();
      
      // Documents to remove (in vector but not in active context)
      final docsToRemove = vectorDocs
          .where((vDoc) => vDoc.source == 'context_library' && 
                 !contextDocIds.contains(vDoc.id))
          .toList();
      
      // Remove outdated documents
      for (final docToRemove in docsToRemove) {
        await _vectorDB.removeDocument(docToRemove.id);
      }
      
      // Process active documents
      await ingestMultipleDocuments(docsToProcess);
      
      print('✅ Full sync completed');
      
    } catch (e) {
      print('❌ Failed to sync documents: $e');
      rethrow;
    }
  }

  /// Get ingestion statistics
  Future<Map<String, dynamic>> getIngestionStats() async {
    try {
      final stats = await _vectorDB.getStats();
      final contextDocs = await _vectorDB.listDocuments(
        filter: {'source': 'context_library'}
      );
      
      return {
        'total_vector_documents': stats.totalDocuments,
        'context_documents_ingested': contextDocs.length,
        'total_chunks': stats.totalChunks,
        'active_ingestions': _activeIngestions.length,
        'last_updated': stats.lastUpdated.toIso8601String(),
      };
      
    } catch (e) {
      print('❌ Failed to get ingestion stats: $e');
      return {
        'error': e.toString(),
        'active_ingestions': _activeIngestions.length,
      };
    }
  }

  /// Convert context type to content type
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

  /// Check if document is currently being ingested
  bool isIngesting(String contextDocumentId) {
    return _activeIngestions.containsKey('context_$contextDocumentId');
  }

  /// Wait for all active ingestions to complete
  Future<void> waitForIngestions() async {
    if (_activeIngestions.isNotEmpty) {
      await Future.wait(_activeIngestions.values);
    }
  }

  /// Dispose and cleanup
  Future<void> dispose() async {
    await waitForIngestions();
    _activeIngestions.clear();
  }
}

/// Riverpod provider for context vector ingestion service  
final contextVectorIngestionServiceProvider = Provider<ContextVectorIngestionService?>((ref) {
  final vectorDBAsync = ref.watch(vectorDatabaseProvider);
  final contextRepo = ref.read(contextRepositoryProvider);
  
  return vectorDBAsync.when(
    data: (vectorDB) => ContextVectorIngestionService(
      vectorDatabase: vectorDB,
      contextRepository: contextRepo,
    ),
    loading: () => null, // Return null while loading instead of crashing
    error: (error, stack) {
      print('⚠️ Vector database initialization failed: $error');
      return null; // Return null on error instead of crashing
    },
  );
});