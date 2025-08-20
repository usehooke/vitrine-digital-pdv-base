class SkuModel {
  final String id;
  final String size;
  final String generatedSku; // <-- Campo renomeado
  final double retailPrice;
  final double wholesalePrice;
  final int stock;

  const SkuModel({
    required this.id,
    required this.size,
    required this.generatedSku,
    required this.retailPrice,
    required this.wholesalePrice,
    required this.stock,
  });

  /// Criação a partir do Firestore
  factory SkuModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return SkuModel(
      id: documentId,
      size: data['size'] ?? '',
      generatedSku: data['sku'] ?? '',
      retailPrice: (data['retailPrice'] ?? 0.0).toDouble(),
      wholesalePrice: (data['wholesalePrice'] ?? 0.0).toDouble(),
      stock: (data['stock'] ?? 0).toInt(),
    );
  }

  /// Conversão para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'size': size,
      'sku': generatedSku,
      'retailPrice': retailPrice,
      'wholesalePrice': wholesalePrice,
      'stock': stock,
    };
  }

  /// Verifica se há estoque disponível
  bool get isAvailable => stock > 0;

  /// Representação textual para debug
  @override
  String toString() {
    return 'SkuModel(sku: $generatedSku, size: $size, stock: $stock, retail: $retailPrice)';
  }
}