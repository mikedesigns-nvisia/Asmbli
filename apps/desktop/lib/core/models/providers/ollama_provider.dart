import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../model_interfaces.dart';

/// Ollama local model provider implementation
class OllamaProvider extends ModelProvider {
  final String baseUrl;
  final Duration timeout;
  
  late final Dio _client;
  bool _isInitialized = false;
  List<ModelInfo> _availableModels = [];
  
  static const Map<String, ModelCapabilities> _modelCapabilities = {
    'llama2': ModelCapabilities(
      supportsStreaming: true,
      maxTokens: 4096,
      contextWindow: 4096,
      costPerInputToken: 0.0, // Local models are free
      costPerOutputToken: 0.0,
      type: ModelType.chat,
    ),
    'llama2:13b': ModelCapabilities(
      supportsStreaming: true,
      maxTokens: 4096,
      contextWindow: 4096,
      costPerInputToken: 0.0,
      costPerOutputToken: 0.0,
      type: ModelType.chat,
    ),
    'codellama': ModelCapabilities(
      supportsStreaming: true,
      maxTokens: 16384,
      contextWindow: 16384,
      costPerInputToken: 0.0,
      costPerOutputToken: 0.0,
      type: ModelType.code,
    ),
    'mistral': ModelCapabilities(
      supportsStreaming: true,
      maxTokens: 8192,
      contextWindow: 8192,
      costPerInputToken: 0.0,
      costPerOutputToken: 0.0,
      type: ModelType.chat,
    ),
    'neural-chat': ModelCapabilities(
      supportsStreaming: true,
      maxTokens: 4096,
      contextWindow: 4096,
      costPerInputToken: 0.0,
      costPerOutputToken: 0.0,
      type: ModelType.chat,
    ),
  };

  OllamaProvider({
    this.baseUrl = 'http://localhost:11434',
    this.timeout = ModelConstants.defaultTimeout,
  });

  @override
  String get id => 'ollama';

  @override
  String get name => 'Ollama';

  @override
  ModelCapabilities get capabilities => const ModelCapabilities(
    supportsStreaming: true,
    maxTokens: 16384,
    contextWindow: 16384,
    type: ModelType.chat,
    costPerInputToken: 0.0,
    costPerOutputToken: 0.0,
  );

  @override
  Map<String, dynamic> get config => {
    'base_url': baseUrl,
    'timeout': timeout.inMilliseconds,
  };

  @override
  bool get isAvailable => _isInitialized;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    print('🔧 Initializing Ollama provider');

