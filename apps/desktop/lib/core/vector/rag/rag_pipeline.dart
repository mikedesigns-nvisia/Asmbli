import 'dart:math';
import '../database/vector_database.dart';
import '../models/vector_models.dart';
import '../../services/llm/unified_llm_service.dart';

/// Retrieval-Augmented Generation (RAG) pipeline for contextual AI responses
class RAGPipeline {
  final VectorDatabase _vectorDB;
  final UnifiedLLMService _modelService;
  final RAGConfig _config;

  RAGPipeline({
    required VectorDatabase vectorDatabase,
    required UnifiedLLMService modelService,
    RAGConfig? config,
  }) : _vectorDB = vectorDatabase,
       _modelService = modelService,
       _config = config ?? const RAGConfig();

  /// Generate a response with retrieved context
  Future<RAGResponse> generateWithContext(
    String query, {
    List<String>? documentIds,
    int maxContextTokens = 8000,
    bool includeCitations = true,
    Map<String, dynamic>? metadata,
  }) async {
    print('🤖 Generating RAG response for: "$query"');
    final startTime = DateTime.now();

    try {
      // Step 1: Retrieve relevant context
      final searchResults = await _retrieveContext(
        query,
        documentIds: documentIds,
        maxResults: _config.maxRetrievedChunks,
      );

      if (searchResults.isEmpty) {
        return RAGResponse(
          query: query,
          answer: _config.noContextResponse,
          sources: [],
          metadata: {
            'retrieval_time_ms': 0,
            'generation_time_ms': 0,
            'total_time_ms': DateTime.now().difference(startTime).inMilliseconds,
            'context_chunks_used': 0,
            ...metadata ?? {},
          },
        );
      }

      // Step 2: Build context with intelligent truncation
      final context = await _buildContext(searchResults, maxContextTokens);

      // Step 3: Create the RAG prompt
      final prompt = _buildRAGPrompt(query, context);

      // Step 4: Generate response
      final generationStart = DateTime.now();
      final response = await _modelService.generate(prompt);
      final generationTime = DateTime.now().difference(generationStart);

      // Step 5: Process and enhance the response
      final processedResponse = _processResponse(response, searchResults);

      // Step 6: Add citations if requested
      final finalAnswer = includeCitations
          ? _addCitations(processedResponse, searchResults)
          : processedResponse;

      final totalTime = DateTime.now().difference(startTime);

      return RAGResponse(
        query: query,
        answer: finalAnswer,
        sources: searchResults.map((result) => RAGSource.fromSearchResult(result)).toList(),
        metadata: {
          'retrieval_time_ms': generationStart.difference(startTime).inMilliseconds,
          'generation_time_ms': generationTime.inMilliseconds,
          'total_time_ms': totalTime.inMilliseconds,
          'context_chunks_used': searchResults.length,
          'context_tokens_estimated': _estimateTokens(context),
          'prompt_tokens_estimated': _estimateTokens(prompt),
          'avg_similarity_score': searchResults.isEmpty ? 0 : 
              searchResults.map((r) => r.effectiveScore).reduce((a, b) => a + b) / searchResults.length,
          ...metadata ?? {},
        },
      );

    } catch (e) {
      throw RAGException('Failed to generate RAG response: $e');
    }
  }

  /// Retrieve relevant context for the query
  Future<List<VectorSearchResult>> _retrieveContext(
    String query, {
    List<String>? documentIds,
    int maxResults = 10,
  }) async {
    final searchQuery = VectorSearchQuery(
      query: query,
      limit: maxResults,
      documentIds: documentIds,
      minSimilarity: _config.minSimilarity,
      enableReranking: _config.enableReranking,
      includeMetadata: true,
    );

    return await _vectorDB.search(searchQuery);
  }

  /// Build context string from search results with smart truncation
  Future<String> _buildContext(
    List<VectorSearchResult> results, 
    int maxTokens,
  ) async {
    if (results.isEmpty) return '';

    final contextParts = <String>[];
    int totalTokens = 0;
    int usedChunks = 0;

    // Sort by relevance (effective score)
    results.sort((a, b) => b.effectiveScore.compareTo(a.effectiveScore));

    for (final result in results) {
      final chunk = result.chunk;
      
      // Create context entry with metadata
      final contextEntry = _formatContextEntry(chunk, usedChunks);
      final entryTokens = _estimateTokens(contextEntry);

      // Check if we have room for this entry
      if (totalTokens + entryTokens > maxTokens) {
        if (usedChunks == 0) {
          // If this is the first chunk and it's too big, truncate it
          final truncatedEntry = _truncateContextEntry(contextEntry, maxTokens);
          contextParts.add(truncatedEntry);
          usedChunks++;
        }
        break;
      }

      contextParts.add(contextEntry);
      totalTokens += entryTokens;
      usedChunks++;
    }

    print('📖 Built context from $usedChunks chunks (~$totalTokens tokens)');
    return contextParts.join('\n\n---\n\n');
  }

