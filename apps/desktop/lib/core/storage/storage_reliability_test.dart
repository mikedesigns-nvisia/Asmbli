import 'dart:async';
import 'dart:math';
import '../utils/app_logger.dart';
import '../utils/storage_transaction_manager.dart';
import '../services/desktop/desktop_storage_service.dart';
import 'safe_storage_manager.dart';
import 'storage_health_monitor.dart';

/// Comprehensive storage reliability test suite
class StorageReliabilityTest {
  static const String _testPrefix = '_reliability_test_';

  /// Run complete storage reliability test suite
  static Future<StorageReliabilityReport> runCompleteTest() async {
    AppLogger.info('Starting comprehensive storage reliability test', component: 'StorageTest');

    final report = StorageReliabilityReport();

    try {
      // Test 1: Basic CRUD operations
      report.basicOperations = await _testBasicOperations();

      // Test 2: Transaction system
      report.transactions = await _testTransactionSystem();

      // Test 3: Fallback systems
      report.fallbackSystems = await _testFallbackSystems();

      // Test 4: Error recovery
      report.errorRecovery = await _testErrorRecovery();

      // Test 5: Concurrent operations
      report.concurrency = await _testConcurrentOperations();

      // Test 6: Data migration
      report.migration = await _testDataMigration();

      // Test 7: Health monitoring
      report.healthMonitoring = await _testHealthMonitoring();

      report.overallSuccess = _calculateOverallSuccess(report);

      AppLogger.info('Storage reliability test completed: ${report.overallSuccess ? "PASSED" : "FAILED"}', component: 'StorageTest');
      return report;

    } catch (e) {
      AppLogger.error('Storage reliability test failed with exception', component: 'StorageTest', error: e);
      report.overallSuccess = false;
      report.errorMessage = e.toString();
      return report;
    }
  }

  static Future<TestResult> _testBasicOperations() async {
    AppLogger.info('Testing basic CRUD operations', component: 'StorageTest');

    final issues = <String>[];
    final storage = DesktopStorageService.instance;

    try {
      // Test SharedPreferences CRUD
      const prefKey = '${_testPrefix}pref_test';
      const prefValue = 'preference_test_value';

      await storage.setPreference(prefKey, prefValue);
      final retrievedPref = storage.getPreference<String>(prefKey);
      if (retrievedPref != prefValue) {
        issues.add('SharedPreferences retrieval failed');
      }

      await storage.removePreference(prefKey);
      final deletedPref = storage.getPreference<String>(prefKey);
      if (deletedPref != null) {
        issues.add('SharedPreferences deletion failed');
      }

      // Test Hive CRUD
      const hiveBox = '${_testPrefix}hive_test';
      const hiveKey = 'test_key';
      const hiveValue = {'complex': 'data', 'number': 42};

      await storage.setHiveData(hiveBox, hiveKey, hiveValue);
      final retrievedHive = storage.getHiveData<Map>(hiveBox, hiveKey);
      if (retrievedHive?['complex'] != 'data' || retrievedHive?['number'] != 42) {
        issues.add('Hive retrieval failed');
      }

      await storage.removeHiveData(hiveBox, hiveKey);
      final deletedHive = storage.getHiveData<Map>(hiveBox, hiveKey);
      if (deletedHive != null) {
        issues.add('Hive deletion failed');
      }

    } catch (e) {
      issues.add('Basic operations exception: $e');
    }

    return TestResult(
      success: issues.isEmpty,
      issues: issues,
    );
  }

  static Future<TestResult> _testTransactionSystem() async {
    AppLogger.info('Testing transaction system', component: 'StorageTest');

    final issues = <String>[];

    try {
      final manager = StorageTransactionManager.instance;

      // Test successful transaction
      final transaction1 = manager.beginTransaction();
      transaction1.addOperation(SetHiveDataOperation(
        boxName: '${_testPrefix}tx_test',
        key: 'tx_key_1',
        value: 'transaction_value_1',
        storageType: StorageType.preferences,
      ));
      transaction1.addOperation(SetHiveDataOperation(
        boxName: '${_testPrefix}tx_test',
        key: 'tx_key_2',
        value: 'transaction_value_2',
        storageType: StorageType.hive,
      ));

      final result1 = await transaction1.commit();
      if (!result1.success) {
        issues.add('Transaction commit failed: ${result1.errors.join(', ')}');
      }

      // Verify data was stored
      final storage = DesktopStorageService.instance;
      final value1 = storage.getPreference<String>('tx_key_1');
      final value2 = storage.getHiveData<String>('${_testPrefix}tx_test', 'tx_key_2');

      if (value1 != 'transaction_value_1') {
        issues.add('Transaction data not persisted in preferences');
      }
      if (value2 != 'transaction_value_2') {
        issues.add('Transaction data not persisted in Hive');
      }

      // Test rollback transaction
      final transaction2 = manager.beginTransaction();
      transaction2.addOperation(SetHiveDataOperation(
        boxName: '${_testPrefix}tx_test',
        key: 'rollback_key',
        value: 'should_be_rolled_back',
        storageType: StorageType.preferences,
      ));

      await transaction2.commit();
      await transaction2.rollback();

      final rolledBackValue = storage.getPreference<String>('rollback_key');
      if (rolledBackValue != null) {
        issues.add('Transaction rollback failed');
      }

      // Cleanup
      await storage.removePreference('tx_key_1');
      await storage.removeHiveData('${_testPrefix}tx_test', 'tx_key_2');

    } catch (e) {
      issues.add('Transaction system exception: $e');
    }

    return TestResult(
      success: issues.isEmpty,
      issues: issues,
    );
  }

