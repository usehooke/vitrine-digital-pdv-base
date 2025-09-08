// CONTEÚDO COMPLETO E FINAL PARA: lib/data/models/sku_model.dart

class SkuModel {
  final String id;
  final String size;
  final double retailPrice;
  final double wholesalePrice;
  final int stock;
  final String generatedSku;

  SkuModel({
    required this.id,
    required this.size,
    required this.retailPrice,
    required this.wholesalePrice,
    required this.stock,
    required this.generatedSku,
  });

  factory SkuModel.fromFirestore(Map<String, dynamic> data, String id) {
    return SkuModel(
      id: id,
      size: data['size'] ?? '',
      retailPrice: (data['retailPrice'] as num?)?.toDouble() ?? 0.0,
      wholesalePrice: (data['wholesalePrice'] as num?)?.toDouble() ?? 0.0,
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      generatedSku: data['generatedSku'] ?? '',
    );
  }

  // --- NOVA LINHA ADICIONADA AQUI ---
  /// Getter que calcula se o item está disponível baseado no estoque.
  bool get isAvailable => stock > 0;
}