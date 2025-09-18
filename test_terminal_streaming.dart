import 'dart:async';
import 'dart:io';
import 'apps/desktop/lib/core/models/agent_terminal.dart';
import 'apps/desktop/lib/core/services/agent_terminal_manager.dart';
import 'apps/desktop/lib/core/services/terminal_output_service.dart';
import 'apps/desktop/lib/core/services/terminal_session_service.dart';
import 'apps/desktop/lib/core/services/mcp_installation_service.dart';
import 'apps/desktop/lib/core/services/mcp_process_manager.dart';

/// Test the enhanced terminal I/O streaming functionality
void main() async {
  print('🧪 Testing Terminal I/O Streaming Implementation...\n');

  // Create services
  final outputService = TerminalOutputService();
  final installationService = MCPInstallationService();
  final processManager = MCPProcessManager();
  final terminalManager = AgentTerminalManager(
    installationService,
    processManager,
    outputService,
  );
  final sessionService = TerminalSessionService(terminalManager);

  try {
    await testBasicTerminalCreation(terminalManager);
    await testTerminalStreaming(terminalManager, outputService);
    await testCommandHistory(terminalManager);
    await testSessionPersistence(terminalManager, sessionService);
    await testOutputBuffering(outputService);
    
    print('✅ All terminal streaming tests passed!');
  } catch (e, stackTrace) {
    print('❌ Test failed: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  } finally {
    await terminalManager.dispose();
    await outputService.closeAllStreams();
  }
}

Future<void> testBasicTerminalCreation(AgentTerminalManager terminalManager) async {
  print('📋 Testing basic terminal creation...');

  final config = AgentTerminalConfig(
    agentId: 'test-agent-1',
    workingDirectory: Directory.current.path,
    securityContext: SecurityContext(
      agentId: 'test-agent-1',
      resourceLimits: const ResourceLimits(),
      terminalPermissions: const TerminalPermissions(
        canExecuteShellCommands: true,
        canInstallPackages: false,
      ),
    ),
    resourceLimits: const ResourceLimits(),
  );

  final terminal = await terminalManager.createTerminal('test-agent-1', config);
  
  assert(terminal.agentId == 'test-agent-1');
  assert(terminal.status == TerminalStatus.ready);
  assert(terminal.workingDirectory == Directory.current.path);
  
  print('✅ Terminal created successfully');
}

Future<void> testTerminalStreaming(
  AgentTerminalManager terminalManager,
  TerminalOutputService outputService,
) async {
  print('📋 Testing terminal output streaming...');

  final agentId = 'test-agent-1';
  final outputReceived = <TerminalOutput>[];
  
  // Listen to output stream
  final subscription = terminalManager.streamOutput(agentId).listen((output) {
    outputReceived.add(output);
    print('📤 Received output: ${output.type.name} - ${output.content}');
  });

  // Execute a simple command
  final command = Platform.isWindows ? 'echo Hello Terminal' : 'echo "Hello Terminal"';
  final result = await terminalManager.executeCommand(agentId, command);
  
  // Wait for output to be processed
  await Future.delayed(const Duration(milliseconds: 500));
  
  assert(result.isSuccess, 'Command should succeed');
  assert(outputReceived.isNotEmpty, 'Should receive output');
  
  // Check that we received command and stdout output
  final commandOutputs = outputReceived.where((o) => o.type == TerminalOutputType.command).toList();
  final stdoutOutputs = outputReceived.where((o) => o.type == TerminalOutputType.stdout).toList();
  
  assert(commandOutputs.isNotEmpty, 'Should receive command output');
  assert(stdoutOutputs.isNotEmpty, 'Should receive stdout output');
  
  await subscription.cancel();
  print('✅ Terminal streaming works correctly');
}

Future<void> testCommandHistory(AgentTerminalManager terminalManager) async {
  print('📋 Testing command history tracking...');

  final agentId = 'test-agent-1';
  
  // Execute multiple commands
  final commands = Platform.isWindows 
      ? ['echo Command 1', 'echo Command 2', 'echo Command 3']
      : ['echo "Command 1"', 'echo "Command 2"', 'echo "Command 3"'];
  
  for (final command in commands) {
    await terminalManager.executeCommand(agentId, command);
    await Future.delayed(const Duration(milliseconds: 100));
  }

  // Get command history
  final history = terminalManager.getCommandHistory(agentId);
  
  assert(history.length >= commands.length, 'Should have at least ${commands.length} commands in history');
  
  // Check that commands are in history
  final historyCommands = history.map((h) => h.command).toList();
  for (final command in commands) {
    assert(historyCommands.contains(command), 'History should contain command: $command');
  }

  // Test filtered history
  final successfulHistory = terminalManager.getCommandHistory(
    agentId,
    successfulOnly: true,
    limit: 2,
  );
  
  assert(successfulHistory.length <= 2, 'Should respect limit');
  assert(successfulHistory.every((h) => h.wasSuccessful), 'Should only contain successful commands');
  
  print('✅ Command history tracking works correctly');
}

Future<void> testSessionPersistence(
  AgentTerminalManager terminalManager,
  TerminalSessionService sessionService,
) async {
  print('📋 Testing session persistence...');

  final agentId = 'test-agent-1';
  
  // Save current session
  await sessionService.saveTerminalSession(agentId);
  
  // Get session info
  final sessionInfo = await sessionService.getSessionInfo(agentId);
  assert(sessionInfo != null, 'Session info should exist');
  assert(sessionInfo!['agentId'] == agentId, 'Session should have correct agent ID');
  
  // List sessions
  final sessions = await sessionService.listTerminalSessions();
  assert(sessions.contains(agentId), 'Session list should contain our agent');
  
  print('✅ Session persistence works correctly');
}

Future<void> testOutputBuffering(TerminalOutputService outputService) async {
  print('📋 Testing output buffering...');

  final agentId = 'test-buffer-agent';
  
  // Create output stream
  outputService.createOutputStream(agentId);
  
  // Add multiple outputs
  final outputs = List.generate(10, (i) => TerminalOutput(
    agentId: agentId,
    content: 'Test output $i',
    type: TerminalOutputType.stdout,
    timestamp: DateTime.now(),
  ));
  
  outputService.addOutputBatch(agentId, outputs);
  
  // Get buffered history
  final history = outputService.getOutputHistory(agentId);
  assert(history.length == outputs.length, 'Should buffer all outputs');
  
  // Test filtered output
  final filteredOutput = outputService.getFilteredOutput(
    agentId,
    types: [TerminalOutputType.stdout],
    limit: 5,
  );
  
  assert(filteredOutput.length == 5, 'Should respect filter and limit');
  assert(filteredOutput.every((o) => o.type == TerminalOutputType.stdout), 'Should only contain stdout');
  
  // Get output stats
  final stats = outputService.getOutputStats(agentId);
  assert(stats['totalOutputs'] == outputs.length, 'Stats should show correct total');
  
  await outputService.closeOutputStream(agentId);
  print('✅ Output buffering works correctly');
}