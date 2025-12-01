/// DSPy-Powered RAG Service
///
/// This replaces:
/// - RAGPipeline
/// - VectorContextRetrievalService
/// - StreamlinedVectorContextService
/// - ContextVectorIngestionService
/// - VectorIntegrationService
/// - VectorDatabaseService
///
/// All vector operations and RAG now go through DSPy backend.
/// Flutter only handles document metadata and UI.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dspy_service.dart';
import 'dspy_client.dart';

/// Document metadata stored locally
class DocumentMetadata {
  final String id;
  final String title;
  final String? description;
  final DateTime uploadedAt;
  final int chunkCount;
  final Map<String, dynamic> tags;

  DocumentMetadata({
    required this.id,
    required this.title,
    this.description,
    required this.uploadedAt,
    required this.chunkCount,
    this.tags = const {},
  });

  factory DocumentMetadata.fromUploadResponse(DspyDocumentResponse response) {
    return DocumentMetadata(
      id: response.documentId,
      title: response.title,
      uploadedAt: DateTime.now(),
      chunkCount: response.chunksCreated,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'uploadedAt': uploadedAt.toIso8601String(),
    'chunkCount': chunkCount,
    'tags': tags,
  };

  factory DocumentMetadata.fromJson(Map<String, dynamic> json) {
    return DocumentMetadata(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      chunkCount: json['chunkCount'] as int,
      tags: (json['tags'] as Map<String, dynamic>?) ?? {},
    );
  }
}

/// RAG query result
class RagQueryResult {
  final String answer;
  final double confidence;
  final List<RagSource> sources;
  final int passagesUsed;
  final Duration queryTime;

  RagQueryResult({
    required this.answer,
    required this.confidence,
    required this.sources,
    required this.passagesUsed,
    required this.queryTime,
  });
}

/// Source from RAG query
class RagSource {
  final String documentId;
  final String title;
  final String excerpt;
  final double relevanceScore;

  RagSource({
    required this.documentId,
    required this.title,
    required this.excerpt,
    required this.relevanceScore,
  });

  factory RagSource.fromDspy(DspyRagSource source) {
    return RagSource(
      documentId: source.documentId,
      title: source.title,
      excerpt: source.excerpt,
      relevanceScore: source.relevanceScore,
    );
  }
}

/// Simplified RAG service that delegates to DSPy
///
/// Usage:
/// ```dart
/// final rag = ref.watch(dspyRagServiceProvider);
///
/// // Upload a document
/// await rag.uploadDocument(
///   title: 'Flutter Guide',
///   content: 'Flutter is a UI toolkit...',
/// );
///
/// // Query
/// final result = await rag.query('How do I build a Flutter app?');
/// print(result.answer);
/// print(result.sources);
/// ```
class DspyRagService {
  final DspyService _dspy;

  // Local cache of document metadata
  final Map<String, DocumentMetadata> _documents = {};

  DspyRagService({required DspyService dspy}) : _dspy = dspy;

  // ============== Document Management ==============

  /// Upload a document for RAG
  Future<DocumentMetadata> uploadDocument({
    required String title,
    required String content,
    String? description,
    Map<String, dynamic>? tags,
  }) async {
    final response = await _dspy.uploadDocument(
      title,
      content,
      metadata: {
        if (description != null) 'description': description,
        if (tags != null) ...tags,
      },
    );

    final metadata = DocumentMetadata(
      id: response.documentId,
      title: response.title,
      description: description,
      uploadedAt: DateTime.now(),
      chunkCount: response.chunksCreated,
      tags: tags ?? {},
    );

    _documents[metadata.id] = metadata;
    return metadata;
  }

  /// Upload a file (reads content and uploads)
  Future<DocumentMetadata> uploadFile({
    required String title,
    required String filePath,
    String? description,
  }) async {
    // In production, read the file content here
    // For now, this is a placeholder
    throw UnimplementedError('File upload not implemented - use uploadDocument with content');
  }

  /// List all documents
  Future<List<DocumentMetadata>> listDocuments() async {
    // Refresh from backend
    final backendDocs = await _dspy.listDocuments();

    _documents.clear();
    for (final doc in backendDocs) {
      final metadata = DocumentMetadata(
        id: doc['document_id'] as String,
        title: doc['title'] as String,
        uploadedAt: DateTime.now(), // Backend doesn't store this
        chunkCount: doc['chunk_count'] as int? ?? 0,
      );
      _documents[metadata.id] = metadata;
    }

    return _documents.values.toList();
  }

  /// Get document by ID
  DocumentMetadata? getDocument(String id) => _documents[id];

  /// Delete a document
  Future<void> deleteDocument(String documentId) async {
    await _dspy.deleteDocument(documentId);
    _documents.remove(documentId);
  }

