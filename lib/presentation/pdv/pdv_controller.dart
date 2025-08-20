import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
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
  final Gemini _gemini = Gemini.instance;

  PdvController(this._productRepository, this._currentUser);

  List<SaleItemModel> cart = [];

  bool _isProcessingSale = false;
  bool get isProcessingSale => _isProcessingSale;

  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final StreamController<String> _errorController = StreamController.broadcast();
  Stream<String> get errorStream => _errorController.stream;

  double get totalAmount => cart.fold(
    0.0,
    (sum, item) => sum + (item.pricePaid * item.quantity),
  );

  void addItem(ProductModel product, VariantModel variant, SkuModel sku) {
    if (sku.stock <= 0) {
      debugPrint("Tentativa de adicionar item sem estoque: ${sku.generatedSku}");
      return;
    }

    final existingItemIndex = cart.indexWhere((item) => item.skuId == sku.id);

    if (existingItemIndex != -1) {
      incrementQuantity(sku.id, sku.stock);
    } else {
      cart.add(SaleItemModel(
        productId: product.id,
        variantId: variant.id,
        skuId: sku.id,
        productName: '${product.name} - ${product.model}',
        variantColor: variant.color,
        skuSize: sku.size,
        generatedSku: sku.generatedSku,
        pricePaid: sku.retailPrice,
      ));
    }

    notifyListeners();
  }

  void removeItem(String skuId) {
    cart.removeWhere((item) => item.skuId == skuId);
    notifyListeners();
  }

  void incrementQuantity(String skuId, int skuStock) {
    final item = cart.firstWhere((item) => item.skuId == skuId);
    if (item.quantity < skuStock) {
      item.quantity++;
      notifyListeners();
    } else {
      debugPrint("Estoque máximo atingido para o SKU: ${item.generatedSku}");
    }
  }

  void decrementQuantity(String skuId) {
    final item = cart.firstWhere((item) => item.skuId == skuId);
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      removeItem(skuId);
    }
    notifyListeners();
  }

  Future<String?> finalizeSale() async {
    if (cart.isEmpty || _isProcessingSale) return null;

    _isProcessingSale = true;
    isLoading.value = true;
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
      debugPrint('### ERRO AO FINALIZAR VENDA: $e');
      _errorController.add(e.toString());
      return e.toString().replaceAll('Exception: ', '');
    } finally {
      _isProcessingSale = false;
      isLoading.value = false;
      notifyListeners();
    }
  }

  Future<void> _generateAndSaveSaleSummary(SaleModel sale) async {
    try {
      final itemsDescription = sale.items.map((item) =>
        '- ${item.quantity}x ${item.productName} (${item.variantColor}, Tam: ${item.skuSize})'
      ).join('\n');

      final prompt = 'Gere um resumo conciso e amigável, em uma frase, para a seguinte venda realizada por "${sale.userName}":\n$itemsDescription\nTotal: R\$ ${sale.totalAmount.toStringAsFixed(2)}';

      final response = await _gemini.text(prompt);
      final summary = response?.output;

      if (summary != null && summary.isNotEmpty) {
        sale.geminiSummary = summary;
        await FirebaseFirestore.instance
            .collection('sales')
            .doc(sale.id)
            .update({'geminiSummary': summary});
      }
    } catch (e) {
      debugPrint('### ERRO ao gerar resumo com Gemini: $e');
      _errorController.add('Erro ao gerar resumo com Gemini');
    }
  }

  void disposeController() {
    _errorController.close();
    isLoading.dispose();
  }
}