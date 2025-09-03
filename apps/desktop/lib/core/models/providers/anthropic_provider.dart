import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../model_interfaces.dart';

/// Anthropic model provider implementation
class AnthropicProvider extends ModelProvider {
  final String apiKey;
  final String baseUrl;
  final Duration timeout;
  
  late final Dio _client;
  bool _isInitialized = false;
  
  static const Map<String, ModelInfo> _models = {
    'claude-3-haiku-20240307': ModelInfo(
      id: 'claude-3-haiku-20240307',
      name: 'Claude 3 Haiku',
      description: 'Fast and affordable Claude model',
      capabilities: ModelCapabilities(
        supportsStreaming: true,
        maxTokens: 4096,
        contextWindow: 200000,
        costPerInputToken: 0.00025,
        costPerOutputToken: 0.00125,
        type: ModelType.chat,
      ),
      providerId: 'anthropic',
    ),
    'claude-3-sonnet-20240229': ModelInfo(
      id: 'claude-3-sonnet-20240229',
      name: 'Claude 3 Sonnet',
      description: 'Balanced performance Claude model',
      capabilities: ModelCapabilities(
        supportsStreaming: true,
        supportsVision: true,
        maxTokens: 4096,
        contextWindow: 200000,
        costPerInputToken: 0.003,
        costPerOutputToken: 0.015,
        type: ModelType.multimodal,
      ),
      providerId: 'anthropic',
    ),
    'claude-3-opus-20240229': ModelInfo(
      id: 'claude-3-opus-20240229',
      name: 'Claude 3 Opus',
      description: 'Most capable Claude model',
      capabilities: ModelCapabilities(
        supportsStreaming: true,
        supportsVision: true,
        maxTokens: 4096,
        contextWindow: 200000,
        costPerInputToken: 0.015,
        costPerOutputToken: 0.075,
        type: ModelType.multimodal,
      ),
      providerId: 'anthropic',
    ),
  };

  AnthropicProvider({
    required this.apiKey,
    this.baseUrl = 'https://api.anthropic.com',
    this.timeout = ModelConstants.defaultTimeout,
  });

  @override
  String get id => 'anthropic';

  @override
  String get name => 'Anthropic';

  @override
  ModelCapabilities get capabilities => const ModelCapabilities(
    supportsStreaming: true,
    supportsVision: true,
    maxTokens: 4096,
    contextWindow: 200000,
    type: ModelType.multimodal,
    costPerInputToken: 0.00025,
    costPerOutputToken: 0.00125,
  );

  @override
  Map<String, dynamic> get config => {
    'api_key': '***',
    'base_url': baseUrl,
    'timeout': timeout.inMilliseconds,
  };

  @override
  bool get isAvailable => _isInitialized && apiKey.isNotEmpty;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    print('🔧 Initializing Anthropic provider');

