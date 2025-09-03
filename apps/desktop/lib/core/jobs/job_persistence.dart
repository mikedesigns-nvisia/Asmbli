import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../cache/file_cache.dart';
import 'job_queue.dart';

/// Job persistence and recovery system
class JobPersistenceManager {
  final FileCache _cache;
  final Directory _checkpointDir;
  final Duration _checkpointInterval;
  final Duration _recoveryTimeout;
  final bool _enableWAL; // Write-Ahead Logging
  
  // State tracking
  final Map<String, JobCheckpoint> _checkpoints = {};
  final List<JobTransaction> _pendingTransactions = [];
  
  // Timers
  Timer? _checkpointTimer;
  Timer? _walFlushTimer;
  
  // Statistics
  int _totalCheckpoints = 0;
  int _totalRecoveries = 0;
  int _corruptedJobs = 0;

  JobPersistenceManager({
    required FileCache cache,
    required String checkpointDirectory,
    Duration checkpointInterval = const Duration(minutes: 5),
    Duration recoveryTimeout = const Duration(seconds: 30),
    bool enableWAL = true,
    Duration walFlushInterval = const Duration(seconds: 10),
  }) : _cache = cache,
       _checkpointDir = Directory(checkpointDirectory),
       _checkpointInterval = checkpointInterval,
       _recoveryTimeout = recoveryTimeout,
       _enableWAL = enableWAL {
    
    if (_enableWAL) {
      _walFlushTimer = Timer.periodic(walFlushInterval, (_) => _flushWAL());
    }
    
    _checkpointTimer = Timer.periodic(checkpointInterval, (_) => _createCheckpoint());
    
    print('💾 Job persistence manager initialized (checkpoints: ${_checkpointInterval.inMinutes}m, WAL: $_enableWAL)');
  }

  /// Initialize persistence system
  Future<void> initialize() async {
    try {
      // Create checkpoint directory
      if (!await _checkpointDir.exists()) {
        await _checkpointDir.create(recursive: true);
      }
      
      // Load existing checkpoints
      await _loadCheckpoints();
      
      print('✅ Job persistence initialized with ${_checkpoints.length} checkpoints');
    } catch (e) {
      throw PersistenceException('Failed to initialize persistence: $e');
    }
  }

  /// Persist job state
  Future<void> persistJob(QueuedJob job, JobPersistenceState state) async {
    if (_enableWAL) {
      // Write to WAL first
      await _writeToWAL(JobTransaction(
        type: JobTransactionType.persist,
        jobId: job.job.id,
        job: job,
        state: state,
        timestamp: DateTime.now(),
      ));
    }
    
    // Create or update checkpoint
    final checkpoint = JobCheckpoint(
      jobId: job.job.id,
      job: job,
      state: state,
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
      version: (_checkpoints[job.job.id]?.version ?? 0) + 1,
    );
    
    _checkpoints[job.job.id] = checkpoint;
    
    // Persist to cache
    await _cache.put(
      _getJobKey(job.job.id),
      checkpoint.toJson(),
      ttl: const Duration(days: 7),
    );
    
    print('💾 Persisted job: ${job.job.id} (state: ${state.name})');
  }

  /// Update job progress
  Future<void> updateJobProgress(String jobId, Map<String, dynamic> progress) async {
    final checkpoint = _checkpoints[jobId];
    if (checkpoint == null) return;
    
    if (_enableWAL) {
      await _writeToWAL(JobTransaction(
        type: JobTransactionType.progress,
        jobId: jobId,
        progress: progress,
        timestamp: DateTime.now(),
      ));
    }
    
    final updatedCheckpoint = checkpoint.copyWith(
      progress: {...checkpoint.progress, ...progress},
      lastUpdated: DateTime.now(),
      version: checkpoint.version + 1,
    );
    
    _checkpoints[jobId] = updatedCheckpoint;
    
    // Update cache
    await _cache.put(
      _getJobKey(jobId),
      updatedCheckpoint.toJson(),
      ttl: const Duration(days: 7),
    );
  }

  /// Remove persisted job
  Future<void> removeJob(String jobId) async {
    if (_enableWAL) {
      await _writeToWAL(JobTransaction(
        type: JobTransactionType.remove,
        jobId: jobId,
        timestamp: DateTime.now(),
      ));
    }
    
    _checkpoints.remove(jobId);
    await _cache.remove(_getJobKey(jobId));
    
    print('🗑️ Removed persisted job: $jobId');
  }

