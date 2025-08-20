// CONTEÚDO COMPLETO PARA: lib/data/models/sale_item_model.dart

class SaleItemModel {
  final String productId;
  final String variantId;
  final String skuId;
  final String productName;
  final String variantColor;
  final String skuSize;
  final String generatedSku;
  final double pricePaid;
  int quantity;

  SaleItemModel({
    required this.productId,
    required this.variantId,
    required this.skuId,
    required this.productName,
    required this.variantColor,
    required this.skuSize,
    required this.generatedSku,
    required this.pricePaid,
    this.quantity = 1,
  });

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
    };
  }
}