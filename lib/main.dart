import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/notifiers/auth_state_notifier.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/product_repository.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepository>(
          create: (_) => AuthRepository(FirebaseAuth.instance, FirebaseFirestore.instance),
        ),
        Provider<ProductRepository>(
          create: (_) => ProductRepository(FirebaseFirestore.instance),
        ),
        ChangeNotifierProvider<AuthStateNotifier>(
          create: (context) => AuthStateNotifier(context.read<AuthRepository>()),
        ),
      ],
      child: const MainApp(),
    ),
  );
}