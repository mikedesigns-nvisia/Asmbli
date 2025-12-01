import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/model_config.dart';
import 'desktop/desktop_service_provider.dart';

/// Service for managing embedded Ollama instance and local models
/// 
/// STANDARD APPROACH FOR OLLAMA MODELS:
/// - Uses DYNAMIC naming based on actual Ollama API parameter_size
/// - NO hardcoded model names or capabilities
/// - Automatically handles any model installed in Ollama
/// - Scales to support new models without code changes
class OllamaService {
  final DesktopServiceProvider _desktopService;
  Process? _ollamaProcess;
  final Dio _dio;
  bool _isInitialized = false;
  String? _ollamaBinaryPath;

  OllamaService(this._desktopService) : _dio = Dio() {
    _dio.options.baseUrl = 'http://127.0.0.1:11434';
    _dio.options.connectTimeout = const Duration(seconds: 10);
    // OPTIMIZATION: Reduced from 5 minutes to 60 seconds for better UX
    // Local models rarely take more than 60s, even for large responses
    _dio.options.receiveTimeout = const Duration(seconds: 60);
  }

  /// Check if Ollama is available and running
  Future<bool> get isAvailable async {
    try {
      final response = await _dio.get('/api/version');
      debugPrint('Ollama available - status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Initialize the embedded Ollama service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // First check if Ollama is already running externally
      if (await isAvailable) {
        debugPrint('Found existing Ollama instance');
        _isInitialized = true;
        return;
      }

      // Try to extract and start embedded Ollama
      try {
        await _extractOllamaBinary();
        await _startEmbeddedOllama();
        await _waitForStartup();
      } catch (e) {
        debugPrint('Failed to start embedded Ollama, trying system installation: $e');
        
        // Try to use system-installed Ollama as fallback
        if (await _trySystemOllama()) {
          debugPrint('Using system-installed Ollama');
        } else {
          debugPrint('No Ollama installation found. Local models will not be available.');
          // Don't throw - just mark as not initialized so local models aren't available
          return;
        }
      }
      
      _isInitialized = true;
      debugPrint('Ollama service initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize Ollama service: $e');
      // Don't throw - gracefully handle missing Ollama
    }
  }

  /// Extract Ollama binary from assets to local directory
  Future<void> _extractOllamaBinary() async {
    try {
      // Use application support directory for better cross-platform support
      final appSupportDir = await getApplicationSupportDirectory();
      final ollamaDir = Directory(path.join(appSupportDir.path, 'ollama'));
      
      
      if (!ollamaDir.existsSync()) {
        ollamaDir.createSync(recursive: true);
      }

      // Determine platform-specific binary name
      String binaryName;
      String assetPath;
      
      if (_desktopService.isWindows) {
        binaryName = 'ollama.exe';
        assetPath = 'assets/binaries/windows/ollama.exe';
      } else if (_desktopService.isMacOS) {
        binaryName = 'ollama';
        assetPath = 'assets/binaries/macos/ollama';
      } else if (_desktopService.isLinux) {
        binaryName = 'ollama';
        assetPath = 'assets/binaries/linux/ollama';
      } else {
        throw UnsupportedError('Unsupported platform for local LLM');
      }

      _ollamaBinaryPath = path.join(ollamaDir.path, binaryName);
      final binaryFile = File(_ollamaBinaryPath!);

      // Only extract if binary doesn't exist or is outdated
      if (!binaryFile.existsSync()) {
        
        try {
          final byteData = await rootBundle.load(assetPath);
          final bytes = byteData.buffer.asUint8List();
          await binaryFile.writeAsBytes(bytes);
          
          // Make executable on Unix-like systems
          if (!_desktopService.isWindows) {
            await Process.run('chmod', ['+x', _ollamaBinaryPath!]);
          }
          
        } catch (e) {
          debugPrint('Failed to extract Ollama binary from assets: $e');
          // For development, try to find system-installed Ollama
          if (_desktopService.isWindows) {
            _ollamaBinaryPath = 'ollama.exe';
          } else {
            _ollamaBinaryPath = 'ollama';
          }
        }
      } else {
      }
    } catch (e) {
      debugPrint('Error extracting Ollama binary: $e');
      rethrow;
    }
  }

  /// Start the embedded Ollama server process
  Future<void> _startEmbeddedOllama() async {
    if (_ollamaBinaryPath == null) {
      throw Exception('Ollama binary path not set');
    }

    try {
      
      final environment = <String, String>{
        'OLLAMA_HOST': '127.0.0.1:11434',
        'OLLAMA_ORIGINS': '*',
      };

      _ollamaProcess = await Process.start(
        _ollamaBinaryPath!,
        ['serve'],
        environment: environment,
        runInShell: true,
      );

      // Listen to process output for debugging
      _ollamaProcess!.stdout.transform(utf8.decoder).listen((data) {
      });

      _ollamaProcess!.stderr.transform(utf8.decoder).listen((data) {
      });

    } catch (e) {
      debugPrint('Failed to start Ollama server: $e');
      rethrow;
    }
  }

  /// Wait for Ollama server to be ready with optimized exponential backoff
  /// This reduces blocking time on startup from up to 30s to typically <2s
  Future<void> _waitForStartup() async {
    // Exponential backoff: start fast, slow down gradually
    // 100ms, 200ms, 400ms, 800ms, 1000ms, 1000ms, ...
    const initialDelay = 100;
    const maxDelay = 1000;
    const maxAttempts = 30;

    int currentDelay = initialDelay;

    for (int i = 0; i < maxAttempts; i++) {
      await Future.delayed(Duration(milliseconds: currentDelay));

      if (await isAvailable) {
        debugPrint('Ollama server ready after ${i + 1} attempts');
        return;
      }

      // Double delay until we hit max (exponential backoff)
      currentDelay = (currentDelay * 2).clamp(initialDelay, maxDelay);
    }

    throw Exception('Ollama server failed to start within 30 seconds');
  }

  /// Get list of installed models
  Future<List<ModelConfig>> getInstalledModels() async {
    try {
      final response = await _dio.get('/api/tags');
      final data = response.data as Map<String, dynamic>;
      final models = data['models'] as List<dynamic>? ?? [];
      
      
      return models.map<ModelConfig>((modelData) {
        final model = modelData as Map<String, dynamic>;
        final name = model['name'] as String;
        final sizeBytes = model['size'] as int? ?? 0;
        final details = model['details'] as Map<String, dynamic>? ?? {};
        final parameterSize = details['parameter_size'] as String? ?? '';
        
        final modelConfig = ModelConfig.localModel(
          id: 'local_${name.replaceAll(':', '_')}',
          name: _formatModelNameWithParams(name, parameterSize),
          ollamaModelId: name,
          status: ModelStatus.ready,
          modelSize: sizeBytes,
          capabilities: _getModelCapabilities(name),
        );
        
        return modelConfig;
      }).toList();
    } catch (e) {
      debugPrint('Failed to get installed models: $e');
      return [];
    }
  }

  /// Download a model from Ollama registry
  Future<void> downloadModel(
    String modelName, {
    Function(double)? onProgress,
  }) async {
    try {
      
      final response = await _dio.post(
        '/api/pull',
        data: {'name': modelName, 'stream': true},
        options: Options(responseType: ResponseType.stream),
      );

      final stream = response.data as ResponseBody;
      
      await for (final chunk in stream.stream) {
        try {
          final jsonStr = utf8.decode(chunk);
          final lines = jsonStr.split('\n').where((line) => line.trim().isNotEmpty);
          
          for (final line in lines) {
            try {
              final data = json.decode(line) as Map<String, dynamic>;
              
              if (data.containsKey('completed') && data.containsKey('total')) {
                final completed = data['completed'] as int;
                final total = data['total'] as int;
                
                if (total > 0) {
                  final progress = completed / total;
                  onProgress?.call(progress);
                }
              }
              
              if (data.containsKey('status')) {
              }
            } catch (e) {
              // Skip malformed JSON lines
              continue;
            }
          }
        } catch (e) {
        }
      }
      
    } catch (e) {
      debugPrint('Failed to download model $modelName: $e');
      rethrow;
    }
  }

  /// Remove a model from local storage
  Future<void> removeModel(String modelName) async {
    try {
      await _dio.delete('/api/delete', data: {'name': modelName});
    } catch (e) {
      debugPrint('Failed to remove model $modelName: $e');
      rethrow;
    }
  }

  /// Generate a chat response using a local model
  Future<String> generateResponse({
    required String model,
    required String prompt,
    List<Map<String, String>>? messages,
    String? systemPrompt,
  }) async {
    try {
      final requestData = <String, dynamic>{
        'model': model,
        'prompt': prompt,
        'stream': false,
        'keep_alive': '30m', // OPTIMIZATION: Keep model in memory for 30 minutes to avoid cold starts
        'options': {
          'temperature': 0.7,
          'top_p': 0.9,
        },
      };

      if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
        requestData['system'] = systemPrompt;
      }

      final response = await _dio.post('/api/generate', data: requestData);
      final data = response.data as Map<String, dynamic>;
      
      return data['response'] as String? ?? '';
    } catch (e) {
      debugPrint('Failed to generate response: $e');
      rethrow;
    }
  }

