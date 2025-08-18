import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static const String _agentsBox = 'agents';
  static const String _settingsBox = 'settings';
  static const String _templatesBox = 'templates';

  static late Box<Map> _agentsBoxInstance;
  static late Box<dynamic> _settingsBoxInstance;
  static late Box<Map> _templatesBoxInstance;

  static Future<void> init() async {
    _agentsBoxInstance = await Hive.openBox<Map>(_agentsBox);
    _settingsBoxInstance = await Hive.openBox<dynamic>(_settingsBox);
    _templatesBoxInstance = await Hive.openBox<Map>(_templatesBox);
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

  // Clear all data
  static Future<void> clearAll() async {
    await _agentsBoxInstance.clear();
    await _settingsBoxInstance.clear();
    await _templatesBoxInstance.clear();
  }
}