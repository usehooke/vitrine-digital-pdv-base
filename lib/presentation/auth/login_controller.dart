import 'package:flutter/material.dart';
import '../../core/notifiers/auth_state_notifier.dart';
import '../../data/repositories/auth_repository.dart';

class LoginController extends ChangeNotifier {
  final AuthRepository _authRepository;
  final AuthStateNotifier _authStateNotifier;

  LoginController(this._authRepository, this._authStateNotifier);

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> login() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        throw Exception('Por favor, preencha o e-mail e a senha.');
      }

      // Chama o método de login seguro que criámos
      final user = await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Se o login for bem-sucedido, atualiza o estado da aplicação
      if (user != null) {
        _authStateNotifier.setUser(user);
      } else {
        throw Exception('Não foi possível fazer o login.');
      }

    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}