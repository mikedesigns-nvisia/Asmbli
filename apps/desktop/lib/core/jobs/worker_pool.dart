import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'job_queue.dart';

/// Worker pool configuration
class WorkerPoolConfig {
  final int minWorkers;
  final int maxWorkers;
  final Duration workerIdleTimeout;
  final Duration healthCheckInterval;
  final Duration workerStartupTimeout;
  final bool enableAutoScaling;
  final double targetCpuUtilization;

  const WorkerPoolConfig({
    this.minWorkers = 2,
    this.maxWorkers = 8,
    this.workerIdleTimeout = const Duration(minutes: 5),
    this.healthCheckInterval = const Duration(seconds: 30),
    this.workerStartupTimeout = const Duration(seconds: 10),
    this.enableAutoScaling = true,
    this.targetCpuUtilization = 0.7,
  });
}

/// Worker status enumeration
enum WorkerStatus {
  starting,
  idle,
  busy,
  stopping,
  crashed,
  stopped,
}

/// Individual worker information
class WorkerInfo {
  final String id;
  final Isolate isolate;
  final SendPort sendPort;
  final ReceivePort receivePort;
  WorkerStatus status;
  DateTime lastActivity;
  String? currentJobId;
  int jobsProcessed;
  int jobsFailed;
  Duration totalProcessingTime;

  WorkerInfo({
    required this.id,
    required this.isolate,
    required this.sendPort,
    required this.receivePort,
    this.status = WorkerStatus.starting,
    DateTime? lastActivity,
    this.currentJobId,
    this.jobsProcessed = 0,
    this.jobsFailed = 0,
    this.totalProcessingTime = Duration.zero,
  }) : lastActivity = lastActivity ?? DateTime.now();

  WorkerInfo copyWith({
    WorkerStatus? status,
    DateTime? lastActivity,
    String? currentJobId,
    int? jobsProcessed,
    int? jobsFailed,
    Duration? totalProcessingTime,
  }) {
    return WorkerInfo(
      id: id,
      isolate: isolate,
      sendPort: sendPort,
      receivePort: receivePort,
      status: status ?? this.status,
      lastActivity: lastActivity ?? this.lastActivity,
      currentJobId: currentJobId,
      jobsProcessed: jobsProcessed ?? this.jobsProcessed,
      jobsFailed: jobsFailed ?? this.jobsFailed,
      totalProcessingTime: totalProcessingTime ?? this.totalProcessingTime,
    );
  }

  bool get isIdle => status == WorkerStatus.idle;
  bool get isBusy => status == WorkerStatus.busy;
  bool get isHealthy => status == WorkerStatus.idle || status == WorkerStatus.busy;
  
  Duration get idleTime => DateTime.now().difference(lastActivity);
  
  double get successRate {
    final total = jobsProcessed + jobsFailed;
    return total > 0 ? jobsProcessed / total : 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status.name,
      'last_activity': lastActivity.toIso8601String(),
      'current_job_id': currentJobId,
      'jobs_processed': jobsProcessed,
      'jobs_failed': jobsFailed,
      'total_processing_time_ms': totalProcessingTime.inMilliseconds,
      'success_rate': successRate,
      'idle_time_seconds': idleTime.inSeconds,
    };
  }
}

/// Worker pool manager with auto-scaling and health monitoring
class WorkerPool {
  final WorkerPoolConfig config;
  final Map<String, WorkerInfo> _workers = {};
  final Map<String, QueuedJob> _assignedJobs = {};
  
  // Event streams
  final StreamController<WorkerPoolEvent> _eventController = StreamController.broadcast();
  
  // Timers
  Timer? _healthCheckTimer;
  Timer? _scalingTimer;
  Timer? _cleanupTimer;
  
  // Scaling metrics
  final List<double> _utilizationHistory = [];
  DateTime _lastScaleAction = DateTime.now();
  
  // Statistics
  int _totalWorkersCreated = 0;
  int _totalWorkersDestroyed = 0;

  WorkerPool({required this.config}) {
    
    _healthCheckTimer = Timer.periodic(config.healthCheckInterval, (_) => _performHealthCheck());
    
    if (config.enableAutoScaling) {
      _scalingTimer = Timer.periodic(const Duration(seconds: 30), (_) => _evaluateScaling());
    }
    
    _cleanupTimer = Timer.periodic(const Duration(minutes: 1), (_) => _cleanupIdleWorkers());
  }

