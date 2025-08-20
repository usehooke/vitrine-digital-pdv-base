// CONTEÚDO CORRETO E FINAL PARA: lib/presentation/home/home_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/notifiers/auth_state_notifier.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../widgets/product_card.dart';
import 'home_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = HomeController(context.read<ProductRepository>());
    final user = context.watch<AuthStateNotifier>().user;
    print('--- PASSO 3 (HOME PAGE): Construindo a página. Utilizador é nulo? ${user == null}. Papel: ${user?.role}');


    return Scaffold(
      appBar: AppBar(
        title: const Text('Vitrine de Produtos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () {
              context.read<AuthStateNotifier>().setUser(null);
            },
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
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                onTap: () {
                  if (user != null && user.role == 'admin') {
                    context.go('/edit-product/${product.id}');
                  } else {
                    context.go('/product/${product.id}');
                  }
                },
                onLongPress: () {
                  if (user != null && user.role == 'admin') {
                    context.go('/product/${product.id}');
                  }
                },
              );
            },
          );
        },
      ),
      // A LÓGICA CORRETA PARA MOSTRAR O BOTÃO ESTÁ AQUI
      floatingActionButton: (user != null)
          ? FloatingActionButton(
              onPressed: () {
                if (user.role == 'admin') {
                  context.go('/add-product');
                } else {
                  context.go('/pdv');
                }
              },
              backgroundColor: Theme.of(context).primaryColor,
              child: Icon(user.role == 'admin' ? Icons.add : Icons.point_of_sale),
            )
          : null,
    );
  }
}