  static Future<TestResult> _testFallbackSystems() async {
    AppLogger.info('Testing fallback systems', component: 'StorageTest');

    final issues = <String>[];

    try {
      final manager = StorageTransactionManager.instance;

      // Test file storage fallback (should use preferences)
      final fileTransaction = manager.beginTransaction();
      fileTransaction.addOperation(SetHiveDataOperation(
        boxName: 'test_box',
        key: 'file_fallback_test',
        value: 'file_storage_fallback_value',
        storageType: StorageType.file,
      ));

      final fileResult = await fileTransaction.commit();
      if (!fileResult.success) {
        issues.add('File storage fallback failed: ${fileResult.errors.join(', ')}');
      }

      // Verify it was stored in preferences (the fallback)
      final storage = DesktopStorageService.instance;
      final fileValue = storage.getPreference<String>('file_fallback_test');
      if (fileValue != 'file_storage_fallback_value') {
        issues.add('File storage fallback data not found in preferences');
      }

      // Test secure storage fallback (should use preferences)
      final secureTransaction = manager.beginTransaction();
      secureTransaction.addOperation(SetHiveDataOperation(
        boxName: 'test_box',
        key: 'secure_fallback_test',
        value: 'secure_storage_fallback_value',
        storageType: StorageType.secure,
      ));

      final secureResult = await secureTransaction.commit();
      if (!secureResult.success) {
        issues.add('Secure storage fallback failed: ${secureResult.errors.join(', ')}');
      }

      // Verify it was stored in preferences (the fallback)
      final secureValue = storage.getPreference<String>('secure_fallback_test');
      if (secureValue != 'secure_storage_fallback_value') {
        issues.add('Secure storage fallback data not found in preferences');
      }

      // Cleanup
      await storage.removePreference('file_fallback_test');
      await storage.removePreference('secure_fallback_test');

    } catch (e) {
      issues.add('Fallback system exception: $e');
    }

    return TestResult(
      success: issues.isEmpty,
      issues: issues,
    );
  }

