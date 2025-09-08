import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/notifiers/auth_state_notifier.dart';
import '../../data/models/product_model.dart';
import '../../data/models/sku_model.dart';
import '../../data/models/variant_model.dart';
import '../../data/repositories/product_repository.dart';
import '../widgets/product_card.dart';
import 'pdv_controller.dart';

class PdvPage extends StatelessWidget {
  const PdvPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthStateNotifier>().user;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Erro: Utilizador não encontrado.')),
      );
    }

    return ChangeNotifierProvider(
      create: (context) => PdvController(context.read<ProductRepository>(), user),
      child: Scaffold(
        appBar: AppBar(title: const Text('Ponto de Venda')),
        body: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: ProductGrid()),
            Expanded(flex: 2, child: CartView()),
          ],
        ),
      ),
    );
  }
}

class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final productRepo = context.read<ProductRepository>();
    return StreamBuilder<List<ProductModel>>(
      stream: productRepo.getProductsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erro ao carregar produtos: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data!;
        if (products.isEmpty) {
          return const Center(child: Text('Nenhum produto encontrado.'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.8,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ProductCard(
              product: product,
              onTap: () => _showVariantSelectionDialog(context, product),
            );
          },
        );
      },
    );
  }

  void _showVariantSelectionDialog(BuildContext context, ProductModel product) {
    final productRepo = context.read<ProductRepository>();
    final pdvController = context.read<PdvController>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Selecione a Variante para "${product.name}"'),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<List<VariantModel>>(
              stream: productRepo.getVariantsStream(product.id),
              builder: (context, variantSnapshot) {
                if (variantSnapshot.hasError) {
                  return Center(child: Text('Erro: ${variantSnapshot.error}'));
                }
                if (!variantSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final variants = variantSnapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: variants.length,
                  itemBuilder: (context, index) {
                    final variant = variants[index];
                    return ExpansionTile(
                      leading: Image.network(
                        variant.imageUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                      title: Text(variant.color),
                      children: [
                        StreamBuilder<List<SkuModel>>(
                          stream: productRepo.getSkusStream(product.id, variant.id),
                          builder: (context, skuSnapshot) {
                            if (skuSnapshot.hasError) {
                              return Center(child: Text('Erro: ${skuSnapshot.error}'));
                            }
                            if (!skuSnapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final skus = skuSnapshot.data!;
                            return Column(
                              children: skus.map((sku) {
                                return ListTile(
                                  title: Text('Tamanho: ${sku.size}'),
                                  subtitle: Text('Estoque: ${sku.stock}'),
                                  trailing: Text('R\$ ${sku.retailPrice.toStringAsFixed(2)}'),
                                  onTap: () {
                                    if (sku.isAvailable) {
                                      pdvController.addItem(product, variant, sku);
                                      Navigator.of(context).pop();
                                    } else {
                                      debugPrint('SKU sem estoque: ${sku.generatedSku}');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Este SKU está sem estoque.'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                  },
                                );
                              }).toList(),
                            );
                          },
                        )
                      ],
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }
}

class CartView extends StatelessWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos context.watch para que o widget seja reconstruído quando o controller notificar.
    final controller = context.watch<PdvController>();

    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Widgets para mostrar erros e loading (sem alterações)
          StreamBuilder<String>(
            stream: controller.errorStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    snapshot.data!,
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: controller.isLoading,
            builder: (context, isLoading, _) {
              if (isLoading) {
                return const LinearProgressIndicator();
              }
              return const SizedBox.shrink();
            },
          ),
          Text('Carrinho', style: Theme.of(context).textTheme.headlineSmall),
          const Divider(height: 24),

          // --- ALTERAÇÃO 1: INTERRUPTOR DE ATACADO ADICIONADO ---
          SwitchListTile(
            title: const Text('Ativar Preço de Atacado'),
            value: controller.isManualWholesaleActive,
            onChanged: (bool value) {
              controller.setManualWholesale(value);
            },
            subtitle: controller.totalQuantity >= 5 
              ? const Text('Ativo automaticamente (5+ peças)', style: TextStyle(color: Colors.green)) 
              : null,
          ),
          // --- FIM DA ALTERAÇÃO 1 ---

          Expanded(
            child: controller.cart.isEmpty
                ? const Center(child: Text('O carrinho está vazio.'))
                : ListView.builder(
                    itemCount: controller.cart.length,
                    itemBuilder: (context, index) {
                      final item = controller.cart[index];
                      return ListTile(
                        title: Text(item.productName),
                        
                        // --- ALTERAÇÃO 2: MOSTRAR O PREÇO INDIVIDUAL DO ITEM ---
                        subtitle: Text(
                          '${item.variantColor}, Tam: ${item.skuSize} | R\$ ${item.pricePaid.toStringAsFixed(2)}',
                        ),
                        // --- FIM DA ALTERAÇÃO 2 ---

                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => controller.decrementQuantity(item.skuId),
                            ),
                            Text(
                              item.quantity.toString(),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => controller.incrementQuantity(item.skuId),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total:', style: Theme.of(context).textTheme.headlineSmall),
              Text(
                'R\$ ${controller.totalAmount.toStringAsFixed(2)}',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: Theme.of(context).primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(20),
              backgroundColor: Colors.green,
            ),
            onPressed: controller.cart.isEmpty || controller.isProcessingSale
                ? null
                : () async {
                    final result = await controller.finalizeSale();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result ?? 'Ocorreu um erro.'),
                          backgroundColor: result != null && result.contains('sucesso')
                              ? Colors.green
                              : Colors.red,
                        ),
                      );
                    }
                  },
            child: controller.isProcessingSale
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Finalizar Venda', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}