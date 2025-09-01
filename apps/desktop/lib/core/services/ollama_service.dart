import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/model_config.dart';
import 'desktop/desktop_service_provider.dart';

/// Service for managing embedded Ollama instance and local models
class OllamaService {
  final DesktopServiceProvider _desktopService;
  Process? _ollamaProcess;
  final Dio _dio;
  bool _isInitialized = false;
  String? _ollamaBinaryPath;

  OllamaService(this._desktopService) : _dio = Dio() {
    _dio.options.baseUrl = 'http://127.0.0.1:11434';
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  /// Check if Ollama is available and running
  Future<bool> get isAvailable async {
    try {
      final response = await _dio.get('/api/version');
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
        print('Found existing Ollama instance');
        _isInitialized = true;
        return;
      }

      // Extract and start embedded Ollama
      await _extractOllamaBinary();
      await _startEmbeddedOllama();
      await _waitForStartup();
      
      _isInitialized = true;
      print('Ollama service initialized successfully');
    } catch (e) {
      print('Failed to initialize Ollama service: $e');
      throw Exception('Failed to initialize local LLM service: $e');
    }
  }

  /// Extract Ollama binary from assets to local directory
  Future<void> _extractOllamaBinary() async {
    try {
      final appDocumentsPath = (await getApplicationDocumentsDirectory()).path;
      final ollamaDir = Directory(path.join(appDocumentsPath, 'ollama'));
      
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
        print('Extracting Ollama binary to $_ollamaBinaryPath');
        
        try {
          final byteData = await rootBundle.load(assetPath);
          final bytes = byteData.buffer.asUint8List();
          await binaryFile.writeAsBytes(bytes);
          
          // Make executable on Unix-like systems
          if (!_desktopService.isWindows) {
            await Process.run('chmod', ['+x', _ollamaBinaryPath!]);
          }
          
          print('Ollama binary extracted successfully');
        } catch (e) {
          print('Failed to extract Ollama binary from assets: $e');
          // For development, try to find system-installed Ollama
          if (_desktopService.isWindows) {
            _ollamaBinaryPath = 'ollama.exe';
          } else {
            _ollamaBinaryPath = 'ollama';
          }
          print('Using system Ollama binary: $_ollamaBinaryPath');
        }
      } else {
        print('Using existing Ollama binary: $_ollamaBinaryPath');
      }
    } catch (e) {
      print('Error extracting Ollama binary: $e');
      rethrow;
    }
  }

  /// Start the embedded Ollama server process
  Future<void> _startEmbeddedOllama() async {
    if (_ollamaBinaryPath == null) {
      throw Exception('Ollama binary path not set');
    }

    try {
      print('Starting Ollama server...');
      
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
        print('Ollama stdout: $data');
      });

      _ollamaProcess!.stderr.transform(utf8.decoder).listen((data) {
        print('Ollama stderr: $data');
      });

      print('Ollama server process started with PID: ${_ollamaProcess!.pid}');
    } catch (e) {
      print('Failed to start Ollama server: $e');
      rethrow;
    }
  }

  /// Wait for Ollama server to be ready
  Future<void> _waitForStartup() async {
    print('Waiting for Ollama server to start...');
    
    for (int i = 0; i < 30; i++) {
      await Future.delayed(const Duration(seconds: 1));
      
      if (await isAvailable) {
        print('Ollama server is ready!');
        return;
      }
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
        
        return ModelConfig.localModel(
          id: 'local_${name.replaceAll(':', '_')}',
          name: _formatModelName(name),
          ollamaModelId: name,
          status: ModelStatus.ready,
          modelSize: sizeBytes,
          capabilities: _getModelCapabilities(name),
        );
      }).toList();
    } catch (e) {
      print('Failed to get installed models: $e');
      return [];
    }
  }

  /// Download a model from Ollama registry
  Future<void> downloadModel(
    String modelName, {
    Function(double)? onProgress,
  }) async {
    try {
      print('Starting download of model: $modelName');
      
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
                print('Download status: ${data['status']}');
              }
            } catch (e) {
              // Skip malformed JSON lines
              continue;
            }
          }
        } catch (e) {
          print('Error processing download chunk: $e');
        }
      }
      
      print('Model download completed: $modelName');
    } catch (e) {
      print('Failed to download model $modelName: $e');
      rethrow;
    }
  }

  /// Remove a model from local storage
  Future<void> removeModel(String modelName) async {
    try {
      await _dio.delete('/api/delete', data: {'name': modelName});
      print('Model removed: $modelName');
    } catch (e) {
      print('Failed to remove model $modelName: $e');
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
      print('Failed to generate response: $e');
      rethrow;
    }
  }

  /// Generate a streaming chat response
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
                  yield responseText;
                }
              }
              
              // Check for completion
              final done = data['done'] as bool? ?? false;
              if (done) {
                return;
              }
            } catch (e) {
              // Skip malformed JSON lines
              continue;
            }
          }
        } catch (e) {
          print('Error processing streaming chunk: $e');
        }
      }
    } catch (e) {
      print('Failed to generate streaming response: $e');
      rethrow;
    }
  }

  /// Get available models for download
  List<ModelConfig> getAvailableModels() {
    return [
      ModelConfig.localModel(
        id: 'qwq_32b',
        name: 'QwQ 32B',
        ollamaModelId: 'qwq:32b-preview-q4_k_m',
        status: ModelStatus.needsSetup,
        modelSize: 20 * 1024 * 1024 * 1024, // ~20GB
        capabilities: ['reasoning', 'thinking', 'math'],
        downloadUrl: 'qwq:32b-preview-q4_k_m',
      ),
      ModelConfig.localModel(
        id: 'gemma2_27b',
        name: 'Gemma 2 27B',
        ollamaModelId: 'gemma2:27b-instruct-q4_k_m',
        status: ModelStatus.needsSetup,
        modelSize: 16 * 1024 * 1024 * 1024, // ~16GB
        capabilities: ['chat', 'reasoning', 'general'],
        downloadUrl: 'gemma2:27b-instruct-q4_k_m',
      ),
      ModelConfig.localModel(
        id: 'gpt_oss_20b',
        name: 'GPT-OSS 20B',
        ollamaModelId: 'gpt-oss:20b-q4_k_m',
        status: ModelStatus.needsSetup,
        modelSize: 12 * 1024 * 1024 * 1024, // ~12GB
        capabilities: ['reasoning', 'code', 'general'],
        downloadUrl: 'gpt-oss:20b-q4_k_m',
      ),
      ModelConfig.localModel(
        id: 'deepseek_coder_6_7b',
        name: 'DeepSeek Coder 6.7B',
        ollamaModelId: 'deepseek-coder:6.7b-instruct-q4_k_m',
        status: ModelStatus.needsSetup,
        modelSize: 4 * 1024 * 1024 * 1024, // ~4GB
        capabilities: ['code', 'programming', 'instruct'],
        downloadUrl: 'deepseek-coder:6.7b-instruct-q4_k_m',
      ),
    ];
  }

  /// Format model name for display
  String _formatModelName(String ollamaName) {
    // Convert ollama model names to display names
    final name = ollamaName.split(':').first;
    
    switch (name.toLowerCase()) {
      case 'qwq':
        return 'QwQ ${ollamaName.contains('32b') ? '32B' : 'Unknown'}';
      case 'gemma2':
        return 'Gemma 2 ${ollamaName.contains('27b') ? '27B' : 'Unknown'}';
      case 'gpt-oss':
        return 'GPT-OSS ${ollamaName.contains('20b') ? '20B' : ollamaName.contains('120b') ? '120B' : 'Unknown'}';
      case 'deepseek-coder':
        return 'DeepSeek Coder ${ollamaName.contains('6.7b') ? '6.7B' : 'Unknown'}';
      default:
        return name.toUpperCase();
    }
  }

  /// Get model capabilities based on model name
  List<String> _getModelCapabilities(String ollamaName) {
    final name = ollamaName.toLowerCase();
    
    if (name.contains('qwq')) {
      return ['reasoning', 'thinking', 'math'];
    } else if (name.contains('gemma')) {
      return ['chat', 'reasoning', 'general'];
    } else if (name.contains('gpt-oss')) {
      return ['reasoning', 'code', 'general'];
    } else if (name.contains('coder')) {
      return ['code', 'programming', 'instruct'];
    } else {
      return ['general'];
    }
  }

  /// Shutdown the Ollama service
  Future<void> shutdown() async {
    if (_ollamaProcess != null) {
      print('Shutting down Ollama server...');
      _ollamaProcess!.kill();
      await _ollamaProcess!.exitCode;
      _ollamaProcess = null;
      print('Ollama server shut down');
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
    print('Failed to initialize Ollama service: $e');
  });
  
  // Cleanup on disposal
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});