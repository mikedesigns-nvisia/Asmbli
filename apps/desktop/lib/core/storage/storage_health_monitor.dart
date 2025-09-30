import 'dart:async';
import '../utils/app_logger.dart';
import '../services/desktop/desktop_storage_service.dart';
import 'safe_storage_manager.dart';

/// Comprehensive storage health monitoring and validation
class StorageHealthMonitor {
  static const String _healthCheckPrefix = '_health_check_';
  static StorageHealthMonitor? _instance;
  static StorageHealthMonitor get instance => _instance ??= StorageHealthMonitor._();

  Timer? _periodicHealthCheck;
  final List<StorageHealthIssue> _recentIssues = [];

  StorageHealthMonitor._();

  /// Start periodic health monitoring
  void startMonitoring({Duration interval = const Duration(minutes: 30)}) {
    _periodicHealthCheck?.cancel();
    _periodicHealthCheck = Timer.periodic(interval, (_) => _performHealthCheck());

    AppLogger.info('Storage health monitoring started', component: 'StorageHealth');
  }

  /// Stop health monitoring
  void stopMonitoring() {
    _periodicHealthCheck?.cancel();
    _periodicHealthCheck = null;
    AppLogger.info('Storage health monitoring stopped', component: 'StorageHealth');
  }

  /// Perform comprehensive storage health check
  Future<StorageHealthReport> performHealthCheck() async {
    AppLogger.info('Starting comprehensive storage health check', component: 'StorageHealth');

    final report = StorageHealthReport();
    final issues = <StorageHealthIssue>[];

    try {
      // Test 1: Basic connectivity
      final connectivityResult = await _testStorageConnectivity();
      report.connectivity = connectivityResult;
      if (!connectivityResult.isHealthy) {
        issues.add(StorageHealthIssue(
          type: StorageIssueType.connectivity,
          severity: StorageIssueSeverity.critical,
          message: connectivityResult.issues.join(', '),
        ));
      }

      // Test 2: Read/Write performance
      final performanceResult = await _testStoragePerformance();
      report.performance = performanceResult;
      if (!performanceResult.isHealthy) {
        issues.add(StorageHealthIssue(
          type: StorageIssueType.performance,
          severity: StorageIssueSeverity.warning,
          message: 'Storage performance degraded: ${performanceResult.issues.join(', ')}',
        ));
      }

      // Test 3: Data integrity
      final integrityResult = await _testDataIntegrity();
      report.integrity = integrityResult;
      if (!integrityResult.isHealthy) {
        issues.add(StorageHealthIssue(
          type: StorageIssueType.integrity,
          severity: StorageIssueSeverity.critical,
          message: 'Data integrity issues: ${integrityResult.issues.join(', ')}',
        ));
      }

      // Test 4: Capacity monitoring
      final capacityResult = await _testStorageCapacity();
      report.capacity = capacityResult;
      if (!capacityResult.isHealthy) {
        issues.add(StorageHealthIssue(
          type: StorageIssueType.capacity,
          severity: StorageIssueSeverity.warning,
          message: 'Storage capacity issues: ${capacityResult.issues.join(', ')}',
        ));
      }

      // Test 5: Fallback system validation
      final fallbackResult = await _testFallbackSystems();
      report.fallbacks = fallbackResult;
      if (!fallbackResult.isHealthy) {
        issues.add(StorageHealthIssue(
          type: StorageIssueType.fallback,
          severity: StorageIssueSeverity.warning,
          message: 'Fallback system issues: ${fallbackResult.issues.join(', ')}',
        ));
      }

      report.issues = issues;
      report.overallHealth = _calculateOverallHealth(report);

      AppLogger.info('Storage health check completed: ${report.overallHealth}', component: 'StorageHealth');
      return report;

    } catch (e) {
      AppLogger.error('Storage health check failed', component: 'StorageHealth', error: e);

      report.issues = [
        StorageHealthIssue(
          type: StorageIssueType.system,
          severity: StorageIssueSeverity.critical,
          message: 'Health check system failure: $e',
        )
      ];
      report.overallHealth = StorageHealth.critical;
      return report;
    }
  }

