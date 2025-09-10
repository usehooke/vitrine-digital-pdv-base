import 'package:equatable/equatable.dart';

class VariantModel extends Equatable {
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

  @override
  List<Object?> get props => [id, color, imageUrl];
}