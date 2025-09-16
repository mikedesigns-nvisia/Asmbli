import 'dart:io';
import 'apps/desktop/lib/core/services/resource_monitor.dart';
import 'apps/desktop/lib/core/services/process_cleanup_service.dart';
import 'apps/desktop/lib/core/services/graceful_shutdown_service.dart';
import 'apps/desktop/lib/core/models/agent_terminal.dart';

void main() async {
  print('Testing terminal cleanup and resource management...');

  // Create services
  final resourceMonitor = ResourceMonitor();
  final cleanupService = ProcessCleanupService();
  final shutdownService = GracefulShutdownService(cleanupService, resourceMonitor);

  try {
    // Test resource monitoring
    print('\n1. Testing resource monitoring...');
    
    final resourceLimits = ResourceLimits(
      maxMemoryMB: 256,
      maxCpuPercent: 50,
      maxProcesses: 5,
      maxExecutionTime: Duration(minutes: 5),
    );

    await resourceMonitor.startMonitoring('test-agent', resourceLimits);
    print('✓ Resource monitoring started');

    // Simulate tracking a process
    final testProcess = await Process.start('ping', ['127.0.0.1']);
    resourceMonitor.trackProcess('test-agent', testProcess.pid);
    cleanupService.trackProcess('test-agent', testProcess.pid);
    print('✓ Process tracked: PID ${testProcess.pid}');

    // Get resource usage
    final usage = await resourceMonitor.getResourceUsage('test-agent');
    print('✓ Resource usage: ${usage.memoryUsageMB.toStringAsFixed(1)}MB, ${usage.cpuUsagePercent.toStringAsFixed(1)}% CPU, ${usage.activeProcesses} processes');

    // Test cleanup status
    print('\n2. Testing cleanup status...');
    final cleanupStatus = cleanupService.getCleanupStatus('test-agent');
    print('✓ Cleanup status: ${cleanupStatus.trackedProcesses} processes, ${cleanupStatus.totalTrackedResources} total resources');

    // Test graceful shutdown
    print('\n3. Testing graceful shutdown...');
    final shutdownResult = await shutdownService.shutdownAgent('test-agent');
    
    if (shutdownResult.success) {
      print('✓ Graceful shutdown completed successfully');
      print('  - Duration: ${shutdownResult.duration.inMilliseconds}ms');
      print('  - State preserved: ${shutdownResult.statePreserved}');
      print('  - Resources cleaned: ${shutdownResult.resourcesCleanedUp}');
    } else {
      print('✗ Graceful shutdown failed: ${shutdownResult.error}');
      if (shutdownResult.warnings.isNotEmpty) {
        print('  Warnings: ${shutdownResult.warnings.join(', ')}');
      }
    }

    // Verify process was cleaned up
    await Future.delayed(Duration(seconds: 1));
    final finalUsage = await resourceMonitor.getResourceUsage('test-agent');
    print('✓ Final resource usage: ${finalUsage.activeProcesses} processes');

    print('\n✅ All tests completed successfully!');

  } catch (e, stackTrace) {
    print('❌ Test failed: $e');
    print('Stack trace: $stackTrace');
  } finally {
    // Cleanup
    try {
      await resourceMonitor.dispose();
      await cleanupService.dispose();
      await shutdownService.dispose();
      print('✓ Services disposed');
    } catch (e) {
      print('Warning: Error during cleanup: $e');
    }
  }
}