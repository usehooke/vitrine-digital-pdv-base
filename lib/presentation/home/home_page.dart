import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/notifiers/auth_state_notifier.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';
import '../widgets/product_card.dart';
import 'home_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Funções auxiliares para deixar o 'build' mais limpo
  bool _isAdmin(user) => user?.role == 'admin';
  bool _isPDV(user) => user?.role == 'pdv';

  @override
  Widget build(BuildContext context) {
    final controller = HomeController(context.read<ProductRepository>());
    final user = context.watch<AuthStateNotifier>().user;

    // Usamos debugPrint para logs mais detalhados
    debugPrint('--- ROLE DO UTILIZADOR NA HOME: ${user?.role ?? 'Nenhum (a carregar)'} ---');

    // Mostra um indicador de carregamento enquanto o estado de autenticação é verificado
    if (user == null && !context.read<AuthStateNotifier>().isAuthCheckComplete) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vitrine de Produtos'),
        actions: [
          if (_isAdmin(user))
            IconButton(
              icon: const Icon(Icons.manage_accounts),
              tooltip: 'Gerir Utilizadores',
              onPressed: () => context.go('/user-management'),
            ),
          if (_isPDV(user))
            IconButton(
              icon: const Icon(Icons.point_of_sale),
              tooltip: 'Ponto de Venda',
              onPressed: () => context.go('/pdv'),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => context.read<AuthStateNotifier>().logout(),
          ),
        ],
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: controller.productsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ocorreu um erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum produto encontrado.'));
          }

          final products = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 250,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final route = _isAdmin(user)
                  ? '/edit-product/${product.id}'
                  : '/product/${product.id}';
              return ProductCard(
                product: product,
                onTap: () => context.go(route),
              );
            },
          );
        },
      ),
      floatingActionButton: _isAdmin(user)
          ? FloatingActionButton(
              onPressed: () => context.go('/add-product'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}