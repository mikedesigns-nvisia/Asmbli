import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/agent_engine_core.dart';
import 'mcp_settings_service.dart';
import 'integration_service.dart';
import 'detection_configuration_service.dart';


import '../models/mcp_server_config.dart';

/// Service that handles the complete integration installation workflow
class IntegrationInstallationService {
  final MCPSettingsService _mcpSettingsService;
  final IntegrationService _integrationService;
  final DetectionConfigurationService _detectionConfigurationService;

  IntegrationInstallationService(
    this._mcpSettingsService,
    this._integrationService,
    this._detectionConfigurationService,
  );

  /// Install an integration with complete workflow
  Future<InstallationResult> installIntegration({
    required String integrationId,
    Map<String, dynamic>? customConfig,
    bool autoDetect = true,
  }) async {
    try {
      print('IntegrationInstallationService: Starting installation of $integrationId');

      // 1. Get integration definition
      final integration = IntegrationRegistry.getById(integrationId);
      if (integration == null) {
        throw IntegrationException('Integration not found: $integrationId');
      }

      if (!integration.isAvailable) {
        throw IntegrationException('Integration not yet available: ${integration.name}');
      }

      print('IntegrationInstallationService: Found integration: ${integration.name}');

      // 2. Check prerequisites
      final prerequisiteResult = await _checkPrerequisites(integration);
      if (!prerequisiteResult.allMet) {
        print('IntegrationInstallationService: Prerequisites not met for ${integration.name}');
        return InstallationResult(
          success: false,
          integrationId: integrationId,
          integration: integration,
          error: 'Prerequisites not met: ${prerequisiteResult.missingPrerequisites.join(', ')}',
          prerequisiteResult: prerequisiteResult,
        );
      }

      // 3. Auto-detect configuration if requested
      Map<String, dynamic> finalConfig = customConfig ?? {};
      if (autoDetect) {
        print('IntegrationInstallationService: Running auto-detection for ${integration.name}');
        final detectedConfig = await _autoDetectConfiguration(integration);
        if (detectedConfig != null) {
          finalConfig = {...detectedConfig, ...finalConfig}; // Custom config overrides
          print('IntegrationInstallationService: Auto-detected configuration for ${integration.name}');
        }
      }

      // 4. Validate configuration
      final validationResult = await _validateConfiguration(integration, finalConfig);
      if (!validationResult.isValid) {
        print('IntegrationInstallationService: Configuration validation failed for ${integration.name}');
        return InstallationResult(
          success: false,
          integrationId: integrationId,
          integration: integration,
          error: 'Configuration validation failed: ${validationResult.errors.join(', ')}',
          validationResult: validationResult,
        );
      }

      // 5. Create MCP server configuration
      final mcpConfig = await _createMCPConfiguration(integration, finalConfig);
      print('IntegrationInstallationService: Created MCP configuration for ${integration.name}');

      // 6. Install and test MCP server
      await _mcpSettingsService.setMCPServer(integrationId, mcpConfig);
      print('IntegrationInstallationService: Saved MCP server configuration for ${integration.name}');

      // 7. Test connection
      final connectionResult = await _testConnection(integrationId, mcpConfig);
      if (!connectionResult.success) {
        print('IntegrationInstallationService: Connection test failed for ${integration.name}');
        // Remove the failed configuration
        await _mcpSettingsService.removeMCPServer(integrationId);
        
        return InstallationResult(
          success: false,
          integrationId: integrationId,
          integration: integration,
          error: 'Connection test failed: ${connectionResult.error}',
          connectionResult: connectionResult,
        );
      }

      // 8. Update integration service status
      await _integrationService.updateIntegrationStatus(integrationId, IntegrationStatus.active);
      print('IntegrationInstallationService: Integration ${integration.name} installed successfully');

      return InstallationResult(
        success: true,
        integrationId: integrationId,
        integration: integration,
        mcpConfig: mcpConfig,
        finalConfiguration: finalConfig,
        prerequisiteResult: prerequisiteResult,
        validationResult: validationResult,
        connectionResult: connectionResult,
      );

    } catch (e) {
      print('IntegrationInstallationService: Installation failed for $integrationId: $e');
      return InstallationResult(
        success: false,
        integrationId: integrationId,
        integration: IntegrationRegistry.getById(integrationId),
        error: e.toString(),
      );
    }
  }

