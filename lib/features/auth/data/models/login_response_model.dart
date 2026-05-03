import 'package:equatable/equatable.dart';

class LoginResponseModel extends Equatable {
  const LoginResponseModel({
    required this.success,
    this.message,
    required this.accessToken,
    required this.tokenType,
    required this.statusCode,
  });

  final bool success;
  final String? message;
  final String accessToken;
  final String tokenType;
  final int statusCode;

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    Map<String, dynamic>? dataMap;
    if (data is Map<String, dynamic>) {
      dataMap = data;
    } else if (data is Map) {
      dataMap = Map<String, dynamic>.from(data);
    }

    return LoginResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      accessToken: dataMap?['access_token'] as String? ?? '',
      tokenType: dataMap?['token_type'] as String? ?? 'bearer',
      statusCode: json['status_code'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props =>
      [success, message, accessToken, tokenType, statusCode];
}
