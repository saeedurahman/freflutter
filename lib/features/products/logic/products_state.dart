import 'package:equatable/equatable.dart';

import '../data/models/product_model.dart';

sealed class ProductsState extends Equatable {
  const ProductsState();

  @override
  List<Object?> get props => [];
}

class ProductsInitial extends ProductsState {
  const ProductsInitial();
}

class ProductsLoading extends ProductsState {
  const ProductsLoading();
}

class ProductsLoaded extends ProductsState {
  const ProductsLoaded(this.products);

  final List<ProductModel> products;

  @override
  List<Object?> get props => [products];
}

class ProductsError extends ProductsState {
  const ProductsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ProductSearching extends ProductsState {
  const ProductSearching();
}
