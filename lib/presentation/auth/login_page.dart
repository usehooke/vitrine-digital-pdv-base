// lib/presentation/auth/login_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/notifiers/auth_state_notifier.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'login_controller.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // CORREÇÃO AQUI: Passamos as duas dependências para o controller.
      create: (context) => LoginController(
        context.read<AuthRepository>(),
        context.read<AuthStateNotifier>(),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Selecione o Utilizador'),
        ),
        body: Consumer<LoginController>(
          builder: (context, controller, child) {
            if (controller.isLoading && controller.users.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.users.isEmpty) {
              return const Center(child: Text('Nenhum utilizador encontrado.'));
            }
            return GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
              ),
              itemCount: controller.users.length,
              itemBuilder: (context, index) {
                final user = controller.users[index];
                return InkWell(
                  onTap: () => _showPinDialog(context, controller, user.id),
                  child: Card(
                    color: Theme.of(context).cardColor,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person, size: 48),
                        const SizedBox(height: 8),
                        Text(user.name, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showPinDialog(BuildContext context, LoginController controller, String userId) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Digite o seu PIN'),
          content: TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 8),
            decoration: const InputDecoration(counterText: ''),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await controller.signInWithPin(userId, pinController.text);
                if (success) {
                  if(dialogContext.mounted) Navigator.of(dialogContext).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(controller.errorMessage ?? 'Ocorreu um erro.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Entrar'),
            ),
          ],
        );
      },
    );
  }
}