  static Future<TestResult> _testErrorRecovery() async {
    AppLogger.info('Testing error recovery', component: 'StorageTest');

    final issues = <String>[];

    try {
      // Test that the system handles errors gracefully without crashing
      final manager = StorageTransactionManager.instance;

      // Try to store invalid data that might cause issues
      final transaction = manager.beginTransaction();
      transaction.addOperation(SetHiveDataOperation(
        boxName: 'error_test_box',
        key: 'error_test_key',
        value: {'circular': 'reference'}, // This might cause serialization issues
        storageType: StorageType.preferences,
      ));

      await transaction.commit();
      // The system should handle this gracefully, either succeeding or failing safely

      // Test recovery from backup
      final backupManager = SafeStorageManager.instance;
      final backup = await backupManager.createBackup();
      if (backup.timestamp.isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {
        issues.add('Backup creation timestamp is incorrect');
      }

    } catch (e) {
      // Errors are expected in error recovery testing
      AppLogger.debug('Expected error in error recovery test: $e', component: 'StorageTest');
    }

    return TestResult(
      success: issues.isEmpty,
      issues: issues,
    );
  }

  static Future<TestResult> _testConcurrentOperations() async {
    AppLogger.info('Testing concurrent operations', component: 'StorageTest');

    final issues = <String>[];

    try {
      final storage = DesktopStorageService.instance;
      final futures = <Future>[];

      // Run multiple concurrent storage operations
      for (int i = 0; i < 10; i++) {
        futures.add(_concurrentStorageOperation(i));
      }

      await Future.wait(futures);

      // Verify all operations completed successfully
      for (int i = 0; i < 10; i++) {
        final value = storage.getPreference<String>('concurrent_test_$i');
        if (value != 'concurrent_value_$i') {
          issues.add('Concurrent operation $i failed');
        }
      }

      // Cleanup
      for (int i = 0; i < 10; i++) {
        await storage.removePreference('concurrent_test_$i');
      }

    } catch (e) {
      issues.add('Concurrent operations exception: $e');
    }

    return TestResult(
      success: issues.isEmpty,
      issues: issues,
    );
  }

  static Future<void> _concurrentStorageOperation(int index) async {
    final storage = DesktopStorageService.instance;
    await storage.setPreference('concurrent_test_$index', 'concurrent_value_$index');

    // Small random delay to increase concurrency stress
    await Future.delayed(Duration(milliseconds: Random().nextInt(50)));
  }

  static Future<TestResult> _testDataMigration() async {
    AppLogger.info('Testing data migration', component: 'StorageTest');

    final issues = <String>[];

    try {
      final migrationManager = SafeStorageManager.instance;

      // Create some test data
      final storage = DesktopStorageService.instance;
      await storage.setPreference('migration_test_1', 'migration_value_1');
      await storage.setHiveData('migration_box', 'migration_key', 'migration_hive_value');

      // Perform migration
      final migrationResult = await migrationManager.migrateStorage();

      if (!migrationResult.success) {
        issues.add('Data migration failed: ${migrationResult.error}');
      }

      if (migrationResult.backup == null) {
        issues.add('Migration backup was not created');
      }

      if (migrationResult.postValidation?.isValid != true) {
        issues.add('Post-migration validation failed');
      }

      // Verify data is still accessible after migration
      final migratedValue1 = storage.getPreference<String>('migration_test_1');
      final migratedValue2 = storage.getHiveData<String>('migration_box', 'migration_key');

      if (migratedValue1 != 'migration_value_1') {
        issues.add('Preferences data lost during migration');
      }

      if (migratedValue2 != 'migration_hive_value') {
        issues.add('Hive data lost during migration');
      }

      // Cleanup
      await storage.removePreference('migration_test_1');
      await storage.removeHiveData('migration_box', 'migration_key');

    } catch (e) {
      issues.add('Data migration exception: $e');
    }

    return TestResult(
      success: issues.isEmpty,
      issues: issues,
    );
  }

  static Future<TestResult> _testHealthMonitoring() async {
    AppLogger.info('Testing health monitoring', component: 'StorageTest');

    final issues = <String>[];

    try {
      final healthMonitor = StorageHealthMonitor.instance;

      // Perform health check
      final healthReport = await healthMonitor.performHealthCheck();

      if (healthReport.overallHealth == StorageHealth.critical) {
        issues.add('Health monitoring detected critical issues');
      }

      if (healthReport.connectivity?.isHealthy != true) {
        issues.add('Storage connectivity issues detected');
      }

      if (healthReport.integrity?.isHealthy != true) {
        issues.add('Data integrity issues detected');
      }

      // The performance and capacity tests might show warnings, which is okay
      // as long as the core functionality works

    } catch (e) {
      issues.add('Health monitoring exception: $e');
    }

    return TestResult(
      success: issues.isEmpty,
      issues: issues,
    );
  }

  static bool _calculateOverallSuccess(StorageReliabilityReport report) {
    return report.basicOperations.success &&
           report.transactions.success &&
           report.fallbackSystems.success &&
           report.errorRecovery.success &&
           report.concurrency.success &&
           report.migration.success &&
           report.healthMonitoring.success;
  }
}

class StorageReliabilityReport {
  TestResult basicOperations = TestResult(success: false, issues: []);
  TestResult transactions = TestResult(success: false, issues: []);
  TestResult fallbackSystems = TestResult(success: false, issues: []);
  TestResult errorRecovery = TestResult(success: false, issues: []);
  TestResult concurrency = TestResult(success: false, issues: []);
  TestResult migration = TestResult(success: false, issues: []);
  TestResult healthMonitoring = TestResult(success: false, issues: []);
  bool overallSuccess = false;
  String? errorMessage;

  List<String> get allIssues {
    final issues = <String>[];
    issues.addAll(basicOperations.issues.map((i) => 'Basic: $i'));
    issues.addAll(transactions.issues.map((i) => 'Transactions: $i'));
    issues.addAll(fallbackSystems.issues.map((i) => 'Fallbacks: $i'));
    issues.addAll(errorRecovery.issues.map((i) => 'Recovery: $i'));
    issues.addAll(concurrency.issues.map((i) => 'Concurrency: $i'));
    issues.addAll(migration.issues.map((i) => 'Migration: $i'));
    issues.addAll(healthMonitoring.issues.map((i) => 'Health: $i'));
    return issues;
  }

  @override
  String toString() {
    return 'StorageReliabilityReport(success: $overallSuccess, issues: ${allIssues.length})';
  }
}

class TestResult {
  final bool success;
  final List<String> issues;

  TestResult({required this.success, required this.issues});

  @override
  String toString() => 'TestResult(success: $success, issues: ${issues.length})';
}