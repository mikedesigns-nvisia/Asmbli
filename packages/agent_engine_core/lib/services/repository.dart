abstract class Repository<T> {
  Future<T> create(T item);
  Future<T?> read(String id);
  Future<List<T>> readAll();
  Future<T> update(T item);
  Future<void> delete(String id);
  Future<void> deleteAll();
}
