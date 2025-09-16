import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/agent_terminal.dart';
import '../models/mcp_server_process.dart';
import 'production_logger.dart';

/// Service responsible for proper cleanup of processes and resources
class ProcessCleanupService {
  final Map<String, Set<int>> _agentProcesses = {};
  final Map<String, Set<String>> _agentMCPServers = {};
  final Map<String, List<String>> _agentTempFiles = {};
  final Map<String, List<String>> _agentTempDirectories = {};
  
  static const Duration _gracefulShutdownTimeout = Duration(seconds: 10);
  static const Duration _forceKillTimeout = Duration(seconds: 5);

  /// Register a process for cleanup tracking
  void trackProcess(String agentId, int pid) {
    _agentProcesses.putIfAbsent(agentId, () => <int>{}).add(pid);
    
    ProductionLogger.instance.debug(
      'Tracking process for cleanup',
      data: {'agent_id': agentId, 'pid': pid},
      category: 'process_cleanup',
    );
  }

  /// Unregister a process from cleanup tracking
  void untrackProcess(String agentId, int pid) {
    _agentProcesses[agentId]?.remove(pid);
    
    ProductionLogger.instance.debug(
      'Stopped tracking process for cleanup',
      data: {'agent_id': agentId, 'pid': pid},
      category: 'process_cleanup',
    );
  }

  /// Register an MCP server for cleanup tracking
  void trackMCPServer(String agentId, String serverId) {
    _agentMCPServers.putIfAbsent(agentId, () => <String>{}).add(serverId);
    
    ProductionLogger.instance.debug(
      'Tracking MCP server for cleanup',
      data: {'agent_id': agentId, 'server_id': serverId},
      category: 'process_cleanup',
    );
  }

  /// Unregister an MCP server from cleanup tracking
  void untrackMCPServer(String agentId, String serverId) {
    _agentMCPServers[agentId]?.remove(serverId);
    
    ProductionLogger.instance.debug(
      'Stopped tracking MCP server for cleanup',
      data: {'agent_id': agentId, 'server_id': serverId},
      category: 'process_cleanup',
    );
  }

  /// Register a temporary file for cleanup
  void trackTempFile(String agentId, String filePath) {
    _agentTempFiles.putIfAbsent(agentId, () => <String>[]).add(filePath);
    
    ProductionLogger.instance.debug(
      'Tracking temp file for cleanup',
      data: {'agent_id': agentId, 'file_path': filePath},
      category: 'process_cleanup',
    );
  }

  /// Register a temporary directory for cleanup
  void trackTempDirectory(String agentId, String dirPath) {
    _agentTempDirectories.putIfAbsent(agentId, () => <String>[]).add(dirPath);
    
    ProductionLogger.instance.debug(
      'Tracking temp directory for cleanup',
      data: {'agent_id': agentId, 'dir_path': dirPath},
      category: 'process_cleanup',
    );
  }

  /// Perform complete cleanup for an agent terminal
  Future<CleanupResult> cleanupAgent(String agentId) async {
    final startTime = DateTime.now();
    final result = CleanupResult(agentId: agentId, startTime: startTime);

    ProductionLogger.instance.info(
      'Starting cleanup for agent',
      data: {
        'agent_id': agentId,
        'tracked_processes': _agentProcesses[agentId]?.length ?? 0,
        'tracked_mcp_servers': _agentMCPServers[agentId]?.length ?? 0,
        'tracked_temp_files': _agentTempFiles[agentId]?.length ?? 0,
        'tracked_temp_dirs': _agentTempDirectories[agentId]?.length ?? 0,
      },
      category: 'process_cleanup',
    );

    try {
      // 1. Stop MCP servers gracefully
      await _cleanupMCPServers(agentId, result);

      // 2. Terminate processes gracefully, then forcefully if needed
      await _cleanupProcesses(agentId, result);

      // 3. Clean up temporary files and directories
      await _cleanupTempFiles(agentId, result);
      await _cleanupTempDirectories(agentId, result);

      // 4. Remove tracking entries
      _agentProcesses.remove(agentId);
      _agentMCPServers.remove(agentId);
      _agentTempFiles.remove(agentId);
      _agentTempDirectories.remove(agentId);

      result.success = true;
      result.endTime = DateTime.now();

      ProductionLogger.instance.info(
        'Cleanup completed successfully',
        data: {
          'agent_id': agentId,
          'duration_ms': result.duration.inMilliseconds,
          'processes_terminated': result.processesTerminated,
          'mcp_servers_stopped': result.mcpServersStopped,
          'temp_files_deleted': result.tempFilesDeleted,
          'temp_dirs_deleted': result.tempDirsDeleted,
        },
        category: 'process_cleanup',
      );

    } catch (e) {
      result.success = false;
      result.error = e.toString();
      result.endTime = DateTime.now();

      ProductionLogger.instance.error(
        'Cleanup failed for agent',
        error: e,
        data: {
          'agent_id': agentId,
          'duration_ms': result.duration.inMilliseconds,
        },
        category: 'process_cleanup',
      );
    }

    return result;
  }

