import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:equatable/equatable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pinput/pinput.dart';
import 'package:crypto/crypto.dart';

import 'firebase_options.dart';

//##############################################################################
//# ESTRUTURAS DE DADOS (MODELS)
//##############################################################################

/// Modelo de dados para um item no carrinho de compras.
/// Utiliza o pacote `equatable` para facilitar a comparação de objetos.
class CartItem extends Equatable {
  final String productId;
  final String sku;
  final String nome;
  final String cor;
  final String tamanho;
  final String categoria;
  final double precoVarejo;
  final double precoAtacado;
  final int quantidade;

  const CartItem({
    required this.productId,
    required this.sku,
    required this.nome,
    required this.cor,
    required this.tamanho,
    required this.categoria,
    required this.precoVarejo,
    required this.precoAtacado,
    this.quantidade = 1,
  });

  CartItem copyWith({
    int? quantidade,
  }) {
    return CartItem(
      productId: productId,
      sku: sku,
      nome: nome,
      cor: cor,
      tamanho: tamanho,
      categoria: categoria,
      precoVarejo: precoVarejo,
      precoAtacado: precoAtacado,
      quantidade: quantidade ?? this.quantidade,
    );
  }

  @override
  List<Object?> get props => [sku];
}

/// Modelo de dados puro para representar uma variação de cor de um produto.
class ColorVariant {
  String cor;
  String imagem;
  ColorVariant({this.cor = '', this.imagem = ''});
}

/// Modelo de dados puro para representar uma variação de SKU de um produto.
class SkuVariant {
  String cor;
  String tamanho;
  double preco_varejo;
  double preco_atacado;
  int estoque;
  int estoque_minimo;
  String sku;

  SkuVariant({
    required this.cor,
    required this.tamanho,
    required this.preco_varejo,
    required this.preco_atacado,
    required this.estoque,
    required this.estoque_minimo,
    required this.sku,
  });
}

/// Modelo de dados para um usuário do sistema de login local.
class AppUser {
  final String name;
  final String pinHash;
  final bool isAdmin;

  AppUser({required this.name, required this.pinHash, this.isAdmin = false});

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      name: json['name'],
      pinHash: json['pinHash'],
      isAdmin: json['isAdmin'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'pinHash': pinHash,
      'isAdmin': isAdmin,
    };
  }
}

//##############################################################################
//# GESTORES DE ESTADO GLOBAIS
//##############################################################################

/// Gestor de estado para o Carrinho de Compras.
class CartManager extends ValueNotifier<List<CartItem>> {
  CartManager() : super([]);

  void addItem(CartItem newItem) {
    final items = List<CartItem>.from(value);
    final existingIndex = items.indexWhere((item) => item.sku == newItem.sku);

    if (existingIndex >= 0) {
      final existingItem = items[existingIndex];
      items[existingIndex] = existingItem.copyWith(
        quantidade: existingItem.quantidade + newItem.quantidade,
      );
    } else {
      items.add(newItem);
    }
    value = items;
  }

  void removeItem(String sku) {
    final items = List<CartItem>.from(value);
    items.removeWhere((item) => item.sku == sku);
    value = items;
  }

  void updateQuantity(String sku, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(sku);
      return;
    }
    
    final items = List<CartItem>.from(value);
    final index = items.indexWhere((item) => item.sku == sku);
    
    if (index >= 0) {
      items[index] = items[index].copyWith(quantidade: newQuantity);
      value = items;
    }
  }

  void clear() {
    value = [];
  }

  int get totalItems => value.fold(0, (sum, item) => sum + item.quantidade);
  
  double get totalPrice {
    bool isAtacado = totalItems >= 5;
    return value.fold(0.0, (sum, item) {
      final price = isAtacado ? item.precoAtacado : item.precoVarejo;
      return sum + (price * item.quantidade);
    });
  }
}

final cartManager = CartManager();

/// Serviço de autenticação para gerir usuários e logins com PIN.
class AuthService extends ValueNotifier<AppUser?> {
  AuthService() : super(null);

