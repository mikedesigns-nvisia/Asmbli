import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../di/service_locator.dart';
import 'desktop/desktop_storage_service.dart';

/// Service for OpenAI Vision API integration to generate code from wireframes
class OpenAIVisionService {
  static const String _baseUrl = 'https://api.openai.com/v1';
  late final DesktopStorageService _storageService;

  OpenAIVisionService() {
    _storageService = ServiceLocator.instance.get<DesktopStorageService>();
  }

  /// Get OpenAI API key from storage
  String? _getApiKey() {
    return _storageService.getPreference<String>('openai_api_key');
  }

  /// Generate HTML/CSS code from wireframe image
  Future<String> generateCodeFromWireframe(
    String base64Image, {
    String prompt = 'Generate clean, responsive HTML and CSS code for this wireframe',
  }) async {
    final apiKey = _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OpenAI API key not configured. Please add your API key in settings.');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o', // Updated to use gpt-4o instead of deprecated gpt-4-vision-preview
          'messages': [
            {
              'role': 'system',
              'content': '''You are an expert front-end developer. Generate clean, modern HTML and CSS code from wireframe images.

Requirements:
- Use semantic HTML5 elements
- Create responsive design with mobile-first approach
- Use modern CSS features (flexbox, grid, custom properties)
- Include proper accessibility attributes
- Use clean, readable code structure
- Add helpful comments
- Make it production-ready

Output format: Provide complete HTML file with embedded CSS in <style> tags.'''
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': prompt,
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/png;base64,$base64Image',
                    'detail': 'high',
                  },
                },
              ],
            },
          ],
          'max_tokens': 4000,
          'temperature': 0.1, // Low temperature for consistent code generation
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        
        // Extract code from markdown if present
        return _extractCodeFromResponse(content);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('OpenAI API error: ${errorData['error']['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      if (e.toString().contains('API key')) {
        rethrow;
      }
      throw Exception('Failed to generate code: $e');
    }
  }

  /// Extract code from markdown response
  String _extractCodeFromResponse(String response) {
    // Look for HTML code blocks
    final htmlRegex = RegExp(r'```html\s*(.*?)\s*```', dotAll: true);
    final htmlMatch = htmlRegex.firstMatch(response);
    
    if (htmlMatch != null) {
      return htmlMatch.group(1)?.trim() ?? response;
    }

    // Look for general code blocks
    final codeRegex = RegExp(r'```\s*(.*?)\s*```', dotAll: true);
    final codeMatch = codeRegex.firstMatch(response);
    
    if (codeMatch != null) {
      return codeMatch.group(1)?.trim() ?? response;
    }

    // Return as-is if no code blocks found
    return response.trim();
  }

  /// Analyze wireframe and provide design suggestions
  Future<String> analyzeWireframe(String base64Image) async {
    return generateCodeFromWireframe(
      base64Image,
      prompt: '''Analyze this wireframe and provide design recommendations:
      
1. Identify UI components and their purposes
2. Suggest improvements for user experience
3. Recommend responsive design considerations
4. Point out accessibility concerns
5. Suggest modern design patterns that could enhance this layout

Provide actionable insights for improving this design.''',
    );
  }

  /// Check if service is properly configured
  bool isConfigured() {
    final apiKey = _getApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// Save API key to storage
  Future<void> saveApiKey(String apiKey) async {
    await _storageService.setPreference('openai_api_key', apiKey.trim());
  }

  /// Remove API key from storage
  Future<void> removeApiKey() async {
    await _storageService.removePreference('openai_api_key');
  }
}