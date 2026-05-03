import 'package:equatable/equatable.dart';

class OrderItemModel extends Equatable {
  const OrderItemModel({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.priceAtOrder,
  });

  final String id;
  final String productId;
  final int quantity;
  final double priceAtOrder;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final qtyRaw = json['quantity'];
    final qty = qtyRaw is int
        ? qtyRaw
        : (qtyRaw is num ? qtyRaw.toInt() : int.tryParse('$qtyRaw') ?? 0);

    final priceRaw = json['price_at_order'] ??
        json['priceAtOrder'] ??
        json['unit_price'] ??
        json['price'];
    double price = 0;
    if (priceRaw is num) {
      price = priceRaw.toDouble();
    } else {
      price = double.tryParse(priceRaw?.toString() ?? '') ?? 0;
    }

    final pid = (json['product_id'] ?? json['productId'])?.toString() ??
        (json['product'] is Map
            ? (json['product'] as Map)['id']?.toString()
            : null) ??
        '';

    return OrderItemModel(
      id: json['id']?.toString() ?? '',
      productId: pid,
      quantity: qty,
      priceAtOrder: price,
    );
  }

  @override
  List<Object?> get props => [id, productId, quantity, priceAtOrder];
}

class OrderModel extends Equatable {
  const OrderModel({
    required this.id,
    required this.clientId,
    required this.locationId,
    this.locationName,
    required this.status,
    this.createdAt,
    this.updatedAt,
    required this.items,
  });

  final String id;
  final String clientId;
  final String locationId;
  final String? locationName;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<OrderItemModel> items;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    final items = <OrderItemModel>[];
    if (itemsRaw is List) {
      for (final e in itemsRaw) {
        if (e is Map<String, dynamic>) {
          items.add(OrderItemModel.fromJson(e));
        } else if (e is Map) {
          items.add(OrderItemModel.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    final createdRaw = json['created_at'] ?? json['createdAt'];
    final updatedRaw = json['updated_at'] ?? json['updatedAt'];

    final rawLocation = json['location'];
    final locationName = json['location_name']?.toString() ??
        json['location_label']?.toString() ??
        (rawLocation is Map
            ? (rawLocation['label'] ?? rawLocation['name'])?.toString()
            : null);

    return OrderModel(
      id: json['id']?.toString() ?? '',
      clientId:
          (json['client_id'] ?? json['clientId'])?.toString() ?? '',
      locationId:
          (json['location_id'] ?? json['locationId'])?.toString() ?? '',
      locationName: locationName,
      status: json['status']?.toString() ?? 'pending',
      createdAt: createdRaw is String ? DateTime.tryParse(createdRaw) : null,
      updatedAt: updatedRaw is String ? DateTime.tryParse(updatedRaw) : null,
      items: items,
    );
  }

  int get totalLineQuantity =>
      items.fold<int>(0, (sum, e) => sum + e.quantity);

  double get totalAmount =>
      items.fold<double>(0, (sum, e) => sum + e.priceAtOrder * e.quantity);

  @override
  List<Object?> get props =>
      [id, clientId, locationId, locationName, status, createdAt, updatedAt, items];
}
