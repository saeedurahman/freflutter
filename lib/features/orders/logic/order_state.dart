import 'package:equatable/equatable.dart';

import '../data/models/location_model.dart';
import '../data/models/order_model.dart';

sealed class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {
  const OrderInitial();
}

class OrderLoading extends OrderState {
  const OrderLoading();
}

class LocationsLoaded extends OrderState {
  const LocationsLoaded(this.locations);

  final List<LocationModel> locations;

  @override
  List<Object?> get props => [locations];
}

class OrderPlacing extends OrderState {
  const OrderPlacing();
}

class OrderSuccess extends OrderState {
  const OrderSuccess(this.order);

  final OrderModel order;

  @override
  List<Object?> get props => [order];
}

class OrderFailure extends OrderState {
  const OrderFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class OrdersLoaded extends OrderState {
  const OrdersLoaded(this.orders);

  final List<OrderModel> orders;

  @override
  List<Object?> get props => [orders];
}
