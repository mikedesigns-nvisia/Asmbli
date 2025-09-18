import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'structured_logger.dart';

/// Service for managing log retention policies and cleanup
class LogRetentionService {
  static LogRetentionService? _instance;
  static LogRetentionService get instance => _instance ??= LogRetentionService._();
  
  LogRetentionService._();

  final StructuredLogger _logger = StructuredLogger.instance;
  Timer? _cleanupTimer;
  bool _initialized = false;

  /// Default retention policies
  static const Map<String, RetentionPolicy> defaultPolicies = {
    'terminal': RetentionPolicy(
      maxAge: Duration(days: 30),
      maxSizeMB: 100,
      maxFiles: 50,
      compressionEnabled: true,
    ),
    'mcp': RetentionPolicy(
      maxAge: Duration(days: 30),
      maxSizeMB: 100,
      maxFiles: 50,
      compressionEnabled: true,
    ),
    'security': RetentionPolicy(
      maxAge: Duration(days: 90),
      maxSizeMB: 200,
      maxFiles: 100,
      compressionEnabled: true,
    ),
    'performance': RetentionPolicy(
      maxAge: Duration(days: 7),
      maxSizeMB: 50,
      maxFiles: 20,
      compressionEnabled: false,
    ),
    'error': RetentionPolicy(
      maxAge: Duration(days: 60),
      maxSizeMB: 150,
      maxFiles: 75,
      compressionEnabled: true,
    ),
  };

  Map<String, RetentionPolicy> _retentionPolicies = Map.from(defaultPolicies);

  /// Initialize the retention service
  Future<void> initialize() async {
    if (_initialized) return;

    await _loadRetentionPolicies();
    
    // Start periodic cleanup (daily)
    _cleanupTimer = Timer.periodic(
      const Duration(hours: 24),
      (_) => performCleanup(),
    );
    
    _initialized = true;
    
    _logger.logTerminalOperation(
      agentId: 'system',
      operation: 'retention_service_init',
      success: true,
      metadata: {
        'policies': _retentionPolicies.keys.toList(),
        'cleanup_interval': '24h',
      },
    );
  }

  /// Set retention policy for a category
  void setRetentionPolicy(String category, RetentionPolicy policy) {
    _retentionPolicies[category] = policy;
    _saveRetentionPolicies();
    
    _logger.logTerminalOperation(
      agentId: 'system',
      operation: 'set_retention_policy',
      success: true,
      metadata: {
        'category': category,
        'max_age_days': policy.maxAge.inDays,
        'max_size_mb': policy.maxSizeMB,
        'max_files': policy.maxFiles,
        'compression': policy.compressionEnabled,
      },
    );
  }

  /// Get retention policy for a category
  RetentionPolicy getRetentionPolicy(String category) {
    return _retentionPolicies[category] ?? defaultPolicies['terminal']!;
  }

  /// Perform comprehensive cleanup based on retention policies
  Future<CleanupResult> performCleanup({List<String>? categories}) async {
    final stopwatch = Stopwatch()..start();
    final result = CleanupResult();

    try {
      final categoriesToClean = categories ?? _retentionPolicies.keys.toList();
      
      for (final category in categoriesToClean) {
        final policy = _retentionPolicies[category];
        if (policy == null) continue;

        final categoryResult = await _cleanupCategory(category, policy);
        result.merge(categoryResult);
      }

      stopwatch.stop();
      result.duration = stopwatch.elapsed;

      _logger.logTerminalOperation(
        agentId: 'system',
        operation: 'cleanup_completed',
        success: true,
        metadata: {
          'duration_ms': stopwatch.elapsed.inMilliseconds,
          'files_deleted': result.filesDeleted,
          'files_compressed': result.filesCompressed,
          'space_freed_mb': result.spaceFreedMB,
          'categories': categoriesToClean,
        },
      );

      return result;
    } catch (e, stackTrace) {
      _logger.logError(
        component: 'log_retention',
        error: e.toString(),
        operation: 'cleanup',
        stackTrace: stackTrace,
        context: {'categories': categories},
      );
      rethrow;
    }
  }