  /// Uninstall an integration
  Future<bool> uninstallIntegration(String integrationId) async {
    try {
      print('IntegrationInstallationService: Uninstalling integration $integrationId');
      
      // Remove MCP server
      await _mcpSettingsService.removeMCPServer(integrationId);
      
      // Update integration status
      await _integrationService.updateIntegrationStatus(integrationId, IntegrationStatus.available);
      
      print('IntegrationInstallationService: Integration $integrationId uninstalled successfully');
      return true;
    } catch (e) {
      print('IntegrationInstallationService: Failed to uninstall $integrationId: $e');
      return false;
    }
  }

  /// Check prerequisites for an integration
  Future<PrerequisiteResult> _checkPrerequisites(IntegrationDefinition integration) async {
    final missingPrerequisites = <String>[];
    final metPrerequisites = <String>[];

    for (final prerequisite in integration.prerequisites) {
      final isMet = await _checkSinglePrerequisite(prerequisite);
      if (isMet) {
        metPrerequisites.add(prerequisite);
      } else {
        missingPrerequisites.add(prerequisite);
      }
    }

    return PrerequisiteResult(
      allMet: missingPrerequisites.isEmpty,
      metPrerequisites: metPrerequisites,
      missingPrerequisites: missingPrerequisites,
    );
  }

  /// Check a single prerequisite
  Future<bool> _checkSinglePrerequisite(String prerequisite) async {
    final lowercasePrereq = prerequisite.toLowerCase();
    
    // Check for common prerequisites
    if (lowercasePrereq.contains('git')) {
      return await _checkExecutableExists(['git', 'git.exe']);
    }
    
    if (lowercasePrereq.contains('node')) {
      return await _checkExecutableExists(['node', 'node.exe']);
    }
    
    if (lowercasePrereq.contains('python')) {
      return await _checkExecutableExists(['python', 'python.exe', 'python3']);
    }
    
    if (lowercasePrereq.contains('docker')) {
      return await _checkExecutableExists(['docker', 'docker.exe']);
    }

    if (lowercasePrereq.contains('postgresql') || lowercasePrereq.contains('postgres')) {
      return await _checkExecutableExists(['psql', 'psql.exe', 'pg_config']);
    }

    if (lowercasePrereq.contains('mysql')) {
      return await _checkExecutableExists(['mysql', 'mysql.exe']);
    }

    // Default to true for unknown prerequisites
    return true;
  }

  /// Check if executable exists in PATH
  Future<bool> _checkExecutableExists(List<String> executables) async {
    for (final executable in executables) {
      try {
        final result = await Process.run('where', [executable]);
        if (result.exitCode == 0) {
          return true;
        }
      } catch (e) {
        // Try with which on Unix-like systems
        try {
          final result = await Process.run('which', [executable]);
          if (result.exitCode == 0) {
            return true;
          }
        } catch (e) {
          // Continue to next executable
        }
      }
    }
    return false;
  }

  /// Auto-detect configuration for an integration
  Future<Map<String, dynamic>?> _autoDetectConfiguration(IntegrationDefinition integration) async {
    // First, try detection-derived configuration via DetectionConfigurationService
    try {
      final detectionConfig = await _detectionConfigurationService.generateConfigurationForIntegration(integration.id);
      if (detectionConfig != null) {
        // Map ToolConfiguration -> Map<String,dynamic> expected by installer
        final map = <String, dynamic>{};
        map['executablePath'] = detectionConfig.executablePath;
        if (detectionConfig.environmentVariables.isNotEmpty) {
          map.addAll(detectionConfig.environmentVariables);
        }
        if (detectionConfig.configPaths.isNotEmpty) {
          map['configPaths'] = detectionConfig.configPaths;
        }
        return map;
      }
    } catch (e) {
      // ignore and fallback to older detectors
    }

    // Fallback to built-in integration-specific detectors
    switch (integration.id) {
      case 'filesystem':
        return await _autoDetectFilesystem();
      case 'git':
        return await _autoDetectGit();
      case 'postgresql':
        return await _autoDetectPostgreSQL();
      case 'terminal':
        return await _autoDetectTerminal();
      default:
        return null;
    }
  }

