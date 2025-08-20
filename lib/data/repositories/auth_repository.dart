// lib/data/repositories/auth_repository.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository(this._firebaseAuth, this._firestore);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<List<UserModel>> getUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('### ERRO ao buscar utilizadores: $e');
      return [];
    }
  }

  Future<UserModel> signInWithPin(String userId, String pin) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        throw Exception('Utilizador não encontrado.');
      }
      final user = UserModel.fromFirestore(doc.data()!, doc.id);
      print('### DADOS DO UTILIZADOR LOGADO: ID=${user.id}, Nome=${user.name}, Papel=${user.role}');
      if (user.pin != pin) {
        throw Exception('PIN incorreto.');
      }
      await _firebaseAuth.signInAnonymously();
      return user;
    } catch (e) {
      print('### ERRO no login com PIN: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      print('### ERRO no logout: $e');
      rethrow;
    }
  }
}