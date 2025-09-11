/// Simplified unified configuration for vector/context system
/// Replaces multiple configuration classes with a single, streamlined config
class VectorConfig {
  // Database configuration
  final String? databasePath;
  final bool enableInMemoryMode;
  
  // Chunking configuration (simplified from ChunkingConfig)
  final int chunkSize;
  final int chunkOverlap;
  final List<String> separators;
  final bool preserveCodeBlocks;
  final bool preserveTables;
  final int minChunkSize;
  
  // RAG configuration (simplified from RAGConfig)
  final String systemPrompt;
  final int maxRetrievedChunks;
  final double minSimilarity;
  final bool enableReranking;
  final String noContextResponse;
  
  // Caching configuration
  final int maxCacheEntries;
  final Duration cacheExpiry;
  
  // Performance configuration
  final int batchSize;
  final Duration syncInterval;
  final Duration initTimeout;
  
  const VectorConfig({
    // Database
    this.databasePath,
    this.enableInMemoryMode = false,
    
    // Chunking
    this.chunkSize = 1024,
    this.chunkOverlap = 100,
    this.separators = const ['\n\n', '\n', '. ', '! ', '? ', ' '],
    this.preserveCodeBlocks = true,
    this.preserveTables = true,
    this.minChunkSize = 100,
    
    // RAG
    this.systemPrompt = 'You are a helpful AI assistant that answers questions based on provided context.',
    this.maxRetrievedChunks = 8,
    this.minSimilarity = 0.3,
    this.enableReranking = true,
    this.noContextResponse = "I don't have enough information to answer that question based on the available context.",
    
    // Caching
    this.maxCacheEntries = 50,
    this.cacheExpiry = const Duration(minutes: 5),
    
    // Performance
    this.batchSize = 5,
    this.syncInterval = const Duration(minutes: 5),
    this.initTimeout = const Duration(seconds: 30),
  });

  /// Development configuration - optimized for local development
  factory VectorConfig.development() {
    return VectorConfig(
      chunkSize: 512,
      maxRetrievedChunks: 5,
      maxCacheEntries: 25,
      batchSize: 3,
      syncInterval: const Duration(minutes: 10),
    );
  }

  /// Production configuration - optimized for production use
  factory VectorConfig.production() {
    return VectorConfig(
      chunkSize: 1024,
      maxRetrievedChunks: 10,
      maxCacheEntries: 100,
      batchSize: 10,
      syncInterval: const Duration(minutes: 3),
    );
  }

  /// Testing configuration - minimal resources for testing
  factory VectorConfig.testing() {
    return VectorConfig(
      enableInMemoryMode: true,
      chunkSize: 256,
      maxRetrievedChunks: 3,
      maxCacheEntries: 10,
      batchSize: 1,
      syncInterval: const Duration(seconds: 10),
      initTimeout: const Duration(seconds: 5),
    );
  }

  /// Copy with method for customizing configuration
  VectorConfig copyWith({
    String? databasePath,
    bool? enableInMemoryMode,
    int? chunkSize,
    int? chunkOverlap,
    List<String>? separators,
    bool? preserveCodeBlocks,
    bool? preserveTables,
    int? minChunkSize,
    String? systemPrompt,
    int? maxRetrievedChunks,
    double? minSimilarity,
    bool? enableReranking,
    String? noContextResponse,
    int? maxCacheEntries,
    Duration? cacheExpiry,
    int? batchSize,
    Duration? syncInterval,
    Duration? initTimeout,
  }) {
    return VectorConfig(
      databasePath: databasePath ?? this.databasePath,
      enableInMemoryMode: enableInMemoryMode ?? this.enableInMemoryMode,
      chunkSize: chunkSize ?? this.chunkSize,
      chunkOverlap: chunkOverlap ?? this.chunkOverlap,
      separators: separators ?? this.separators,
      preserveCodeBlocks: preserveCodeBlocks ?? this.preserveCodeBlocks,
      preserveTables: preserveTables ?? this.preserveTables,
      minChunkSize: minChunkSize ?? this.minChunkSize,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      maxRetrievedChunks: maxRetrievedChunks ?? this.maxRetrievedChunks,
      minSimilarity: minSimilarity ?? this.minSimilarity,
      enableReranking: enableReranking ?? this.enableReranking,
      noContextResponse: noContextResponse ?? this.noContextResponse,
      maxCacheEntries: maxCacheEntries ?? this.maxCacheEntries,
      cacheExpiry: cacheExpiry ?? this.cacheExpiry,
      batchSize: batchSize ?? this.batchSize,
      syncInterval: syncInterval ?? this.syncInterval,
      initTimeout: initTimeout ?? this.initTimeout,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'databasePath': databasePath,
      'enableInMemoryMode': enableInMemoryMode,
      'chunkSize': chunkSize,
      'chunkOverlap': chunkOverlap,
      'separators': separators,
      'preserveCodeBlocks': preserveCodeBlocks,
      'preserveTables': preserveTables,
      'minChunkSize': minChunkSize,
      'systemPrompt': systemPrompt,
      'maxRetrievedChunks': maxRetrievedChunks,
      'minSimilarity': minSimilarity,
      'enableReranking': enableReranking,
      'noContextResponse': noContextResponse,
      'maxCacheEntries': maxCacheEntries,
      'cacheExpiry': cacheExpiry.inMilliseconds,
      'batchSize': batchSize,
      'syncInterval': syncInterval.inMilliseconds,
      'initTimeout': initTimeout.inMilliseconds,
    };
  }

