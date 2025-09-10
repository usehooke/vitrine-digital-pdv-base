import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart' as app;

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository(this._firebaseAuth, this._firestore);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<app.UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    print('--- AUTH REPO: Tentando login para o e-mail: $email ---');
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        print('--- AUTH REPO: Login na Auth teve sucesso, mas o utilizador é nulo.');
        throw Exception('Utilizador do Firebase não encontrado após o login.');
      }
      print('--- AUTH REPO: Login na Auth bem-sucedido. UID: ${firebaseUser.uid} ---');
      return await getUserData(firebaseUser.uid);
    } on FirebaseAuthException catch (e) {
      print('--- AUTH REPO: ERRO de autenticação do Firebase: ${e.code} ---');
      throw Exception('Email ou senha inválidos.');
    } catch (e) {
      print('--- AUTH REPO: ERRO inesperado no signIn: $e');
      rethrow;
    }
  }

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    // ... (este método já está bom, sem necessidade de mais prints)
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Não foi possível criar o utilizador no Firebase Auth.');
      }
      await _firestore.collection('users').doc(firebaseUser.uid).set({
        'name': name,
        'email': email,
        'role': role,
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('Este e-mail já está a ser utilizado.');
      } else if (e.code == 'weak-password') {
        throw Exception('A senha é muito fraca.');
      }
      throw Exception('Ocorreu um erro ao criar o utilizador.');
    }
  }

  Future<app.UserModel?> getUserData(String userId) async {
    print('--- AUTH REPO: A procurar documento em /users/$userId ---');
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        print('--- AUTH REPO: Documento encontrado! Dados: ${doc.data()} ---');
        return app.UserModel.fromFirestore(doc.data()!, doc.id);
      } else {
        print('--- AUTH REPO: AVISO! doc.exists é falso. Documento não foi encontrado. ---');
        return null;
      }
    } catch (e) {
      print('--- AUTH REPO: ERRO CRÍTICO ao tentar buscar o documento: $e ---');
      rethrow;
    }
  }

  Future<List<app.UserModel>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs
          .map((d) => app.UserModel.fromFirestore(d.data(), d.id))
          .toList();
    } catch (e) {
      print('### ERRO ao buscar todos os utilizadores: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    print('--- AUTH REPO: A fazer logout ---');
    await _firebaseAuth.signOut();
  }
}