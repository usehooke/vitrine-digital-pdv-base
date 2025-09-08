import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart'; // Usamos o pacote para Cloud Functions
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/product_model.dart';
import '../../data/models/sale_item_model.dart';
import '../../data/models/sale_model.dart';
import '../../data/models/sku_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/variant_model.dart';
import '../../data/repositories/product_repository.dart';

class PdvController extends ChangeNotifier {
  final ProductRepository _productRepository;
  final UserModel _currentUser;

  PdvController(this._productRepository, this._currentUser);

  final isLoading = ValueNotifier<bool>(false);
  final _errorStreamController = StreamController<String>.broadcast();
  Stream<String> get errorStream => _errorStreamController.stream;
  List<SaleItemModel> cart = [];
  bool _isProcessingSale = false;
  bool get isProcessingSale => _isProcessingSale;
  bool _manualWholesale = false;
  bool get isManualWholesaleActive => _manualWholesale;
  int get totalQuantity => cart.fold(0, (sum, item) => sum + item.quantity);
  bool get isWholesalePriceActive => _manualWholesale || totalQuantity >= 5;
  double get totalAmount => cart.fold(0.0, (sum, item) => sum + (item.pricePaid * item.quantity));

  void setManualWholesale(bool value) {
    _manualWholesale = value;
    _recalculateAllCartPrices();
  }

  void _recalculateAllCartPrices() {
    final shouldUseWholesale = isWholesalePriceActive;
    for (var item in cart) {
      item.pricePaid = shouldUseWholesale
          ? item.sku.wholesalePrice
          : item.sku.retailPrice;
    }
    notifyListeners();
  }

  void addItem(ProductModel product, VariantModel variant, SkuModel sku) {
    if (sku.stock <= 0) return;
    final existingItemIndex = cart.indexWhere((item) => item.skuId == sku.id);
    if (existingItemIndex != -1) {
      if (cart[existingItemIndex].quantity < sku.stock) {
        cart[existingItemIndex].quantity++;
      }
    } else {
      cart.add(SaleItemModel(
        productId: product.id,
        variantId: variant.id,
        skuId: sku.id,
        sku: sku,
        productName: '${product.name} - ${product.model}',
        variantColor: variant.color,
        skuSize: sku.size,
        generatedSku: sku.generatedSku,
        pricePaid: 0.0,
      ));
    }
    _recalculateAllCartPrices();
  }

  void incrementQuantity(String skuId) {
    final itemIndex = cart.indexWhere((item) => item.skuId == skuId);
    if (itemIndex != -1) {
      cart[itemIndex].quantity++;
      _recalculateAllCartPrices();
    }
  }

  void decrementQuantity(String skuId) {
    final itemIndex = cart.indexWhere((item) => item.skuId == skuId);
    if (itemIndex != -1) {
      if (cart[itemIndex].quantity > 1) {
        cart[itemIndex].quantity--;
      } else {
        cart.removeAt(itemIndex);
      }
      _recalculateAllCartPrices();
    }
  }

  void removeItem(String skuId) {
    cart.removeWhere((item) => item.skuId == skuId);
    _recalculateAllCartPrices();
  }

  Future<String?> finalizeSale() async {
    if (cart.isEmpty || _isProcessingSale) return null;
    _isProcessingSale = true;
    notifyListeners();
    try {
      final sale = SaleModel(
        id: const Uuid().v4(),
        saleDate: DateTime.now(),
        userId: _currentUser.id,
        userName: _currentUser.name,
        items: cart,
        totalAmount: totalAmount,
      );
      await _productRepository.processSale(sale);
      await _generateAndSaveSaleSummary(sale);
      cart.clear();
      return 'Venda finalizada com sucesso!';
    } catch (e) {
      return e.toString();
    } finally {
      _isProcessingSale = false;
      notifyListeners();
    }
  }

  Future<void> _generateAndSaveSaleSummary(SaleModel sale) async {
    try {
      final itemsDescription = sale.items.map((item) => '- ${item.quantity}x ${item.productName} (${item.variantColor}, Tam: ${item.skuSize})').join('\n');
      final prompt = 'Gere um resumo conciso e amigável, em uma frase, para a seguinte venda realizada por "${sale.userName}":\n$itemsDescription\nTotal: R\$ ${sale.totalAmount.toStringAsFixed(2)}';

      final callable = FirebaseFunctions.instanceFor(region: "us-central1")
          .httpsCallable('generateSummary');

      final response = await callable.call<Map<String, dynamic>>({
        'prompt': prompt,
      });

      final summary = response.data['summary'] as String?;
      
      if (summary != null && summary.isNotEmpty) {
        await _productRepository.updateSaleSummary(saleId: sale.id, summary: summary);
      }
    } on FirebaseFunctionsException catch (e) {
      print('### ERRO AO CHAMAR A CLOUD FUNCTION: ${e.code} - ${e.message}');
    } catch (e) {
      print('### ERRO INESPERADO AO GERAR RESUMO: $e');
    }
  }

  @override
  void dispose() {
    _errorStreamController.close();
    isLoading.dispose();
    super.dispose();
  }
}