// lib/config/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF0ea5e9),
    scaffoldBackgroundColor: const Color(0xFF0f172a),
    cardColor: const Color(0xFF1e293b),
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1e293b), // Dando uma cor sólida à AppBar
      elevation: 4,
      centerTitle: true,
    ),
    // ... pode adicionar outras configurações de tema aqui
  );
}