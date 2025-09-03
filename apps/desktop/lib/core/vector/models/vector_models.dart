/// Core models for vector database operations
library;

/// Represents a document to be indexed in the vector database
class VectorDocument {
  final String id;
  final String title;
  final String content;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? source;
  final String contentType;

  const VectorDocument({
    required this.id,
    required this.title,
    required this.content,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
    this.source,
    this.contentType = 'text/plain',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'source': source,
      'contentType': contentType,
    };
  }

  factory VectorDocument.fromJson(Map<String, dynamic> json) {
    return VectorDocument(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      source: json['source'],
      contentType: json['contentType'] ?? 'text/plain',
    );
  }

  VectorDocument copyWith({
    String? id,
    String? title,
    String? content,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? source,
    String? contentType,
  }) {
    return VectorDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source ?? this.source,
      contentType: contentType ?? this.contentType,
    );
  }
}

/// Represents a chunk of text from a document
class VectorChunk {
  final String id;
  final String documentId;
  final String text;
  final int chunkIndex;
  final int totalChunks;
  final Map<String, dynamic> metadata;
  final int startChar;
  final int endChar;
  final List<double>? embedding;

  const VectorChunk({
    required this.id,
    required this.documentId,
    required this.text,
    required this.chunkIndex,
    required this.totalChunks,
    this.metadata = const {},
    required this.startChar,
    required this.endChar,
    this.embedding,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentId': documentId,
      'text': text,
      'chunkIndex': chunkIndex,
      'totalChunks': totalChunks,
      'metadata': metadata,
      'startChar': startChar,
      'endChar': endChar,
      'embedding': embedding,
    };
  }

  factory VectorChunk.fromJson(Map<String, dynamic> json) {
    return VectorChunk(
      id: json['id'],
      documentId: json['documentId'],
      text: json['text'],
      chunkIndex: json['chunkIndex'],
      totalChunks: json['totalChunks'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      startChar: json['startChar'],
      endChar: json['endChar'],
      embedding: json['embedding'] != null 
          ? List<double>.from(json['embedding'])
          : null,
    );
  }

  VectorChunk copyWith({
    String? id,
    String? documentId,
    String? text,
    int? chunkIndex,
    int? totalChunks,
    Map<String, dynamic>? metadata,
    int? startChar,
    int? endChar,
    List<double>? embedding,
  }) {
    return VectorChunk(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      text: text ?? this.text,
      chunkIndex: chunkIndex ?? this.chunkIndex,
      totalChunks: totalChunks ?? this.totalChunks,
      metadata: metadata ?? this.metadata,
      startChar: startChar ?? this.startChar,
      endChar: endChar ?? this.endChar,
      embedding: embedding ?? this.embedding,
    );
  }
}

/// Represents a search result from the vector database
class VectorSearchResult {
  final VectorChunk chunk;
  final double similarity;
  final double? rerankScore;
  final Map<String, dynamic> debugInfo;

  const VectorSearchResult({
    required this.chunk,
    required this.similarity,
    this.rerankScore,
    this.debugInfo = const {},
  });

  /// Get the effective score (rerank score if available, otherwise similarity)
  double get effectiveScore => rerankScore ?? similarity;

  Map<String, dynamic> toJson() {
    return {
      'chunk': chunk.toJson(),
      'similarity': similarity,
      'rerankScore': rerankScore,
      'debugInfo': debugInfo,
    };
  }

  factory VectorSearchResult.fromJson(Map<String, dynamic> json) {
    return VectorSearchResult(
      chunk: VectorChunk.fromJson(json['chunk']),
      similarity: json['similarity'].toDouble(),
      rerankScore: json['rerankScore']?.toDouble(),
      debugInfo: Map<String, dynamic>.from(json['debugInfo'] ?? {}),
    );
  }

  VectorSearchResult copyWith({
    VectorChunk? chunk,
    double? similarity,
    double? rerankScore,
    Map<String, dynamic>? debugInfo,
  }) {
    return VectorSearchResult(
      chunk: chunk ?? this.chunk,
      similarity: similarity ?? this.similarity,
      rerankScore: rerankScore ?? this.rerankScore,
      debugInfo: debugInfo ?? this.debugInfo,
    );
  }
}

/// Search query parameters for vector database
class VectorSearchQuery {
  final String query;
  final int limit;
  final double minSimilarity;
  final Map<String, dynamic>? filter;
  final List<String>? documentIds;
  final bool enableReranking;
  final bool includeMetadata;

