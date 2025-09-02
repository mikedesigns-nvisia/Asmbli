import 'package:agent_engine_core/services/repository.dart';
import 'desktop_storage_service.dart';

/// A persistent repository implementation that uses DesktopStorageService
/// Provides automatic JSON serialization/deserialization with fallback mechanisms
class DesktopRepository<T> implements Repository<T> {
  final String boxName;
  final String Function(T) _getId;
  final T Function(Map<String, dynamic>) _fromJson;
  final Map<String, dynamic> Function(T) _toJson;
  final DesktopStorageService _storage;

  DesktopRepository({
    required this.boxName,
    required String Function(T) getId,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
  }) : _getId = getId,
       _fromJson = fromJson,
       _toJson = toJson,
       _storage = DesktopStorageService.instance;

  @override
  Future<T> create(T item) async {
    final id = _getId(item);
    final data = _toJson(item);
    await _storage.setHiveData(boxName, id, data);
    return item;
  }

  @override
  Future<T?> read(String id) async {
    try {
      final data = _storage.getHiveData<Map<String, dynamic>>(boxName, id);
      if (data == null) return null;
      return _fromJson(data);
    } catch (e) {
      print('⚠️ Failed to read $id from $boxName: $e');
      return null;
    }
  }

  @override
  Future<List<T>> readAll() async {
    try {
      final keys = _storage.getHiveKeys(boxName);
      final List<T> items = [];
      
      for (final key in keys) {
        final item = await read(key);
        if (item != null) {
          items.add(item);
        }
      }
      
      return items;
    } catch (e) {
      print('⚠️ Failed to read all from $boxName: $e');
      return [];
    }
  }

  @override
  Future<T> update(T item) async {
    final id = _getId(item);
    
    // Check if item exists
    final existing = await read(id);
    if (existing == null) {
      throw Exception('Item with id $id not found');
    }
    
    final data = _toJson(item);
    await _storage.setHiveData(boxName, id, data);
    return item;
  }

  @override
  Future<void> delete(String id) async {
    await _storage.removeHiveData(boxName, id);
  }

  @override
  Future<void> deleteAll() async {
    await _storage.clearHiveBox(boxName);
  }

  /// Get count of items in the repository
  Future<int> count() async {
    final keys = _storage.getHiveKeys(boxName);
    return keys.length;
  }

  /// Check if an item exists
  Future<bool> exists(String id) async {
    final item = await read(id);
    return item != null;
  }
}