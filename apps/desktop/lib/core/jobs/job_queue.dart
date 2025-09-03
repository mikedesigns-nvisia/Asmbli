import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import '../cache/file_cache.dart';

/// Priority levels for jobs
enum JobPriority {
  low(0),
  normal(1),
  high(2),
  critical(3);

  const JobPriority(this.value);
  final int value;
}

/// Job status enumeration
enum JobStatus {
  pending,
  running,
  completed,
  failed,
  cancelled,
  retrying,
}

/// Base job interface
abstract class Job {
  String get id;
  String get type;
  JobPriority get priority;
  Map<String, dynamic> get data;
  int get maxRetries;
  Duration get timeout;
  
  /// Execute the job
  Future<JobResult> execute();
  
  /// Serialize job for persistence
  Map<String, dynamic> toJson();
  
  /// Create job from JSON
  factory Job.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'document_processing':
        return DocumentProcessingJob.fromJson(json);
      case 'model_embedding':
        return ModelEmbeddingJob.fromJson(json);
      case 'file_indexing':
        return FileIndexingJob.fromJson(json);
      default:
        throw UnimplementedError('Job type ${json['type']} not implemented');
    }
  }
}

/// Job execution result
class JobResult {
  final String jobId;
  final bool success;
  final dynamic result;
  final String? error;
  final Duration executionTime;
  final Map<String, dynamic> metadata;