  final _storage = const FlutterSecureStorage();
  static const _usersKey = 'app_users';

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin); 
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<List<AppUser>> getUsers() async {
    final usersJson = await _storage.read(key: _usersKey);
    if (usersJson == null) return [];
    final List<dynamic> usersList = jsonDecode(usersJson);
    return usersList.map((json) => AppUser.fromJson(json)).toList();
  }

  Future<void> _saveUsers(List<AppUser> users) async {
    await _storage.write(key: _usersKey, value: jsonEncode(users.map((u) => u.toJson()).toList()));
  }

  Future<bool> createUser(String name, String pin) async {
    final users = await getUsers();
    if (users.any((user) => user.name.toLowerCase() == name.toLowerCase())) {
      return false; 
    }
    
    final isFirstUserAdmin = users.isEmpty;
    final newUser = AppUser(name: name, pinHash: _hashPin(pin), isAdmin: isFirstUserAdmin);
    users.add(newUser);
    await _saveUsers(users);
    return true;
  }

  Future<bool> login(String name, String pin) async {
    final users = await getUsers();
    try {
      final user = users.firstWhere((u) => u.name == name);
      if (user.pinHash == _hashPin(pin)) {
        value = user;
        return true;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  void logout() {
    value = null;
  }

  Future<bool> deleteUser(String nameToDelete) async {
    if (value?.name == nameToDelete) {
      return false;
    }
    final users = await getUsers();
    users.removeWhere((user) => user.name == nameToDelete);
    await _saveUsers(users);
    return true;
  }

  Future<bool> toggleAdminStatus(String nameToUpdate) async {
    final users = await getUsers();
    
    final adminCount = users.where((u) => u.isAdmin).length;
    final targetUser = users.firstWhere((u) => u.name == nameToUpdate);
    if (targetUser.isAdmin && adminCount <= 1) {
      return false;
    }

    for (var i = 0; i < users.length; i++) {
      if (users[i].name == nameToUpdate) {
        users[i] = AppUser(name: users[i].name, pinHash: users[i].pinHash, isAdmin: !users[i].isAdmin);
        break;
      }
    }
    await _saveUsers(users);
    return true;
  }
}

final authService = AuthService();

//##############################################################################
//# PONTO DE ENTRADA DA APLICAÇÃO
//##############################################################################

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: kIsWeb
        ? DefaultFirebaseOptions.web
        : DefaultFirebaseOptions.currentPlatform,
  );

  try {
    await FirebaseAuth.instance.signInAnonymously();
    print("Login anónimo no Firebase realizado com sucesso!");
  } catch (e) {
    print("### ERRO no login anónimo no Firebase: $e");
  }

  runApp(const MyApp());
}

//##############################################################################
//# WIDGET RAIZ DA APLICAÇÃO (MyApp)
//##############################################################################

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vitrine Digital de Moda',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0ea5e9),
        scaffoldBackgroundColor: const Color(0xFF0f172a),
        cardColor: const Color(0xFF1e293b),
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF0ea5e9)),
          ),
          labelStyle: const TextStyle(color: Colors.grey),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0ea5e9),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

//##############################################################################
//# TELAS (SCREENS)
//##############################################################################

/// Widget que decide qual tela mostrar: Login ou Home.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppUser?>(
      valueListenable: authService,
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

/// Tela de seleção de usuário.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Bem-vindo', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Selecione o seu perfil para continuar', style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 48),
              FutureBuilder<List<AppUser>>(
                future: _usersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('Nenhum usuário cadastrado.', style: TextStyle(color: Colors.grey));
                  }

                  final users = snapshot.data!;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: users.map((user) => _buildUserAvatar(context, user)).toList(),
                  );
                },
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Criar Novo Usuário'),
                onPressed: () async {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CreateUserPage()));
                  _loadUsers();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context, AppUser user) {
    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute(builder: (context) => PinInputPage(user: user)));
      },
      borderRadius: BorderRadius.circular(50),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFF1e293b),
            child: Text(user.name.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 32, color: Colors.white)),
          ),
          const SizedBox(height: 8),
          Text(user.name),
        ],
      ),
    );
  }
}

/// Tela para inserir o PIN de 4 dígitos.
class PinInputPage extends StatefulWidget {
  final AppUser user;
  const PinInputPage({super.key, required this.user});

  @override
  State<PinInputPage> createState() => _PinInputPageState();
}

class _PinInputPageState extends State<PinInputPage> {
  final pinController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  Future<void> _attemptLogin(String pin) async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final success = await authService.login(widget.user.name, pin);

