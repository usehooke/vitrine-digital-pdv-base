import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthStateNotifier extends ChangeNotifier {
  final AuthRepository _authRepository;
  UserModel? _user;
  StreamSubscription<User?>? _authSub;

  AuthStateNotifier(this._authRepository) {
    // Escuta continuamente as alterações de estado do Firebase Auth
    _authSub = _authRepository.authStateChanges.listen(_handleAuthStateChanged);
  }

  Future<void> _handleAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      setUser(null);
    } else {
      try {
        final userModel = await _authRepository.getUserData(firebaseUser.uid);
        if (userModel == null) {
          // Caso de segurança: o utilizador existe na Auth, mas não no Firestore.
          // Força o logout para evitar um estado inconsistente.
          print('### AVISO: Utilizador ${firebaseUser.uid} autenticado mas sem perfil no Firestore. A deslogar.');
          await logout();
        } else {
          setUser(userModel);
        }
      } catch (e) {
        print('### ERRO ao obter dados do utilizador no Notifier: $e');
        setUser(null);
      }
    }
  }

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;

  void setUser(UserModel? newUser) {
    if (_user?.id != newUser?.id) {
      _user = newUser;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authRepository.signOut();
    setUser(null);
  }

  @override
  void dispose() {
    _authSub?.cancel(); // Cancela a escuta para evitar memory leaks
    super.dispose();
  }
}