  /// Clean up logs for a specific category
  Future<CleanupResult> _cleanupCategory(String category, RetentionPolicy policy) async {
    final result = CleanupResult();
    final logDirectory = await _getCategoryLogDirectory(category);
    
    if (!await Directory(logDirectory).exists()) {
      return result;
    }

    final logFiles = await _getLogFiles(logDirectory);
    
    // Sort files by modification time (oldest first)
    logFiles.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

    final cutoffDate = DateTime.now().subtract(policy.maxAge);
    int totalSizeMB = 0;
    final filesToDelete = <File>[];
    final filesToCompress = <File>[];

    // Calculate current total size
    for (final file in logFiles) {
      final sizeBytes = await file.length();
      totalSizeMB += (sizeBytes / (1024 * 1024)).round();
    }

    // Apply retention policies
    for (final file in logFiles) {
      final lastModified = file.lastModifiedSync();
      final sizeBytes = await file.length();
      final sizeMB = (sizeBytes / (1024 * 1024)).round();

      // Delete files older than max age
      if (lastModified.isBefore(cutoffDate)) {
        filesToDelete.add(file);
        result.spaceFreedMB += sizeMB;
        continue;
      }

      // Compress old files if enabled
      if (policy.compressionEnabled && 
          !file.path.endsWith('.gz') &&
          lastModified.isBefore(DateTime.now().subtract(const Duration(days: 7)))) {
        filesToCompress.add(file);
      }
    }

    // Delete excess files if over file limit
    if (logFiles.length > policy.maxFiles) {
      final excessFiles = logFiles.take(logFiles.length - policy.maxFiles);
      for (final file in excessFiles) {
        if (!filesToDelete.contains(file)) {
          filesToDelete.add(file);
          final sizeMB = ((await file.length()) / (1024 * 1024)).round();
          result.spaceFreedMB += sizeMB;
        }
      }
    }

    // Delete files if over size limit
    if (totalSizeMB > policy.maxSizeMB) {
      int currentSize = totalSizeMB;
      for (final file in logFiles) {
        if (currentSize <= policy.maxSizeMB) break;
        if (!filesToDelete.contains(file)) {
          filesToDelete.add(file);
          final sizeMB = ((await file.length()) / (1024 * 1024)).round();
          result.spaceFreedMB += sizeMB;
          currentSize -= sizeMB;
        }
      }
    }

    // Perform deletions
    for (final file in filesToDelete) {
      try {
        await file.delete();
        result.filesDeleted++;
      } catch (e) {
        _logger.logError(
          component: 'log_retention',
          error: 'Failed to delete file: ${file.path}',
          operation: 'delete_file',
          context: {'category': category, 'file': file.path},
        );
      }
    }

    // Perform compressions
    for (final file in filesToCompress) {
      try {
        await _compressFile(file);
        result.filesCompressed++;
      } catch (e) {
        _logger.logError(
          component: 'log_retention',
          error: 'Failed to compress file: ${file.path}',
          operation: 'compress_file',
          context: {'category': category, 'file': file.path},
        );
      }
    }

    return result;
  }

  /// Compress a log file using gzip
  Future<void> _compressFile(File file) async {
    final compressedPath = '${file.path}.gz';
    final compressedFile = File(compressedPath);
    
    if (await compressedFile.exists()) {
      return; // Already compressed
    }

    final bytes = await file.readAsBytes();
    final compressed = gzip.encode(bytes);
    
    await compressedFile.writeAsBytes(compressed);
    await file.delete();
  }

  /// Get log files in a directory
  Future<List<File>> _getLogFiles(String directory) async {
    final dir = Directory(directory);
    if (!await dir.exists()) return [];

    return await dir
        .list(recursive: false)
        .where((entity) => entity is File)
        .cast<File>()
        .where((file) => 
          file.path.endsWith('.log') || 
          file.path.endsWith('.log.gz') ||
          file.path.endsWith('.json'))
        .toList();
  }

