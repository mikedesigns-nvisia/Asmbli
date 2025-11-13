import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mcp_settings_service.dart';

/// Service for making actual API calls to Claude/Anthropic API
class ClaudeApiService {
  static const String _anthropicApiUrl = 'https://api.anthropic.com';
  static const String _apiVersion = '2023-06-01';
  
  final Dio _dio;
  final MCPSettingsService _settingsService;
  
  ClaudeApiService(this._settingsService) : _dio = Dio() {
    _dio.options.baseUrl = _anthropicApiUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
  }

  /// Send a vision message with image to Claude API
  Future<ClaudeResponse> sendVisionMessage({
    required String message,
    required String base64Image,
    required String apiKey,
    String model = 'claude-3-5-sonnet-20241022',
    double temperature = 0.7,
    int maxTokens = 2048,
    String? systemPrompt,
    List<Map<String, dynamic>>? conversationHistory,
  }) async {
    try {
      // Build messages array from conversation history
      List<Map<String, dynamic>> messages = [];
      
      // Add conversation history if provided
      if (conversationHistory != null) {
        messages.addAll(conversationHistory);
      }
      
      // Add the new user message with image
      messages.add({
        'role': 'user',
        'content': [
          {
            'type': 'image',
            'source': {
              'type': 'base64',
              'media_type': 'image/png',
              'data': base64Image.split(',').last, // Remove data:image/png;base64, prefix
            }
          },
          {
            'type': 'text',
            'text': message,
          }
        ],
      });

      // Build request payload
      final requestData = {
        'model': model,
        'max_tokens': maxTokens,
        'temperature': temperature,
        'messages': messages,
      };

      // Add system prompt if provided
      if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
        requestData['system'] = systemPrompt;
      }

      // Make API call
      final response = await _dio.post(
        '/v1/messages',
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': _apiVersion,
          },
        ),
      );

      return ClaudeResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response?.data;
        throw ClaudeApiException(
          'Claude Vision API error: ${errorData?['error']?['message'] ?? e.message}',
          statusCode: e.response?.statusCode,
          errorData: errorData,
        );
      } else {
        throw ClaudeApiException('Network error: ${e.message}');
      }
    } catch (e) {
      throw ClaudeApiException('Unexpected error: $e');
    }
  }

  /// Send a message to Claude API and get response
  Future<ClaudeResponse> sendMessage({
    required String message,
    required String apiKey,
    String model = 'claude-3-5-sonnet-20241022',
    double temperature = 0.7,
    int maxTokens = 2048,
    String? systemPrompt,
    List<Map<String, dynamic>>? conversationHistory,
  }) async {
    try {
      // Build messages array from conversation history + new message
      List<Map<String, dynamic>> messages = [];
      
      // Add conversation history if provided
      if (conversationHistory != null) {
        messages.addAll(conversationHistory);
      }
      
      // Add the new user message
      messages.add({
        'role': 'user',
        'content': message,
      });

      // Build request payload
      final requestData = {
        'model': model,
        'max_tokens': maxTokens,
        'temperature': temperature,
        'messages': messages,
      };

      // Add system prompt if provided
      if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
        requestData['system'] = systemPrompt;
      }

      // Make API call
      final response = await _dio.post(
        '/v1/messages',
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': _apiVersion,
          },
        ),
      );

      return ClaudeResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response?.data;
        throw ClaudeApiException(
          'Claude API error: ${errorData?['error']?['message'] ?? e.message}',
          statusCode: e.response?.statusCode,
          errorData: errorData,
        );
      } else {
        throw ClaudeApiException('Network error: ${e.message}');
      }
    } catch (e) {
      throw ClaudeApiException('Unexpected error: $e');
    }
  }

  /// Stream a message to Claude API for real-time responses
  Stream<String> streamMessage({
    required String message,
    required String apiKey,
    String model = 'claude-3-5-sonnet-20241022',
    double temperature = 0.7,
    int maxTokens = 2048,
    String? systemPrompt,
    List<Map<String, dynamic>>? conversationHistory,
  }) async* {
    try {
      // Build messages array
      List<Map<String, dynamic>> messages = [];
      
      if (conversationHistory != null) {
        messages.addAll(conversationHistory);
      }
      
      messages.add({
        'role': 'user',
        'content': message,
      });

      // Build request payload for streaming
      final requestData = {
        'model': model,
        'max_tokens': maxTokens,
        'temperature': temperature,
        'messages': messages,
        'stream': true, // Enable streaming
      };

      if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
        requestData['system'] = systemPrompt;
      }

      // Make streaming API call
      final response = await _dio.post(
        '/v1/messages',
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': _apiVersion,
            'Accept': 'text/event-stream',
          },
          responseType: ResponseType.stream,
        ),
      );

      // Parse SSE stream
      await for (final chunk in _parseSSEStream(response.data)) {
        yield chunk;
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response?.data;
        throw ClaudeApiException(
          'Claude API error: ${errorData?['error']?['message'] ?? e.message}',
          statusCode: e.response?.statusCode,
          errorData: errorData,
        );
      } else {
        throw ClaudeApiException('Network error: ${e.message}');
      }
    } catch (e) {
      throw ClaudeApiException('Unexpected error: $e');
    }
  }

  /// Parse Server-Sent Events stream from Claude API
  Stream<String> _parseSSEStream(Stream<List<int>> stream) async* {
    String buffer = '';
    
    await for (final chunk in stream) {
      buffer += utf8.decode(chunk);
      final lines = buffer.split('\n');
      
      // Keep the last incomplete line in buffer
      buffer = lines.removeLast();
      
      for (final line in lines) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          
          if (data == '[DONE]') {
            return;
          }
          
          try {
            final jsonData = json.decode(data);
            final delta = jsonData['delta'];
            
            if (delta != null && delta['text'] != null) {
              yield delta['text'] as String;
            }
          } catch (e) {
            // Skip malformed JSON
            continue;
          }
        }
      }
    }
  }

  /// Test API key validity
  Future<bool> testApiKey(String apiKey) async {
    try {
      await sendMessage(
        message: 'Hello',
        apiKey: apiKey,
        maxTokens: 10,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get available models (static list for now)
  List<String> getAvailableModels() {
    return [
      'claude-3-5-sonnet-20241022',
      'claude-3-5-sonnet-20240620',
      'claude-3-5-haiku-20241022',
      'claude-3-opus-20240229',
      'claude-3-sonnet-20240229',
      'claude-3-haiku-20240307',
    ];
  }
}

/// Response from Claude API
class ClaudeResponse {
  final String id;
  final String type;
  final String role;
  final List<ClaudeContent> content;
  final String model;
  final String? stopReason;
  final String? stopSequence;
  final ClaudeUsage usage;

  ClaudeResponse({
    required this.id,
    required this.type,
    required this.role,
    required this.content,
    required this.model,
    this.stopReason,
    this.stopSequence,
    required this.usage,
  });

  factory ClaudeResponse.fromJson(Map<String, dynamic> json) {
    return ClaudeResponse(
      id: json['id'] as String,
      type: json['type'] as String,
      role: json['role'] as String,
      content: (json['content'] as List)
          .map((item) => ClaudeContent.fromJson(item))
          .toList(),
      model: json['model'] as String,
      stopReason: json['stop_reason'] as String?,
      stopSequence: json['stop_sequence'] as String?,
      usage: ClaudeUsage.fromJson(json['usage']),
    );
  }

  /// Get the text content from the response
  String get text {
    return content
        .where((item) => item.type == 'text')
        .map((item) => item.text)
        .join('');
  }
}

/// Content item from Claude response
class ClaudeContent {
  final String type;
  final String text;

  ClaudeContent({
    required this.type,
    required this.text,
  });

  factory ClaudeContent.fromJson(Map<String, dynamic> json) {
    return ClaudeContent(
      type: json['type'] as String,
      text: json['text'] as String,
    );
  }
}

/// Usage statistics from Claude API
class ClaudeUsage {
  final int inputTokens;
  final int outputTokens;

  ClaudeUsage({
    required this.inputTokens,
    required this.outputTokens,
  });

  factory ClaudeUsage.fromJson(Map<String, dynamic> json) {
    return ClaudeUsage(
      inputTokens: json['input_tokens'] as int,
      outputTokens: json['output_tokens'] as int,
    );
  }

  int get totalTokens => inputTokens + outputTokens;
}

/// Exception thrown by Claude API service
class ClaudeApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errorData;

  ClaudeApiException(this.message, {this.statusCode, this.errorData});

  @override
  String toString() => 'ClaudeApiException: $message';
}

// Riverpod provider for Claude API service
final claudeApiServiceProvider = Provider<ClaudeApiService>((ref) {
  final settingsService = ref.read(mcpSettingsServiceProvider);
  return ClaudeApiService(settingsService);
});