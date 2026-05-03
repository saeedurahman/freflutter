import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/admin_client_repository.dart';
import 'admin_clients_state.dart';

class AdminClientsCubit extends Cubit<AdminClientsState> {
  AdminClientsCubit(this._repository) : super(const AdminClientsInitial());

  final AdminClientRepository _repository;

  Future<void> loadClients() async {
    emit(const AdminClientsLoading());
    try {
      final clients = await _repository.getAllClients();
      emit(AdminClientsLoaded(clients));
    } on AdminClientRepositoryException catch (e) {
      emit(AdminClientsError(e.message));
    } catch (_) {
      emit(const AdminClientsError('Something went wrong. Please try again.'));
    }
  }

  Future<void> loadClientDetail(String id) async {
    emit(const AdminClientsLoading());
    try {
      final client = await _repository.getClientById(id);
      emit(AdminClientDetailLoaded(client, client.locations));
    } on AdminClientRepositoryException catch (e) {
      emit(AdminClientsError(e.message));
    } catch (_) {
      emit(const AdminClientsError('Something went wrong. Please try again.'));
    }
  }

  Future<void> createClient(Map<String, dynamic> data) async {
    emit(const AdminClientCreating());
    try {
      await _repository.createClient(data);
      emit(const AdminClientCreated());
    } on AdminClientRepositoryException catch (e) {
      emit(AdminClientsError(e.message));
    } catch (_) {
      emit(const AdminClientsError('Something went wrong. Please try again.'));
    }
  }

  Future<void> addLocation(String clientId, Map<String, dynamic> data) async {
    emit(const AdminClientCreating());
    try {
      await _repository.addLocation(clientId, data);
      emit(const AdminClientCreated());
    } on AdminClientRepositoryException catch (e) {
      emit(AdminClientsError(e.message));
    } catch (_) {
      emit(const AdminClientsError('Something went wrong. Please try again.'));
    }
  }
}
