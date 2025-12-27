import 'package:flutter/material.dart';
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
  // String get tableName;
  // String get pkField;

  int? id;
  set pkValue(dynamic value);
  dynamic get pkValue;

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
    if (model.pkValue == null) {
      return await _create(model, transaction: transaction);
    } else {
      return await _update(model, transaction: transaction);
    }
  }

  Future<List<Object?>> massSave(List<ApplicationRecord> models) async {
    Batch batch = db.batch();
    for (ApplicationRecord model in models) {
      final data = model.toJson();
      if (model.pkValue == null) {
        batch.insert(tableName, data,
            conflictAlgorithm: ConflictAlgorithm.rollback);
      } else {
        batch.update(tableName, data,
            where: '$pkField = ?',
            whereArgs: [data[pkField]],
            conflictAlgorithm: ConflictAlgorithm.rollback);
      }
    }
    return batch.commit(
      continueOnError: true,
    );
  }

  Future<int> _create(ApplicationRecord model,
      {Transaction? transaction}) async {
    final data = model.toJson();
    if (model.pkValue != null) {
      model.pkValue == null;
    }
    try {
      if (transaction == null) {
        model.pkValue = await db.insert(tableName, data);
      } else {
        model.pkValue = await transaction.insert(tableName, data);
      }
    } catch (e) {
      debugPrint('error sql: ${e.toString()}');
    }

    return model.pkValue;
  }

  Future<int> _update(ApplicationRecord model,
      {Transaction? transaction}) async {
    final data = model.toJson();
    if (transaction == null) {
      return await db.update(tableName, data,
          where: '$pkField = ?', whereArgs: [model.pkValue]);
    }
    return await transaction.update(tableName, data,
        where: '$pkField = ?', whereArgs: [model.pkValue]);
  }

  Future<Object?> maxOf(String keyname,
      {Map<String, String> filter = const {}}) async {
    return reduce('MAX', keyname, filter: filter);
  }

  Future<Object?> countOf(String keyname,
      {Map<String, String> filter = const {}}) async {
    return reduce('COUNT', keyname, filter: filter);
  }

  Future<Object?> minOf(String keyname,
      {Map<String, String> filter = const {}}) async {
    return reduce('MIN', keyname, filter: filter);
  }

  Future<Object?> sumOf(String keyname,
      {Map<String, String> filter = const {}}) async {
    return reduce('SUM', keyname, filter: filter);
  }

  Future<Object?> avgOf(String keyname,
      {Map<String, String> filter = const {}}) async {
    return reduce('AVG', keyname, filter: filter);
  }

  Future<Object?> reduce(String operator, String keyname,
      {Map<String, String> filter = const {}}) async {
    String name = '$operator($keyname)';
    String query = "SELECT $name from $tableName";
    List filterQuery = [];
    for (String key in filter.keys.toList()) {
      final value = filter[key];
      filterQuery.add("$key = '$value'");
    }
    if (filterQuery.isNotEmpty) {
      query += ' WHERE ${filterQuery.join(' AND ')}';
    }
    final result = await db.rawQuery(query);
    return result.firstOrNull?[name];
  }

  Future<int> deleteById(id) async {
    return await db.delete(tableName, where: '$pkField = ?', whereArgs: [id]);
  }

  Future<int> deleteAll({String? where, List<Object?>? whereArgs}) async {
    return await db.delete(tableName, where: where, whereArgs: whereArgs);
  }
}
