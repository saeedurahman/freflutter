import 'package:equatable/equatable.dart';

import '../../../../features/orders/data/models/location_model.dart';

class UserModel extends Equatable {
  const UserModel({
    required this.id,
    required this.clientCode,
    this.name,
    this.email,
    this.phone,
    this.address,
    this.taxId,
    this.isActive = true,
    this.locations = const [],
  });

  final String id;
  final String clientCode;
  final String? name;
  final String? email;
  final String? phone;
  final String? address;
  final String? taxId;
  final bool isActive;
  final List<LocationModel>? locations;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawLocations = json['locations'];
    final locations = <LocationModel>[];
    if (rawLocations is List) {
      for (final element in rawLocations) {
        if (element is Map<String, dynamic>) {
          locations.add(LocationModel.fromJson(element));
        } else if (element is Map) {
          locations.add(LocationModel.fromJson(Map<String, dynamic>.from(element)));
        }
      }
    }

    final isActiveRaw = json['is_active'] ?? json['isActive'];
    final isActive = isActiveRaw is bool
        ? isActiveRaw
        : isActiveRaw?.toString().toLowerCase() == 'true';

    return UserModel(
      id: json['id']?.toString() ?? '',
      clientCode: json['client_code']?.toString() ?? '',
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      taxId: json['tax_id']?.toString(),
      isActive: isActive,
      locations: locations,
    );
  }

  @override
  List<Object?> get props => [
        id,
        clientCode,
        name,
        email,
        phone,
        address,
        taxId,
        isActive,
        locations,
      ];
}
