import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mcp_server_process.dart';
import '../models/mcp_catalog_entry.dart';
import '../models/agent_terminal.dart';
import 'production_logger.dart';
import 'mcp_catalog_service.dart';

/// Service for installing MCP servers using uvx/npx in agent terminals
class MCPInstallationService {
  static const Duration _installTimeout = Duration(minutes: 5);
  static const Duration _checkTimeout = Duration(seconds: 30);
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  final MCPCatalogService _catalogService;
  final Map<String, StreamController<MCPInstallationProgress>> _progressStreams = {};

  MCPInstallationService(this._catalogService);

  /// Install MCP server in agent terminal with progress tracking and retry logic
  Future<MCPInstallResult> installServerInTerminal(
    String agentId,
    String serverId,
    AgentTerminal terminal, {
    Map<String, String>? additionalEnvironment,
  }) async {
    final catalogEntry = _catalogService.getCatalogEntry(serverId);
    if (catalogEntry == null) {
      throw MCPInstallationException('Server not found in catalog: $serverId');
    }

    return await _installWithRetry(
      agentId,
      serverId,
      catalogEntry,
      terminal,
      additionalEnvironment: additionalEnvironment,
    );
  }

  /// Install MCP server using appropriate package manager (legacy method)
  Future<MCPInstallResult> installServer(
    String serverId,
    MCPCatalogEntry catalogEntry, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    final startTime = DateTime.now();
    final installationLogs = <String>[];

    try {
      ProductionLogger.instance.info(
        'Starting MCP server installation',
        data: {
          'server_id': serverId,
          'server_name': catalogEntry.name,
          'command': catalogEntry.command,
        },
        category: 'mcp_installation',
      );

      // Determine installation method
      final installMethod = _determineInstallMethod(catalogEntry);
      
      // Check if package manager is available
      await _checkPackageManagerAvailability(installMethod);

      // Perform installation
      final installResult = await _performInstallation(
        catalogEntry,
        installMethod,
        workingDirectory: workingDirectory,
        environment: environment,
        logs: installationLogs,
      );

      if (!installResult) {
        throw MCPInstallationException('Installation failed for $serverId');
      }

      // Verify installation
      final verificationResult = await _verifyInstallation(catalogEntry, installationLogs);
      
      if (!verificationResult) {
        throw MCPInstallationException('Installation verification failed for $serverId');
      }

      final installationTime = DateTime.now().difference(startTime);
      
      ProductionLogger.instance.info(
        'MCP server installation completed successfully',
        data: {
          'server_id': serverId,
          'installation_time_ms': installationTime.inMilliseconds,
        },
        category: 'mcp_installation',
      );

      return MCPInstallResult(
        success: true,
        serverId: serverId,
        installationTime: installationTime,
        installationLogs: installationLogs,
      );
    } catch (e) {
      final installationTime = DateTime.now().difference(startTime);
      
      ProductionLogger.instance.error(
        'MCP server installation failed',
        error: e,
        data: {
          'server_id': serverId,
          'installation_time_ms': installationTime.inMilliseconds,
          'logs': installationLogs,
        },
        category: 'mcp_installation',
      );

      return MCPInstallResult(
        success: false,
        serverId: serverId,
        error: e.toString(),
        installationTime: installationTime,
        installationLogs: installationLogs,
      );
    }
  }

  /// Determine the installation method based on the command
  MCPInstallMethod _determineInstallMethod(MCPCatalogEntry catalogEntry) {
    final command = catalogEntry.command?.toLowerCase() ?? '';
    
    if (command.startsWith('uvx') || command.contains('uvx')) {
      return MCPInstallMethod.uvx;
    } else if (command.startsWith('npx') || command.contains('npx')) {
      return MCPInstallMethod.npx;
    } else if (command.startsWith('pip') || command.contains('pip')) {
      return MCPInstallMethod.pip;
    } else {
      // Default to uvx for official MCP servers
      return MCPInstallMethod.uvx;
    }
  }

  /// Check if the required package manager is available
  Future<void> _checkPackageManagerAvailability(MCPInstallMethod method) async {
    String command;
    List<String> args;

    switch (method) {
      case MCPInstallMethod.uvx:
        command = 'uvx';
        args = ['--version'];
        break;
      case MCPInstallMethod.npx:
        command = 'npx';
        args = ['--version'];
        break;
      case MCPInstallMethod.pip:
        command = 'pip';
        args = ['--version'];
        break;
    }

    try {
      final result = await Process.run(
        command,
        args,
        runInShell: true,
      ).timeout(_checkTimeout);

      if (result.exitCode != 0) {
        throw MCPInstallationException(
          '$command is not available or not working properly. '
          'Exit code: ${result.exitCode}, Error: ${result.stderr}',
        );
      }

      print('✅ $command is available: ${result.stdout.toString().trim()}');
    } catch (e) {
      if (e is TimeoutException) {
        throw MCPInstallationException('$command check timed out');
      }
      throw MCPInstallationException('$command is not available: $e');
    }
  }

