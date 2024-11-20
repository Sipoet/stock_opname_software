class OpnameItem {
  String itemCode;
  int quantity;
  DateTime lastUpdated;
  OpnameItem({this.itemCode = '', this.quantity = 0, DateTime? lastUpdated})
      : lastUpdated = lastUpdated ?? DateTime.now();
}
