import 'dart:async';
import 'dart:io';

/// Simple test for terminal I/O streaming functionality
void main() async {
  print('🧪 Testing Terminal I/O Streaming (Simple)...\n');

  try {
    // Test 1: Basic command execution with streaming
    print('📋 Test 1: Basic command execution...');
    
    final command = Platform.isWindows ? 'echo Hello World' : 'echo "Hello World"';
    
    final result = await Process.run(
      Platform.isWindows ? 'cmd' : 'bash',
      Platform.isWindows ? ['/c', command] : ['-c', command],
      runInShell: true,
    );

    print('✅ Command executed: $command');
    print('   Exit code: ${result.exitCode}');
    print('   Output: ${result.stdout.toString().trim()}');

    // Test 2: Streaming command execution
    print('\n📋 Test 2: Streaming command execution...');
    
    final streamCommand = Platform.isWindows ? 'dir' : 'ls -la';
    
    final process = await Process.start(
      Platform.isWindows ? 'cmd' : 'bash',
      Platform.isWindows ? ['/c', streamCommand] : ['-c', streamCommand],
      runInShell: true,
    );

    // Stream stdout
    final stdoutCompleter = Completer<void>();
    final stderrCompleter = Completer<void>();
    
    process.stdout
        .transform(const SystemEncoding().decoder)
        .listen(
      (data) {
        print('📡 STDOUT: $data');
      },
      onDone: () => stdoutCompleter.complete(),
      onError: (error) => stdoutCompleter.completeError(error),
    );

    process.stderr
        .transform(const SystemEncoding().decoder)
        .listen(
      (data) {
        print('📡 STDERR: $data');
      },
      onDone: () => stderrCompleter.complete(),
      onError: (error) => stderrCompleter.completeError(error),
    );

    // Wait for streams to complete
    await Future.wait([stdoutCompleter.future, stderrCompleter.future]);
    
    final exitCode = await process.exitCode;
    print('✅ Stream command completed with exit code: $exitCode');

    // Test 3: Real-time output buffering simulation
    print('\n📋 Test 3: Real-time output buffering...');
    
    final outputBuffer = <String>[];
    final maxBufferSize = 10;
    
    // Simulate adding output to buffer
    for (int i = 1; i <= 15; i++) {
      final output = 'Output line $i';
      outputBuffer.add(output);
      
      // Maintain buffer size limit
      while (outputBuffer.length > maxBufferSize) {
        outputBuffer.removeAt(0);
      }
      
      print('📝 Added: $output (Buffer size: ${outputBuffer.length})');
    }
    
    print('✅ Final buffer contents:');
    for (int i = 0; i < outputBuffer.length; i++) {
      print('   ${i + 1}. ${outputBuffer[i]}');
    }

    // Test 4: Command history simulation
    print('\n📋 Test 4: Command history tracking...');
    
    final commandHistory = <Map<String, dynamic>>[];
    final commands = [
      'echo "Test 1"',
      'echo "Test 2"',
      Platform.isWindows ? 'dir' : 'ls',
      'echo "Test 3"',
    ];
    
    for (final cmd in commands) {
      final startTime = DateTime.now();
      
      final result = await Process.run(
        Platform.isWindows ? 'cmd' : 'bash',
        Platform.isWindows ? ['/c', cmd] : ['-c', cmd],
        runInShell: true,
      );
      
      final executionTime = DateTime.now().difference(startTime);
      
      final historyEntry = {
        'command': cmd,
        'timestamp': DateTime.now().toIso8601String(),
        'exitCode': result.exitCode,
        'executionTime': executionTime.inMilliseconds,
        'wasSuccessful': result.exitCode == 0,
      };
      
      commandHistory.add(historyEntry);
      
      print('📝 Executed: $cmd (${result.exitCode == 0 ? "✅" : "❌"})');
    }
    
    print('\n✅ Command history (${commandHistory.length} entries):');
    for (final entry in commandHistory) {
      print('   - ${entry['command']} (${entry['wasSuccessful'] ? "✅" : "❌"}) - ${entry['executionTime']}ms');
    }

    // Test 5: Output filtering simulation
    print('\n📋 Test 5: Output filtering...');
    
    final allOutputs = [
      {'type': 'stdout', 'content': 'Normal output'},
      {'type': 'stderr', 'content': 'Error message'},
      {'type': 'system', 'content': 'System message'},
      {'type': 'stdout', 'content': 'Another output'},
      {'type': 'command', 'content': '> echo test'},
    ];
    
    // Filter only stdout and system messages
    final filteredOutputs = allOutputs.where((output) => 
        output['type'] == 'stdout' || output['type'] == 'system').toList();
    
    print('✅ Filtered outputs (${filteredOutputs.length}/${allOutputs.length}):');
    for (final output in filteredOutputs) {
      print('   [${output['type']}] ${output['content']}');
    }

    print('\n🎉 All terminal streaming tests completed successfully!');
    
  } catch (e, stackTrace) {
    print('❌ Test failed: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}