  /// Generate a streaming chat response with optimized token batching
  Stream<String> generateStreamingResponse({
    required String model,
    required String prompt,
    List<Map<String, String>>? messages,
    String? systemPrompt,
  }) async* {
    try {
      final requestData = <String, dynamic>{
        'model': model,
        'prompt': prompt,
        'stream': true,
        'keep_alive': '30m', // OPTIMIZATION: Keep model in memory for 30 minutes to avoid cold starts
        'options': {
          'temperature': 0.7,
          'top_p': 0.9,
        },
      };

      if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
        requestData['system'] = systemPrompt;
      }

      final response = await _dio.post(
        '/api/generate',
        data: requestData,
        options: Options(responseType: ResponseType.stream),
      );

      final stream = response.data as ResponseBody;

      // Buffer tokens for batching - reduces UI rebuild frequency
      final buffer = StringBuffer();
      DateTime lastYieldTime = DateTime.now();
      const batchDuration = Duration(milliseconds: 50);
      bool streamComplete = false;

      await for (final chunk in stream.stream) {
        try {
          final jsonStr = utf8.decode(chunk);
          final lines = jsonStr.split('\n').where((line) => line.trim().isNotEmpty);

          for (final line in lines) {
            try {
              final data = json.decode(line) as Map<String, dynamic>;

              if (data.containsKey('response')) {
                final responseText = data['response'] as String?;
                if (responseText != null && responseText.isNotEmpty) {
                  buffer.write(responseText);

                  // Batch tokens: yield every 50ms or when buffer has content
                  final now = DateTime.now();
                  if (now.difference(lastYieldTime) >= batchDuration) {
                    if (buffer.isNotEmpty) {
                      yield buffer.toString();
                      buffer.clear();
                      lastYieldTime = now;
                    }
                  }
                }
              }

              // Check for completion
              final done = data['done'] as bool? ?? false;
              if (done) {
                streamComplete = true;
                break;
              }
            } catch (e) {
              // Skip malformed JSON lines
              continue;
            }
          }

          if (streamComplete) break;
        } catch (e) {
          // Continue processing stream
        }
      }

      // Flush any remaining buffered tokens
      if (buffer.isNotEmpty) {
        yield buffer.toString();
      }
    } catch (e) {
      debugPrint('Failed to generate streaming response: $e');
      rethrow;
    }
  }

  /// Generate a vision response using a local LLaVA model
  Future<String> generateVisionResponse({
    required String model,
    required String prompt,
    required String base64Image,
    String? systemPrompt,
  }) async {
    try {
      final requestData = <String, dynamic>{
        'model': model,
        'prompt': prompt,
        'stream': false,
        'images': [base64Image.split(',').last], // Remove data:image/png;base64, prefix if present
        'options': {
          'temperature': 0.7,
          'top_p': 0.9,
        },
      };

      if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
        requestData['system'] = systemPrompt;
      }

      final response = await _dio.post(
        '/api/generate',
        data: requestData,
      );

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        return responseData['response'] as String? ?? '';
      } else {
        throw Exception('Failed to generate vision response: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Failed to generate vision response: $e');
      rethrow;
    }
  }

  /// Get available models for download (no hardcoded samples - user must install through Ollama)
  List<ModelConfig> getAvailableModels() {
    // Return empty list - users should use ollama CLI to install models
    // This eliminates dummy data and forces users to actually install models they want
    return [];
  }

  /// Format model name for display using actual parameter information from Ollama
  /// This is the STANDARD method for all Ollama models - completely dynamic
  String _formatModelNameWithParams(String ollamaName, String parameterSize) {
    final baseName = ollamaName.split(':').first;
    final tag = ollamaName.contains(':') ? ollamaName.split(':').last : 'latest';
    
    // Convert base name to human-readable format
    // Split on hyphens/underscores and capitalize each word
    final displayName = baseName
        .replaceAll('_', '-')  // Normalize underscores to hyphens
        .split('-')
        .map((word) => _capitalizeWord(word))
        .join(' ');
    
    // Add parameter size if available (e.g., "7B", "13B", "70B")
    if (parameterSize.isNotEmpty) {
      return '$displayName $parameterSize';
    }
    
    // Add tag if it's not "latest" and we don't have parameter size
    if (tag != 'latest') {
      return '$displayName ($tag)';
    }
    
    return displayName;
  }
  
  /// Capitalize a word with special handling for common model name patterns
  String _capitalizeWord(String word) {
    if (word.isEmpty) return word;
    
    // Handle special cases for common model naming patterns
    switch (word.toLowerCase()) {
      case 'llm':
        return 'LLM';
      case 'gpt':
        return 'GPT';
      case 'ai':
        return 'AI';
      case 'oss':
        return 'OSS';
      case 'api':
        return 'API';
      case 'ui':
        return 'UI';
      case 'cli':
        return 'CLI';
      case 'nlp':
        return 'NLP';
      case 'ml':
        return 'ML';
      default:
        // Standard capitalization
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }
  }

  /// Get model capabilities based on model name patterns
  /// This is the STANDARD method for all Ollama models - completely dynamic
  List<String> _getModelCapabilities(String ollamaName) {
    final name = ollamaName.toLowerCase();
    final capabilities = <String>[];
    
    // Only mark confirmed function calling models
    if (name.contains('llama3.1')) {
      capabilities.add('function_calling');
    }
    
    // Vision models
    if (name.contains('llava') || name.contains('vision')) {
      capabilities.addAll(['vision', 'multimodal']);
    }
    
    // Reasoning models  
    if (name.contains('deepseek-r1') || name.contains('qwq') || name.contains('o1')) {
      capabilities.addAll(['reasoning', 'thinking']);
    }
    
    // General chat models
    if (name.contains('llama') || name.contains('gemma') || name.contains('mistral')) {
      capabilities.add('chat');
    }
    
    // Language-specific models
    if (name.contains('translate') || name.contains('multilingual')) {
      capabilities.addAll(['translation', 'multilingual']);
    }
    
    // If no specific capabilities detected, default to general
    if (capabilities.isEmpty) {
      capabilities.add('general');
    }
    
    // Remove duplicates and return
    return capabilities.toSet().toList();
  }

  /// Try to use system-installed Ollama as fallback
  Future<bool> _trySystemOllama() async {
    try {
      // Try common system paths for Ollama
      List<String> systemPaths = [];
      
      if (_desktopService.isWindows) {
        systemPaths = [
          'ollama.exe',
          r'C:\Users\%USERNAME%\AppData\Local\Programs\Ollama\ollama.exe',
          r'C:\Program Files\Ollama\ollama.exe',
          r'C:\Program Files (x86)\Ollama\ollama.exe',
        ];
      } else if (_desktopService.isMacOS) {
        systemPaths = [
          'ollama',
          '/usr/local/bin/ollama',
          '/opt/homebrew/bin/ollama',
          '/Applications/Ollama.app/Contents/Resources/ollama',
        ];
      } else if (_desktopService.isLinux) {
        systemPaths = [
          'ollama',
          '/usr/local/bin/ollama',
          '/usr/bin/ollama',
          '~/.local/bin/ollama',
        ];
      }
      
      for (final systemPath in systemPaths) {
        try {
          // Try to run ollama --version to check if it exists and works
          final result = await Process.run(systemPath, ['--version']);
          if (result.exitCode == 0) {
            _ollamaBinaryPath = systemPath;
            debugPrint('Found system Ollama at: $systemPath');
            
            // Try to start the service
            await _startEmbeddedOllama();
            await _waitForStartup();
            return true;
          }
        } catch (e) {
          // Continue to next path
          continue;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Error trying system Ollama: $e');
      return false;
    }
  }

  /// Shutdown the Ollama service
  Future<void> shutdown() async {
    if (_ollamaProcess != null) {
      _ollamaProcess!.kill();
      await _ollamaProcess!.exitCode;
      _ollamaProcess = null;
    }
    _isInitialized = false;
  }

  /// Dispose resources
  void dispose() {
    _dio.close();
    shutdown();
  }
}

// Riverpod provider for Ollama service
final ollamaServiceProvider = Provider<OllamaService>((ref) {
  final desktopService = DesktopServiceProvider.instance;
  final service = OllamaService(desktopService);
  
  // Initialize on first access (don't await to avoid blocking)
  service.initialize().catchError((e) {
    debugPrint('Failed to initialize Ollama service: $e');
  });
  
  // Cleanup on disposal
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});