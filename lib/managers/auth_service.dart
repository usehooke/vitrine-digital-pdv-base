import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import '../models/app_user.dart';

/// Serviço de autenticação para gerir usuários e logins com PIN de forma segura e offline.
class AuthService extends ValueNotifier<AppUser?> {
  AuthService() : super(null);

  final _storage = const FlutterSecureStorage();
  static const _usersKey = 'app_users';

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<List<AppUser>> getUsers() async {
    final usersJson = await _storage.read(key: _usersKey);
    if (usersJson == null) return [];
    final List<dynamic> usersList = jsonDecode(usersJson);
    return usersList.map((json) => AppUser.fromJson(json)).toList();
  }

  Future<void> _saveUsers(List<AppUser> users) async {
    await _storage.write(key: _usersKey, value: jsonEncode(users.map((u) => u.toJson()).toList()));
  }

  Future<bool> createUser(String name, String pin) async {
    final users = await getUsers();
    if (users.any((user) => user.name.toLowerCase() == name.toLowerCase())) {
      return false;
    }
    
    final isFirstUserAdmin = users.isEmpty;
    final newUser = AppUser(name: name, pinHash: _hashPin(pin), isAdmin: isFirstUserAdmin);
    users.add(newUser);
    await _saveUsers(users);
    return true;
  }

  Future<bool> login(String name, String pin) async {
    final users = await getUsers();
    try {
      final user = users.firstWhere((u) => u.name == name);
      if (user.pinHash == _hashPin(pin)) {
        value = user;
        return true;
      }
    } catch (e) {
      return false; // Usuário não encontrado
    }
    return false;
  }

  void logout() {
    value = null;
  }

  // --- NOVAS FUNÇÕES DE GESTÃO PARA O ADMIN ---

  /// Apaga um usuário pelo nome.
  /// Um administrador não pode apagar a sua própria conta.
  Future<bool> deleteUser(String nameToDelete) async {
    if (value?.name == nameToDelete) {
      print("Admin não pode apagar a si mesmo.");
      return false;
    }
    final users = await getUsers();
    users.removeWhere((user) => user.name == nameToDelete);
    await _saveUsers(users);
    return true;
  }

  /// Alterna a permissão de administrador de um usuário.
  /// Um administrador não pode remover a sua própria permissão se for o último admin.
  Future<bool> toggleAdminStatus(String nameToUpdate) async {
    final users = await getUsers();
    
    // Proteção para não remover o último administrador
    final adminCount = users.where((u) => u.isAdmin).length;
    final targetUser = users.firstWhere((u) => u.name == nameToUpdate);
    if (targetUser.isAdmin && adminCount <= 1) {
      print("Não é possível remover o último administrador.");
      return false;
    }

    for (var user in users) {
      if (user.name == nameToUpdate) {
        final updatedUser = AppUser(name: user.name, pinHash: user.pinHash, isAdmin: !user.isAdmin);
        users[users.indexOf(user)] = updatedUser;
        break;
      }
    }
    await _saveUsers(users);
    return true;
  }
}

final authService = AuthService();
