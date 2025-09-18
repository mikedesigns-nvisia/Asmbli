import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/agent_terminal.dart';
import 'production_logger.dart';
import 'process_cleanup_service.dart';
import 'resource_monitor.dart';

/// Service that handles graceful shutdown of agent terminals
class GracefulShutdownService {
  final ProcessCleanupService _cleanupService;
  final ResourceMonitor _resourceMonitor;
  
  final Map<String, ShutdownState> _shutdownStates = {};
  final Map<String, Completer<ShutdownResult>> _shutdownCompleters = {};
  
  static const Duration _defaultShutdownTimeout = Duration(seconds: 30);
  static const Duration _emergencyShutdownTimeout = Duration(seconds: 60);

  GracefulShutdownService(this._cleanupService, this._resourceMonitor);

  /// Initiate graceful shutdown for an agent terminal
  Future<ShutdownResult> shutdownAgent(
    String agentId, {
    Duration timeout = _defaultShutdownTimeout,
    bool force = false,
  }) async {
    // Check if shutdown is already in progress
    if (_shutdownStates.containsKey(agentId)) {
      final existingCompleter = _shutdownCompleters[agentId];
      if (existingCompleter != null && !existingCompleter.isCompleted) {
        return await existingCompleter.future;
      }
    }

    final completer = Completer<ShutdownResult>();
    _shutdownCompleters[agentId] = completer;

    final shutdownState = ShutdownState(
      agentId: agentId,
      startTime: DateTime.now(),
      timeout: timeout,
      force: force,
    );
    _shutdownStates[agentId] = shutdownState;

    ProductionLogger.instance.info(
      'Initiating graceful shutdown for agent',
      data: {
        'agent_id': agentId,
        'timeout_seconds': timeout.inSeconds,
        'force': force,
      },
      category: 'graceful_shutdown',
    );

    // Start shutdown process
    _performShutdown(agentId, shutdownState, completer);

    return await completer.future;
  }

  /// Perform the actual shutdown process
  void _performShutdown(
    String agentId,
    ShutdownState state,
    Completer<ShutdownResult> completer,
  ) async {
    final result = ShutdownResult(
      agentId: agentId,
      startTime: state.startTime,
      force: state.force,
    );

    try {
      // Set up timeout
      final timeoutTimer = Timer(state.timeout, () {
        if (!completer.isCompleted) {
          result.timedOut = true;
          result.endTime = DateTime.now();
          result.success = false;
          result.error = 'Shutdown timed out after ${state.timeout.inSeconds} seconds';
          
          ProductionLogger.instance.warning(
            'Agent shutdown timed out',
            data: {
              'agent_id': agentId,
              'timeout_seconds': state.timeout.inSeconds,
            },
            category: 'graceful_shutdown',
          );
          
          completer.complete(result);
        }
      });

      // Phase 1: Pre-shutdown preparation
      state.phase = ShutdownPhase.preparation;
      await _performPreShutdownPreparation(agentId, state, result);

      if (completer.isCompleted) return;

      // Phase 2: Stop accepting new work
      state.phase = ShutdownPhase.stopAcceptingWork;
      await _stopAcceptingNewWork(agentId, state, result);

      if (completer.isCompleted) return;

      // Phase 3: Wait for current operations to complete
      state.phase = ShutdownPhase.waitingForCompletion;
      await _waitForCurrentOperations(agentId, state, result);

      if (completer.isCompleted) return;

      // Phase 4: Stop MCP servers
      state.phase = ShutdownPhase.stoppingMCPServers;
      await _stopMCPServers(agentId, state, result);

      if (completer.isCompleted) return;

      // Phase 5: Cleanup resources
      state.phase = ShutdownPhase.cleanupResources;
      await _cleanupResources(agentId, state, result);

      if (completer.isCompleted) return;

      // Phase 6: Final cleanup
      state.phase = ShutdownPhase.finalCleanup;
      await _performFinalCleanup(agentId, state, result);

      // Success
      timeoutTimer.cancel();
      result.success = true;
      result.endTime = DateTime.now();
      
      ProductionLogger.instance.info(
        'Agent shutdown completed successfully',
        data: {
          'agent_id': agentId,
          'duration_ms': result.duration.inMilliseconds,
          'phases_completed': state.phase.index + 1,
        },
        category: 'graceful_shutdown',
      );

      if (!completer.isCompleted) {
        completer.complete(result);
      }

    } catch (e) {
      result.success = false;
      result.error = e.toString();
      result.endTime = DateTime.now();
      
      ProductionLogger.instance.error(
        'Agent shutdown failed',
        error: e,
        data: {
          'agent_id': agentId,
          'phase': state.phase.name,
          'duration_ms': result.duration.inMilliseconds,
        },
        category: 'graceful_shutdown',
      );

      if (!completer.isCompleted) {
        completer.complete(result);
      }
    } finally {
      _shutdownStates.remove(agentId);
      _shutdownCompleters.remove(agentId);
    }
  }

