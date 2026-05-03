import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/storage/storage_service.dart';
import '../data/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository, this._storage) : super(const AuthInitial());

  final AuthRepository _repository;
  final StorageService _storage;

  Future<void> loginAsClient(String clientCode, String password) async {
    emit(const AuthLoading());
    try {
      final result = await _repository.loginAsClient(clientCode, password);
      await _storage.saveToken(result.accessToken);
      await _storage.saveRole('client');
      emit(AuthSuccess(result));
    } on AuthRepositoryException catch (e) {
      emit(AuthFailure(e.message));
    } catch (_) {
      emit(
        const AuthFailure(
          'Something went wrong. Please try again.',
        ),
      );
    }
  }

  Future<void> loginAsAdmin(String email, String password) async {
    emit(const AuthLoading());
    try {
      final result = await _repository.loginAsAdmin(email, password);
      await _storage.saveToken(result.accessToken);
      await _storage.saveRole('admin');
      emit(AuthSuccess(result));
    } on AuthRepositoryException catch (e) {
      emit(AuthFailure(e.message));
    } catch (_) {
      emit(
        const AuthFailure(
          'Something went wrong. Please try again.',
        ),
      );
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
    emit(const AuthInitial());
  }
}