    try {
      _client = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: timeout,
        receiveTimeout: timeout,
        headers: {
          'Content-Type': 'application/json',
        },
      ));

      // Add interceptors for logging and error handling
      _client.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          print('🔍 Ollama Request: ${options.method} ${options.path}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ Ollama Response: ${response.statusCode}');
          handler.next(response);
        },
        onError: (error, handler) {
          print('❌ Ollama Error: ${error.message}');
          handler.next(error);
        },
      ));

      // Test connection and load available models
      await _loadAvailableModels();

      _isInitialized = true;
      print('✅ Ollama provider initialized successfully');
    } catch (e) {
      print('⚠️ Ollama provider initialization failed: $e');
      // Don't throw error for Ollama as it might not be running
      // but we want to keep the provider available for when it is
    }
  }

  @override
  Future<bool> testConnection() async {
    try {
      print('🔍 Testing Ollama connection');
      
      final response = await _client.get('/api/tags');
      final isHealthy = response.statusCode == 200;
      
      print('${isHealthy ? "✅" : "❌"} Ollama connection test: ${isHealthy ? "SUCCESS" : "FAILED"}');
      return isHealthy;
    } catch (e) {
      print('❌ Ollama connection test failed: $e');
      return false;
    }
  }

  @override
  Future<ModelResponse> complete(ModelRequest request) async {
    if (!_isInitialized) await initialize();

    final startTime = DateTime.now();
    
    try {
      print('🤖 Ollama completion request for model: ${request.model ?? ModelConstants.defaultOllamaModel}');
      
      final requestData = _buildCompletionRequest(request);
      final response = await _client.post('/api/generate', data: requestData);
      
      if (response.statusCode != 200) {
        throw ModelCompletionException(
          'Ollama API returned status ${response.statusCode}',
          providerId: id,
          modelId: request.model,
          request: request,
        );
      }

      final data = response.data as Map<String, dynamic>;
      final responseTime = DateTime.now().difference(startTime);
      
      return _parseCompletionResponse(data, request.model, responseTime);
    } on DioException catch (e) {
      throw _handleDioError(e, request);
    } catch (e) {
      throw ModelCompletionException(
        'Ollama completion failed: $e',
        providerId: id,
        modelId: request.model,
        request: request,
        originalError: e,
      );
    }
  }

  @override
  Stream<String> stream(ModelRequest request) async* {
    if (!_isInitialized) await initialize();

    try {
      print('🌊 Ollama streaming request for model: ${request.model ?? ModelConstants.defaultOllamaModel}');
      
      final requestData = _buildCompletionRequest(request, stream: true);
      
      final response = await _client.post(
        '/api/generate',
        data: requestData,
        options: Options(
          responseType: ResponseType.stream,
        ),
      );

      if (response.statusCode != 200) {
        throw ModelCompletionException(
          'Ollama streaming API returned status ${response.statusCode}',
          providerId: id,
          modelId: request.model,
          request: request,
        );
      }

      await for (final chunk in _parseStreamingResponse(response.data)) {
        yield chunk;
      }
    } on DioException catch (e) {
      throw _handleDioError(e, request);
    } catch (e) {
      throw ModelCompletionException(
        'Ollama streaming failed: $e',
        providerId: id,
        modelId: request.model,
        request: request,
        originalError: e,
      );
    }
  }

  @override
  Future<List<double>> embed(String text) async {
    if (!_isInitialized) await initialize();

    try {
      print('🔢 Ollama embedding request');
      
      final requestData = {
        'model': 'llama2', // Use a default model for embeddings
        'prompt': text,
      };

      final response = await _client.post('/api/embeddings', data: requestData);
      
      if (response.statusCode != 200) {
        throw ModelCompletionException(
          'Ollama embeddings API returned status ${response.statusCode}',
          providerId: id,
          modelId: 'llama2',
        );
      }

      final data = response.data as Map<String, dynamic>;
      final embedding = data['embedding'] as List?;
      
      if (embedding == null) {
        throw ModelCompletionException(
          'No embeddings returned from Ollama',
          providerId: id,
          modelId: 'llama2',
        );
      }

      return List<double>.from(embedding);
    } on DioException catch (e) {
      throw _handleDioError(e, null);
    } catch (e) {
      throw ModelCompletionException(
        'Ollama embedding failed: $e',
        providerId: id,
        modelId: 'llama2',
        originalError: e,
      );
    }
  }

  @override
  Future<List<ModelInfo>> getAvailableModels() async {
    if (!_isInitialized) await initialize();

    if (_availableModels.isEmpty) {
      await _loadAvailableModels();
    }

    return _availableModels;
  }

  @override
  Future<ProviderHealth> healthCheck() async {
    final startTime = DateTime.now();
    
    try {
      final isHealthy = await testConnection();
      final latency = DateTime.now().difference(startTime).inMilliseconds.toDouble();
      
      return ProviderHealth(
        isHealthy: isHealthy,
        latency: latency,
        status: isHealthy ? 'healthy' : 'unhealthy',
        details: {
          'provider': id,
          'models_available': _availableModels.length,
          'base_url': baseUrl,
          'is_local': true,
        },
      );
    } catch (e) {
      final latency = DateTime.now().difference(startTime).inMilliseconds.toDouble();
      
      return ProviderHealth(
        isHealthy: false,
        latency: latency,
        status: 'error',
        error: e.toString(),
        details: {
          'provider': id,
          'error_type': e.runtimeType.toString(),
          'is_local': true,
        },
      );
    }
  }

  @override
  Future<void> dispose() async {
    if (!_isInitialized) return;
    
    print('🧹 Disposing Ollama provider');
    _client.close();
    _isInitialized = false;
  }

  /// Load available models from Ollama
  Future<void> _loadAvailableModels() async {
    try {
      print('📋 Loading Ollama models');
      
      final response = await _client.get('/api/tags');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final models = data['models'] as List? ?? [];
        
        _availableModels = models.map<ModelInfo>((model) {
          final name = model['name'] as String;
          final size = model['size'] as int? ?? 0;
          final modifiedAt = model['modified_at'] as String?;
          
          // Extract base model name for capabilities lookup
          final baseModel = name.split(':').first;
          final capabilities = _modelCapabilities[baseModel] ?? _modelCapabilities['llama2']!;
          
          return ModelInfo(
            id: name,
            name: name,
            description: 'Ollama local model - ${_formatBytes(size)}',
            capabilities: capabilities,
            providerId: id,
            isLocal: true,
            lastUpdated: modifiedAt != null ? DateTime.tryParse(modifiedAt) : null,
            metadata: {
              'size_bytes': size,
              'size_formatted': _formatBytes(size),
              'base_model': baseModel,
            },
          );
        }).toList();
        
        print('✅ Loaded ${_availableModels.length} Ollama models');
      }
    } catch (e) {
      print('⚠️ Failed to load Ollama models: $e');
      // Create default model entries if we can't fetch from API
      _availableModels = _modelCapabilities.entries.map((entry) {
        return ModelInfo(
          id: entry.key,
          name: entry.key,
          description: 'Ollama ${entry.key} model',
          capabilities: entry.value,
          providerId: id,
          isLocal: true,
        );
      }).toList();
    }
  }

  /// Build completion request payload
  Map<String, dynamic> _buildCompletionRequest(ModelRequest request, {bool stream = false}) {
    // Convert messages to Ollama prompt format
    final prompt = _buildPromptFromMessages(request.messages, request.systemPrompt);
    
    return {
      'model': request.model ?? ModelConstants.defaultOllamaModel,
      'prompt': prompt,
      'stream': stream,
      'options': {
        'temperature': request.temperature,
        'top_p': request.topP,
        'num_predict': request.maxTokens,
        if (request.stop != null) 'stop': request.stop,
      },
    };
  }

  /// Build prompt from messages
  String _buildPromptFromMessages(List<Message> messages, String? systemPrompt) {
    final buffer = StringBuffer();
    
    // Add system prompt if provided
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      buffer.writeln('System: $systemPrompt\n');
    }
    
    // Convert messages to conversation format
    for (final message in messages) {
      switch (message.role) {
        case 'system':
          if (systemPrompt == null || systemPrompt.isEmpty) {
            buffer.writeln('System: ${message.content}\n');
          }
          break;
        case 'user':
          buffer.writeln('Human: ${message.content}\n');
          break;
        case 'assistant':
          buffer.writeln('Assistant: ${message.content}\n');
          break;
        default:
          buffer.writeln('${message.role}: ${message.content}\n');
      }
    }
    
    // Add assistant prompt to continue conversation
    buffer.write('Assistant: ');
    
    return buffer.toString();
  }

  /// Parse completion response
  ModelResponse _parseCompletionResponse(
    Map<String, dynamic> data,
    String? modelId,
    Duration responseTime,
  ) {
    final response = data['response'] as String? ?? '';
    final done = data['done'] as bool? ?? true;
    
    if (!done) {
      throw ModelCompletionException(
        'Ollama response not completed',
        providerId: id,
        modelId: modelId,
      );
    }

    // Ollama doesn't provide detailed token usage, so we estimate
    final promptTokens = _estimateTokens(data['prompt'] as String? ?? '');
    final completionTokens = _estimateTokens(response);
    
    final usage = Usage(
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      totalCost: 0.0, // Local models are free
      breakdown: {
        'input_cost': 0.0,
        'output_cost': 0.0,
        'model': modelId,
        'is_local': true,
      },
    );

    return ModelResponse(
      content: response,
      usage: usage,
      model: data['model'] as String?,
      finishReason: done ? 'stop' : null,
      responseTime: responseTime,
      metadata: {
        'provider': id,
        'is_local': true,
        'total_duration': data['total_duration'],
        'load_duration': data['load_duration'],
        'prompt_eval_count': data['prompt_eval_count'],
        'eval_count': data['eval_count'],
      },
    );
  }

  /// Parse streaming response
  Stream<String> _parseStreamingResponse(ResponseBody responseBody) async* {
    final stream = responseBody.stream;
    
    await for (final chunk in stream.transform(utf8.decoder)) {
      final lines = chunk.split('\n');
      
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        
        try {
          final json = jsonDecode(line) as Map<String, dynamic>;
          final response = json['response'] as String?;
          final done = json['done'] as bool? ?? false;
          
          if (response != null && response.isNotEmpty) {
            yield response;
          }
          
          if (done) {
            return;
          }
        } catch (e) {
          // Ignore parsing errors for individual chunks
          print('⚠️ Failed to parse Ollama streaming chunk: $e');
        }
      }
    }
  }

  /// Estimate token count (rough approximation)
  int _estimateTokens(String text) {
    // Rough estimate: 1 token ≈ 4 characters
    return (text.length / 4).ceil();
  }

  /// Format bytes to human readable string
  String _formatBytes(int bytes) {
    if (bytes == 0) return '0 B';
    
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    int unitIndex = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    
    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  /// Handle Dio errors and convert to appropriate exceptions
  ModelException _handleDioError(DioException error, ModelRequest? request) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ProviderConnectionException(
          'Ollama connection timeout - is Ollama running?',
          providerId: id,
          originalError: error,
        );
      
      case DioExceptionType.connectionError:
        return ProviderConnectionException(
          'Cannot connect to Ollama - is it running on ${baseUrl}?',
          providerId: id,
          originalError: error,
        );
      
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        return ModelCompletionException(
          'Ollama API error (${statusCode}): ${error.message}',
          providerId: id,
          request: request,
          originalError: error,
        );
      
      default:
        return ModelCompletionException(
          'Ollama request failed: ${error.message}',
          providerId: id,
          request: request,
          originalError: error,
        );
    }
  }
}