import 'sqlite_repository.dart';

class ConcreteSqliteRepository<T> extends SqliteRepository<T> {
  ConcreteSqliteRepository(
    String tableName,
    String Function(T) getId,
    T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic> Function(T) toJson,
  ) : super(tableName, getId, fromJson, toJson);
}
