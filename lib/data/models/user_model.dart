class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    // Verificação explícita: se 'role' não existir, lança um erro.
    if (data['role'] == null || (data['role'] as String).isEmpty) {
      throw Exception('O documento do utilizador $id no Firestore não tem uma "role" definida.');
    }
    
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'], // Agora, sem o fallback '??'.
    );
  }
}