import 'dart:io';
import 'package:path/path.dart' as path;
import 'models/vector_models.dart';
import 'database/vector_database.dart';
import 'embeddings/embedding_service.dart';
import 'storage/vector_storage.dart';
import 'processing/document_chunker.dart';
import 'processing/document_processor.dart';
import 'rag/rag_pipeline.dart';
import '../services/llm/unified_llm_service.dart';

/// Example demonstrating complete vector database integration
class VectorIntegrationExample {
  late VectorDatabase _vectorDB;
  late RAGPipeline _ragPipeline;

  /// Initialize the complete vector database system
  Future<void> initialize(String databasePath, UnifiedLLMService llmService) async {
    print('🚀 Initializing Vector Database Integration Example');

    // Create embedding service (local for offline operation)
    final embeddingService = EmbeddingServiceFactory.createLocal();

    // Create storage
    final storage = VectorStorageFactory.createFile(databasePath);

    // Create chunker with optimized configuration
    final chunker = DocumentChunker(
      config: ChunkingConfig(
        chunkSize: 1000,
        chunkOverlap: 200,
        separators: ['\n\n', '\n', '. ', ' '],
        preserveCodeBlocks: true,
        minChunkSize: 100,
      ),
    );

    // Initialize vector database
    _vectorDB = VectorDatabase(
      embeddingService: embeddingService,
      storage: storage,
      chunker: chunker,
    );

    await _vectorDB.initialize();

    // Initialize RAG pipeline
    _ragPipeline = RAGPipeline(
      vectorDatabase: _vectorDB,
      modelService: llmService,
      config: RAGConfig(
        maxRetrievedChunks: 10,
        minSimilarity: 0.3,
        enableReranking: true,
        systemPrompt: 'You are a helpful AI assistant that provides accurate answers based on the provided context.',
      ),
    );

    print('✅ Vector Database Integration initialized successfully');
  }

  /// Example: Process and index multiple documents
  Future<void> indexDocuments(List<String> filePaths) async {
    print('📚 Indexing ${filePaths.length} documents');

    for (final filePath in filePaths) {
      try {
        final file = File(filePath);
        
        // Check if file format is supported
        if (!DocumentProcessor.isSupported(filePath)) {
          print('⚠️ Skipping unsupported file: $filePath');
          continue;
        }

        // Process the document
        final document = await DocumentProcessor.processFile(file);
        
        // Add to vector database
        await _vectorDB.addDocument(document);
        
        print('✅ Indexed: ${document.title}');
        
      } catch (e) {
        print('❌ Failed to index $filePath: $e');
      }
    }

    // Show database statistics
    final stats = await _vectorDB.getStats();
    print('📊 Database Stats: ${stats.totalDocuments} documents, ${stats.totalChunks} chunks');
  }

  /// Example: Perform semantic search
  Future<List<VectorSearchResult>> searchDocuments(String query, {int limit = 5}) async {
    print('🔍 Searching for: "$query"');

    final searchQuery = VectorSearchQuery(
      query: query,
      limit: limit,
      minSimilarity: 0.2,
      enableReranking: true,
      includeMetadata: true,
    );

    final results = await _vectorDB.search(searchQuery);
    
    print('📋 Found ${results.length} relevant results:');
    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      final score = (result.effectiveScore * 100).toStringAsFixed(1);
      print('  ${i + 1}. Score: $score% - ${result.chunk.metadata['document_title']}');
      print('     Preview: ${result.chunk.text.substring(0, 100)}...');
    }