  /// Format a context entry with metadata
  String _formatContextEntry(VectorChunk chunk, int index) {
    final buffer = StringBuffer();
    
    // Add source information
    final title = chunk.metadata['document_title']?.toString() ?? 'Unknown Document';
    buffer.writeln('Source ${index + 1}: $title');
    
    // Add chunk context if available
    if (chunk.chunkIndex > 0) {
      buffer.writeln('(Part ${chunk.chunkIndex + 1} of ${chunk.totalChunks})');
    }
    
    buffer.writeln();
    buffer.write(chunk.text);
    
    return buffer.toString();
  }

  /// Truncate context entry to fit within token limit
  String _truncateContextEntry(String entry, int maxTokens) {
    final words = entry.split(' ');
    final estimatedWordsPerToken = 0.75; // Rough estimate
    final maxWords = (maxTokens * estimatedWordsPerToken).floor();
    
    if (words.length <= maxWords) return entry;
    
    return '${words.take(maxWords).join(' ')}... [truncated]';
  }

  /// Build the RAG prompt
  String _buildRAGPrompt(String query, String context) {
    if (context.isEmpty) {
      return '''You are a helpful AI assistant. Answer the following question to the best of your ability.

Question: $query

Answer:''';
    }

    return '''${_config.systemPrompt}

Context:
$context

Question: $query

Instructions:
- Use the provided context to answer the question
- If the answer is not in the context, clearly state that you don't have enough information
- Be specific and cite relevant parts of the context when possible
- If the context is contradictory, acknowledge the conflicting information

Answer:''';
  }

  /// Process the raw model response
  String _processResponse(String response, List<VectorSearchResult> sources) {
    // Clean up the response
    String processed = response.trim();
    
    // Remove any repeated instructions or prompts
    processed = _removePromptEchoes(processed);
    
    // Enhance with source-specific information if relevant
    processed = _enhanceWithSourceInfo(processed, sources);
    
    return processed;
  }

  /// Remove prompt echoes from the response
  String _removePromptEchoes(String response) {
    // Remove common prompt echoes
    final patterns = [
      RegExp(r'^(Answer:|Response:|Based on the context:?)\s*', caseSensitive: false),
      RegExp(r'\n+(Answer:|Response:)\s*', caseSensitive: false),
    ];
    
    String cleaned = response;
    for (final pattern in patterns) {
      cleaned = cleaned.replaceAll(pattern, '');
    }
    
    return cleaned.trim();
  }

  /// Enhance response with source-specific information
  String _enhanceWithSourceInfo(String response, List<VectorSearchResult> sources) {
    // This is a placeholder for more sophisticated enhancement
    // In a real implementation, this might:
    // - Add specific details from high-scoring sources
    // - Resolve contradictions between sources
    // - Add temporal context from document metadata
    
    return response;
  }

  /// Add citations to the response
  String _addCitations(String response, List<VectorSearchResult> sources) {
    if (sources.isEmpty) return response;

    final citations = <String>[];
    final seenTitles = <String>{};

    for (int i = 0; i < sources.length; i++) {
      final source = sources[i];
      final title = source.chunk.metadata['document_title']?.toString() ?? 'Unknown Document';
      
      if (!seenTitles.contains(title)) {
        seenTitles.add(title);
        final score = (source.effectiveScore * 100).toStringAsFixed(1);
        citations.add('[$i] $title (relevance: $score%)');
      }
    }

    if (citations.isEmpty) return response;

    return '''$response

**Sources:**
${citations.join('\n')}''';
  }

  /// Estimate token count for text (rough approximation)
  int _estimateTokens(String text) {
    // Rough estimate: 1 token ≈ 4 characters or 0.75 words
    final chars = text.length;
    final words = text.split(RegExp(r'\s+')).length;
    return max((chars / 4).ceil(), (words / 0.75).ceil());
  }

  /// Generate a summary of a document using RAG
  Future<String> generateDocumentSummary(
    String documentId, {
    int maxLength = 200,
    String? focusQuery,
  }) async {
    try {
      final document = await _vectorDB.getDocument(documentId);
      if (document == null) {
        throw RAGException('Document not found: $documentId');
      }

      final query = focusQuery ?? 'Summarize the main points and key information from this document';
      
      final response = await generateWithContext(
        query,
        documentIds: [documentId],
        maxContextTokens: 4000,
        includeCitations: false,
      );

      return response.answer;

    } catch (e) {
      throw RAGException('Failed to generate document summary: $e');
    }
  }

