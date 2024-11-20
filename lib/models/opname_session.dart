import 'package:stock_opname_software/models/opname_item.dart';
export 'package:stock_opname_software/models/opname_item.dart';

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
      default:
        return '';
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

class OpnameSession {
  DateTime updatedAt;
  String location;
  OpnameStatus status;
  List<OpnameItem> items;
  OpnameSession({
    DateTime? updatedAt,
    this.location = 'TOKO',
    this.status = OpnameStatus.open,
    items,
  })  : items = items ?? <OpnameItem>[],
        updatedAt = updatedAt ?? DateTime.now();
}
