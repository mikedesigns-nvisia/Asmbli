import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'simple_detection_service.dart';
import 'detection_integration_mapping.dart';
import 'mcp_settings_service.dart';

/// Service that bridges detection results to MCP server configuration
class DetectionConfigurationService {
  final MCPSettingsService _mcpSettingsService;
  final SimpleDetectionService _detectionService;

  DetectionConfigurationService(this._mcpSettingsService, this._detectionService);

  /// Auto-configure MCP servers based on detection results
  Future<ConfigurationResult> autoConfigureFromDetection() async {
    try {
      print('DetectionConfigurationService: Starting auto-configuration...');
      
      // Get detection results
      final detectionResult = await _detectionService.detectBasicTools();
      print('DetectionConfigurationService: Found ${detectionResult.totalFound} tools');
      
      final configuredServers = <String>[];
      final failedConfigurations = <String, String>{};
      
      // Configure each detected tool
      for (final entry in detectionResult.detections.entries) {
        if (entry.value) { // Tool was detected
          final toolName = entry.key;
          try {
            final success = await _configureToolIntegration(toolName);
            if (success) {
              configuredServers.add(toolName);
              print('DetectionConfigurationService: ✅ Configured $toolName');
            } else {
              failedConfigurations[toolName] = 'Configuration template not found';
              print('DetectionConfigurationService: ❌ No template for $toolName');
            }
          } catch (e) {
            failedConfigurations[toolName] = e.toString();
            print('DetectionConfigurationService: ❌ Failed to configure $toolName: $e');
          }
        }
      }
      
      return ConfigurationResult(
        totalDetected: detectionResult.totalFound,
        successfulConfigurations: configuredServers,
        failedConfigurations: failedConfigurations,
        detectionResult: detectionResult,
      );
    } catch (e) {
      print('DetectionConfigurationService: Fatal error during auto-configuration: $e');
      rethrow;
    }
  }

  /// Configure a specific tool integration
  Future<bool> _configureToolIntegration(String toolName) async {
    final template = _getIntegrationTemplate(toolName);
    if (template == null) return false;

    try {
      // Get detected paths and configuration
      final config = await _generateConfigurationForTool(toolName);
      if (config == null) return false;

      // Create MCP server configuration
      final mcpConfig = MCPServerConfig(
        id: template.id,
        name: template.name,
        command: config.executablePath,
        args: template.args,
        env: {...template.env, ...config.environmentVariables},
        description: template.description,
        enabled: true,
        createdAt: DateTime.now(),
      );

      // Save configuration
      await _mcpSettingsService.setMCPServer(mcpConfig.id, mcpConfig);
      print('DetectionConfigurationService: Saved MCP config for ${template.name}');
      
      return true;
    } catch (e) {
      print('DetectionConfigurationService: Error configuring $toolName: $e');
      return false;
    }
  }

  /// Public helper: given an integration id, check detection results and
  /// return a ToolConfiguration for the first detected tool that maps to
  /// the requested integration id (using the deterministic mapping).
  Future<ToolConfiguration?> generateConfigurationForIntegration(String integrationId) async {
    final detectionResult = await _detectionService.detectBasicTools();

    for (final entry in detectionResult.detections.entries) {
      if (!entry.value) continue;
      final toolName = entry.key;
      final mapped = mapDetectionToIntegrationId(toolName);
      if (mapped != null && mapped == integrationId) {
        // Try to generate a configuration for this tool
        final config = await _generateConfigurationForTool(toolName);
        if (config != null) return config;
      }
    }

    return null;
  }

  /// Generate configuration for a detected tool
  Future<ToolConfiguration?> _generateConfigurationForTool(String toolName) async {
    switch (toolName.toLowerCase()) {
      case 'vs code':
        return await _configureVSCode();
      case 'git':
        return await _configureGit();
      case 'github cli':
        return await _configureGitHub();
      case 'node.js':
        return await _configureNodeJS();
      case 'python':
        return await _configurePython();
      case 'docker':
        return await _configureDocker();
      case 'brave browser':
      case 'chrome':
      case 'firefox':
        return await _configureBrowser(toolName);
      default:
        return null;
    }
  }

