import 'package:intl/intl.dart';

extension FormatDatetime on DateTime {
  String formatDatetime() {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return dateFormat.format(this);
  }

  String formatDate() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return dateFormat.format(this);
  }

  String dateIso() {
    final dateFormat = DateFormat('yyyy-MM-dd');
    return dateFormat.format(this);
  }
}

extension FormatNumberInt on int {
  String format({String pattern = "#,###"}) {
    final numberFormat = NumberFormat(pattern);
    return numberFormat.format(this);
  }
}

extension FormatNumberDouble on double {
  String format({String pattern = "#,###"}) {
    final numberFormat = NumberFormat(pattern);
    return numberFormat.format(this);
  }
}
