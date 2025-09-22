import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'file_system_service.dart';

enum StorageType {
 preferences,
 hive,
 file,
 secure,
}

class DesktopStorageService {
 static DesktopStorageService? _instance;
 static SharedPreferences? _preferences;
 static final Map<String, Box> _hiveBoxes = {};
 static bool _isInitialized = false;
 static bool _isInitializing = false;
 
 DesktopStorageService._();
 
 static DesktopStorageService get instance {
 _instance ??= DesktopStorageService._();
 return _instance!;
 }

 Future<void> initialize() async {
 // Prevent concurrent initialization
 if (_isInitialized) return;
 if (_isInitializing) {
   // Wait for ongoing initialization to complete
   while (_isInitializing) {
     await Future.delayed(const Duration(milliseconds: 100));
   }
   if (_isInitialized) return;
 }
 
 _isInitializing = true;
 
 try {
   _preferences = await SharedPreferences.getInstance();
   await _initializeHive();
   _isInitialized = true;
   print('✅ Storage service initialized');
 } catch (e) {
   print('❌ Storage initialization failed: $e');
   // Continue anyway with in-memory fallback
   _isInitialized = true; // Mark as initialized to prevent retry loops
 } finally {
   _isInitializing = false;
 }
 }

 Future<void> _initializeHive() async {
 try {
   final appDir = await DesktopFileSystemService.instance.getAsmbliDirectory();
   final hiveDir = Directory(path.join(appDir.path, 'storage'));
   
   if (!await hiveDir.exists()) {
     await hiveDir.create(recursive: true);
   }
   
   // Clean up any stale lock files
   await _cleanupLockFiles(hiveDir);
   
   await Hive.initFlutter(hiveDir.path);
   
   // Open boxes one by one with error handling
   final boxNames = ['agents', 'conversations', 'templates', 'settings', 'cache', 'user_data', 'mcp_servers', 'api_keys'];
   
   for (final boxName in boxNames) {
     try {
       await _openBox(boxName);
     } catch (e) {
       print('⚠️ Failed to open box $boxName: $e (continuing with in-memory fallback)');
     }
   }
 } catch (e) {
   print('⚠️ Hive initialization failed: $e (using SharedPreferences fallback)');
   rethrow;
 }
 }
 
 /// Clean up stale lock files that might prevent Hive from opening
 Future<void> _cleanupLockFiles(Directory hiveDir) async {
 try {
   final lockFiles = hiveDir.listSync()
       .where((file) => file.path.endsWith('.lock'))
       .cast<File>();
       
   for (final lockFile in lockFiles) {
     try {
       // Check if lock file is stale (older than 5 minutes)
       final stat = await lockFile.stat();
       final age = DateTime.now().difference(stat.modified);
       
       if (age.inMinutes > 5) {
         await lockFile.delete();
         print('🧹 Cleaned up stale lock file: ${lockFile.path}');
       }
     } catch (e) {
       // Ignore individual file cleanup errors
     }
   }
 } catch (e) {
   // Ignore cleanup errors - they're not critical
 }
 }

 Future<Box<dynamic>> _openBox<T>(String boxName) async {
 if (_hiveBoxes.containsKey(boxName)) {
   return _hiveBoxes[boxName]!;
 }
 
 // For complex types, use dynamic boxes and handle JSON serialization ourselves
 late Box<dynamic> box;
 try {
   box = await Hive.openBox(boxName);
 } catch (e) {
   print('⚠️ Failed to open Hive box $boxName: $e');
   rethrow;
 }
 
 _hiveBoxes[boxName] = box;
 return box;
 }

 Future<void> setPreference<T>(String key, T value) async {
 if (_preferences == null) {
 throw Exception('Storage not initialized');
 }

 switch (T) {
 case String:
 await _preferences!.setString(key, value as String);
 break;
 case int:
 await _preferences!.setInt(key, value as int);
 break;
 case double:
 await _preferences!.setDouble(key, value as double);
 break;
 case bool:
 await _preferences!.setBool(key, value as bool);
 break;
 case const (List<String>):
 await _preferences!.setStringList(key, value as List<String>);
 break;
 default:
 await _preferences!.setString(key, jsonEncode(value));
 }
 }

