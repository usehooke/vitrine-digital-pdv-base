import 'package:flutter/material.dart';
import '../../managers/auth_service.dart';

/// Tela para criar um novo usuário com nome e PIN.
/// Inclui validação para garantir que os campos são preenchidos corretamente.
class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _isLoading = false;

  /// Tenta criar um novo usuário.
  Future<void> _createUser() async {
    // Valida o formulário antes de continuar.
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      final success = await authService.createUser(
        _nameController.text.trim(),
        _pinController.text,
      );

      // Garante que o widget ainda está na árvore de widgets.
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Usuário criado com sucesso!'),
            backgroundColor: Colors.green,
          ));
          Navigator.of(context).pop(); // Volta para a tela de login
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Este nome de usuário já existe.'),
            backgroundColor: Colors.orange,
          ));
        }
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Novo Usuário')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SizedBox(
              width: 400, // Limita a largura do formulário em telas grandes
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nome do Usuário'),
                    validator: (value) =>
                        value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pinController,
                    decoration: const InputDecoration(labelText: 'PIN de 4 dígitos'),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    validator: (value) {
                      if (value == null || value.length != 4) {
                        return 'O PIN deve ter 4 dígitos.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPinController,
                    decoration: const InputDecoration(labelText: 'Confirmar PIN'),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    validator: (value) {
                      if (value != _pinController.text) {
                        return 'Os PINs não coincidem.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _createUser,
                          child: const Text('Salvar Usuário'),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
