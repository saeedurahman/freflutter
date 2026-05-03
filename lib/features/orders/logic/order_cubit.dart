import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/cart_item_model.dart';
import '../data/models/order_model.dart';
import '../data/repositories/order_repository.dart';
import 'cart_cubit.dart';
import 'order_state.dart';

class OrderCubit extends Cubit<OrderState> {
  OrderCubit(
    this._repository,
    this._cartCubit,
  ) : super(const OrderInitial());

  final OrderRepository _repository;
  final CartCubit _cartCubit;

  Future<void> loadLocations() async {
    emit(const OrderLoading());
    try {
      final list = await _repository.getMyLocations();
      emit(LocationsLoaded(list));
    } on OrderRepositoryException catch (e) {
      emit(OrderFailure(e.message));
    } catch (_) {
      emit(
        const OrderFailure(
          'Could not load locations. Please try again.',
        ),
      );
    }
  }

  Future<OrderModel?> placeOrder(String locationId, List<CartItemModel> items) async {
    if (items.isEmpty) return null;
    emit(const OrderPlacing());
    try {
      final order = await _repository.placeOrder(locationId, items);
      _cartCubit.clearCart();
      emit(OrderSuccess(order));
      return order;
    } on OrderRepositoryException catch (e) {
      emit(OrderFailure(e.message));
    } catch (_) {
      emit(
        const OrderFailure(
          'Could not place order. Please try again.',
        ),
      );
    }
    return null;
  }

  Future<void> loadMyOrders({String? status}) async {
    emit(const OrderLoading());
    try {
      final list = await _repository.getMyOrders(status: status);
      emit(OrdersLoaded(list));
    } on OrderRepositoryException catch (e) {
      emit(OrderFailure(e.message));
    } catch (_) {
      emit(
        const OrderFailure(
          'Could not load orders. Please try again.',
        ),
      );
    }
  }

  Future<void> loadOrderById(String id) async {
    emit(const OrderLoading());
    try {
      final order = await _repository.getOrderById(id);
      emit(OrderSuccess(order));
    } on OrderRepositoryException catch (e) {
      emit(OrderFailure(e.message));
    } catch (_) {
      emit(
        const OrderFailure(
          'Could not load order. Please try again.',
        ),
      );
    }
  }

  void reset() {
    emit(const OrderInitial());
  }
}
