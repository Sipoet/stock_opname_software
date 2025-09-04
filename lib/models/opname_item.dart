import 'package:stock_opname_software/models/application_record.dart';

class OpnameItem extends ApplicationRecord {
  static const tableName = 'opname_items';
  static const pkField = 'id';
  int opnameSessionId;
  String itemCode;
  int quantity;
  Set<String> rack;
  DateTime updatedAt;
  OpnameItem(
      {this.itemCode = '',
      this.quantity = 0,
      DateTime? updatedAt,
      super.id,
      this.rack = const {},
      required this.opnameSessionId})
      : updatedAt = updatedAt ?? DateTime.now();

  static OpnameItem convert(json) {
    return OpnameItem(
        itemCode: json['item_code'],
        quantity: json['quantity'],
        rack: json['rack']
                ?.split(',')
                .map<String>((String rackStr) => rackStr.toString().trim())
                .toSet() ??
            <String>{},
        updatedAt: DateTime.parse(json['updated_at']),
        id: json['id'],
        opnameSessionId: json['opname_session_id']);
  }

  String get rackFormat => rack.join(', ');

  @override
  set pkValue(value) => id = value;

  @override
  get pkValue => id;

  @override
  Map<String, Object?> toJson() {
    return {
      'item_code': itemCode,
      'quantity': quantity,
      'rack': rack.join(','),
      'updated_at': updatedAt.toIso8601String(),
      'opname_session_id': opnameSessionId,
      'id': id,
    };
  }
}