    return results;
  }

  /// Example: Generate RAG response
  Future<RAGResponse> answerQuestion(String question) async {
    print('❓ Generating answer for: "$question"');

    final response = await _ragPipeline.generateWithContext(
      question,
      maxContextTokens: 8000,
      includeCitations: true,
    );

    print('💡 Answer generated:');
    print('   Query: ${response.query}');
    print('   Answer: ${response.answer}');
    print('   Sources: ${response.sources.length} documents referenced');
    print('   Processing time: ${response.metadata['total_time_ms']}ms');

    return response;
  }

  /// Example: Find similar documents
  Future<List<VectorSearchResult>> findSimilarDocuments(String documentId) async {
    print('🔗 Finding documents similar to: $documentId');

    final similarDocs = await _vectorDB.findSimilarDocuments(
      documentId,
      limit: 3,
      minSimilarity: 0.4,
    );

    print('📋 Found ${similarDocs.length} similar documents:');
    for (final doc in similarDocs) {
      final score = (doc.effectiveScore * 100).toStringAsFixed(1);
      print('  - Similarity: $score% - ${doc.chunk.metadata['document_title']}');
    }

    return similarDocs;
  }

  /// Example: Process different file formats
  Future<void> demonstrateFileFormats() async {
    print('📄 Demonstrating supported file formats');

    final supportedExtensions = DocumentProcessor.getSupportedExtensions();
    print('✅ Supported formats: ${supportedExtensions.join(', ')}');

    // Create sample files for demonstration
    final tempDir = Directory.systemTemp.createTempSync('vector_demo_');
    
    try {
      // Create sample markdown file
      final mdFile = File(path.join(tempDir.path, 'sample.md'));
      await mdFile.writeAsString('''
# Sample Document

This is a **sample** markdown document for testing the vector database.

## Features

- Document processing
- Semantic search
- RAG responses

The vector database can handle multiple file formats and provides intelligent chunking.
''');

      // Create sample JSON file
      final jsonFile = File(path.join(tempDir.path, 'data.json'));
      await jsonFile.writeAsString('''
{
  "title": "Configuration Data",
  "settings": {
    "embedding_dimension": 384,
    "chunk_size": 1000,
    "supported_formats": ["txt", "md", "json", "csv"]
  },
  "description": "This JSON file contains configuration data for the vector database system."
}
''');

      // Process the files
      await indexDocuments([mdFile.path, jsonFile.path]);

      // Test search
      await searchDocuments('vector database features');

    } finally {
      // Cleanup
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  }

  /// Example: Complete workflow demonstration
  Future<void> runCompleteExample() async {
    print('🎯 Running complete vector database workflow example\n');

    // Step 1: Database statistics before adding documents
    var stats = await _vectorDB.getStats();
    print('📊 Initial stats: ${stats.totalDocuments} documents');

    // Step 2: Demonstrate file format support
    await demonstrateFileFormats();

    // Step 3: Perform semantic searches
    final searchQueries = [
      'document processing and chunking',
      'embedding generation techniques',
      'semantic search algorithms',
    ];

    for (final query in searchQueries) {
      await searchDocuments(query, limit: 3);
      print(''); // Add spacing
    }

    // Step 4: Generate RAG responses
    final questions = [
      'How does the vector database handle different file formats?',
      'What are the benefits of semantic search?',
      'Explain the chunking strategy used in document processing.',
    ];

    for (final question in questions) {
      await answerQuestion(question);
      print(''); // Add spacing
    }

    // Step 5: Final statistics
    stats = await _vectorDB.getStats();
    print('📊 Final stats: ${stats.totalDocuments} documents, ${stats.totalChunks} chunks');
    print('✅ Complete workflow example finished successfully!');
  }

  /// Cleanup resources
  Future<void> dispose() async {
    await _vectorDB.dispose();
    print('🧹 Vector database resources cleaned up');
  }
}

/// Utility function to run the integration example
Future<void> runVectorIntegrationExample(
  String databasePath,
  UnifiedLLMService llmService, {
  List<String>? documentPaths,
}) async {
  final example = VectorIntegrationExample();
  
  try {
    // Initialize the system
    await example.initialize(databasePath, llmService);
    
    // Index documents if provided
    if (documentPaths != null && documentPaths.isNotEmpty) {
      await example.indexDocuments(documentPaths);
    }
    
    // Run the complete example workflow
    await example.runCompleteExample();
    
  } catch (e) {
    print('❌ Example failed: $e');
  } finally {
    // Always cleanup
    await example.dispose();
  }
}