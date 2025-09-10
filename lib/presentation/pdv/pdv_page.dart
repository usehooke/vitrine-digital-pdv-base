import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/notifiers/auth_state_notifier.dart';
import '../../data/models/product_model.dart';
import '../../data/models/sale_item_model.dart';
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
      // Esta verificação de segurança garante que a página não é construída sem um utilizador.
      return const Scaffold(body: Center(child: Text('Erro: Utilizador não autenticado.')));
    }

    // O ChangeNotifierProvider garante que o PdvController está disponível para os widgets abaixo.
    return ChangeNotifierProvider(
      create: (context) => PdvController(context.read<ProductRepository>(), user),
      child: Scaffold(
        appBar: AppBar(title: const Text('Ponto de Venda')),
        body: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _ProductGridPdv()),
            Expanded(flex: 2, child: _CartViewPdv()),
          ],
        ),
      ),
    );
  }
}

/// Widget privado para a grelha de produtos.
class _ProductGridPdv extends StatelessWidget {
  const _ProductGridPdv();

  @override
  Widget build(BuildContext context) {
    final productRepo = context.read<ProductRepository>();

    return StreamBuilder<List<ProductModel>>(
      stream: productRepo.getProductsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}'));
        if (!snapshot.hasData || snapshot.data == null) return const Center(child: CircularProgressIndicator());
        
        final products = snapshot.data!;
        if (products.isEmpty) return const Center(child: Text('Nenhum produto encontrado.'));
        
        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            childAspectRatio: 0.8,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
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
    // Usamos 'read' porque estamos dentro de uma função de callback.
    final pdvController = context.read<PdvController>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Selecione a Variante para "${product.name}"'),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<List<VariantModel>>(
              stream: productRepo.getVariantsStream(product.id),
              builder: (context, variantSnapshot) {
                if (!variantSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                final variants = variantSnapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: variants.length,
                  itemBuilder: (context, index) {
                    final variant = variants[index];
                    return ExpansionTile(
                      leading: Image.network(variant.imageUrl, width: 40, height: 40, fit: BoxFit.cover),
                      title: Text(variant.color),
                      children: [
                        StreamBuilder<List<SkuModel>>(
                          stream: productRepo.getSkusStream(product.id, variant.id),
                          builder: (context, skuSnapshot) {
                            if (!skuSnapshot.hasData) return const Center(child: CircularProgressIndicator());
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
                                      Navigator.of(dialogContext).pop();
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Este SKU está sem estoque.'), backgroundColor: Colors.orange),
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
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }
}


/// Widget privado para a vista do carrinho, usando ValueListenableBuilders para performance.
class _CartViewPdv extends StatelessWidget {
  const _CartViewPdv();

  @override
  Widget build(BuildContext context) {
    // Usamos .read pois as atualizações serão geridas pelos ValueListenableBuilders
    final controller = context.read<PdvController>();

    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Carrinho', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),

          // Ouve apenas as mudanças do 'manualWholesale' e da quantidade total
          ValueListenableBuilder<bool>(
            valueListenable: controller.manualWholesale,
            builder: (context, isManual, child) {
              // Reconstroi o widget que depende da quantidade total
              final totalQuantity = context.select((PdvController c) => c.totalQuantity);
              return SwitchListTile(
                title: const Text('Ativar Preço de Atacado'),
                value: isManual,
                onChanged: controller.setManualWholesale,
                subtitle: totalQuantity >= 5 
                  ? const Text('Ativo automaticamente (5+ peças)', style: TextStyle(color: Colors.green)) 
                  : null,
              );
            },
          ),
          const Divider(height: 24),

          // Ouve apenas as mudanças da lista 'cart'
          Expanded(
            child: ValueListenableBuilder<List<SaleItemModel>>(
              valueListenable: controller.cart,
              builder: (context, cartItems, child) {
                if (cartItems.isEmpty) {
                  return const Center(child: Text('O carrinho está vazio.'));
                }
                return ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return ListTile(
                      title: Text(item.productName),
                      subtitle: Text('${item.variantColor}, Tam: ${item.skuSize} | R\$ ${item.pricePaid.toStringAsFixed(2)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () => controller.decrementQuantity(item.sku.id),
                          ),
                          Text(item.quantity.toString(), style: Theme.of(context).textTheme.titleMedium),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => controller.incrementQuantity(item.sku.id),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 24),

          // Ouve apenas as mudanças do 'totalAmount'
          ValueListenableBuilder<double>(
            valueListenable: controller.totalAmount,
            builder: (context, total, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total:', style: Theme.of(context).textTheme.headlineSmall),
                  Text(
                    'R\$ ${total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).primaryColor),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Ouve as mudanças do 'isProcessingSale' e do 'cart'
          ValueListenableBuilder<bool>(
            valueListenable: controller.isProcessingSale,
            builder: (context, isProcessing, child) {
              final cartIsEmpty = context.select((PdvController c) => c.cart.value.isEmpty);
              return FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(20),
                ),
                onPressed: cartIsEmpty || isProcessing
                  ? null
                  : () async {
                      final result = await controller.finalizeSale();
                      if (context.mounted && result != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result),
                            backgroundColor: result.contains('sucesso') ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    },
                child: isProcessing
                  ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(color: Colors.white))
                  : const Text('Finalizar Venda', style: TextStyle(fontSize: 18)),
              );
            },
          ),
        ],
      ),
    );
  }
}