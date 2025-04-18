import 'package:stock_opname_software/models/application_record.dart';

class OpnameItem extends ApplicationRecord {
  static const tableName = 'opname_items';
  static const pkField = 'id';
  int opnameSessionId;
  String itemCode;
  int quantity;
  DateTime updatedAt;
  OpnameItem(
      {this.itemCode = '',
      this.quantity = 0,
      DateTime? updatedAt,
      super.id,
      required this.opnameSessionId})
      : updatedAt = updatedAt ?? DateTime.now();

  static OpnameItem convert(json) {
    return OpnameItem(
        itemCode: json['item_code'],
        quantity: json['quantity'],
        updatedAt: DateTime.parse(json['updated_at']),
        id: json['id'],
        opnameSessionId: json['opname_session_id']);
  }

  @override
  Map<String, Object?> toJson() {
    return {
      'item_code': itemCode,
      'quantity': quantity,
      'updated_at': updatedAt.toIso8601String(),
      'opname_session_id': opnameSessionId,
      'id': id,
    };
  }
}
