import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agent_terminal.dart';
import '../models/mcp_server_process.dart';
import '../interfaces/agent_terminal_manager_interface.dart';
import 'production_logger.dart';
import 'mcp_installation_service.dart';
import 'mcp_process_manager.dart';
import 'terminal_output_service.dart';
import 'terminal_session_service.dart';
import 'resource_monitor.dart';
import 'process_cleanup_service.dart';
import 'graceful_shutdown_service.dart';

/// Manages agent terminal instances and their lifecycle
class AgentTerminalManager implements AgentTerminalManagerInterface {
  final MCPInstallationService _installationService;
  final MCPProcessManager _processManager;
  final TerminalOutputService _outputService;
  final ResourceMonitor _resourceMonitor;
  final ProcessCleanupService _cleanupService;
  final GracefulShutdownService _shutdownService;
  final Map<String, AgentTerminalImpl> _terminals = {};

  AgentTerminalManager(
    this._installationService, 
    this._processManager,
    this._outputService,
    this._resourceMonitor,
    this._cleanupService,
    this._shutdownService,
  );

  /// Create a new terminal instance for an agent
  @override
  Future<AgentTerminal> createTerminal(String agentId, AgentTerminalConfig config) async {
    if (_terminals.containsKey(agentId)) {
      throw TerminalException('Terminal already exists for agent $agentId');
    }

    try {
      ProductionLogger.instance.info(
        'Creating terminal for agent',
        data: {'agent_id': agentId, 'working_directory': config.workingDirectory},
        category: 'agent_terminal',
      );

      // Create output stream
      _outputService.createOutputStream(agentId);

      // Create terminal implementation
      final terminal = AgentTerminalImpl(
        agentId: agentId,
        config: config,
        outputService: _outputService,
        cleanupService: _cleanupService,
      );

      await terminal.initialize();
      _terminals[agentId] = terminal;

      // Start resource monitoring
      await _resourceMonitor.startMonitoring(agentId, config.resourceLimits);

      ProductionLogger.instance.info(
        'Terminal created successfully',
        data: {'agent_id': agentId},
        category: 'agent_terminal',
      );

      return terminal;
    } catch (e) {
      ProductionLogger.instance.error(
        'Failed to create terminal',
        error: e,
        data: {'agent_id': agentId},
        category: 'agent_terminal',
      );
      rethrow;
    }
  }

  /// Get existing terminal for an agent
  @override
  AgentTerminal? getTerminal(String agentId) {
    return _terminals[agentId];
  }

  /// Execute command in agent's terminal with security validation
  @override
  Future<CommandResult> executeCommand(
    String agentId,
    String command, {
    bool requiresApproval = false,
  }) async {
    final terminal = _terminals[agentId];
    if (terminal == null) {
      throw TerminalException('No terminal found for agent $agentId');
    }

    // Validate command against security policies
    final validationResult = await validateCommand(agentId, command);
    if (!validationResult.isAllowed) {
      throw SecurityException('Command not allowed: ${validationResult.reason}');
    }

    if (requiresApproval || validationResult.recommendedAction == SecurityAction.requireApproval) {
      // In a real implementation, this would show a UI prompt
      ProductionLogger.instance.info(
        'Command requires approval',
        data: {'agent_id': agentId, 'command': command},
        category: 'security',
      );
    }

    return await terminal.execute(command);
  }

