import 'package:stock_opname_software/models/application_record.dart';

class SystemSetting extends ApplicationRecord {
  static const tableName = 'system_settings';
  static const pkField = 'id';

  String keyname;
  String valueStr;

  SystemSetting({
    this.keyname = '',
    this.valueStr = '',
    DateTime? updatedAt,
    super.id,
  });

  static SystemSetting convert(json) {
    return SystemSetting(
      keyname: json['keyname'],
      valueStr: json['value_str'],
      id: json['id'],
    );
  }

  @override
  Map<String, Object?> toJson() {
    return {
      'keyname': keyname,
      'value_str': valueStr,
      'id': id,
    };
  }
}