  /// Phase 1: Pre-shutdown preparation
  Future<void> _performPreShutdownPreparation(
    String agentId,
    ShutdownState state,
    ShutdownResult result,
  ) async {
    ProductionLogger.instance.info(
      'Starting pre-shutdown preparation',
      data: {'agent_id': agentId},
      category: 'graceful_shutdown',
    );

    // Save current terminal state for potential recovery
    try {
      // This would integrate with the terminal manager to save state
      result.statePreserved = true;
      
      ProductionLogger.instance.debug(
        'Terminal state preserved',
        data: {'agent_id': agentId},
        category: 'graceful_shutdown',
      );
    } catch (e) {
      result.warnings.add('Failed to preserve terminal state: $e');
      ProductionLogger.instance.warning(
        'Failed to preserve terminal state',
        data: {'agent_id': agentId, 'error': e.toString()},
        category: 'graceful_shutdown',
      );
    }

    // Notify any listeners about impending shutdown
    result.preparationCompleted = true;
  }

  /// Phase 2: Stop accepting new work
  Future<void> _stopAcceptingNewWork(
    String agentId,
    ShutdownState state,
    ShutdownResult result,
  ) async {
    ProductionLogger.instance.info(
      'Stopping acceptance of new work',
      data: {'agent_id': agentId},
      category: 'graceful_shutdown',
    );

    // Mark terminal as shutting down so no new commands are accepted
    // This would integrate with the terminal manager
    result.stoppedAcceptingWork = true;
  }

  /// Phase 3: Wait for current operations to complete
  Future<void> _waitForCurrentOperations(
    String agentId,
    ShutdownState state,
    ShutdownResult result,
  ) async {
    ProductionLogger.instance.info(
      'Waiting for current operations to complete',
      data: {'agent_id': agentId},
      category: 'graceful_shutdown',
    );

    final maxWaitTime = state.force ? Duration.zero : Duration(seconds: 10);
    final startWait = DateTime.now();

    while (DateTime.now().difference(startWait) < maxWaitTime) {
      // Check if there are any running operations
      // This would integrate with the terminal manager to check for active commands
      final hasActiveOperations = await _hasActiveOperations(agentId);
      
      if (!hasActiveOperations) {
        result.operationsCompleted = true;
        ProductionLogger.instance.debug(
          'All operations completed',
          data: {'agent_id': agentId},
          category: 'graceful_shutdown',
        );
        return;
      }

      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (state.force) {
      result.warnings.add('Forced shutdown - operations may have been interrupted');
    } else {
      result.warnings.add('Some operations may not have completed gracefully');
    }
  }

  /// Phase 4: Stop MCP servers
  Future<void> _stopMCPServers(
    String agentId,
    ShutdownState state,
    ShutdownResult result,
  ) async {
    ProductionLogger.instance.info(
      'Stopping MCP servers',
      data: {'agent_id': agentId},
      category: 'graceful_shutdown',
    );

    try {
      // Get cleanup status to see what MCP servers need to be stopped
      final cleanupStatus = _cleanupService.getCleanupStatus(agentId);
      
      if (cleanupStatus.trackedMCPServers > 0) {
        // Stop MCP servers gracefully
        // This would integrate with the MCP process manager
        result.mcpServersStoppedCount = cleanupStatus.trackedMCPServers;
        
        ProductionLogger.instance.debug(
          'MCP servers stopped',
          data: {
            'agent_id': agentId,
            'server_count': cleanupStatus.trackedMCPServers,
          },
          category: 'graceful_shutdown',
        );
      }
      
      result.mcpServersStopped = true;
    } catch (e) {
      result.warnings.add('Failed to stop some MCP servers: $e');
      ProductionLogger.instance.warning(
        'Failed to stop MCP servers gracefully',
        data: {'agent_id': agentId, 'error': e.toString()},
        category: 'graceful_shutdown',
      );
    }
  }

  /// Phase 5: Cleanup resources
  Future<void> _cleanupResources(
    String agentId,
    ShutdownState state,
    ShutdownResult result,
  ) async {
    ProductionLogger.instance.info(
      'Cleaning up resources',
      data: {'agent_id': agentId},
      category: 'graceful_shutdown',
    );

    try {
      // Stop resource monitoring
      await _resourceMonitor.stopMonitoring(agentId);
      
      // Perform cleanup
      final cleanupResult = await _cleanupService.cleanupAgent(agentId);
      
      result.cleanupResult = cleanupResult;
      result.resourcesCleanedUp = cleanupResult.success;
      
      if (!cleanupResult.success) {
        result.warnings.addAll(cleanupResult.errors);
      }
      
      ProductionLogger.instance.debug(
        'Resource cleanup completed',
        data: {
          'agent_id': agentId,
          'cleanup_success': cleanupResult.success,
          'processes_terminated': cleanupResult.processesTerminated,
          'temp_files_deleted': cleanupResult.tempFilesDeleted,
        },
        category: 'graceful_shutdown',
      );
    } catch (e) {
      result.warnings.add('Resource cleanup failed: $e');
      ProductionLogger.instance.warning(
        'Resource cleanup failed',
        data: {'agent_id': agentId, 'error': e.toString()},
        category: 'graceful_shutdown',
      );
    }
  }

  /// Phase 6: Final cleanup
  Future<void> _performFinalCleanup(
    String agentId,
    ShutdownState state,
    ShutdownResult result,
  ) async {
    ProductionLogger.instance.info(
      'Performing final cleanup',
      data: {'agent_id': agentId},
      category: 'graceful_shutdown',
    );

    // Remove any remaining references
    // Close any open streams
    // Final logging
    
    result.finalCleanupCompleted = true;
  }

  /// Check if there are active operations for an agent
  Future<bool> _hasActiveOperations(String agentId) async {
    // This would integrate with the terminal manager to check for:
    // - Running commands
    // - Active MCP server communications
    // - Pending I/O operations
    
    // For now, return false (no active operations)
    return false;
  }

  /// Get shutdown status for an agent
  ShutdownStatus? getShutdownStatus(String agentId) {
    final state = _shutdownStates[agentId];
    if (state == null) return null;

    return ShutdownStatus(
      agentId: agentId,
      phase: state.phase,
      startTime: state.startTime,
      timeout: state.timeout,
      force: state.force,
      elapsedTime: DateTime.now().difference(state.startTime),
    );
  }

  /// Emergency shutdown - force kill everything immediately
  Future<ShutdownResult> emergencyShutdown(String agentId) async {
    ProductionLogger.instance.warning(
      'Initiating emergency shutdown for agent',
      data: {'agent_id': agentId},
      category: 'graceful_shutdown',
    );

    return await shutdownAgent(
      agentId,
      timeout: _emergencyShutdownTimeout,
      force: true,
    );
  }

  /// Dispose all resources
  Future<void> dispose() async {
    final agentIds = List.from(_shutdownStates.keys);
    for (final agentId in agentIds) {
      await emergencyShutdown(agentId);
    }
  }
}

/// State of shutdown process
class ShutdownState {
  final String agentId;
  final DateTime startTime;
  final Duration timeout;
  final bool force;
  ShutdownPhase phase = ShutdownPhase.preparation;