  /// Execute API call through agent's secure context
  @override
  Future<APICallResult> executeAPICall(
    String agentId,
    String provider,
    String model,
    Map<String, dynamic> request,
  ) async {
    final terminal = _terminals[agentId];
    if (terminal == null) {
      throw TerminalException('No terminal found for agent $agentId');
    }

    final startTime = DateTime.now();

    try {
      // Validate API permissions
      final apiPermission = terminal.config.securityContext.apiPermissions[provider];
      if (apiPermission == null) {
        throw SecurityException('No API permission for provider $provider');
      }

      if (!apiPermission.allowedModels.contains(model)) {
        throw SecurityException('Model $model not allowed for provider $provider');
      }

      // TODO: Implement actual API call logic
      // This would integrate with the existing LLM services
      
      final executionTime = DateTime.now().difference(startTime);
      
      return APICallResult(
        provider: provider,
        model: model,
        success: true,
        response: const {'message': 'API call executed successfully'},
        executionTime: executionTime,
        timestamp: DateTime.now(),
        tokensUsed: 100, // Mock value
      );
    } catch (e) {
      final executionTime = DateTime.now().difference(startTime);
      
      return APICallResult(
        provider: provider,
        model: model,
        success: false,
        error: e.toString(),
        executionTime: executionTime,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Stream terminal output
  @override
  Stream<TerminalOutput> streamOutput(String agentId) {
    final stream = _outputService.getOutputStream(agentId);
    if (stream == null) {
      throw TerminalException('No output stream for agent $agentId');
    }
    return stream;
  }

  /// Validate command against security policies
  @override
  Future<SecurityValidationResult> validateCommand(String agentId, String command) async {
    final terminal = _terminals[agentId];
    if (terminal == null) {
      return const SecurityValidationResult(
        isAllowed: false,
        reason: 'Terminal not found',
        recommendedAction: SecurityAction.deny,
      );
    }

    final securityContext = terminal.config.securityContext;
    final terminalPermissions = securityContext.terminalPermissions;

    // Check if shell commands are allowed
    if (!terminalPermissions.canExecuteShellCommands) {
      return const SecurityValidationResult(
        isAllowed: false,
        reason: 'Shell command execution not permitted',
        recommendedAction: SecurityAction.deny,
      );
    }

    // Check command blacklist
    for (final blockedCommand in terminalPermissions.commandBlacklist) {
      if (command.toLowerCase().contains(blockedCommand.toLowerCase())) {
        return SecurityValidationResult(
          isAllowed: false,
          reason: 'Command contains blocked term: $blockedCommand',
          violations: [blockedCommand],
          recommendedAction: SecurityAction.deny,
        );
      }
    }

    // Check command whitelist (if defined)
    if (terminalPermissions.commandWhitelist.isNotEmpty) {
      bool isWhitelisted = false;
      for (final allowedCommand in terminalPermissions.commandWhitelist) {
        if (command.toLowerCase().startsWith(allowedCommand.toLowerCase())) {
          isWhitelisted = true;
          break;
        }
      }
      
      if (!isWhitelisted) {
        return const SecurityValidationResult(
          isAllowed: false,
          reason: 'Command not in whitelist',
          recommendedAction: SecurityAction.deny,
        );
      }
    }

    // Check for dangerous commands
    final dangerousCommands = ['rm -rf', 'del /f', 'format', 'fdisk', 'mkfs'];
    for (final dangerous in dangerousCommands) {
      if (command.toLowerCase().contains(dangerous.toLowerCase())) {
        return SecurityValidationResult(
          isAllowed: false,
          reason: 'Dangerous command detected: $dangerous',
          violations: [dangerous],
          recommendedAction: SecurityAction.requireApproval,
        );
      }
    }

    // Check for package installation commands
    final installCommands = ['npm install', 'pip install', 'apt install', 'yum install'];
    if (!terminalPermissions.canInstallPackages) {
      for (final installCmd in installCommands) {
        if (command.toLowerCase().contains(installCmd.toLowerCase())) {
          return SecurityValidationResult(
            isAllowed: false,
            reason: 'Package installation not permitted',
            violations: [installCmd],
            recommendedAction: SecurityAction.deny,
          );
        }
      }
    }

    return const SecurityValidationResult(
      isAllowed: true,
      recommendedAction: SecurityAction.allow,
    );
  }

  /// Destroy terminal and cleanup resources
  @override
  Future<void> destroyTerminal(String agentId) async {
    ProductionLogger.instance.info(
      'Starting terminal destruction',
      data: {'agent_id': agentId},
      category: 'agent_terminal',
    );

    try {
      // Perform graceful shutdown
      final shutdownResult = await _shutdownService.shutdownAgent(agentId);
      
      if (!shutdownResult.success) {
        ProductionLogger.instance.warning(
          'Graceful shutdown failed, performing emergency cleanup',
          data: {
            'agent_id': agentId,
            'shutdown_error': shutdownResult.error,
            'warnings': shutdownResult.warnings,
          },
          category: 'agent_terminal',
        );
        
        // Fallback to emergency shutdown
        await _shutdownService.emergencyShutdown(agentId);
      }

      // Remove terminal from tracking
      final terminal = _terminals.remove(agentId);
      if (terminal != null) {
        await terminal.terminate();
      }

      // Close output stream
      await _outputService.closeOutputStream(agentId);

      ProductionLogger.instance.info(
        'Terminal destroyed successfully',
        data: {
          'agent_id': agentId,
          'shutdown_duration_ms': shutdownResult.duration.inMilliseconds,
          'graceful': shutdownResult.success,
        },
        category: 'agent_terminal',
      );

    } catch (e) {
      ProductionLogger.instance.error(
        'Failed to destroy terminal cleanly',
        error: e,
        data: {'agent_id': agentId},
        category: 'agent_terminal',
      );
      
      // Force cleanup as last resort
      final terminal = _terminals.remove(agentId);
      if (terminal != null) {
        await terminal.terminate();
      }
      await _outputService.closeOutputStream(agentId);
      rethrow;
    }
  }

  /// Get all active terminals
  @override
  List<AgentTerminal> getActiveTerminals() {
    return _terminals.values.cast<AgentTerminal>().toList();
  }

  /// Install MCP server for agent
  @override
  Future<MCPInstallResult> installMCPServer(String agentId, String serverId) async {
    final terminal = _terminals[agentId];
    if (terminal == null) {
      throw TerminalException('No terminal found for agent $agentId');
    }

    ProductionLogger.instance.info(
      'Installing MCP server for agent',
      data: {'agent_id': agentId, 'server_id': serverId},
      category: 'mcp_installation',
    );

    try {
      // Use the enhanced installation service with agent terminal integration
      return await _installationService.installServerInTerminal(
        agentId,
        serverId,
        terminal,
      );
    } catch (e) {
      ProductionLogger.instance.error(
        'Failed to install MCP server',
        error: e,
        data: {'agent_id': agentId, 'server_id': serverId},
        category: 'mcp_installation',
      );
      rethrow;
    }
  }

  /// Get installation progress for an agent
  Stream<MCPInstallationProgress>? getInstallationProgress(String agentId) {
    return _installationService.getInstallationProgress(agentId);
  }

  /// Check if MCP server is installed for agent
  Future<bool> isMCPServerInstalled(String agentId, String serverId) async {
    final terminal = _terminals[agentId];
    if (terminal == null) {
      return false;
    }

    return await _installationService.isServerInstalledInTerminal(terminal, serverId);
  }

  /// Uninstall MCP server from agent
  Future<bool> uninstallMCPServer(String agentId, String serverId) async {
    final terminal = _terminals[agentId];
    if (terminal == null) {
      return false;
    }

    try {
      return await _installationService.uninstallServerFromTerminal(terminal, serverId);
    } catch (e) {
      ProductionLogger.instance.error(
        'Failed to uninstall MCP server',
        error: e,
        data: {'agent_id': agentId, 'server_id': serverId},
        category: 'mcp_installation',
      );
      return false;
    }
  }

  /// Get terminal session state for persistence
  @override
  Map<String, dynamic> getTerminalState(String agentId) {
    final terminal = _terminals[agentId];
    if (terminal == null) {
      throw TerminalException('No terminal found for agent $agentId');
    }

    return {
      'agentId': terminal.agentId,
      'workingDirectory': terminal.workingDirectory,
      'environment': terminal.environment,
      'status': terminal.status.name,
      'createdAt': terminal.createdAt.toIso8601String(),
      'lastActivity': terminal.lastActivity.toIso8601String(),
      'commandHistory': terminal.getHistory().map((h) => {
        'command': h.command,
        'timestamp': h.timestamp.toIso8601String(),
        'wasSuccessful': h.wasSuccessful,
        'result': h.result != null ? {
          'exitCode': h.result!.exitCode,
          'stdout': h.result!.stdout,
          'stderr': h.result!.stderr,
          'executionTime': h.result!.executionTime.inMilliseconds,
        } : null,
      }).toList(),
      'mcpServers': terminal.mcpServers.map((s) => {
        'serverId': s.serverId,
        'status': s.status.name,
        'startedAt': s.startTime.toIso8601String(),
      }).toList(),
    };
  }

  /// Restore terminal session from saved state
  @override
  Future<AgentTerminal> restoreTerminalState(String agentId, Map<String, dynamic> state) async {
    if (_terminals.containsKey(agentId)) {
      throw TerminalException('Terminal already exists for agent $agentId');
    }

    try {
      ProductionLogger.instance.info(
        'Restoring terminal state for agent',
        data: {'agent_id': agentId},
        category: 'agent_terminal',
      );

      // Create basic config from state
      final config = AgentTerminalConfig(
        agentId: agentId,
        workingDirectory: state['workingDirectory'] as String,
        environment: Map<String, String>.from(state['environment'] as Map),
        securityContext: _createDefaultSecurityContext(agentId),
        resourceLimits: const ResourceLimits(),
      );

      // Create terminal
      final terminal = await createTerminal(agentId, config);

      // Restore command history if available
      if (state['commandHistory'] != null) {
        final historyData = state['commandHistory'] as List;
        for (final historyItem in historyData) {
          final history = CommandHistory(
            command: historyItem['command'] as String,
            timestamp: DateTime.parse(historyItem['timestamp'] as String),
            wasSuccessful: historyItem['wasSuccessful'] as bool,
            result: historyItem['result'] != null ? CommandResult(
              command: historyItem['command'] as String,
              exitCode: historyItem['result']['exitCode'] as int,
              stdout: historyItem['result']['stdout'] as String,
              stderr: historyItem['result']['stderr'] as String,
              executionTime: Duration(milliseconds: historyItem['result']['executionTime'] as int),
              timestamp: DateTime.parse(historyItem['timestamp'] as String),
            ) : null,
          );
          
          // Add to terminal's history
          terminal.history.add(history);
        }
      }

      ProductionLogger.instance.info(
        'Terminal state restored successfully',
        data: {'agent_id': agentId, 'history_count': state['commandHistory']?.length ?? 0},
        category: 'agent_terminal',
      );

      return terminal;
    } catch (e) {
      ProductionLogger.instance.error(
        'Failed to restore terminal state',
        error: e,
        data: {'agent_id': agentId},
        category: 'agent_terminal',
      );
      rethrow;
    }
  }

  /// Get command history for an agent with filtering options
  @override
  List<CommandHistory> getCommandHistory(
    String agentId, {
    int? limit,
    DateTime? since,
    bool? successfulOnly,
  }) {
    final terminal = _terminals[agentId];
    if (terminal == null) {
      throw TerminalException('No terminal found for agent $agentId');
    }

    var history = terminal.getHistory();

    // Apply filters
    if (since != null) {
      history = history.where((h) => h.timestamp.isAfter(since)).toList();
    }

    if (successfulOnly != null) {
      history = history.where((h) => h.wasSuccessful == successfulOnly).toList();
    }

    // Sort by timestamp (most recent first)
    history.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Apply limit
    if (limit != null && limit > 0) {
      history = history.take(limit).toList();
    }

    return history;
  }

  /// Clear command history for an agent
  @override
  Future<void> clearCommandHistory(String agentId) async {
    final terminal = _terminals[agentId];
    if (terminal == null) {
      throw TerminalException('No terminal found for agent $agentId');
    }

    terminal.history.clear();
    ProductionLogger.instance.info(
      'Command history cleared',
      data: {'agent_id': agentId},
      category: 'agent_terminal',
    );
  }

  /// Get real-time terminal metrics
  @override
  Map<String, dynamic> getTerminalMetrics(String agentId) {
    final terminal = _terminals[agentId];
    if (terminal == null) {
      throw TerminalException('No terminal found for agent $agentId');
    }

    final history = terminal.getHistory();
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));

    final recentCommands = history.where((h) => h.timestamp.isAfter(last24Hours)).toList();
    final successfulCommands = recentCommands.where((h) => h.wasSuccessful).length;
    final failedCommands = recentCommands.length - successfulCommands;

    return {
      'agentId': agentId,
      'status': terminal.status.name,
      'uptime': now.difference(terminal.createdAt).inMinutes,
      'lastActivity': terminal.lastActivity.toIso8601String(),
      'totalCommands': history.length,
      'recentCommands24h': recentCommands.length,
      'successfulCommands24h': successfulCommands,
      'failedCommands24h': failedCommands,
      'successRate': recentCommands.isNotEmpty ? (successfulCommands / recentCommands.length * 100).round() : 100,
      'mcpServerCount': terminal.mcpServers.length,
      'workingDirectory': terminal.workingDirectory,
      'environmentVariables': terminal.environment.length,
    };
  }

  /// Get resource usage for an agent
  @override
  Future<ResourceUsage> getResourceUsage(String agentId) async {
    return await _resourceMonitor.getResourceUsage(agentId);
  }

  /// Get cleanup status for an agent
  @override
  CleanupStatus getCleanupStatus(String agentId) {
    return _cleanupService.getCleanupStatus(agentId);
  }

  /// Get shutdown status for an agent
  @override
  ShutdownStatus? getShutdownStatus(String agentId) {
    return _shutdownService.getShutdownStatus(agentId);
  }

  /// Dispose all resources
  @override
  Future<void> dispose() async {
    ProductionLogger.instance.info(
      'Disposing agent terminal manager',
      data: {'active_terminals': _terminals.length},
      category: 'agent_terminal',
    );

    // Gracefully shutdown all terminals
    final futures = _terminals.keys.map((agentId) => destroyTerminal(agentId));
    await Future.wait(futures, eagerError: false);

    // Dispose services
    await _resourceMonitor.dispose();
    await _cleanupService.dispose();
    await _shutdownService.dispose();
    _installationService.dispose();

    ProductionLogger.instance.info(
      'Agent terminal manager disposed',
      category: 'agent_terminal',
    );
  }

  /// Create default security context for terminal restoration
  SecurityContext _createDefaultSecurityContext(String agentId) {
    return SecurityContext(
      agentId: agentId,
      resourceLimits: const ResourceLimits(),
      terminalPermissions: const TerminalPermissions(
        canExecuteShellCommands: true,
        canInstallPackages: false,
        canModifyEnvironment: true,
        canAccessNetwork: true,
        commandBlacklist: ['rm -rf', 'del /f', 'format', 'fdisk'],
      ),
    );
  }
}

/// Implementation of AgentTerminal
class AgentTerminalImpl implements AgentTerminal {
  @override
  final String agentId;
  