 T? getPreference<T>(String key, {T? defaultValue}) {
 if (_preferences == null) {
 return defaultValue;
 }

 switch (T) {
 case String:
 return _preferences!.getString(key) as T? ?? defaultValue;
 case int:
 return _preferences!.getInt(key) as T? ?? defaultValue;
 case double:
 return _preferences!.getDouble(key) as T? ?? defaultValue;
 case bool:
 return _preferences!.getBool(key) as T? ?? defaultValue;
 case const (List<String>):
 return _preferences!.getStringList(key) as T? ?? defaultValue;
 default:
 final jsonString = _preferences!.getString(key);
 if (jsonString != null) {
 try {
 return jsonDecode(jsonString) as T;
 } catch (e) {
 return defaultValue;
 }
 }
 return defaultValue;
 }
 }

 Future<void> removePreference(String key) async {
 if (_preferences != null) {
 await _preferences!.remove(key);
 }
 }

 Future<void> clearPreferences() async {
 if (_preferences != null) {
 await _preferences!.clear();
 }
 }

 Future<void> setHiveData<T>(String boxName, String key, T value) async {
 try {
   final box = _hiveBoxes[boxName];
   
   // Convert complex objects to JSON string to avoid Hive adapter issues
   dynamic storageValue;
   if (value is Map<String, dynamic>) {
     storageValue = json.encode(value);
   } else if (value is List) {
     storageValue = json.encode(value);
   } else if (value is String || value is num || value is bool || value == null) {
     storageValue = value;
   } else {
     // For any other type, try to convert to JSON string
     try {
       storageValue = json.encode(value);
     } catch (e) {
       // If JSON encoding fails, convert to string
       storageValue = value.toString();
     }
   }
   
   if (box != null) {
     await box.put(key, storageValue);
   } else {
     // Try to open box if not available
     final newBox = await _openBox<dynamic>(boxName);
     await newBox.put(key, storageValue);
   }
 } catch (e) {
   print('⚠️ Failed to save to Hive box $boxName: $e (falling back to SharedPreferences)');
   // Fallback to SharedPreferences for persistence
   await setPreference('hive_fallback_${boxName}_$key', value);
 }
 }

 T? getHiveData<T>(String boxName, String key, {T? defaultValue}) {
 try {
   final box = _hiveBoxes[boxName];
   if (box == null) {
     // Fallback to SharedPreferences
     return getPreference<T>('hive_fallback_${boxName}_$key', defaultValue: defaultValue);
   }
   
   final rawValue = box.get(key, defaultValue: defaultValue);
   if (rawValue == null) return null;
   
   // Handle JSON string decoding for complex objects
   if (T.toString().contains('Map<String, dynamic>') && rawValue is String) {
     try {
       return json.decode(rawValue) as T?;
     } catch (e) {
       print('⚠️ Failed to decode JSON from Hive: $e');
       return defaultValue;
     }
   }
   
   // Handle List decoding
   if (T.toString().startsWith('List') && rawValue is String) {
     try {
       return json.decode(rawValue) as T?;
     } catch (e) {
       print('⚠️ Failed to decode List JSON from Hive: $e');
       return defaultValue;
     }
   }
   
   return rawValue as T?;
 } catch (e) {
   print('⚠️ Failed to read from Hive box $boxName: $e (using fallback)');
   return getPreference<T>('hive_fallback_${boxName}_$key', defaultValue: defaultValue);
 }
 }

 Future<void> removeHiveData(String boxName, String key) async {
 try {
   final box = _hiveBoxes[boxName];
   if (box != null) {
     await box.delete(key);
   }
   // Also remove fallback data
   await removePreference('hive_fallback_${boxName}_$key');
 } catch (e) {
   print('⚠️ Failed to remove from Hive box $boxName: $e');
   // At least remove fallback data
   await removePreference('hive_fallback_${boxName}_$key');
 }
 }

 Future<void> clearHiveBox(String boxName) async {
 try {
   final box = _hiveBoxes[boxName];
   if (box != null) {
     await box.clear();
   }
 } catch (e) {
   print('⚠️ Failed to clear Hive box $boxName: $e');
 }
 }

 List<String> getHiveKeys(String boxName) {
 try {
   final box = _hiveBoxes[boxName];
   if (box == null) return [];
   return box.keys.cast<String>().toList();
 } catch (e) {
   print('⚠️ Failed to get keys from Hive box $boxName: $e');
   return [];
 }
 }

