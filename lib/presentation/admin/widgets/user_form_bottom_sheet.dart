import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/user_model.dart';
import '../user_management_controller.dart';

class UserFormBottomSheet extends StatefulWidget {
  final UserModel? userToEdit;
  const UserFormBottomSheet({super.key, this.userToEdit});

  @override
  State<UserFormBottomSheet> createState() => _UserFormBottomSheetState();
}

class _UserFormBottomSheetState extends State<UserFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  String _selectedRole = 'pdv';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = widget.userToEdit;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _passwordController = TextEditingController();
    _selectedRole = user?.role ?? 'pdv';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final controller = context.read<UserManagementController>();
    
    String? error;
    if (widget.userToEdit == null) { // Modo de Criação
      error = await controller.createUser(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        role: _selectedRole,
      );
    } else { // Modo de Edição
      error = await controller.updateUser(
        widget.userToEdit!.id,
        _nameController.text,
        _selectedRole,
      );
    }

    if (mounted) {
      if (error == null) {
        Navigator.of(context).pop(); // Fecha o formulário em caso de sucesso
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.userToEdit != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isEditMode ? 'Editar Utilizador' : 'Novo Utilizador', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (value) => (value == null || value.isEmpty) ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'E-mail'),
              keyboardType: TextInputType.emailAddress,
              enabled: !isEditMode,
              validator: (value) => (value == null || !value.contains('@')) ? 'E-mail inválido' : null,
            ),
            if (!isEditMode) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Senha'),
                obscureText: true,
                validator: (value) => (value == null || value.length < 6) ? 'A senha deve ter pelo menos 6 caracteres' : null,
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(labelText: 'Função (Role)'),
              items: ['pdv', 'admin'].map((role) => DropdownMenuItem(value: role, child: Text(role.toUpperCase()))).toList(),
              onChanged: (value) => setState(() => _selectedRole = value ?? 'pdv'),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isLoading ? null : _submitForm,
              icon: _isLoading ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
              label: Text(isEditMode ? 'Salvar Alterações' : 'Criar Utilizador'),
            ),
          ],
        ),
      ),
    );
  }
}