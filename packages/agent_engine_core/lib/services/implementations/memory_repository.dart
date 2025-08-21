import 'dart:async';
import '../repository.dart';

class InMemoryRepository<T> implements Repository<T> {
  final Map<String, T> _store = {};
  final String Function(T) _getId;

  InMemoryRepository(this._getId);

  @override
  Future<T> create(T item) async {
    final id = _getId(item);
    _store[id] = item;
    return item;
  }

  @override
  Future<T?> read(String id) async {
    return _store[id];
  }

  @override
  Future<List<T>> readAll() async {
    return _store.values.toList();
  }

  @override
  Future<T> update(T item) async {
    final id = _getId(item);
    if (!_store.containsKey(id)) {
      throw Exception('Item with id $id not found');
    }
    _store[id] = item;
    return item;
  }

  @override
  Future<void> delete(String id) async {
    _store.remove(id);
  }

  @override
  Future<void> deleteAll() async {
    _store.clear();
  }
}
