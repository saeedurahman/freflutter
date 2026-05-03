import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../app/router.dart';
import '../constants/api_constants.dart';
import '../storage/storage_service.dart';

class DioClient {
  DioClient({required StorageService storageService})
      : _storageService = storageService,
        dio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _storageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint(
              '[Dio] ${response.requestOptions.method} '
              '${response.requestOptions.uri} '
              '→ ${response.statusCode}',
            );
            debugPrint('[Dio] ${response.data}');
          }
          handler.next(response);
        },
        onError: (error, handler) async {
          final status = error.response?.statusCode;
          if (status == 401) {
            await _storageService.clearAll();
            appRouter.go('/login');
          }
          handler.next(error);
        },
      ),
    );
  }

  final StorageService _storageService;
  final Dio dio;
}
