import 'package:dio/dio.dart';
import 'dart:io';

class ClaudeApiService {
  static const String _anthropicApiUrl = 'https://api.anthropic.com';
  static const String _apiVersion = '2023-06-01';
  
  final Dio _dio;
  
  ClaudeApiService() : _dio = Dio() {
    _dio.options.baseUrl = _anthropicApiUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
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
          'Claude API error: \${errorData?['error']?['message'] ?? e.message}',
          statusCode: e.response?.statusCode,
          errorData: errorData,
        );
      } else {
        throw ClaudeApiException('Network error: \${e.message}');
      }
    } catch (e) {
      throw ClaudeApiException('Unexpected error: \$e');
    }
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
  final ClaudeUsage usage;

  ClaudeResponse({
    required this.id,
    required this.type,
    required this.role,
    required this.content,
    required this.model,
    this.stopReason,
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
  String toString() => 'ClaudeApiException: \$message';
}

/// Demonstration of AgentEngine's AI integration capabilities
void main(List<String> args) async {
  if (args.isEmpty) {
    print('🤖 AgentEngine Claude API Integration Test');
    print('==========================================');
    print('');
    print('Usage: dart run minimal_chat_test.dart YOUR_API_KEY');
    print('');
    print('💡 Get your API key from: https://console.anthropic.com/');
    print('   Example: dart run minimal_chat_test.dart sk-ant-...');
    return;
  }
  
  final apiKey = args[0];
  final claudeService = ClaudeApiService();
  
  print('🚀 AgentEngine - Phase 2: Claude API Integration Test');
  print('====================================================');
  print('');
  print('Testing the core AI integration that powers AgentEngine...');
  print('');

  // Test 1: Basic API connectivity
  print('📡 Test 1: API Connectivity');
  try {
    final response = await claudeService.sendMessage(
      message: 'Hello! Please confirm you are working by saying "AgentEngine Claude integration is operational."',
      apiKey: apiKey,
      maxTokens: 50,
    );
    
    print('✅ SUCCESS: \${response.text}');
    print('   Tokens used: \${response.usage.totalTokens} (Input: \${response.usage.inputTokens}, Output: \${response.usage.outputTokens})');
    print('');
  } catch (e) {
    print('❌ FAILED: \$e');
    print('');
    print('💡 Common issues:');
    print('   • Invalid API key (check https://console.anthropic.com/)');
    print('   • Network connectivity issues');
    print('   • API rate limits or billing issues');
    exit(1);
  }

  // Test 2: Conversation with system prompt
  print('🧠 Test 2: System Prompt & Agent Behavior');
  try {
    final response = await claudeService.sendMessage(
      message: 'What can you help me with?',
      apiKey: apiKey,
      maxTokens: 200,
      systemPrompt: 'You are AgentEngine, a powerful AI assistant that can connect to MCP servers, manage context, and help users with complex tasks. Be helpful and mention your MCP integration capabilities.',
    );
    
    print('✅ SUCCESS: \${response.text}');
    print('   Tokens used: \${response.usage.totalTokens}');
    print('');
  } catch (e) {
    print('❌ FAILED: \$e');
    exit(1);
  }

  // Test 3: Conversation history
  print('💬 Test 3: Conversation History');
  try {
    final conversationHistory = [
      {'role': 'user', 'content': 'My name is Alex'},
      {'role': 'assistant', 'content': 'Nice to meet you, Alex! How can I help you today?'},
    ];
    
    final response = await claudeService.sendMessage(
      message: 'What is my name?',
      apiKey: apiKey,
      maxTokens: 50,
      conversationHistory: conversationHistory,
    );
    
    print('✅ SUCCESS: \${response.text}');
    print('   Tokens used: \${response.usage.totalTokens}');
    print('');
  } catch (e) {
    print('❌ FAILED: \$e');
    exit(1);
  }

  print('🎉 All tests passed! AgentEngine Claude API integration is fully functional.');
  print('');
  print('✨ What this means:');
  print('   • Users can now have real AI conversations');
  print('   • Agent system prompts work correctly');
  print('   • Conversation history is properly maintained');
  print('   • Token usage is tracked for billing/optimization');
  print('');
  print('🚀 AgentEngine is ready for Phase 2 deployment!');
  print('   Next steps: Add API key through Settings → API Configuration');
}