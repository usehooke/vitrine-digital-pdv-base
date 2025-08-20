// CONTEÚDO CORRETO PARA: lib/data/models/product_model.dart

class ProductModel {
  final String id;
  final String category;
  final String name;
  final String model;
  final String coverImageUrl;

  const ProductModel({
    required this.id,
    required this.category,
    required this.name,
    required this.model,
    required this.coverImageUrl,
  });

  factory ProductModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return ProductModel(
      id: documentId,
      category: data['category'] ?? '',
      name: data['name'] ?? '',
      model: data['model'] ?? '',
      coverImageUrl: data['coverImageUrl'] ?? '',
    );
  }
}