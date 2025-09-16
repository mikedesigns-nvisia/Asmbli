import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'apps/desktop/lib/core/services/mcp_installation_service.dart';
import 'apps/desktop/lib/core/services/mcp_catalog_service.dart';
import 'apps/desktop/lib/core/models/mcp_server_process.dart';
import 'apps/desktop/lib/core/models/mcp_catalog_entry.dart';
import 'apps/desktop/lib/core/models/agent_terminal.dart';

/// Mock implementation of AgentTerminal for testing
class MockAgentTerminal implements AgentTerminal {
  @override
  final String agentId;
  
  @override
  String workingDirectory = Directory.current.path;
  
  @override
  Map<String, String> environment = Map.from(Platform.environment);
  
  @override
  TerminalStatus status = TerminalStatus.ready;
  
  @override
  final DateTime createdAt = DateTime.now();
  
  @override
  DateTime lastActivity = DateTime.now();
  
  @override
  final List<MCPServerProcess> mcpServers = [];
  
  @override
  final List<CommandHistory> history = [];

  final List<String> _executedCommands = [];
  final Map<String, CommandResult> _commandResults = {};

  MockAgentTerminal(this.agentId);

  /// Set up mock command result
  void setCommandResult(String command, CommandResult result) {
    _commandResults[command] = result;
  }

