import 'package:equatable/equatable.dart';

class LocationModel extends Equatable {
  const LocationModel({
    required this.id,
    required this.clientId,
    required this.label,
    required this.address,
    required this.isDefault,
  });

  final String id;
  final String clientId;
  final String label;
  final String address;
  final bool isDefault;

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    final defaultRaw = json['is_default'] ?? json['isDefault'];
    final isDefault = defaultRaw is bool
        ? defaultRaw
        : defaultRaw?.toString().toLowerCase() == 'true';

    return LocationModel(
      id: json['id']?.toString() ?? '',
      clientId:
          (json['client_id'] ?? json['clientId'])?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      isDefault: isDefault,
    );
  }

  @override
  List<Object?> get props => [id, clientId, label, address, isDefault];
}
