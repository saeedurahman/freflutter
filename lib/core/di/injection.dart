import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/logic/auth_cubit.dart';
import '../../features/orders/data/repositories/order_repository.dart';
import '../../features/orders/logic/cart_cubit.dart';
import '../../features/orders/logic/order_cubit.dart';
import '../../features/products/data/repositories/product_repository.dart';
import '../../features/products/logic/products_cubit.dart';
import '../../features/profile/data/repositories/profile_repository.dart';
import '../../features/profile/logic/profile_cubit.dart';
import '../../features/admin/data/repositories/admin_order_repository.dart';
import '../../features/admin/data/repositories/admin_product_repository.dart';
import '../../features/admin/data/repositories/admin_client_repository.dart';
import '../../features/admin/logic/admin_orders_cubit.dart';
import '../../features/admin/logic/admin_products_cubit.dart';
import '../../features/admin/logic/admin_clients_cubit.dart';
import '../network/dio_client.dart';
import '../storage/storage_service.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  getIt.registerSingleton<StorageService>(StorageService());

  getIt.registerLazySingleton<DioClient>(
    () => DioClient(storageService: getIt<StorageService>()),
  );

  getIt.registerLazySingleton<Dio>(() => getIt<DioClient>().dio);

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(getIt<Dio>()),
  );
  getIt.registerLazySingleton<ProductRepository>(
    () => ProductRepository(getIt<Dio>()),
  );
  getIt.registerLazySingleton<OrderRepository>(
    () => OrderRepository(getIt<Dio>()),
  );
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepository(getIt<Dio>()),
  );
  getIt.registerLazySingleton<AdminOrderRepository>(
    () => AdminOrderRepository(getIt<Dio>()),
  );
  getIt.registerLazySingleton<AdminProductRepository>(
    () => AdminProductRepository(getIt<Dio>()),
  );
  getIt.registerLazySingleton<AdminClientRepository>(
    () => AdminClientRepository(getIt<Dio>()),
  );

  getIt.registerLazySingleton<CartCubit>(() => CartCubit());

  getIt.registerFactory<AuthCubit>(
    () => AuthCubit(
      getIt<AuthRepository>(),
      getIt<StorageService>(),
    ),
  );
  getIt.registerFactory<ProductsCubit>(
    () => ProductsCubit(getIt<ProductRepository>()),
  );
  getIt.registerFactory<OrderCubit>(
    () => OrderCubit(
      getIt<OrderRepository>(),
      getIt<CartCubit>(),
    ),
  );
  getIt.registerFactory<ProfileCubit>(
    () => ProfileCubit(getIt<ProfileRepository>()),
  );
  getIt.registerFactory<AdminOrdersCubit>(
    () => AdminOrdersCubit(
      getIt<AdminOrderRepository>(),
      getIt<AdminClientRepository>(),
    ),
  );
  getIt.registerFactory<AdminProductsCubit>(
    () => AdminProductsCubit(getIt<AdminProductRepository>()),
  );
  getIt.registerFactory<AdminClientsCubit>(
    () => AdminClientsCubit(getIt<AdminClientRepository>()),
  );
}
