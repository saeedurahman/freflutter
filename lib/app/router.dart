import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injection.dart';
import '../core/storage/storage_service.dart';
import '../features/auth/logic/auth_cubit.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/orders/logic/order_cubit.dart';
import '../features/orders/presentation/cart_screen.dart';
import '../features/orders/presentation/order_success_screen.dart';
import '../features/products/presentation/product_detail_screen.dart';
import '../features/profile/logic/profile_cubit.dart';
import '../features/splash/splash_screen.dart';
import '../features/admin/presentation/admin_main_screen.dart';
import '../features/admin/presentation/admin_order_detail_screen.dart';
import '../features/admin/presentation/admin_client_detail_screen.dart';
import '../presentation/main_screen.dart';

bool _requiresAuth(String path) {
  return path.startsWith('/home') ||
      path.startsWith('/admin') ||
      path == '/cart' ||
      path == '/order-success';
}

int _homeTabIndex(GoRouterState state) {
  switch (state.uri.queryParameters['tab']) {
    case 'products':
      return 1;
    case 'orders':
      return 2;
    case 'profile':
      return 3;
    default:
      return 0;
  }
}

String? _authRedirect(BuildContext context, GoRouterState state) {
  final storage = getIt<StorageService>();
  final loggedIn = storage.isLoggedIn();
  final role = storage.getRole();
  final path = state.uri.path;

  if (path == '/splash') {
    return null;
  }
  if (path == '/') {
    return '/splash';
  }
  if (!loggedIn && _requiresAuth(path)) {
    return '/login';
  }
  if (loggedIn) {
    if (path == '/login') {
      return role == 'admin' ? '/admin' : '/home';
    }
    
    // Role-based guarding
    if (role == 'admin' && (path.startsWith('/home') || path == '/cart' || path == '/order-success')) {
      return '/admin';
    }
    if (role == 'client' && path.startsWith('/admin')) {
      return '/home';
    }
  }
  return null;
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: _authRedirect,
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => BlocProvider(
        create: (_) => getIt<AuthCubit>(),
        child: const LoginScreen(),
      ),
    ),
    GoRoute(
      path: '/home/products/:id',
      builder: (context, state) => ProductDetailScreen(
        productId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/cart',
      builder: (context, state) => BlocProvider(
        create: (_) => getIt<OrderCubit>(),
        child: const CartScreen(),
      ),
    ),
    GoRoute(
      path: '/order-success',
      builder: (context, state) {
        final extra = state.extra as OrderSuccessExtra?;
        if (extra == null) {
          return Scaffold(
            body: Center(
              child: Text(
                'Missing order details.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          );
        }
        return OrderSuccessScreen(extra: extra);
      },
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) {
        final tab = _homeTabIndex(state);
        final tabKey = state.uri.queryParameters['tab'] ?? 'home';
        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => getIt<ProfileCubit>()..loadProfile(),
            ),
            BlocProvider(
              create: (_) => getIt<OrderCubit>(),
            ),
          ],
          child: MainScreen(
            key: ValueKey(tabKey),
            initialTabIndex: tab,
          ),
        );
      },
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminMainScreen(),
    ),
    GoRoute(
      path: '/admin/orders/:id',
      builder: (context, state) => AdminOrderDetailScreen(
        orderId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/admin/clients/:id',
      builder: (context, state) => AdminClientDetailScreen(
        clientId: state.pathParameters['id']!,
      ),
    ),
  ],
);
