import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/product_repository.dart';
import 'products_state.dart';

class ProductsCubit extends Cubit<ProductsState> {
  ProductsCubit(this._repository) : super(const ProductsInitial());

  final ProductRepository _repository;

  Timer? _searchDebounce;
  String? _lastSearchQuery;

  Future<void> loadProducts() async {
    _lastSearchQuery = null;
    emit(const ProductsLoading());
    try {
      final list = await _repository.getProducts();
      emit(ProductsLoaded(list));
    } on ProductRepositoryException catch (e) {
      emit(ProductsError(e.message));
    } catch (_) {
      emit(
        const ProductsError('Something went wrong. Please try again.'),
      );
    }
  }

  void searchProducts(String query) {
    final trimmed = query.trim();
    _lastSearchQuery = trimmed.isEmpty ? null : trimmed;

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      emit(const ProductSearching());
      try {
        final list = await _repository.getProducts(
          search: _lastSearchQuery,
        );
        emit(ProductsLoaded(list));
      } on ProductRepositoryException catch (e) {
        emit(ProductsError(e.message));
      } catch (_) {
        emit(
          const ProductsError('Something went wrong. Please try again.'),
        );
      }
    });
  }

  Future<void> refresh() async {
    try {
      final list = await _repository.getProducts(search: _lastSearchQuery);
      emit(ProductsLoaded(list));
    } on ProductRepositoryException catch (e) {
      emit(ProductsError(e.message));
    } catch (_) {
      emit(
        const ProductsError('Something went wrong. Please try again.'),
      );
    }
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
