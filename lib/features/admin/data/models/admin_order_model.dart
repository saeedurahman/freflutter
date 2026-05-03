class AdminOrderModel {
  AdminOrderModel({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.totalLineQuantity,
    required this.clientId,
    required this.locationId,
    this.items = const [],
    this.createdAt,
  });

  factory AdminOrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final parsedItems = rawItems
        .map((e) => AdminOrderItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // API does not return total_amount / total_line_quantity — derive them
    final totalAmount = parsedItems.fold<double>(
      0,
      (sum, item) => sum + item.priceAtOrder * item.quantity,
    );
    final totalLineQuantity = parsedItems.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return AdminOrderModel(
      id: json['id'] as String,
      status: json['status'] as String,
      totalAmount: totalAmount,
      totalLineQuantity: totalLineQuantity,
      clientId: json['client_id'] as String,
      locationId: json['location_id'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      items: parsedItems,
    );
  }

  final String id;
  final String status;
  final double totalAmount;
  final int totalLineQuantity;
  final String clientId;
  final String locationId;
  final List<AdminOrderItemModel> items;
  final DateTime? createdAt;
}

class AdminOrderItemModel {
  AdminOrderItemModel({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.priceAtOrder,
  });

  factory AdminOrderItemModel.fromJson(Map<String, dynamic> json) {
    // price_at_order is returned as a String e.g. "2500.00", not a num
    final priceRaw = json['price_at_order'];
    final price = priceRaw is num
        ? priceRaw.toDouble()
        : double.parse(priceRaw.toString());

    return AdminOrderItemModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      quantity: (json['quantity'] as num).toInt(),
      priceAtOrder: price,
    );
  }

  final String id;
  final String productId;
  final int quantity;
  final double priceAtOrder;
}