  Future<ToolConfiguration?> _configureVSCode() async {
    final paths = await _findExecutablePaths([
      r'C:\Program Files\Microsoft VS Code\Code.exe',
      r'C:\Program Files (x86)\Microsoft VS Code\Code.exe',
      'C:\\Users\\${Platform.environment['USERNAME'] ?? 'User'}\\AppData\\Local\\Programs\\Microsoft VS Code\\Code.exe',
    ]);

    if (paths.isEmpty) return null;

    return ToolConfiguration(
      executablePath: paths.first,
      environmentVariables: {
        'VSCODE_PATH': paths.first,
        'EDITOR': paths.first,
      },
      configPaths: [
        'C:\\Users\\${Platform.environment['USERNAME'] ?? 'User'}\\AppData\\Roaming\\Code\\User\\settings.json',
      ],
    );
  }

  Future<ToolConfiguration?> _configureGit() async {
    final paths = await _findExecutablePaths([
      r'C:\Program Files\Git\bin\git.exe',
      r'C:\Program Files (x86)\Git\bin\git.exe',
      '/usr/bin/git',
      '/usr/local/bin/git',
    ]);

    if (paths.isEmpty) return null;

    return ToolConfiguration(
      executablePath: paths.first,
      environmentVariables: {
        'GIT_PATH': paths.first,
      },
    );
  }

  Future<ToolConfiguration?> _configureGitHub() async {
    final paths = await _findExecutablePaths([
      r'C:\Program Files\GitHub CLI\gh.exe',
      '/usr/local/bin/gh',
      '/usr/bin/gh',
    ]);

    if (paths.isEmpty) return null;

    return ToolConfiguration(
      executablePath: paths.first,
      environmentVariables: {
        'GH_PATH': paths.first,
        'GITHUB_TOKEN': Platform.environment['GITHUB_TOKEN'] ?? '',
      },
    );
  }

  Future<ToolConfiguration?> _configureNodeJS() async {
    final paths = await _findExecutablePaths([
      r'C:\Program Files\nodejs\node.exe',
      r'C:\Program Files (x86)\nodejs\node.exe',
      '/usr/local/bin/node',
      '/usr/bin/node',
    ]);

    if (paths.isEmpty) return null;

    return ToolConfiguration(
      executablePath: paths.first,
      environmentVariables: {
        'NODE_PATH': paths.first,
        'NPM_PATH': paths.first.replaceAll('node.exe', 'npm.cmd'),
      },
    );
  }

  Future<ToolConfiguration?> _configurePython() async {
    final paths = await _findExecutablePaths([
      r'C:\Python\python.exe',
      r'C:\Program Files\Python\python.exe',
      '/usr/local/bin/python3',
      '/usr/bin/python3',
      '/usr/bin/python',
    ]);

    if (paths.isEmpty) return null;

    return ToolConfiguration(
      executablePath: paths.first,
      environmentVariables: {
        'PYTHON_PATH': paths.first,
        'PIP_PATH': paths.first.replaceAll('python', 'pip'),
      },
    );
  }

  Future<ToolConfiguration?> _configureDocker() async {
    final paths = await _findExecutablePaths([
      r'C:\Program Files\Docker\Docker\Docker Desktop.exe',
      '/usr/local/bin/docker',
      '/usr/bin/docker',
    ]);

    if (paths.isEmpty) return null;

    return ToolConfiguration(
      executablePath: paths.first,
      environmentVariables: {
        'DOCKER_PATH': paths.first,
      },
    );
  }

  Future<ToolConfiguration?> _configureBrowser(String browserName) async {
    final Map<String, List<String>> browserPaths = {
      'chrome': [
        r'C:\Program Files\Google\Chrome\Application\chrome.exe',
        r'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe',
      ],
      'brave browser': [
        r'C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe',
        r'C:\Program Files (x86)\BraveSoftware\Brave-Browser\Application\brave.exe',
      ],
      'firefox': [
        r'C:\Program Files\Mozilla Firefox\firefox.exe',
        r'C:\Program Files (x86)\Mozilla Firefox\firefox.exe',
      ],
    };

    final paths = await _findExecutablePaths(
      browserPaths[browserName.toLowerCase()] ?? []
    );

    if (paths.isEmpty) return null;

    return ToolConfiguration(
      executablePath: paths.first,
      environmentVariables: {
        'BROWSER_PATH': paths.first,
      },
    );
  }

