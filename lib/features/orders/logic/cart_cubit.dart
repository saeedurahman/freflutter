import 'package:flutter_bloc/flutter_bloc.dart';

import '../../products/data/models/product_model.dart';
import '../data/models/cart_item_model.dart';
import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState());

  void addToCart(ProductModel product, int quantity) {
    if (quantity <= 0) return;
    final list = List<CartItemModel>.from(state.items);
    final idx = list.indexWhere((e) => e.product.id == product.id);
    if (idx >= 0) {
      final existing = list[idx];
      list[idx] = existing.copyWith(quantity: existing.quantity + quantity);
    } else {
      list.add(CartItemModel(product: product, quantity: quantity));
    }
    emit(state.copyWith(items: list));
  }

  void removeFromCart(String productId) {
    final list =
        state.items.where((e) => e.product.id != productId).toList();
    emit(state.copyWith(items: list));
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    final list = List<CartItemModel>.from(state.items);
    final idx = list.indexWhere((e) => e.product.id == productId);
    if (idx < 0) return;
    list[idx] = list[idx].copyWith(quantity: quantity);
    emit(state.copyWith(items: list));
  }

  void clearCart() {
    emit(const CartState());
  }

  int getQuantity(String productId) {
    try {
      return state.items
          .firstWhere((e) => e.product.id == productId)
          .quantity;
    } catch (_) {
      return 0;
    }
  }
}
