class RestaurantTable {
  final String id;
  final String name;
  final String? activeOrderId;

  RestaurantTable({required this.id, required this.name, this.activeOrderId});

  factory RestaurantTable.fromMap(String id, Map<String, dynamic> map) {
    final name = map['name']?.toString() ?? 'T${map['number'] ?? id}';
    return RestaurantTable(
      id: id,
      name: name,
      activeOrderId: map['activeOrderId']?.toString(),
    );
  }

  bool get hasOrder => activeOrderId != null && activeOrderId!.isNotEmpty;
}
