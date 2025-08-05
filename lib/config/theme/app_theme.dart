// lib/config/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'app_colors.dart'; // Importe as cores

// Uma classe para centralizar as definições de tema da aplicação.
class AppTheme {
  // Construtor privado para que ninguém possa instanciar esta classe.
  AppTheme._();

  // Definimos o tema escuro como uma variável estática e constante.
  // "static" significa que pertence à classe e não a uma instância.
  // "const" significa que é um valor constante em tempo de compilação.
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF0ea5e9), // Azul-céu
    scaffoldBackgroundColor: const Color(0xFF0f172a), // Azul-ardósia escuro
    cardColor: const Color(0xFF1e293b), // Azul-ardósia um pouco mais claro
    fontFamily: 'Inter',

    // Tema para a AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),

    // Tema para campos de texto (TextFormField, TextField)
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF0ea5e9)), // Cor primária
      ),
      labelStyle: const TextStyle(color: Colors.grey),
    ),

    // Tema para botões elevados (ElevatedButton)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0ea5e9), // Cor primária
        foregroundColor: Colors.white, // Cor do texto/ícone
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
}