  @override
  Future<CommandResult> execute(String command) async {
    _executedCommands.add(command);
    lastActivity = DateTime.now();
    
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

  @override
  Stream<String> executeStream(String command) async* {
    final result = await execute(command);
    yield result.stdout;
    if (result.stderr.isNotEmpty) {
      yield result.stderr;
    }
  }

  @override
  Future<void> changeDirectory(String path) async {
    workingDirectory = path;
    lastActivity = DateTime.now();
  }

  @override
  Future<void> setEnvironment(String key, String value) async {
    environment[key] = value;
    lastActivity = DateTime.now();
  }

  @override
  List<CommandHistory> getHistory() => List.unmodifiable(history);

  @override
  Future<void> terminate() async {
    status = TerminalStatus.terminated;
  }

  @override
  Future<void> addMCPServer(MCPServerProcess server) async {
    mcpServers.add(server);
  }

  @override
  Future<void> removeMCPServer(String serverId) async {
    mcpServers.removeWhere((s) => s.serverId == serverId);
  }

  /// Get executed commands for testing
  List<String> get executedCommands => List.unmodifiable(_executedCommands);
}

void main() {
  group('Enhanced MCP Installation Service Tests', () {
    late MCPCatalogService catalogService;
    late MCPInstallationService installationService;
    late MockAgentTerminal mockTerminal;

    setUp(() {
      catalogService = MCPCatalogService();
      catalogService.initializeDefaults();
      installationService = MCPInstallationService(catalogService);
      mockTerminal = MockAgentTerminal('test-agent-1');
    });

    tearDown(() {
      installationService.dispose();
    });

    test('should install MCP server in agent terminal successfully', () async {
      // Arrange
      const serverId = 'filesystem';
      const agentId = 'test-agent-1';
      
      // Set up mock command results for successful installation
      mockTerminal.setCommandResult('uvx --version', CommandResult(
        command: 'uvx --version',
        exitCode: 0,
        stdout: 'uvx 0.4.0',
        stderr: '',
        executionTime: const Duration(milliseconds: 100),
        timestamp: DateTime.now(),
      ));

      mockTerminal.setCommandResult('uvx mcp-server-filesystem --help', CommandResult(
        command: 'uvx mcp-server-filesystem --help',
        exitCode: 0,
        stdout: 'MCP Filesystem Server Help',
        stderr: '',
        executionTime: const Duration(milliseconds: 200),
        timestamp: DateTime.now(),
      ));

      // Act
      final result = await installationService.installServerInTerminal(
        agentId,
        serverId,
        mockTerminal,
      );

      // Assert
      expect(result.success, isTrue);
      expect(result.serverId, equals(serverId));
      expect(result.installationLogs, isNotEmpty);
      expect(mockTerminal.executedCommands, contains('uvx --version'));
      expect(mockTerminal.executedCommands, contains('uvx mcp-server-filesystem --help'));
    });

    test('should track installation progress', () async {
      // Arrange
      const serverId = 'git';
      const agentId = 'test-agent-2';
      final progressUpdates = <MCPInstallationProgress>[];
      
      // Set up successful mock results
      mockTerminal.setCommandResult('uvx --version', CommandResult(
        command: 'uvx --version',
        exitCode: 0,
        stdout: 'uvx 0.4.0',
        stderr: '',
        executionTime: const Duration(milliseconds: 100),
        timestamp: DateTime.now(),
      ));

      mockTerminal.setCommandResult('uvx mcp-server-git --help', CommandResult(
        command: 'uvx mcp-server-git --help',
        exitCode: 0,
        stdout: 'MCP Git Server Help',
        stderr: '',
        executionTime: const Duration(milliseconds: 200),
        timestamp: DateTime.now(),
      ));

      // Listen to progress updates
      final progressStream = installationService.getInstallationProgress(agentId);
      final subscription = progressStream?.listen((progress) {
        progressUpdates.add(progress);
      });

      // Act
      final result = await installationService.installServerInTerminal(
        agentId,
        serverId,
        MockAgentTerminal(agentId),
      );

      // Wait a bit for progress updates
      await Future.delayed(const Duration(milliseconds: 100));
      await subscription?.cancel();

      // Assert
      expect(result.success, isTrue);
      expect(progressUpdates, isNotEmpty);
      expect(progressUpdates.first.stage, equals(MCPInstallationStage.starting));
      expect(progressUpdates.last.stage, equals(MCPInstallationStage.completed));
    });

    test('should retry installation on failure', () async {
      // Arrange
      const serverId = 'sqlite';
      const agentId = 'test-agent-3';
      final terminal = MockAgentTerminal(agentId);
      
      // Set up uvx check to succeed
      terminal.setCommandResult('uvx --version', CommandResult(
        command: 'uvx --version',
        exitCode: 0,
        stdout: 'uvx 0.4.0',
        stderr: '',
        executionTime: const Duration(milliseconds: 100),
        timestamp: DateTime.now(),
      ));

      // Set up verification to fail first two times, then succeed
      var verificationAttempts = 0;
      terminal.setCommandResult('uvx mcp-server-sqlite --help', CommandResult(
        command: 'uvx mcp-server-sqlite --help',
        exitCode: verificationAttempts++ < 2 ? 1 : 0, // Fail first 2 times
        stdout: verificationAttempts <= 2 ? '' : 'MCP SQLite Server Help',
        stderr: verificationAttempts <= 2 ? 'Command not found' : '',
        executionTime: const Duration(milliseconds: 200),
        timestamp: DateTime.now(),
      ));

      // Act
      final result = await installationService.installServerInTerminal(
        agentId,
        serverId,
        terminal,
      );

      // Assert
      expect(result.success, isTrue);
      expect(result.installationLogs.any((log) => log.contains('Installation attempt')), isTrue);
    });

    test('should fail after maximum retries', () async {
      // Arrange
      const serverId = 'filesystem';
      const agentId = 'test-agent-4';
      final terminal = MockAgentTerminal(agentId);
      
      // Set up uvx check to succeed
      terminal.setCommandResult('uvx --version', CommandResult(
        command: 'uvx --version',
        exitCode: 0,
        stdout: 'uvx 0.4.0',
        stderr: '',
        executionTime: const Duration(milliseconds: 100),
        timestamp: DateTime.now(),
      ));

      // Set up verification to always fail
      terminal.setCommandResult('uvx mcp-server-filesystem --help', CommandResult(
        command: 'uvx mcp-server-filesystem --help',
        exitCode: 1,
        stdout: '',
        stderr: 'Command not found',
        executionTime: const Duration(milliseconds: 200),
        timestamp: DateTime.now(),
      ));

      // Act
      final result = await installationService.installServerInTerminal(
        agentId,
        serverId,
        terminal,
      );

      // Assert
      expect(result.success, isFalse);
      expect(result.error, isNotNull);
      expect(result.installationLogs.any((log) => log.contains('Installation attempt 3')), isTrue);
    });

    test('should check if server is installed', () async {
      // Arrange
      const serverId = 'git';
      final terminal = MockAgentTerminal('test-agent-5');
      
      // Set up successful check
      terminal.setCommandResult('uvx mcp-server-git --help', CommandResult(
        command: 'uvx mcp-server-git --help',
        exitCode: 0,
        stdout: 'MCP Git Server Help',
        stderr: '',
        executionTime: const Duration(milliseconds: 200),
        timestamp: DateTime.now(),
      ));

      // Act
      final isInstalled = await installationService.isServerInstalledInTerminal(
        terminal,
        serverId,
      );

      // Assert
      expect(isInstalled, isTrue);
    });

    test('should handle package manager not available', () async {
      // Arrange
      const serverId = 'filesystem';
      const agentId = 'test-agent-6';
      final terminal = MockAgentTerminal(agentId);
      
      // Set up uvx check to fail
      terminal.setCommandResult('uvx --version', CommandResult(
        command: 'uvx --version',
        exitCode: 1,
        stdout: '',
        stderr: 'uvx: command not found',
        executionTime: const Duration(milliseconds: 100),
        timestamp: DateTime.now(),
      ));

      // Act & Assert
      expect(
        () => installationService.installServerInTerminal(agentId, serverId, terminal),
        throwsA(isA<MCPInstallationException>()),
      );
    });

    test('should handle unknown server ID', () async {
      // Arrange
      const serverId = 'unknown-server';
      const agentId = 'test-agent-7';
      final terminal = MockAgentTerminal(agentId);

      // Act & Assert
      expect(
        () => installationService.installServerInTerminal(agentId, serverId, terminal),
        throwsA(isA<MCPInstallationException>()),
      );
    });

    test('should set additional environment variables', () async {
      // Arrange
      const serverId = 'filesystem';
      const agentId = 'test-agent-8';
      final terminal = MockAgentTerminal(agentId);
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

      // Act
      final result = await installationService.installServerInTerminal(
        agentId,
        serverId,
        terminal,
        additionalEnvironment: additionalEnv,
      );

      // Assert
      expect(result.success, isTrue);
      expect(terminal.environment['TEST_VAR'], equals('test_value'));
      expect(terminal.environment['API_KEY'], equals('secret'));
    });
  });
}