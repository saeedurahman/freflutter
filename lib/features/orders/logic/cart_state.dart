import 'package:equatable/equatable.dart';

import '../data/models/cart_item_model.dart';

class CartState extends Equatable {
  const CartState({this.items = const []});

  final List<CartItemModel> items;

  int get totalItems =>
      items.fold<int>(0, (sum, e) => sum + e.quantity);

  double get totalPrice =>
      items.fold<double>(0, (sum, e) => sum + e.totalPrice);

  bool get isEmpty => items.isEmpty;

  CartState copyWith({
    List<CartItemModel>? items,
  }) {
    return CartState(items: items ?? this.items);
  }

  @override
  List<Object?> get props => [items];
}