  /// Event stream
  Stream<WorkerPoolEvent> get onEvent => _eventController.stream;

  /// Start the worker pool
  Future<void> start() async {
    
    // Create minimum number of workers
    final futures = <Future<void>>[];
    for (int i = 0; i < config.minWorkers; i++) {
      futures.add(_createWorker());
    }
    
    await Future.wait(futures);
  }

  /// Submit job to worker pool
  Future<WorkerInfo?> assignJob(QueuedJob job) async {
    final availableWorker = _getAvailableWorker();
    
    if (availableWorker == null) {
      // Try to scale up if possible
      if (_canScaleUp()) {
        await _createWorker();
        return await assignJob(job); // Retry
      }
      return null; // No workers available
    }
    
    // Assign job to worker
    await _assignJobToWorker(availableWorker, job);
    return availableWorker;
  }

  /// Get worker pool statistics
  WorkerPoolStatistics getStatistics() {
    final activeWorkers = _workers.values.where((w) => w.isHealthy).length;
    final busyWorkers = _workers.values.where((w) => w.isBusy).length;
    final idleWorkers = _workers.values.where((w) => w.isIdle).length;
    final crashedWorkers = _workers.values.where((w) => w.status == WorkerStatus.crashed).length;
    
    final totalJobsProcessed = _workers.values.fold<int>(0, (sum, w) => sum + w.jobsProcessed);
    final totalJobsFailed = _workers.values.fold<int>(0, (sum, w) => sum + w.jobsFailed);
    
    final avgProcessingTime = _workers.values.isNotEmpty
        ? _workers.values.fold<Duration>(Duration.zero, (sum, w) => sum + w.totalProcessingTime) ~/ _workers.length
        : Duration.zero;
    
    return WorkerPoolStatistics(
      totalWorkers: _workers.length,
      activeWorkers: activeWorkers,
      busyWorkers: busyWorkers,
      idleWorkers: idleWorkers,
      crashedWorkers: crashedWorkers,
      assignedJobs: _assignedJobs.length,
      totalJobsProcessed: totalJobsProcessed,
      totalJobsFailed: totalJobsFailed,
      totalWorkersCreated: _totalWorkersCreated,
      totalWorkersDestroyed: _totalWorkersDestroyed,
      averageProcessingTime: avgProcessingTime,
      utilization: _workers.isNotEmpty ? busyWorkers / _workers.length : 0.0,
      config: config,
    );
  }

  /// Get available worker
  WorkerInfo? _getAvailableWorker() {
    final idleWorkers = _workers.values.where((w) => w.isIdle).toList();
    
    if (idleWorkers.isEmpty) return null;
    
    // Return worker with best performance (highest success rate, recent activity)
    idleWorkers.sort((a, b) {
      final aScore = a.successRate - (a.idleTime.inSeconds / 3600.0); // Penalize long idle times
      final bScore = b.successRate - (b.idleTime.inSeconds / 3600.0);
      return bScore.compareTo(aScore);
    });
    
    return idleWorkers.first;
  }

