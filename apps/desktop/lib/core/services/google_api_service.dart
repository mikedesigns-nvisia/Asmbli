import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'openai_api_service.dart'; // For reusing response models

/// Service for making API calls to Google Gemini
class GoogleApiService {
  static const String _googleApiUrl = 'https://generativelanguage.googleapis.com';
  
  final Dio _dio;
  
  GoogleApiService() : _dio = Dio() {
    _dio.options.baseUrl = _googleApiUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
  }

  /// Send a vision message with image to Gemini API
  Future<GoogleResponse> sendVisionMessage({
    required String message,
    required String base64Image,
    required String apiKey,
    String model = 'gemini-pro-vision',
    double temperature = 0.7,
    int maxTokens = 2048,
    String? systemPrompt,
    List<Map<String, dynamic>>? conversationHistory,
  }) async {
    try {
      // Build the request parts
      List<Map<String, dynamic>> parts = [
        {
          'text': systemPrompt != null && systemPrompt.trim().isNotEmpty
              ? '$systemPrompt\n\n$message'
              : message,
        },
        {
          'inline_data': {
            'mime_type': 'image/png',
            'data': base64Image.startsWith('data:') 
                ? base64Image.split(',').last
                : base64Image,
          }
        }
      ];

      // Add conversation history if provided
      if (conversationHistory != null && conversationHistory.isNotEmpty) {
        final contextParts = conversationHistory.map((msg) => {
          'text': '${msg['role']}: ${msg['content']}'
        }).toList();
        parts.insertAll(0, contextParts);
      }

      // Build request payload
      final requestData = {
        'contents': [
          {
            'parts': parts,
          }
        ],
        'generationConfig': {
          'temperature': temperature,
          'maxOutputTokens': maxTokens,
        }
      };

      // Make API call
      final response = await _dio.post(
        '/v1/models/$model:generateContent',
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
        ),
      );

      return GoogleResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response?.data;
        throw GoogleApiException(
          'Google Gemini Vision API error: ${errorData?['error']?['message'] ?? e.message}',
          statusCode: e.response?.statusCode,
          errorData: errorData,
        );
      } else {
        throw GoogleApiException('Network error: ${e.message}');
      }
    } catch (e) {
      throw GoogleApiException('Unexpected error: $e');
    }
  }

  /// Send a regular message to Gemini models
  Future<GoogleResponse> sendMessage({
    required String message,
    required String apiKey,
    String model = 'gemini-pro',
    double temperature = 0.7,
    int maxTokens = 2048,
    String? systemPrompt,
    List<Map<String, dynamic>>? conversationHistory,
  }) async {
    try {
      // Build the request parts
      List<Map<String, dynamic>> parts = [
        {
          'text': systemPrompt != null && systemPrompt.trim().isNotEmpty
              ? '$systemPrompt\n\n$message'
              : message,
        }
      ];

      // Add conversation history if provided
      if (conversationHistory != null && conversationHistory.isNotEmpty) {
        final contextParts = conversationHistory.map((msg) => {
          'text': '${msg['role']}: ${msg['content']}'
        }).toList();
        parts.insertAll(0, contextParts);
      }

      // Build request payload
      final requestData = {
        'contents': [
          {
            'parts': parts,
          }
        ],
        'generationConfig': {
          'temperature': temperature,
          'maxOutputTokens': maxTokens,
        }
      };

      // Make API call
      final response = await _dio.post(
        '/v1/models/$model:generateContent',
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
        ),
      );

      return GoogleResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response?.data;
        throw GoogleApiException(
          'Google Gemini API error: ${errorData?['error']?['message'] ?? e.message}',
          statusCode: e.response?.statusCode,
          errorData: errorData,
        );
      } else {
        throw GoogleApiException('Network error: ${e.message}');
      }
    } catch (e) {
      throw GoogleApiException('Unexpected error: $e');
    }
  }

  /// Stream a message from Gemini API
  Stream<String> streamMessage({
    required String message,
    required String apiKey,
    String model = 'gemini-pro',
    double temperature = 0.7,
    int maxTokens = 2048,
    String? systemPrompt,
    List<Map<String, dynamic>>? conversationHistory,
  }) async* {
    try {
      // Build the request parts
      List<Map<String, dynamic>> parts = [
        {
          'text': systemPrompt != null && systemPrompt.trim().isNotEmpty
              ? '$systemPrompt\n\n$message'
              : message,
        }
      ];

      if (conversationHistory != null && conversationHistory.isNotEmpty) {
        final contextParts = conversationHistory.map((msg) => {
          'text': '${msg['role']}: ${msg['content']}'
        }).toList();
        parts.insertAll(0, contextParts);
      }

      final requestData = {
        'contents': [
          {
            'parts': parts,
          }
        ],
        'generationConfig': {
          'temperature': temperature,
          'maxOutputTokens': maxTokens,
        }
      };

      final response = await _dio.post(
        '/v1/models/$model:streamGenerateContent',
        data: requestData,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
        ),
      );

      final stream = response.data.stream;
      StringBuffer buffer = StringBuffer();
      int openBraces = 0;
      bool inString = false;
      bool escaped = false;

      await for (final chunk in stream.transform(utf8.decoder)) {
        final String chunkStr = chunk;
        
        for (int i = 0; i < chunkStr.length; i++) {
          final char = chunkStr[i];
          buffer.write(char);
          
          if (escaped) {
            escaped = false;
            continue;
          }
          
          if (char == '\\') {
            escaped = true;
            continue;
          }
          
          if (char == '"') {
            inString = !inString;
            continue;
          }
          
          if (!inString) {
            if (char == '{') {
              openBraces++;
            } else if (char == '}') {
              openBraces--;
              
              if (openBraces == 0 && buffer.toString().trim().startsWith('{')) {
                // Found a complete JSON object
                final jsonStr = buffer.toString().trim();
                try {
                  final json = jsonDecode(jsonStr);
                  final candidates = json['candidates'] as List?;
                  if (candidates != null && candidates.isNotEmpty) {
                    final content = candidates[0]['content'];
                    if (content != null) {
                      final parts = content['parts'] as List?;
                      if (parts != null && parts.isNotEmpty) {
                        final text = parts[0]['text'] as String?;
                        if (text != null) {
                          yield text;
                        }
                      }
                    }
                  }
                } catch (e) {
                  // Ignore parse errors
                }
                buffer.clear();
              }
            } else if (char == '[' && buffer.length < 5) {
              // Ignore starting bracket of the array
              buffer.clear();
            } else if (char == ',' && openBraces == 0) {
              // Ignore comma separators between objects
              buffer.clear();
            } else if (char == ']' && openBraces == 0) {
              // End of array
              buffer.clear();
            }
          }
        }
      }
    } catch (e) {
      if (e is DioException) {
        throw GoogleApiException('Google Gemini streaming error: ${e.message}');
      }
      throw GoogleApiException('Unexpected streaming error: $e');
    }
  }

  /// Test API key validity
  Future<bool> testApiKey(String apiKey) async {
    try {
      await sendMessage(
        message: 'Hello, this is a test.',
        apiKey: apiKey,
        model: 'gemini-pro',
        maxTokens: 10,
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Google API response model
class GoogleResponse {
  final List<GoogleCandidate> candidates;
  final GoogleUsageMetadata? usageMetadata;

  GoogleResponse({
    required this.candidates,
    this.usageMetadata,
  });

  factory GoogleResponse.fromJson(Map<String, dynamic> json) {
    return GoogleResponse(
      candidates: (json['candidates'] as List<dynamic>?)
          ?.map((candidate) => GoogleCandidate.fromJson(candidate))
          .toList() ?? [],
      usageMetadata: json['usageMetadata'] != null
          ? GoogleUsageMetadata.fromJson(json['usageMetadata'])
          : null,
    );
  }

  String get content => candidates.isNotEmpty 
      ? candidates.first.content.parts.map((p) => p.text).join(' ')
      : '';
  String get model => 'gemini'; // Gemini doesn't return model name in response
}

class GoogleCandidate {
  final GoogleContent content;
  final String? finishReason;
  final int index;

  GoogleCandidate({
    required this.content,
    this.finishReason,
    required this.index,
  });

  factory GoogleCandidate.fromJson(Map<String, dynamic> json) {
    return GoogleCandidate(
      content: GoogleContent.fromJson(json['content'] ?? {}),
      finishReason: json['finishReason'],
      index: json['index'] ?? 0,
    );
  }
}

class GoogleContent {
  final List<GooglePart> parts;
  final String role;

  GoogleContent({
    required this.parts,
    required this.role,
  });

  factory GoogleContent.fromJson(Map<String, dynamic> json) {
    return GoogleContent(
      parts: (json['parts'] as List<dynamic>?)
          ?.map((part) => GooglePart.fromJson(part))
          .toList() ?? [],
      role: json['role'] ?? 'model',
    );
  }
}

class GooglePart {
  final String text;

  GooglePart({
    required this.text,
  });

  factory GooglePart.fromJson(Map<String, dynamic> json) {
    return GooglePart(
      text: json['text'] ?? '',
    );
  }
}

class GoogleUsageMetadata {
  final int promptTokenCount;
  final int candidatesTokenCount;
  final int totalTokenCount;

  GoogleUsageMetadata({
    required this.promptTokenCount,
    required this.candidatesTokenCount,
    required this.totalTokenCount,
  });

  factory GoogleUsageMetadata.fromJson(Map<String, dynamic> json) {
    return GoogleUsageMetadata(
      promptTokenCount: json['promptTokenCount'] ?? 0,
      candidatesTokenCount: json['candidatesTokenCount'] ?? 0,
      totalTokenCount: json['totalTokenCount'] ?? 0,
    );
  }
}

/// Google API exception
class GoogleApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errorData;

  GoogleApiException(
    this.message, {
    this.statusCode,
    this.errorData,
  });

  @override
  String toString() => 'GoogleApiException: $message';
}

/// Riverpod provider for Google API service
final googleApiServiceProvider = Provider<GoogleApiService>((ref) {
  return GoogleApiService();
});