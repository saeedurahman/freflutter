import '../data/models/admin_product_model.dart';

abstract class AdminProductsState {
  const AdminProductsState();
}

class AdminProductsInitial extends AdminProductsState {
  const AdminProductsInitial();
}

class AdminProductsLoading extends AdminProductsState {
  const AdminProductsLoading();
}

class AdminProductsLoaded extends AdminProductsState {
  const AdminProductsLoaded(this.products);
  final List<AdminProductModel> products;
}

class AdminProductsError extends AdminProductsState {
  const AdminProductsError(this.message);
  final String message;
}

class AdminProductCreating extends AdminProductsState {
  const AdminProductCreating();
}

class AdminProductCreated extends AdminProductsState {
  const AdminProductCreated();
}

class AdminProductUpdating extends AdminProductsState {
  const AdminProductUpdating();
}

class AdminProductUpdated extends AdminProductsState {
  const AdminProductUpdated();
}
