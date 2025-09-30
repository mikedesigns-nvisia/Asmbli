import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mcp_catalog_entry.dart';
import 'mcp_catalog_service.dart';
import 'secure_credentials_service.dart';

/// Service for validating MCP server configurations and dependencies
@Deprecated('Will be consolidated into MCPSecurityService. See docs/SERVICE_CONSOLIDATION_PLAN.md')
class MCPValidationService {
  final MCPCatalogService _catalogService;
  final SecureCredentialsService _credentialsService;

  MCPValidationService(this._catalogService, this._credentialsService);

  /// Validate all MCP servers for an agent
  Future<MCPValidationResult> validateAgentMCPConfiguration(String agentId) async {
    final result = MCPValidationResult(agentId: agentId);
    final enabledServerIds = _catalogService.getEnabledServerIds(agentId);

    for (final serverId in enabledServerIds) {
      final serverValidation = await _validateSingleServer(agentId, serverId);
      result.serverValidations[serverId] = serverValidation;

      if (!serverValidation.isValid) {
        result.overallValid = false;
      }
    }

    return result;
  }

  /// Validate a single MCP server configuration
  Future<ServerValidationResult> _validateSingleServer(String agentId, String serverId) async {
    final result = ServerValidationResult(serverId: serverId);

    try {
      // Check if catalog entry exists
      final catalogEntry = _catalogService.getCatalogEntry(serverId);
      if (catalogEntry == null) {
        result.addError(MCPValidationError.catalogEntryNotFound(serverId));
        return result;
      }

      // Validate authentication
      await _validateAuthentication(agentId, serverId, catalogEntry, result);

      // Validate dependencies
      await _validateDependencies(catalogEntry, result);

      // Validate network connectivity for remote servers
      if (catalogEntry.isRemote) {
        await _validateNetworkConnectivity(catalogEntry, result);
      }

      // Validate permissions for local servers
      if (catalogEntry.isLocal) {
        await _validateFilePermissions(catalogEntry, result);
      }

    } catch (e) {
      result.addError(MCPValidationError.unexpectedError(serverId, e.toString()));
    }

    return result;
  }

  /// Validate authentication configuration
  Future<void> _validateAuthentication(
    String agentId,
    String serverId,
    MCPCatalogEntry catalogEntry,
    ServerValidationResult result,
  ) async {
    for (final authReq in catalogEntry.requiredAuth.where((a) => a.required)) {
      final credentialKey = _getMCPCredentialKey(serverId, agentId, authReq.name);
      final credential = await _credentialsService.getCredential(credentialKey);

      if (credential == null || credential.isEmpty) {
        result.addError(MCPValidationError.missingCredential(serverId, authReq.name));
        continue;
      }

      // Validate credential format
      if (!_validateCredentialFormat(authReq, credential)) {
        result.addError(MCPValidationError.invalidCredentialFormat(serverId, authReq.name));
      }
    }
  }

  /// Validate system dependencies
  Future<void> _validateDependencies(
    MCPCatalogEntry catalogEntry,
    ServerValidationResult result,
  ) async {
    if (catalogEntry.command?.isNotEmpty == true) {
      final commandParts = catalogEntry.command!.split(' ');
      final executable = commandParts.first;

      // Check if executable is available
      try {
        final processResult = await Process.run(
          executable,
          ['--version'],
          runInShell: true,
        );

        if (processResult.exitCode != 0) {
          // Try alternative check for package managers
          if (executable == 'uvx' || executable == 'npx') {
            final altResult = await Process.run(
              executable,
              ['--help'],
              runInShell: true,
            );
            
            if (altResult.exitCode != 0) {
              result.addError(MCPValidationError.dependencyNotFound(
                catalogEntry.id, 
                executable,
              ));
            }
          } else {
            result.addError(MCPValidationError.dependencyNotFound(
              catalogEntry.id,
              executable,
            ));
          }
        }
      } catch (e) {
        result.addError(MCPValidationError.dependencyCheckFailed(
          catalogEntry.id,
          executable,
          e.toString(),
        ));
      }
    }

    // Check for specific platform dependencies
    await _validatePlatformDependencies(catalogEntry, result);
  }

