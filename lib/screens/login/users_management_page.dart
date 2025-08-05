import 'package:flutter/material.dart';
import '../../managers/auth_service.dart';
import '../../models/app_user.dart';
import 'create_user_page.dart';

/// Tela para administradores gerirem todos os usuários da aplicação.
/// Permite apagar usuários e promover/despromover outros administradores.
class UsersManagementPage extends StatefulWidget {
  const UsersManagementPage({super.key});

  @override
  State<UsersManagementPage> createState() => _UsersManagementPageState();
}

class _UsersManagementPageState extends State<UsersManagementPage> {
  Future<List<AppUser>>? _usersFuture;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    setState(() {
      _usersFuture = authService.getUsers();
    });
  }

  void _showManagementOptions(AppUser user) {
    // Não mostra opções para o próprio admin logado
    if (user.name == authService.value?.name) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(user.isAdmin ? Icons.admin_panel_settings : Icons.admin_panel_settings_outlined),
              title: Text(user.isAdmin ? 'Remover permissão de Admin' : 'Tornar Admin'),
              onTap: () async {
                Navigator.pop(context);
                final success = await authService.toggleAdminStatus(user.name);
                if (!success && mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Não é possível remover o último administrador.'),
                    backgroundColor: Colors.orange,
                  ));
                }
                _loadUsers();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Apagar Usuário', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await authService.deleteUser(user.name);
                _loadUsers();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerir Usuários'),
      ),
      body: FutureBuilder<List<AppUser>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum usuário encontrado.'));
          }

          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(user.name.substring(0, 1).toUpperCase()),
                ),
                title: Text(user.name),
                subtitle: Text(user.isAdmin ? 'Administrador' : 'Vendedor'),
                trailing: (user.name != authService.value?.name) 
                  ? const Icon(Icons.more_vert)
                  : null, // Não mostra o menu para o próprio admin
                onTap: () => _showManagementOptions(user),
              );
            },
          );
        },
      ),
       floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CreateUserPage()));
          _loadUsers();
        },
        tooltip: 'Criar Novo Usuário',
        child: const Icon(Icons.add),
      ),
    );
  }
}
