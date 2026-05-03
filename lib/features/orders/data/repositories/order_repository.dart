import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../models/cart_item_model.dart';
import '../models/location_model.dart';
import '../models/order_model.dart';

class OrderRepositoryException implements Exception {
  OrderRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OrderRepository {
  OrderRepository(this._dio);

  final Dio _dio;

  Future<List<LocationModel>> getMyLocations() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.myLocations,
      );
      return _parseLocationList(response.data);
    } on DioException catch (e) {
      throw OrderRepositoryException(_messageFromDio(e));
    }
  }

  Future<OrderModel> placeOrder(String locationId, List<CartItemModel> items) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.orders,
        data: <String, dynamic>{
          'location_id': locationId,
          'items': items
              .map(
                (e) => <String, dynamic>{
                  'product_id': e.product.id,
                  'quantity': e.quantity,
                },
              )
              .toList(),
        },
      );

      final map = _unwrapOrderMap(response.data);
      if (map == null) {
        throw OrderRepositoryException('Invalid order response.');
      }
      return OrderModel.fromJson(map);
    } on DioException catch (e) {
      throw OrderRepositoryException(_messageFromDio(e));
    }
  }

  Future<List<OrderModel>> getMyOrders({String? status}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.orders,
        queryParameters: <String, dynamic>{
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );
      return _parseOrderList(response.data);
    } on DioException catch (e) {
      throw OrderRepositoryException(_messageFromDio(e));
    }
  }

  Future<OrderModel> getOrderById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiConstants.orders}/$id',
      );
      final map = _unwrapOrderMap(response.data);
      if (map == null) {
        throw OrderRepositoryException('Invalid order response.');
      }
      return OrderModel.fromJson(map);
    } on DioException catch (e) {
      throw OrderRepositoryException(_messageFromDio(e));
    }
  }

  List<LocationModel> _parseLocationList(Map<String, dynamic>? body) {
    if (body == null) return [];

    final root = body['data'] ?? body['locations'] ?? body['items'] ?? body;
    if (root is List) {
      return root
          .whereType<Map>()
          .map((e) => LocationModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  List<OrderModel> _parseOrderList(Map<String, dynamic>? body) {
    if (body == null) return [];

    final root = body['data'] ?? body['orders'] ?? body['items'] ?? body;
    if (root is List) {
      return root
          .whereType<Map>()
          .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (root is Map) {
      final inner = root['items'] ?? root['data'] ?? root['results'];
      if (inner is List) {
        return inner
            .whereType<Map>()
            .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    return [];
  }

  Map<String, dynamic>? _unwrapOrderMap(Map<String, dynamic>? body) {
    if (body == null) return null;
    final data = body['data'] ?? body['order'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (body.containsKey('id')) return body;
    return null;
  }

  String _messageFromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'] ?? data['error'];
      if (msg != null && msg.toString().isNotEmpty) {
        return msg.toString();
      }
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please try again.';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        return 'Request failed (${code ?? 'error'}).';
      default:
        return e.message?.isNotEmpty == true
            ? e.message!
            : 'Something went wrong. Please try again.';
    }
  }
}