  /// Validate platform-specific dependencies
  Future<void> _validatePlatformDependencies(
    MCPCatalogEntry catalogEntry,
    ServerValidationResult result,
  ) async {
    final currentPlatform = Platform.operatingSystem;
    
    if (!catalogEntry.supportedPlatforms.contains('desktop') && 
        !catalogEntry.supportedPlatforms.contains(currentPlatform)) {
      result.addError(MCPValidationError.platformNotSupported(
        catalogEntry.id,
        currentPlatform,
        catalogEntry.supportedPlatforms,
      ));
    }

    // Check specific dependencies based on server type
    switch (catalogEntry.category) {
      case MCPServerCategory.development:
        if (catalogEntry.id == 'github') {
          await _checkGitInstallation(catalogEntry, result);
        }
        break;
      case MCPServerCategory.filesystem:
        await _checkFileSystemAccess(result);
        break;
      case MCPServerCategory.web:
        await _checkNetworkAccess(result);
        break;
      default:
        break;
    }
  }

  /// Check Git installation for GitHub server
  Future<void> _checkGitInstallation(
    MCPCatalogEntry catalogEntry,
    ServerValidationResult result,
  ) async {
    try {
      final gitResult = await Process.run('git', ['--version'], runInShell: true);
      if (gitResult.exitCode != 0) {
        result.addWarning(MCPValidationWarning.optionalDependencyMissing(
          catalogEntry.id,
          'git',
          'Git is recommended for GitHub operations',
        ));
      }
    } catch (e) {
      result.addWarning(MCPValidationWarning.optionalDependencyMissing(
        catalogEntry.id,
        'git',
        'Git is recommended for GitHub operations',
      ));
    }
  }

  /// Check filesystem access
  Future<void> _checkFileSystemAccess(ServerValidationResult result) async {
    try {
      final tempDir = Directory.systemTemp;
      if (!await tempDir.exists()) {
        result.addError(MCPValidationError.fileSystemAccessDenied(
          'filesystem',
          'Cannot access system temp directory',
        ));
      }
    } catch (e) {
      result.addError(MCPValidationError.fileSystemAccessDenied(
        'filesystem',
        e.toString(),
      ));
    }
  }

  /// Check network access
  Future<void> _checkNetworkAccess(ServerValidationResult result) async {
    try {
      // Simple connectivity test
      final socket = await Socket.connect('8.8.8.8', 53, timeout: Duration(seconds: 3));
      await socket.close();
    } catch (e) {
      result.addWarning(MCPValidationWarning.networkConnectivityIssue(
        'web',
        'Network connectivity may be limited',
      ));
    }
  }

  /// Validate network connectivity for remote servers
  Future<void> _validateNetworkConnectivity(
    MCPCatalogEntry catalogEntry,
    ServerValidationResult result,
  ) async {
    if (catalogEntry.remoteUrl?.isNotEmpty == true) {
      try {
        final uri = Uri.parse(catalogEntry.remoteUrl!);
        final socket = await Socket.connect(
          uri.host,
          uri.port,
          timeout: Duration(seconds: 5),
        );
        await socket.close();
      } catch (e) {
        result.addError(MCPValidationError.networkConnectivityFailed(
          catalogEntry.id,
          catalogEntry.remoteUrl!,
          e.toString(),
        ));
      }
    }
  }

  /// Validate file permissions
  Future<void> _validateFilePermissions(
    MCPCatalogEntry catalogEntry,
    ServerValidationResult result,
  ) async {
    // Check if we can write to temp directory for server operations
    try {
      final tempDir = Directory.systemTemp;
      final testFile = File('${tempDir.path}/mcp_test_${DateTime.now().millisecondsSinceEpoch}');
      
      await testFile.writeAsString('test');
      await testFile.delete();
    } catch (e) {
      result.addWarning(MCPValidationWarning.filePermissionIssue(
        catalogEntry.id,
        'Limited file system permissions detected',
      ));
    }
  }

  /// Validate credential format based on auth requirement
  bool _validateCredentialFormat(MCPAuthRequirement authReq, String credential) {
    switch (authReq.type) {
      case MCPAuthType.apiKey:
        return credential.length >= 16 && !credential.contains(' ');
      case MCPAuthType.bearerToken:
        if (authReq.name.toLowerCase().contains('github')) {
          return credential.startsWith('ghp_') || credential.startsWith('github_pat_');
        }
        if (authReq.name.toLowerCase().contains('slack')) {
          return credential.startsWith('xoxb-') || credential.startsWith('xoxp-');
        }
        return credential.length >= 16;
      case MCPAuthType.basicAuth:
        return credential.contains(':') && credential.length >= 8;
      case MCPAuthType.oauth:
        return credential.length >= 32; // OAuth tokens are typically long
      case MCPAuthType.database:
        return credential.contains(':') && credential.length >= 8; // Similar to basic auth
      case MCPAuthType.complex:
        return credential.isNotEmpty && credential.length >= 8;
      case MCPAuthType.custom:
        return credential.isNotEmpty;
    }
  }

