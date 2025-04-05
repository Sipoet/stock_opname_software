import 'package:stock_opname_software/models/opname_item.dart';
export 'package:stock_opname_software/models/opname_item.dart';
import 'package:stock_opname_software/models/application_record.dart';

enum OpnameStatus {
  open,
  close;

  @override
  String toString() {
    switch (this) {
      case open:
        return 'open';
      case close:
        return 'close';
    }
  }

  static OpnameStatus? fromString(String statusStr) {
    switch (statusStr) {
      case 'open':
        return open;
      case 'close':
        return close;
      default:
        return null;
    }
  }
}

class OpnameSession extends ApplicationRecord {
  static const tableName = 'opname_sessions';
  static const pkField = 'id';
  DateTime updatedAt;
  String location;
  OpnameStatus status;
  List<OpnameItem> items;
  OpnameSession({
    DateTime? updatedAt,
    this.location = 'TOKO',
    this.status = OpnameStatus.open,
    super.id,
    items,
  })  : items = items ?? <OpnameItem>[],
        updatedAt = updatedAt ?? DateTime.now();

  static OpnameSession convert(json) {
    return OpnameSession(
      updatedAt: DateTime.parse(json['updated_at']),
      location: json['location'],
      status: OpnameStatus.fromString(json['status']) ?? OpnameStatus.open,
      id: json['id'],
    );
  }

  @override
  Map<String, Object?> toJson() {
    return {
      'updated_at': updatedAt.toIso8601String(),
      'location': location,
      'status': status.toString(),
      'id': id,
    };
  }
}
