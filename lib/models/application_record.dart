import 'package:sqflite/sqflite.dart';

enum QueryOrder {
  asc,
  desc;

  @override
  String toString() {
    if (this == asc) {
      return 'ASC';
    } else {
      return 'DESC';
    }
  }
}

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

  Future<T?> find<T extends ApplicationRecord>(
      String id, T Function(Map<String, Object?>) convert) async {
    final result =
        await db.query(tableName, where: '$pkField = ?', whereArgs: [id]);
    return result.map<T>((row) => convert(row)).toList().firstOrNull;
  }

  Future<T?> findBy<T extends ApplicationRecord>(Map<String, Object?> filter,
      T Function(Map<String, Object?>) convert) async {
    List<String> query = [];
    List<Object?> values = [];
    filter.forEach((key, value) {
      query.add('$key = ?');
      values.add(value);
    });

    final result = await db.query(
      tableName,
      where: query.join(' AND '),
      whereArgs: values,
    );
    return result.map<T>((row) => convert(row)).toList().firstOrNull;
  }

  Future<List<T>> finds<T extends ApplicationRecord>(
      {Map<String, Object?>? filter,
      int? page,
      int? limit,
      String? orderBy,
      QueryOrder orderValue = QueryOrder.asc,
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
        orderBy: "$orderBy ${orderValue.toString()}",
        limit: limit);
    return result.map<T>((row) => convert(row)).toList();
  }

  Future<int> save(ApplicationRecord model, {Transaction? transaction}) async {
    final data = model.toJson();
    if (data[pkField] == null) {
      return await _create(data, transaction: transaction);
    } else {
      return await _update(data, transaction: transaction);
    }
  }

  Future<bool> massSave(List<ApplicationRecord> models) async {
    return db.transaction<bool>((trx) async {
      for (ApplicationRecord model in models) {
        await save(model, transaction: trx);
      }
      return true;
    });
  }

  Future<int> _create(Map<String, Object?> data,
      {Transaction? transaction}) async {
    if (data[pkField] == null) {
      data.remove(pkField);
    }
    if (transaction == null) {
      return await db.transaction<int>((txn) async {
        return await txn.insert(tableName, data);
      });
    }
    return await transaction.insert(tableName, data);
  }

  Future<int> _update(Map<String, Object?> data,
      {Transaction? transaction}) async {
    if (transaction == null) {
      return await db.update(tableName, data,
          where: '$pkField = ?', whereArgs: [data[pkField]]);
    }
    return await transaction.update(tableName, data,
        where: '$pkField = ?', whereArgs: [data[pkField]]);
  }

  Future<Object?> maxOf(String keyname,
      {Map<String, String> filter = const {}}) async {
    String query = "SELECT MAX($keyname) from $tableName";
    List filterQuery = [];
    for (String key in filter.keys.toList()) {
      final value = filter[key];
      filterQuery.add("$key = '$value'");
    }
    if (filterQuery.isNotEmpty) {
      query += ' WHERE ${filterQuery.join(' AND ')}';
    }
    final result = await db.rawQuery(query);
    return result.firstOrNull?['MAX($keyname)'];
  }

  Future<int> delete<T extends ApplicationRecord>(id) async {
    return await db.delete(tableName, where: '$pkField = ?', whereArgs: [id]);
  }

  Future<int> deleteWhere<T extends ApplicationRecord>(
      {required String where, required List<Object?> whereArgs}) async {
    return await db.delete(tableName, where: where, whereArgs: whereArgs);
  }
}