  /// Find existing executable paths from a list of candidates
  Future<List<String>> _findExecutablePaths(List<String> candidates) async {
    final existingPaths = <String>[];
    
    for (final path in candidates) {
      final expandedPath = _expandEnvironmentVariables(path);
      if (await File(expandedPath).exists()) {
        existingPaths.add(expandedPath);
      }
    }
    
    return existingPaths;
  }

  /// Expand environment variables in paths
  String _expandEnvironmentVariables(String path) {
    var expandedPath = path;
    Platform.environment.forEach((key, value) {
      expandedPath = expandedPath.replaceAll('\${$key}', value);
    });
    return expandedPath;
  }

  /// Get integration template for a tool
  IntegrationTemplate? _getIntegrationTemplate(String toolName) {
    final templates = {
      'vs code': IntegrationTemplate(
        id: 'vscode',
        name: 'VS Code',
        description: 'Visual Studio Code integration for file editing and project management',
        command: 'code',
        args: ['--server-mode'],
        env: {},
        category: 'development',
      ),
      'git': IntegrationTemplate(
        id: 'git',
        name: 'Git',
        description: 'Git version control integration',
        command: 'git',
        args: [],
        env: {},
        category: 'development',
      ),
      'github cli': IntegrationTemplate(
        id: 'github',
        name: 'GitHub CLI',
        description: 'GitHub repository management',
        command: 'gh',
        args: [],
        env: {},
        category: 'development',
      ),
      'node.js': IntegrationTemplate(
        id: 'nodejs',
        name: 'Node.js',
        description: 'Node.js runtime and package management',
        command: 'node',
        args: [],
        env: {},
        category: 'development',
      ),
      'python': IntegrationTemplate(
        id: 'python',
        name: 'Python',
        description: 'Python interpreter and package management',
        command: 'python',
        args: [],
        env: {},
        category: 'development',
      ),
      'docker': IntegrationTemplate(
        id: 'docker',
        name: 'Docker',
        description: 'Docker container management',
        command: 'docker',
        args: [],
        env: {},
        category: 'development',
      ),
      'brave browser': IntegrationTemplate(
        id: 'brave',
        name: 'Brave Browser',
        description: 'Brave browser automation and bookmarks',
        command: 'brave',
        args: [],
        env: {},
        category: 'browsers',
      ),
      'chrome': IntegrationTemplate(
        id: 'chrome',
        name: 'Google Chrome',
        description: 'Chrome browser automation and bookmarks',
        command: 'chrome',
        args: [],
        env: {},
        category: 'browsers',
      ),
      'firefox': IntegrationTemplate(
        id: 'firefox',
        name: 'Mozilla Firefox',
        description: 'Firefox browser automation and bookmarks',
        command: 'firefox',
        args: [],
        env: {},
        category: 'browsers',
      ),
    };

    return templates[toolName.toLowerCase()];
  }
}

/// Configuration result from detection-to-MCP process
class ConfigurationResult {
  final int totalDetected;
  final List<String> successfulConfigurations;
  final Map<String, String> failedConfigurations;
  final SimpleDetectionResult detectionResult;

  const ConfigurationResult({
    required this.totalDetected,
    required this.successfulConfigurations,
    required this.failedConfigurations,
    required this.detectionResult,
  });

  int get totalConfigured => successfulConfigurations.length;
  int get totalFailed => failedConfigurations.length;
  double get successRate => totalDetected > 0 ? (totalConfigured / totalDetected) : 0.0;
}

/// Tool-specific configuration
class ToolConfiguration {
  final String executablePath;
  final Map<String, String> environmentVariables;
  final List<String> configPaths;

  const ToolConfiguration({
    required this.executablePath,
    required this.environmentVariables,
    this.configPaths = const [],
  });
}

/// Integration template for MCP server creation
class IntegrationTemplate {
  final String id;
  final String name;
  final String description;
  final String command;
  final List<String> args;
  final Map<String, String> env;
  final String category;

  const IntegrationTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.command,
    required this.args,
    required this.env,
    required this.category,
  });
}

/// Provider for detection configuration service
final detectionConfigurationServiceProvider = Provider<DetectionConfigurationService>((ref) {
  final mcpSettingsService = ref.read(mcpSettingsServiceProvider);
  final detectionService = ref.read(simpleDetectionServiceProvider);
  return DetectionConfigurationService(mcpSettingsService, detectionService);
});