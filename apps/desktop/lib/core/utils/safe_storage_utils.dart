import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import '../services/desktop/desktop_storage_service.dart';

class StorageResult<T> {
  final bool success;
  final T? data;
  final String? error;
  final bool wasCorrupted;
  final bool wasRestored;
  
  const StorageResult({
    required this.success,
    this.data,
    this.error,
    this.wasCorrupted = false,
    this.wasRestored = false,
  });
  
  factory StorageResult.success(T data) {
    return StorageResult(success: true, data: data);
  }
  
  factory StorageResult.error(String error) {
    return StorageResult(success: false, error: error);
  }
  
  factory StorageResult.corrupted(String error, {bool wasRestored = false, T? restoredData}) {
    return StorageResult(
      success: wasRestored,
      data: restoredData,
      error: error,
      wasCorrupted: true,
      wasRestored: wasRestored,
    );
  }
}

/// Safe storage wrapper with corruption detection, backup, and recovery
class SafeStorageUtils {
  static const String BACKUP_SUFFIX = '_backup';
  static const String CHECKSUM_SUFFIX = '_checksum';
  static const int MAX_BACKUP_VERSIONS = 3;
  
  /// Safely stores data with automatic backup and checksum generation
  static Future<StorageResult<void>> safePut<T>(
    String boxName,
    String key,
    T value, {
    StorageType storageType = StorageType.hive,
  }) async {
    try {
      // Create backup of existing data before overwriting
      await _createBackup(boxName, key, storageType);
      
      // Serialize value for checksum calculation
      final serializedValue = _serializeValue(value);
      final checksum = _calculateChecksum(serializedValue);
      
      // Store data with metadata
      final dataWithChecksum = {
        'data': value,
        'checksum': checksum,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'version': 1,
      };
      
      // Store main data
      await _storeData(boxName, key, dataWithChecksum, storageType);
      
      // Store separate checksum for verification
      await _storeData(boxName, '$key$CHECKSUM_SUFFIX', checksum, storageType);
      
      return StorageResult.success(null);
    } catch (e) {
      return StorageResult.error('Failed to store data: $e');
    }
  }
  
  /// Safely retrieves data with corruption detection and recovery
  static Future<StorageResult<T?>> safeGet<T>(
    String boxName,
    String key, {
    T? defaultValue,
    StorageType storageType = StorageType.hive,
  }) async {
    try {
      // Attempt to read main data
      final dataResult = await _retrieveData(boxName, key, storageType);
      
      if (dataResult == null) {
        // No data found, try to restore from backup
        final backupResult = await _restoreFromBackup<T>(boxName, key, storageType);
        if (backupResult.success) {
          return StorageResult.corrupted(
            'Main data not found, restored from backup',
            wasRestored: true,
            restoredData: backupResult.data,
          );
        }
        return StorageResult.success(defaultValue);
      }
      
      // Validate data integrity
      final validationResult = await _validateDataIntegrity(dataResult, boxName, key, storageType);
      
      if (validationResult.isValid) {
        // Data is valid, extract the actual value
        final data = dataResult['data'] as T?;
        return StorageResult.success(data);
      } else {
        // Data is corrupted, attempt recovery
        print('⚠️ Data corruption detected in $boxName:$key - ${validationResult.error}');
        final recoveryResult = await _handleCorruption<T>(boxName, key, storageType);
        return recoveryResult;
      }
    } catch (e) {
      // Critical error, attempt recovery
      print('❌ Critical error reading $boxName:$key - $e');
      final recoveryResult = await _handleCorruption<T>(boxName, key, storageType);
      if (recoveryResult.success) {
        return recoveryResult;
      }
      return StorageResult.error('Failed to read data: $e');
    }
  }
  
  /// Safely removes data and its associated metadata
  static Future<StorageResult<void>> safeRemove(
    String boxName,
    String key, {
    StorageType storageType = StorageType.hive,
  }) async {
    try {
      // Create final backup before deletion
      await _createBackup(boxName, key, storageType);
      
      // Remove main data
      await _removeData(boxName, key, storageType);
      
      // Remove checksum
      await _removeData(boxName, '$key$CHECKSUM_SUFFIX', storageType);
      
      return StorageResult.success(null);
    } catch (e) {
      return StorageResult.error('Failed to remove data: $e');
    }
  }
  
