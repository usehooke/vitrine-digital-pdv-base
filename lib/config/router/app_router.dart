// CONTEÚDO COMPLETO PARA: lib/config/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/notifiers/auth_state_notifier.dart';
import '../../presentation/admin/product_form_page.dart';
import '../../presentation/auth/login_page.dart';
import '../../presentation/home/home_page.dart';
import '../../presentation/pdv/pdv_page.dart';
import '../../presentation/product/product_detail_page.dart';


class AppRouter {
  final AuthStateNotifier authStateNotifier;
  AppRouter(this.authStateNotifier);

  late final GoRouter router = GoRouter(
    refreshListenable: authStateNotifier,
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/pdv', builder: (context, state) => const PdvPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      GoRoute(path: '/add-product', builder: (context, state) => const ProductFormPage()),
      GoRoute(
        path: '/product/:productId',
        builder: (context, state) {
          final productId = state.pathParameters['productId']!;
          return ProductDetailPage(productId: productId);
        },
      ),
      GoRoute(
        path: '/edit-product/:productId',
        builder: (context, state) {
          final productId = state.pathParameters['productId']!;
          return ProductFormPage(productId: productId);
        },
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = authStateNotifier.isLoggedIn;
      final userRole = authStateNotifier.user?.role;
      final String location = state.matchedLocation;

      // ###############################################################
      // ## O "ESPIÃO" FICA AQUI                                      ##
      print('--- PASSO 2 (ROUTER): Verificando rota. Destino: $location. Logado: $loggedIn, Papel: $userRole');
      // ###############################################################

      if (!loggedIn && location != '/login') {
        return '/login';
      }
      if (loggedIn && location == '/login') {
        return '/home';
      }
      return null;
    },
  );
}