  /// Archive old logs to a separate location
  Future<ArchiveResult> archiveLogs({
    required String category,
    required DateTime beforeDate,
    String? archivePath,
  }) async {
    final stopwatch = Stopwatch()..start();
    final result = ArchiveResult();

    try {
      final logDirectory = await _getCategoryLogDirectory(category);
      final logFiles = await _getLogFiles(logDirectory);
      
      final archiveDir = archivePath ?? await _getArchiveDirectory(category);
      await Directory(archiveDir).create(recursive: true);

      final filesToArchive = logFiles.where((file) => 
        file.lastModifiedSync().isBefore(beforeDate)
      ).toList();

      for (final file in filesToArchive) {
        try {
          final archiveFile = File(path.join(archiveDir, path.basename(file.path)));
          await file.copy(archiveFile.path);
          await file.delete();
          
          result.filesArchived++;
          result.sizeArchivedMB += ((await archiveFile.length()) / (1024 * 1024)).round();
        } catch (e) {
          result.errors.add('Failed to archive ${file.path}: $e');
        }
      }

      stopwatch.stop();
      result.duration = stopwatch.elapsed;

      _logger.logTerminalOperation(
        agentId: 'system',
        operation: 'archive_logs',
        success: result.errors.isEmpty,
        metadata: {
          'category': category,
          'files_archived': result.filesArchived,
          'size_archived_mb': result.sizeArchivedMB,
          'duration_ms': stopwatch.elapsed.inMilliseconds,
          'errors': result.errors.length,
        },
      );

      return result;
    } catch (e, stackTrace) {
      _logger.logError(
        component: 'log_retention',
        error: e.toString(),
        operation: 'archive_logs',
        stackTrace: stackTrace,
        context: {
          'category': category,
          'before_date': beforeDate.toIso8601String(),
        },
      );
      rethrow;
    }
  }

  /// Get storage statistics for log categories
  Future<Map<String, StorageStats>> getStorageStatistics() async {
    final stats = <String, StorageStats>{};

    for (final category in _retentionPolicies.keys) {
      try {
        final logDirectory = await _getCategoryLogDirectory(category);
        final logFiles = await _getLogFiles(logDirectory);
        
        int totalSizeMB = 0;
        int compressedFiles = 0;
        DateTime? oldestFile;
        DateTime? newestFile;

        for (final file in logFiles) {
          final sizeBytes = await file.length();
          totalSizeMB += (sizeBytes / (1024 * 1024)).round();
          
          if (file.path.endsWith('.gz')) {
            compressedFiles++;
          }

          final lastModified = file.lastModifiedSync();
          if (oldestFile == null || lastModified.isBefore(oldestFile)) {
            oldestFile = lastModified;
          }
          if (newestFile == null || lastModified.isAfter(newestFile)) {
            newestFile = lastModified;
          }
        }

        stats[category] = StorageStats(
          totalFiles: logFiles.length,
          totalSizeMB: totalSizeMB,
          compressedFiles: compressedFiles,
          oldestFile: oldestFile,
          newestFile: newestFile,
          policy: _retentionPolicies[category]!,
        );
      } catch (e) {
        _logger.logError(
          component: 'log_retention',
          error: 'Failed to get stats for category: $category',
          operation: 'get_storage_stats',
          context: {'category': category},
        );
      }
    }

    return stats;
  }

  /// Load retention policies from configuration
  Future<void> _loadRetentionPolicies() async {
    try {
      final configFile = File(await _getRetentionConfigPath());
      if (await configFile.exists()) {
        final configJson = await configFile.readAsString();
        final config = jsonDecode(configJson) as Map<String, dynamic>;
        
        for (final entry in config.entries) {
          final policyData = entry.value as Map<String, dynamic>;
          _retentionPolicies[entry.key] = RetentionPolicy.fromJson(policyData);
        }
      }
    } catch (e) {
      _logger.logError(
        component: 'log_retention',
        error: 'Failed to load retention policies',
        operation: 'load_policies',
        context: {'error': e.toString()},
      );
      // Use default policies
      _retentionPolicies = Map.from(defaultPolicies);
    }
  }

