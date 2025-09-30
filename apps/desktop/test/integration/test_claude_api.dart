import 'dart:io';
import 'package:dio/dio.dart';

/// Quick test to verify Claude API integration is working
/// Usage: dart run test_claude_api.dart YOUR_API_KEY
void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run test_claude_api.dart YOUR_API_KEY');
    print('Get your API key from: https://console.anthropic.com/');
    return;
  }
  
  final apiKey = args[0];
  print('🤖 Testing Claude API integration...\n');
  
  try {
    final dio = Dio();
    dio.options.baseUrl = 'https://api.anthropic.com';
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 60);

    final response = await dio.post(
      '/v1/messages',
      data: {
        'model': 'claude-3-5-sonnet-20241022',
        'max_tokens': 100,
        'messages': [
          {
            'role': 'user',
            'content': 'Hello! Please respond with "Claude API is working!" to confirm the connection.'
          }
        ],
      },
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
      ),
    );

    final content = response.data['content'][0]['text'];
    print('✅ SUCCESS: ${content}');
    print('\n🎉 Claude API integration is fully functional!');
    print('\nAgent Engine is ready for real AI conversations.');
    
  } catch (e) {
    if (e is DioException) {
      if (e.response != null) {
        final errorData = e.response?.data;
        print('❌ API Error: ${errorData?['error']?['message'] ?? e.message}');
        
        if (e.response?.statusCode == 401) {
          print('\n💡 This usually means:');
          print('   • Invalid API key');
          print('   • API key doesn\'t have the required permissions');
          print('   • Check your API key at https://console.anthropic.com/');
        }
      } else {
        print('❌ Network Error: ${e.message}');
        print('\n💡 Check your internet connection and try again.');
      }
    } else {
      print('❌ Unexpected Error: $e');
    }
    exit(1);
  }
}