  /// Perform the actual installation
  Future<bool> _performInstallation(
    MCPCatalogEntry catalogEntry,
    MCPInstallMethod method,
    {
    String? workingDirectory,
    Map<String, String>? environment,
    required List<String> logs,
  }) async {
    // Parse the command to extract package name
    final packageName = _extractPackageName(catalogEntry, method);
    
    String command;
    List<String> args;

    switch (method) {
      case MCPInstallMethod.uvx:
        command = 'uvx';
        args = ['--help']; // First check if uvx works
        break;
      case MCPInstallMethod.npx:
        command = 'npm';
        args = ['install', '-g', packageName]; // Install globally with npm
        break;
      case MCPInstallMethod.pip:
        command = 'pip';
        args = ['install', packageName];
        break;
    }

    // For uvx, we don't need to install - it runs packages directly
    if (method == MCPInstallMethod.uvx) {
      logs.add('Using uvx - no installation required, will run package directly');
      return true;
    }

    try {
      logs.add('Starting installation: $command ${args.join(' ')}');
      
      final process = await Process.start(
        command,
        args,
        workingDirectory: workingDirectory,
        environment: environment != null 
            ? {...Platform.environment, ...environment}
            : null,
        runInShell: true,
      );

      // Capture output
      final stdoutCompleter = Completer<String>();
      final stderrCompleter = Completer<String>();

      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        logs.add('STDOUT: $line');
        print('Installation STDOUT: $line');
      }, onDone: () => stdoutCompleter.complete(''));

      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        logs.add('STDERR: $line');
        print('Installation STDERR: $line');
      }, onDone: () => stderrCompleter.complete(''));

      // Wait for process completion with timeout
      final exitCode = await process.exitCode.timeout(_installTimeout);
      
      await Future.wait([stdoutCompleter.future, stderrCompleter.future]);

      logs.add('Installation completed with exit code: $exitCode');
      
      return exitCode == 0;
    } catch (e) {
      logs.add('Installation error: $e');
      return false;
    }
  }

  /// Extract package name from catalog entry
  String _extractPackageName(MCPCatalogEntry catalogEntry, MCPInstallMethod method) {
    final command = catalogEntry.command ?? '';
    
    // For uvx commands like "uvx @modelcontextprotocol/server-filesystem"
    if (command.startsWith('uvx ')) {
      final parts = command.split(' ');
      if (parts.length > 1) {
        return parts[1]; // Return the package name
      }
    }
    
    // For npx commands
    if (command.startsWith('npx ')) {
      final parts = command.split(' ');
      if (parts.length > 1) {
        return parts[1];
      }
    }

    // Default fallback - try to extract from args
    if (catalogEntry.args.isNotEmpty) {
      return catalogEntry.args.first;
    }

    throw MCPInstallationException('Could not determine package name for ${catalogEntry.id}');
  }

  /// Verify that the installation was successful
  Future<bool> _verifyInstallation(MCPCatalogEntry catalogEntry, List<String> logs) async {
    try {
      logs.add('Verifying installation...');
      
      // For uvx, we can test by running the command with --help
      final command = catalogEntry.command ?? 'uvx';
      final args = [...catalogEntry.args, '--help'];

      final result = await Process.run(
        command,
        args,
        runInShell: true,
      ).timeout(_checkTimeout);

      logs.add('Verification exit code: ${result.exitCode}');
      
      if (result.exitCode == 0) {
        logs.add('✅ Installation verified successfully');
        return true;
      } else {
        logs.add('❌ Verification failed: ${result.stderr}');
        return false;
      }
    } catch (e) {
      logs.add('❌ Verification error: $e');
      return false;
    }
  }

  /// Check if a server is already installed
  Future<bool> isServerInstalled(MCPCatalogEntry catalogEntry) async {
    try {
      final method = _determineInstallMethod(catalogEntry);
      
      // For uvx, we don't need to check installation - it handles packages dynamically
      if (method == MCPInstallMethod.uvx) {
        return true;
      }

      // For other methods, try to run the command
      final command = catalogEntry.command ?? '';
      final args = [...catalogEntry.args, '--help'];

      final result = await Process.run(
        command,
        args,
        runInShell: true,
      ).timeout(_checkTimeout);

      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Install with retry mechanism
  Future<MCPInstallResult> _installWithRetry(
    String agentId,
    String serverId,
    MCPCatalogEntry catalogEntry,
    AgentTerminal terminal, {
    Map<String, String>? additionalEnvironment,
  }) async {
    final startTime = DateTime.now();
    final installationLogs = <String>[];
    Exception? lastException;

    // Create progress stream
    final progressController = StreamController<MCPInstallationProgress>.broadcast();
    _progressStreams[agentId] = progressController;

    try {
      _emitProgress(agentId, MCPInstallationProgress(
        agentId: agentId,
        serverId: serverId,
        stage: MCPInstallationStage.starting,
        progress: 0.0,
        message: 'Starting MCP server installation',
      ));

      ProductionLogger.instance.info(
        'Starting MCP server installation in agent terminal',
        data: {
          'agent_id': agentId,
          'server_id': serverId,
          'server_name': catalogEntry.name,
          'command': catalogEntry.command,
        },
        category: 'mcp_installation',
      );

      // Determine installation method
      final installMethod = _determineInstallMethod(catalogEntry);
      
      _emitProgress(agentId, MCPInstallationProgress(
        agentId: agentId,
        serverId: serverId,
        stage: MCPInstallationStage.checkingDependencies,
        progress: 0.1,
        message: 'Checking package manager availability',
      ));

      // Check if package manager is available
      await _checkPackageManagerInTerminal(terminal, installMethod, installationLogs);

      // Attempt installation with retries
      for (int attempt = 1; attempt <= _maxRetries; attempt++) {
        try {
          _emitProgress(agentId, MCPInstallationProgress(
            agentId: agentId,
            serverId: serverId,
            stage: MCPInstallationStage.installing,
            progress: 0.2 + (attempt - 1) * 0.2,
            message: 'Installation attempt $attempt of $_maxRetries',
          ));

          installationLogs.add('=== Installation Attempt $attempt ===');
          
          final installResult = await _performInstallationInTerminal(
            terminal,
            catalogEntry,
            installMethod,
            additionalEnvironment: additionalEnvironment,
            logs: installationLogs,
          );

          if (installResult) {
            _emitProgress(agentId, MCPInstallationProgress(
              agentId: agentId,
              serverId: serverId,
              stage: MCPInstallationStage.verifying,
              progress: 0.8,
              message: 'Verifying installation',
            ));

            // Verify installation
            final verificationResult = await _verifyInstallationInTerminal(
              terminal, 
              catalogEntry, 
              installationLogs,
            );
            
            if (verificationResult) {
              final installationTime = DateTime.now().difference(startTime);
              
              _emitProgress(agentId, MCPInstallationProgress(
                agentId: agentId,
                serverId: serverId,
                stage: MCPInstallationStage.completed,
                progress: 1.0,
                message: 'Installation completed successfully',
              ));

              ProductionLogger.instance.info(
                'MCP server installation completed successfully',
                data: {
                  'agent_id': agentId,
                  'server_id': serverId,
                  'installation_time_ms': installationTime.inMilliseconds,
                  'attempts': attempt,
                },
                category: 'mcp_installation',
              );

              return MCPInstallResult(
                success: true,
                serverId: serverId,
                installationTime: installationTime,
                installationLogs: installationLogs,
              );
            }
          }

          // If we get here, installation or verification failed
          if (attempt < _maxRetries) {
            installationLogs.add('Installation attempt $attempt failed, retrying in ${_retryDelay.inSeconds} seconds...');
            await Future.delayed(_retryDelay);
          }

        } catch (e) {
          lastException = e is Exception ? e : Exception(e.toString());
          installationLogs.add('Installation attempt $attempt failed with error: $e');
          
          if (attempt < _maxRetries) {
            installationLogs.add('Retrying in ${_retryDelay.inSeconds} seconds...');
            await Future.delayed(_retryDelay);
          }
        }
      }

      // All attempts failed
      final installationTime = DateTime.now().difference(startTime);
      final error = lastException?.toString() ?? 'Installation failed after $_maxRetries attempts';
      
      _emitProgress(agentId, MCPInstallationProgress(
        agentId: agentId,
        serverId: serverId,
        stage: MCPInstallationStage.failed,
        progress: 0.0,
        message: 'Installation failed after $_maxRetries attempts',
        error: error,
      ));

      ProductionLogger.instance.error(
        'MCP server installation failed after all retries',
        error: lastException,
        data: {
          'agent_id': agentId,
          'server_id': serverId,
          'installation_time_ms': installationTime.inMilliseconds,
          'attempts': _maxRetries,
          'logs': installationLogs,
        },
        category: 'mcp_installation',
      );

      return MCPInstallResult(
        success: false,
        serverId: serverId,
        error: error,
        installationTime: installationTime,
        installationLogs: installationLogs,
      );

    } finally {
      // Clean up progress stream
      progressController.close();
      _progressStreams.remove(agentId);
    }
  }

  /// Check package manager availability in terminal
  Future<void> _checkPackageManagerInTerminal(
    AgentTerminal terminal,
    MCPInstallMethod method,
    List<String> logs,
  ) async {
    String command;
    List<String> args;

    switch (method) {
      case MCPInstallMethod.uvx:
        command = 'uvx --version';
        break;
      case MCPInstallMethod.npx:
        command = 'npx --version';
        break;
      case MCPInstallMethod.pip:
        command = 'pip --version';
        break;
    }

    try {
      logs.add('Checking package manager: $command');
      final result = await terminal.execute(command);

      if (result.exitCode != 0) {
        throw MCPInstallationException(
          '${method.name} is not available or not working properly. '
          'Exit code: ${result.exitCode}, Error: ${result.stderr}',
        );
      }

      logs.add('✅ ${method.name} is available: ${result.stdout.trim()}');
    } catch (e) {
      logs.add('❌ ${method.name} check failed: $e');
      throw MCPInstallationException('${method.name} is not available: $e');
    }
  }

  /// Perform installation in agent terminal
  Future<bool> _performInstallationInTerminal(
    AgentTerminal terminal,
    MCPCatalogEntry catalogEntry,
    MCPInstallMethod method, {
    Map<String, String>? additionalEnvironment,
    required List<String> logs,
  }) async {
    // Set additional environment variables if provided
    if (additionalEnvironment != null) {
      for (final entry in additionalEnvironment.entries) {
        await terminal.setEnvironment(entry.key, entry.value);
        logs.add('Set environment variable: ${entry.key}');
      }
    }

    // Parse the command to extract package name
    final packageName = _extractPackageName(catalogEntry, method);
    
    String command;

    switch (method) {
      case MCPInstallMethod.uvx:
        // For uvx, we don't need to install - it runs packages directly
        logs.add('Using uvx - no installation required, will run package directly');
        return true;
      case MCPInstallMethod.npx:
        command = 'npm install -g $packageName';
        break;
      case MCPInstallMethod.pip:
        command = 'pip install $packageName';
        break;
    }

    try {
      logs.add('Starting installation: $command');
      
      final result = await terminal.execute(command);
      
      logs.add('Installation completed with exit code: ${result.exitCode}');
      
      if (result.stdout.isNotEmpty) {
        logs.add('STDOUT: ${result.stdout}');
      }
      
      if (result.stderr.isNotEmpty) {
        logs.add('STDERR: ${result.stderr}');
      }
      
      return result.exitCode == 0;
    } catch (e) {
      logs.add('Installation error: $e');
      return false;
    }
  }

  /// Verify installation in agent terminal
  Future<bool> _verifyInstallationInTerminal(
    AgentTerminal terminal,
    MCPCatalogEntry catalogEntry,
    List<String> logs,
  ) async {
    try {
      logs.add('Verifying installation...');
      
      // For uvx, we can test by running the command with --help
      final command = '${catalogEntry.command} ${catalogEntry.args.join(' ')} --help';

      final result = await terminal.execute(command);

      logs.add('Verification exit code: ${result.exitCode}');
      
      if (result.exitCode == 0) {
        logs.add('✅ Installation verified successfully');
        return true;
      } else {
        logs.add('❌ Verification failed: ${result.stderr}');
        return false;
      }
    } catch (e) {
      logs.add('❌ Verification error: $e');
      return false;
    }
  }

  /// Get installation progress stream for an agent
  Stream<MCPInstallationProgress>? getInstallationProgress(String agentId) {
    return _progressStreams[agentId]?.stream;
  }

  /// Emit progress update
  void _emitProgress(String agentId, MCPInstallationProgress progress) {
    final controller = _progressStreams[agentId];
    if (controller != null && !controller.isClosed) {
      controller.add(progress);
    }
  }

  /// Check if server is installed in agent terminal
  Future<bool> isServerInstalledInTerminal(
    AgentTerminal terminal,
    String serverId,
  ) async {
    final catalogEntry = _catalogService.getCatalogEntry(serverId);
    if (catalogEntry == null) {
      return false;
    }

    try {
      final method = _determineInstallMethod(catalogEntry);
      
      // For uvx, we don't need to check installation - it handles packages dynamically
      if (method == MCPInstallMethod.uvx) {
        return true;
      }

      // For other methods, try to run the command
      final command = '${catalogEntry.command} ${catalogEntry.args.join(' ')} --help';

      final result = await terminal.execute(command);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Uninstall MCP server from agent terminal
  Future<bool> uninstallServerFromTerminal(
    AgentTerminal terminal,
    String serverId,
  ) async {
    final catalogEntry = _catalogService.getCatalogEntry(serverId);
    if (catalogEntry == null) {
      return false;
    }

    try {
      final method = _determineInstallMethod(catalogEntry);
      
      // For uvx, no uninstallation needed
      if (method == MCPInstallMethod.uvx) {
        return true;
      }

      final packageName = _extractPackageName(catalogEntry, method);
      
      String command;

      switch (method) {
        case MCPInstallMethod.uvx:
          return true; // No uninstall needed
        case MCPInstallMethod.npx:
          command = 'npm uninstall -g $packageName';
          break;
        case MCPInstallMethod.pip:
          command = 'pip uninstall -y $packageName';
          break;
      }

      final result = await terminal.execute(command);
      return result.exitCode == 0;
    } catch (e) {
      ProductionLogger.instance.error(
        'Uninstallation error',
        error: e,
        data: {'server_id': serverId},
        category: 'mcp_installation',
      );
      return false;
    }
  }

  /// Uninstall MCP server (legacy method)
  Future<bool> uninstallServer(MCPCatalogEntry catalogEntry) async {
    try {
      final method = _determineInstallMethod(catalogEntry);
      
      // For uvx, no uninstallation needed
      if (method == MCPInstallMethod.uvx) {
        return true;
      }

      final packageName = _extractPackageName(catalogEntry, method);
      
      String command;
      List<String> args;

      switch (method) {
        case MCPInstallMethod.uvx:
          return true; // No uninstall needed
        case MCPInstallMethod.npx:
          command = 'npm';
          args = ['uninstall', '-g', packageName];
          break;
        case MCPInstallMethod.pip:
          command = 'pip';
          args = ['uninstall', '-y', packageName];
          break;
      }

      final result = await Process.run(
        command,
        args,
        runInShell: true,
      ).timeout(_installTimeout);

      return result.exitCode == 0;
    } catch (e) {
      print('Uninstallation error: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    for (final controller in _progressStreams.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _progressStreams.clear();
  }

  /// Check if MCP should be installed when agent loads
  bool shouldInstallMCPOnAgentLoad(String agentId) {
    // Check if agent has MCP servers that need installation
    // This is a simplified implementation
    return true;
  }

  /// Check agent MCP requirements
  Future<List<String>> checkAgentMCPRequirements(String agentId) async {
    // Return list of required MCP server IDs for this agent
    // This is a simplified implementation
    return [];
  }

  /// Install MCP servers for an agent
  Future<void> installMCPServers(String agentId, List<String> serverIds) async {
    // Install multiple MCP servers for an agent
    for (final serverId in serverIds) {
      try {
        final catalogEntry = _catalogService.getCatalogEntry(serverId);
        if (catalogEntry != null) {
          await installServer(serverId, catalogEntry);
        }
      } catch (e) {
        ProductionLogger.instance.error(
          'Failed to install MCP server',
          error: e,
          data: {'agent_id': agentId, 'server_id': serverId},
          category: 'mcp_installation',
        );
      }
    }
  }

  /// Mark agent as used in conversation
  void markAgentUsedInConversation(String agentId) {
    // Track agent usage for analytics
    ProductionLogger.instance.info(
      'Agent used in conversation',
      data: {'agent_id': agentId},
      category: 'agent_usage',
    );
  }
}

/// Installation methods for MCP servers
enum MCPInstallMethod {
  uvx,  // Python uvx (recommended)
  npx,  // Node.js npx
  pip,  // Python pip
}

/// Exception thrown during MCP installation
class MCPInstallationException implements Exception {
  final String message;
  MCPInstallationException(this.message);

  @override
  String toString() => 'MCPInstallationException: $message';
}

// ==================== Riverpod Provider ====================

final mcpInstallationServiceProvider = Provider<MCPInstallationService>((ref) {
  final catalogService = ref.watch(mcpCatalogServiceProvider);
  return MCPInstallationService(catalogService);
});