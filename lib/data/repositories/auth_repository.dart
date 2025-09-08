import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart' as app; // Usar 'as app' evita conflitos com o User do Firebase

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository(this._firebaseAuth, this._firestore);

  // Stream que notifica a aplicação sobre mudanças de autenticação (login/logout)
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Método para fazer login de um utilizador
  Future<app.UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Utilizador do Firebase não encontrado após o login.');
      }
      return await getUserData(firebaseUser.uid);
    } on FirebaseAuthException {
      // Devolve uma mensagem de erro mais amigável para a UI
      throw Exception('Email ou senha inválidos.');
    }
  }

  // Método para o admin criar novos utilizadores
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Não foi possível criar o utilizador no Firebase Auth.');
      }
      // Após criar na autenticação, cria o perfil na base de dados
      await _firestore.collection('users').doc(firebaseUser.uid).set({
        'name': name,
        'email': email,
        'role': role,
      });
    } on FirebaseAuthException catch (e) {
      // Trata erros comuns com mensagens claras
      if (e.code == 'email-already-in-use') {
        throw Exception('Este e-mail já está a ser utilizado.');
      } else if (e.code == 'weak-password') {
        throw Exception('A senha deve ter pelo menos 6 caracteres.');
      }
      throw Exception('Ocorreu um erro ao criar o utilizador.');
    }
  }

  // Método para buscar os dados de um utilizador específico no Firestore
  Future<app.UserModel?> getUserData(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return app.UserModel.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }

  // Método para a página de gestão de utilizadores (apenas para admins)
  Future<List<app.UserModel>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs
          .map((d) => app.UserModel.fromFirestore(d.data(), d.id))
          .toList();
    } catch (e) {
      print('### ERRO ao buscar todos os utilizadores: $e');
      rethrow; // Propaga o erro para ser tratado na UI
    }
  }

  // Método para fazer logout
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}