  /// Validates data integrity
  static ValidationResult _validateDataIntegrity(
    Map<String, dynamic> data,
    String boxName,
    String key,
    StorageType storageType,
  ) {
    try {
      // Check if data has required metadata
      if (!data.containsKey('data') || !data.containsKey('checksum')) {
        return ValidationResult(
          isValid: false,
          error: 'Missing required metadata (data/checksum)',
        );
      }
      
      // Extract values
      final actualData = data['data'];
      final storedChecksum = data['checksum'] as String;
      
      // Calculate current checksum
      final serializedData = _serializeValue(actualData);
      final calculatedChecksum = _calculateChecksum(serializedData);
      
      // Compare checksums
      if (storedChecksum != calculatedChecksum) {
        return ValidationResult(
          isValid: false,
          error: 'Checksum mismatch - stored: $storedChecksum, calculated: $calculatedChecksum',
        );
      }
      
      // Check timestamp validity
      if (data.containsKey('timestamp')) {
        final timestamp = data['timestamp'] as int?;
        if (timestamp != null) {
          final dataAge = DateTime.now().millisecondsSinceEpoch - timestamp;
          if (dataAge < 0) {
            return ValidationResult(
              isValid: false,
              error: 'Future timestamp detected - possible corruption',
            );
          }
        }
      }
      
      return ValidationResult(isValid: true);
    } catch (e) {
      return ValidationResult(
        isValid: false,
        error: 'Validation error: $e',
      );
    }
  }
  
  /// Handles corruption by attempting various recovery strategies
  static Future<StorageResult<T?>> _handleCorruption<T>(
    String boxName,
    String key,
    StorageType storageType,
  ) async {
    print('🔧 Attempting corruption recovery for $boxName:$key');
    
    // Strategy 1: Try to restore from most recent backup
    final backupResult = await _restoreFromBackup<T>(boxName, key, storageType);
    if (backupResult.success) {
      print('✅ Successfully restored from backup');
      return StorageResult.corrupted(
        'Data was corrupted but restored from backup',
        wasRestored: true,
        restoredData: backupResult.data,
      );
    }
    
    // Strategy 2: Try older backup versions
    for (int version = 1; version < MAX_BACKUP_VERSIONS; version++) {
      final olderBackupResult = await _restoreFromBackup<T>(
        boxName, 
        key, 
        storageType, 
        version: version,
      );
      if (olderBackupResult.success) {
        print('✅ Successfully restored from backup version $version');
        return StorageResult.corrupted(
          'Data was corrupted but restored from backup version $version',
          wasRestored: true,
          restoredData: olderBackupResult.data,
        );
      }
    }
    
    // Strategy 3: Delete corrupted data and return null
    try {
      await _removeData(boxName, key, storageType);
      await _removeData(boxName, '$key$CHECKSUM_SUFFIX', storageType);
      print('🗑️ Removed corrupted data');
    } catch (e) {
      print('⚠️ Failed to clean up corrupted data: $e');
    }
    
    return StorageResult.corrupted('Data was corrupted and could not be recovered');
  }
  
  /// Creates a backup of existing data
  static Future<void> _createBackup(
    String boxName,
    String key,
    StorageType storageType,
  ) async {
    try {
      final existingData = await _retrieveData(boxName, key, storageType);
      if (existingData != null) {
        // Rotate existing backups
        await _rotateBackups(boxName, key, storageType);
        
        // Create new backup
        final backupKey = '$key$BACKUP_SUFFIX';
        await _storeData(boxName, backupKey, existingData, storageType);
      }
    } catch (e) {
      print('⚠️ Failed to create backup for $boxName:$key - $e');
      // Don't fail the main operation due to backup failure
    }
  }
  
  /// Rotates backup versions
  static Future<void> _rotateBackups(
    String boxName,
    String key,
    StorageType storageType,
  ) async {
    try {
      // Move backups: backup -> backup_1, backup_1 -> backup_2, etc.
      for (int i = MAX_BACKUP_VERSIONS - 1; i > 0; i--) {
        final fromKey = i == 1 ? '$key$BACKUP_SUFFIX' : '${key}${BACKUP_SUFFIX}_${i-1}';
        final toKey = '${key}${BACKUP_SUFFIX}_$i';
        
        final backupData = await _retrieveData(boxName, fromKey, storageType);
        if (backupData != null) {
          await _storeData(boxName, toKey, backupData, storageType);
        }
      }
      
      // Remove the oldest backup if it exists
      final oldestBackupKey = '${key}${BACKUP_SUFFIX}_${MAX_BACKUP_VERSIONS}';
      await _removeData(boxName, oldestBackupKey, storageType);
    } catch (e) {
      print('⚠️ Failed to rotate backups for $boxName:$key - $e');
    }
  }
  
  /// Restores data from backup
  static Future<StorageResult<T?>> _restoreFromBackup<T>(
    String boxName,
    String key,
    StorageType storageType, {
    int version = 0,
  }) async {
    try {
      final backupKey = version == 0 
        ? '$key$BACKUP_SUFFIX'
        : '${key}${BACKUP_SUFFIX}_$version';
      
      final backupData = await _retrieveData(boxName, backupKey, storageType);
      if (backupData == null) {
        return StorageResult.error('No backup found');
      }
      
      // Validate backup integrity
      final validationResult = _validateDataIntegrity(backupData, boxName, backupKey, storageType);
      if (!validationResult.isValid) {
        return StorageResult.error('Backup is also corrupted: ${validationResult.error}');
      }
      
      // Restore the data
      await _storeData(boxName, key, backupData, storageType);
      
      final restoredData = backupData['data'] as T?;
      return StorageResult.success(restoredData);
    } catch (e) {
      return StorageResult.error('Failed to restore from backup: $e');
    }
  }
  