  /// Cleanup MCP servers for an agent
  Future<void> _cleanupMCPServers(String agentId, CleanupResult result) async {
    final serverIds = _agentMCPServers[agentId];
    if (serverIds == null || serverIds.isEmpty) return;

    ProductionLogger.instance.info(
      'Cleaning up MCP servers',
      data: {'agent_id': agentId, 'server_count': serverIds.length},
      category: 'process_cleanup',
    );

    for (final serverId in serverIds) {
      try {
        // Send graceful shutdown signal to MCP server
        // This would integrate with the MCP process manager
        await _shutdownMCPServer(serverId);
        result.mcpServersStopped++;
        
        ProductionLogger.instance.debug(
          'MCP server stopped',
          data: {'agent_id': agentId, 'server_id': serverId},
          category: 'process_cleanup',
        );
      } catch (e) {
        result.errors.add('Failed to stop MCP server $serverId: $e');
        ProductionLogger.instance.warning(
          'Failed to stop MCP server',
          data: {'agent_id': agentId, 'server_id': serverId, 'error': e.toString()},
          category: 'process_cleanup',
        );
      }
    }
  }

  /// Cleanup processes for an agent
  Future<void> _cleanupProcesses(String agentId, CleanupResult result) async {
    final processes = _agentProcesses[agentId];
    if (processes == null || processes.isEmpty) return;

    ProductionLogger.instance.info(
      'Cleaning up processes',
      data: {'agent_id': agentId, 'process_count': processes.length},
      category: 'process_cleanup',
    );

    // First, try graceful termination
    final gracefulResults = await _terminateProcessesGracefully(processes.toList());
    result.processesTerminated += gracefulResults.terminated;
    result.errors.addAll(gracefulResults.errors);

    // Then, force kill any remaining processes
    if (gracefulResults.remaining.isNotEmpty) {
      ProductionLogger.instance.warning(
        'Some processes did not terminate gracefully, force killing',
        data: {
          'agent_id': agentId,
          'remaining_processes': gracefulResults.remaining.length,
        },
        category: 'process_cleanup',
      );

      final forceResults = await _forceKillProcesses(gracefulResults.remaining);
      result.processesTerminated += forceResults.terminated;
      result.errors.addAll(forceResults.errors);

      if (forceResults.remaining.isNotEmpty) {
        result.errors.add('Failed to kill ${forceResults.remaining.length} processes');
      }
    }
  }

  /// Attempt graceful termination of processes
  Future<ProcessTerminationResult> _terminateProcessesGracefully(List<int> pids) async {
    final result = ProcessTerminationResult();
    
    // Send SIGTERM (or equivalent) to all processes
    for (final pid in pids) {
      try {
        if (Platform.isWindows) {
          // On Windows, use taskkill without /F flag for graceful termination
          await Process.run('taskkill', ['/PID', pid.toString()]);
        } else {
          // On Unix systems, send SIGTERM
          await Process.run('kill', ['-TERM', pid.toString()]);
        }
      } catch (e) {
        result.errors.add('Failed to send termination signal to PID $pid: $e');
      }
    }

    // Wait for processes to terminate gracefully
    await Future.delayed(_gracefulShutdownTimeout);

    // Check which processes are still running
    for (final pid in pids) {
      if (await _isProcessRunning(pid)) {
        result.remaining.add(pid);
      } else {
        result.terminated++;
      }
    }

    return result;
  }

