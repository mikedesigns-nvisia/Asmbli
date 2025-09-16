import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import '../models/agent_terminal.dart';
import 'production_logger.dart';

/// Monitors and enforces resource limits for agent terminals
class ResourceMonitor {
  final Map<String, ResourceMonitorState> _monitorStates = {};
  final Map<String, Timer> _monitorTimers = {};
  final Map<String, List<int>> _trackedProcesses = {};
  
  static const Duration _monitorInterval = Duration(seconds: 5);
  static const Duration _cleanupTimeout = Duration(seconds: 30);

  /// Start monitoring resources for an agent terminal
  Future<void> startMonitoring(String agentId, ResourceLimits limits) async {
    if (_monitorStates.containsKey(agentId)) {
      await stopMonitoring(agentId);
    }

    final state = ResourceMonitorState(
      agentId: agentId,
      limits: limits,
      startTime: DateTime.now(),
    );

    _monitorStates[agentId] = state;
    _trackedProcesses[agentId] = [];

    // Start periodic monitoring
    _monitorTimers[agentId] = Timer.periodic(_monitorInterval, (timer) {
      _performResourceCheck(agentId);
    });

    ProductionLogger.instance.info(
      'Started resource monitoring for agent',
      data: {
        'agent_id': agentId,
        'max_memory_mb': limits.maxMemoryMB,
        'max_cpu_percent': limits.maxCpuPercent,
        'max_processes': limits.maxProcesses,
      },
      category: 'resource_monitor',
    );
  }

  /// Stop monitoring resources for an agent terminal
  Future<void> stopMonitoring(String agentId) async {
    _monitorTimers[agentId]?.cancel();
    _monitorTimers.remove(agentId);
    _monitorStates.remove(agentId);
    _trackedProcesses.remove(agentId);

    ProductionLogger.instance.info(
      'Stopped resource monitoring for agent',
      data: {'agent_id': agentId},
      category: 'resource_monitor',
    );
  }

  /// Track a process for resource monitoring
  void trackProcess(String agentId, int pid) {
    final processes = _trackedProcesses[agentId];
    if (processes != null && !processes.contains(pid)) {
      processes.add(pid);
      ProductionLogger.instance.debug(
        'Tracking process for agent',
        data: {'agent_id': agentId, 'pid': pid},
        category: 'resource_monitor',
      );
    }
  }

  /// Stop tracking a process
  void untrackProcess(String agentId, int pid) {
    final processes = _trackedProcesses[agentId];
    if (processes != null) {
      processes.remove(pid);
      ProductionLogger.instance.debug(
        'Stopped tracking process for agent',
        data: {'agent_id': agentId, 'pid': pid},
        category: 'resource_monitor',
      );
    }
  }

  /// Get current resource usage for an agent
  Future<ResourceUsage> getResourceUsage(String agentId) async {
    final processes = _trackedProcesses[agentId] ?? [];
    
    double totalMemoryMB = 0;
    double totalCpuPercent = 0;
    int activeProcesses = 0;
    final List<ProcessInfo> processDetails = [];

    for (final pid in processes) {
      try {
        final processInfo = await _getProcessInfo(pid);
        if (processInfo != null) {
          totalMemoryMB += processInfo.memoryMB;
          totalCpuPercent += processInfo.cpuPercent;
          activeProcesses++;
          processDetails.add(processInfo);
        }
      } catch (e) {
        // Process might have terminated, remove from tracking
        untrackProcess(agentId, pid);
      }
    }

    return ResourceUsage(
      agentId: agentId,
      memoryUsageMB: totalMemoryMB,
      cpuUsagePercent: totalCpuPercent,
      activeProcesses: activeProcesses,
      processDetails: processDetails,
      timestamp: DateTime.now(),
    );
  }

  /// Perform resource check and enforcement
  Future<void> _performResourceCheck(String agentId) async {
    final state = _monitorStates[agentId];
    if (state == null) return;

    try {
      final usage = await getResourceUsage(agentId);
      final limits = state.limits;

      // Check memory limit
      if (usage.memoryUsageMB > limits.maxMemoryMB) {
        await _handleResourceViolation(
          agentId,
          ResourceViolationType.memory,
          'Memory usage ${usage.memoryUsageMB.toStringAsFixed(1)}MB exceeds limit ${limits.maxMemoryMB}MB',
          usage,
        );
      }

      // Check CPU limit (averaged over time)
      if (usage.cpuUsagePercent > limits.maxCpuPercent) {
        await _handleResourceViolation(
          agentId,
          ResourceViolationType.cpu,
          'CPU usage ${usage.cpuUsagePercent.toStringAsFixed(1)}% exceeds limit ${limits.maxCpuPercent}%',
          usage,
        );
      }

      // Check process count limit
      if (usage.activeProcesses > limits.maxProcesses) {
        await _handleResourceViolation(
          agentId,
          ResourceViolationType.processCount,
          'Process count ${usage.activeProcesses} exceeds limit ${limits.maxProcesses}',
          usage,
        );
      }

      // Check execution time limit
      final executionTime = DateTime.now().difference(state.startTime);
      if (executionTime > limits.maxExecutionTime) {
        await _handleResourceViolation(
          agentId,
          ResourceViolationType.executionTime,
          'Execution time ${executionTime.inMinutes}min exceeds limit ${limits.maxExecutionTime.inMinutes}min',
          usage,
        );
      }

      // Update state with current usage
      state.lastUsage = usage;
      state.lastCheck = DateTime.now();

    } catch (e) {
      ProductionLogger.instance.error(
        'Error during resource check',
        error: e,
        data: {'agent_id': agentId},
        category: 'resource_monitor',
      );
    }
  }

