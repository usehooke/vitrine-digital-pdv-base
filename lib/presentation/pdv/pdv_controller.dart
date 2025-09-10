import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/product_model.dart';
import '../../data/models/sale_item_model.dart';
import '../../data/models/sale_model.dart';
import '../../data/models/sku_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/variant_model.dart';
import '../../data/repositories/product_repository.dart';
import 'package:uuid/uuid.dart';

class PdvController extends ChangeNotifier {
  final ProductRepository _productRepository;
  final UserModel _currentUser;

  PdvController(this._productRepository, this._currentUser);

  final cart = ValueNotifier<List<SaleItemModel>>([]);
  final isProcessingSale = ValueNotifier<bool>(false);
  final manualWholesale = ValueNotifier<bool>(false);

  // Getters para facilitar o acesso aos valores
  int get totalQuantity => cart.value.fold(0, (sum, item) => sum + item.quantity);
  bool get isWholesalePriceActive => manualWholesale.value || totalQuantity >= 5;
  
  // O total é calculado dinamicamente sempre que o carrinho muda
  late final totalAmount = ValueNotifier<double>(0.0)..addListener(notifyListeners);

  void _updateTotal() {
    totalAmount.value = cart.value.fold(0.0, (sum, item) => sum + (item.pricePaid * item.quantity));
  }

  void _recalculateAllCartPrices() {
    final shouldUseWholesale = isWholesalePriceActive;
    for (var item in cart.value) {
      item.pricePaid = shouldUseWholesale
          ? item.sku.wholesalePrice
          : item.sku.retailPrice;
    }
    _updateTotal();
    // Notifica os ouvintes do ValueNotifier do carrinho
    cart.value = List.from(cart.value);
  }

  void setManualWholesale(bool value) {
    manualWholesale.value = value;
    _recalculateAllCartPrices();
  }

  void addItem(ProductModel product, VariantModel variant, SkuModel sku) {
    if (sku.stock <= 0) return;

    final existingItem = cart.value.firstWhere(
      (item) => item.sku.id == sku.id,
      orElse: () => SaleItemModel.empty(),
    );

    if (existingItem.isEmpty) {
      cart.value.add(SaleItemModel(
        productId: product.id,
        variantId: variant.id,
        skuId: sku.id,
        sku: sku,
        productName: '${product.name} - ${product.model}',
        variantColor: variant.color,
        skuSize: sku.size,
        generatedSku: sku.generatedSku,
        pricePaid: 0.0, // Será calculado
      ));
    } else {
      if (existingItem.quantity < sku.stock) {
        existingItem.quantity++;
      }
    }
    _recalculateAllCartPrices();
  }

  void incrementQuantity(String skuId) {
    final item = cart.value.firstWhere((item) => item.sku.id == skuId, orElse: () => SaleItemModel.empty());
    if (!item.isEmpty && item.quantity < item.sku.stock) {
      item.quantity++;
      _recalculateAllCartPrices();
    }
  }

  void decrementQuantity(String skuId) {
    final item = cart.value.firstWhere((item) => item.sku.id == skuId, orElse: () => SaleItemModel.empty());
    if (!item.isEmpty) {
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        cart.value.removeWhere((cartItem) => cartItem.sku.id == skuId);
      }
      _recalculateAllCartPrices();
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
      await _productRepository.processSale(sale);
      await _generateAndSaveSaleSummary(sale);
      cart.value = [];
      _updateTotal();
      return 'Venda finalizada com sucesso!';
    } catch (e) {
      return e.toString();
    } finally {
      isProcessingSale.value = false;
    }
  }

  Future<void> _generateAndSaveSaleSummary(SaleModel sale) async {
    try {
      final itemsDescription = sale.items.map((item) => '- ${item.quantity}x ${item.productName} (${item.variantColor}, Tam: ${item.skuSize})').join('\n');
      final prompt = 'Gere um resumo conciso e amigável, em uma frase, para a seguinte venda realizada por "${sale.userName}":\n$itemsDescription\nTotal: R\$ ${sale.totalAmount.toStringAsFixed(2)}';

      final callable = FirebaseFunctions.instanceFor(region: "us-central1").httpsCallable('generateSummary');
      final response = await callable.call<Map<String, dynamic>>({'prompt': prompt});
      final summary = response.data['summary'] as String?;
      
      if (summary != null && summary.isNotEmpty) {
        await _productRepository.updateSaleSummary(saleId: sale.id, summary: summary);
      }
    } catch (e) {
      print('### ERRO AO GERAR RESUMO: $e');
    }
  }

  @override
  void dispose() {
    cart.dispose();
    isProcessingSale.dispose();
    manualWholesale.dispose();
    totalAmount.dispose();
    super.dispose();
  }
}