  /// Recover jobs from persistence
  Future<JobRecoveryResult> recoverJobs() async {
    print('🔄 Starting job recovery...');
    
    final recoveredJobs = <QueuedJob>[];
    final failedRecoveries = <String, String>{};
    final corruptedCheckpoints = <String>[];
    
    try {
      // Apply WAL transactions first
      if (_enableWAL) {
        await _applyWAL();
      }
      
      for (final checkpoint in _checkpoints.values) {
        try {
          final recoveredJob = await _recoverJob(checkpoint);
          if (recoveredJob != null) {
            recoveredJobs.add(recoveredJob);
            print('✅ Recovered job: ${checkpoint.jobId} (${checkpoint.state.name})');
          }
        } catch (e) {
          failedRecoveries[checkpoint.jobId] = e.toString();
          print('❌ Failed to recover job ${checkpoint.jobId}: $e');
        }
      }
      
      _totalRecoveries += recoveredJobs.length;
      _corruptedJobs += corruptedCheckpoints.length;
      
      // Clean up corrupted checkpoints
      for (final jobId in corruptedCheckpoints) {
        await removeJob(jobId);
      }
      
      final result = JobRecoveryResult(
        recoveredJobs: recoveredJobs,
        failedRecoveries: failedRecoveries,
        corruptedCheckpoints: corruptedCheckpoints,
        totalAttempted: _checkpoints.length,
        recoveryTime: DateTime.now(),
      );
      
      print('🎯 Recovery completed: ${result.successCount}/${result.totalAttempted} jobs recovered');
      return result;
      
    } catch (e) {
      throw PersistenceException('Job recovery failed: $e');
    }
  }

  /// Recover specific job from checkpoint
  Future<QueuedJob?> _recoverJob(JobCheckpoint checkpoint) async {
    // Validate checkpoint integrity
    if (!_validateCheckpoint(checkpoint)) {
      throw const PersistenceException('Checkpoint integrity check failed');
    }
    
    // Determine recovery action based on state
    switch (checkpoint.state) {
      case JobPersistenceState.queued:
        return checkpoint.job.copyWith(status: JobStatus.pending);
        
      case JobPersistenceState.running:
        // Job was interrupted - reset to pending for retry
        return checkpoint.job.copyWith(
          status: JobStatus.pending,
          attemptCount: checkpoint.job.attemptCount,
        );
        
      case JobPersistenceState.retrying:
        // Continue retry schedule
        return checkpoint.job.copyWith(status: JobStatus.retrying);
        
      case JobPersistenceState.completed:
      case JobPersistenceState.failed:
        // Don't recover completed/failed jobs
        return null;
        
      case JobPersistenceState.cancelled:
        return null;
    }
  }

