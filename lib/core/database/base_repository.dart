import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

abstract class BaseRepository<T> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  String get tableName;

  Future<Database> get _database async => await _databaseHelper.database;

  T fromMap(Map<String, dynamic> map);

  Map<String, dynamic> toMap(T item);

  Future<List<T>> getAll() async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return List.generate(maps.length, (i) => fromMap(maps[i]));
  }

  Future<T?> getById(String id) async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return fromMap(maps.first);
    }
    return null;
  }

  Future<List<T>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final db = await _database;
    final placeholders = List.filled(ids.length, '?').join(',');
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );

    return List.generate(maps.length, (i) => fromMap(maps[i]));
  }

  Future<String> insert(T item) async {
    final db = await _database;
    final map = toMap(item);
    map['created_at'] = DateTime.now().toIso8601String();
    map['updated_at'] = DateTime.now().toIso8601String();

    await db.insert(
      tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return map['id'] as String;
  }

  Future<void> insertBatch(List<T> items) async {
    if (items.isEmpty) return;

    final db = await _database;
    final batch = db.batch();

    for (final item in items) {
      final map = toMap(item);
      map['created_at'] = DateTime.now().toIso8601String();
      map['updated_at'] = DateTime.now().toIso8601String();

      batch.insert(
        tableName,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit();
  }

  Future<int> update(T item) async {
    final db = await _database;
    final map = toMap(item);
    map['updated_at'] = DateTime.now().toIso8601String();

    return await db.update(
      tableName,
      map,
      where: 'id = ?',
      whereArgs: [map['id']],
    );
  }

  Future<int> delete(String id) async {
    final db = await _database;
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAll() async {
    final db = await _database;
    return await db.delete(tableName);
  }

  Future<List<T>> query({
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) => fromMap(maps[i]));
  }

  Future<int> count({String? where, List<dynamic>? whereArgs}) async {
    final db = await _database;
    final result = await db.query(
      tableName,
      columns: ['COUNT(*) as count'],
      where: where,
      whereArgs: whereArgs,
    );

    return result.first['count'] as int;
  }

  Future<bool> exists(String id) async {
    final count = await this.count(where: 'id = ?', whereArgs: [id]);
    return count > 0;
  }
}