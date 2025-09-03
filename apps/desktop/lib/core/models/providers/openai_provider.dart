import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../model_interfaces.dart';

/// OpenAI model provider implementation
class OpenAIProvider extends ModelProvider {
  final String apiKey;
  final String baseUrl;
  final String organization;
  final Duration timeout;
  
  late final Dio _client;
  bool _isInitialized = false;
  
  static const Map<String, ModelInfo> _models = {
    'gpt-3.5-turbo': ModelInfo(
      id: 'gpt-3.5-turbo',
      name: 'GPT-3.5 Turbo',
      description: 'Most capable GPT-3.5 model, optimized for chat',
      capabilities: ModelCapabilities(
        supportsStreaming: true,
        supportsTools: true,
        maxTokens: 4096,
        contextWindow: 4096,
        costPerInputToken: 0.0005,
        costPerOutputToken: 0.0015,
        type: ModelType.chat,
      ),
      providerId: 'openai',
    ),
    'gpt-4': ModelInfo(
      id: 'gpt-4',
      name: 'GPT-4',
      description: 'More capable than any GPT-3.5 model',
      capabilities: ModelCapabilities(
        supportsStreaming: true,
        supportsTools: true,
        maxTokens: 8192,
        contextWindow: 8192,
        costPerInputToken: 0.03,
        costPerOutputToken: 0.06,
        type: ModelType.chat,
      ),
      providerId: 'openai',
    ),
    'gpt-4-turbo': ModelInfo(
      id: 'gpt-4-turbo',
      name: 'GPT-4 Turbo',
      description: 'Latest GPT-4 model with improved capabilities',
      capabilities: ModelCapabilities(
        supportsStreaming: true,
        supportsTools: true,
        supportsVision: true,
        maxTokens: 4096,
        contextWindow: 128000,
        costPerInputToken: 0.01,
        costPerOutputToken: 0.03,
        type: ModelType.multimodal,
      ),
      providerId: 'openai',
    ),
    'text-embedding-3-small': ModelInfo(
      id: 'text-embedding-3-small',
      name: 'Text Embedding 3 Small',
      description: 'Small embedding model for text similarity',
      capabilities: ModelCapabilities(
        supportsEmbeddings: true,
        maxTokens: 8191,
        contextWindow: 8191,
        costPerInputToken: 0.00002,
        costPerOutputToken: 0.0,
        type: ModelType.embedding,
      ),
      providerId: 'openai',
    ),
  };

  OpenAIProvider({
    required this.apiKey,
    this.baseUrl = 'https://api.openai.com/v1',
    this.organization = '',
    this.timeout = ModelConstants.defaultTimeout,
  });

  @override
  String get id => 'openai';

  @override
  String get name => 'OpenAI';

  @override
  ModelCapabilities get capabilities => const ModelCapabilities(
    supportsStreaming: true,
    supportsTools: true,
    supportsVision: true,
    supportsEmbeddings: true,
    maxTokens: 128000,
    contextWindow: 128000,
    type: ModelType.multimodal,
    costPerInputToken: 0.0005,
    costPerOutputToken: 0.0015,
  );

  @override
  Map<String, dynamic> get config => {
    'api_key': '***',
    'base_url': baseUrl,
    'organization': organization,
    'timeout': timeout.inMilliseconds,
  };

  @override
  bool get isAvailable => _isInitialized && apiKey.isNotEmpty;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    print('🔧 Initializing OpenAI provider');

