import 'package:stock_opname_software/models/application_record.dart';

class Item extends ApplicationRecord {
  static const tableName = 'items';
  static const pkField = 'id';

  String code;
  String name;
  String barcode;
  double sellPrice;

  DateTime updatedAt;
  Item({
    this.code = '',
    this.name = '',
    this.sellPrice = 0,
    DateTime? updatedAt,
    super.id,
    this.barcode = '',
  }) : updatedAt = updatedAt ?? DateTime.now();

  static Item convert(json) {
    return Item(
      code: json['code'],
      name: json['name'],
      barcode: json['barcode'],
      sellPrice: json['sell_price'],
      updatedAt: DateTime.parse(json['updated_at']),
      id: json['id'],
    );
  }

  @override
  set pkValue(value) => id = value;

  @override
  get pkValue => id;

  @override
  Map<String, Object?> toJson() {
    return {
      'code': code,
      'name': name,
      'barcode': barcode,
      'sell_price': sellPrice,
      'updated_at': updatedAt.toIso8601String(),
      'id': id,
    };
  }
}