  JobResult({
    required this.jobId,
    required this.success,
    this.result,
    this.error,
    required this.executionTime,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'job_id': jobId,
      'success': success,
      'result': result,
      'error': error,
      'execution_time_ms': executionTime.inMilliseconds,
      'metadata': metadata,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  factory JobResult.fromJson(Map<String, dynamic> json) {
    return JobResult(
      jobId: json['job_id'],
      success: json['success'],
      result: json['result'],
      error: json['error'],
      executionTime: Duration(milliseconds: json['execution_time_ms']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

/// Job queue entry with metadata
class QueuedJob {
  final Job job;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final int attemptCount;
  final List<String> errorHistory;
  JobStatus status;

  QueuedJob({
    required this.job,
    required this.createdAt,
    this.scheduledAt,
    this.attemptCount = 0,
    this.errorHistory = const [],
    this.status = JobStatus.pending,
  });

  bool get canRetry => attemptCount < job.maxRetries;
  bool get isScheduled => scheduledAt != null && DateTime.now().isBefore(scheduledAt!);
  
  QueuedJob copyWith({
    JobStatus? status,
    int? attemptCount,
    List<String>? errorHistory,
    DateTime? scheduledAt,
  }) {
    return QueuedJob(
      job: job,
      createdAt: createdAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      attemptCount: attemptCount ?? this.attemptCount,
      errorHistory: errorHistory ?? this.errorHistory,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job': job.toJson(),
      'created_at': createdAt.toIso8601String(),
      'scheduled_at': scheduledAt?.toIso8601String(),
      'attempt_count': attemptCount,
      'error_history': errorHistory,
      'status': status.name,
    };
  }

  factory QueuedJob.fromJson(Map<String, dynamic> json) {
    return QueuedJob(
      job: Job.fromJson(json['job']),
      createdAt: DateTime.parse(json['created_at']),
      scheduledAt: json['scheduled_at'] != null 
          ? DateTime.parse(json['scheduled_at']) 
          : null,
      attemptCount: json['attempt_count'] ?? 0,
      errorHistory: List<String>.from(json['error_history'] ?? []),
      status: JobStatus.values.byName(json['status'] ?? 'pending'),
    );
  }
}

/// Background job queue with priority support and persistence
class JobQueue {
  final List<QueuedJob> _queue = [];
  final Map<String, QueuedJob> _activeJobs = {};
  final Map<String, JobResult> _completedJobs = {};
  final FileCache _persistenceCache;
  
  // Configuration
  final int maxConcurrentJobs;
  final Duration defaultRetryDelay;
  final bool enablePersistence;
  
  // Event streams
  final StreamController<QueuedJob> _jobStartedController = StreamController.broadcast();
  final StreamController<JobResult> _jobCompletedController = StreamController.broadcast();
  final StreamController<QueueEvent> _queueEventController = StreamController.broadcast();
  
  // Timers and cleanup
  Timer? _processingTimer;
  Timer? _persistenceTimer;
  Timer? _cleanupTimer;
  
  // Statistics
  int _totalJobsProcessed = 0;
  int _totalJobsFailed = 0;
  final Map<String, int> _jobTypeStats = {};

  JobQueue({
    required this.maxConcurrentJobs,
    required FileCache persistenceCache,
    this.defaultRetryDelay = const Duration(seconds: 30),
    this.enablePersistence = true,
    Duration processingInterval = const Duration(seconds: 1),
    Duration persistenceInterval = const Duration(minutes: 1),
    Duration cleanupInterval = const Duration(minutes: 10),
  }) : _persistenceCache = persistenceCache {
    
    // Start processing timer
    _processingTimer = Timer.periodic(processingInterval, (_) => _processQueue());
    
    if (enablePersistence) {
      // Start persistence timer
      _persistenceTimer = Timer.periodic(persistenceInterval, (_) => _persistQueue());
      
      // Load persisted jobs on startup
      _loadPersistedJobs();
    }
    
    // Start cleanup timer
    _cleanupTimer = Timer.periodic(cleanupInterval, (_) => _cleanupCompletedJobs());
    
    print('📋 Job queue initialized (maxConcurrent: $maxConcurrentJobs)');
  }

  /// Event streams
  Stream<QueuedJob> get onJobStarted => _jobStartedController.stream;
  Stream<JobResult> get onJobCompleted => _jobCompletedController.stream;
  Stream<QueueEvent> get onQueueEvent => _queueEventController.stream;

  /// Add job to queue
  Future<String> addJob(Job job, {DateTime? scheduledAt}) async {
    final queuedJob = QueuedJob(
      job: job,
      createdAt: DateTime.now(),
      scheduledAt: scheduledAt,
    );
    
    // Insert job in priority order
    _insertJobByPriority(queuedJob);
    
    // Emit event
    _queueEventController.add(QueueEvent.jobAdded(queuedJob));
    
    print('➕ Added job: ${job.id} (${job.type}, priority: ${job.priority.name})');
    
    if (enablePersistence) {
      await _persistQueue();
    }
    
    return job.id;
  }

  /// Cancel job
  Future<bool> cancelJob(String jobId) async {
    // Check if job is in queue
    final queueIndex = _queue.indexWhere((q) => q.job.id == jobId);
    if (queueIndex >= 0) {
      final queuedJob = _queue.removeAt(queueIndex);
      final cancelledJob = queuedJob.copyWith(status: JobStatus.cancelled);
      
      _queueEventController.add(QueueEvent.jobCancelled(cancelledJob));
      print('❌ Cancelled queued job: $jobId');
      
      if (enablePersistence) {
        await _persistQueue();
      }
      
      return true;
    }
    
    // Check if job is currently running
    final activeJob = _activeJobs[jobId];
    if (activeJob != null) {
      activeJob.status = JobStatus.cancelled;
      _queueEventController.add(QueueEvent.jobCancelled(activeJob));
      print('❌ Marked running job for cancellation: $jobId');
      return true;
    }
    
    return false;
  }

  /// Get job status
  JobStatus? getJobStatus(String jobId) {
    // Check active jobs
    final activeJob = _activeJobs[jobId];
    if (activeJob != null) {
      return activeJob.status;
    }
    
    // Check queued jobs
    for (final queuedJob in _queue) {
      if (queuedJob.job.id == jobId) {
        return queuedJob.status;
      }
    }
    
    // Check completed jobs
    if (_completedJobs.containsKey(jobId)) {
      return JobStatus.completed;
    }
    
    return null;
  }

  /// Get job result
  JobResult? getJobResult(String jobId) {
    return _completedJobs[jobId];
  }

  /// Get queue statistics
  QueueStatistics getStatistics() {
    final pendingJobs = _queue.where((j) => j.status == JobStatus.pending).length;
    final runningJobs = _activeJobs.length;
    final completedJobs = _completedJobs.length;
    final failedJobs = _queue.where((j) => j.status == JobStatus.failed).length;
    
    return QueueStatistics(
      pendingJobs: pendingJobs,
      runningJobs: runningJobs,
      completedJobs: completedJobs,
      failedJobs: failedJobs,
      totalJobsProcessed: _totalJobsProcessed,
      totalJobsFailed: _totalJobsFailed,
      jobTypeStats: Map.from(_jobTypeStats),
      queueSize: _queue.length,
      maxConcurrentJobs: maxConcurrentJobs,
    );
  }

  /// Process the job queue
  Future<void> _processQueue() async {
    if (_activeJobs.length >= maxConcurrentJobs) {
      return; // At capacity
    }
    
    // Find next job to process
    final nextJob = _getNextJob();
    if (nextJob == null) {
      return; // No jobs available
    }
    
    // Move job to active
    _queue.remove(nextJob);
    nextJob.status = JobStatus.running;
    _activeJobs[nextJob.job.id] = nextJob;
    
    _jobStartedController.add(nextJob);
    _queueEventController.add(QueueEvent.jobStarted(nextJob));
    
    print('🚀 Starting job: ${nextJob.job.id} (${nextJob.job.type})');
    
    // Execute job asynchronously
    _executeJob(nextJob);
  }

  /// Get next job to process (considering priority and scheduling)
  QueuedJob? _getNextJob() {
    final now = DateTime.now();
    
    // Find highest priority job that's ready to run
    QueuedJob? bestJob;
    int highestPriority = -1;
    
    for (final queuedJob in _queue) {
      if (queuedJob.status != JobStatus.pending) continue;
      if (queuedJob.isScheduled) continue; // Not ready yet
      
      if (queuedJob.job.priority.value > highestPriority) {
        highestPriority = queuedJob.job.priority.value;
        bestJob = queuedJob;
      }
    }
    
    return bestJob;
  }

  /// Execute a job
  Future<void> _executeJob(QueuedJob queuedJob) async {
    final stopwatch = Stopwatch()..start();
    JobResult result;
    
    try {
      // Execute with timeout
      final jobResult = await queuedJob.job.execute()
          .timeout(queuedJob.job.timeout);
      
      stopwatch.stop();
      
      result = JobResult(
        jobId: queuedJob.job.id,
        success: jobResult.success,
        result: jobResult.result,
        error: jobResult.error,
        executionTime: stopwatch.elapsed,
        metadata: {
          ...jobResult.metadata,
          'attempt_count': queuedJob.attemptCount + 1,
          'job_type': queuedJob.job.type,
        },
      );
      
      if (result.success) {
        print('✅ Job completed: ${queuedJob.job.id} (${stopwatch.elapsed.inMilliseconds}ms)');
        _totalJobsProcessed++;
      } else {
        print('❌ Job failed: ${queuedJob.job.id} - ${result.error}');
        _totalJobsFailed++;
      }
      
    } catch (e, stackTrace) {
      stopwatch.stop();
      
      result = JobResult(
        jobId: queuedJob.job.id,
        success: false,
        error: e.toString(),
        executionTime: stopwatch.elapsed,
        metadata: {
          'attempt_count': queuedJob.attemptCount + 1,
          'job_type': queuedJob.job.type,
          'stack_trace': stackTrace.toString(),
        },
      );
      
      print('💥 Job crashed: ${queuedJob.job.id} - $e');
      _totalJobsFailed++;
    }
    
    // Remove from active jobs
    _activeJobs.remove(queuedJob.job.id);
    
    // Handle result
    if (result.success) {
      // Job completed successfully
      _completedJobs[queuedJob.job.id] = result;
      _updateJobTypeStats(queuedJob.job.type, success: true);
    } else {
      // Job failed - check if we should retry
      final updatedJob = queuedJob.copyWith(
        attemptCount: queuedJob.attemptCount + 1,
        errorHistory: [...queuedJob.errorHistory, result.error ?? 'Unknown error'],
      );
      
      if (updatedJob.canRetry) {
        // Schedule retry
        final retryDelay = _calculateRetryDelay(updatedJob.attemptCount);
        final scheduledAt = DateTime.now().add(retryDelay);
        
        final retryJob = updatedJob.copyWith(
          status: JobStatus.retrying,
          scheduledAt: scheduledAt,
        );
        
        _insertJobByPriority(retryJob);
        
        print('🔄 Scheduled retry for ${queuedJob.job.id} in ${retryDelay.inSeconds}s (attempt ${updatedJob.attemptCount}/${queuedJob.job.maxRetries})');
        
        _queueEventController.add(QueueEvent.jobRetrying(retryJob));
      } else {
        // Max retries reached
        updatedJob.status = JobStatus.failed;
        _completedJobs[queuedJob.job.id] = result;
        _updateJobTypeStats(queuedJob.job.type, success: false);
        
        _queueEventController.add(QueueEvent.jobFailed(updatedJob, result));
      }
    }
    
    // Emit completion event
    _jobCompletedController.add(result);
    
    if (enablePersistence) {
      await _persistQueue();
    }
  }

  /// Insert job in queue maintaining priority order
  void _insertJobByPriority(QueuedJob job) {
    int insertIndex = 0;
    
    for (int i = 0; i < _queue.length; i++) {
      if (_queue[i].job.priority.value < job.job.priority.value) {
        insertIndex = i;
        break;
      }
      insertIndex = i + 1;
    }
    
    _queue.insert(insertIndex, job);
  }

  /// Calculate retry delay with exponential backoff
  Duration _calculateRetryDelay(int attemptCount) {
    final baseDelay = defaultRetryDelay.inMilliseconds;
    final exponentialDelay = baseDelay * pow(2, attemptCount - 1);
    final jitter = Random().nextDouble() * 0.1 * exponentialDelay;
    
    return Duration(milliseconds: (exponentialDelay + jitter).toInt());
  }

  /// Update job type statistics
  void _updateJobTypeStats(String jobType, {required bool success}) {
    final key = success ? '${jobType}_success' : '${jobType}_failure';
    _jobTypeStats[key] = (_jobTypeStats[key] ?? 0) + 1;
  }

  /// Persist queue state to disk
  Future<void> _persistQueue() async {
    if (!enablePersistence) return;
    
    try {
      final queueData = {
        'queue': _queue.map((q) => q.toJson()).toList(),
        'active_jobs': _activeJobs.values.map((q) => q.toJson()).toList(),
        'completed_jobs': _completedJobs.map((k, v) => MapEntry(k, v.toJson())),
        'statistics': {
          'total_processed': _totalJobsProcessed,
          'total_failed': _totalJobsFailed,
          'job_type_stats': _jobTypeStats,
        },
        'persisted_at': DateTime.now().toIso8601String(),
      };
      
      await _persistenceCache.put(
        'job_queue_state',
        queueData,
        ttl: const Duration(days: 7),
      );
    } catch (e) {
      print('⚠️ Failed to persist job queue: $e');
    }
  }

  /// Load persisted queue state
  Future<void> _loadPersistedJobs() async {
    if (!enablePersistence) return;
    
    try {
      final queueData = await _persistenceCache.get<Map<String, dynamic>>('job_queue_state');
      if (queueData == null) return;
      
      // Restore queue
      final queueList = queueData['queue'] as List?;
      if (queueList != null) {
        _queue.clear();
        _queue.addAll(queueList.map((q) => QueuedJob.fromJson(q)));
      }
      
      // Restore completed jobs
      final completedJobs = queueData['completed_jobs'] as Map<String, dynamic>?;
      if (completedJobs != null) {
        _completedJobs.clear();
        completedJobs.forEach((k, v) {
          _completedJobs[k] = JobResult.fromJson(v);
        });
      }
      
      // Restore statistics
      final stats = queueData['statistics'] as Map<String, dynamic>?;
      if (stats != null) {
        _totalJobsProcessed = stats['total_processed'] ?? 0;
        _totalJobsFailed = stats['total_failed'] ?? 0;
        _jobTypeStats.clear();
        final jobTypeStats = stats['job_type_stats'] as Map<String, dynamic>?;
        if (jobTypeStats != null) {
          jobTypeStats.forEach((k, v) => _jobTypeStats[k] = v);
        }
      }
      
      print('💾 Loaded persisted queue state: ${_queue.length} jobs, ${_completedJobs.length} completed');
    } catch (e) {
      print('⚠️ Failed to load persisted job queue: $e');
    }
  }

  /// Cleanup old completed jobs
  Future<void> _cleanupCompletedJobs() async {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 24));
    
    final keysToRemove = <String>[];
    
    for (final entry in _completedJobs.entries) {
      // Parse timestamp from metadata or use old cutoff
      final resultJson = entry.value.toJson();
      final timestamp = resultJson['timestamp'] as String?;
      
      if (timestamp != null) {
        final resultTime = DateTime.parse(timestamp);
        if (resultTime.isBefore(cutoff)) {
          keysToRemove.add(entry.key);
        }
      }
    }
    
    for (final key in keysToRemove) {
      _completedJobs.remove(key);
    }
    
    if (keysToRemove.isNotEmpty) {
      print('🧹 Cleaned up ${keysToRemove.length} old job results');
      
      if (enablePersistence) {
        await _persistQueue();
      }
    }
  }

  /// Dispose of the job queue
  Future<void> dispose() async {
    _processingTimer?.cancel();
    _persistenceTimer?.cancel();
    _cleanupTimer?.cancel();
    
    if (enablePersistence) {
      await _persistQueue();
    }
    
    await _jobStartedController.close();
    await _jobCompletedController.close();
    await _queueEventController.close();
    
    print('🛑 Job queue disposed');
  }
}

/// Queue event types
abstract class QueueEvent {
  final DateTime timestamp = DateTime.now();
  
  factory QueueEvent.jobAdded(QueuedJob job) = JobAddedEvent;
  factory QueueEvent.jobStarted(QueuedJob job) = JobStartedEvent;
  factory QueueEvent.jobCompleted(QueuedJob job, JobResult result) = JobCompletedEvent;
  factory QueueEvent.jobFailed(QueuedJob job, JobResult result) = JobFailedEvent;
  factory QueueEvent.jobCancelled(QueuedJob job) = JobCancelledEvent;
  factory QueueEvent.jobRetrying(QueuedJob job) = JobRetryingEvent;
}

class JobAddedEvent extends QueueEvent {
  final QueuedJob job;
  JobAddedEvent(this.job);
}

class JobStartedEvent extends QueueEvent {
  final QueuedJob job;
  JobStartedEvent(this.job);
}

class JobCompletedEvent extends QueueEvent {
  final QueuedJob job;
  final JobResult result;
  JobCompletedEvent(this.job, this.result);
}

class JobFailedEvent extends QueueEvent {
  final QueuedJob job;
  final JobResult result;
  JobFailedEvent(this.job, this.result);
}

class JobCancelledEvent extends QueueEvent {
  final QueuedJob job;
  JobCancelledEvent(this.job);
}

class JobRetryingEvent extends QueueEvent {
  final QueuedJob job;
  JobRetryingEvent(this.job);
}

/// Queue statistics
class QueueStatistics {
  final int pendingJobs;
  final int runningJobs;
  final int completedJobs;
  final int failedJobs;
  final int totalJobsProcessed;
  final int totalJobsFailed;
  final Map<String, int> jobTypeStats;
  final int queueSize;
  final int maxConcurrentJobs;

  const QueueStatistics({
    required this.pendingJobs,
    required this.runningJobs,
    required this.completedJobs,
    required this.failedJobs,
    required this.totalJobsProcessed,
    required this.totalJobsFailed,
    required this.jobTypeStats,
    required this.queueSize,
    required this.maxConcurrentJobs,
  });

  double get successRate {
    final total = totalJobsProcessed + totalJobsFailed;
    return total > 0 ? totalJobsProcessed / total : 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'pending_jobs': pendingJobs,
      'running_jobs': runningJobs,
      'completed_jobs': completedJobs,
      'failed_jobs': failedJobs,
      'total_jobs_processed': totalJobsProcessed,
      'total_jobs_failed': totalJobsFailed,
      'success_rate': successRate,
      'job_type_stats': jobTypeStats,
      'queue_size': queueSize,
      'max_concurrent_jobs': maxConcurrentJobs,
      'utilization': runningJobs / maxConcurrentJobs,
    };
  }

  @override
  String toString() {
    return 'QueueStats(pending: $pendingJobs, running: $runningJobs, completed: $completedJobs, success: ${(successRate * 100).toStringAsFixed(1)}%)';
  }
}

/// Document processing job implementation
class DocumentProcessingJob implements Job {
  @override
  final String id;
  
  @override
  final String type = 'document_processing';
  
  @override
  final JobPriority priority;
  
  @override
  final Map<String, dynamic> data;
  
  @override
  final int maxRetries;
  
  @override
  final Duration timeout;

  DocumentProcessingJob({
    required this.id,
    required this.data,
    this.priority = JobPriority.normal,
    this.maxRetries = 3,
    this.timeout = const Duration(minutes: 5),
  });

  @override
  Future<JobResult> execute() async {
    try {
      final filePath = data['file_path'] as String;
      final processingType = data['processing_type'] as String;
      
      print('📄 Processing document: $filePath ($processingType)');
      
      // Simulate document processing
      await Future.delayed(Duration(seconds: 2 + Random().nextInt(3)));
      
      final result = {
        'file_path': filePath,
        'processing_type': processingType,
        'processed_at': DateTime.now().toIso8601String(),
        'word_count': 1000 + Random().nextInt(5000),
        'status': 'processed',
      };
      
      return JobResult(
        jobId: id,
        success: true,
        result: result,
        executionTime: Duration(seconds: 3),
        metadata: {'file_size_bytes': 1024 * (500 + Random().nextInt(1500))},
      );
    } catch (e) {
      return JobResult(
        jobId: id,
        success: false,
        error: e.toString(),
        executionTime: Duration(seconds: 1),
      );
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'priority': priority.name,
      'data': data,
      'max_retries': maxRetries,
      'timeout_seconds': timeout.inSeconds,
    };
  }

  factory DocumentProcessingJob.fromJson(Map<String, dynamic> json) {
    return DocumentProcessingJob(
      id: json['id'],
      data: Map<String, dynamic>.from(json['data']),
      priority: JobPriority.values.byName(json['priority'] ?? 'normal'),
      maxRetries: json['max_retries'] ?? 3,
      timeout: Duration(seconds: json['timeout_seconds'] ?? 300),
    );
  }
}

/// Model embedding job implementation
class ModelEmbeddingJob implements Job {
  @override
  final String id;
  
  @override
  final String type = 'model_embedding';
  
  @override
  final JobPriority priority;
  
  @override
  final Map<String, dynamic> data;
  
  @override
  final int maxRetries;
  
  @override
  final Duration timeout;

  ModelEmbeddingJob({
    required this.id,
    required this.data,
    this.priority = JobPriority.normal,
    this.maxRetries = 2,
    this.timeout = const Duration(minutes: 10),
  });

  @override
  Future<JobResult> execute() async {
    try {
      final text = data['text'] as String;
      final model = data['model'] as String? ?? 'text-embedding-ada-002';
      
      print('🔢 Generating embeddings for text (${text.length} chars, model: $model)');
      
      // Simulate embedding generation
      await Future.delayed(Duration(seconds: 5 + Random().nextInt(10)));
      
      // Generate fake embeddings
      final embeddings = List.generate(1536, (i) => Random().nextDouble() * 2 - 1);
      
      final result = {
        'text': text,
        'model': model,
        'embeddings': embeddings,
        'dimension': embeddings.length,
        'generated_at': DateTime.now().toIso8601String(),
      };
      
      return JobResult(
        jobId: id,
        success: true,
        result: result,
        executionTime: Duration(seconds: 8),
        metadata: {
          'text_length': text.length,
          'embedding_dimension': embeddings.length,
        },
      );
    } catch (e) {
      return JobResult(
        jobId: id,
        success: false,
        error: e.toString(),
        executionTime: Duration(seconds: 2),
      );
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'priority': priority.name,
      'data': data,
      'max_retries': maxRetries,
      'timeout_seconds': timeout.inSeconds,
    };
  }

  factory ModelEmbeddingJob.fromJson(Map<String, dynamic> json) {
    return ModelEmbeddingJob(
      id: json['id'],
      data: Map<String, dynamic>.from(json['data']),
      priority: JobPriority.values.byName(json['priority'] ?? 'normal'),
      maxRetries: json['max_retries'] ?? 2,
      timeout: Duration(seconds: json['timeout_seconds'] ?? 600),
    );
  }
}

/// File indexing job implementation
class FileIndexingJob implements Job {
  @override
  final String id;
  
  @override
  final String type = 'file_indexing';
  
  @override
  final JobPriority priority;
  
  @override
  final Map<String, dynamic> data;
  
  @override
  final int maxRetries;
  
  @override
  final Duration timeout;

  FileIndexingJob({
    required this.id,
    required this.data,
    this.priority = JobPriority.low,
    this.maxRetries = 3,
    this.timeout = const Duration(minutes: 15),
  });

  @override
  Future<JobResult> execute() async {
    try {
      final directoryPath = data['directory_path'] as String;
      final includePatterns = data['include_patterns'] as List<String>?;
      
      print('📂 Indexing files in: $directoryPath');
      
      // Simulate file indexing
      await Future.delayed(Duration(seconds: 10 + Random().nextInt(20)));
      
      final filesIndexed = 50 + Random().nextInt(500);
      final result = {
        'directory_path': directoryPath,
        'files_indexed': filesIndexed,
        'include_patterns': includePatterns,
        'indexed_at': DateTime.now().toIso8601String(),
        'total_size_bytes': filesIndexed * (1024 + Random().nextInt(10240)),
      };
      
      return JobResult(
        jobId: id,
        success: true,
        result: result,
        executionTime: Duration(seconds: 15),
        metadata: {
          'files_processed': filesIndexed,
          'directory_depth': 3 + Random().nextInt(5),
        },
      );
    } catch (e) {
      return JobResult(
        jobId: id,
        success: false,
        error: e.toString(),
        executionTime: Duration(seconds: 3),
      );
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'priority': priority.name,
      'data': data,
      'max_retries': maxRetries,
      'timeout_seconds': timeout.inSeconds,
    };
  }

  factory FileIndexingJob.fromJson(Map<String, dynamic> json) {
    return FileIndexingJob(
      id: json['id'],
      data: Map<String, dynamic>.from(json['data']),
      priority: JobPriority.values.byName(json['priority'] ?? 'low'),
      maxRetries: json['max_retries'] ?? 3,
      timeout: Duration(seconds: json['timeout_seconds'] ?? 900),
    );
  }
}