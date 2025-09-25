import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class UserManagementController extends ChangeNotifier {
  final AuthRepository _authRepository;
  bool _disposed = false;

  UserManagementController(this._authRepository) {
    fetchUsers();
  }

  List<UserModel> _users = [];
  List<UserModel> get users => _users;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUsers() async {
    _isLoading = true;
    _errorMessage = null;
    if (!_disposed) notifyListeners();
    try {
      _users = await _authRepository.getAllUsers();
    } catch (e) {
      _errorMessage = 'Erro ao carregar utilizadores. Verifique as suas permissões.';
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<String?> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
  if (!_disposed) notifyListeners();
    String? error;
    try {
      await _authRepository.createUserWithEmailAndPassword(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      await fetchUsers(); // Atualiza a lista após a criação
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
    return error;
  }

  Future<String?> updateUser(String userId, String name, String role) async {
    // TODO: Adicionar um método 'updateUser' ao seu AuthRepository
    debugPrint('Lógica de atualização para $userId com nome $name e função $role');
    await fetchUsers();
    return null;
  }

  Future<String?> deleteUser(String userId) async {
    // TODO: A exclusão de utilizadores da Auth requer uma Cloud Function por segurança.
    debugPrint('Lógica para apagar o utilizador $userId');
    await fetchUsers();
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}