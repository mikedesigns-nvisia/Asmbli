import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
 static const String _agentsBox = 'agents';
 static const String _settingsBox = 'settings';
 static const String _templatesBox = 'templates';

 static late Box<Map> _agentsBoxInstance;
 static late Box<dynamic> _settingsBoxInstance;
 static late Box<Map> _templatesBoxInstance;

 static Future<void> init() async {
 try {
   // Since we're no longer using this service for critical functionality,
   // just create stub instances that won't conflict with the modern service
   print('⚠️ Legacy StorageService is deprecated - using fallback stubs');
   
   // Use the existing modern storage boxes but wrap them safely
   if (Hive.isBoxOpen(_agentsBox)) {
     final dynamicBox = Hive.box<dynamic>(_agentsBox);
     // Create a wrapper that provides the expected interface
     _agentsBoxInstance = _createMapBoxWrapper(dynamicBox);
     print('♻️ Created wrapper for existing agents box');
   } else {
     _agentsBoxInstance = await Hive.openBox<Map>(_agentsBox);
   }
   
   if (Hive.isBoxOpen(_settingsBox)) {
     _settingsBoxInstance = Hive.box<dynamic>(_settingsBox);
     print('♻️ Reusing already opened settings box');
   } else {
     _settingsBoxInstance = await Hive.openBox<dynamic>(_settingsBox);
   }
   
   if (Hive.isBoxOpen(_templatesBox)) {
     final dynamicBox = Hive.box<dynamic>(_templatesBox);
     _templatesBoxInstance = _createMapBoxWrapper(dynamicBox);
     print('♻️ Created wrapper for existing templates box');
   } else {
     _templatesBoxInstance = await Hive.openBox<Map>(_templatesBox);
   }
   
 } catch (e) {
   print('⚠️ Legacy storage initialization failed: $e');
   throw e;
 }
 }

 // Agent Storage
 static Future<void> saveAgent(String id, Map<String, dynamic> agent) async {
 await _agentsBoxInstance.put(id, agent);
 }

 static Map<String, dynamic>? getAgent(String id) {
 return _agentsBoxInstance.get(id)?.cast<String, dynamic>();
 }

 static List<Map<String, dynamic>> getAllAgents() {
 return _agentsBoxInstance.values
 .map((agent) => agent.cast<String, dynamic>())
 .toList();
 }

 static Future<void> deleteAgent(String id) async {
 await _agentsBoxInstance.delete(id);
 }

 // Settings Storage
 static Future<void> saveSetting(String key, dynamic value) async {
 await _settingsBoxInstance.put(key, value);
 }

 static T? getSetting<T>(String key, {T? defaultValue}) {
 return _settingsBoxInstance.get(key, defaultValue: defaultValue) as T?;
 }

 // Template Cache
 static Future<void> cacheTemplate(String id, Map<String, dynamic> template) async {
 await _templatesBoxInstance.put(id, template);
 }

 static Map<String, dynamic>? getCachedTemplate(String id) {
 return _templatesBoxInstance.get(id)?.cast<String, dynamic>();
 }

 static List<Map<String, dynamic>> getAllCachedTemplates() {
 return _templatesBoxInstance.values
 .map((template) => template.cast<String, dynamic>())
 .toList();
 }

 static Future<void> clearTemplateCache() async {
 await _templatesBoxInstance.clear();
 }

 // Generic string storage for context documents
 static Future<void> setString(String key, String value) async {
 await _settingsBoxInstance.put(key, value);
 }

 static Future<String?> getString(String key) async {
 return _settingsBoxInstance.get(key) as String?;
 }

 // Clear all data
 static Future<void> clearAll() async {
 await _agentsBoxInstance.clear();
 await _settingsBoxInstance.clear();
 await _templatesBoxInstance.clear();
 }

 /// Create a Box<Map> wrapper around a Box<dynamic>
 static Box<Map> _createMapBoxWrapper(Box<dynamic> dynamicBox) {
   return _BoxWrapper(dynamicBox);
 }
}

/// Wrapper class that adapts Box<dynamic> to Box<Map> interface
class _BoxWrapper implements Box<Map> {
  final Box<dynamic> _box;
  
  _BoxWrapper(this._box);
  
  @override
  Map? get(key, {Map? defaultValue}) {
    final value = _box.get(key, defaultValue: defaultValue);
    if (value is Map) return value;
    if (value == null) return defaultValue;
    return defaultValue;
  }
  
  @override
  Future<void> put(key, Map? value) => _box.put(key, value);
  
  @override
  Future<void> delete(key) => _box.delete(key);
  
  @override
  Future<int> clear() => _box.clear();
  
  @override
  Iterable<Map> get values => _box.values.whereType<Map>();
  
  @override
  Iterable<dynamic> get keys => _box.keys;
  
  @override
  int get length => _box.length;
  
  @override
  bool get isEmpty => _box.isEmpty;
  
  @override
  bool get isNotEmpty => _box.isNotEmpty;
  
  @override
  bool containsKey(key) => _box.containsKey(key);
  
  @override
  Future<void> close() => _box.close();
  
  @override
  Future<void> deleteFromDisk() => _box.deleteFromDisk();
  
  @override
  bool get isOpen => _box.isOpen;
  
  @override
  String get name => _box.name;
  
  @override
  String? get path => _box.path;
  
  // Delegate all other methods to the underlying box
  @override dynamic noSuchMethod(Invocation invocation) => 
    throw UnsupportedError('Method ${invocation.memberName} not implemented in wrapper');
}