import 'sku_model.dart';

/// Representa um item individual dentro de uma venda.
class SaleItemModel {
  final String productId;
  final String variantId;
  final String skuId;
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
  })  : assert(pricePaid >= 0, 'Preço não pode ser negativo'),
        assert(quantity >= 0, 'Quantidade inválida');

  SaleItemModel.empty()
      : productId = '',
        variantId = '',
        skuId = '',
        sku = const SkuModel(id: '', size: '', retailPrice: 0, wholesalePrice: 0, stock: 0, generatedSku: ''),
        productName = '',
        variantColor = '',
        skuSize = '',
        generatedSku = '',
        pricePaid = 0.0,
        quantity = 0;

  bool get isEmpty => productId.isEmpty;

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

  factory SaleItemModel.fromMap(Map<String, dynamic> map, SkuModel sku) {
    return SaleItemModel(
      productId: map['productId'] ?? '',
      variantId: map['variantId'] ?? '',
      skuId: map['skuId'] ?? '',
      sku: sku,
      productName: map['productName'] ?? '',
      variantColor: map['variantColor'] ?? '',
      skuSize: map['skuSize'] ?? '',
      generatedSku: map['generatedSku'] ?? '',
      pricePaid: (map['pricePaid'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
    );
  }

  SaleItemModel copyWith({
    String? productId,
    String? variantId,
    String? skuId,
    SkuModel? sku,
    String? productName,
    String? variantColor,
    String? skuSize,
    String? generatedSku,
    double? pricePaid,
    int? quantity,
  }) {
    return SaleItemModel(
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      skuId: skuId ?? this.skuId,
      sku: sku ?? this.sku,
      productName: productName ?? this.productName,
      variantColor: variantColor ?? this.variantColor,
      skuSize: skuSize ?? this.skuSize,
      generatedSku: generatedSku ?? this.generatedSku,
      pricePaid: pricePaid ?? this.pricePaid,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaleItemModel && runtimeType == other.runtimeType && skuId == other.skuId;

  @override
  int get hashCode => skuId.hashCode;
}