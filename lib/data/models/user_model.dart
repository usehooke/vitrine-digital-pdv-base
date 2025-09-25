import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    final role = data['role'] ?? '';
    if (role is! String || role.isEmpty) {
      throw Exception('O documento do utilizador $id no Firestore não tem uma "role" definida.');
    }
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: role,
    );
  }

  @override
  List<Object?> get props => [id, name, email, role];
}