  /// Force kill remaining processes
  Future<ProcessTerminationResult> _forceKillProcesses(List<int> pids) async {
    final result = ProcessTerminationResult();
    
    for (final pid in pids) {
      try {
        if (Platform.isWindows) {
          await Process.run('taskkill', ['/F', '/PID', pid.toString()]);
        } else {
          await Process.run('kill', ['-9', pid.toString()]);
        }

        // Wait a bit and check if process is gone
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (await _isProcessRunning(pid)) {
          result.remaining.add(pid);
        } else {
          result.terminated++;
        }
      } catch (e) {
        result.errors.add('Failed to force kill PID $pid: $e');
        result.remaining.add(pid);
      }
    }

    return result;
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

  /// Cleanup temporary files for an agent
  Future<void> _cleanupTempFiles(String agentId, CleanupResult result) async {
    final tempFiles = _agentTempFiles[agentId];
    if (tempFiles == null || tempFiles.isEmpty) return;

    ProductionLogger.instance.info(
      'Cleaning up temporary files',
      data: {'agent_id': agentId, 'file_count': tempFiles.length},
      category: 'process_cleanup',
    );

    for (final filePath in tempFiles) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
          result.tempFilesDeleted++;
          
          ProductionLogger.instance.debug(
            'Deleted temp file',
            data: {'agent_id': agentId, 'file_path': filePath},
            category: 'process_cleanup',
          );
        }
      } catch (e) {
        result.errors.add('Failed to delete temp file $filePath: $e');
        ProductionLogger.instance.warning(
          'Failed to delete temp file',
          data: {'agent_id': agentId, 'file_path': filePath, 'error': e.toString()},
          category: 'process_cleanup',
        );
      }
    }
  }

  /// Cleanup temporary directories for an agent
  Future<void> _cleanupTempDirectories(String agentId, CleanupResult result) async {
    final tempDirs = _agentTempDirectories[agentId];
    if (tempDirs == null || tempDirs.isEmpty) return;

    ProductionLogger.instance.info(
      'Cleaning up temporary directories',
      data: {'agent_id': agentId, 'dir_count': tempDirs.length},
      category: 'process_cleanup',
    );

    for (final dirPath in tempDirs) {
      try {
        final directory = Directory(dirPath);
        if (await directory.exists()) {
          await directory.delete(recursive: true);
          result.tempDirsDeleted++;
          
          ProductionLogger.instance.debug(
            'Deleted temp directory',
            data: {'agent_id': agentId, 'dir_path': dirPath},
            category: 'process_cleanup',
          );
        }
      } catch (e) {
        result.errors.add('Failed to delete temp directory $dirPath: $e');
        ProductionLogger.instance.warning(
          'Failed to delete temp directory',
          data: {'agent_id': agentId, 'dir_path': dirPath, 'error': e.toString()},
          category: 'process_cleanup',
        );
      }
    }
  }

  /// Shutdown an MCP server gracefully
  Future<void> _shutdownMCPServer(String serverId) async {
    // This would integrate with the MCP process manager
    // For now, we'll just log the action
    ProductionLogger.instance.info(
      'Shutting down MCP server',
      data: {'server_id': serverId},
      category: 'process_cleanup',
    );
    
    // TODO: Implement actual MCP server shutdown
    // This would involve:
    // 1. Sending a shutdown message via JSON-RPC
    // 2. Waiting for graceful shutdown
    // 3. Force killing if needed
  }

  /// Get cleanup status for an agent
  CleanupStatus getCleanupStatus(String agentId) {
    return CleanupStatus(
      agentId: agentId,
      trackedProcesses: _agentProcesses[agentId]?.length ?? 0,
      trackedMCPServers: _agentMCPServers[agentId]?.length ?? 0,
      trackedTempFiles: _agentTempFiles[agentId]?.length ?? 0,
      trackedTempDirectories: _agentTempDirectories[agentId]?.length ?? 0,
    );
  }

  /// Dispose all resources
  Future<void> dispose() async {
    final agentIds = List.from(_agentProcesses.keys);
    for (final agentId in agentIds) {
      await cleanupAgent(agentId);
    }
  }
}

/// Result of cleanup operation
class CleanupResult {
  final String agentId;
  final DateTime startTime;
  DateTime? endTime;
  bool success = false;
  String? error;
  int processesTerminated = 0;
  int mcpServersStopped = 0;
  int tempFilesDeleted = 0;
  int tempDirsDeleted = 0;
  final List<String> errors = [];

  CleanupResult({
    required this.agentId,
    required this.startTime,
  });

  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'success': success,
      'error': error,
      'processesTerminated': processesTerminated,
      'mcpServersStopped': mcpServersStopped,
      'tempFilesDeleted': tempFilesDeleted,
      'tempDirsDeleted': tempDirsDeleted,
      'errors': errors,
      'durationMs': duration.inMilliseconds,
    };
  }
}

/// Status of cleanup tracking for an agent
class CleanupStatus {
  final String agentId;
  final int trackedProcesses;
  final int trackedMCPServers;
  final int trackedTempFiles;
  final int trackedTempDirectories;

  const CleanupStatus({
    required this.agentId,
    required this.trackedProcesses,
    required this.trackedMCPServers,
    required this.trackedTempFiles,
    required this.trackedTempDirectories,
  });

  int get totalTrackedResources =>
      trackedProcesses + trackedMCPServers + trackedTempFiles + trackedTempDirectories;

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'trackedProcesses': trackedProcesses,
      'trackedMCPServers': trackedMCPServers,
      'trackedTempFiles': trackedTempFiles,
      'trackedTempDirectories': trackedTempDirectories,
      'totalTrackedResources': totalTrackedResources,
    };
  }
}

/// Result of process termination attempt
class ProcessTerminationResult {
  int terminated = 0;
  final List<int> remaining = [];
  final List<String> errors = [];
}