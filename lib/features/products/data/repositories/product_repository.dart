import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../models/product_model.dart';

class ProductRepositoryException implements Exception {
  ProductRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProductRepository {
  ProductRepository(this._dio);

  final Dio _dio;

  Future<List<ProductModel>> getProducts({String? search}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.products,
        queryParameters: <String, dynamic>{
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          'page': 1,
          'limit': 20,
        },
      );

      return _parseProductList(response.data);
    } on DioException catch (e) {
      throw ProductRepositoryException(_messageFromDio(e));
    }
  }

  Future<ProductModel> getProductById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiConstants.products}/$id',
      );

      final raw = response.data;
      final map = _unwrapDataMap(raw);
      if (map == null) {
        throw ProductRepositoryException('Invalid product response.');
      }

      return ProductModel.fromJson(map);
    } on DioException catch (e) {
      throw ProductRepositoryException(_messageFromDio(e));
    }
  }

  List<ProductModel> _parseProductList(Map<String, dynamic>? body) {
    if (body == null) return [];

    final dynamic root = body['data'] ?? body['products'] ?? body['items'] ?? body;

    if (root is List) {
      return root
          .whereType<Map>()
          .map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    if (root is Map<String, dynamic>) {
      final inner = root['items'] ?? root['data'] ?? root['results'];
      if (inner is List) {
        return inner
            .whereType<Map>()
            .map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }

    return [];
  }

  Map<String, dynamic>? _unwrapDataMap(Map<String, dynamic>? body) {
    if (body == null) return null;

    final data = body['data'] ?? body['product'] ?? body['item'];
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
        if (code == 404) return 'Product not found.';
        return 'Could not load products (${code ?? 'error'}).';
      default:
        return e.message?.isNotEmpty == true
            ? e.message!
            : 'Something went wrong. Please try again.';
    }
  }
}
