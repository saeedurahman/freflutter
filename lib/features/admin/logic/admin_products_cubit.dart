import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/admin_product_repository.dart';
import 'admin_products_state.dart';

class AdminProductsCubit extends Cubit<AdminProductsState> {
  AdminProductsCubit(this._repository) : super(const AdminProductsInitial());

  final AdminProductRepository _repository;

  Future<void> loadProducts({bool? isActive}) async {
    emit(const AdminProductsLoading());
    try {
      final products = await _repository.getAllProducts(isActive: isActive);
      emit(AdminProductsLoaded(products));
    } on AdminProductRepositoryException catch (e) {
      emit(AdminProductsError(e.message));
    } catch (_) {
      emit(const AdminProductsError('Something went wrong. Please try again.'));
    }
  }

  Future<void> createProduct(Map<String, dynamic> data) async {
    emit(const AdminProductCreating());
    try {
      await _repository.createProduct(data);
      emit(const AdminProductCreated());
    } on AdminProductRepositoryException catch (e) {
      emit(AdminProductsError(e.message));
    } catch (_) {
      emit(const AdminProductsError('Something went wrong. Please try again.'));
    }
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    emit(const AdminProductUpdating());
    try {
      await _repository.updateProduct(id, data);
      emit(const AdminProductUpdated());
    } on AdminProductRepositoryException catch (e) {
      emit(AdminProductsError(e.message));
    } catch (_) {
      emit(const AdminProductsError('Something went wrong. Please try again.'));
    }
  }

  Future<void> deactivateProduct(String id) async {
    emit(const AdminProductUpdating());
    try {
      await _repository.deactivateProduct(id);
      emit(const AdminProductUpdated());
    } on AdminProductRepositoryException catch (e) {
      emit(AdminProductsError(e.message));
    } catch (_) {
      emit(const AdminProductsError('Something went wrong. Please try again.'));
    }
  }
}