  Future<void> _performHealthCheck() async {
    try {
      final report = await performHealthCheck();

      // Store recent issues for trend analysis
      _recentIssues.addAll(report.issues);
      if (_recentIssues.length > 100) {
        _recentIssues.removeRange(0, _recentIssues.length - 100);
      }

      // Log significant issues
      final criticalIssues = report.issues.where((i) => i.severity == StorageIssueSeverity.critical);
      if (criticalIssues.isNotEmpty) {
        AppLogger.critical('Critical storage issues detected', component: 'StorageHealth');
        for (final issue in criticalIssues) {
          AppLogger.critical(issue.message, component: 'StorageHealth');
        }
      }

    } catch (e) {
      AppLogger.error('Periodic health check failed', component: 'StorageHealth', error: e);
    }
  }

  Future<StorageTestResult> _testStorageConnectivity() async {
    final issues = <String>[];
    final storage = DesktopStorageService.instance;

    try {
      // Test SharedPreferences connectivity
      const testKey = '${_healthCheckPrefix}connectivity_test';
      const testValue = 'connectivity_ok';

      await storage.setPreference(testKey, testValue);
      final retrieved = storage.getPreference<String>(testKey);
      await storage.removePreference(testKey);

      if (retrieved != testValue) {
        issues.add('SharedPreferences connectivity failed');
      }

    } catch (e) {
      issues.add('SharedPreferences error: $e');
    }

    try {
      // Test Hive connectivity
      const testBox = '${_healthCheckPrefix}test_box';
      const testKey = 'connectivity_test';
      const testValue = 'hive_connectivity_ok';

      await storage.setHiveData(testBox, testKey, testValue);
      final retrieved = storage.getHiveData<String>(testBox, testKey);
      await storage.removeHiveData(testBox, testKey);

      if (retrieved != testValue) {
        issues.add('Hive connectivity failed');
      }

    } catch (e) {
      issues.add('Hive error: $e');
    }

    return StorageTestResult(
      isHealthy: issues.isEmpty,
      issues: issues,
    );
  }

  Future<StorageTestResult> _testStoragePerformance() async {
    final issues = <String>[];
    final storage = DesktopStorageService.instance;

    try {
      // Test write performance
      final writeStopwatch = Stopwatch()..start();
      const testKey = '${_healthCheckPrefix}perf_test';
      final testData = List.generate(1000, (i) => 'performance_test_data_$i');

      await storage.setPreference(testKey, testData);
      writeStopwatch.stop();

      if (writeStopwatch.elapsedMilliseconds > 5000) { // 5 second threshold
        issues.add('Write performance slow: ${writeStopwatch.elapsedMilliseconds}ms');
      }

      // Test read performance
      final readStopwatch = Stopwatch()..start();
      final retrieved = storage.getPreference<List>(testKey);
      readStopwatch.stop();

      if (readStopwatch.elapsedMilliseconds > 1000) { // 1 second threshold
        issues.add('Read performance slow: ${readStopwatch.elapsedMilliseconds}ms');
      }

      if (retrieved?.length != testData.length) {
        issues.add('Performance test data integrity failed');
      }

      // Cleanup
      await storage.removePreference(testKey);

    } catch (e) {
      issues.add('Performance test failed: $e');
    }

    return StorageTestResult(
      isHealthy: issues.isEmpty,
      issues: issues,
    );
  }

