class OrderItem {
  final String name;
  final double unitPrice;
  final int qty;
  final int paidQty;

  OrderItem({
    required this.name,
    required this.unitPrice,
    required this.qty,
    this.paidQty = 0,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    final price = map['unitPrice'] ?? map['price'] ?? 0;
    final qty = map['qty'] ?? 1;
    final paidQty = map['paidQty'] ?? 0;
    return OrderItem(
      name: map['name']?.toString() ?? '',
      unitPrice: (price as num).toDouble(),
      qty: (qty as num).toInt(),
      paidQty: (paidQty as num).toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'unitPrice': unitPrice,
        'qty': qty,
        'paidQty': paidQty,
      };

  OrderItem copyWith({int? paidQty}) => OrderItem(
        name: name,
        unitPrice: unitPrice,
        qty: qty,
        paidQty: paidQty ?? this.paidQty,
      );

  int get remainingQty => qty - paidQty;

  double get total => unitPrice * qty;
}
