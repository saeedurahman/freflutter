import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

class FreApp extends StatelessWidget {
  const FreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FreshOrder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