  /// Generate scoped credential key for MCP servers
  String _getMCPCredentialKey(String serverId, String agentId, String credentialName) {
    return 'mcp:$agentId:$serverId:$credentialName';
  }

  /// Get system requirements for an MCP server
  List<String> getSystemRequirements(String serverId) {
    final catalogEntry = _catalogService.getCatalogEntry(serverId);
    if (catalogEntry == null) return [];

    final requirements = <String>[];

    // Add command requirements
    if (catalogEntry.command?.isNotEmpty == true) {
      final executable = catalogEntry.command!.split(' ').first;
      requirements.add(executable);
    }

    // Add platform requirements
    requirements.addAll(catalogEntry.supportedPlatforms);

    // Add category-specific requirements
    switch (catalogEntry.category) {
      case MCPServerCategory.development:
        if (catalogEntry.id == 'github') {
          requirements.add('git (recommended)');
        }
        break;
      case MCPServerCategory.web:
        requirements.add('Internet connectivity');
        break;
      case MCPServerCategory.filesystem:
        requirements.add('File system access');
        break;
      default:
        break;
    }

    return requirements;
  }

  /// Get setup instructions for fixing validation errors
  List<String> getSetupInstructions(List<MCPValidationError> errors) {
    final instructions = <String>[];
    final seenInstructions = <String>{};

    for (final error in errors) {
      final instruction = _getInstructionForError(error);
      if (instruction != null && !seenInstructions.contains(instruction)) {
        instructions.add(instruction);
        seenInstructions.add(instruction);
      }
    }

    return instructions;
  }

  String? _getInstructionForError(MCPValidationError error) {
    switch (error.type) {
      case MCPValidationErrorType.dependencyNotFound:
        return 'Install ${error.details['dependency']}: Visit the official website or use a package manager';
      case MCPValidationErrorType.missingCredential:
        return 'Configure ${error.details['credentialName']} in the MCP server setup dialog';
      case MCPValidationErrorType.platformNotSupported:
        return 'This server is not supported on ${error.details['currentPlatform']}';
      case MCPValidationErrorType.networkConnectivityFailed:
        return 'Check your internet connection and firewall settings';
      case MCPValidationErrorType.fileSystemAccessDenied:
        return 'Grant file system permissions to the application';
      default:
        return null;
    }
  }
}

// ==================== Data Models ====================

class MCPValidationResult {
  final String agentId;
  bool overallValid = true;
  final Map<String, ServerValidationResult> serverValidations = {};

  MCPValidationResult({required this.agentId});

  List<MCPValidationError> get allErrors {
    return serverValidations.values
        .expand((result) => result.errors)
        .toList();
  }

  List<MCPValidationWarning> get allWarnings {
    return serverValidations.values
        .expand((result) => result.warnings)
        .toList();
  }
}

class ServerValidationResult {
  final String serverId;
  final List<MCPValidationError> errors = [];
  final List<MCPValidationWarning> warnings = [];

  ServerValidationResult({required this.serverId});

  bool get isValid => errors.isEmpty;
  bool get hasWarnings => warnings.isNotEmpty;

  void addError(MCPValidationError error) => errors.add(error);
  void addWarning(MCPValidationWarning warning) => warnings.add(warning);
}

class MCPValidationError {
  final String serverId;
  final MCPValidationErrorType type;
  final String message;
  final Map<String, dynamic> details;

  MCPValidationError({
    required this.serverId,
    required this.type,
    required this.message,
    this.details = const {},
  });

  factory MCPValidationError.catalogEntryNotFound(String serverId) {
    return MCPValidationError(
      serverId: serverId,
      type: MCPValidationErrorType.catalogEntryNotFound,
      message: 'Catalog entry not found for server: $serverId',
      details: {'serverId': serverId},
    );
  }

  factory MCPValidationError.missingCredential(String serverId, String credentialName) {
    return MCPValidationError(
      serverId: serverId,
      type: MCPValidationErrorType.missingCredential,
      message: 'Missing required credential: $credentialName',
      details: {'credentialName': credentialName},
    );
  }