  /// Storage abstraction methods
  static Future<void> _storeData(
    String boxName,
    String key,
    dynamic value,
    StorageType storageType,
  ) async {
    switch (storageType) {
      case StorageType.hive:
        await DesktopStorageService.instance.setHiveData(boxName, key, value);
        break;
      case StorageType.preferences:
        await DesktopStorageService.instance.setPreference(key, value);
        break;
      case StorageType.file:
        // File storage implementation would go here
        throw UnimplementedError('File storage not implemented');
      case StorageType.secure:
        // Secure storage implementation would go here
        throw UnimplementedError('Secure storage not implemented');
    }
  }
  
  static Future<dynamic> _retrieveData(
    String boxName,
    String key,
    StorageType storageType,
  ) async {
    switch (storageType) {
      case StorageType.hive:
        return DesktopStorageService.instance.getHiveData(boxName, key);
      case StorageType.preferences:
        return DesktopStorageService.instance.getPreference(key);
      case StorageType.file:
        // File storage implementation would go here
        throw UnimplementedError('File storage not implemented');
      case StorageType.secure:
        // Secure storage implementation would go here
        throw UnimplementedError('Secure storage not implemented');
    }
  }
  
  static Future<void> _removeData(
    String boxName,
    String key,
    StorageType storageType,
  ) async {
    switch (storageType) {
      case StorageType.hive:
        await DesktopStorageService.instance.removeHiveData(boxName, key);
        break;
      case StorageType.preferences:
        await DesktopStorageService.instance.removePreference(key);
        break;
      case StorageType.file:
        // File storage implementation would go here
        throw UnimplementedError('File storage not implemented');
      case StorageType.secure:
        // Secure storage implementation would go here
        throw UnimplementedError('Secure storage not implemented');
    }
  }
  
  /// Utility methods
  static String _serializeValue(dynamic value) {
    try {
      return json.encode(value);
    } catch (e) {
      return value.toString();
    }
  }
  
  static String _calculateChecksum(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Health check for storage subsystem
  static Future<StorageHealthResult> performHealthCheck() async {
    final results = <String, bool>{};
    final errors = <String>[];
    
    try {
      // Test basic storage operations
      const testKey = '__health_check_test__';
      const testData = {'test': true, 'timestamp': 12345};
      
      // Test Hive storage
      try {
        final putResult = await safePut('settings', testKey, testData);
        final getResult = await safeGet<Map<String, dynamic>>('settings', testKey);
        final removeResult = await safeRemove('settings', testKey);
        
        results['hive'] = putResult.success && getResult.success && removeResult.success;
        if (!results['hive']!) {
          errors.add('Hive operations failed');
        }
      } catch (e) {
        results['hive'] = false;
        errors.add('Hive test error: $e');
      }
      
      // Test SharedPreferences storage
      try {
        final putResult = await safePut('', testKey, testData, storageType: StorageType.preferences);
        final getResult = await safeGet<Map<String, dynamic>>('', testKey, storageType: StorageType.preferences);
        final removeResult = await safeRemove('', testKey, storageType: StorageType.preferences);
        
        results['preferences'] = putResult.success && getResult.success && removeResult.success;
        if (!results['preferences']!) {
          errors.add('SharedPreferences operations failed');
        }
      } catch (e) {
        results['preferences'] = false;
        errors.add('SharedPreferences test error: $e');
      }
      
    } catch (e) {
      errors.add('Health check error: $e');
    }
    
    final isHealthy = results.values.any((result) => result);
    
    return StorageHealthResult(
      isHealthy: isHealthy,
      subsystemResults: results,
      errors: errors,
      timestamp: DateTime.now(),
    );
  }
}

class ValidationResult {
  final bool isValid;
  final String? error;
  
  const ValidationResult({
    required this.isValid,
    this.error,
  });
}

class StorageHealthResult {
  final bool isHealthy;
  final Map<String, bool> subsystemResults;
  final List<String> errors;
  final DateTime timestamp;
  
  const StorageHealthResult({
    required this.isHealthy,
    required this.subsystemResults,
    required this.errors,
    required this.timestamp,
  });
  
  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Storage Health Check Results:');
    buffer.writeln('Overall Status: ${isHealthy ? '✅ Healthy' : '❌ Unhealthy'}');
    
    for (final entry in subsystemResults.entries) {
      final status = entry.value ? '✅' : '❌';
      buffer.writeln('  ${entry.key}: $status');
    }
    
    if (errors.isNotEmpty) {
      buffer.writeln('Errors:');
      for (final error in errors) {
        buffer.writeln('  • $error');
      }
    }
    
    return buffer.toString();
  }
}