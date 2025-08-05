import 'package:flutter/material.dart';
import '../models/cart_item.dart';

/// Gerencia o estado global do carrinho de compras usando [ValueNotifier].
class CartManager extends ValueNotifier<List<CartItem>> {
  CartManager() : super([]);

  /// Adiciona ou atualiza um [CartItem] no carrinho com base no SKU.
  void addItem(CartItem newItem) {
    final items = List<CartItem>.from(value);
    final index = items.indexWhere((item) => item.sku == newItem.sku);

    if (index >= 0) {
      final existing = items[index];
      items[index] = existing.copyWith(
        quantidade: existing.quantidade + newItem.quantidade,
      );
    } else {
      items.add(newItem);
    }

    value = items;
  }

  /// Atualiza a quantidade de um item específico.
  /// Se a nova quantidade for 0 ou menor, remove o item.
  void updateQuantity(String sku, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(sku);
      return;
    }

    final items = List<CartItem>.from(value);
    final index = items.indexWhere((item) => item.sku == sku);

    if (index >= 0) {
      items[index] = items[index].copyWith(quantidade: newQuantity);
      value = items;
    }
  }

  /// Remove um item do carrinho pelo SKU.
  void removeItem(String sku) {
    value = value.where((item) => item.sku != sku).toList();
  }

  /// Limpa todos os itens do carrinho.
  void clear() => value = [];

  /// Quantidade total de peças.
  int get totalItems => value.fold(0, (sum, item) => sum + item.quantidade);

  /// Preço total com regra de atacado (>=5 peças).
  double get totalPrice {
    final isAtacado = totalItems >= 5;
    return value.fold(0.0, (sum, item) {
      final preco = isAtacado ? item.precoAtacado : item.precoVarejo;
      return sum + preco * item.quantidade;
    });
  }
}

/// Instância global para acesso em toda a aplicação.
final cartManager = CartManager();