  Future<Map<String, dynamic>?> _autoDetectFilesystem() async {
    // Default to user's home directory or Documents folder
    final userHome = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '';
    if (userHome.isNotEmpty) {
      final documentsPath = Platform.isWindows 
        ? '$userHome\\Documents'
        : '$userHome/Documents';
      
      if (await Directory(documentsPath).exists()) {
        return {
          'rootPath': documentsPath,
          'readOnly': true, // Default to safe mode
        };
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> _autoDetectGit() async {
    // Look for .git directory in common project locations
    final userHome = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '';
    final projectDirs = [
      '$userHome\\projects',
      '$userHome\\code',
      '$userHome\\dev',
      '$userHome\\workspace',
      '$userHome/projects',
      '$userHome/code',
      '$userHome/dev',
      '$userHome/workspace',
    ];

    for (final dir in projectDirs) {
      if (await Directory(dir).exists()) {
        final contents = await Directory(dir).list().toList();
        for (final item in contents) {
          if (item is Directory) {
            final gitDir = Directory('${item.path}\\.git');
            final gitDirUnix = Directory('${item.path}/.git');
            if (await gitDir.exists() || await gitDirUnix.exists()) {
              return {'repositoryPath': item.path};
            }
          }
        }
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> _autoDetectPostgreSQL() async {
    // Try to connect to localhost with default settings
    return {
      'host': 'localhost',
      'port': 5432,
      'database': 'postgres',
      'username': 'postgres',
      // Password will need to be provided by user
    };
  }

  Future<Map<String, dynamic>?> _autoDetectTerminal() async {
    // Default working directory to user home
    final userHome = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '';
    return {
      'workingDirectory': userHome,
      'allowDangerous': false, // Default to safe mode
    };
  }

  /// Validate configuration against integration field requirements
  Future<ValidationResult> _validateConfiguration(
    IntegrationDefinition integration, 
    Map<String, dynamic> config
  ) async {
    final errors = <String>[];

    for (final field in integration.configFields) {
      final value = config[field.id];

      // Check required fields
      if (field.required && (value == null || value.toString().isEmpty)) {
        errors.add('${field.label} is required');
        continue;
      }

      // Skip validation if field is not provided and not required
      if (value == null) continue;

      // Validate by field type
      switch (field.fieldType) {
        case IntegrationFieldType.email:
          if (!_isValidEmail(value.toString())) {
            errors.add('${field.label} must be a valid email address');
          }
          break;
        
        case IntegrationFieldType.url:
          if (!_isValidUrl(value.toString())) {
            errors.add('${field.label} must be a valid URL');
          }
          break;
        
        case IntegrationFieldType.number:
          if (double.tryParse(value.toString()) == null) {
            errors.add('${field.label} must be a valid number');
          }
          break;
        
        case IntegrationFieldType.directory:
          if (!await Directory(value.toString()).exists()) {
            errors.add('${field.label} directory does not exist: $value');
          }
          break;
        
        case IntegrationFieldType.file:
          if (!await File(value.toString()).exists()) {
            errors.add('${field.label} file does not exist: $value');
          }
          break;
        
        default:
          // No specific validation for other types
          break;
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// Create MCP server configuration from integration definition and config
  Future<MCPServerConfig> _createMCPConfiguration(
    IntegrationDefinition integration, 
    Map<String, dynamic> config
  ) async {
    // Build environment variables
    final env = <String, String>{};
    
    for (final field in integration.configFields) {
      final value = config[field.id];
      if (value != null) {
        // Convert field ID to environment variable name
        final envKey = field.id.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9_]'), '_');
        env[envKey] = value.toString();
      }
    }

    return MCPServerConfig(
      id: integration.id,
      name: integration.name,
      command: integration.command,
      args: [...integration.args, ...(_buildCommandArgs(integration, config))],
      env: env,
      description: integration.description,
      enabled: true,
      createdAt: DateTime.now(),
    );
  }

  /// Build command-line arguments from configuration
  List<String> _buildCommandArgs(IntegrationDefinition integration, Map<String, dynamic> config) {
    final args = <String>[];

    // Add common arguments based on integration type
    switch (integration.id) {
      case 'filesystem':
        final rootPath = config['rootPath'];
        final readOnly = config['readOnly'] ?? false;
        if (rootPath != null) {
          args.addAll(['--root-path', rootPath.toString()]);
        }
        if (readOnly) {
          args.add('--read-only');
        }
        break;

      case 'git':
        final repoPath = config['repositoryPath'];
        if (repoPath != null) {
          args.addAll(['--repository', repoPath.toString()]);
        }
        break;

      case 'postgresql':
        final host = config['host'] ?? 'localhost';
        final port = config['port'] ?? 5432;
        final database = config['database'] ?? 'postgres';
        final username = config['username'];
        
        args.addAll([
          '--host', host.toString(),
          '--port', port.toString(),
          '--database', database.toString(),
        ]);
        
        if (username != null) {
          args.addAll(['--username', username.toString()]);
        }
        break;
    }

    return args;
  }

  /// Test connection to MCP server
  Future<ConnectionResult> _testConnection(String integrationId, MCPServerConfig config) async {
    try {
      print('IntegrationInstallationService: Testing connection for ${config.name}');
      
      // Use the MCP settings service to test the connection
      final status = await _mcpSettingsService.testMCPServerConnection(integrationId);
      
      if (status.isConnected) {
        return ConnectionResult(
          success: true,
          latency: status.latencyMs ?? 0,
        );
      } else {
        return ConnectionResult(
          success: false,
          error: status.errorMessage ?? 'Connection failed',
        );
      }
    } catch (e) {
      return ConnectionResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  /// Validate URL format
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}

/// Result of integration installation
class InstallationResult {
  final bool success;
  final String integrationId;
  final IntegrationDefinition? integration;
  final String? error;
  final MCPServerConfig? mcpConfig;
  final Map<String, dynamic>? finalConfiguration;
  final PrerequisiteResult? prerequisiteResult;
  final ValidationResult? validationResult;
  final ConnectionResult? connectionResult;

  const InstallationResult({
    required this.success,
    required this.integrationId,
    this.integration,
    this.error,
    this.mcpConfig,
    this.finalConfiguration,
    this.prerequisiteResult,
    this.validationResult,
    this.connectionResult,
  });

  /// User-friendly status message
  String get statusMessage {
    if (success) {
      return '${integration?.name ?? integrationId} installed successfully';
    }
    
    if (prerequisiteResult != null && !prerequisiteResult!.allMet) {
      return 'Missing prerequisites: ${prerequisiteResult!.missingPrerequisites.join(', ')}';
    }
    
    if (validationResult != null && !validationResult!.isValid) {
      return 'Configuration errors: ${validationResult!.errors.join(', ')}';
    }
    
    if (connectionResult != null && !connectionResult!.success) {
      return 'Connection failed: ${connectionResult!.error}';
    }
    
    return error ?? 'Installation failed';
  }
}

/// Result of prerequisite checking
class PrerequisiteResult {
  final bool allMet;
  final List<String> metPrerequisites;
  final List<String> missingPrerequisites;

  const PrerequisiteResult({
    required this.allMet,
    required this.metPrerequisites,
    required this.missingPrerequisites,
  });
}

/// Result of configuration validation
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  const ValidationResult({
    required this.isValid,
    required this.errors,
  });
}

/// Result of connection testing
class ConnectionResult {
  final bool success;
  final String? error;
  final int latency;

  const ConnectionResult({
    required this.success,
    this.error,
    this.latency = 0,
  });
}

/// Integration-specific exceptions
class IntegrationException implements Exception {
  final String message;
  const IntegrationException(this.message);
  @override
  String toString() => 'IntegrationException: $message';
}

/// Provider for integration installation service
final integrationInstallationServiceProvider = Provider<IntegrationInstallationService>((ref) {
  final mcpSettingsService = ref.read(mcpSettingsServiceProvider);
  final integrationService = ref.read(integrationServiceProvider);
  final detectionConfigurationService = ref.read(detectionConfigurationServiceProvider);
  
  return IntegrationInstallationService(
    mcpSettingsService,
    integrationService,
    detectionConfigurationService,
  );
});

/// Integration status enum
enum IntegrationStatus {
  available,
  installing,
  installed,
  active,
  error,
  disabled,
}