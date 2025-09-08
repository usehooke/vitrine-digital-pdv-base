class ProductModel {
  final String id;
  final String name;
  final String model;
  final String category;
  final String mainImageUrl; // Nome correto da imagem

  ProductModel({
    required this.id,
    required this.name,
    required this.model,
    required this.category,
    required this.mainImageUrl,
  });

  factory ProductModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ProductModel(
      id: id,
      name: data['name'] ?? '',
      model: data['model'] ?? '',
      category: data['category'] ?? '',
      mainImageUrl: data['mainImageUrl'] ?? '', // Corrigido aqui
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'model': model,
      'category': category,
      'mainImageUrl': mainImageUrl,
    };
  }
}