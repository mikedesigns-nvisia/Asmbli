import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../ollama_service.dart';
import 'macos_service_provider.dart';
import '../../models/model_config.dart';

/// macOS-native Ollama service with platform-specific optimizations
/// Handles macOS-specific installation paths, permissions, and security features
class MacOSOllamaService extends OllamaService {
  final MacOSServiceProvider _macOSService;
  
  // Initialization tracking
  bool _isInitialized = false;
  Completer<void>? _initializationCompleter;
  String? _ollamaBinaryPath;
  Process? _ollamaProcess;

  // macOS-specific paths where Ollama might be installed
  static const List<String> _macOSOllamaPaths = [
    '/Applications/Ollama.app/Contents/Resources/ollama',
    '/opt/homebrew/bin/ollama',
    '/usr/local/bin/ollama',
    '/opt/local/bin/ollama', // MacPorts
  ];

  MacOSOllamaService(MacOSServiceProvider macOSService)
      : _macOSService = macOSService,
        super(macOSService);

  /// Check if we're running in macOS app sandbox
  Future<bool> get _isAppSandboxed async {
    try {
      final homeDir = Platform.environment['HOME'] ?? '';
      return homeDir.contains('Containers') || homeDir.contains('Library/Containers');
    } catch (e) {
      return false;
    }
  }

  /// Check if Ollama.app is installed via official installer
  Future<bool> get isOllamaAppInstalled async {
    final appPath = Directory('/Applications/Ollama.app');
    return appPath.existsSync();
  }

  /// Check if Ollama is installed via Homebrew
  Future<bool> get isHomebrewOllamaInstalled async {
    final homebrewPath = File('/opt/homebrew/bin/ollama');
    final oldHomebrewPath = File('/usr/local/bin/ollama');
    return homebrewPath.existsSync() || oldHomebrewPath.existsSync();
  }

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (_initializationCompleter != null) {
      return _initializationCompleter!.future;
    }

    _initializationCompleter = Completer<void>();
    debugPrint('🍎 Initializing macOS Ollama service');

