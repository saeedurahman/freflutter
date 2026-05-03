import 'package:equatable/equatable.dart';

import '../../../products/data/models/product_model.dart';

class CartItemModel extends Equatable {
  const CartItemModel({
    required this.product,
    required this.quantity,
  });

  final ProductModel product;
  final int quantity;

  double get totalPrice => product.pricePerCarton * quantity;

  CartItemModel copyWith({
    ProductModel? product,
    int? quantity,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [product, quantity];
}
