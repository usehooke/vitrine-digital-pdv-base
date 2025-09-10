import 'package:equatable/equatable.dart';

class ProductModel extends Equatable {
  final String id;
  final String name;
  final String model;
  final String category;
  final String mainImageUrl;

  const ProductModel({
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
      mainImageUrl: data['mainImageUrl'] ?? '',
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

  @override
  List<Object?> get props => [id, name, model, category, mainImageUrl];
}