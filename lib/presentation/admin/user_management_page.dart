import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'user_management_controller.dart';
import 'widgets/user_form_bottom_sheet.dart'; // Importa o nosso novo formulário

class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UserManagementController(context.read<AuthRepository>()),
      child: const _UserManagementView(),
    );
  }
}

class _UserManagementView extends StatelessWidget {
  const _UserManagementView();

  void _showUserForm(BuildContext context, {UserModel? user}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        // Fornecemos o controller da página principal para o formulário poder usá-lo
        return ChangeNotifierProvider.value(
          value: context.read<UserManagementController>(),
          child: UserFormBottomSheet(userToEdit: user),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<UserManagementController>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Utilizadores'),
        actions: [
          IconButton(onPressed: controller.fetchUsers, icon: const Icon(Icons.refresh), tooltip: 'Atualizar Lista')
        ],
      ),
      body: Builder(
        builder: (context) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(controller.errorMessage!, textAlign: TextAlign.center),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: controller.users.length,
            itemBuilder: (context, index) {
              final user = controller.users[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?'),
                  ),
                  title: Text(user.name, style: textTheme.titleMedium),
                  subtitle: Text(user.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(
                        label: Text(
                          user.role.toUpperCase(),
                          style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: user.role == 'admin'
                            ? Theme.of(context).colorScheme.tertiaryContainer
                            : Theme.of(context).colorScheme.secondaryContainer,
                        side: BorderSide.none,
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showUserForm(context, user: user);
                          } else if (value == 'delete') {
                            // Adicionar diálogo de confirmação antes de apagar
                            controller.deleteUser(user.id);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Editar')),
                          const PopupMenuItem(value: 'delete', child: Text('Apagar')),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserForm(context),
        label: const Text('Novo Utilizador'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}