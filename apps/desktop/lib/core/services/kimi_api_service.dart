import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'openai_api_service.dart'; // For reusing response structure patterns

/// Service for making API calls to Moonshot AI (Kimi)
class KimiApiService {
  static const String _kimiApiUrl = 'https://api.moonshot.cn';
  
  final Dio _dio;
  
  KimiApiService() : _dio = Dio() {
    _dio.options.baseUrl = _kimiApiUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
  }

  /// Send a message to Kimi API
  Future<KimiResponse> sendMessage({
    required String message,
    required String apiKey,
    String model = 'moonshot-v1-8k',
    double temperature = 0.3,
    int maxTokens = 2048,
    String? systemPrompt,
    List<Map<String, dynamic>>? conversationHistory,
  }) async {
    try {
      // Build messages array
      List<Map<String, dynamic>> messages = [];

      // Add system message if provided
      if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
        messages.add({
          'role': 'system',
          'content': systemPrompt,
        });
      }

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
        'messages': messages,
        'temperature': temperature,
        'max_tokens': maxTokens,
      };

      // Make API call
      final response = await _dio.post(
        '/v1/chat/completions',
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
        ),
      );

      return KimiResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response?.data;
        throw KimiApiException(
          'Kimi API error: ${errorData?['error']?['message'] ?? e.message}',
          statusCode: e.response?.statusCode,
          errorData: errorData,
        );
      } else {
        throw KimiApiException('Network error: ${e.message}');
      }
    } catch (e) {
      throw KimiApiException('Unexpected error: $e');
    }
  }

  /// Stream a message from Kimi API
  Stream<String> streamMessage({
    required String message,
    required String apiKey,
    String model = 'moonshot-v1-8k',
    double temperature = 0.3,
    int maxTokens = 2048,
    String? systemPrompt,
    List<Map<String, dynamic>>? conversationHistory,
  }) async* {
    try {
      // Build messages array
      List<Map<String, dynamic>> messages = [];

      if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
        messages.add({
          'role': 'system',
          'content': systemPrompt,
        });
      }

      if (conversationHistory != null) {
        messages.addAll(conversationHistory);
      }

      messages.add({
        'role': 'user',
        'content': message,
      });

      final requestData = {
        'model': model,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': maxTokens,
        'stream': true,
      };

      final response = await _dio.post(
        '/v1/chat/completions',
        data: requestData,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
            'Accept': 'text/event-stream',
          },
        ),
      );

      final stream = response.data.stream;
      
      await for (final chunk in stream) {
        final String chunkStr = utf8.decode(chunk);
        final lines = chunkStr.split('\n').where((line) => line.trim().isNotEmpty);
        
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') continue;
            
            try {
              final json = jsonDecode(data);
              final choices = json['choices'] as List;
              if (choices.isNotEmpty) {
                final delta = choices[0]['delta'];
                if (delta.containsKey('content')) {
                  final content = delta['content'] as String?;
                  if (content != null && content.isNotEmpty) {
                    yield content;
                  }
                }
              }
            } catch (e) {
              // Ignore parse errors
            }
          }
        }
      }
    } catch (e) {
      if (e is DioException) {
        throw KimiApiException('Kimi streaming error: ${e.message}');
      }
      throw KimiApiException('Unexpected streaming error: $e');
    }
  }

  /// Test API key validity
  Future<bool> testApiKey(String apiKey) async {
    try {
      await sendMessage(
        message: 'Hello, this is a test.',
        apiKey: apiKey,
        model: 'moonshot-v1-8k',
        maxTokens: 10,
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Kimi API response model (similar to OpenAI format)
class KimiResponse {
  final String id;
  final String object;
  final int created;
  final String model;
  final List<KimiChoice> choices;
  final KimiUsage usage;

  KimiResponse({
    required this.id,
    required this.object,
    required this.created,
    required this.model,
    required this.choices,
    required this.usage,
  });

  factory KimiResponse.fromJson(Map<String, dynamic> json) {
    return KimiResponse(
      id: json['id'] ?? '',
      object: json['object'] ?? '',
      created: json['created'] ?? 0,
      model: json['model'] ?? '',
      choices: (json['choices'] as List<dynamic>?)
          ?.map((choice) => KimiChoice.fromJson(choice))
          .toList() ?? [],
      usage: KimiUsage.fromJson(json['usage'] ?? {}),
    );
  }

  String get content => choices.isNotEmpty ? choices.first.message.content : '';
}

class KimiChoice {
  final int index;
  final KimiMessage message;
  final String? finishReason;

  KimiChoice({
    required this.index,
    required this.message,
    this.finishReason,
  });

  factory KimiChoice.fromJson(Map<String, dynamic> json) {
    return KimiChoice(
      index: json['index'] ?? 0,
      message: KimiMessage.fromJson(json['message'] ?? {}),
      finishReason: json['finish_reason'],
    );
  }
}

class KimiMessage {
  final String role;
  final String content;

  KimiMessage({
    required this.role,
    required this.content,
  });

  factory KimiMessage.fromJson(Map<String, dynamic> json) {
    return KimiMessage(
      role: json['role'] ?? '',
      content: json['content'] ?? '',
    );
  }
}

class KimiUsage {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  KimiUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  factory KimiUsage.fromJson(Map<String, dynamic> json) {
    return KimiUsage(
      promptTokens: json['prompt_tokens'] ?? 0,
      completionTokens: json['completion_tokens'] ?? 0,
      totalTokens: json['total_tokens'] ?? 0,
    );
  }
}

/// Kimi API exception
class KimiApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errorData;

  KimiApiException(
    this.message, {
    this.statusCode,
    this.errorData,
  });

  @override
  String toString() => 'KimiApiException: $message';
}

/// Riverpod provider for Kimi API service
final kimiApiServiceProvider = Provider<KimiApiService>((ref) {
  return KimiApiService();
});