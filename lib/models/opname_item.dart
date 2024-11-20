class OpnameItem {
  String kodeitem;
  int quantity;
  DateTime lastUpdated;
  OpnameItem({this.kodeitem = '', this.quantity = 0, DateTime? lastUpdated})
      : lastUpdated = lastUpdated ?? DateTime.now();
}
