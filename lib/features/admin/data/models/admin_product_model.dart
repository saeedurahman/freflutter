class AdminProductModel {
  AdminProductModel({
    required this.id,
    required this.internalCode,
    required this.name,
    required this.pricePerCarton,
    required this.itemsPerCarton,
    required this.isActive,
    this.imageUrl,
    this.createdAt,
  });

  factory AdminProductModel.fromJson(Map<String, dynamic> json) {
    final priceRaw = json['price_per_carton'];
    final price = priceRaw is num
        ? priceRaw.toDouble()
        : double.parse(priceRaw.toString());

    return AdminProductModel(
      id: json['id'] as String,
      internalCode: json['internal_code'] as String,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String?,
      pricePerCarton: price,
      itemsPerCarton: (json['items_per_carton'] as num).toInt(),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  final String id;
  final String internalCode;
  final String name;
  final String? imageUrl;
  final double pricePerCarton;
  final int itemsPerCarton;
  final bool isActive;
  final DateTime? createdAt;
}
