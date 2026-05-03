import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/admin_client_repository.dart';
import '../data/repositories/admin_order_repository.dart';
import 'admin_orders_state.dart';

class AdminOrdersCubit extends Cubit<AdminOrdersState> {
  AdminOrdersCubit(
    this._repository,
    this._clientRepository,
  ) : super(const AdminOrdersInitial());

  final AdminOrderRepository _repository;
  final AdminClientRepository _clientRepository;

  Future<void> loadOrders({String? status, String? clientId}) async {
    emit(const AdminOrdersLoading());
    try {
      // 1. Fetch all clients
      final clients = await _clientRepository.getAllClients();
      final Map<String, String> clientsMap = {};
      final Map<String, String> locationsMap = {};

      // 2. For each client, fetch their locations
      for (final client in clients) {
        clientsMap[client.id] = client.name;
        
        try {
          final fullClient = await _clientRepository.getClientById(client.id);
          for (final loc in fullClient.locations) {
            locationsMap[loc.id] = loc.label;
          }
        } catch (_) {
          // Skip if individual client fetch fails
        }
      }

      // 3. Fetch orders
      final orders = await _repository.getAllOrders(
        status: status,
        clientId: clientId,
      );

      emit(AdminOrdersLoaded(
        orders,
        clientsMap: clientsMap,
        locationsMap: locationsMap,
      ));
    } on AdminOrderRepositoryException catch (e) {
      emit(AdminOrdersError(e.message));
    } catch (_) {
      emit(const AdminOrdersError('Something went wrong. Please try again.'));
    }
  }

  Future<void> updateStatus(String orderId, String newStatus) async {
    emit(const AdminOrderStatusUpdating());
    try {
      await _repository.updateOrderStatus(orderId, newStatus);
      emit(const AdminOrderStatusUpdated());
      // Re-fetch logic can be called from the UI after getting this state
    } on AdminOrderRepositoryException catch (e) {
      emit(AdminOrdersError(e.message));
    } catch (_) {
      emit(const AdminOrdersError('Something went wrong. Please try again.'));
    }
  }
}
