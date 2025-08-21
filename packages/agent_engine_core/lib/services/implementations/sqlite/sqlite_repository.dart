import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqlite3/sqlite3.dart';
import '../../repository.dart';

abstract class SqliteRepository<T> implements Repository<T> {
  final String tableName;
  final String Function(T) _getId;
  final T Function(Map<String, dynamic>) _fromJson;
  final Map<String, dynamic> Function(T) _toJson;
  late Database _db;

  SqliteRepository(this.tableName, this._getId, this._fromJson, this._toJson);

  Future<void> initialize() async {
    final dbPath = join(Directory.current.path, 'data', 'agent_engine.db');
    final dbDir = Directory(dirname(dbPath));
    if (!dbDir.existsSync()) {
      dbDir.createSync(recursive: true);
    }

    _db = sqlite3.open(dbPath);
    _db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL
      )
    ''');
  }

  @override
  Future<T> create(T item) async {
    final stmt = _db.prepare(
      'INSERT OR REPLACE INTO $tableName (id, data) VALUES (?, ?)',
    );
    stmt.execute([
      _getId(item),
      jsonEncode(_toJson(item)),
    ]);
    stmt.dispose();
    return item;
  }

  @override
  Future<T?> read(String id) async {
    final stmt = _db.prepare(
      'SELECT data FROM $tableName WHERE id = ? LIMIT 1',
    );
    final result = stmt.select([id]);
    stmt.dispose();

    if (result.isEmpty) {
      return null;
    }

    return _fromJson(jsonDecode(result.first['data'] as String) as Map<String, dynamic>);
  }

  @override
  Future<List<T>> readAll() async {
    final stmt = _db.prepare('SELECT data FROM $tableName');
    final results = stmt.select();
    stmt.dispose();

    return results
        .map((row) => _fromJson(jsonDecode(row['data'] as String) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<T> update(T item) async {
    final id = _getId(item);
    
    // Check if the item exists
    final checkStmt = _db.prepare(
      'SELECT COUNT(*) as count FROM $tableName WHERE id = ?',
    );
    final count = checkStmt.select([id]).first['count'] as int;
    checkStmt.dispose();

    if (count == 0) {
      throw Exception('Item with id $id not found');
    }

    // Perform the update
    final updateStmt = _db.prepare(
      'UPDATE $tableName SET data = ? WHERE id = ?',
    );
    updateStmt.execute([jsonEncode(_toJson(item)), id]);
    updateStmt.dispose();

    return item;
  }

  @override
  Future<void> delete(String id) async {
    final stmt = _db.prepare('DELETE FROM $tableName WHERE id = ?');
    stmt.execute([id]);
    stmt.dispose();
  }

  @override
  Future<void> deleteAll() async {
    _db.execute('DELETE FROM $tableName');
  }

  Future<void> close() async {
    _db.dispose();
  }
}
