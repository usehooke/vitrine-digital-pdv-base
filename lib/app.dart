// lib/app.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/router/app_router.dart';
import 'config/theme/app_theme.dart';
import 'core/notifiers/auth_state_notifier.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Lemos o notifier e criamos o router com ele.
    final authNotifier = context.watch<AuthStateNotifier>();
    final router = AppRouter(authNotifier).router;

    return MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
    );
  }
}