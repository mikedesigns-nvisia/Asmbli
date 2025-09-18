import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';

/// Abstract base class for embedding generation services
abstract class EmbeddingService {
  /// Get the dimension of embeddings produced by this service
  int get embeddingDimension;
  
  /// Get the model name/identifier
  String get modelName;
  
  /// Generate embeddings for a single text
  Future<List<double>> generateEmbedding(String text);
  
  /// Generate embeddings for multiple texts (batch processing)
  Future<List<List<double>>> generateEmbeddings(List<String> texts);
  
  /// Calculate similarity between two embeddings
  double calculateSimilarity(List<double> embedding1, List<double> embedding2);
  
  /// Dispose of any resources
  Future<void> dispose();
}

/// Local embedding service that can work offline
class LocalEmbeddingService extends EmbeddingService {
  static const String _defaultModel = 'all-MiniLM-L6-v2';
  final String modelPath;
  final int _dimension = 384; // Dimension for all-MiniLM-L6-v2
  bool _isInitialized = false;

  LocalEmbeddingService({
    this.modelPath = 'assets/models/all-MiniLM-L6-v2.onnx',
  });

  @override
  int get embeddingDimension => _dimension;

  @override
  String get modelName => _defaultModel;

  /// Initialize the local embedding model
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🔧 Initializing local embedding service with model: $modelName');
      
      // Load the specified ONNX model for local embeddings
      // Using mock implementation until ONNX runtime is integrated
      await _loadModel();
      
      _isInitialized = true;
      print('✅ Local embedding service initialized');
    } catch (e) {
      throw EmbeddingException('Failed to initialize local embedding service: $e');
    }
  }

  Future<void> _loadModel() async {
    // Simulate model loading
    await Future.delayed(const Duration(milliseconds: 500));
    
    // In a real implementation, this would load the ONNX model
    // using packages like onnxruntime_flutter
    print('📦 Mock: Loaded embedding model from $modelPath');
  }

  @override
  Future<List<double>> generateEmbedding(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Preprocess text
      final processedText = _preprocessText(text);
      
      // Generate embedding using ONNX model inference
      // Currently using deterministic mock until ONNX runtime integration
      final embedding = _generateMockEmbedding(processedText);
      
      return embedding;
    } catch (e) {
      throw EmbeddingException('Failed to generate embedding: $e');
    }
  }

  @override
  Future<List<List<double>>> generateEmbeddings(List<String> texts) async {
    if (!_isInitialized) {
      await initialize();
    }

    print('🔢 Generating ${texts.length} embeddings');
    
    // Process in batches to avoid memory issues
    const batchSize = 32;
    final embeddings = <List<double>>[];
    
    for (int i = 0; i < texts.length; i += batchSize) {
      final end = (i + batchSize < texts.length) ? i + batchSize : texts.length;
      final batch = texts.sublist(i, end);
      
      final batchEmbeddings = await Future.wait(
        batch.map((text) => generateEmbedding(text)),
      );
      
      embeddings.addAll(batchEmbeddings);
      
      // Small delay to prevent overwhelming the system
      if (end < texts.length) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
    
    print('✅ Generated ${embeddings.length} embeddings');
    return embeddings;
  }

  /// Preprocess text for embedding
  String _preprocessText(String text) {
    if (text.isEmpty) return text;
    
    final processed = text
        // Remove excessive whitespace
        .replaceAll(RegExp(r'\s+'), ' ')
        // Remove special characters that might interfere
        .replaceAll(RegExp(r'[^\w\s.,!?-]'), '')
        .trim();
    
    // Safely limit length to prevent issues
    final maxLength = min(processed.length, 512);
    if (maxLength <= 0) return '';
    
    return processed.substring(0, maxLength);
  }

  /// Generate a mock embedding (deterministic based on text)
  List<double> _generateMockEmbedding(String text) {
    // Create a deterministic hash-based embedding
    final hash = text.hashCode;
    final random = Random(hash);
    
    final embedding = List<double>.generate(_dimension, (index) {
      // Generate values between -1 and 1
      return (random.nextDouble() - 0.5) * 2;
    });
    
    // Normalize the embedding
    return _normalizeEmbedding(embedding);
  }

  /// Normalize embedding to unit vector
  List<double> _normalizeEmbedding(List<double> embedding) {
    final magnitude = sqrt(
      embedding.map((x) => x * x).reduce((a, b) => a + b),
    );
    
    if (magnitude == 0) return embedding;
    
    return embedding.map((x) => x / magnitude).toList();
  }

  @override
  double calculateSimilarity(List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) {
      throw ArgumentError('Embeddings must have the same dimension');
    }

    // Calculate cosine similarity
    double dotProduct = 0;
    double magnitude1 = 0;
    double magnitude2 = 0;

    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
      magnitude1 += embedding1[i] * embedding1[i];
      magnitude2 += embedding2[i] * embedding2[i];
    }

    magnitude1 = sqrt(magnitude1);
    magnitude2 = sqrt(magnitude2);

    if (magnitude1 == 0 || magnitude2 == 0) return 0;

    return dotProduct / (magnitude1 * magnitude2);
  }

  @override
  Future<void> dispose() async {
    if (!_isInitialized) return;
    
    print('🧹 Disposing local embedding service');
    _isInitialized = false;
  }
}