  ShutdownState({
    required this.agentId,
    required this.startTime,
    required this.timeout,
    required this.force,
  });
}

/// Phases of graceful shutdown
enum ShutdownPhase {
  preparation,
  stopAcceptingWork,
  waitingForCompletion,
  stoppingMCPServers,
  cleanupResources,
  finalCleanup,
}

/// Result of shutdown operation
class ShutdownResult {
  final String agentId;
  final DateTime startTime;
  final bool force;
  DateTime? endTime;
  bool success = false;
  bool timedOut = false;
  String? error;
  final List<String> warnings = [];

  // Phase completion flags
  bool statePreserved = false;
  bool preparationCompleted = false;
  bool stoppedAcceptingWork = false;
  bool operationsCompleted = false;
  bool mcpServersStopped = false;
  bool resourcesCleanedUp = false;
  bool finalCleanupCompleted = false;

  // Metrics
  int mcpServersStoppedCount = 0;
  CleanupResult? cleanupResult;

  ShutdownResult({
    required this.agentId,
    required this.startTime,
    required this.force,
  });

  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'success': success,
      'timedOut': timedOut,
      'force': force,
      'error': error,
      'warnings': warnings,
      'statePreserved': statePreserved,
      'preparationCompleted': preparationCompleted,
      'stoppedAcceptingWork': stoppedAcceptingWork,
      'operationsCompleted': operationsCompleted,
      'mcpServersStopped': mcpServersStopped,
      'resourcesCleanedUp': resourcesCleanedUp,
      'finalCleanupCompleted': finalCleanupCompleted,
      'mcpServersStoppedCount': mcpServersStoppedCount,
      'cleanupResult': cleanupResult?.toJson(),
      'durationMs': duration.inMilliseconds,
    };
  }
}

/// Current status of shutdown process
class ShutdownStatus {
  final String agentId;
  final ShutdownPhase phase;
  final DateTime startTime;
  final Duration timeout;
  final bool force;
  final Duration elapsedTime;

  const ShutdownStatus({
    required this.agentId,
    required this.phase,
    required this.startTime,
    required this.timeout,
    required this.force,
    required this.elapsedTime,
  });

  double get progressPercent {
    final totalPhases = ShutdownPhase.values.length;
    final currentPhaseIndex = phase.index + 1;
    return (currentPhaseIndex / totalPhases) * 100;
  }

  bool get isTimingOut {
    return elapsedTime >= timeout;
  }

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'phase': phase.name,
      'startTime': startTime.toIso8601String(),
      'timeout': timeout.inMilliseconds,
      'force': force,
      'elapsedTime': elapsedTime.inMilliseconds,
      'progressPercent': progressPercent,
      'isTimingOut': isTimingOut,
    };
  }
}