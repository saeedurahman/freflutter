import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../models/login_response_model.dart';

class AuthRepositoryException implements Exception {
  AuthRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<LoginResponseModel> loginAsClient(String clientCode, String password) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.clientLogin,
        data: <String, dynamic>{
          'client_code': clientCode,
          'password': password,
        },
      );

      final raw = response.data;
      if (raw == null) {
        throw AuthRepositoryException('Empty response from server.');
      }

      final model = LoginResponseModel.fromJson(raw);
      if (!model.success || model.accessToken.isEmpty) {
        throw AuthRepositoryException(
          model.message?.isNotEmpty == true
              ? model.message!
              : 'Login failed. Please check your credentials.',
        );
      }

      return model;
    } on DioException catch (e) {
      throw AuthRepositoryException(_messageFromDio(e));
    }
  }

  Future<LoginResponseModel> loginAsAdmin(String email, String password) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.adminLogin,
        data: <String, dynamic>{
          'email': email,
          'password': password,
        },
      );

      final raw = response.data;
      if (raw == null) {
        throw AuthRepositoryException('Empty response from server.');
      }

      final model = LoginResponseModel.fromJson(raw);
      if (!model.success || model.accessToken.isEmpty) {
        throw AuthRepositoryException(
          model.message?.isNotEmpty == true
              ? model.message!
              : 'Admin login failed. Please check your credentials.',
        );
      }

      return model;
    } on DioException catch (e) {
      throw AuthRepositoryException(_messageFromDio(e));
    }
  }

  String _messageFromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'];
      if (msg != null && msg.toString().isNotEmpty) {
        return msg.toString();
      }
      final err = data['error'];
      if (err != null && err.toString().isNotEmpty) {
        return err.toString();
      }
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Check your network and try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please try again.';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 401 || code == 403) {
          return 'Invalid client code or password.';
        }
        return 'Server error (${code ?? 'unknown'}). Please try again.';
      default:
        return e.message?.isNotEmpty == true
            ? e.message!
            : 'Something went wrong. Please try again.';
    }
  }
}
