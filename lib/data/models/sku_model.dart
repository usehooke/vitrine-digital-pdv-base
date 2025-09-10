import 'package:equatable/equatable.dart';

class SkuModel extends Equatable {
  final String id;
  final String size;
  final double retailPrice;
  final double wholesalePrice;
  final int stock;
  final String generatedSku;

  const SkuModel({
    required this.id,
    required this.size,
    required this.retailPrice,
    required this.wholesalePrice,
    required this.stock,
    required this.generatedSku,
  });

  bool get isAvailable => stock > 0;

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

  @override
  List<Object?> get props => [id, size, retailPrice, wholesalePrice, stock, generatedSku];
}