    if (mounted) {
      if (!success) {
        setState(() {
          _isLoading = false;
          _errorText = 'PIN incorreto. Tente novamente.';
          pinController.clear();
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
              const Text('Digite o seu PIN de 4 dígitos', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 32),
              Pinput(
                controller: pinController,
                length: 4,
                obscureText: true,
                autofocus: true,
                onCompleted: _attemptLogin,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),
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

/// Tela para criar um novo usuário com nome e PIN.
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

  Future<void> _createUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      final success = await authService.createUser(_nameController.text.trim(), _pinController.text);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuário criado com sucesso!'), backgroundColor: Colors.green));
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Este nome de usuário já existe.'), backgroundColor: Colors.orange));
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
              width: 400,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nome do Usuário'),
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
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

/// Tela de gestão de usuários (apenas para Admins).
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerir Usuários')),
      body: FutureBuilder<List<AppUser>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum usuário para gerir.'));
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final user = snapshot.data![index];
              return ListTile(
                title: Text(user.name),
                subtitle: Text(user.isAdmin ? 'Administrador' : 'Vendedor'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: user.isAdmin,
                      onChanged: (value) async {
                        final success = await authService.toggleAdminStatus(user.name);
                        if (!success && mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não é possível remover o último administrador.'), backgroundColor: Colors.orange));
                        }
                        _loadUsers();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        final success = await authService.deleteUser(user.name);
                        if (!success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não pode apagar o seu próprio usuário.'), backgroundColor: Colors.orange));
                        }
                        _loadUsers();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Tela principal da aplicação, a vitrine de produtos.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Stream<QuerySnapshot> _productsStream = FirebaseFirestore.instance
      .collection('artifacts/hooke-loja-pdv-d2e5c/public/data/produtos')
      .orderBy('nome')
      .snapshots();

  void _showProductDialog({String? documentId, Map<String, dynamic>? data}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddProductDialog(documentId: documentId, initialData: data);
      },
    );
  }

  void _showCartDialog() {
    showDialog(
      context: context,
      builder: (context) => const CartDialog(),
    );
  }

  void _showSalesHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => const SalesHistoryDialog(),
    );
  }
  
  void _showDashboardDialog() {
    showDialog(
      context: context,
      builder: (context) => const DashboardDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder<AppUser?>(
          valueListenable: authService,
          builder: (context, user, child) {
            return Text(
              user?.name ?? 'Vitrine de Moda',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Ler Código',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ScannerPage()));
            },
          ),
          if (authService.value?.isAdmin ?? false)
            IconButton(
              icon: const Icon(Icons.dashboard_outlined),
              tooltip: 'Dashboard',
              onPressed: _showDashboardDialog,
            ),
          if (authService.value?.isAdmin ?? false)
            IconButton(
              icon: const Icon(Icons.manage_accounts),
              tooltip: 'Gerir Usuários',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const UsersManagementPage())),
            ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Histórico de Vendas',
            onPressed: _showSalesHistoryDialog,
          ),
          ValueListenableBuilder<List<CartItem>>(
            valueListenable: cartManager,
            builder: (context, items, child) {
              return Badge(
                label: Text('${cartManager.totalItems}'),
                isLabelVisible: cartManager.totalItems > 0,
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  tooltip: 'Carrinho',
                  onPressed: _showCartDialog,
                ),
              );
            },
          ),
           IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => authService.logout(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _productsStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Algo deu errado ao carregar os produtos.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum produto encontrado.\nClique no botão + para adicionar o seu primeiro produto.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }
          
          return LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 2; 
              if (constraints.maxWidth > 1200) {
                crossAxisCount = 5;
              } else if (constraints.maxWidth > 800) {
                crossAxisCount = 4;
              } else if (constraints.maxWidth > 550) {
                crossAxisCount = 3;
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.6,
                ),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final document = snapshot.data!.docs[index];
                  final data = document.data()! as Map<String, dynamic>;
                  return ProductGridItem(
                    id: document.id, 
                    data: data,
                    onEdit: () => _showProductDialog(documentId: document.id, data: data),
                  );
                },
              );
            }
          );
        },
      ),
      floatingActionButton: (authService.value?.isAdmin ?? false)
          ? FloatingActionButton(
              onPressed: () => _showProductDialog(),
              backgroundColor: const Color(0xFF0ea5e9),
              tooltip: 'Adicionar Produto',
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

// ... O restante do código (Widgets) será fornecido na próxima resposta.