/// API-based embedding service (e.g., OpenAI, Cohere)
class APIEmbeddingService extends EmbeddingService {
  final String apiKey;
  final String apiUrl;
  final String model;
  final Dio _client;
  final int _dimension;

  APIEmbeddingService({
    required this.apiKey,
    this.apiUrl = 'https://api.openai.com/v1/embeddings',
    this.model = 'text-embedding-3-small',
    int dimension = 1536,
  }) : _dimension = dimension,
       _client = Dio(BaseOptions(
         connectTimeout: const Duration(seconds: 30),
         receiveTimeout: const Duration(seconds: 60),
         headers: {
           'Authorization': 'Bearer $apiKey',
           'Content-Type': 'application/json',
         },
       ));

  @override
  int get embeddingDimension => _dimension;

  @override
  String get modelName => model;

  @override
  Future<List<double>> generateEmbedding(String text) async {
    try {
      final response = await _client.post(apiUrl, data: {
        'model': model,
        'input': text,
      });

      final data = response.data;
      if (data['data'] == null || data['data'].isEmpty) {
        throw const EmbeddingException('No embedding data received from API');
      }

      return List<double>.from(data['data'][0]['embedding']);
    } on DioException catch (e) {
      throw EmbeddingException('API request failed: ${e.message}');
    } catch (e) {
      throw EmbeddingException('Failed to generate API embedding: $e');
    }
  }

  @override
  Future<List<List<double>>> generateEmbeddings(List<String> texts) async {
    // API services usually support batch processing
    try {
      print('🔢 Generating ${texts.length} embeddings via API');
      
      final response = await _client.post(apiUrl, data: {
        'model': model,
        'input': texts,
      });

      final data = response.data;
      if (data['data'] == null) {
        throw const EmbeddingException('No embedding data received from API');
      }

      final embeddings = <List<double>>[];
      for (final item in data['data']) {
        embeddings.add(List<double>.from(item['embedding']));
      }

      print('✅ Generated ${embeddings.length} API embeddings');
      return embeddings;
    } on DioException catch (e) {
      throw EmbeddingException('API batch request failed: ${e.message}');
    } catch (e) {
      throw EmbeddingException('Failed to generate API embeddings: $e');
    }
  }

  @override
  double calculateSimilarity(List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) {
      throw ArgumentError('Embeddings must have the same dimension');
    }

    // Calculate cosine similarity
    double dotProduct = 0;
    double magnitude1 = 0;
    double magnitude2 = 0;

    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
      magnitude1 += embedding1[i] * embedding1[i];
      magnitude2 += embedding2[i] * embedding2[i];
    }

    magnitude1 = sqrt(magnitude1);
    magnitude2 = sqrt(magnitude2);

    if (magnitude1 == 0 || magnitude2 == 0) return 0;

    return dotProduct / (magnitude1 * magnitude2);
  }

  @override
  Future<void> dispose() async {
    _client.close();
    print('🧹 Disposed API embedding service');
  }
}

/// Factory for creating embedding services
class EmbeddingServiceFactory {
  static EmbeddingService createLocal({
    String modelPath = 'assets/models/all-MiniLM-L6-v2.onnx',
  }) {
    return LocalEmbeddingService(modelPath: modelPath);
  }

  static EmbeddingService createAPI({
    required String apiKey,
    String apiUrl = 'https://api.openai.com/v1/embeddings',
    String model = 'text-embedding-3-small',
    int dimension = 1536,
  }) {
    return APIEmbeddingService(
      apiKey: apiKey,
      apiUrl: apiUrl,
      model: model,
      dimension: dimension,
    );
  }

  static EmbeddingService createFromConfig(Map<String, dynamic> config) {
    final type = config['type']?.toString() ?? 'local';
    
    switch (type.toLowerCase()) {
      case 'local':
        return createLocal(
          modelPath: config['modelPath'] ?? 'assets/models/all-MiniLM-L6-v2.onnx',
        );
      
      case 'api':
      case 'openai':
        return createAPI(
          apiKey: config['apiKey'] ?? '',
          apiUrl: config['apiUrl'] ?? 'https://api.openai.com/v1/embeddings',
          model: config['model'] ?? 'text-embedding-3-small',
          dimension: config['dimension'] ?? 1536,
        );
      
      default:
        throw ArgumentError('Unknown embedding service type: $type');
    }
  }
}

/// Exception for embedding-related errors
class EmbeddingException implements Exception {
  final String message;
  final dynamic originalError;

  const EmbeddingException(this.message, [this.originalError]);

  @override
  String toString() {
    final buffer = StringBuffer('EmbeddingException: $message');
    if (originalError != null) {
      buffer.write(' (caused by: $originalError)');
    }
    return buffer.toString();
  }
}