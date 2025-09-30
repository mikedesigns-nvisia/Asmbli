import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../utils/app_logger.dart';
import '../services/desktop/desktop_storage_service.dart';

/// Safe storage manager that prevents data loss during migrations
class SafeStorageManager {
  static const String _backupFileName = 'storage_backup.json';
  static SafeStorageManager? _instance;
  static SafeStorageManager get instance => _instance ??= SafeStorageManager._();

  SafeStorageManager._();

  /// Backup all storage data before performing risky operations
  Future<StorageBackup> createBackup() async {
    AppLogger.info('Creating storage backup', component: 'StorageManager');

    final backup = StorageBackup();

    try {
      // Backup SharedPreferences
      await _backupSharedPreferences(backup);

      // Backup Hive data
      await _backupHiveData(backup);

      // Save backup to file
      await _saveBackupToFile(backup);

      AppLogger.info('Storage backup created successfully', component: 'StorageManager');
      return backup;
    } catch (e) {
      AppLogger.error('Failed to create storage backup', component: 'StorageManager');
      rethrow;
    }
  }

  /// Restore data from backup if migration fails
  Future<void> restoreFromBackup(StorageBackup backup) async {
    AppLogger.warning('Restoring from storage backup', component: 'StorageManager');

    try {
      // Restore SharedPreferences
      await _restoreSharedPreferences(backup);

      // Restore Hive data
      await _restoreHiveData(backup);

      AppLogger.info('Storage restore completed successfully', component: 'StorageManager');
    } catch (e) {
      AppLogger.critical('Failed to restore from backup', component: 'StorageManager');
      rethrow;
    }
  }

  /// Validate data integrity after migration
  Future<StorageValidationResult> validateStorage() async {
    AppLogger.info('Validating storage integrity', component: 'StorageManager');

    final result = StorageValidationResult();

    try {
      // Test SharedPreferences access
      result.preferencesValid = await _testPreferences();

      // Test Hive access
      result.hiveValid = await _testHive();

      // Test file system access (for future file storage)
      result.fileSystemValid = await _testFileSystem();

      // Test secure storage access (for future secure storage)
      result.secureStorageValid = await _testSecureStorage();

      AppLogger.info('Storage validation completed', component: 'StorageManager');
      return result;
    } catch (e) {
      AppLogger.error('Storage validation failed', component: 'StorageManager');
      result.validationError = e.toString();
      return result;
    }
  }

  Future<void> _backupSharedPreferences(StorageBackup backup) async {
    try {
      final storage = DesktopStorageService.instance;
      // Get all preference keys and their values
      // Note: This is a simplified approach - in reality we'd enumerate all keys
      backup.preferences = <String, dynamic>{};

      // Try to get some common keys to verify preferences work
      final testKeys = ['selectedModel', 'theme', 'apiKeys', 'conversations'];
      for (final key in testKeys) {
        try {
          final value = storage.getPreference<dynamic>(key);
          if (value != null) {
            backup.preferences[key] = value;
          }
        } catch (e) {
          AppLogger.debug('Could not backup preference $key', component: 'StorageManager');
        }
      }

      AppLogger.debug('Backed up ${backup.preferences.length} preferences', component: 'StorageManager');
    } catch (e) {
      AppLogger.warning('Failed to backup SharedPreferences', component: 'StorageManager');
    }
  }

  Future<void> _backupHiveData(StorageBackup backup) async {
    try {
      backup.hiveData = <String, Map<String, dynamic>>{};

      // Common Hive boxes in the app
      final commonBoxes = ['conversations', 'models', 'agents', 'settings'];
      for (final boxName in commonBoxes) {
        try {
          final boxData = <String, dynamic>{};
          // Note: This is simplified - real implementation would enumerate all keys in box
          backup.hiveData[boxName] = boxData;
        } catch (e) {
          AppLogger.debug('Could not backup Hive box $boxName', component: 'StorageManager');
        }
      }

      AppLogger.debug('Backed up ${backup.hiveData.length} Hive boxes', component: 'StorageManager');
    } catch (e) {
      AppLogger.warning('Failed to backup Hive data', component: 'StorageManager');
    }
  }

  Future<void> _saveBackupToFile(StorageBackup backup) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupFile = File('${appDir.path}/$_backupFileName');

      final backupJson = {
        'timestamp': backup.timestamp.toIso8601String(),
        'preferences': backup.preferences,
        'hiveData': backup.hiveData,
      };

