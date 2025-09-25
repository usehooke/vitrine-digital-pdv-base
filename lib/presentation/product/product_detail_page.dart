// ignore_for_file: sort_child_properties_last
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/notifiers/auth_state_notifier.dart';
import '../../data/models/product_model.dart';
import '../../data/models/sku_model.dart';
import '../../data/models/variant_model.dart';
import '../../data/repositories/product_repository.dart';
import 'product_detail_controller.dart';

class ProductDetailPage extends StatelessWidget {
  final String productId;
  const ProductDetailPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<ProductRepository>();
    final user = context.watch<AuthStateNotifier>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Produto'),
        actions: [
          if (user != null && user.role == 'admin')
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Apagar Produto',
              onPressed: () => _showDeleteConfirmation(context, repository),
            ),
        ],
      ),
      body: FutureBuilder<ProductModel>(
        future: repository.getProduct(productId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError || !snapshot.hasData) return const Center(child: Text('Erro ao carregar o produto.'));
          final product = snapshot.data!;
          final controller = ProductDetailController(repository, productId);
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(product.name, style: Theme.of(context).textTheme.headlineMedium),
              Text('${product.category} - ${product.model}', style: Theme.of(context).textTheme.titleMedium),
              const Divider(height: 32),
              StreamBuilder<List<VariantModel>>(
                stream: controller.variantsStream,
                builder: (context, variantSnapshot) {
                  if (variantSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!variantSnapshot.hasData || variantSnapshot.data!.isEmpty) return const Text('Nenhuma variante encontrada.');
                  final variants = variantSnapshot.data!;
                  return Column(
                    children: variants.map((variant) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ExpansionTile(
                          leading: variant.imageUrl.isNotEmpty ? Image.network(variant.imageUrl, width: 50, height: 50, fit: BoxFit.cover) : null,
                          title: Text(variant.color, style: const TextStyle(fontWeight: FontWeight.bold)),
                          children: [
                            StreamBuilder<List<SkuModel>>(
                              stream: controller.getSkusStream(variant.id),
                              builder: (context, skuSnapshot) {
                                if (skuSnapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator());
                                if (!skuSnapshot.hasData || skuSnapshot.data!.isEmpty) return const ListTile(title: Text('Nenhum SKU para esta variante.'));
                                final skus = skuSnapshot.data!;
                                return Column(
                                  children: skus.map((sku) {
                                    return ListTile(
                                      title: Text('Tamanho: ${sku.size}'),
                                      subtitle: Text('SKU: ${sku.generatedSku}'),
                                      trailing: Text('Estoque: ${sku.stock} | R\$ ${sku.retailPrice.toStringAsFixed(2)}'),
                                    );
                                  }).toList(),
                                );
                              },
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ProductRepository repository) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text('Tem a certeza de que quer apagar este produto? Esta ação não pode ser desfeita.'),
          actions: [
            TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(dialogContext).pop()),
            FilledButton(
              child: const Text('Apagar'),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                try {
                  await repository.deleteProduct(productId);
                  if (context.mounted) {
                    context.go('/home');
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produto apagado com sucesso!'), backgroundColor: Colors.green));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao apagar o produto.'), backgroundColor: Colors.red));
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}