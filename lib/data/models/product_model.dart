import 'package:equatable/equatable.dart';
import 'variant_model.dart';

class ProductModel extends Equatable {
  final String id;
  final String name;
  final String model;
  final String category;
  final String mainImageUrl;
  final List<VariantModel> variants;

  const ProductModel({
    required this.id,
    required this.name,
    required this.model,
    required this.category,
    required this.mainImageUrl,
    this.variants = const [],
  });

  factory ProductModel.fromFirestore(Map<String, dynamic> data, String id) {
    final rawVariants = data['variants'];
    List<VariantModel> parsedVariants = [];
    if (rawVariants is List) {
      parsedVariants = rawVariants.map<VariantModel>((v) => VariantModel.fromDynamic(v)).toList();
    }
    return ProductModel(
      id: id,
      name: data['name'] ?? '',
      model: data['model'] ?? '',
      category: data['category'] ?? '',
      mainImageUrl: data['mainImageUrl'] ?? '',
      variants: parsedVariants,
    );
  }

  factory ProductModel.fromDynamic(dynamic raw) {
    if (raw == null) {
      return const ProductModel(id: '', name: '', model: '', category: '', mainImageUrl: '', variants: []);
    }
    final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    final rawVariants = data['variants'] ?? [];
    final variants = (rawVariants is List) ? rawVariants.map<VariantModel>((v) => VariantModel.fromDynamic(v)).toList() : <VariantModel>[];
    return ProductModel(
      id: (data['id'] ?? data['productId'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      model: (data['model'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      mainImageUrl: (data['mainImageUrl'] ?? data['image'] ?? '').toString(),
      variants: variants,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'model': model,
      'category': category,
      'mainImageUrl': mainImageUrl,
      'variants': variants.map((v) => v.toMap()).toList(),
    };
  }

  @override
  List<Object?> get props => [id, name, model, category, mainImageUrl, variants];
}