  /// Handle resource limit violations
  Future<void> _handleResourceViolation(
    String agentId,
    ResourceViolationType violationType,
    String message,
    ResourceUsage usage,
  ) async {
    ProductionLogger.instance.warning(
      'Resource limit violation detected',
      data: {
        'agent_id': agentId,
        'violation_type': violationType.name,
        'message': message,
        'memory_usage_mb': usage.memoryUsageMB,
        'cpu_usage_percent': usage.cpuUsagePercent,
        'active_processes': usage.activeProcesses,
      },
      category: 'resource_monitor',
    );

    // For now, just log the violation
    // In a production system, this could:
    // - Terminate processes
    // - Throttle CPU usage
    // - Send alerts to administrators
    // - Trigger graceful shutdown
  }

  /// Get process information for a specific PID
  Future<ProcessInfo?> _getProcessInfo(int pid) async {
    try {
      if (Platform.isWindows) {
        return await _getWindowsProcessInfo(pid);
      } else {
        return await _getUnixProcessInfo(pid);
      }
    } catch (e) {
      return null;
    }
  }

  /// Get process info on Windows using tasklist
  Future<ProcessInfo?> _getWindowsProcessInfo(int pid) async {
    try {
      final result = await Process.run(
        'tasklist',
        ['/FI', 'PID eq $pid', '/FO', 'CSV'],
        runInShell: true,
      );

      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        if (lines.length > 1) {
          final parts = lines[1].split(',');
          if (parts.length >= 5) {
            final memoryStr = parts[4].replaceAll('"', '').replaceAll(',', '').replaceAll(' K', '');
            final memoryKB = double.tryParse(memoryStr) ?? 0;
            
            return ProcessInfo(
              pid: pid,
              name: parts[0].replaceAll('"', ''),
              memoryMB: memoryKB / 1024,
              cpuPercent: 0, // Windows tasklist doesn't provide CPU usage
            );
          }
        }
      }
    } catch (e) {
      // Process might not exist
    }
    return null;
  }

  /// Get process info on Unix systems using ps
  Future<ProcessInfo?> _getUnixProcessInfo(int pid) async {
    try {
      final result = await Process.run(
        'ps',
        ['-p', pid.toString(), '-o', 'pid,comm,%cpu,%mem'],
        runInShell: true,
      );

      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        if (lines.length > 1) {
          final parts = lines[1].trim().split(RegExp(r'\s+'));
          if (parts.length >= 4) {
            return ProcessInfo(
              pid: pid,
              name: parts[1],
              cpuPercent: double.tryParse(parts[2]) ?? 0,
              memoryMB: (double.tryParse(parts[3]) ?? 0) * 10, // Rough estimate
            );
          }
        }
      }
    } catch (e) {
      // Process might not exist
    }
    return null;
  }

  /// Kill all tracked processes for an agent
  Future<void> killAllProcesses(String agentId) async {
    final processes = _trackedProcesses[agentId];
    if (processes == null || processes.isEmpty) return;

    ProductionLogger.instance.info(
      'Killing all processes for agent',
      data: {'agent_id': agentId, 'process_count': processes.length},
      category: 'resource_monitor',
    );

    final killFutures = processes.map((pid) => _killProcess(pid));
    await Future.wait(killFutures, eagerError: false);

    _trackedProcesses[agentId]?.clear();
  }

  /// Kill a specific process
  Future<void> _killProcess(int pid) async {
    try {
      if (Platform.isWindows) {
        await Process.run('taskkill', ['/F', '/PID', pid.toString()]);
      } else {
        await Process.run('kill', ['-9', pid.toString()]);
      }
      
      ProductionLogger.instance.debug(
        'Killed process',
        data: {'pid': pid},
        category: 'resource_monitor',
      );
    } catch (e) {
      ProductionLogger.instance.warning(
        'Failed to kill process',
        data: {'pid': pid, 'error': e.toString()},
        category: 'resource_monitor',
      );
    }
  }

  /// Dispose all resources
  Future<void> dispose() async {
    final agentIds = List.from(_monitorStates.keys);
    for (final agentId in agentIds) {
      await stopMonitoring(agentId);
    }
  }
}

/// State for resource monitoring
class ResourceMonitorState {
  final String agentId;
  final ResourceLimits limits;
  final DateTime startTime;
  DateTime lastCheck;
  ResourceUsage? lastUsage;

  ResourceMonitorState({
    required this.agentId,
    required this.limits,
    required this.startTime,
  }) : lastCheck = DateTime.now();
}

/// Current resource usage information
class ResourceUsage {
  final String agentId;
  final double memoryUsageMB;
  final double cpuUsagePercent;
  final int activeProcesses;
  final List<ProcessInfo> processDetails;
  final DateTime timestamp;

  const ResourceUsage({
    required this.agentId,
    required this.memoryUsageMB,
    required this.cpuUsagePercent,
    required this.activeProcesses,
    required this.processDetails,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'memoryUsageMB': memoryUsageMB,
      'cpuUsagePercent': cpuUsagePercent,
      'activeProcesses': activeProcesses,
      'processDetails': processDetails.map((p) => p.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Information about a specific process
class ProcessInfo {
  final int pid;
  final String name;
  final double memoryMB;
  final double cpuPercent;

  const ProcessInfo({
    required this.pid,
    required this.name,
    required this.memoryMB,
    required this.cpuPercent,
  });

  Map<String, dynamic> toJson() {
    return {
      'pid': pid,
      'name': name,
      'memoryMB': memoryMB,
      'cpuPercent': cpuPercent,
    };
  }
}

/// Types of resource violations
enum ResourceViolationType {
  memory,
  cpu,
  processCount,
  executionTime,
  networkConnections,
  fileSize,
}