 Map<String, dynamic> getAllHiveData(String boxName) {
 final box = _hiveBoxes[boxName];
 if (box == null) return {};
 
 final Map<String, dynamic> data = {};
 for (final key in box.keys) {
 data[key.toString()] = box.get(key);
 }
 return data;
 }

 Future<void> saveToFile(String fileName, Map<String, dynamic> data) async {
 final appDir = await DesktopFileSystemService.instance.getAsmbliDirectory();
 final filePath = path.join(appDir.path, fileName);
 
 final jsonString = const JsonEncoder.withIndent(' ').convert(data);
 await DesktopFileSystemService.instance.writeFile(filePath, jsonString);
 }

 Future<Map<String, dynamic>?> loadFromFile(String fileName) async {
 try {
 final appDir = await DesktopFileSystemService.instance.getAsmbliDirectory();
 final filePath = path.join(appDir.path, fileName);
 
 if (!await DesktopFileSystemService.instance.fileExists(filePath)) {
 return null;
 }
 
 final jsonString = await DesktopFileSystemService.instance.readFile(filePath);
 return jsonDecode(jsonString) as Map<String, dynamic>;
 } catch (e) {
 print('Error loading file $fileName: $e');
 return null;
 }
 }

 Future<void> deleteFile(String fileName) async {
 final appDir = await DesktopFileSystemService.instance.getAsmbliDirectory();
 final filePath = path.join(appDir.path, fileName);
 await DesktopFileSystemService.instance.deleteFile(filePath);
 }

 Future<void> exportData(String exportPath) async {
 final exportData = <String, dynamic>{};
 
 for (final boxName in _hiveBoxes.keys) {
 exportData[boxName] = getAllHiveData(boxName);
 }
 
 exportData['preferences'] = _preferences?.getKeys().fold<Map<String, dynamic>>(
 {},
 (map, key) => map..[key] = _preferences!.get(key),
 ) ?? {};
 
 final jsonString = const JsonEncoder.withIndent(' ').convert(exportData);
 await File(exportPath).writeAsString(jsonString);
 }

 Future<void> importData(String importPath) async {
 final file = File(importPath);
 if (!await file.exists()) {
 throw FileSystemException('Import file not found', importPath);
 }
 
 final jsonString = await file.readAsString();
 final importData = jsonDecode(jsonString) as Map<String, dynamic>;
 
 for (final entry in importData.entries) {
 if (entry.key == 'preferences') {
 final prefs = entry.value as Map<String, dynamic>;
 for (final prefEntry in prefs.entries) {
 await setPreference(prefEntry.key, prefEntry.value);
 }
 } else {
 final boxData = entry.value as Map<String, dynamic>;
 for (final dataEntry in boxData.entries) {
 await setHiveData(entry.key, dataEntry.key, dataEntry.value);
 }
 }
 }
 }

 Future<void> backupData([String? backupPath]) async {
 final timestamp = DateTime.now().millisecondsSinceEpoch;
 final defaultBackupPath = backupPath ?? path.join(
 (await getApplicationDocumentsDirectory()).path,
 'Asmbli',
 'backups',
 'backup_$timestamp.json',
 );
 
 await DesktopFileSystemService.instance.ensureDirectoryExists(
 path.dirname(defaultBackupPath),
 );
 
 await exportData(defaultBackupPath);
 }

 Future<List<String>> getBackupFiles() async {
 final backupsDir = path.join(
 (await getApplicationDocumentsDirectory()).path,
 'Asmbli',
 'backups',
 );
 
 if (!await Directory(backupsDir).exists()) {
 return [];
 }
 
 final entities = await DesktopFileSystemService.instance.listDirectory(backupsDir);
 return entities
 .whereType<File>()
 .where((file) => file.path.endsWith('.json'))
 .map((file) => file.path)
 .toList();
 }

 Future<void> restoreFromBackup(String backupPath) async {
 await clearAllData();
 await importData(backupPath);
 }

 Future<void> clearAllData() async {
 if (_preferences != null) {
 await _preferences!.clear();
 }
 
 for (final box in _hiveBoxes.values) {
 await box.clear();
 }
 }

