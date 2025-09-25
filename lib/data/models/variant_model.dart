import 'package:equatable/equatable.dart';
import 'sku_model.dart';

class VariantModel extends Equatable {
  final String id;
  final String color;
  final String imageUrl;
  final List<SkuModel> skus;

  const VariantModel({
    required this.id,
    required this.color,
    required this.imageUrl,
    this.skus = const [],
  });

  factory VariantModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return VariantModel.fromDynamic({...data, 'id': documentId});
  }

  factory VariantModel.fromDynamic(dynamic raw) {
    if (raw == null) {
      return const VariantModel(id: '', color: '', imageUrl: '', skus: []);
    }

    final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};

    final id = (data['id'] ?? data['variantId'] ?? (raw?.id ?? '')).toString();
    final color = (data['color'] ?? data['name'] ?? (raw?.color ?? '')).toString();
    final imageUrl = (data['imageUrl'] ?? data['image'] ?? (raw?.imageUrl ?? '')).toString();

    final rawSkus = data['skus'] ?? data['skuList'] ?? (raw is Map ? raw['skus'] : raw?.skus) ?? <dynamic>[];
    final List<dynamic> skusList = rawSkus is List ? rawSkus : <dynamic>[];

    final skus = skusList.map<SkuModel>((s) {
      final sku = s as dynamic;
      final skuId = (sku is Map ? (sku['id'] ?? sku['skuId']) : (sku?.id ?? '')).toString();
      final size = (sku is Map ? (sku['size'] ?? sku['tamanho']) : (sku?.size ?? '')).toString();
      final retailRaw = (sku is Map ? (sku['retailPrice'] ?? sku['price']) : (sku?.retailPrice ?? 0)) ?? 0;
      final wholesaleRaw = (sku is Map ? (sku['wholesalePrice'] ?? sku['priceAtacado']) : (sku?.wholesalePrice ?? retailRaw)) ?? retailRaw;
      final stockRaw = (sku is Map ? (sku['stock'] ?? sku['qty'] ?? 0) : (sku?.stock ?? 0)) ?? 0;
      final generatedSku = (sku is Map ? (sku['generatedSku'] ?? sku['codigo'] ?? '') : (sku?.generatedSku ?? '')).toString();

      final retailPrice = (retailRaw is num) ? retailRaw.toDouble() : double.tryParse(retailRaw.toString()) ?? 0.0;
      final wholesalePrice = (wholesaleRaw is num) ? wholesaleRaw.toDouble() : double.tryParse(wholesaleRaw.toString()) ?? retailPrice;
      final stock = (stockRaw is num) ? stockRaw.toInt() : int.tryParse(stockRaw.toString()) ?? 0;

      return SkuModel(
        id: skuId,
        size: size,
        retailPrice: retailPrice,
        wholesalePrice: wholesalePrice,
        stock: stock,
        generatedSku: generatedSku,
      );
    }).toList();

    return VariantModel(id: id, color: color, imageUrl: imageUrl, skus: skus);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'color': color,
      'imageUrl': imageUrl,
      'skus': skus
          .map((s) => {
                'id': s.id,
                'size': s.size,
                'retailPrice': s.retailPrice,
                'wholesalePrice': s.wholesalePrice,
                'stock': s.stock,
                'generatedSku': s.generatedSku,
              })
          .toList(),
    };
  }

  VariantModel copyWith({
    String? id,
    String? color,
    String? imageUrl,
    List<SkuModel>? skus,
  }) {
    return VariantModel(
      id: id ?? this.id,
      color: color ?? this.color,
      imageUrl: imageUrl ?? this.imageUrl,
      skus: skus ?? this.skus,
    );
  }

  @override
  List<Object?> get props => [id, color, imageUrl, skus];
}