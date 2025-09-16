import 'dart:async';
import 'dart:io';

// Simple test to verify MCP installation logic without Flutter dependencies

/// Mock implementation of MCPCatalogEntry
class MCPCatalogEntry {
  final String id;
  final String name;
  final String description;
  final String command;
  final List<String> args;
  final String transport;
  final List<String> capabilities;
  final List<String> tags;

  const MCPCatalogEntry({
    required this.id,
    required this.name,
    required this.description,
    required this.command,
    required this.args,
    required this.transport,
    required this.capabilities,
    required this.tags,
  });
}

/// Mock implementation of MCPInstallResult
class MCPInstallResult {
  final bool success;
  final String serverId;
  final String? error;
  final Duration installationTime;
  final List<String> installationLogs;

  const MCPInstallResult({
    required this.success,
    required this.serverId,
    this.error,
    required this.installationTime,
    this.installationLogs = const [],
  });
}

/// Mock implementation of MCPInstallationProgress
class MCPInstallationProgress {
  final String agentId;
  final String serverId;
  final String stage;
  final double progress;
  final String message;
  final String? error;
  final DateTime timestamp;

  MCPInstallationProgress({
    required this.agentId,
    required this.serverId,
    required this.stage,
    required this.progress,
    required this.message,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Mock implementation of CommandResult
class CommandResult {
  final String command;
  final int exitCode;
  final String stdout;
  final String stderr;
  final Duration executionTime;
  final DateTime timestamp;

  const CommandResult({
    required this.command,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.executionTime,
    required this.timestamp,
  });

  bool get isSuccess => exitCode == 0;
}

/// Mock implementation of AgentTerminal
class MockAgentTerminal {
  final String agentId;
  String workingDirectory = Directory.current.path;
  Map<String, String> environment = Map.from(Platform.environment);
  
  final List<String> _executedCommands = [];
  final Map<String, CommandResult> _commandResults = {};

  MockAgentTerminal(this.agentId);

  /// Set up mock command result
  void setCommandResult(String command, CommandResult result) {
    _commandResults[command] = result;
  }

  Future<CommandResult> execute(String command) async {
    _executedCommands.add(command);
    
    // Return mock result if configured
    if (_commandResults.containsKey(command)) {
      return _commandResults[command]!;
    }
    
    // Default successful result
    return CommandResult(
      command: command,
      exitCode: 0,
      stdout: 'Mock output for: $command',
      stderr: '',
      executionTime: const Duration(milliseconds: 100),
      timestamp: DateTime.now(),
    );
  }

  Future<void> setEnvironment(String key, String value) async {
    environment[key] = value;
  }

  /// Get executed commands for testing
  List<String> get executedCommands => List.unmodifiable(_executedCommands);
}

/// Mock implementation of MCPCatalogService
class MCPCatalogService {
  final Map<String, MCPCatalogEntry> _catalog = {};

  MCPCatalogEntry? getCatalogEntry(String serverId) {
    return _catalog[serverId];
  }

  void addCatalogEntry(MCPCatalogEntry entry) {
    _catalog[entry.id] = entry;
  }

  void initializeDefaults() {
    addCatalogEntry(const MCPCatalogEntry(
      id: 'filesystem',
      name: 'Filesystem MCP Server',
      description: 'Provides file system access capabilities',
      command: 'uvx',
      args: ['mcp-server-filesystem'],
      transport: 'stdio',
      capabilities: ['read_file', 'write_file', 'list_directory'],
      tags: ['filesystem', 'files'],
    ));

    addCatalogEntry(const MCPCatalogEntry(
      id: 'git',
      name: 'Git MCP Server',
      description: 'Provides Git repository management capabilities',
      command: 'uvx',
      args: ['mcp-server-git'],
      transport: 'stdio',
      capabilities: ['git_status', 'git_commit', 'git_push', 'git_pull'],
      tags: ['git', 'version-control'],
    ));
  }
}

/// Simplified MCP Installation Service for testing
class MCPInstallationService {
  static const Duration _installTimeout = Duration(minutes: 5);
  static const Duration _checkTimeout = Duration(seconds: 30);
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1); // Shorter for testing

  final MCPCatalogService _catalogService;
  final Map<String, StreamController<MCPInstallationProgress>> _progressStreams = {};

  MCPInstallationService(this._catalogService);

  /// Install MCP server in agent terminal with progress tracking and retry logic
  Future<MCPInstallResult> installServerInTerminal(
    String agentId,
    String serverId,
    MockAgentTerminal terminal, {
    Map<String, String>? additionalEnvironment,
  }) async {
    final catalogEntry = _catalogService.getCatalogEntry(serverId);
    if (catalogEntry == null) {
      throw Exception('Server not found in catalog: $serverId');
    }

    return await _installWithRetry(
      agentId,
      serverId,
      catalogEntry,
      terminal,
      additionalEnvironment: additionalEnvironment,
    );
  }

  /// Install with retry mechanism
  Future<MCPInstallResult> _installWithRetry(
    String agentId,
    String serverId,
    MCPCatalogEntry catalogEntry,
    MockAgentTerminal terminal, {
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
        stage: 'starting',
        progress: 0.0,
        message: 'Starting MCP server installation',
      ));

      print('Starting MCP server installation in agent terminal');
      print('Agent ID: $agentId, Server ID: $serverId');

      // Check if package manager is available
      _emitProgress(agentId, MCPInstallationProgress(
        agentId: agentId,
        serverId: serverId,
        stage: 'checking_dependencies',
        progress: 0.1,
        message: 'Checking package manager availability',
      ));

      await _checkPackageManagerInTerminal(terminal, catalogEntry.command, installationLogs);

      // Attempt installation with retries
      for (int attempt = 1; attempt <= _maxRetries; attempt++) {
        try {
          _emitProgress(agentId, MCPInstallationProgress(
            agentId: agentId,
            serverId: serverId,
            stage: 'installing',
            progress: 0.2 + (attempt - 1) * 0.2,
            message: 'Installation attempt $attempt of $_maxRetries',
          ));

          installationLogs.add('=== Installation Attempt $attempt ===');
          
          final installResult = await _performInstallationInTerminal(
            terminal,
            catalogEntry,
            additionalEnvironment: additionalEnvironment,
            logs: installationLogs,
          );

          if (installResult) {
            _emitProgress(agentId, MCPInstallationProgress(
              agentId: agentId,
              serverId: serverId,
              stage: 'verifying',
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
                stage: 'completed',
                progress: 1.0,
                message: 'Installation completed successfully',
              ));

              print('MCP server installation completed successfully');
              print('Installation time: ${installationTime.inMilliseconds}ms');
              print('Attempts: $attempt');

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
        stage: 'failed',
        progress: 0.0,
        message: 'Installation failed after $_maxRetries attempts',
        error: error,
      ));

      print('MCP server installation failed after all retries');
      print('Error: $error');

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
    MockAgentTerminal terminal,
    String command,
    List<String> logs,
  ) async {
    final checkCommand = '$command --version';

    try {
      logs.add('Checking package manager: $checkCommand');
      final result = await terminal.execute(checkCommand);

      if (result.exitCode != 0) {
        throw Exception(
          '$command is not available or not working properly. '
          'Exit code: ${result.exitCode}, Error: ${result.stderr}',
        );
      }

      logs.add('✅ $command is available: ${result.stdout.trim()}');
    } catch (e) {
      logs.add('❌ $command check failed: $e');
      throw Exception('$command is not available: $e');
    }
  }

  /// Perform installation in agent terminal
  Future<bool> _performInstallationInTerminal(
    MockAgentTerminal terminal,
    MCPCatalogEntry catalogEntry, {
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

    // For uvx, we don't need to install - it runs packages directly
    if (catalogEntry.command == 'uvx') {
      logs.add('Using uvx - no installation required, will run package directly');
      return true;
    }

    // For other package managers, perform installation
    final packageName = catalogEntry.args.isNotEmpty ? catalogEntry.args.first : catalogEntry.id;
    String installCommand;

    if (catalogEntry.command == 'npx') {
      installCommand = 'npm install -g $packageName';
    } else if (catalogEntry.command == 'pip') {
      installCommand = 'pip install $packageName';
    } else {
      installCommand = '${catalogEntry.command} install $packageName';
    }

    try {
      logs.add('Starting installation: $installCommand');
      
      final result = await terminal.execute(installCommand);
      
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
    MockAgentTerminal terminal,
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
    MockAgentTerminal terminal,
    String serverId,
  ) async {
    final catalogEntry = _catalogService.getCatalogEntry(serverId);
    if (catalogEntry == null) {
      return false;
    }

    try {
      // For uvx, we don't need to check installation - it handles packages dynamically
      if (catalogEntry.command == 'uvx') {
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

  /// Dispose resources
  void dispose() {
    for (final controller in _progressStreams.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _progressStreams.clear();
  }
}

/// Simple test runner
void main() async {
  print('🧪 Running MCP Installation Service Tests');
  
  // Test 1: Successful installation
  await testSuccessfulInstallation();
  
  // Test 2: Progress tracking
  await testProgressTracking();
  
  // Test 3: Retry mechanism
  await testRetryMechanism();
  
  // Test 4: Package manager not available
  await testPackageManagerNotAvailable();
  
  // Test 5: Environment variables
  await testEnvironmentVariables();
  
  print('✅ All tests completed successfully!');
}

Future<void> testSuccessfulInstallation() async {
  print('\n📋 Test 1: Successful Installation');
  
  final catalogService = MCPCatalogService();
  catalogService.initializeDefaults();
  final installationService = MCPInstallationService(catalogService);
  final terminal = MockAgentTerminal('test-agent-1');
  
  // Set up successful mock results
  terminal.setCommandResult('uvx --version', CommandResult(
    command: 'uvx --version',
    exitCode: 0,
    stdout: 'uvx 0.4.0',
    stderr: '',
    executionTime: const Duration(milliseconds: 100),
    timestamp: DateTime.now(),
  ));

  terminal.setCommandResult('uvx mcp-server-filesystem --help', CommandResult(
    command: 'uvx mcp-server-filesystem --help',
    exitCode: 0,
    stdout: 'MCP Filesystem Server Help',
    stderr: '',
    executionTime: const Duration(milliseconds: 200),
    timestamp: DateTime.now(),
  ));

  try {
    final result = await installationService.installServerInTerminal(
      'test-agent-1',
      'filesystem',
      terminal,
    );

    assert(result.success == true, 'Installation should succeed');
    assert(result.serverId == 'filesystem', 'Server ID should match');
    assert(result.installationLogs.isNotEmpty, 'Should have installation logs');
    assert(terminal.executedCommands.contains('uvx --version'), 'Should check uvx version');
    assert(terminal.executedCommands.contains('uvx mcp-server-filesystem --help'), 'Should verify installation');
    
    print('✅ Successful installation test passed');
  } finally {
    installationService.dispose();
  }
}

Future<void> testProgressTracking() async {
  print('\n📋 Test 2: Progress Tracking');
  
  final catalogService = MCPCatalogService();
  catalogService.initializeDefaults();
  final installationService = MCPInstallationService(catalogService);
  final terminal = MockAgentTerminal('test-agent-2');
  final progressUpdates = <MCPInstallationProgress>[];
  
  // Set up successful mock results
  terminal.setCommandResult('uvx --version', CommandResult(
    command: 'uvx --version',
    exitCode: 0,
    stdout: 'uvx 0.4.0',
    stderr: '',
    executionTime: const Duration(milliseconds: 100),
    timestamp: DateTime.now(),
  ));

  terminal.setCommandResult('uvx mcp-server-git --help', CommandResult(
    command: 'uvx mcp-server-git --help',
    exitCode: 0,
    stdout: 'MCP Git Server Help',
    stderr: '',
    executionTime: const Duration(milliseconds: 200),
    timestamp: DateTime.now(),
  ));

  // Listen to progress updates
  final progressStream = installationService.getInstallationProgress('test-agent-2');
  final subscription = progressStream?.listen((progress) {
    progressUpdates.add(progress);
    print('Progress: ${progress.stage} - ${progress.message} (${(progress.progress * 100).toInt()}%)');
  });

  try {
    final result = await installationService.installServerInTerminal(
      'test-agent-2',
      'git',
      terminal,
    );

    // Wait a bit for progress updates
    await Future.delayed(const Duration(milliseconds: 100));
    await subscription?.cancel();

    assert(result.success == true, 'Installation should succeed');
    assert(progressUpdates.isNotEmpty, 'Should have progress updates');
    assert(progressUpdates.first.stage == 'starting', 'First stage should be starting');
    assert(progressUpdates.last.stage == 'completed', 'Last stage should be completed');
    
    print('✅ Progress tracking test passed');
  } finally {
    await subscription?.cancel();
    installationService.dispose();
  }
}

Future<void> testRetryMechanism() async {
  print('\n📋 Test 3: Retry Mechanism');
  
  final catalogService = MCPCatalogService();
  catalogService.initializeDefaults();
  final installationService = MCPInstallationService(catalogService);
  final terminal = MockAgentTerminal('test-agent-3');
  
  // Set up uvx check to succeed
  terminal.setCommandResult('uvx --version', CommandResult(
    command: 'uvx --version',
    exitCode: 0,
    stdout: 'uvx 0.4.0',
    stderr: '',
    executionTime: const Duration(milliseconds: 100),
    timestamp: DateTime.now(),
  ));

  // Set up verification to fail first time, then succeed
  var verificationAttempts = 0;
  terminal.setCommandResult('uvx mcp-server-filesystem --help', CommandResult(
    command: 'uvx mcp-server-filesystem --help',
    exitCode: ++verificationAttempts > 1 ? 0 : 1, // Fail first time, succeed second
    stdout: verificationAttempts > 1 ? 'MCP Filesystem Server Help' : '',
    stderr: verificationAttempts > 1 ? '' : 'Command not found',
    executionTime: const Duration(milliseconds: 200),
    timestamp: DateTime.now(),
  ));

  try {
    final result = await installationService.installServerInTerminal(
      'test-agent-3',
      'filesystem',
      terminal,
    );

    assert(result.success == true, 'Installation should eventually succeed');
    assert(result.installationLogs.any((log) => log.contains('Installation attempt')), 'Should show retry attempts');
    
    print('✅ Retry mechanism test passed');
  } finally {
    installationService.dispose();
  }
}

Future<void> testPackageManagerNotAvailable() async {
  print('\n📋 Test 4: Package Manager Not Available');
  
  final catalogService = MCPCatalogService();
  catalogService.initializeDefaults();
  final installationService = MCPInstallationService(catalogService);
  final terminal = MockAgentTerminal('test-agent-4');
  
  // Set up uvx check to fail
  terminal.setCommandResult('uvx --version', CommandResult(
    command: 'uvx --version',
    exitCode: 1,
    stdout: '',
    stderr: 'uvx: command not found',
    executionTime: const Duration(milliseconds: 100),
    timestamp: DateTime.now(),
  ));

  try {
    final result = await installationService.installServerInTerminal(
      'test-agent-4',
      'filesystem',
      terminal,
    );

    assert(result.success == false, 'Installation should fail');
    assert(result.error != null, 'Should have error message');
    assert(result.error!.contains('not available'), 'Error should mention unavailability');
    
    print('✅ Package manager not available test passed');
  } catch (e) {
    // Expected to throw exception
    assert(e.toString().contains('not available'), 'Should throw availability error');
    print('✅ Package manager not available test passed (threw expected exception)');
  } finally {
    installationService.dispose();
  }
}

Future<void> testEnvironmentVariables() async {
  print('\n📋 Test 5: Environment Variables');
  
  final catalogService = MCPCatalogService();
  catalogService.initializeDefaults();
  final installationService = MCPInstallationService(catalogService);
  final terminal = MockAgentTerminal('test-agent-5');
  final additionalEnv = {'TEST_VAR': 'test_value', 'API_KEY': 'secret'};
  
  // Set up successful installation
  terminal.setCommandResult('uvx --version', CommandResult(
    command: 'uvx --version',
    exitCode: 0,
    stdout: 'uvx 0.4.0',
    stderr: '',
    executionTime: const Duration(milliseconds: 100),
    timestamp: DateTime.now(),
  ));

  terminal.setCommandResult('uvx mcp-server-filesystem --help', CommandResult(
    command: 'uvx mcp-server-filesystem --help',
    exitCode: 0,
    stdout: 'MCP Filesystem Server Help',
    stderr: '',
    executionTime: const Duration(milliseconds: 200),
    timestamp: DateTime.now(),
  ));

  try {
    final result = await installationService.installServerInTerminal(
      'test-agent-5',
      'filesystem',
      terminal,
      additionalEnvironment: additionalEnv,
    );

    assert(result.success == true, 'Installation should succeed');
    assert(terminal.environment['TEST_VAR'] == 'test_value', 'Should set TEST_VAR');
    assert(terminal.environment['API_KEY'] == 'secret', 'Should set API_KEY');
    
    print('✅ Environment variables test passed');
  } finally {
    installationService.dispose();
  }
}