  factory MCPValidationError.invalidCredentialFormat(String serverId, String credentialName) {
    return MCPValidationError(
      serverId: serverId,
      type: MCPValidationErrorType.invalidCredentialFormat,
      message: 'Invalid format for credential: $credentialName',
      details: {'credentialName': credentialName},
    );
  }

  factory MCPValidationError.dependencyNotFound(String serverId, String dependency) {
    return MCPValidationError(
      serverId: serverId,
      type: MCPValidationErrorType.dependencyNotFound,
      message: 'Required dependency not found: $dependency',
      details: {'dependency': dependency},
    );
  }

  factory MCPValidationError.dependencyCheckFailed(String serverId, String dependency, String error) {
    return MCPValidationError(
      serverId: serverId,
      type: MCPValidationErrorType.dependencyCheckFailed,
      message: 'Failed to check dependency $dependency: $error',
      details: {'dependency': dependency, 'error': error},
    );
  }

  factory MCPValidationError.platformNotSupported(String serverId, String currentPlatform, List<String> supportedPlatforms) {
    return MCPValidationError(
      serverId: serverId,
      type: MCPValidationErrorType.platformNotSupported,
      message: 'Platform $currentPlatform not supported. Supported: ${supportedPlatforms.join(", ")}',
      details: {'currentPlatform': currentPlatform, 'supportedPlatforms': supportedPlatforms},
    );
  }

  factory MCPValidationError.networkConnectivityFailed(String serverId, String url, String error) {
    return MCPValidationError(
      serverId: serverId,
      type: MCPValidationErrorType.networkConnectivityFailed,
      message: 'Failed to connect to $url: $error',
      details: {'url': url, 'error': error},
    );
  }

  factory MCPValidationError.fileSystemAccessDenied(String serverId, String error) {
    return MCPValidationError(
      serverId: serverId,
      type: MCPValidationErrorType.fileSystemAccessDenied,
      message: 'File system access denied: $error',
      details: {'error': error},
    );
  }

  factory MCPValidationError.unexpectedError(String serverId, String error) {
    return MCPValidationError(
      serverId: serverId,
      type: MCPValidationErrorType.unexpectedError,
      message: 'Unexpected validation error: $error',
      details: {'error': error},
    );
  }
}

class MCPValidationWarning {
  final String serverId;
  final MCPValidationWarningType type;
  final String message;
  final Map<String, dynamic> details;

  MCPValidationWarning({
    required this.serverId,
    required this.type,
    required this.message,
    this.details = const {},
  });

  factory MCPValidationWarning.optionalDependencyMissing(String serverId, String dependency, String description) {
    return MCPValidationWarning(
      serverId: serverId,
      type: MCPValidationWarningType.optionalDependencyMissing,
      message: 'Optional dependency missing: $dependency - $description',
      details: {'dependency': dependency, 'description': description},
    );
  }

  factory MCPValidationWarning.networkConnectivityIssue(String serverId, String description) {
    return MCPValidationWarning(
      serverId: serverId,
      type: MCPValidationWarningType.networkConnectivityIssue,
      message: 'Network connectivity issue: $description',
      details: {'description': description},
    );
  }

  factory MCPValidationWarning.filePermissionIssue(String serverId, String description) {
    return MCPValidationWarning(
      serverId: serverId,
      type: MCPValidationWarningType.filePermissionIssue,
      message: 'File permission issue: $description',
      details: {'description': description},
    );
  }
}

enum MCPValidationErrorType {
  catalogEntryNotFound,
  missingCredential,
  invalidCredentialFormat,
  dependencyNotFound,
  dependencyCheckFailed,
  platformNotSupported,
  networkConnectivityFailed,
  fileSystemAccessDenied,
  unexpectedError,
}

enum MCPValidationWarningType {
  optionalDependencyMissing,
  networkConnectivityIssue,
  filePermissionIssue,
}

// ==================== Riverpod Providers ====================

final mcpValidationServiceProvider = Provider<MCPValidationService>((ref) {
  final catalogService = ref.read(mcpCatalogServiceProvider);
  final credentialsService = ref.read(secureCredentialsServiceProvider);
  return MCPValidationService(catalogService, credentialsService);
});

/// Provider for validating a specific agent's MCP configuration
final agentMCPValidationProvider = FutureProvider.family<MCPValidationResult, String>((ref, agentId) async {
  final service = ref.read(mcpValidationServiceProvider);
  return await service.validateAgentMCPConfiguration(agentId);
});