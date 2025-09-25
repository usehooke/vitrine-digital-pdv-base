import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/product_model.dart';
import '../../data/models/sale_item_model.dart';
import '../../data/models/sale_model.dart';
import '../../data/models/sku_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/variant_model.dart';
import '../../data/repositories/product_repository.dart';

class PdvController {
  final ProductRepository _productRepository;
  final UserModel _currentUser;

  final Map<String, SaleItemModel> _cartMap = {};

  final cart = ValueNotifier<List<SaleItemModel>>([]);
  final isProcessingSale = ValueNotifier<bool>(false);
  final manualWholesale = ValueNotifier<bool>(false);
  final totalAmount = ValueNotifier<double>(0.0);
  final totalQuantity = ValueNotifier<int>(0);

  PdvController(this._productRepository, this._currentUser) {
    manualWholesale.addListener(_recalculateAllPrices);
  }

  bool get isWholesalePriceActive => manualWholesale.value || totalQuantity.value >= 5;

  void _syncCartNotifier() {
    cart.value = List.unmodifiable(_cartMap.values);
    _recalculateAllPrices();
  }

  void _recalculateAllPrices() {
    final useWholesale = isWholesalePriceActive;
    double newTotal = 0;
    int newQuantity = 0;

    for (final item in _cartMap.values) {
      item.pricePaid = useWholesale ? item.sku.wholesalePrice : item.sku.retailPrice;
      newTotal += item.pricePaid * item.quantity;
      newQuantity += item.quantity;
    }

    totalAmount.value = newTotal;
    totalQuantity.value = newQuantity;
  }

  void setManualWholesale(bool value) {
    if (manualWholesale.value == value) return;
    manualWholesale.value = value;
  }

  void addItem(ProductModel product, VariantModel variant, SkuModel sku) {
    if (sku.stock <= 0) return;

    final existingItem = _cartMap[sku.id];

    if (existingItem == null) {
      final newItem = SaleItemModel(
        productId: product.id,
        variantId: variant.id,
        skuId: sku.id,
        sku: sku,
        productName: '${product.name} - ${product.model}',
        variantColor: variant.color,
        skuSize: sku.size,
        generatedSku: sku.generatedSku,
        pricePaid: 0.0,
      );
      _cartMap[sku.id] = newItem;
    } else {
      if (existingItem.quantity < sku.stock) {
        existingItem.quantity++;
      }
    }
    _syncCartNotifier();
  }

  void incrementQuantity(String skuId) {
    final item = _cartMap[skuId];
    if (item != null && item.quantity < item.sku.stock) {
      item.quantity++;
      _syncCartNotifier();
    }
  }

  void decrementQuantity(String skuId) {
    final item = _cartMap[skuId];
    if (item != null) {
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        _cartMap.remove(skuId);
      }
      _syncCartNotifier();
    }
  }

  Future<String?> finalizeSale() async {
    if (cart.value.isEmpty || isProcessingSale.value) return null;
    isProcessingSale.value = true;

    try {
      final sale = SaleModel(
        id: const Uuid().v4(),
        saleDate: DateTime.now(),
        userId: _currentUser.id,
        userName: _currentUser.name,
        items: cart.value,
        totalAmount: totalAmount.value,
      );
        // Some test mocks may return null (due to mockito null-safety behavior).
        // Guard at runtime: if the call returns a Future<void>, await it; otherwise await a no-op Future.
        // Use dynamic call to handle mocks that may return null at runtime.
        final dynamic maybe = (_productRepository as dynamic).processSale(sale);
        if (maybe is Future) {
          await maybe;
        } else {
          await Future<void>.value();
        }
      _cartMap.clear();
      _syncCartNotifier();
      return 'Venda finalizada com sucesso!';
    } catch (e) {
      return e.toString();
    } finally {
      isProcessingSale.value = false;
    }
  }

  // ignore: unused_element
  Future<void> _generateAndSaveSaleSummary(SaleModel sale) async {
    // TODO: implementar geração de resumo (Cloud Functions / IA).
  }

  void dispose() {
    manualWholesale.removeListener(_recalculateAllPrices);
    cart.dispose();
    isProcessingSale.dispose();
    manualWholesale.dispose();
    totalAmount.dispose();
    totalQuantity.dispose();
  }
}