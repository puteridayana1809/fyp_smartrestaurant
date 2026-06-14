import 'order_item.dart';

class RestaurantOrder {
  final String id;
  final List<OrderItem> items;
  final String status;
  final num? total;
  final String? table;
  final String? payment;
  final dynamic completedAt;

  RestaurantOrder({
    required this.id,
    required this.items,
    required this.status,
    this.total,
    this.table,
    this.payment,
    this.completedAt,
  });

  factory RestaurantOrder.fromMap(String id, Map<String, dynamic> map) {
    final rawItems = (map['items'] as List?) ?? [];
    return RestaurantOrder(
      id: id,
      items: rawItems
          .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      status: map['status']?.toString() ?? '',
      total: map['total'] as num?,
      table: map['table']?.toString(),
      payment: map['payment']?.toString(),
      completedAt: map['completedAt'],
    );
  }
}
