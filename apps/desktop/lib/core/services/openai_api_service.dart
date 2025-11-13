import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'claude_api_service.dart'; // For reusing response models

/// Service for making API calls to OpenAI GPT-4V
class OpenAIApiService {
  static const String _openaiApiUrl = 'https://api.openai.com';
  
  final Dio _dio;
  
  OpenAIApiService() : _dio = Dio() {
    _dio.options.baseUrl = _openaiApiUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
  }

  /// Send a vision message with image to GPT-4V API
  Future<OpenAIResponse> sendVisionMessage({
    required String message,
    required String base64Image,
    required String apiKey,
    String model = 'gpt-4-vision-preview',
    double temperature = 0.7,
    int maxTokens = 2048,
    String? systemPrompt,
    List<Map<String, dynamic>>? conversationHistory,
  }) async {
    try {
      // Build messages array from conversation history
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
      
      // Add the new user message with image
      messages.add({
        'role': 'user',
        'content': [
          {
            'type': 'text',
            'text': message,
          },
          {
            'type': 'image_url',
            'image_url': {
              'url': base64Image.startsWith('data:') 
                ? base64Image 
                : 'data:image/png;base64,${base64Image.split(',').last}',
            }
          }
        ],
      });

      // Build request payload
      final requestData = {
        'model': model,
        'messages': messages,
        'max_tokens': maxTokens,
        'temperature': temperature,
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

      return OpenAIResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response?.data;
        throw OpenAIApiException(
          'OpenAI Vision API error: ${errorData?['error']?['message'] ?? e.message}',
          statusCode: e.response?.statusCode,
          errorData: errorData,
        );
      } else {
        throw OpenAIApiException('Network error: ${e.message}');
      }
    } catch (e) {
      throw OpenAIApiException('Unexpected error: $e');
    }
  }

  /// Send a regular message to GPT models
  Future<OpenAIResponse> sendMessage({
    required String message,
    required String apiKey,
    String model = 'gpt-4',
    double temperature = 0.7,
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
        'max_tokens': maxTokens,
        'temperature': temperature,
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

      return OpenAIResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response?.data;
        throw OpenAIApiException(
          'OpenAI API error: ${errorData?['error']?['message'] ?? e.message}',
          statusCode: e.response?.statusCode,
          errorData: errorData,
        );
      } else {
        throw OpenAIApiException('Network error: ${e.message}');
      }
    } catch (e) {
      throw OpenAIApiException('Unexpected error: $e');
    }
  }

  /// Test API key validity
  Future<bool> testApiKey(String apiKey) async {
    try {
      await sendMessage(
        message: 'Hello, this is a test.',
        apiKey: apiKey,
        model: 'gpt-3.5-turbo', // Use cheaper model for testing
        maxTokens: 10,
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// OpenAI API response model
class OpenAIResponse {
  final String id;
  final String object;
  final int created;
  final String model;
  final List<OpenAIChoice> choices;
  final OpenAIUsage usage;

  OpenAIResponse({
    required this.id,
    required this.object,
    required this.created,
    required this.model,
    required this.choices,
    required this.usage,
  });

  factory OpenAIResponse.fromJson(Map<String, dynamic> json) {
    return OpenAIResponse(
      id: json['id'] ?? '',
      object: json['object'] ?? '',
      created: json['created'] ?? 0,
      model: json['model'] ?? '',
      choices: (json['choices'] as List<dynamic>?)
          ?.map((choice) => OpenAIChoice.fromJson(choice))
          .toList() ?? [],
      usage: OpenAIUsage.fromJson(json['usage'] ?? {}),
    );
  }

  String get content => choices.isNotEmpty ? choices.first.message.content : '';
}

class OpenAIChoice {
  final int index;
  final OpenAIMessage message;
  final String? finishReason;

  OpenAIChoice({
    required this.index,
    required this.message,
    this.finishReason,
  });

  factory OpenAIChoice.fromJson(Map<String, dynamic> json) {
    return OpenAIChoice(
      index: json['index'] ?? 0,
      message: OpenAIMessage.fromJson(json['message'] ?? {}),
      finishReason: json['finish_reason'],
    );
  }
}

class OpenAIMessage {
  final String role;
  final String content;

  OpenAIMessage({
    required this.role,
    required this.content,
  });

  factory OpenAIMessage.fromJson(Map<String, dynamic> json) {
    return OpenAIMessage(
      role: json['role'] ?? '',
      content: json['content'] ?? '',
    );
  }
}

class OpenAIUsage {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  OpenAIUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  factory OpenAIUsage.fromJson(Map<String, dynamic> json) {
    return OpenAIUsage(
      promptTokens: json['prompt_tokens'] ?? 0,
      completionTokens: json['completion_tokens'] ?? 0,
      totalTokens: json['total_tokens'] ?? 0,
    );
  }
}

/// OpenAI API exception
class OpenAIApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errorData;

  OpenAIApiException(
    this.message, {
    this.statusCode,
    this.errorData,
  });

  @override
  String toString() => 'OpenAIApiException: $message';
}

/// Riverpod provider for OpenAI API service
final openaiApiServiceProvider = Provider<OpenAIApiService>((ref) {
  return OpenAIApiService();
});