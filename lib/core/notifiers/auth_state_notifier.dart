// lib/core/notifiers/auth_state_notifier.dart (versão atualizada)

import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';

class AuthStateNotifier extends ChangeNotifier {
  UserModel? _user;
  UserModel? get user => _user;

  bool get isLoggedIn => _user != null;

  // Método para definir o utilizador logado (será chamado pelo LoginController)
  void setUser(UserModel? user) {
    _user = user;
    notifyListeners();
  }
}