    try {
      _client = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: timeout,
        receiveTimeout: timeout,
        headers: {
          'x-api-key': apiKey,
          'Content-Type': 'application/json',
          'anthropic-version': '2023-06-01',
        },
      ));

      // Add interceptors for logging and error handling
      _client.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          print('🔍 Anthropic Request: ${options.method} ${options.path}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ Anthropic Response: ${response.statusCode}');
          handler.next(response);
        },
        onError: (error, handler) {
          print('❌ Anthropic Error: ${error.message}');
          handler.next(error);
        },
      ));

      _isInitialized = true;
      print('✅ Anthropic provider initialized successfully');
    } catch (e) {
      throw ProviderInitializationException(
        'Failed to initialize Anthropic provider: $e',
        providerId: id,
        originalError: e,
      );
    }
  }

  @override
  Future<bool> testConnection() async {
    if (!_isInitialized) await initialize();

    try {
      print('🔍 Testing Anthropic connection');
      
      // Anthropic doesn't have a dedicated health check endpoint,
      // so we'll make a minimal completion request
      final testRequest = ModelRequest(
        messages: [ModelMessage.user('Hi')],
        maxTokens: 1,
      );
      
      await complete(testRequest);
      
      print('✅ Anthropic connection test: SUCCESS');
      return true;
    } catch (e) {
      print('❌ Anthropic connection test failed: $e');
      return false;
    }
  }

  @override
  Future<ModelResponse> complete(ModelRequest request) async {
    if (!_isInitialized) await initialize();

    final startTime = DateTime.now();
    
    try {
      print('🤖 Anthropic completion request for model: ${request.model ?? ModelConstants.defaultClaudeModel}');
      
      final requestData = _buildCompletionRequest(request);
      final response = await _client.post('/v1/messages', data: requestData);
      
      if (response.statusCode != 200) {
        throw ModelCompletionException(
          'Anthropic API returned status ${response.statusCode}',
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
        'Anthropic completion failed: $e',
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
      print('🌊 Anthropic streaming request for model: ${request.model ?? ModelConstants.defaultClaudeModel}');
      
      final requestData = _buildCompletionRequest(request, stream: true);
      
      final response = await _client.post(
        '/v1/messages',
        data: requestData,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
        ),
      );

      if (response.statusCode != 200) {
        throw ModelCompletionException(
          'Anthropic streaming API returned status ${response.statusCode}',
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
        'Anthropic streaming failed: $e',
        providerId: id,
        modelId: request.model,
        request: request,
        originalError: e,
      );
    }
  }

  @override
  Future<List<double>> embed(String text) async {
    // Anthropic doesn't provide embedding models as of now
    throw ModelCompletionException(
      'Anthropic does not support embeddings',
      providerId: id,
    );
  }

  @override
  Future<List<ModelInfo>> getAvailableModels() async {
    // Anthropic doesn't have a models endpoint, return predefined models
    print('📋 Returning predefined Anthropic models');
    return _models.values.toList();
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
    
    print('🧹 Disposing Anthropic provider');
    _client.close();
    _isInitialized = false;
  }

  /// Build completion request payload
  Map<String, dynamic> _buildCompletionRequest(ModelRequest request, {bool stream = false}) {
    final messages = <Map<String, dynamic>>[];
    
    // Handle system prompt
    String? systemPrompt = request.systemPrompt;
    
    // Convert messages, extracting system messages
    for (final message in request.messages) {
      if (message.role == 'system') {
        systemPrompt = (systemPrompt ?? '') + message.content;
      } else {
        messages.add({
          'role': message.role,
          'content': message.content,
        });
      }
    }
    
    return {
      'model': request.model ?? ModelConstants.defaultClaudeModel,
      'messages': messages,
      'max_tokens': request.maxTokens,
      'temperature': request.temperature,
      'top_p': request.topP,
      'stream': stream,
      if (systemPrompt != null && systemPrompt.isNotEmpty) 'system': systemPrompt,
      if (request.stop != null) 'stop_sequences': request.stop,
    };
  }

  /// Parse completion response
  ModelResponse _parseCompletionResponse(
    Map<String, dynamic> data,
    String? modelId,
    Duration responseTime,
  ) {
    final content = data['content'] as List?;
    if (content == null || content.isEmpty) {
      throw ModelCompletionException(
        'No content returned from Anthropic',
        providerId: id,
        modelId: modelId,
      );
    }

    final textContent = content
        .where((item) => item['type'] == 'text')
        .map((item) => item['text'] as String)
        .join('');

    final finishReason = data['stop_reason'] as String?;

    final usageData = data['usage'] as Map<String, dynamic>?;
    final usage = usageData != null
        ? _parseUsage(usageData, modelId)
        : Usage.free();

    return ModelResponse(
      content: textContent,
      usage: usage,
      model: data['model'] as String?,
      finishReason: finishReason,
      responseTime: responseTime,
      metadata: {
        'provider': id,
        'stop_reason': finishReason,
        'content_blocks': content.length,
      },
    );
  }

  /// Parse streaming response
  Stream<String> _parseStreamingResponse(ResponseBody responseBody) async* {
    final stream = responseBody.stream;
    final buffer = StringBuffer();
    
    await for (final chunk in stream.cast<List<int>>().transform(utf8.decoder)) {
      buffer.write(chunk);
      final lines = buffer.toString().split('\n');
      
      // Keep the last potentially incomplete line in the buffer
      buffer.clear();
      if (lines.isNotEmpty && lines.last.isNotEmpty) {
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
            final type = json['type'] as String?;
            
            if (type == 'content_block_delta') {
              final delta = json['delta'] as Map<String, dynamic>?;
              final text = delta?['text'] as String?;
              
              if (text != null) {
                yield text;
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
    final inputTokens = usageData['input_tokens'] as int? ?? 0;
    final outputTokens = usageData['output_tokens'] as int? ?? 0;
    
    // Calculate cost based on model
    double inputCost = 0.0;
    double outputCost = 0.0;
    
    if (modelId != null && _models.containsKey(modelId)) {
      final model = _models[modelId]!;
      inputCost = inputTokens * model.capabilities.costPerInputToken / 1000;
      outputCost = outputTokens * model.capabilities.costPerOutputToken / 1000;
    }
    
    return Usage(
      promptTokens: inputTokens,
      completionTokens: outputTokens,
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
          'Anthropic connection timeout: ${error.message}',
          providerId: id,
          originalError: error,
        );
      
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final errorData = error.response?.data;
        
        if (statusCode == 429) {
          return QuotaExceededException(
            'Anthropic rate limit exceeded',
            providerId: id,
            originalError: error,
          );
        } else if (statusCode == 401) {
          return ProviderConnectionException(
            'Anthropic authentication failed - check API key',
            providerId: id,
            originalError: error,
          );
        } else if (statusCode == 400 && errorData != null) {
          final errorType = errorData['error']?['type'] as String?;
          final errorMessage = errorData['error']?['message'] as String?;
          
          return ModelCompletionException(
            'Anthropic API error ($errorType): ${errorMessage ?? error.message}',
            providerId: id,
            request: request,
            originalError: error,
          );
        } else {
          return ModelCompletionException(
            'Anthropic API error ($statusCode): ${error.message}',
            providerId: id,
            request: request,
            originalError: error,
          );
        }
      
      default:
        return ModelCompletionException(
          'Anthropic request failed: ${error.message}',
          providerId: id,
          request: request,
          originalError: error,
        );
    }
  }
}