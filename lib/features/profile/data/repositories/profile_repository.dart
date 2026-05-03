import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../models/user_model.dart';

class ProfileRepositoryException implements Exception {
  ProfileRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProfileRepository {
  ProfileRepository(this._dio);

  final Dio _dio;

  Future<UserModel> getProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(ApiConstants.me);
      final raw = response.data;
      if (raw == null) {
        throw ProfileRepositoryException('Empty response from server.');
      }
      
      final data = raw['data'];
      if (data == null) {
        return UserModel.fromJson(raw);
      }
      return UserModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ProfileRepositoryException(_messageFromDio(e));
    }
  }

  String _messageFromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'];
      if (msg != null && msg.toString().isNotEmpty) {
        return msg.toString();
      }
    }
    return e.message ?? 'Failed to load profile.';
  }
}