 Future<int> getStorageSize() async {
 int totalSize = 0;
 
 final appDir = await DesktopFileSystemService.instance.getAsmbliDirectory();
 final entities = await DesktopFileSystemService.instance.listDirectory(
 appDir.path,
 recursive: true,
 );
 
 for (final entity in entities) {
 if (entity is File) {
 totalSize += await entity.length();
 }
 }
 
 return totalSize;
 }

 String formatStorageSize(int bytes) {
 return DesktopFileSystemService.instance.formatFileSize(bytes);
 }

 Future<Map<String, int>> getStorageBreakdown() async {
 final breakdown = <String, int>{};
 
 final appDir = await DesktopFileSystemService.instance.getAsmbliDirectory();
 final directories = ['storage', 'agents', 'templates', 'logs', 'mcp_servers'];
 
 for (final dirName in directories) {
 final dir = Directory(path.join(appDir.path, dirName));
 if (await dir.exists()) {
 int dirSize = 0;
 await for (final entity in dir.list(recursive: true)) {
 if (entity is File) {
 dirSize += await entity.length();
 }
 }
 breakdown[dirName] = dirSize;
 }
 }
 
 return breakdown;
 }

 Future<void> cleanupOldData({int maxAgeInDays = 30}) async {
 final cutoffDate = DateTime.now().subtract(Duration(days: maxAgeInDays));
 
 final cacheBox = _hiveBoxes['cache'];
 if (cacheBox != null) {
 final keysToDelete = <String>[];
 
 for (final key in cacheBox.keys) {
 final data = cacheBox.get(key);
 if (data is Map && data.containsKey('timestamp')) {
 final timestamp = DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int);
 if (timestamp.isBefore(cutoffDate)) {
 keysToDelete.add(key.toString());
 }
 }
 }
 
 for (final key in keysToDelete) {
 await cacheBox.delete(key);
 }
 }
 
 final backupsDir = path.join(
 (await getApplicationDocumentsDirectory()).path,
 'Asmbli',
 'backups',
 );
 
 if (await Directory(backupsDir).exists()) {
 final backupFiles = await Directory(backupsDir).list().toList();
 
 for (final file in backupFiles) {
 if (file is File) {
 final stat = await file.stat();
 if (stat.modified.isBefore(cutoffDate)) {
 await file.delete();
 }
 }
 }
 }
 }

 Future<bool> isHealthy() async {
 try {
 if (_preferences == null) return false;
 
 for (final box in _hiveBoxes.values) {
 if (!box.isOpen) return false;
 }
 
 final testKey = '_health_check_${DateTime.now().millisecondsSinceEpoch}';
 await setPreference(testKey, 'test');
 final testValue = getPreference<String>(testKey);
 await removePreference(testKey);
 
 return testValue == 'test';
 } catch (e) {
 return false;
 }
 }

 Future<void> compactStorage() async {
 for (final box in _hiveBoxes.values) {
 await box.compact();
 }
 }

 void dispose() {
 for (final box in _hiveBoxes.values) {
 box.close();
 }
 _hiveBoxes.clear();
 }

 Future<void> saveAgentData(String agentId, Map<String, dynamic> data) async {
 await setHiveData('agents', agentId, data);
 }

 Map<String, dynamic>? getAgentData(String agentId) {
 return getHiveData<Map<String, dynamic>>('agents', agentId);
 }

 Future<void> deleteAgentData(String agentId) async {
 await removeHiveData('agents', agentId);
 }

 List<String> getAllAgentIds() {
 return getHiveKeys('agents');
 }

 Future<void> saveConversationData(String conversationId, Map<String, dynamic> data) async {
 await setHiveData('conversations', conversationId, data);
 }

 Map<String, dynamic>? getConversationData(String conversationId) {
 return getHiveData<Map<String, dynamic>>('conversations', conversationId);
 }

 Future<void> deleteConversationData(String conversationId) async {
 await removeHiveData('conversations', conversationId);
 }

 List<String> getAllConversationIds() {
 return getHiveKeys('conversations');
 }

 Future<void> cacheTemplate(String templateId, Map<String, dynamic> template) async {
 await setHiveData('templates', templateId, template);
 }

 Map<String, dynamic>? getCachedTemplate(String templateId) {
 return getHiveData<Map<String, dynamic>>('templates', templateId);
 }

 Future<void> clearTemplateCache() async {
 await clearHiveBox('templates');
 }

 List<String> getAllCachedTemplateIds() {
 return getHiveKeys('templates');
 }
}