  /// Clear all documents
  Future<void> clearAllDocuments() async {
    final docs = await listDocuments();
    for (final doc in docs) {
      await deleteDocument(doc.id);
    }
  }

  // ============== RAG Queries ==============

  /// Query documents and get an answer
  Future<RagQueryResult> query(
    String question, {
    List<String>? documentIds,
    int numPassages = 5,
    bool includeCitations = true,
  }) async {
    final startTime = DateTime.now();

    final response = await _dspy.queryDocuments(
      question,
      documentIds: documentIds,
      numPassages: numPassages,
      includeCitations: includeCitations,
    );

    return RagQueryResult(
      answer: response.answer,
      confidence: response.confidence,
      sources: response.sources.map((s) => RagSource.fromDspy(s)).toList(),
      passagesUsed: response.passagesUsed,
      queryTime: DateTime.now().difference(startTime),
    );
  }

  /// Ask a question about a specific document
  Future<RagQueryResult> askDocument(String documentId, String question) async {
    return query(question, documentIds: [documentId]);
  }

  /// Summarize a document
  Future<String> summarizeDocument(String documentId) async {
    final result = await query(
      'Provide a comprehensive summary of this document, including the main topics and key points.',
      documentIds: [documentId],
    );
    return result.answer;
  }

  /// Find related information across all documents
  Future<RagQueryResult> findRelated(String topic) async {
    return query('Find all information related to: $topic');
  }

  /// Compare information across documents
  Future<RagQueryResult> compare(
    String topic,
    List<String> documentIds,
  ) async {
    return query(
      'Compare and contrast what these documents say about: $topic',
      documentIds: documentIds,
    );
  }

  // ============== Convenience Methods ==============

  /// Quick Q&A - upload temp doc, query, delete
  Future<String> quickAnswer(String content, String question) async {
    // Upload temp doc
    final doc = await uploadDocument(
      title: 'Temp Query Doc',
      content: content,
    );

    try {
      // Query
      final result = await askDocument(doc.id, question);
      return result.answer;
    } finally {
      // Cleanup
      await deleteDocument(doc.id);
    }
  }

  /// Check if any documents are indexed
  Future<bool> hasDocuments() async {
    final docs = await listDocuments();
    return docs.isNotEmpty;
  }

  /// Get document count
  Future<int> documentCount() async {
    final docs = await listDocuments();
    return docs.length;
  }
}

// ============== Riverpod Providers ==============

/// Provider for DSPy RAG service
final dspyRagServiceProvider = Provider<DspyRagService>((ref) {
  final dspy = ref.watch(dspyServiceProvider);
  return DspyRagService(dspy: dspy);
});

/// Provider for document list
final ragDocumentsProvider = FutureProvider<List<DocumentMetadata>>((ref) async {
  final rag = ref.watch(dspyRagServiceProvider);
  return rag.listDocuments();
});

/// Provider for document count
final ragDocumentCountProvider = FutureProvider<int>((ref) async {
  final rag = ref.watch(dspyRagServiceProvider);
  return rag.documentCount();
});

/// State provider for RAG query results
final ragQueryResultProvider = StateProvider<RagQueryResult?>((ref) => null);

/// Notifier for RAG operations
class RagNotifier extends StateNotifier<RagState> {
  final DspyRagService _ragService;

  RagNotifier(this._ragService) : super(const RagState());

  Future<RagQueryResult> query(String question, {List<String>? documentIds}) async {
    state = state.copyWith(isQuerying: true, error: null);

    try {
      final result = await _ragService.query(question, documentIds: documentIds);
      state = state.copyWith(
        isQuerying: false,
        lastResult: result,
      );
      return result;
    } catch (e) {
      state = state.copyWith(
        isQuerying: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<DocumentMetadata> uploadDocument(String title, String content) async {
    state = state.copyWith(isUploading: true, error: null);

    try {
      final doc = await _ragService.uploadDocument(title: title, content: content);
      state = state.copyWith(isUploading: false);
      return doc;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  void reset() {
    state = const RagState();
  }
}

/// State for RAG operations
class RagState {
  final bool isQuerying;
  final bool isUploading;
  final RagQueryResult? lastResult;
  final String? error;

  const RagState({
    this.isQuerying = false,
    this.isUploading = false,
    this.lastResult,
    this.error,
  });

  RagState copyWith({
    bool? isQuerying,
    bool? isUploading,
    RagQueryResult? lastResult,
    String? error,
  }) {
    return RagState(
      isQuerying: isQuerying ?? this.isQuerying,
      isUploading: isUploading ?? this.isUploading,
      lastResult: lastResult ?? this.lastResult,
      error: error,
    );
  }
}

/// Provider for RAG notifier
final ragNotifierProvider = StateNotifierProvider<RagNotifier, RagState>((ref) {
  final ragService = ref.watch(dspyRagServiceProvider);
  return RagNotifier(ragService);
});