  Future<StorageTestResult> _testDataIntegrity() async {
    final issues = <String>[];
    final storage = DesktopStorageService.instance;

    try {
      // Test data persistence across multiple operations
      const testKey = '${_healthCheckPrefix}integrity_test';
      final originalData = {
        'string': 'test_value',
        'number': 42,
        'boolean': true,
        'list': [1, 2, 3],
        'map': {'nested': 'value'},
      };

      // Write data
      await storage.setPreference(testKey, originalData);

      // Read it back multiple times to test consistency
      for (int i = 0; i < 5; i++) {
        final retrieved = storage.getPreference<Map>(testKey);
        if (retrieved == null) {
          issues.add('Data disappeared after $i reads');
          break;
        }

        // Verify structure integrity
        if (retrieved['string'] != originalData['string'] ||
            retrieved['number'] != originalData['number'] ||
            retrieved['boolean'] != originalData['boolean']) {
          issues.add('Data corruption detected in basic types');
          break;
        }

        // Small delay between reads
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Cleanup
      await storage.removePreference(testKey);

    } catch (e) {
      issues.add('Integrity test failed: $e');
    }

    return StorageTestResult(
      isHealthy: issues.isEmpty,
      issues: issues,
    );
  }

  Future<StorageTestResult> _testStorageCapacity() async {
    final issues = <String>[];

    try {
      // Test if we can write a reasonable amount of data
      final storage = DesktopStorageService.instance;
      const testKey = '${_healthCheckPrefix}capacity_test';

      // Generate 1MB of test data
      final largeData = List.generate(10000, (i) => 'capacity_test_data_$i' * 10);

      final stopwatch = Stopwatch()..start();
      await storage.setPreference(testKey, largeData);
      stopwatch.stop();

      // If it takes too long, might indicate capacity issues
      if (stopwatch.elapsedMilliseconds > 10000) { // 10 second threshold
        issues.add('Large data write extremely slow, possible capacity issue');
      }

      // Try to read it back
      final retrieved = storage.getPreference<List>(testKey);
      if (retrieved == null || retrieved.length != largeData.length) {
        issues.add('Large data storage/retrieval failed');
      }

      // Cleanup
      await storage.removePreference(testKey);

    } catch (e) {
      if (e.toString().contains('space') || e.toString().contains('capacity')) {
        issues.add('Storage capacity exceeded: $e');
      } else {
        issues.add('Capacity test failed: $e');
      }
    }

    return StorageTestResult(
      isHealthy: issues.isEmpty,
      issues: issues,
    );
  }

  Future<StorageTestResult> _testFallbackSystems() async {
    final issues = <String>[];

    try {
      // Test that our fallback systems are working
      // This validates that file/secure storage properly falls back to preferences

      final validationResult = await SafeStorageManager.instance.validateStorage();

      if (!validationResult.preferencesValid) {
        issues.add('Preferences fallback system not working');
      }

      if (!validationResult.hiveValid) {
        issues.add('Hive storage system not working');
      }

      // The fact that file and secure "work" (via fallback) is good
      if (!validationResult.fileSystemValid) {
        issues.add('File system fallback not working');
      }

      if (!validationResult.secureStorageValid) {
        issues.add('Secure storage fallback not working');
      }

    } catch (e) {
      issues.add('Fallback system test failed: $e');
    }

    return StorageTestResult(
      isHealthy: issues.isEmpty,
      issues: issues,
    );
  }

  StorageHealth _calculateOverallHealth(StorageHealthReport report) {
    final criticalIssues = report.issues.where((i) => i.severity == StorageIssueSeverity.critical).length;
    final warningIssues = report.issues.where((i) => i.severity == StorageIssueSeverity.warning).length;

    if (criticalIssues > 0) {
      return StorageHealth.critical;
    } else if (warningIssues > 2) {
      return StorageHealth.degraded;
    } else if (warningIssues > 0) {
      return StorageHealth.warning;
    } else {
      return StorageHealth.healthy;
    }
  }

  /// Get recent health issues for trend analysis
  List<StorageHealthIssue> getRecentIssues() => List.unmodifiable(_recentIssues);

  void dispose() {
    stopMonitoring();
  }
}

class StorageHealthReport {
  StorageTestResult? connectivity;
  StorageTestResult? performance;
  StorageTestResult? integrity;
  StorageTestResult? capacity;
  StorageTestResult? fallbacks;
  List<StorageHealthIssue> issues = [];
  StorageHealth overallHealth = StorageHealth.unknown;

  @override
  String toString() {
    return 'StorageHealthReport(health: $overallHealth, issues: ${issues.length})';
  }
}

class StorageTestResult {
  final bool isHealthy;
  final List<String> issues;

  StorageTestResult({required this.isHealthy, required this.issues});
}

class StorageHealthIssue {
  final StorageIssueType type;
  final StorageIssueSeverity severity;
  final String message;
  final DateTime timestamp;

  StorageHealthIssue({
    required this.type,
    required this.severity,
    required this.message,
  }) : timestamp = DateTime.now();

  @override
  String toString() => '[$severity] $type: $message';
}

enum StorageHealth {
  healthy,
  warning,
  degraded,
  critical,
  unknown,
}

enum StorageIssueType {
  connectivity,
  performance,
  integrity,
  capacity,
  fallback,
  system,
}

enum StorageIssueSeverity {
  info,
  warning,
  critical,
}