  const VectorSearchQuery({
    required this.query,
    this.limit = 10,
    this.minSimilarity = 0.0,
    this.filter,
    this.documentIds,
    this.enableReranking = true,
    this.includeMetadata = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'limit': limit,
      'minSimilarity': minSimilarity,
      'filter': filter,
      'documentIds': documentIds,
      'enableReranking': enableReranking,
      'includeMetadata': includeMetadata,
    };
  }

  factory VectorSearchQuery.fromJson(Map<String, dynamic> json) {
    return VectorSearchQuery(
      query: json['query'],
      limit: json['limit'] ?? 10,
      minSimilarity: json['minSimilarity']?.toDouble() ?? 0.0,
      filter: json['filter'],
      documentIds: json['documentIds']?.cast<String>(),
      enableReranking: json['enableReranking'] ?? true,
      includeMetadata: json['includeMetadata'] ?? true,
    );
  }

  VectorSearchQuery copyWith({
    String? query,
    int? limit,
    double? minSimilarity,
    Map<String, dynamic>? filter,
    List<String>? documentIds,
    bool? enableReranking,
    bool? includeMetadata,
  }) {
    return VectorSearchQuery(
      query: query ?? this.query,
      limit: limit ?? this.limit,
      minSimilarity: minSimilarity ?? this.minSimilarity,
      filter: filter ?? this.filter,
      documentIds: documentIds ?? this.documentIds,
      enableReranking: enableReranking ?? this.enableReranking,
      includeMetadata: includeMetadata ?? this.includeMetadata,
    );
  }
}

/// Configuration for document chunking
class ChunkingConfig {
  final int chunkSize;
  final int chunkOverlap;
  final List<String> separators;
  final bool preserveCodeBlocks;
  final bool preserveTables;
  final int minChunkSize;

  const ChunkingConfig({
    this.chunkSize = 512,
    this.chunkOverlap = 50,
    this.separators = const ['\n\n', '\n', '. ', ' '],
    this.preserveCodeBlocks = true,
    this.preserveTables = true,
    this.minChunkSize = 50,
  });

  Map<String, dynamic> toJson() {
    return {
      'chunkSize': chunkSize,
      'chunkOverlap': chunkOverlap,
      'separators': separators,
      'preserveCodeBlocks': preserveCodeBlocks,
      'preserveTables': preserveTables,
      'minChunkSize': minChunkSize,
    };
  }

  factory ChunkingConfig.fromJson(Map<String, dynamic> json) {
    return ChunkingConfig(
      chunkSize: json['chunkSize'] ?? 512,
      chunkOverlap: json['chunkOverlap'] ?? 50,
      separators: List<String>.from(json['separators'] ?? ['\n\n', '\n', '. ', ' ']),
      preserveCodeBlocks: json['preserveCodeBlocks'] ?? true,
      preserveTables: json['preserveTables'] ?? true,
      minChunkSize: json['minChunkSize'] ?? 50,
    );
  }
}

/// Vector database statistics
class VectorDatabaseStats {
  final int totalDocuments;
  final int totalChunks;
  final int totalEmbeddings;
  final Map<String, int> documentsByType;
  final DateTime lastUpdated;
  final String databaseVersion;
  final Map<String, dynamic> performanceMetrics;

  const VectorDatabaseStats({
    required this.totalDocuments,
    required this.totalChunks,
    required this.totalEmbeddings,
    this.documentsByType = const {},
    required this.lastUpdated,
    required this.databaseVersion,
    this.performanceMetrics = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'totalDocuments': totalDocuments,
      'totalChunks': totalChunks,
      'totalEmbeddings': totalEmbeddings,
      'documentsByType': documentsByType,
      'lastUpdated': lastUpdated.toIso8601String(),
      'databaseVersion': databaseVersion,
      'performanceMetrics': performanceMetrics,
    };
  }

  factory VectorDatabaseStats.fromJson(Map<String, dynamic> json) {
    return VectorDatabaseStats(
      totalDocuments: json['totalDocuments'],
      totalChunks: json['totalChunks'],
      totalEmbeddings: json['totalEmbeddings'],
      documentsByType: Map<String, int>.from(json['documentsByType'] ?? {}),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      databaseVersion: json['databaseVersion'],
      performanceMetrics: Map<String, dynamic>.from(json['performanceMetrics'] ?? {}),
    );
  }
}