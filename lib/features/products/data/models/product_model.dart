import 'package:equatable/equatable.dart';

class ProductModel extends Equatable {
  const ProductModel({
    required this.id,
    required this.internalCode,
    required this.name,
    this.imageUrl,
    required this.pricePerCarton,
    required this.itemsPerCarton,
    required this.isActive,
    this.createdAt,
  });

  final String id;
  final String internalCode;
  final String name;
  final String? imageUrl;
  final double pricePerCarton;
  final int itemsPerCarton;
  final bool isActive;
  final DateTime? createdAt;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final internalCode = (json['internal_code'] ?? json['internalCode'])
            ?.toString() ??
        '';
    final name = json['name']?.toString() ?? '';
    final imageRaw = json['image_url'] ?? json['imageUrl'];
    final imageUrl =
        imageRaw == null || imageRaw.toString().isEmpty ? null : imageRaw.toString();

    final priceRaw = json['price_per_carton'] ?? json['pricePerCarton'];
    final pricePerCarton = _parseDouble(priceRaw);

    final itemsRaw = json['items_per_carton'] ?? json['itemsPerCarton'];
    final itemsPerCarton = _parseInt(itemsRaw, fallback: 1);

    final activeRaw = json['is_active'] ?? json['isActive'];
    final isActive = activeRaw is bool
        ? activeRaw
        : activeRaw?.toString().toLowerCase() == 'true';

    final createdRaw = json['created_at'] ?? json['createdAt'];
    DateTime? createdAt;
    if (createdRaw is String) {
      createdAt = DateTime.tryParse(createdRaw);
    }

    return ProductModel(
      id: id,
      internalCode: internalCode,
      name: name,
      imageUrl: imageUrl,
      pricePerCarton: pricePerCarton,
      itemsPerCarton: itemsPerCarton,
      isActive: isActive,
      createdAt: createdAt,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static int _parseInt(dynamic value, {required int fallback}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  @override
  List<Object?> get props => [
        id,
        internalCode,
        name,
        imageUrl,
        pricePerCarton,
        itemsPerCarton,
        isActive,
        createdAt,
      ];
}
