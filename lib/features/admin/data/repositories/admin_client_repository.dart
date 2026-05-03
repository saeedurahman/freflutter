import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../models/admin_client_model.dart';

class AdminClientRepositoryException implements Exception {
  AdminClientRepositoryException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AdminClientRepository {
  AdminClientRepository(this._dio);
  final Dio _dio;

  Future<List<AdminClientModel>> getAllClients() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.adminClients,
      );

      final raw = response.data;
      if (raw == null || !raw['success']) {
        throw AdminClientRepositoryException('Failed to fetch clients.');
      }

      final dataMap = raw['data'] as Map<String, dynamic>?;
      final items = dataMap?['items'] as List<dynamic>? ?? [];
      return items
          .map((e) => AdminClientModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw AdminClientRepositoryException(_messageFromDio(e));
    }
  }

  Future<AdminClientModel> getClientById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiConstants.adminClients}/$id',
      );

      final raw = response.data;
      if (raw == null || !raw['success']) {
        throw AdminClientRepositoryException('Failed to fetch client detail.');
      }

      // Detail endpoint returns: { data: { client: {...}, locations: [...] } }
      final dataMap = raw['data'] as Map<String, dynamic>;
      final clientJson = dataMap['client'] as Map<String, dynamic>;
      final locationsJson = dataMap['locations'] as List<dynamic>? ?? [];

      // Inject locations into client JSON so fromJson can parse them
      final mergedJson = <String, dynamic>{
        ...clientJson,
        'locations': locationsJson,
      };

      return AdminClientModel.fromJson(mergedJson);
    } on DioException catch (e) {
      throw AdminClientRepositoryException(_messageFromDio(e));
    }
  }

  Future<void> createClient(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.adminClients,
        data: data,
      );

      final raw = response.data;
      if (raw == null || !raw['success']) {
        throw AdminClientRepositoryException('Failed to create client.');
      }
    } on DioException catch (e) {
      throw AdminClientRepositoryException(_messageFromDio(e));
    }
  }

  Future<void> addLocation(String clientId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiConstants.adminClients}/$clientId/locations',
        data: data,
      );

      final raw = response.data;
      if (raw == null || !raw['success']) {
        throw AdminClientRepositoryException('Failed to add location.');
      }
    } on DioException catch (e) {
      throw AdminClientRepositoryException(_messageFromDio(e));
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
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Check your network and try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