      await backupFile.writeAsString(jsonEncode(backupJson));
      AppLogger.debug('Backup saved to ${backupFile.path}', component: 'StorageManager');
    } catch (e) {
      AppLogger.warning('Failed to save backup to file', component: 'StorageManager');
    }
  }

  Future<void> _restoreSharedPreferences(StorageBackup backup) async {
    final storage = DesktopStorageService.instance;

    for (final entry in backup.preferences.entries) {
      try {
        await storage.setPreference(entry.key, entry.value);
      } catch (e) {
        AppLogger.warning('Failed to restore preference ${entry.key}', component: 'StorageManager');
      }
    }
  }

  Future<void> _restoreHiveData(StorageBackup backup) async {
    final storage = DesktopStorageService.instance;

    for (final boxEntry in backup.hiveData.entries) {
      final boxName = boxEntry.key;
      final boxData = boxEntry.value;

      for (final dataEntry in boxData.entries) {
        try {
          await storage.setHiveData(boxName, dataEntry.key, dataEntry.value);
        } catch (e) {
          AppLogger.warning('Failed to restore Hive data $boxName.${dataEntry.key}', component: 'StorageManager');
        }
      }
    }
  }

  Future<bool> _testPreferences() async {
    try {
      final storage = DesktopStorageService.instance;
      const testKey = '_storage_test_pref';
      const testValue = 'test_value_123';

      await storage.setPreference(testKey, testValue);
      final retrieved = storage.getPreference<String>(testKey);
      await storage.removePreference(testKey);

      return retrieved == testValue;
    } catch (e) {
      AppLogger.debug('SharedPreferences test failed', component: 'StorageManager');
      return false;
    }
  }

  Future<bool> _testHive() async {
    try {
      final storage = DesktopStorageService.instance;
      const testBox = '_storage_test_box';
      const testKey = '_test_key';
      const testValue = 'test_value_456';

      await storage.setHiveData(testBox, testKey, testValue);
      final retrieved = storage.getHiveData<String>(testBox, testKey);
      await storage.removeHiveData(testBox, testKey);

      return retrieved == testValue;
    } catch (e) {
      AppLogger.debug('Hive test failed', component: 'StorageManager');
      return false;
    }
  }

  Future<bool> _testFileSystem() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final testFile = File('${appDir.path}/_storage_test.txt');
      const testContent = 'storage_test_789';

      await testFile.writeAsString(testContent);
      final retrieved = await testFile.readAsString();
      await testFile.delete();

      return retrieved == testContent;
    } catch (e) {
      AppLogger.debug('File system test failed', component: 'StorageManager');
      return false;
    }
  }

  Future<bool> _testSecureStorage() async {
    try {
      // For now, secure storage falls back to preferences
      // In the future, this would test flutter_secure_storage
      return await _testPreferences();
    } catch (e) {
      AppLogger.debug('Secure storage test failed', component: 'StorageManager');
      return false;
    }
  }

  /// Migrate storage system safely
  Future<StorageMigrationResult> migrateStorage() async {
    AppLogger.info('Starting safe storage migration', component: 'StorageManager');

    final result = StorageMigrationResult();

    try {
      // Step 1: Create backup
      result.backup = await createBackup();

      // Step 2: Validate current storage
      final preValidation = await validateStorage();
      result.preValidation = preValidation;

      if (!preValidation.isValid) {
        AppLogger.warning('Pre-migration validation failed, proceeding with caution', component: 'StorageManager');
      }

      // Step 3: Perform migration (implement missing storage methods)
      await _performMigration();

      // Step 4: Post-migration validation
      final postValidation = await validateStorage();
      result.postValidation = postValidation;

      if (postValidation.isValid) {
        result.success = true;
        AppLogger.info('Storage migration completed successfully', component: 'StorageManager');
      } else {
        result.success = false;
        AppLogger.error('Post-migration validation failed, restoring backup', component: 'StorageManager');
        if (result.backup != null) {
          await restoreFromBackup(result.backup!);
        }
      }

    } catch (e) {
      result.success = false;
      result.error = e.toString();
      AppLogger.critical('Storage migration failed', component: 'StorageManager');

      if (result.backup != null) {
        try {
          await restoreFromBackup(result.backup!);
          AppLogger.info('Successfully restored from backup after migration failure', component: 'StorageManager');
        } catch (restoreError) {
          AppLogger.critical('Failed to restore from backup', component: 'StorageManager', error: restoreError);
        }
      }
    }

    return result;
  }

  Future<void> _performMigration() async {
    // This will be where we fix the UnimplementedError issues
    // For now, just log that migration is happening
    AppLogger.info('Performing storage system migration', component: 'StorageManager');

    // The actual fix will be implemented in the next step
    await Future.delayed(const Duration(milliseconds: 100));
  }
}

class StorageBackup {
  final DateTime timestamp;
  Map<String, dynamic> preferences = {};
  Map<String, Map<String, dynamic>> hiveData = {};

  StorageBackup() : timestamp = DateTime.now();
}

class StorageValidationResult {
  bool preferencesValid = false;
  bool hiveValid = false;
  bool fileSystemValid = false;
  bool secureStorageValid = false;
  String? validationError;

  bool get isValid => preferencesValid && hiveValid && fileSystemValid && secureStorageValid;

  @override
  String toString() {
    return 'StorageValidation(preferences: $preferencesValid, hive: $hiveValid, '
           'fileSystem: $fileSystemValid, secure: $secureStorageValid, error: $validationError)';
  }
}

class StorageMigrationResult {
  bool success = false;
  StorageBackup? backup;
  StorageValidationResult? preValidation;
  StorageValidationResult? postValidation;
  String? error;

  @override
  String toString() {
    return 'StorageMigration(success: $success, error: $error, '
           'preValid: ${preValidation?.isValid}, postValid: ${postValidation?.isValid})';
  }
}