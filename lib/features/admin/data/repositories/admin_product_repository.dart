import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../models/admin_product_model.dart';

class AdminProductRepositoryException implements Exception {
  AdminProductRepositoryException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AdminProductRepository {
  AdminProductRepository(this._dio);
  final Dio _dio;

  Future<List<AdminProductModel>> getAllProducts({bool? isActive}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (isActive != null) {
        queryParams['is_active'] = isActive.toString();
      }

      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.adminProducts,
        queryParameters: queryParams,
      );

      final raw = response.data;
      if (raw == null || !raw['success']) {
        throw AdminProductRepositoryException('Failed to fetch products.');
      }

      final dataMap = raw['data'] as Map<String, dynamic>?;
      final items = dataMap?['items'] as List<dynamic>? ?? [];
      return items
          .map((e) => AdminProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw AdminProductRepositoryException(_messageFromDio(e));
    }
  }

  Future<void> createProduct(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.adminProducts,
        data: data,
      );

      final raw = response.data;
      if (raw == null || !raw['success']) {
        throw AdminProductRepositoryException('Failed to create product.');
      }
    } on DioException catch (e) {
      throw AdminProductRepositoryException(_messageFromDio(e));
    }
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '${ApiConstants.adminProducts}/$id',
        data: data,
      );

      final raw = response.data;
      if (raw == null || !raw['success']) {
        throw AdminProductRepositoryException('Failed to update product.');
      }
    } on DioException catch (e) {
      throw AdminProductRepositoryException(_messageFromDio(e));
    }
  }

  Future<void> deactivateProduct(String id) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '${ApiConstants.adminProducts}/$id',
      );

      final raw = response.data;
      if (raw == null || !raw['success']) {
        throw AdminProductRepositoryException('Failed to deactivate product.');
      }
    } on DioException catch (e) {
      throw AdminProductRepositoryException(_messageFromDio(e));
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
