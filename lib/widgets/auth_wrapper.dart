// lib/widgets/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Importe o Provider
import '../managers/auth_service.dart'; // Ajuste o caminho se necessário
import '../models/app_user.dart';
import '../screens/home_page.dart';
import '../screens/login/login_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Em vez de ouvir um ValueListenable global, obtemos o serviço via Provider.
    final authService = Provider.of<AuthService>(context);

    // O ValueListenableBuilder continua a ser uma ótima escolha aqui.
    return ValueListenableBuilder<AppUser?>(
      valueListenable: authService, // Ouve o ValueNotifier do serviço obtido
      builder: (context, user, child) {
        if (user == null) {
          return const LoginPage();
        } else {
          return const HomePage();
        }
      },
    );
  }
}