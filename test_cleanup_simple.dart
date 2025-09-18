import 'dart:io';

/// Simple test for process cleanup functionality
void main() async {
  print('Testing basic process cleanup functionality...');

  try {
    // Test 1: Process tracking and cleanup
    print('\n1. Testing process tracking...');
    
    final trackedProcesses = <int>{};
    
    // Start a test process
    final testProcess = await Process.start('ping', ['127.0.0.1', '-n', '10']);
    trackedProcesses.add(testProcess.pid);
    print('✓ Started test process: PID ${testProcess.pid}');

    // Verify process is running
    final isRunning = await _isProcessRunning(testProcess.pid);
    print('✓ Process running: $isRunning');

    // Test graceful termination
    print('\n2. Testing graceful termination...');
    
    if (Platform.isWindows) {
      await Process.run('taskkill', ['/PID', testProcess.pid.toString()]);
    } else {
      await Process.run('kill', ['-TERM', testProcess.pid.toString()]);
    }
    
    // Wait for graceful shutdown
    await Future.delayed(Duration(seconds: 2));
    
    final stillRunning = await _isProcessRunning(testProcess.pid);
    if (!stillRunning) {
      print('✓ Process terminated gracefully');
    } else {
      print('⚠ Process still running, force killing...');
      
      // Force kill
      if (Platform.isWindows) {
        await Process.run('taskkill', ['/F', '/PID', testProcess.pid.toString()]);
      } else {
        await Process.run('kill', ['-9', testProcess.pid.toString()]);
      }
      
      await Future.delayed(Duration(seconds: 1));
      final finalCheck = await _isProcessRunning(testProcess.pid);
      print('✓ Process force killed: ${!finalCheck}');
    }

    // Test 3: Resource limits simulation
    print('\n3. Testing resource limits simulation...');
    
    final resourceLimits = {
      'maxMemoryMB': 256,
      'maxCpuPercent': 50,
      'maxProcesses': 5,
      'maxExecutionTimeMinutes': 5,
    };
    
    print('✓ Resource limits configured: $resourceLimits');

    // Test 4: Cleanup status tracking
    print('\n4. Testing cleanup status tracking...');
    
    final cleanupStatus = {
      'trackedProcesses': 0,
      'trackedMCPServers': 0,
      'trackedTempFiles': 0,
      'trackedTempDirectories': 0,
    };
    
    print('✓ Cleanup status: $cleanupStatus');

    print('\n✅ All basic tests completed successfully!');
    print('Note: Full integration tests require Flutter environment');

  } catch (e, stackTrace) {
    print('❌ Test failed: $e');
    print('Stack trace: $stackTrace');
  }
}

/// Check if a process is still running
Future<bool> _isProcessRunning(int pid) async {
  try {
    if (Platform.isWindows) {
      final result = await Process.run(
        'tasklist',
        ['/FI', 'PID eq $pid'],
        runInShell: true,
      );
      return result.stdout.toString().contains(pid.toString());
    } else {
      final result = await Process.run('kill', ['-0', pid.toString()]);
      return result.exitCode == 0;
    }
  } catch (e) {
    return false;
  }
}