  final AgentTerminalConfig config;
  final TerminalOutputService outputService;
  final ProcessCleanupService cleanupService;
  
  @override
  String workingDirectory;
  
  @override
  Map<String, String> environment;
  
  @override
  TerminalStatus status = TerminalStatus.creating;
  
  @override
  final DateTime createdAt = DateTime.now();
  
  @override
  DateTime lastActivity = DateTime.now();
  
  @override
  final List<MCPServerProcess> mcpServers = [];
  
  final List<CommandHistory> _history = [];
  final Set<int> _runningProcesses = {};

  // Expose history for state management
  @override
  List<CommandHistory> get history => _history;

  AgentTerminalImpl({
    required this.agentId,
    required this.config,
    required this.outputService,
    required this.cleanupService,
  }) : workingDirectory = config.workingDirectory,
       environment = Map.from(config.environment);

  Future<void> initialize() async {
    try {
      // Add timeout to prevent hanging on macOS directory operations
      await _initializeWithDirectoryCreation().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TerminalException(
            'Terminal initialization timed out for agent $agentId. '
            'This may be due to file system permission issues or slow disk I/O.'
          );
        },
      );

      status = TerminalStatus.ready;
      _addOutput('Terminal initialized for agent $agentId', TerminalOutputType.system);
    } catch (e) {
      status = TerminalStatus.error;
      _addOutput('Failed to initialize terminal: $e', TerminalOutputType.error);
      rethrow;
    }
  }

  /// Initialize directory creation with proper error handling and permission checks
  Future<void> _initializeWithDirectoryCreation() async {
    final workingDir = Directory(workingDirectory);

    // Check if directory already exists
    if (await workingDir.exists()) {
      // Verify we have write permissions
      await _verifyDirectoryPermissions(workingDir);
    } else {
      // Create directory with proper error handling
      await _createWorkingDirectorySafely(workingDir);
    }

    // Set up secure environment variables
    environment.addAll(config.securityContext.terminalPermissions.secureEnvironmentVars);
  }

  /// Verify that we have proper permissions for the working directory
  Future<void> _verifyDirectoryPermissions(Directory directory) async {
    try {
      // Try to create a temporary file to verify write permissions
      final testFile = File('${directory.path}/.asmbli_permission_test');
      await testFile.writeAsString('test');
      await testFile.delete();
    } catch (e) {
      throw TerminalException(
        'Insufficient permissions for working directory ${directory.path}: $e'
      );
    }
  }

  /// Create working directory with proper parent directory handling
  Future<void> _createWorkingDirectorySafely(Directory workingDir) async {
    try {
      // Check parent directory permissions first
      final parentDir = workingDir.parent;
      if (!await parentDir.exists()) {
        // Create parent directories if they don't exist
        await parentDir.create(recursive: true);
      }

      // Verify parent directory is writable
      await _verifyDirectoryPermissions(parentDir);

      // Create the working directory
      await workingDir.create(recursive: true);

      ProductionLogger.instance.info(
        'Created agent working directory',
        data: {'agent_id': agentId, 'directory': workingDir.path},
        category: 'agent_terminal',
      );
    } catch (e) {
      throw TerminalException(
        'Failed to create working directory ${workingDir.path}: $e. '
        'Check file system permissions and available disk space.'
      );
    }
  }

  @override
  Future<CommandResult> execute(String command) async {
    if (status != TerminalStatus.ready) {
      throw TerminalException('Terminal not ready for agent $agentId');
    }

    status = TerminalStatus.busy;
    lastActivity = DateTime.now();
    
    _addOutput('> $command', TerminalOutputType.command);

    final startTime = DateTime.now();
    Process? process;
    
    try {
      // Add timeout to process start to prevent hanging
      process = await Process.start(
        Platform.isWindows ? 'cmd' : 'bash',
        Platform.isWindows ? ['/c', command] : ['-c', command],
        workingDirectory: workingDirectory,
        environment: environment,
        runInShell: true,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TerminalException(
            'Command execution timed out: $command. '
            'Process failed to start within 30 seconds.'
          );
        },
      );

      // Track the process for cleanup
      _runningProcesses.add(process.pid);
      cleanupService.trackProcess(agentId, process.pid);

      // Collect output
      final stdoutBuffer = StringBuffer();
      final stderrBuffer = StringBuffer();

      final stdoutFuture = process.stdout
          .transform(utf8.decoder)
          .forEach((data) => stdoutBuffer.write(data));

      final stderrFuture = process.stderr
          .transform(utf8.decoder)
          .forEach((data) => stderrBuffer.write(data));

      // Wait for process completion with timeout
      final exitCode = await process.exitCode.timeout(config.commandTimeout);
      
      // Wait for output streams to complete
      await Future.wait([stdoutFuture, stderrFuture]);

      // Untrack the process
      _runningProcesses.remove(process.pid);
      cleanupService.untrackProcess(agentId, process.pid);

      final executionTime = DateTime.now().difference(startTime);
      
      final commandResult = CommandResult(
        command: command,
        exitCode: exitCode,
        stdout: stdoutBuffer.toString(),
        stderr: stderrBuffer.toString(),
        executionTime: executionTime,
        timestamp: DateTime.now(),
      );

      // Add to history
      _history.add(CommandHistory(
        command: command,
        timestamp: DateTime.now(),
        result: commandResult,
        wasSuccessful: commandResult.isSuccess,
      ));

      // Stream output
      if (commandResult.stdout.isNotEmpty) {
        _addOutput(commandResult.stdout, TerminalOutputType.stdout);
      }
      if (commandResult.stderr.isNotEmpty) {
        _addOutput(commandResult.stderr, TerminalOutputType.stderr);
      }

      status = TerminalStatus.ready;
      return commandResult;
    } catch (e) {
      // Clean up process if it's still running
      if (process != null) {
        _runningProcesses.remove(process.pid);
        cleanupService.untrackProcess(agentId, process.pid);
        
        try {
          process.kill();
        } catch (_) {
          // Process might already be dead
        }
      }

      status = TerminalStatus.error;
      _addOutput('Command execution failed: $e', TerminalOutputType.error);
      
      // Add failed command to history
      _history.add(CommandHistory(
        command: command,
        timestamp: DateTime.now(),
        wasSuccessful: false,
      ));
      
      rethrow;
    } finally {
      status = TerminalStatus.ready;
    }
  }

  @override
  Stream<String> executeStream(String command) async* {
    if (status != TerminalStatus.ready) {
      throw TerminalException('Terminal not ready for agent $agentId');
    }

    status = TerminalStatus.busy;
    lastActivity = DateTime.now();
    
    _addOutput('> $command', TerminalOutputType.command);

    final startTime = DateTime.now();
    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();

    try {
      final process = await Process.start(
        Platform.isWindows ? 'cmd' : 'bash',
        Platform.isWindows ? ['/c', command] : ['-c', command],
        workingDirectory: workingDirectory,
        environment: environment,
        runInShell: true,
      );

      // Create stream controllers for real-time output
      final stdoutController = StreamController<String>();
      final stderrController = StreamController<String>();
      final combinedController = StreamController<String>();

      // Handle stdout with real-time streaming
      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          stdoutBuffer.writeln(line);
          _addOutput(line, TerminalOutputType.stdout);
          stdoutController.add(line);
          combinedController.add('[STDOUT] $line');
        },
        onDone: () => stdoutController.close(),
        onError: (error) {
          stdoutController.addError(error);
          combinedController.addError(error);
        },
      );

      // Handle stderr with real-time streaming
      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          stderrBuffer.writeln(line);
          _addOutput(line, TerminalOutputType.stderr);
          stderrController.add(line);
          combinedController.add('[STDERR] $line');
        },
        onDone: () => stderrController.close(),
        onError: (error) {
          stderrController.addError(error);
          combinedController.addError(error);
        },
      );

      // Yield real-time output as it comes
      await for (final line in combinedController.stream) {
        yield line;
      }

      // Wait for process completion
      final exitCode = await process.exitCode;
      final executionTime = DateTime.now().difference(startTime);
      
      // Create complete command result
      final commandResult = CommandResult(
        command: command,
        exitCode: exitCode,
        stdout: stdoutBuffer.toString(),
        stderr: stderrBuffer.toString(),
        executionTime: executionTime,
        timestamp: DateTime.now(),
      );

      // Add to history with complete result
      _history.add(CommandHistory(
        command: command,
        timestamp: DateTime.now(),
        result: commandResult,
        wasSuccessful: exitCode == 0,
      ));

      // Emit completion status
      final completionMessage = exitCode == 0 
          ? 'Command completed successfully (exit code: $exitCode)'
          : 'Command failed with exit code: $exitCode';
      
      _addOutput(completionMessage, exitCode == 0 ? TerminalOutputType.system : TerminalOutputType.error);
      yield '[SYSTEM] $completionMessage';

    } catch (e) {
      status = TerminalStatus.error;
      final errorMessage = 'Stream execution failed: $e';
      _addOutput(errorMessage, TerminalOutputType.error);
      
      // Add failed command to history
      _history.add(CommandHistory(
        command: command,
        timestamp: DateTime.now(),
        wasSuccessful: false,
      ));
      
      yield '[ERROR] $errorMessage';
      rethrow;
    } finally {
      status = TerminalStatus.ready;
    }
  }

  @override
  Future<void> changeDirectory(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      throw TerminalException('Directory does not exist: $path');
    }

    workingDirectory = path;
    lastActivity = DateTime.now();
    
    _addOutput('Changed directory to: $path', TerminalOutputType.system);
  }

  @override
  Future<void> setEnvironment(String key, String value) async {
    environment[key] = value;
    lastActivity = DateTime.now();
    
    _addOutput('Set environment variable: $key', TerminalOutputType.system);
  }

  @override
  List<CommandHistory> getHistory() {
    return List.unmodifiable(_history);
  }

  @override
  Future<void> addMCPServer(MCPServerProcess server) async {
    mcpServers.add(server);
    
    // Track MCP server for cleanup
    cleanupService.trackMCPServer(agentId, server.serverId);
    
    _addOutput('Added MCP server: ${server.serverId}', TerminalOutputType.system);
  }

  @override
  Future<void> removeMCPServer(String serverId) async {
    mcpServers.removeWhere((server) => server.serverId == serverId);
    
    // Untrack MCP server from cleanup
    cleanupService.untrackMCPServer(agentId, serverId);
    
    _addOutput('Removed MCP server: $serverId', TerminalOutputType.system);
  }

  @override
  Future<void> terminate() async {
    if (status == TerminalStatus.terminated) {
      return; // Already terminated
    }

    ProductionLogger.instance.info(
      'Terminating terminal',
      data: {
        'agent_id': agentId,
        'running_processes': _runningProcesses.length,
        'mcp_servers': mcpServers.length,
      },
      category: 'agent_terminal',
    );

    status = TerminalStatus.terminated;
    
    try {
      // Kill any running processes
      for (final pid in _runningProcesses.toList()) {
        try {
          if (Platform.isWindows) {
            await Process.run('taskkill', ['/F', '/PID', pid.toString()]);
          } else {
            await Process.run('kill', ['-9', pid.toString()]);
          }
          cleanupService.untrackProcess(agentId, pid);
        } catch (e) {
          ProductionLogger.instance.warning(
            'Failed to kill process during termination',
            data: {'agent_id': agentId, 'pid': pid, 'error': e.toString()},
            category: 'agent_terminal',
          );
        }
      }
      _runningProcesses.clear();

      // Stop all MCP servers
      for (final server in mcpServers.toList()) {
        try {
          cleanupService.untrackMCPServer(agentId, server.serverId);
        } catch (e) {
          ProductionLogger.instance.warning(
            'Failed to untrack MCP server during termination',
            data: {'agent_id': agentId, 'server_id': server.serverId, 'error': e.toString()},
            category: 'agent_terminal',
          );
        }
      }
      mcpServers.clear();

      _addOutput('Terminal terminated', TerminalOutputType.system);
      
      ProductionLogger.instance.info(
        'Terminal terminated successfully',
        data: {'agent_id': agentId},
        category: 'agent_terminal',
      );

    } catch (e) {
      ProductionLogger.instance.error(
        'Error during terminal termination',
        error: e,
        data: {'agent_id': agentId},
        category: 'agent_terminal',
      );
      rethrow;
    }
  }

  /// Check if terminal has active operations
  bool hasActiveOperations() {
    return _runningProcesses.isNotEmpty || status == TerminalStatus.busy;
  }

  void _addOutput(String content, TerminalOutputType type) {
    final output = TerminalOutput(
      agentId: agentId,
      content: content,
      type: type,
      timestamp: DateTime.now(),
    );
    
    outputService.addOutput(agentId, output);
  }
}