  /// Assign job to specific worker
  Future<void> _assignJobToWorker(WorkerInfo worker, QueuedJob job) async {
    try {
      // Update worker state
      final updatedWorker = worker.copyWith(
        status: WorkerStatus.busy,
        currentJobId: job.job.id,
        lastActivity: DateTime.now(),
      );
      _workers[worker.id] = updatedWorker;
      
      // Track job assignment
      _assignedJobs[job.job.id] = job;
      
      // Send job to worker
      worker.sendPort.send({
        'type': 'execute_job',
        'job': job.toJson(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      _eventController.add(WorkerPoolEvent.jobAssigned(updatedWorker, job));
      
    } catch (e) {
      debugPrint('Failed to assign job to worker ${worker.id}: $e');
      _eventController.add(WorkerPoolEvent.workerError(worker, e.toString()));
    }
  }

  /// Create new worker isolate
  Future<void> _createWorker() async {
    final workerId = 'worker_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
    
    try {
      
      final receivePort = ReceivePort();
      final isolate = await Isolate.spawn(
        _workerEntryPoint,
        {
          'send_port': receivePort.sendPort,
          'worker_id': workerId,
        },
        debugName: workerId,
      ).timeout(config.workerStartupTimeout);
      
      // Wait for worker to send its SendPort
      final Completer<SendPort> sendPortCompleter = Completer();
      StreamSubscription? subscription;
      
      subscription = receivePort.listen((message) {
        if (message is Map && message['type'] == 'worker_ready') {
          if (!sendPortCompleter.isCompleted) {
            sendPortCompleter.complete(message['send_port'] as SendPort);
          }
        } else {
          _handleWorkerMessage(workerId, message);
        }
      });
      
      final sendPort = await sendPortCompleter.future.timeout(config.workerStartupTimeout);
      
      // Create worker info
      final workerInfo = WorkerInfo(
        id: workerId,
        isolate: isolate,
        sendPort: sendPort,
        receivePort: receivePort,
        status: WorkerStatus.idle,
      );
      
      _workers[workerId] = workerInfo;
      _totalWorkersCreated++;
      
      _eventController.add(WorkerPoolEvent.workerCreated(workerInfo));
      
    } catch (e) {
      debugPrint('Failed to create worker $workerId: $e');
      _eventController.add(WorkerPoolEvent.workerCreationFailed(workerId, e.toString()));
    }
  }

  /// Handle message from worker
  void _handleWorkerMessage(String workerId, dynamic message) {
    final worker = _workers[workerId];
    if (worker == null) return;
    
    try {
      final msg = message as Map<String, dynamic>;
      final type = msg['type'] as String;
      
      switch (type) {
        case 'job_completed':
          _handleJobCompleted(worker, msg);
          break;
        case 'job_failed':
          _handleJobFailed(worker, msg);
          break;
        case 'worker_error':
          _handleWorkerError(worker, msg['error'] as String);
          break;
        case 'heartbeat':
          _updateWorkerActivity(worker);
          break;
      }
    } catch (e) {
      debugPrint('Invalid message from worker $workerId: $e');
    }
  }

  /// Handle job completion from worker
  void _handleJobCompleted(WorkerInfo worker, Map<String, dynamic> message) {
    final jobId = message['job_id'] as String;
    final executionTime = Duration(milliseconds: message['execution_time_ms'] as int);
    final result = message['result'];
    
    // Update worker state
    final updatedWorker = worker.copyWith(
      status: WorkerStatus.idle,
      currentJobId: null,
      jobsProcessed: worker.jobsProcessed + 1,
      totalProcessingTime: worker.totalProcessingTime + executionTime,
      lastActivity: DateTime.now(),
    );
    _workers[worker.id] = updatedWorker;
    
    // Clean up job assignment
    final job = _assignedJobs.remove(jobId);
    
    _eventController.add(WorkerPoolEvent.jobCompleted(updatedWorker, jobId, result));
  }

  /// Handle job failure from worker
  void _handleJobFailed(WorkerInfo worker, Map<String, dynamic> message) {
    final jobId = message['job_id'] as String;
    final error = message['error'] as String;
    final executionTime = Duration(milliseconds: message['execution_time_ms'] as int? ?? 0);
    
    // Update worker state
    final updatedWorker = worker.copyWith(
      status: WorkerStatus.idle,
      currentJobId: null,
      jobsFailed: worker.jobsFailed + 1,
      totalProcessingTime: worker.totalProcessingTime + executionTime,
      lastActivity: DateTime.now(),
    );
    _workers[worker.id] = updatedWorker;
    
    // Clean up job assignment
    final job = _assignedJobs.remove(jobId);
    
    _eventController.add(WorkerPoolEvent.jobFailed(updatedWorker, jobId, error));
    debugPrint('Job $jobId failed in worker ${worker.id}: $error');
  }

  /// Handle worker error
  void _handleWorkerError(WorkerInfo worker, String error) {
    debugPrint('Worker ${worker.id} error: $error');
    
    final updatedWorker = worker.copyWith(status: WorkerStatus.crashed);
    _workers[worker.id] = updatedWorker;
    
    _eventController.add(WorkerPoolEvent.workerError(updatedWorker, error));
    
    // If worker was processing a job, mark it for retry
    if (worker.currentJobId != null) {
      final job = _assignedJobs.remove(worker.currentJobId!);
      if (job != null) {
        _eventController.add(WorkerPoolEvent.jobInterrupted(worker, job));
      }
    }
  }

  /// Update worker activity timestamp
  void _updateWorkerActivity(WorkerInfo worker) {
    final updatedWorker = worker.copyWith(lastActivity: DateTime.now());
    _workers[worker.id] = updatedWorker;
  }

  /// Perform health check on all workers
  Future<void> _performHealthCheck() async {
    final unhealthyWorkers = <WorkerInfo>[];
    
    for (final worker in _workers.values) {
      // Check if worker is responsive
      final timeSinceActivity = DateTime.now().difference(worker.lastActivity);
      
      if (timeSinceActivity > const Duration(minutes: 2) && worker.status == WorkerStatus.busy) {
        debugPrint('Worker ${worker.id} appears unresponsive');
        unhealthyWorkers.add(worker);
      }
    }
    
    // Restart unhealthy workers
    for (final worker in unhealthyWorkers) {
      await _restartWorker(worker);
    }
    
    if (unhealthyWorkers.isNotEmpty) {
      _eventController.add(WorkerPoolEvent.healthCheckCompleted(unhealthyWorkers.length));
    }
  }

  /// Restart an unhealthy worker
  Future<void> _restartWorker(WorkerInfo worker) async {
    
    try {
      // Kill the isolate
      worker.isolate.kill();
      worker.receivePort.close();
      
      // Mark any assigned job for retry
      if (worker.currentJobId != null) {
        final job = _assignedJobs.remove(worker.currentJobId!);
        if (job != null) {
          _eventController.add(WorkerPoolEvent.jobInterrupted(worker, job));
        }
      }
      
      // Remove worker
      _workers.remove(worker.id);
      _totalWorkersDestroyed++;
      
      // Create replacement if needed
      if (_workers.length < config.minWorkers) {
        await _createWorker();
      }
      
      _eventController.add(WorkerPoolEvent.workerRestarted(worker));
      
    } catch (e) {
      debugPrint('Failed to restart worker ${worker.id}: $e');
    }
  }

  /// Evaluate if scaling is needed
  void _evaluateScaling() {
    final stats = getStatistics();
    final utilization = stats.utilization;
    
    // Track utilization history
    _utilizationHistory.add(utilization);
    if (_utilizationHistory.length > 10) {
      _utilizationHistory.removeAt(0);
    }
    
    final avgUtilization = _utilizationHistory.reduce((a, b) => a + b) / _utilizationHistory.length;
    final timeSinceLastScale = DateTime.now().difference(_lastScaleAction);
    
    // Scale up if high utilization
    if (avgUtilization > config.targetCpuUtilization && _canScaleUp() && timeSinceLastScale.inMinutes > 2) {
      _createWorker();
      _lastScaleAction = DateTime.now();
    }
    // Scale down if low utilization
    else if (avgUtilization < config.targetCpuUtilization * 0.3 && _canScaleDown() && timeSinceLastScale.inMinutes > 5) {
      _removeIdleWorker();
      _lastScaleAction = DateTime.now();
    }
  }

  /// Check if we can scale up
  bool _canScaleUp() {
    return _workers.length < config.maxWorkers;
  }

  /// Check if we can scale down
  bool _canScaleDown() {
    return _workers.length > config.minWorkers;
  }

  /// Remove an idle worker
  void _removeIdleWorker() {
    final idleWorkers = _workers.values.where((w) => w.isIdle).toList();
    
    if (idleWorkers.isNotEmpty) {
      // Remove the worker that has been idle longest
      idleWorkers.sort((a, b) => b.idleTime.compareTo(a.idleTime));
      final workerToRemove = idleWorkers.first;
      
      _destroyWorker(workerToRemove);
    }
  }

  /// Cleanup idle workers that have exceeded timeout
  void _cleanupIdleWorkers() {
    final now = DateTime.now();
    final workersToRemove = <WorkerInfo>[];
    
    for (final worker in _workers.values) {
      if (worker.isIdle && 
          now.difference(worker.lastActivity) > config.workerIdleTimeout &&
          _workers.length > config.minWorkers) {
        workersToRemove.add(worker);
      }
    }
    
    for (final worker in workersToRemove) {
      _destroyWorker(worker);
    }
  }

  /// Destroy a worker
  void _destroyWorker(WorkerInfo worker) {
    try {
      worker.isolate.kill();
      worker.receivePort.close();
      _workers.remove(worker.id);
      _totalWorkersDestroyed++;
      
      _eventController.add(WorkerPoolEvent.workerDestroyed(worker));
      
    } catch (e) {
      debugPrint('Error destroying worker ${worker.id}: $e');
    }
  }

  /// Stop the worker pool
  Future<void> stop() async {
    
    _healthCheckTimer?.cancel();
    _scalingTimer?.cancel();
    _cleanupTimer?.cancel();
    
    // Stop all workers
    final futures = _workers.values.map((worker) async {
      try {
        worker.sendPort.send({'type': 'shutdown'});
        await Future.delayed(const Duration(seconds: 2));
        worker.isolate.kill();
        worker.receivePort.close();
      } catch (e) {
      }
    });
    
    await Future.wait(futures);
    
    _workers.clear();
    _assignedJobs.clear();
    
    await _eventController.close();
  }

  /// Worker isolate entry point
  static void _workerEntryPoint(Map<String, dynamic> args) {
    final sendPort = args['send_port'] as SendPort;
    final workerId = args['worker_id'] as String;
    
    final receivePort = ReceivePort();
    
    // Send ready signal with our SendPort
    sendPort.send({
      'type': 'worker_ready',
      'send_port': receivePort.sendPort,
      'worker_id': workerId,
    });
    
    // Send periodic heartbeats
    Timer.periodic(const Duration(seconds: 30), (_) {
      sendPort.send({
        'type': 'heartbeat',
        'worker_id': workerId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    });
    
    // Listen for jobs
    receivePort.listen((message) async {
      try {
        final msg = message as Map<String, dynamic>;
        final type = msg['type'] as String;
        
        switch (type) {
          case 'execute_job':
            await _executeJobInWorker(sendPort, workerId, msg['job'] as Map<String, dynamic>);
            break;
          case 'shutdown':
            receivePort.close();
            Isolate.exit();
            break;
        }
      } catch (e, stackTrace) {
        sendPort.send({
          'type': 'worker_error',
          'worker_id': workerId,
          'error': e.toString(),
          'stack_trace': stackTrace.toString(),
        });
      }
    });
  }

  /// Execute job in worker isolate
  static Future<void> _executeJobInWorker(SendPort sendPort, String workerId, Map<String, dynamic> jobData) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final queuedJob = QueuedJob.fromJson(jobData);
      final result = await queuedJob.job.execute();
      
      stopwatch.stop();
      
      sendPort.send({
        'type': result.success ? 'job_completed' : 'job_failed',
        'worker_id': workerId,
        'job_id': queuedJob.job.id,
        'result': result.result,
        'error': result.error,
        'execution_time_ms': stopwatch.elapsedMilliseconds,
      });
      
    } catch (e, stackTrace) {
      stopwatch.stop();
      
      sendPort.send({
        'type': 'job_failed',
        'worker_id': workerId,
        'job_id': jobData['job']?['id'] ?? 'unknown',
        'error': e.toString(),
        'execution_time_ms': stopwatch.elapsedMilliseconds,
        'stack_trace': stackTrace.toString(),
      });
    }
  }
}

/// Worker pool events
abstract class WorkerPoolEvent {
  final DateTime timestamp;
  
  // Generative constructor for subclasses
  WorkerPoolEvent() : timestamp = DateTime.now();
  
  factory WorkerPoolEvent.workerCreated(WorkerInfo worker) = WorkerCreatedEvent;
  factory WorkerPoolEvent.workerDestroyed(WorkerInfo worker) = WorkerDestroyedEvent;
  factory WorkerPoolEvent.workerRestarted(WorkerInfo worker) = WorkerRestartedEvent;
  factory WorkerPoolEvent.workerError(WorkerInfo worker, String error) = WorkerErrorEvent;
  factory WorkerPoolEvent.workerCreationFailed(String workerId, String error) = WorkerCreationFailedEvent;
  factory WorkerPoolEvent.jobAssigned(WorkerInfo worker, QueuedJob job) = JobAssignedEvent;
  factory WorkerPoolEvent.jobCompleted(WorkerInfo worker, String jobId, dynamic result) = JobCompletedEvent;
  factory WorkerPoolEvent.jobFailed(WorkerInfo worker, String jobId, String error) = JobFailedEvent;
  factory WorkerPoolEvent.jobInterrupted(WorkerInfo worker, QueuedJob job) = JobInterruptedEvent;
  factory WorkerPoolEvent.healthCheckCompleted(int unhealthyWorkers) = HealthCheckCompletedEvent;
}

class WorkerCreatedEvent extends WorkerPoolEvent {
  final WorkerInfo worker;
  WorkerCreatedEvent(this.worker) : super();
}

class WorkerDestroyedEvent extends WorkerPoolEvent {
  final WorkerInfo worker;
  WorkerDestroyedEvent(this.worker) : super();
}

class WorkerRestartedEvent extends WorkerPoolEvent {
  final WorkerInfo worker;
  WorkerRestartedEvent(this.worker) : super();
}

class WorkerErrorEvent extends WorkerPoolEvent {
  final WorkerInfo worker;
  final String error;
  WorkerErrorEvent(this.worker, this.error) : super();
}

class WorkerCreationFailedEvent extends WorkerPoolEvent {
  final String workerId;
  final String error;
  WorkerCreationFailedEvent(this.workerId, this.error) : super();
}

class JobAssignedEvent extends WorkerPoolEvent {
  final WorkerInfo worker;
  final QueuedJob job;
  JobAssignedEvent(this.worker, this.job) : super();
}

class JobCompletedEvent extends WorkerPoolEvent {
  final WorkerInfo worker;
  final String jobId;
  final dynamic result;
  JobCompletedEvent(this.worker, this.jobId, this.result) : super();
}

class JobFailedEvent extends WorkerPoolEvent {
  final WorkerInfo worker;
  final String jobId;
  final String error;
  JobFailedEvent(this.worker, this.jobId, this.error) : super();
}

class JobInterruptedEvent extends WorkerPoolEvent {
  final WorkerInfo worker;
  final QueuedJob job;
  JobInterruptedEvent(this.worker, this.job) : super();
}

class HealthCheckCompletedEvent extends WorkerPoolEvent {
  final int unhealthyWorkers;
  HealthCheckCompletedEvent(this.unhealthyWorkers) : super();
}

/// Worker pool statistics
class WorkerPoolStatistics {
  final int totalWorkers;
  final int activeWorkers;
  final int busyWorkers;
  final int idleWorkers;
  final int crashedWorkers;
  final int assignedJobs;
  final int totalJobsProcessed;
  final int totalJobsFailed;
  final int totalWorkersCreated;
  final int totalWorkersDestroyed;
  final Duration averageProcessingTime;
  final double utilization;
  final WorkerPoolConfig config;

  const WorkerPoolStatistics({
    required this.totalWorkers,
    required this.activeWorkers,
    required this.busyWorkers,
    required this.idleWorkers,
    required this.crashedWorkers,
    required this.assignedJobs,
    required this.totalJobsProcessed,
    required this.totalJobsFailed,
    required this.totalWorkersCreated,
    required this.totalWorkersDestroyed,
    required this.averageProcessingTime,
    required this.utilization,
    required this.config,
  });

  double get successRate {
    final total = totalJobsProcessed + totalJobsFailed;
    return total > 0 ? totalJobsProcessed / total : 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'total_workers': totalWorkers,
      'active_workers': activeWorkers,
      'busy_workers': busyWorkers,
      'idle_workers': idleWorkers,
      'crashed_workers': crashedWorkers,
      'assigned_jobs': assignedJobs,
      'total_jobs_processed': totalJobsProcessed,
      'total_jobs_failed': totalJobsFailed,
      'total_workers_created': totalWorkersCreated,
      'total_workers_destroyed': totalWorkersDestroyed,
      'success_rate': successRate,
      'utilization': utilization,
      'average_processing_time_ms': averageProcessingTime.inMilliseconds,
      'config': {
        'min_workers': config.minWorkers,
        'max_workers': config.maxWorkers,
        'enable_auto_scaling': config.enableAutoScaling,
        'target_cpu_utilization': config.targetCpuUtilization,
      },
    };
  }

  @override
  String toString() {
    return 'WorkerPoolStats(workers: $totalWorkers, utilization: ${(utilization * 100).toStringAsFixed(1)}%, success: ${(successRate * 100).toStringAsFixed(1)}%)';
  }
}