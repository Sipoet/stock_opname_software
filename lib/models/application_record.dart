import 'package:sqflite/sqflite.dart';

abstract class ApplicationRecord {
  // String ApplicationRecord.tableName = '';
  // String ApplicationRecord.pkField = 'id';

  int? id;
  ApplicationRecord({this.id});

  // static convert(Map json);
  Map<String, Object?> toJson();
}

class Orm {
  final String tableName;
  final String pkField;
  final Database db;
  Orm({required this.tableName, required this.pkField, required this.db});

  Future<T> find<T extends ApplicationRecord>(
      String id, T Function(Map<String, Object?>) convert) async {
    final result =
        await db.query(tableName, where: '$pkField = ?', whereArgs: [id]);
    return result.map<T>((row) => convert(row)).toList().first;
  }

  Future<List<T>> finds<T extends ApplicationRecord>(
      {Map<String, Object?>? filter,
      int? page,
      int? limit,
      required T Function(Map<String, Object?>) convert}) async {
    List<String>? query;
    List? values;
    if (filter != null) {
      query = [];
      values = [];
      filter.forEach((key, value) {
        query?.add('$key = ?');
        values?.add(value);
      });
    }
    int? offset;
    if (page != null) {
      offset = (page - 1) * (limit ?? 10);
    }
    final result = await db.query(tableName,
        where: query?.join(' AND '),
        whereArgs: values,
        offset: offset,
        limit: limit);
    return result.map<T>((row) => convert(row)).toList();
  }

  Future<dynamic> save(ApplicationRecord model) async {
    final data = model.toJson();
    if (data[pkField] == null) {
      return await _create(data);
    } else {
      await _update(data);
      return data[pkField];
    }
  }

  Future<int> _create(Map<String, Object?> data) async {
    if (data[pkField] == null) {
      data.remove(pkField);
    }
    return await db.transaction<int>((txn) async {
      return await txn.insert(tableName, data);
    });
  }

  Future<bool> _update(Map<String, Object?> data) async {
    int? count = await db.update(tableName, data,
        where: '$pkField = ?', whereArgs: [data[pkField]]);
    return count > 0;
  }

  Future<int> delete<T extends ApplicationRecord>(id) async {
    return await db.delete(tableName, where: '$pkField = ?', whereArgs: [id]);
  }
}