    try {
      // First check if Ollama is already running
      if (await isAvailable) {
        debugPrint('✅ Found running Ollama instance');
        _isInitialized = true;
        _initializationCompleter!.complete();
        return;
      }

      // Try macOS-specific installation detection and startup
      if (await _initializeMacOSOllama()) {
        _isInitialized = true;
        debugPrint('✅ macOS Ollama service initialized');
      } else {
        debugPrint('⚠️ Ollama not found on macOS. Local models unavailable.');
      }

      _initializationCompleter!.complete();
    } catch (e) {
      debugPrint('❌ macOS Ollama initialization failed: $e');
      _initializationCompleter!.completeError(e);
    } finally {
      _initializationCompleter = null;
    }
  }

  /// Initialize Ollama using macOS-specific methods
  Future<bool> _initializeMacOSOllama() async {
    // 1. Try to find and start Ollama.app
    if (await _startOllamaApp()) {
      debugPrint('✅ Started Ollama.app');
      return true;
    }

    // 2. Try Homebrew installation
    if (await _startHomebrewOllama()) {
      debugPrint('✅ Started Homebrew Ollama');
      return true;
    }

    // 3. Try system PATH
    if (await _startSystemOllama()) {
      debugPrint('✅ Started system Ollama');
      return true;
    }

    // 4. Check if we can guide user to install
    await _checkInstallationGuidance();
    return false;
  }

  /// Try to start Ollama.app (official macOS installer)
  Future<bool> _startOllamaApp() async {
    try {
      const appPath = '/Applications/Ollama.app/Contents/Resources/ollama';
      final appFile = File(appPath);

      if (!appFile.existsSync()) {
        debugPrint('🔍 Ollama.app not found at $appPath');
        return false;
      }

      // Check permissions
      if (!await _checkExecutePermissions(appPath)) {
        debugPrint('⚠️ No execute permissions for Ollama.app');
        return false;
      }

      return await _startOllamaProcess(appPath);
    } catch (e) {
      debugPrint('❌ Failed to start Ollama.app: $e');
      return false;
    }
  }

  /// Try to start Homebrew Ollama
  Future<bool> _startHomebrewOllama() async {
    try {
      // Check both ARM and Intel Homebrew paths
      const paths = ['/opt/homebrew/bin/ollama', '/usr/local/bin/ollama'];

      for (final ollamaPath in paths) {
        final ollamaFile = File(ollamaPath);
        if (ollamaFile.existsSync()) {
          if (await _checkExecutePermissions(ollamaPath)) {
            debugPrint('🍺 Found Homebrew Ollama at $ollamaPath');
            return await _startOllamaProcess(ollamaPath);
          }
        }
      }

      return false;
    } catch (e) {
      debugPrint('❌ Failed to start Homebrew Ollama: $e');
      return false;
    }
  }

  /// Try to start system Ollama (in PATH)
  Future<bool> _startSystemOllama() async {
    try {
      // Try 'which ollama' to find in PATH
      final result = await Process.run('which', ['ollama']);
      if (result.exitCode == 0) {
        final ollamaPath = result.stdout.toString().trim();
        if (ollamaPath.isNotEmpty) {
          debugPrint('🔍 Found system Ollama at $ollamaPath');
          return await _startOllamaProcess(ollamaPath);
        }
      }
      return false;
    } catch (e) {
      debugPrint('❌ Failed to find system Ollama: $e');
      return false;
    }
  }

  /// Start Ollama process with macOS-specific configuration
  Future<bool> _startOllamaProcess(String ollamaPath) async {
    try {
      _ollamaBinaryPath = ollamaPath;

      // macOS-specific environment variables
      final environment = <String, String>{
        'OLLAMA_HOST': '127.0.0.1:11434',
        'OLLAMA_ORIGINS': '*',
        'OLLAMA_MODELS': await _getMacOSModelsPath(),
        'OLLAMA_KEEP_ALIVE': '5m',
        // Respect macOS data protection
        'OLLAMA_DEBUG': kDebugMode ? '1' : '0',
      };

      // For sandboxed apps, we might need different approach
      if (await _isAppSandboxed) {
        debugPrint('🏖️ Running in App Sandbox, adjusting Ollama configuration');
        environment['OLLAMA_MODELS'] = await _getSandboxedModelsPath();
      }

      _ollamaProcess = await Process.start(
        ollamaPath,
        ['serve'],
        environment: environment,
        runInShell: false, // Don't use shell for better security
      );

      // Monitor process output (simplified)
      _ollamaProcess!.stdout.listen((data) {
        if (kDebugMode) {
          debugPrint('🦙 Ollama stdout: ${String.fromCharCodes(data)}');
        }
      });

      _ollamaProcess!.stderr.listen((data) {
        if (kDebugMode) {
          debugPrint('🦙 Ollama stderr: ${String.fromCharCodes(data)}');
        }
      });

      // Wait for startup and verify
      await _waitForStartup();
      return true;
    } catch (e) {
      debugPrint('❌ Failed to start Ollama process: $e');
      return false;
    }
  }

  /// Wait for Ollama to start up
  Future<void> _waitForStartup() async {
    // Simple startup delay - in a production app you might ping the Ollama API
    await Future.delayed(const Duration(seconds: 2));
  }

  /// Check execute permissions for a file
  Future<bool> _checkExecutePermissions(String filePath) async {
    try {
      final stat = await Process.run('stat', ['-f', '%A', filePath]);
      if (stat.exitCode == 0) {
        final permissions = stat.stdout.toString().trim();
        final octal = int.tryParse(permissions) ?? 0;
        // Check if owner has execute permission (bit 6)
        return (octal & 0o100) != 0;
      }
      return false;
    } catch (e) {
      debugPrint('⚠️ Could not check permissions for $filePath: $e');
      return false;
    }
  }

  /// Get macOS-appropriate models path
  Future<String> _getMacOSModelsPath() async {
    final homeDir = Platform.environment['HOME'] ?? '';
    final modelsPath = path.join(homeDir, 'Library', 'Application Support', 'Ollama', 'models');

    // Ensure directory exists
    final modelsDir = Directory(modelsPath);
    if (!modelsDir.existsSync()) {
      try {
        modelsDir.createSync(recursive: true);
      } catch (e) {
        debugPrint('⚠️ Could not create models directory: $e');
      }
    }

    return modelsPath;
  }

  /// Get sandboxed models path for App Store apps
  Future<String> _getSandboxedModelsPath() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final modelsPath = path.join(appSupportDir.path, 'ollama', 'models');

    final modelsDir = Directory(modelsPath);
    if (!modelsDir.existsSync()) {
      modelsDir.createSync(recursive: true);
    }

    return modelsPath;
  }

  /// Check installation and provide guidance
  Future<void> _checkInstallationGuidance() async {
    debugPrint('🔍 Checking macOS Ollama installation options...');

    // Check if user might have Ollama installed but not in expected locations
    const searchPaths = [
      '/usr/bin/ollama',
      '/usr/sbin/ollama',
      '~/bin/ollama',
      '~/.bin/ollama',
    ];

    for (final searchPath in searchPaths) {
      final expandedPath = searchPath.replaceFirst('~', Platform.environment['HOME'] ?? '');
      if (File(expandedPath).existsSync()) {
        debugPrint('💡 Found Ollama at unexpected location: $expandedPath');
        break;
      }
    }

    // Provide installation guidance
    debugPrint('''
🍎 macOS Ollama Installation Options:

1. Official Installer (Recommended):
   - Download from https://ollama.ai/download
   - Installs to /Applications/Ollama.app

2. Homebrew:
   - brew install ollama
   - Installs to /opt/homebrew/bin/ollama (Apple Silicon) or /usr/local/bin/ollama (Intel)

3. Manual Installation:
   - Download binary and place in PATH

Current search paths checked:
${_macOSOllamaPaths.join('\n')}
''');
  }

  /// Get macOS-specific system information
  Future<Map<String, dynamic>> getMacOSSystemInfo() async {
    final info = <String, dynamic>{};

    try {
      // macOS version
      final swVers = await Process.run('sw_vers', ['-productVersion']);
      if (swVers.exitCode == 0) {
        info['macos_version'] = swVers.stdout.toString().trim();
      }

      // Architecture
      final uname = await Process.run('uname', ['-m']);
      if (uname.exitCode == 0) {
        info['architecture'] = uname.stdout.toString().trim();
      }

      // Check installation status
      info['installation_status'] = {
        'ollama_app_installed': await isOllamaAppInstalled,
        'homebrew_installed': await isHomebrewOllamaInstalled,
        'app_sandboxed': await _isAppSandboxed,
        'models_path': await _getMacOSModelsPath(),
      };

      // Available disk space for models
      final modelsPath = await _getMacOSModelsPath();
      final diskSpace = await _getDiskSpace(modelsPath);
      if (diskSpace != null) {
        info['disk_space'] = diskSpace;
      }

    } catch (e) {
      info['error'] = 'Failed to gather macOS system info: $e';
    }

    return info;
  }

  /// Get disk space information
  Future<Map<String, dynamic>?> _getDiskSpace(String path) async {
    try {
      final result = await Process.run('df', ['-h', path]);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        if (lines.length > 1) {
          final parts = lines[1].split(RegExp(r'\s+'));
          if (parts.length >= 4) {
            return {
              'total': parts[1],
              'used': parts[2],
              'available': parts[3],
              'percentage_used': parts[4],
            };
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to get disk space: $e');
    }
    return null;
  }

  /// Download and install a model with macOS-specific optimizations
  @override
  Future<void> downloadModel(
    String modelName, {
    Function(double)? onProgress,
  }) async {
    debugPrint('🍎 Starting macOS model download: $modelName');

    // Check available disk space before download
    final modelsPath = await _getMacOSModelsPath();
    final diskSpace = await _getDiskSpace(modelsPath);

    if (diskSpace != null) {
      debugPrint('💾 Available disk space: ${diskSpace['available']}');
    }

    try {
      // Use parent implementation but with enhanced progress tracking
      await super.downloadModel(
        modelName,
        onProgress: (progress) {
          debugPrint('📥 Download progress: ${(progress * 100).toStringAsFixed(1)}%');
          onProgress?.call(progress);
        },
      );

      debugPrint('✅ Model download completed: $modelName');

      // Verify model installation
      final models = await getInstalledModels();
      final installedModel = models.where((m) => m.ollamaModelId == modelName).firstOrNull;

      if (installedModel != null) {
        debugPrint('✅ Model verified in installation: $modelName');
      } else {
        debugPrint('⚠️ Model download completed but not found in list');
      }

    } catch (e) {
      debugPrint('❌ macOS model download failed: $e');
      rethrow;
    }
  }

  /// Cleanup models and temporary files (macOS-optimized)
  Future<void> cleanupMacOSModels() async {
    try {
      debugPrint('🧹 Starting macOS Ollama cleanup...');

      final modelsPath = await _getMacOSModelsPath();
      final modelsDir = Directory(modelsPath);

      if (!modelsDir.existsSync()) {
        debugPrint('📁 Models directory does not exist');
        return;
      }

      // Get disk usage before cleanup
      final diskSpaceBefore = await _getDiskSpace(modelsPath);

      // Clean up temporary files and caches
      const tempPatterns = ['*.tmp', '*.partial', '.DS_Store', '*.log'];

      for (final pattern in tempPatterns) {
        try {
          final result = await Process.run('find', [
            modelsPath,
            '-name',
            pattern,
            '-delete'
          ]);

          if (result.exitCode == 0) {
            debugPrint('🗑️ Cleaned up temporary files: $pattern');
          }
        } catch (e) {
          debugPrint('⚠️ Could not clean pattern $pattern: $e');
        }
      }

      // Get disk usage after cleanup
      final diskSpaceAfter = await _getDiskSpace(modelsPath);

      if (diskSpaceBefore != null && diskSpaceAfter != null) {
        debugPrint('💾 Cleanup completed. Available space: ${diskSpaceAfter['available']}');
      }

    } catch (e) {
      debugPrint('❌ macOS cleanup failed: $e');
    }
  }

  @override
  Future<void> shutdown() async {
    debugPrint('🛑 Shutting down macOS Ollama service...');
    await super.shutdown();
  }

  @override
  void dispose() {
    debugPrint('🧹 Disposing macOS Ollama service');
    super.dispose();
  }
}

// ==================== Riverpod Providers ====================

final macOSOllamaServiceProvider = Provider<MacOSOllamaService>((ref) {
  final macOSService = ref.read(macOSServiceProvider);
  final service = MacOSOllamaService(macOSService);

  // Initialize asynchronously
  service.initialize().catchError((e) {
    debugPrint('❌ Failed to initialize macOS Ollama service: $e');
  });

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider that returns the appropriate Ollama service for the platform
final platformOllamaServiceProvider = Provider<OllamaService>((ref) {
  if (!kIsWeb && Platform.isMacOS) {
    return ref.read(macOSOllamaServiceProvider);
  } else {
    return ref.read(ollamaServiceProvider);
  }
});

/// Provider for macOS system information
final macOSOllamaSystemInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  if (!kIsWeb && Platform.isMacOS) {
    final service = ref.read(macOSOllamaServiceProvider);
    return await service.getMacOSSystemInfo();
  }
  return {'platform': 'not_macos'};
});