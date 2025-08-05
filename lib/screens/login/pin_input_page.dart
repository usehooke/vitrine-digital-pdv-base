import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import '../../managers/auth_service.dart';
import '../../models/app_user.dart';

/// Tela para o usuário inserir o seu PIN de 4 dígitos.
/// Valida o PIN inserido contra o hash guardado no AuthService.
class PinInputPage extends StatefulWidget {
  final AppUser user;
  const PinInputPage({super.key, required this.user});

  @override
  State<PinInputPage> createState() => _PinInputPageState();
}

class _PinInputPageState extends State<PinInputPage> {
  final _pinController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  /// Tenta fazer o login com o PIN inserido.
  Future<void> _attemptLogin(String pin) async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final success = await authService.login(widget.user.name, pin);

    // Garante que o widget ainda está na árvore de widgets antes de atualizar o estado.
    if (mounted) {
      if (success) {
        // Se o login for bem-sucedido, o AuthWrapper tratará de navegar para a HomePage.
        // O pop() fecha a tela de PIN, revelando a HomePage.
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        setState(() {
          _isLoading = false;
          _errorText = 'PIN incorreto. Tente novamente.';
          _pinController.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login - ${widget.user.name}'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Digite o seu PIN de 4 dígitos',
                  style: TextStyle(fontSize: 18)),
              const SizedBox(height: 32),

              // Widget do pacote `pinput` para uma entrada de PIN estilizada.
              Pinput(
                controller: _pinController,
                length: 4,
                obscureText: true,
                autofocus: true,
                onCompleted: _attemptLogin,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),

              // Exibe um indicador de progresso durante o login ou uma mensagem de erro.
              if (_isLoading) const CircularProgressIndicator(),
              if (_errorText != null)
                Text(_errorText!, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }
}
