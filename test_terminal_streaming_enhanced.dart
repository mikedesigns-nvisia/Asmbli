import 'dart:async';
import 'dart:io';
import 'apps/desktop/lib/core/services/agent_terminal_manager.dart';
import 'apps/desktop/lib/core/services/terminal_output_service.dart';
import 'apps/desktop/lib/core/services/mcp_installation_service.dart';
import 'apps/desktop/lib/core/services/mcp_process_manager.dart';
import 'apps/desktop/lib/core/models/agent_terminal.dart';

/// Test enhanced terminal I/O streaming functionality
void main() async {
  print('🧪 Testing Enhanced Terminal I/O Streaming...\n');

  // Create services
  final outputService = TerminalOutputService();
  final installationService = MCPInstallationService();
  final processManager = MCPProcessManager(null, null); // Mock dependencies
  final terminalManager = AgentTerminalManager(
    installationService,
    processManager,
    outputService,
  );

  const agentId = 'test-agent-streaming';
  
  try {
    // Test 1: Create terminal with streaming
    print('📋 Test 1: Creating terminal with streaming capabilities...');
    
    final config = AgentTerminalConfig(
      agentId: agentId,
      workingDirectory: Directory.current.path,
      securityContext: SecurityContext(
        agentId: agentId,
        resourceLimits: const ResourceLimits(),
        terminalPermissions: const TerminalPermissions(
          canExecuteShellCommands: true,
          canModifyEnvironment: true,
          canAccessNetwork: true,
        ),
      ),
      resourceLimits: const ResourceLimits(),
    );

    final terminal = await terminalManager.createTerminal(agentId, config);
    print('✅ Terminal created successfully');

    // Test 2: Stream output in real-time
    print('\n📋 Test 2: Testing real-time output streaming...');
    
    final outputStream = terminalManager.streamOutput(agentId);
    final streamSubscription = outputStream.listen((output) {
      print('📡 [${output.type.name.toUpperCase()}] ${output.content}');
    });

    // Test 3: Execute command with streaming
    print('\n📋 Test 3: Executing command with streaming...');
    
    final command = Platform.isWindows ? 'echo Hello from streaming terminal' : 'echo "Hello from streaming terminal"';
    
    // Test both execute methods
    final result = await terminal.execute(command);
    print('✅ Command executed: ${result.command}');
    print('   Exit code: ${result.exitCode}');
    print('   Execution time: ${result.executionTime.inMilliseconds}ms');

    // Test 4: Stream command execution
    print('\n📋 Test 4: Testing stream execution...');
    
    final streamCommand = Platform.isWindows ? 'dir' : 'ls -la';
    
    await for (final line in terminal.executeStream(streamCommand)) {
      print('🔄 Stream: $line');
      // Break after a few lines to avoid too much output
      if (line.contains('[SYSTEM]')) break;
    }

    // Test 5: Test command history
    print('\n📋 Test 5: Testing command history...');
    
    final history = terminalManager.getCommandHistory(agentId, limit: 5);
    print('✅ Command history (${history.length} entries):');
    for (final entry in history) {
      print('   - ${entry.command} (${entry.wasSuccessful ? "✅" : "❌"})');
    }

    // Test 6: Test filtered output streaming
    print('\n📋 Test 6: Testing filtered output streaming...');
    
    final filteredStream = outputService.streamFilteredOutput(
      agentId,
      types: [TerminalOutputType.stdout, TerminalOutputType.system],
    );

    // Execute another command to generate output
    final testCommand = Platform.isWindows ? 'echo Filtered output test' : 'echo "Filtered output test"';
    
    // Listen to filtered stream for a short time
    final filteredSubscription = filteredStream.listen((output) {
      print('🔍 Filtered: [${output.type.name}] ${output.content}');
    });

    await terminal.execute(testCommand);
    
    // Wait a bit for output to be processed
    await Future.delayed(const Duration(milliseconds: 500));

    // Test 7: Test terminal metrics
    print('\n📋 Test 7: Testing terminal metrics...');
    
    final metrics = terminalManager.getTerminalMetrics(agentId);
    print('✅ Terminal metrics:');
    print('   - Status: ${metrics['status']}');
    print('   - Total commands: ${metrics['totalCommands']}');
    print('   - Success rate: ${metrics['successRate']}%');
    print('   - Uptime: ${metrics['uptime']} minutes');

    // Test 8: Test output statistics
    print('\n📋 Test 8: Testing output statistics...');
    
    final outputStats = outputService.getOutputStats(agentId);
    print('✅ Output statistics:');
    print('   - Total outputs: ${outputStats['totalOutputs']}');
    print('   - Buffer size: ${outputStats['bufferSize']}');
    print('   - Type breakdown: ${outputStats['typeBreakdown']}');

    // Cleanup
    await streamSubscription.cancel();
    await filteredSubscription.cancel();
    await terminalManager.destroyTerminal(agentId);
    
    print('\n🎉 All streaming tests completed successfully!');
    
  } catch (e, stackTrace) {
    print('❌ Test failed: $e');
    print('Stack trace: $stackTrace');
    
    // Cleanup on error
    try {
      await terminalManager.destroyTerminal(agentId);
    } catch (cleanupError) {
      print('⚠️  Cleanup error: $cleanupError');
    }
    
    exit(1);
  }
}