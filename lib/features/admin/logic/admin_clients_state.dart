import '../data/models/admin_client_model.dart';

abstract class AdminClientsState {
  const AdminClientsState();
}

class AdminClientsInitial extends AdminClientsState {
  const AdminClientsInitial();
}

class AdminClientsLoading extends AdminClientsState {
  const AdminClientsLoading();
}

class AdminClientsLoaded extends AdminClientsState {
  const AdminClientsLoaded(this.clients);
  final List<AdminClientModel> clients;
}

class AdminClientDetailLoaded extends AdminClientsState {
  const AdminClientDetailLoaded(this.client, this.locations);
  final AdminClientModel client;
  final List<AdminLocationModel> locations;
}

class AdminClientsError extends AdminClientsState {
  const AdminClientsError(this.message);
  final String message;
}

class AdminClientCreating extends AdminClientsState {
  const AdminClientCreating();
}

class AdminClientCreated extends AdminClientsState {
  const AdminClientCreated();
}
