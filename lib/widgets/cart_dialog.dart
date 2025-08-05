import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../managers/cart_manager.dart';
import '../models/cart_item.dart';

/// Um diálogo que exibe os itens no carrinho de compras, permitindo ao
/// utilizador finalizar a compra ou gerir os itens.
class CartDialog extends StatefulWidget {
  const CartDialog({super.key});

  @override
  State<CartDialog> createState() => _CartDialogState();
}

class _CartDialogState extends State<CartDialog> {
  bool _isLoading = false;
  String? _selectedPaymentMethod;

  /// Processa a finalização da compra.
  /// Dá baixa no estoque e regista a venda no Firestore.
  Future<void> _finalizePurchase() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Por favor, selecione uma forma de pagamento.'),
          backgroundColor: Colors.orange));
      return;
    }
    setState(() {
      _isLoading = true;
    });

    final items = List<CartItem>.from(cartManager.value);
    final total = cartManager.totalPrice;
    final totalItems = cartManager.totalItems;

    // Usa um WriteBatch para garantir que todas as operações ocorram de forma atómica.
    final WriteBatch batch = FirebaseFirestore.instance.batch();
    final productsCollection = FirebaseFirestore.instance
        .collection('artifacts/hooke-loja-pdv-d2e5c/public/data/produtos');
    final salesCollection = FirebaseFirestore.instance
        .collection('artifacts/hooke-loja-pdv-d2e5c/public/data/vendas');

    for (var item in items) {
      final productDocRef = productsCollection.doc(item.productId);
      batch.update(productDocRef,
          {'skus.${item.sku}.estoque': FieldValue.increment(-item.quantidade)});
    }

    batch.set(salesCollection.doc(), {
      'items': items
          .map((item) => {
                'sku': item.sku,
                'nome': item.nome,
                'quantidade': item.quantidade,
                'categoria': item.categoria,
                'preco_unitario':
                    totalItems >= 5 ? item.precoAtacado : item.precoVarejo,
              })
          .toList(),
      'total': total,
      'total_items': totalItems,
      'metodo_pagamento': _selectedPaymentMethod,
      'data': FieldValue.serverTimestamp(),
    });

    try {
      await batch.commit();
      // ** A CORREÇÃO ESTÁ AQUI **
      cartManager.clear(); // Usa o método renomeado 'clear'
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Venda finalizada com sucesso!'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao finalizar venda: $e'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usa o ValueListenableBuilder para reconstruir o diálogo sempre que o carrinho mudar.
    return ValueListenableBuilder<List<CartItem>>(
      valueListenable: cartManager,
      builder: (context, items, child) {
        final bool isAtacado = cartManager.totalItems >= 5;

        return AlertDialog(
          backgroundColor: const Color(0xFF1e293b),
          title: const Text('Resumo da Compra'),
          content: SizedBox(
            width: 500,
            height: 600, // Aumenta a altura para melhor visualização
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: items.isEmpty
                      ? const Center(
                          child: Text('O seu carrinho está vazio.'))
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final price =
                                isAtacado ? item.precoAtacado : item.precoVarejo;
                            return ListTile(
                              title: Text(item.nome),
                              subtitle: Text('${item.cor} / ${item.tamanho}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                   IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () => cartManager.updateQuantity(item.sku, item.quantidade - 1),
                                  ),
                                  Text(item.quantidade.toString()),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () => cartManager.updateQuantity(item.sku, item.quantidade + 1),
                                  ),
                                  const SizedBox(width: 16),
                                  Text('R\$ ${price.toStringAsFixed(2)}'),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const Divider(height: 24),
                const Text('Forma de Pagamento',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8.0,
                  children: ['Dinheiro', 'Pix', 'Débito', 'Crédito'].map((method) {
                    return ChoiceChip(
                      label: Text(method),
                      selected: _selectedPaymentMethod == method,
                      onSelected: (selected) =>
                          setState(() => _selectedPaymentMethod = method),
                    );
                  }).toList(),
                ),
                const Divider(height: 24),
                Text(
                  isAtacado
                      ? 'Preço de ATACADO aplicado!'
                      : 'Preço de Varejo',
                  style: TextStyle(
                      color: isAtacado ? Colors.greenAccent : Colors.grey,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total: R\$ ${cartManager.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continuar a comprar')),
            ElevatedButton(
              onPressed:
                  cartManager.value.isEmpty || _isLoading ? null : _finalizePurchase,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Finalizar Compra'),
            ),
          ],
        );
      },
    );
  }
}
