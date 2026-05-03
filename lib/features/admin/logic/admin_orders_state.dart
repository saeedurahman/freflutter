import '../data/models/admin_order_model.dart';

abstract class AdminOrdersState {
  const AdminOrdersState();
}

class AdminOrdersInitial extends AdminOrdersState {
  const AdminOrdersInitial();
}

class AdminOrdersLoading extends AdminOrdersState {
  const AdminOrdersLoading();
}

class AdminOrdersLoaded extends AdminOrdersState {
  const AdminOrdersLoaded(this.orders, {
    this.clientsMap = const {},
    this.locationsMap = const {},
  });
  final List<AdminOrderModel> orders;
  final Map<String, String> clientsMap;
  final Map<String, String> locationsMap;
}

class AdminOrdersError extends AdminOrdersState {
  const AdminOrdersError(this.message);
  final String message;
}

class AdminOrderStatusUpdating extends AdminOrdersState {
  const AdminOrderStatusUpdating();
}

class AdminOrderStatusUpdated extends AdminOrdersState {
  const AdminOrderStatusUpdated();
}
