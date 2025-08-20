// NOVO FICHEIRO: lib/data/models/variant_model.dart

class VariantModel {
  final String id;
  final String color;
  final String imageUrl;

  const VariantModel({
    required this.id,
    required this.color,
    required this.imageUrl,
  });

  factory VariantModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return VariantModel(
      id: documentId,
      color: data['color'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
    );
  }
}