  /// Find related information across documents
  Future<RAGResponse> findRelatedInformation(
    String topic, {
    int maxSources = 5,
    double minSimilarity = 0.3,
  }) async {
    try {
      final query = 'Find information related to: $topic';
      
      final response = await generateWithContext(
        query,
        maxContextTokens: 6000,
        includeCitations: true,
        metadata: {'operation': 'find_related', 'topic': topic},
      );

      return response;

    } catch (e) {
      throw RAGException('Failed to find related information: $e');
    }
  }

  /// Answer a question with explanatory context
  Future<RAGResponse> explainConcept(
    String concept, {
    List<String>? documentIds,
    bool includeExamples = true,
  }) async {
    try {
      final query = includeExamples
          ? 'Explain the concept of "$concept" with examples and details'
          : 'Explain the concept of "$concept"';
      
      final response = await generateWithContext(
        query,
        documentIds: documentIds,
        maxContextTokens: 10000,
        includeCitations: true,
        metadata: {'operation': 'explain_concept', 'concept': concept},
      );

      return response;

    } catch (e) {
      throw RAGException('Failed to explain concept: $e');
    }
  }
}

/// Configuration for RAG pipeline
class RAGConfig {
  final String systemPrompt;
  final int maxRetrievedChunks;
  final double minSimilarity;
  final bool enableReranking;
  final String noContextResponse;

  const RAGConfig({
    this.systemPrompt = 'You are a helpful AI assistant that answers questions based on provided context.',
    this.maxRetrievedChunks = 10,
    this.minSimilarity = 0.1,
    this.enableReranking = true,
    this.noContextResponse = "I don't have enough information to answer that question based on the available context.",
  });

  Map<String, dynamic> toJson() {
    return {
      'systemPrompt': systemPrompt,
      'maxRetrievedChunks': maxRetrievedChunks,
      'minSimilarity': minSimilarity,
      'enableReranking': enableReranking,
      'noContextResponse': noContextResponse,
    };
  }

  factory RAGConfig.fromJson(Map<String, dynamic> json) {
    return RAGConfig(
      systemPrompt: json['systemPrompt'] ?? 'You are a helpful AI assistant that answers questions based on provided context.',
      maxRetrievedChunks: json['maxRetrievedChunks'] ?? 10,
      minSimilarity: json['minSimilarity']?.toDouble() ?? 0.1,
      enableReranking: json['enableReranking'] ?? true,
      noContextResponse: json['noContextResponse'] ?? "I don't have enough information to answer that question based on the available context.",
    );
  }
}

/// RAG response with metadata
class RAGResponse {
  final String query;
  final String answer;
  final List<RAGSource> sources;
  final Map<String, dynamic> metadata;

  const RAGResponse({
    required this.query,
    required this.answer,
    required this.sources,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'answer': answer,
      'sources': sources.map((s) => s.toJson()).toList(),
      'metadata': metadata,
    };
  }

  factory RAGResponse.fromJson(Map<String, dynamic> json) {
    return RAGResponse(
      query: json['query'],
      answer: json['answer'],
      sources: (json['sources'] as List).map((s) => RAGSource.fromJson(s)).toList(),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

/// Source information for RAG responses
class RAGSource {
  final String documentId;
  final String documentTitle;
  final String chunkText;
  final double relevanceScore;
  final int chunkIndex;
  final Map<String, dynamic> metadata;

  const RAGSource({
    required this.documentId,
    required this.documentTitle,
    required this.chunkText,
    required this.relevanceScore,
    required this.chunkIndex,
    this.metadata = const {},
  });

  factory RAGSource.fromSearchResult(VectorSearchResult result) {
    return RAGSource(
      documentId: result.chunk.documentId,
      documentTitle: result.chunk.metadata['document_title']?.toString() ?? 'Unknown',
      chunkText: result.chunk.text,
      relevanceScore: result.effectiveScore,
      chunkIndex: result.chunk.chunkIndex,
      metadata: result.chunk.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'documentTitle': documentTitle,
      'chunkText': chunkText,
      'relevanceScore': relevanceScore,
      'chunkIndex': chunkIndex,
      'metadata': metadata,
    };
  }

  factory RAGSource.fromJson(Map<String, dynamic> json) {
    return RAGSource(
      documentId: json['documentId'],
      documentTitle: json['documentTitle'],
      chunkText: json['chunkText'],
      relevanceScore: json['relevanceScore'].toDouble(),
      chunkIndex: json['chunkIndex'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

/// Exception for RAG operations
class RAGException implements Exception {
  final String message;
  final dynamic originalError;

  const RAGException(this.message, [this.originalError]);

  @override
  String toString() {
    final buffer = StringBuffer('RAGException: $message');
    if (originalError != null) {
      buffer.write(' (caused by: $originalError)');
    }
    return buffer.toString();
  }
}