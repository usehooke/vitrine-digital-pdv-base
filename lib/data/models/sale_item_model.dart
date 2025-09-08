// CONTEÚDO COMPLETO E CORRIGIDO PARA: lib/data/models/sale_item_model.dart

import 'sku_model.dart';

class SaleItemModel {
  final String productId;
  final String variantId;
  final String skuId;
  
  // O SkuModel completo, que usamos para a lógica de preços.
  final SkuModel sku;

  final String productName;
  final String variantColor;
  final String skuSize;
  final String generatedSku;
  
  double pricePaid; 
  int quantity;

  SaleItemModel({
    required this.productId,
    required this.variantId,
    required this.skuId,
    required this.sku,
    required this.productName,
    required this.variantColor,
    required this.skuSize,
    required this.generatedSku,
    required this.pricePaid,
    this.quantity = 1,
  });

  // --- MÉTODO toMap ADICIONADO AQUI ---
  /// Converte este objeto SaleItemModel num Mapa para ser guardado no Firestore.
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'variantId': variantId,
      'skuId': skuId,
      'productName': productName,
      'variantColor': variantColor,
      'skuSize': skuSize,
      'generatedSku': generatedSku,
      'pricePaid': pricePaid,
      'quantity': quantity,
      // Nota: Não guardamos o objeto 'sku' inteiro na venda,
      // pois seria redundante. Os IDs já são suficientes.
    };
  }
}