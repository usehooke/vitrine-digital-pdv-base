import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/notifiers/auth_state_notifier.dart';
import '../../data/repositories/product_repository.dart';
import '../../presentation/admin/product_form_controller.dart';
import '../../presentation/admin/product_form_page.dart';
import '../../presentation/admin/user_management_page.dart';
import '../../presentation/auth/login_page.dart';
import '../../presentation/home/home_page.dart';
import '../../presentation/pdv/pdv_page.dart';
import '../../presentation/product/product_detail_page.dart';

class AppRouter {
  final AuthStateNotifier authStateNotifier;
  AppRouter(this.authStateNotifier);

  late final GoRouter router = GoRouter(
    refreshListenable: authStateNotifier,
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/pdv', builder: (context, state) => const PdvPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/add-product',
        builder: (context, state) => ChangeNotifierProvider(
          create: (context) => ProductFormController(
            context.read<ProductRepository>(),
          ),
          child: const ProductFormPage(),
        ),
      ),
      GoRoute(
        path: '/product/:productId',
        builder: (context, state) {
          final productId = state.pathParameters['productId']!;
          return ProductDetailPage(productId: productId);
        },
      ),
      GoRoute(
        path: '/user-management',
        builder: (context, state) => const UserManagementPage(),
      ),
      GoRoute(
        path: '/edit-product/:productId',
        builder: (context, state) {
          final productId = state.pathParameters['productId'];
          return ChangeNotifierProvider(
            create: (context) => ProductFormController(
              context.read<ProductRepository>(),
              productId: productId,
            ),
            child: ProductFormPage(productId: productId),
          );
        },
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final authNotifier = context.read<AuthStateNotifier>();
      final bool loggedIn = authNotifier.isAuthenticated;
      final String? userRole = authNotifier.user?.role;
      final String location = state.matchedLocation;
      final isLoginPage = location == '/login';

      // Se não está logado e não está a tentar ir para o login, redireciona para o login
      if (!loggedIn && !isLoginPage) return '/login';

      // Se está logado e na página de login, redireciona para a home
      if (loggedIn && isLoginPage) return '/home';

      // --- LÓGICA DE ADMIN SIMPLIFICADA ---
      // Verifica se a rota atual é uma rota exclusiva de admin
      final isAdminOnlyRoute = location.startsWith('/add-product') ||
                             location.startsWith('/edit-product') ||
                             location.startsWith('/user-management');

      // Se for uma rota de admin e o utilizador não for admin, redireciona para a home
      if (loggedIn && isAdminOnlyRoute && userRole != 'admin') {
        return '/home';
      }

      return null; // Não é necessário redirecionar
    },
  );
}