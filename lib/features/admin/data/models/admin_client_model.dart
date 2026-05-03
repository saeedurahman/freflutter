class AdminClientModel {
  AdminClientModel({
    required this.id,
    required this.clientCode,
    required this.name,
    required this.taxId,
    required this.isActive,
    this.imageUrl,
    this.createdAt,
    this.locations = const [],
  });

  factory AdminClientModel.fromJson(Map<String, dynamic> json) {
    final rawLocs = json['locations'] as List<dynamic>? ?? [];
    return AdminClientModel(
      id: json['id'] as String,
      clientCode: json['client_code'] as String,
      name: json['name'] as String,
      taxId: json['tax_id'] as String,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      locations: rawLocs
          .map((e) => AdminLocationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String clientCode;
  final String name;
  final String taxId;
  final String? imageUrl;
  final bool isActive;
  final DateTime? createdAt;
  final List<AdminLocationModel> locations;
}

class AdminLocationModel {
  AdminLocationModel({
    required this.id,
    required this.label,
    required this.address,
    required this.isDefault,
  });

  factory AdminLocationModel.fromJson(Map<String, dynamic> json) {
    return AdminLocationModel(
      id: json['id'] as String,
      label: json['label'] as String,
      address: json['address'] as String,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  final String id;
  final String label;
  final String address;
  final bool isDefault;
}