  /// Create from JSON
  factory VectorConfig.fromJson(Map<String, dynamic> json) {
    return VectorConfig(
      databasePath: json['databasePath'],
      enableInMemoryMode: json['enableInMemoryMode'] ?? false,
      chunkSize: json['chunkSize'] ?? 1024,
      chunkOverlap: json['chunkOverlap'] ?? 100,
      separators: List<String>.from(json['separators'] ?? ['\n\n', '\n', '. ', '! ', '? ', ' ']),
      preserveCodeBlocks: json['preserveCodeBlocks'] ?? true,
      preserveTables: json['preserveTables'] ?? true,
      minChunkSize: json['minChunkSize'] ?? 100,
      systemPrompt: json['systemPrompt'] ?? 'You are a helpful AI assistant that answers questions based on provided context.',
      maxRetrievedChunks: json['maxRetrievedChunks'] ?? 8,
      minSimilarity: json['minSimilarity']?.toDouble() ?? 0.3,
      enableReranking: json['enableReranking'] ?? true,
      noContextResponse: json['noContextResponse'] ?? "I don't have enough information to answer that question based on the available context.",
      maxCacheEntries: json['maxCacheEntries'] ?? 50,
      cacheExpiry: Duration(milliseconds: json['cacheExpiry'] ?? 300000), // 5 minutes
      batchSize: json['batchSize'] ?? 5,
      syncInterval: Duration(milliseconds: json['syncInterval'] ?? 300000), // 5 minutes
      initTimeout: Duration(milliseconds: json['initTimeout'] ?? 30000), // 30 seconds
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VectorConfig &&
           other.databasePath == databasePath &&
           other.enableInMemoryMode == enableInMemoryMode &&
           other.chunkSize == chunkSize &&
           other.chunkOverlap == chunkOverlap &&
           other.separators == separators &&
           other.preserveCodeBlocks == preserveCodeBlocks &&
           other.preserveTables == preserveTables &&
           other.minChunkSize == minChunkSize &&
           other.systemPrompt == systemPrompt &&
           other.maxRetrievedChunks == maxRetrievedChunks &&
           other.minSimilarity == minSimilarity &&
           other.enableReranking == enableReranking &&
           other.noContextResponse == noContextResponse &&
           other.maxCacheEntries == maxCacheEntries &&
           other.cacheExpiry == cacheExpiry &&
           other.batchSize == batchSize &&
           other.syncInterval == syncInterval &&
           other.initTimeout == initTimeout;
  }

  @override
  int get hashCode {
    return Object.hash(
      databasePath,
      enableInMemoryMode,
      chunkSize,
      chunkOverlap,
      separators,
      preserveCodeBlocks,
      preserveTables,
      minChunkSize,
      systemPrompt,
      maxRetrievedChunks,
      minSimilarity,
      enableReranking,
      noContextResponse,
      maxCacheEntries,
      cacheExpiry,
      batchSize,
      syncInterval,
      initTimeout,
    );
  }

  @override
  String toString() {
    return 'VectorConfig(chunkSize: $chunkSize, maxRetrievedChunks: $maxRetrievedChunks, enableReranking: $enableReranking, maxCacheEntries: $maxCacheEntries)';
  }
}