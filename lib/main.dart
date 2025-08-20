// lib/main.dart (versão corrigida e unificada)

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

import 'app.dart';
import 'core/notifiers/auth_state_notifier.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/product_repository.dart';
import 'firebase_options.dart';

// --- IMPORTANTE: Gestão da Chave de API ---
// Para segurança, vamos ler a chave de um ambiente seguro, e não a colocar diretamente no código.
const apiKey = String.fromEnvironment('GEMINI_API_KEY');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializa o Gemini com a chave de API segura
  Gemini.init(apiKey: apiKey, enableDebugging: true);

  // Faz o login anónimo para a sessão da app
  await FirebaseAuth.instance.signInAnonymously();

  // Inicia a aplicação com todos os providers
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepository>(
          create: (_) => AuthRepository(
            FirebaseAuth.instance,
            FirebaseFirestore.instance,
          ),
        ),
        Provider<ProductRepository>(
          create: (_) => ProductRepository(FirebaseFirestore.instance),
        ),
        ChangeNotifierProvider<AuthStateNotifier>(
          create: (_) => AuthStateNotifier(),
        ),
      ],
      child: const MainApp(),
    ),
  );
}