  /// Save retention policies to configuration
  Future<void> _saveRetentionPolicies() async {
    try {
      final configFile = File(await _getRetentionConfigPath());
      await configFile.parent.create(recursive: true);
      
      final config = <String, dynamic>{};
      for (final entry in _retentionPolicies.entries) {
        config[entry.key] = entry.value.toJson();
      }
      
      await configFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(config),
      );
    } catch (e) {
      _logger.logError(
        component: 'log_retention',
        error: 'Failed to save retention policies',
        operation: 'save_policies',
        context: {'error': e.toString()},
      );
    }
  }

  /// Helper methods for paths
  Future<String> _getCategoryLogDirectory(String category) async {
    final baseDir = await _getLogsDirectory();
    return path.join(baseDir, category);
  }

  Future<String> _getArchiveDirectory(String category) async {
    final baseDir = await _getLogsDirectory();
    return path.join(baseDir, 'archive', category);
  }

  Future<String> _getRetentionConfigPath() async {
    final configDir = await _getConfigDirectory();
    return path.join(configDir, 'log_retention.json');
  }

  Future<String> _getLogsDirectory() async {
    if (Platform.isWindows) {
      final appData = Platform.environment['LOCALAPPDATA'] ?? Platform.environment['APPDATA'];
      return path.join(appData!, 'Asmbli', 'logs');
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME']!;
      return path.join(home, 'Library', 'Logs', 'Asmbli');
    } else {
      final home = Platform.environment['HOME']!;
      return path.join(home, '.local', 'share', 'asmbli', 'logs');
    }
  }

  Future<String> _getConfigDirectory() async {
    if (Platform.isWindows) {
      final appData = Platform.environment['LOCALAPPDATA'] ?? Platform.environment['APPDATA'];
      return path.join(appData!, 'Asmbli', 'config');
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME']!;
      return path.join(home, 'Library', 'Application Support', 'Asmbli');
    } else {
      final home = Platform.environment['HOME']!;
      return path.join(home, '.config', 'asmbli');
    }
  }

  /// Dispose resources
  void dispose() {
    _cleanupTimer?.cancel();
    _initialized = false;
  }
}

/// Data models
class RetentionPolicy {
  final Duration maxAge;
  final int maxSizeMB;
  final int maxFiles;
  final bool compressionEnabled;

  const RetentionPolicy({
    required this.maxAge,
    required this.maxSizeMB,
    required this.maxFiles,
    required this.compressionEnabled,
  });

  factory RetentionPolicy.fromJson(Map<String, dynamic> json) {
    return RetentionPolicy(
      maxAge: Duration(days: json['max_age_days'] as int),
      maxSizeMB: json['max_size_mb'] as int,
      maxFiles: json['max_files'] as int,
      compressionEnabled: json['compression_enabled'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'max_age_days': maxAge.inDays,
      'max_size_mb': maxSizeMB,
      'max_files': maxFiles,
      'compression_enabled': compressionEnabled,
    };
  }
}

class CleanupResult {
  int filesDeleted = 0;
  int filesCompressed = 0;
  int spaceFreedMB = 0;
  Duration duration = Duration.zero;
  final List<String> errors = [];

  void merge(CleanupResult other) {
    filesDeleted += other.filesDeleted;
    filesCompressed += other.filesCompressed;
    spaceFreedMB += other.spaceFreedMB;
    errors.addAll(other.errors);
  }
}

class ArchiveResult {
  int filesArchived = 0;
  int sizeArchivedMB = 0;
  Duration duration = Duration.zero;
  final List<String> errors = [];
}

class StorageStats {
  final int totalFiles;
  final int totalSizeMB;
  final int compressedFiles;
  final DateTime? oldestFile;
  final DateTime? newestFile;
  final RetentionPolicy policy;

  StorageStats({
    required this.totalFiles,
    required this.totalSizeMB,
    required this.compressedFiles,
    this.oldestFile,
    this.newestFile,
    required this.policy,
  });

  double get compressionRatio => 
    totalFiles > 0 ? (compressedFiles / totalFiles) * 100 : 0.0;

  bool get isOverSizeLimit => totalSizeMB > policy.maxSizeMB;
  bool get isOverFileLimit => totalFiles > policy.maxFiles;
  
  Duration? get oldestFileAge => 
    oldestFile != null ? DateTime.now().difference(oldestFile!) : null;
}

// ==================== Riverpod Provider ====================

final logRetentionServiceProvider = Provider<LogRetentionService>((ref) {
  return LogRetentionService.instance;
});