import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';

import 'app/app.dart';
import 'core/di/injection.dart';
import 'features/orders/logic/cart_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await configureDependencies();
  Bloc.observer = AppBlocObserver();
  runApp(
    BlocProvider<CartCubit>.value(
      value: getIt<CartCubit>(),
      child: const FreApp(),
    ),
  );
}

class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    if (kDebugMode) {
      debugPrint('Bloc created: ${bloc.runtimeType}');
    }
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    if (kDebugMode) {
      debugPrint('${bloc.runtimeType} event: $event');
    }
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    if (kDebugMode) {
      debugPrint('${bloc.runtimeType} $transition');
    }
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('${bloc.runtimeType} error: $error');
    }
    super.onError(bloc, error, stackTrace);
  }
}
