// CONTEÚDO CORRETO PARA: lib/presentation/auth/login_controller.dart

import 'package:flutter/material.dart';
import '../../core/notifiers/auth_state_notifier.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class LoginController extends ChangeNotifier {
  final AuthRepository _authRepository;
  final AuthStateNotifier _authStateNotifier;

  LoginController(this._authRepository, this._authStateNotifier) {
    fetchUsers();
  }

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<UserModel> _users = [];
  List<UserModel> get users => _users;

  Future<void> fetchUsers() async {
    _isLoading = true;
    notifyListeners();
    _users = await _authRepository.getUsers();
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> signInWithPin(String userId, String pin) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final user = await _authRepository.signInWithPin(userId, pin);
      _authStateNotifier.setUser(user);
      print('--- PASSO 1 (LOGIN CONTROLLER): Utilizador definido no notifier. Papel: ${user.role}');
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}