import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../models/admin_order_model.dart';

class AdminOrderRepositoryException implements Exception {
  AdminOrderRepositoryException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AdminOrderRepository {
  AdminOrderRepository(this._dio);
  final Dio _dio;

  Future<List<AdminOrderModel>> getAllOrders({
    String? status,
    String? clientId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (clientId != null && clientId.isNotEmpty) {
        queryParams['client_id'] = clientId;
      }

      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.adminOrders,
        queryParameters: queryParams,
      );

      final raw = response.data;
      if (raw == null || !raw['success']) {
        throw AdminOrderRepositoryException('Failed to fetch orders.');
      }

      final dataMap = raw['data'] as Map<String, dynamic>?;
      final items = dataMap?['items'] as List<dynamic>? ?? [];
      return items
          .map((e) => AdminOrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw AdminOrderRepositoryException(_messageFromDio(e));
    }
  }

  Future<AdminOrderModel> getOrderById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiConstants.adminOrders}/$id',
      );

      final raw = response.data;
      if (raw == null || !raw['success']) {
        throw AdminOrderRepositoryException('Failed to fetch order.');
      }

      return AdminOrderModel.fromJson(raw['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AdminOrderRepositoryException(_messageFromDio(e));
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '${ApiConstants.adminOrders}/$orderId/status',
        data: {'status': status},
      );

      final raw = response.data;
      if (raw == null || !raw['success']) {
        throw AdminOrderRepositoryException('Failed to update status.');
      }
    } on DioException catch (e) {
      throw AdminOrderRepositoryException(_messageFromDio(e));
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