  /// Validate checkpoint data integrity
  bool _validateCheckpoint(JobCheckpoint checkpoint) {
    try {
      // Basic validation
      if (checkpoint.jobId.isEmpty) return false;
      if (checkpoint.job.job.id != checkpoint.jobId) return false;
      if (checkpoint.version < 1) return false;
      
      // Validate job data
      final jobData = checkpoint.job.toJson();
      if (jobData.isEmpty) return false;
      
      // Validate timestamps
      if (checkpoint.createdAt.isAfter(DateTime.now())) return false;
      if (checkpoint.lastUpdated.isBefore(checkpoint.createdAt)) return false;
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Create checkpoint snapshot
  Future<void> _createCheckpoint() async {
    if (_checkpoints.isEmpty) return;
    
    try {
      final timestamp = DateTime.now();
      final checkpointData = {
        'version': 1,
        'timestamp': timestamp.toIso8601String(),
        'checkpoints': _checkpoints.map((k, v) => MapEntry(k, v.toJson())),
        'statistics': {
          'total_checkpoints': _totalCheckpoints,
          'total_recoveries': _totalRecoveries,
          'corrupted_jobs': _corruptedJobs,
        },
      };
      
      // Write to cache
      await _cache.put(
        'job_checkpoints_snapshot',
        checkpointData,
        ttl: const Duration(days: 30),
      );
      
      // Write to file system as backup
      final checkpointFile = File(path.join(_checkpointDir.path, 'checkpoint_${timestamp.millisecondsSinceEpoch}.json'));
      await checkpointFile.writeAsString(jsonEncode(checkpointData));
      
      _totalCheckpoints++;
      print('📸 Created checkpoint: ${_checkpoints.length} jobs');
      
      // Clean up old checkpoint files
      await _cleanupOldCheckpoints();
      
    } catch (e) {
      print('⚠️ Failed to create checkpoint: $e');
    }
  }

  /// Load checkpoints from persistence
  Future<void> _loadCheckpoints() async {
    try {
      // Try loading from cache first
      final cacheData = await _cache.get<Map<String, dynamic>>('job_checkpoints_snapshot');
      if (cacheData != null) {
        await _loadCheckpointsFromData(cacheData);
        return;
      }
      
      // Fall back to file system
      final checkpointFiles = await _getCheckpointFiles();
      if (checkpointFiles.isNotEmpty) {
        // Load latest checkpoint
        final latestFile = checkpointFiles.last;
        final content = await latestFile.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        await _loadCheckpointsFromData(data);
      }
      
    } catch (e) {
      print('⚠️ Failed to load checkpoints: $e');
    }
  }

  /// Load checkpoints from JSON data
  Future<void> _loadCheckpointsFromData(Map<String, dynamic> data) async {
    final checkpointsData = data['checkpoints'] as Map<String, dynamic>?;
    if (checkpointsData != null) {
      _checkpoints.clear();
      
      for (final entry in checkpointsData.entries) {
        try {
          final checkpoint = JobCheckpoint.fromJson(entry.value);
          _checkpoints[entry.key] = checkpoint;
        } catch (e) {
          print('⚠️ Failed to load checkpoint ${entry.key}: $e');
        }
      }
    }
    
    // Load statistics
    final stats = data['statistics'] as Map<String, dynamic>?;
    if (stats != null) {
      _totalCheckpoints = stats['total_checkpoints'] ?? 0;
      _totalRecoveries = stats['total_recoveries'] ?? 0;
      _corruptedJobs = stats['corrupted_jobs'] ?? 0;
    }
  }

  /// Get checkpoint files sorted by timestamp
  Future<List<File>> _getCheckpointFiles() async {
    final files = <File>[];
    
    await for (final entity in _checkpointDir.list()) {
      if (entity is File && entity.path.endsWith('.json') && entity.path.contains('checkpoint_')) {
        files.add(entity);
      }
    }
    
    // Sort by timestamp (extracted from filename)
    files.sort((a, b) {
      final aTimestamp = _extractTimestamp(a.path);
      final bTimestamp = _extractTimestamp(b.path);
      return aTimestamp.compareTo(bTimestamp);
    });
    
    return files;
  }

  /// Extract timestamp from checkpoint filename
  int _extractTimestamp(String filename) {
    final match = RegExp(r'checkpoint_(\d+)\.json').firstMatch(filename);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  /// Clean up old checkpoint files
  Future<void> _cleanupOldCheckpoints() async {
    try {
      final files = await _getCheckpointFiles();
      
      // Keep only the last 10 checkpoints
      if (files.length > 10) {
        final filesToDelete = files.sublist(0, files.length - 10);
        
        for (final file in filesToDelete) {
          await file.delete();
        }
        
        print('🧹 Cleaned up ${filesToDelete.length} old checkpoint files');
      }
    } catch (e) {
      print('⚠️ Failed to cleanup old checkpoints: $e');
    }
  }

  /// Write transaction to WAL
  Future<void> _writeToWAL(JobTransaction transaction) async {
    _pendingTransactions.add(transaction);
    
    // Write immediately for critical operations
    if (transaction.type == JobTransactionType.persist || transaction.type == JobTransactionType.remove) {
      await _flushWAL();
    }
  }

  /// Flush WAL to disk
  Future<void> _flushWAL() async {
    if (_pendingTransactions.isEmpty) return;
    
    try {
      final walFile = File(path.join(_checkpointDir.path, 'job.wal'));
      final walData = _pendingTransactions.map((t) => t.toJson()).toList();
      
      // Append to WAL file
      final content = '${walData.map((data) => jsonEncode(data)).join('\n')}\n';
      await walFile.writeAsString(content, mode: FileMode.append);
      
      _pendingTransactions.clear();
      print('📝 Flushed ${walData.length} WAL entries');
      
    } catch (e) {
      print('⚠️ Failed to flush WAL: $e');
    }
  }

  /// Apply WAL transactions during recovery
  Future<void> _applyWAL() async {
    try {
      final walFile = File(path.join(_checkpointDir.path, 'job.wal'));
      if (!await walFile.exists()) return;
      
      final content = await walFile.readAsString();
      final lines = content.trim().split('\n');
      
      int appliedCount = 0;
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        
        try {
          final transactionData = jsonDecode(line) as Map<String, dynamic>;
          final transaction = JobTransaction.fromJson(transactionData);
          
          await _applyTransaction(transaction);
          appliedCount++;
          
        } catch (e) {
          print('⚠️ Failed to apply WAL transaction: $e');
        }
      }
      
      print('📋 Applied $appliedCount WAL transactions');
      
      // Clear WAL after successful application
      await walFile.delete();
      
    } catch (e) {
      print('⚠️ Failed to apply WAL: $e');
    }
  }

  /// Apply single transaction
  Future<void> _applyTransaction(JobTransaction transaction) async {
    switch (transaction.type) {
      case JobTransactionType.persist:
        if (transaction.job != null && transaction.state != null) {
          final checkpoint = JobCheckpoint(
            jobId: transaction.jobId,
            job: transaction.job!,
            state: transaction.state!,
            createdAt: transaction.timestamp,
            lastUpdated: transaction.timestamp,
            version: 1,
          );
          _checkpoints[transaction.jobId] = checkpoint;
        }
        break;
        
      case JobTransactionType.progress:
        final existingCheckpoint = _checkpoints[transaction.jobId];
        if (existingCheckpoint != null && transaction.progress != null) {
          final updatedCheckpoint = existingCheckpoint.copyWith(
            progress: {...existingCheckpoint.progress, ...transaction.progress!},
            lastUpdated: transaction.timestamp,
            version: existingCheckpoint.version + 1,
          );
          _checkpoints[transaction.jobId] = updatedCheckpoint;
        }
        break;
        
      case JobTransactionType.remove:
        _checkpoints.remove(transaction.jobId);
        break;
    }
  }

  /// Generate cache key for job
  String _getJobKey(String jobId) => 'job_checkpoint:$jobId';

  /// Get persistence statistics
  JobPersistenceStatistics getStatistics() {
    final activeCheckpoints = _checkpoints.values.where((c) => 
        c.state == JobPersistenceState.queued || 
        c.state == JobPersistenceState.running ||
        c.state == JobPersistenceState.retrying).length;
    
    return JobPersistenceStatistics(
      totalCheckpoints: _totalCheckpoints,
      activeCheckpoints: activeCheckpoints,
      totalRecoveries: _totalRecoveries,
      corruptedJobs: _corruptedJobs,
      pendingWalEntries: _pendingTransactions.length,
      checkpointInterval: _checkpointInterval,
      enableWal: _enableWAL,
      currentJobs: _checkpoints.length,
    );
  }

  /// Dispose persistence manager
  Future<void> dispose() async {
    _checkpointTimer?.cancel();
    _walFlushTimer?.cancel();
    
    // Final checkpoint and WAL flush
    if (_enableWAL) {
      await _flushWAL();
    }
    await _createCheckpoint();
    
    print('💾 Job persistence manager disposed');
  }
}

/// Job persistence states
enum JobPersistenceState {
  queued,
  running,
  retrying,
  completed,
  failed,
  cancelled,
}

/// Job checkpoint data
class JobCheckpoint {
  final String jobId;
  final QueuedJob job;
  final JobPersistenceState state;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final int version;
  final Map<String, dynamic> progress;
  final Map<String, dynamic> metadata;

  JobCheckpoint({
    required this.jobId,
    required this.job,
    required this.state,
    required this.createdAt,
    required this.lastUpdated,
    required this.version,
    this.progress = const {},
    this.metadata = const {},
  });

  JobCheckpoint copyWith({
    JobPersistenceState? state,
    DateTime? lastUpdated,
    int? version,
    Map<String, dynamic>? progress,
    Map<String, dynamic>? metadata,
  }) {
    return JobCheckpoint(
      jobId: jobId,
      job: job,
      state: state ?? this.state,
      createdAt: createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      version: version ?? this.version,
      progress: progress ?? this.progress,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_id': jobId,
      'job': job.toJson(),
      'state': state.name,
      'created_at': createdAt.toIso8601String(),
      'last_updated': lastUpdated.toIso8601String(),
      'version': version,
      'progress': progress,
      'metadata': metadata,
    };
  }

  factory JobCheckpoint.fromJson(Map<String, dynamic> json) {
    return JobCheckpoint(
      jobId: json['job_id'],
      job: QueuedJob.fromJson(json['job']),
      state: JobPersistenceState.values.byName(json['state']),
      createdAt: DateTime.parse(json['created_at']),
      lastUpdated: DateTime.parse(json['last_updated']),
      version: json['version'],
      progress: Map<String, dynamic>.from(json['progress'] ?? {}),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

/// WAL transaction types
enum JobTransactionType {
  persist,
  progress,
  remove,
}

/// Job transaction for WAL
class JobTransaction {
  final JobTransactionType type;
  final String jobId;
  final DateTime timestamp;
  final QueuedJob? job;
  final JobPersistenceState? state;
  final Map<String, dynamic>? progress;

  JobTransaction({
    required this.type,
    required this.jobId,
    required this.timestamp,
    this.job,
    this.state,
    this.progress,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'job_id': jobId,
      'timestamp': timestamp.toIso8601String(),
      'job': job?.toJson(),
      'state': state?.name,
      'progress': progress,
    };
  }

  factory JobTransaction.fromJson(Map<String, dynamic> json) {
    return JobTransaction(
      type: JobTransactionType.values.byName(json['type']),
      jobId: json['job_id'],
      timestamp: DateTime.parse(json['timestamp']),
      job: json['job'] != null ? QueuedJob.fromJson(json['job']) : null,
      state: json['state'] != null ? JobPersistenceState.values.byName(json['state']) : null,
      progress: json['progress'] != null ? Map<String, dynamic>.from(json['progress']) : null,
    );
  }
}

/// Job recovery result
class JobRecoveryResult {
  final List<QueuedJob> recoveredJobs;
  final Map<String, String> failedRecoveries;
  final List<String> corruptedCheckpoints;
  final int totalAttempted;
  final DateTime recoveryTime;

  const JobRecoveryResult({
    required this.recoveredJobs,
    required this.failedRecoveries,
    required this.corruptedCheckpoints,
    required this.totalAttempted,
    required this.recoveryTime,
  });

  int get successCount => recoveredJobs.length;
  int get failureCount => failedRecoveries.length;
  double get successRate => totalAttempted > 0 ? successCount / totalAttempted : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'recovered_jobs': recoveredJobs.map((j) => j.toJson()).toList(),
      'failed_recoveries': failedRecoveries,
      'corrupted_checkpoints': corruptedCheckpoints,
      'total_attempted': totalAttempted,
      'success_count': successCount,
      'failure_count': failureCount,
      'success_rate': successRate,
      'recovery_time': recoveryTime.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'JobRecoveryResult(recovered: $successCount/$totalAttempted, failed: $failureCount, corrupted: ${corruptedCheckpoints.length})';
  }
}

/// Persistence statistics
class JobPersistenceStatistics {
  final int totalCheckpoints;
  final int activeCheckpoints;
  final int totalRecoveries;
  final int corruptedJobs;
  final int pendingWalEntries;
  final Duration checkpointInterval;
  final bool enableWal;
  final int currentJobs;

  const JobPersistenceStatistics({
    required this.totalCheckpoints,
    required this.activeCheckpoints,
    required this.totalRecoveries,
    required this.corruptedJobs,
    required this.pendingWalEntries,
    required this.checkpointInterval,
    required this.enableWal,
    required this.currentJobs,
  });

  Map<String, dynamic> toJson() {
    return {
      'total_checkpoints': totalCheckpoints,
      'active_checkpoints': activeCheckpoints,
      'total_recoveries': totalRecoveries,
      'corrupted_jobs': corruptedJobs,
      'pending_wal_entries': pendingWalEntries,
      'checkpoint_interval_minutes': checkpointInterval.inMinutes,
      'enable_wal': enableWal,
      'current_jobs': currentJobs,
    };
  }

  @override
  String toString() {
    return 'PersistenceStats(checkpoints: $totalCheckpoints, active: $activeCheckpoints, recoveries: $totalRecoveries)';
  }
}

/// Persistence exception
class PersistenceException implements Exception {
  final String message;
  final dynamic originalError;

  const PersistenceException(this.message, [this.originalError]);

  @override
  String toString() {
    final buffer = StringBuffer('PersistenceException: $message');
    if (originalError != null) {
      buffer.write(' (caused by: $originalError)');
    }
    return buffer.toString();
  }
}