/// Terminal-related exceptions
class TerminalException implements Exception {
  final String message;
  TerminalException(this.message);

  @override
  String toString() => 'TerminalException: $message';
}

/// Security-related exceptions
class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}

// ==================== Riverpod Providers ====================

final terminalOutputServiceProvider = Provider<TerminalOutputService>((ref) {
  return TerminalOutputService();
});

final resourceMonitorProvider = Provider<ResourceMonitor>((ref) {
  return ResourceMonitor();
});

final processCleanupServiceProvider = Provider<ProcessCleanupService>((ref) {
  return ProcessCleanupService();
});

final gracefulShutdownServiceProvider = Provider<GracefulShutdownService>((ref) {
  final cleanupService = ref.read(processCleanupServiceProvider);
  final resourceMonitor = ref.read(resourceMonitorProvider);
  return GracefulShutdownService(cleanupService, resourceMonitor);
});

final agentTerminalManagerProvider = Provider<AgentTerminalManager>((ref) {
  final installationService = ref.read(mcpInstallationServiceProvider);
  final processManager = ref.read(mcpProcessManagerProvider);
  final outputService = ref.read(terminalOutputServiceProvider);
  final resourceMonitor = ref.read(resourceMonitorProvider);
  final cleanupService = ref.read(processCleanupServiceProvider);
  final shutdownService = ref.read(gracefulShutdownServiceProvider);
  
  return AgentTerminalManager(
    installationService, 
    processManager, 
    outputService,
    resourceMonitor,
    cleanupService,
    shutdownService,
  );
});

final terminalSessionServiceProvider = Provider<TerminalSessionService>((ref) {
  final terminalManager = ref.read(agentTerminalManagerProvider);
  return TerminalSessionService(terminalManager);
});