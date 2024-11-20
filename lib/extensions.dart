extension FormatDatetime on DateTime {
  String formatDatetime() {
    return "$day/$month/$year $hour:$minute";
  }

  String formatDate() {
    return "$day/$month/$year";
  }

  String dateIso() {
    return "$year-$month-$day";
  }
}