    try {
      _client = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: timeout,
        receiveTimeout: timeout,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          if (organization.isNotEmpty) 'OpenAI-Organization': organization,
        },
      ));

      // Add interceptors for logging and error handling
      _client.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          print('🔍 OpenAI Request: ${options.method} ${options.path}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ OpenAI Response: ${response.statusCode}');
          handler.next(response);
        },
        onError: (error, handler) {
          print('❌ OpenAI Error: ${error.message}');
          handler.next(error);
        },
      ));

      _isInitialized = true;
      print('✅ OpenAI provider initialized successfully');
    } catch (e) {
      throw ProviderInitializationException(
        'Failed to initialize OpenAI provider: $e',
        providerId: id,
        originalError: e,
      );
    }
  }

  @override
  Future<bool> testConnection() async {
    if (!_isInitialized) await initialize();

    try {
      print('🔍 Testing OpenAI connection');
      
      final response = await _client.get('/models');
      final isHealthy = response.statusCode == 200;
      
      print('${isHealthy ? "✅" : "❌"} OpenAI connection test: ${isHealthy ? "SUCCESS" : "FAILED"}');
      return isHealthy;
    } catch (e) {
      print('❌ OpenAI connection test failed: $e');
      return false;
    }
  }

  @override
  Future<ModelResponse> complete(ModelRequest request) async {
    if (!_isInitialized) await initialize();

    final startTime = DateTime.now();
    
    try {
      print('🤖 OpenAI completion request for model: ${request.model ?? "gpt-3.5-turbo"}');
      
      final requestData = _buildCompletionRequest(request);
      final response = await _client.post('/chat/completions', data: requestData);
      
      if (response.statusCode != 200) {
        throw ModelCompletionException(
          'OpenAI API returned status ${response.statusCode}',
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
        'OpenAI completion failed: $e',
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
      print('🌊 OpenAI streaming request for model: ${request.model ?? "gpt-3.5-turbo"}');
      
      final requestData = _buildCompletionRequest(request, stream: true);
      
      final response = await _client.post(
        '/chat/completions',
        data: requestData,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
        ),
      );

      if (response.statusCode != 200) {
        throw ModelCompletionException(
          'OpenAI streaming API returned status ${response.statusCode}',
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
        'OpenAI streaming failed: $e',
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
      print('🔢 OpenAI embedding request');
      
      final requestData = {
        'model': 'text-embedding-3-small',
        'input': text,
      };

      final response = await _client.post('/embeddings', data: requestData);
      
      if (response.statusCode != 200) {
        throw ModelCompletionException(
          'OpenAI embeddings API returned status ${response.statusCode}',
          providerId: id,
          modelId: 'text-embedding-3-small',
        );
      }

      final data = response.data as Map<String, dynamic>;
      final embeddings = data['data'] as List;
      
      if (embeddings.isEmpty) {
        throw ModelCompletionException(
          'No embeddings returned from OpenAI',
          providerId: id,
          modelId: 'text-embedding-3-small',
        );
      }

      return List<double>.from(embeddings.first['embedding']);
    } on DioException catch (e) {
      throw _handleDioError(e, null);
    } catch (e) {
      throw ModelCompletionException(
        'OpenAI embedding failed: $e',
        providerId: id,
        modelId: 'text-embedding-3-small',
        originalError: e,
      );
    }
  }

  @override
  Future<List<ModelInfo>> getAvailableModels() async {
    if (!_isInitialized) await initialize();

    try {
      print('📋 Fetching OpenAI available models');
      
      final response = await _client.get('/models');
      
      if (response.statusCode != 200) {
        return _models.values.toList();
      }

      final data = response.data as Map<String, dynamic>;
      final models = data['data'] as List;
      
      final availableModels = <ModelInfo>[];
      
      for (final model in models) {
        final modelId = model['id'] as String;
        if (_models.containsKey(modelId)) {
          availableModels.add(_models[modelId]!);
        }
      }
      
      // Fallback to predefined models if API doesn't return expected models
      return availableModels.isEmpty ? _models.values.toList() : availableModels;
    } catch (e) {
      print('⚠️ Failed to fetch OpenAI models, using predefined list: $e');
      return _models.values.toList();
    }
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
          'models_available': _models.length,
          'base_url': baseUrl,
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
        },
      );
    }
  }

  @override
  Future<void> dispose() async {
    if (!_isInitialized) return;
    
    print('🧹 Disposing OpenAI provider');
    _client.close();
    _isInitialized = false;
  }

  /// Build completion request payload
  Map<String, dynamic> _buildCompletionRequest(ModelRequest request, {bool stream = false}) {
    return {
      'model': request.model ?? ModelConstants.defaultGPTModel,
      'messages': request.messages.map((m) => m.toJson()).toList(),
      'temperature': request.temperature,
      'max_tokens': request.maxTokens,
      'top_p': request.topP,
      'stream': stream,
      if (request.stop != null) 'stop': request.stop,
      if (request.tools != null) 'tools': request.tools,
      if (request.systemPrompt != null)
        'messages': [
          {'role': 'system', 'content': request.systemPrompt},
          ...request.messages.map((m) => m.toJson()),
        ],
    };
  }

  /// Parse completion response
  ModelResponse _parseCompletionResponse(
    Map<String, dynamic> data,
    String? modelId,
    Duration responseTime,
  ) {
    final choices = data['choices'] as List;
    if (choices.isEmpty) {
      throw ModelCompletionException(
        'No choices returned from OpenAI',
        providerId: id,
        modelId: modelId,
      );
    }

    final choice = choices.first as Map<String, dynamic>;
    final message = choice['message'] as Map<String, dynamic>;
    final content = message['content'] as String? ?? '';
    final finishReason = choice['finish_reason'] as String?;

    final usageData = data['usage'] as Map<String, dynamic>?;
    final usage = usageData != null
        ? _parseUsage(usageData, modelId)
        : Usage.free();

    return ModelResponse(
      content: content,
      usage: usage,
      model: data['model'] as String?,
      finishReason: finishReason,
      responseTime: responseTime,
      metadata: {
        'provider': id,
        'choices_count': choices.length,
        'created': data['created'],
      },
    );
  }

  /// Parse streaming response
  Stream<String> _parseStreamingResponse(ResponseBody responseBody) async* {
    final stream = responseBody.stream;
    final buffer = StringBuffer();
    
    await for (final chunk in stream.transform(utf8.decoder)) {
      buffer.write(chunk);
      final lines = buffer.toString().split('\n');
      
      // Keep the last potentially incomplete line in the buffer
      buffer.clear();
      if (lines.isNotEmpty && !lines.last.isEmpty) {
        buffer.write(lines.last);
      }
      
      // Process complete lines
      for (int i = 0; i < lines.length - 1; i++) {
        final line = lines[i].trim();
        
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          
          if (data == '[DONE]') {
            return;
          }
          
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final choices = json['choices'] as List;
            
            if (choices.isNotEmpty) {
              final choice = choices.first as Map<String, dynamic>;
              final delta = choice['delta'] as Map<String, dynamic>?;
              final content = delta?['content'] as String?;
              
              if (content != null) {
                yield content;
              }
            }
          } catch (e) {
            // Ignore parsing errors for individual chunks
            print('⚠️ Failed to parse streaming chunk: $e');
          }
        }
      }
    }
  }

  /// Parse usage information
  Usage _parseUsage(Map<String, dynamic> usageData, String? modelId) {
    final promptTokens = usageData['prompt_tokens'] as int? ?? 0;
    final completionTokens = usageData['completion_tokens'] as int? ?? 0;
    
    // Calculate cost based on model
    double inputCost = 0.0;
    double outputCost = 0.0;
    
    if (modelId != null && _models.containsKey(modelId)) {
      final model = _models[modelId]!;
      inputCost = promptTokens * model.capabilities.costPerInputToken / 1000;
      outputCost = completionTokens * model.capabilities.costPerOutputToken / 1000;
    }
    
    return Usage(
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      totalCost: inputCost + outputCost,
      breakdown: {
        'input_cost': inputCost,
        'output_cost': outputCost,
        'model': modelId,
      },
    );
  }

  /// Handle Dio errors and convert to appropriate exceptions
  ModelException _handleDioError(DioException error, ModelRequest? request) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ProviderConnectionException(
          'OpenAI connection timeout: ${error.message}',
          providerId: id,
          originalError: error,
        );
      
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 429) {
          return QuotaExceededException(
            'OpenAI rate limit exceeded',
            providerId: id,
            originalError: error,
          );
        } else if (statusCode == 401) {
          return ProviderConnectionException(
            'OpenAI authentication failed - check API key',
            providerId: id,
            originalError: error,
          );
        } else {
          return ModelCompletionException(
            'OpenAI API error (${statusCode}): ${error.message}',
            providerId: id,
            request: request,
            originalError: error,
          );
        }
      
      default:
        return ModelCompletionException(
          'OpenAI request failed: ${error.message}',
          providerId: id,
          request: request,
          originalError: error,
        );
    }
  }
}