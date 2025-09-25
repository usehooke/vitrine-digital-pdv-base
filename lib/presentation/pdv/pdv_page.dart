// Some small constructor const suggestions are not applicable in this layout.
// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/notifiers/auth_state_notifier.dart';
import '../../data/models/product_model.dart';
import '../../data/models/sale_item_model.dart';
import '../../data/models/sku_model.dart';
// removed unused import: variant_model
import '../../data/repositories/product_repository.dart';
import '../widgets/product_card.dart';
import 'pdv_controller.dart';
import '../qr/scanner_page.dart';
import '../admin/print_label_page.dart';

class PdvPage extends StatelessWidget {
  const PdvPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthStateNotifier>().user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Erro: Utilizador não autenticado.')));
    }

    return Provider(
      create: (context) => PdvController(context.read<ProductRepository>(), user),
      dispose: (_, controller) => controller.dispose(),
      child: Builder(
        builder: (innerContext) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Ponto de Venda'),
              actions: [
                IconButton(
                  tooltip: 'Scan',
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () async {
                    final repo = innerContext.read<ProductRepository>();
                    final pdvController = innerContext.read<PdvController>();
                    final result = await Navigator.of(innerContext).push<String>(
                      MaterialPageRoute(builder: (_) => const ScannerPage()),
                    );
                    if (result == null || result.isEmpty) return;
                    final index = await repo.findSkuIndexByGeneratedCode(result);
                    if (index == null) {
                      if (innerContext.mounted) {
                        ScaffoldMessenger.of(innerContext).showSnackBar(const SnackBar(content: Text('SKU não encontrado')));
                      }
                      return;
                    }
                    try {
                      final sku = await repo.getSkuOnDemand(index['productId']!, index['variantId']!, index['skuId']!);
                      final product = await repo.getProduct(index['productId']!);
                      final variant = product.variants.firstWhere((v) => v.id == index['variantId']);
                      pdvController.addItem(product, variant, sku);
                      if (innerContext.mounted) {
                        ScaffoldMessenger.of(innerContext).showSnackBar(const SnackBar(content: Text('Item adicionado pelo QR'), backgroundColor: Colors.green));
                      }
                    } catch (e) {
                      if (innerContext.mounted) {
                        ScaffoldMessenger.of(innerContext).showSnackBar(SnackBar(content: Text('Erro ao adicionar item: $e')));
                      }
                    }
                  },
                ),
              ],
            ),
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Expanded(flex: 3, child: _ProductGridPdv()),
                Expanded(flex: 2, child: _CartViewPdv()),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProductGridPdv extends StatelessWidget {
  const _ProductGridPdv();

  @override
  Widget build(BuildContext context) {
    final productRepo = context.read<ProductRepository>();

    return StreamBuilder<List<ProductModel>>(
      stream: productRepo.getProductsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

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
    final pdvController = context.read<PdvController>();
    final productRepo = context.read<ProductRepository>();
    final variants = product.variants;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Selecione a Variante de ${product.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: variants.isEmpty
                ? const Text('Sem variantes.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: variants.length,
                    itemBuilder: (context, vIdx) {
                      final variant = variants[vIdx];
                      // Carrega SKUs sob demanda: usa primeira emissão do stream
                      final futureSkus = productRepo.getSkusStream(product.id, variant.id).first;
                      return ExpansionTile(
                        title: Text(variant.color),
                        children: [
                          FutureBuilder<List<SkuModel>>(
                            future: futureSkus,
                            builder: (context, snap) {
                              if (snap.connectionState == ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator())),
                                );
                              }
                              if (snap.hasError) {
                                return ListTile(title: Text('Erro ao carregar SKUs: ${snap.error}'));
                              }
                              final skus = snap.data ?? [];
                              if (skus.isEmpty) return const ListTile(title: Text('Sem SKUs'));
                              return Column(
                                children: skus.map((sku) {
                                  return ListTile(
                                    title: Text('Tam: ${sku.size}  |  R\$ ${sku.retailPrice.toStringAsFixed(2)}'),
                                    subtitle: Text('Estoque: ${sku.stock}'),
                                    onTap: () {
                                      Navigator.of(dialogContext).pop();
                                      // Se SKU tem campos mínimos ou precisa de refresh, pode também chamar getSkuOnDemand
                                      pdvController.addItem(product, variant, sku);
                                    },
                                    trailing: sku.qrImageUrl != null
                                        ? IconButton(
                                            icon: const Icon(Icons.print),
                                            onPressed: () {
                                              Navigator.of(dialogContext).push(MaterialPageRoute(builder: (_) => PrintLabelPage(qrUrl: sku.qrImageUrl, skuText: sku.generatedSku)));
                                            },
                                          )
                                        : null,
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Fechar')),
          ],
        );
      },
    );
  }
}

class _CartViewPdv extends StatelessWidget {
  const _CartViewPdv();

  @override
  Widget build(BuildContext context) {
    final controller = context.read<PdvController>();

    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Carrinho', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: Listenable.merge([controller.manualWholesale, controller.totalQuantity]),
            builder: (context, _) {
              final isManual = controller.manualWholesale.value;
              final totalQty = controller.totalQuantity.value;
              return SwitchListTile(
                title: const Text('Ativar Preço de Atacado'),
                value: isManual,
                onChanged: controller.setManualWholesale,
                subtitle: totalQty >= 5 ? const Text('Ativo automaticamente (5+ peças)', style: TextStyle(color: Colors.green)) : null,
              );
            },
          ),
          const Divider(height: 24),
          Expanded(
            child: ValueListenableBuilder<List<SaleItemModel>>(
              valueListenable: controller.cart,
              builder: (context, cartItems, child) {
                if (cartItems.isEmpty) return const Center(child: Text('O carrinho está vazio.'));
                return ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return ListTile(
                      title: Text(item.productName),
                      subtitle: Text('${item.variantColor}, Tam: ${item.skuSize} • R\$ ${item.pricePaid.toStringAsFixed(2)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.remove), onPressed: () => controller.decrementQuantity(item.sku.id)),
                          Text(item.quantity.toString(), style: Theme.of(context).textTheme.titleMedium),
                          IconButton(icon: const Icon(Icons.add), onPressed: () => controller.incrementQuantity(item.sku.id)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 24),
          ValueListenableBuilder<double>(
            valueListenable: controller.totalAmount,
            builder: (context, total, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total:', style: Theme.of(context).textTheme.headlineSmall),
                  Text('R\$ ${total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).primaryColor)),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: Listenable.merge([controller.cart, controller.isProcessingSale]),
            builder: (context, _) {
              final isProcessing = controller.isProcessingSale.value;
              final cartIsEmpty = controller.cart.value.isEmpty;
              return FilledButton(
                style: FilledButton.styleFrom(padding: const EdgeInsets.all(20)),
                onPressed: cartIsEmpty || isProcessing
                    ? null
                    : () async {
                        final result = await controller.finalizeSale();
                        if (context.mounted && result != null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result), backgroundColor: result.contains('sucesso') ? Colors.green : Colors.red));
                        }
                      },
                child: isProcessing ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(color: Colors.white)) : const Text('Finalizar Venda', style: TextStyle(fontSize: 18)),
              );
            },
          ),
        ],
      ),
    );
  }
}