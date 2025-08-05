import 'package:flutter/material.dart';
import '../../managers/auth_service.dart';
import '../../models/app_user.dart';
import 'create_user_page.dart';
import 'pin_input_page.dart';

/// Tela de Login que exibe os perfis de usuário existentes.
/// Permite selecionar um perfil para inserir o PIN ou navegar para a criação de um novo usuário.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Futuro que representa a lista de usuários a ser carregada.
  late Future<List<AppUser>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  /// Inicia o processo de carregamento dos usuários do armazenamento seguro.
  void _loadUsers() {
    setState(() {
      _usersFuture = authService.getUsers();
    });
  }

  /// Navega para a tela de criação de usuário e recarrega a lista ao retornar.
  void _navigateToCreateUser() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const CreateUserPage(),
    ));
    _loadUsers(); // Recarrega a lista para exibir o novo usuário.
  }

  /// Navega para a tela de inserção de PIN para o usuário selecionado.
  void _navigateToPinInput(AppUser user) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => PinInputPage(user: user),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Título e subtítulo da tela
              const Text('Bem-vindo',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Selecione o seu perfil para continuar',
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 48),

              // Construtor do futuro para exibir a lista de usuários de forma assíncrona
              FutureBuilder<List<AppUser>>(
                future: _usersFuture,
                builder: (context, snapshot) {
                  // Exibe um indicador de progresso enquanto os dados estão a ser carregados.
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  // Exibe uma mensagem se não houver usuários cadastrados.
                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return const Text('Nenhum usuário cadastrado.',
                        style: TextStyle(color: Colors.grey));
                  }

                  // Exibe a grelha de avatares dos usuários.
                  final users = snapshot.data!;
                  return Wrap(
                    spacing: 24, // Espaçamento horizontal entre os avatares
                    runSpacing: 24, // Espaçamento vertical entre as linhas de avatares
                    alignment: WrapAlignment.center,
                    children:
                        users.map((user) => _buildUserAvatar(user)).toList(),
                  );
                },
              ),
              const SizedBox(height: 48),

              // Botão para navegar para a tela de criação de usuário.
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Criar Novo Usuário'),
                onPressed: _navigateToCreateUser,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói o widget de avatar para um usuário específico.
  Widget _buildUserAvatar(AppUser user) {
    return InkWell(
      onTap: () => _navigateToPinInput(user),
      borderRadius: BorderRadius.circular(50),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFF1e293b),
            child: Text(
              user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : '?',
              style: const TextStyle(fontSize: 32, color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(user.name),
        ],
      ),
    );
  }
}
