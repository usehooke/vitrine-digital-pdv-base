// CONTEÚDO CORRETO PARA: lib/data/models/user_model.dart

class UserModel {
  final String id; // ID do documento no Firestore
  final String name;
  final String pin;
  final String role; // 'admin' ou 'pdv'

  const UserModel({
    required this.id,
    required this.name,
    required this.pin,
    required this.role,
  });

  // Factory para criar um UserModel a partir de um mapa do Firestore
  factory UserModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return UserModel(
      id: documentId,
      name: data['name'] ?? '',
      pin: data['pin'] ?? '',
      role: data['role'] ?? 'pdv',
    );
  }
}