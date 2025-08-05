// lib/main.dart (versão corrigida e completa)

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'config/theme/app_theme.dart'; // Importação do nosso tema
import 'managers/auth_service.dart';
import 'models/app_user.dart';
import 'widgets/auth_wrapper.dart';
import 'firebase_options.dart';

//##############################################################################
//# PONTO DE ENTRADA DA APLICAÇÃO
//##############################################################################

void main() {
  // Garante que o Flutter está inicializado.
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicia a aplicação com o Provider no topo da árvore de widgets.
  runApp(
    Provider<AuthService>.value(
      value: authService,
      child: const MyApp(),
    ),
  );
}

//##############################################################################
//# WIDGET RAIZ DA APLICAÇÃO (MyApp) - Estrutura Corrigida
//##############################################################################

// A classe StatefulWidget. A única coisa que ela faz é criar o seu State.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

// A classe State. É aqui que toda a lógica e a UI são construídas.
class _MyAppState extends State<MyApp> {
  // Usamos um Future para guardar o resultado da inicialização do Firebase.
  final Future<FirebaseApp> _initialization = _initializeFirebase();

  // Método estático para encapsular a lógica de inicialização.
  static Future<FirebaseApp> _initializeFirebase() async {
    final FirebaseApp app = await Firebase.initializeApp(
      options: kIsWeb
          ? DefaultFirebaseOptions.web
          : DefaultFirebaseOptions.currentPlatform,
    );

    // Tenta fazer o login anónimo.
    try {
      await FirebaseAuth.instance.signInAnonymously();
      print("Login anónimo no Firebase realizado com sucesso!");
    } catch (e) {
      print("### ERRO no login anónimo no Firebase: $e");
    }
    
    return app;
  }

  // O método build pertence à classe State, não à StatefulWidget.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vitrine Digital de Moda',
      debugShowCheckedModeBanner: false,
      
      // Aplicando o tema que centralizámos no ficheiro app_theme.dart
      theme: AppTheme.darkTheme, 

      // O FutureBuilder vai mostrar um ecrã de carregamento enquanto o Firebase inicializa.
      home: FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {
          // Se houver um erro na inicialização.
          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(
                child: Text('Erro ao inicializar a aplicação.'),
              ),
            );
          }

          // Se a inicialização estiver completa, mostre o AuthWrapper.
          if (snapshot.connectionState == ConnectionState.done) {
            return const AuthWrapper();
          }

          // Enquanto estiver a inicializar, mostre um indicador de progresso.
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }
}