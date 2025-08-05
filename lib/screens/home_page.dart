import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../managers/auth_service.dart';
import '../managers/cart_manager.dart';
import '../models/app_user.dart';
import '../models/cart_item.dart';
import '../widgets/add_product_dialog.dart';
import '../widgets/cart_dialog.dart';
import '../widgets/dashboard_dialog.dart';
import '../widgets/product_grid_item.dart';
import '../widgets/sales_history_dialog.dart';
import 'login/users_management_page.dart';
import 'scanner_page.dart';

/// A tela principal da aplicação, que exibe a vitrine de produtos.
/// É um `StatefulWidget` para poder gerir os diálogos que são abertos a partir dela.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Cria um stream que "ouve" as alterações na coleção de produtos em tempo real.
  final Stream<QuerySnapshot> _productsStream = FirebaseFirestore.instance
      .collection('artifacts/hooke-loja-pdv-d2e5c/public/data/produtos')
      .orderBy('nome')
      .snapshots();

  /// Mostra o diálogo para adicionar ou editar um produto.
  void _showProductDialog({String? documentId, Map<String, dynamic>? data}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddProductDialog(documentId: documentId, initialData: data);
      },
    );
  }

  /// Mostra o diálogo do carrinho de compras.
  void _showCartDialog() {
    showDialog(
      context: context,
      builder: (context) => const CartDialog(),
    );
  }

  /// Mostra o diálogo do histórico de vendas.
  void _showSalesHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => const SalesHistoryDialog(),
    );
  }
  
  /// Mostra o diálogo do dashboard de análise.
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
        // *** ALTERAÇÃO AQUI: Aumenta a altura e largura para o logo. ***
        toolbarHeight: 80, 
        leadingWidth: 160, 
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Image.network(
            'https://cdn.dooca.store/162264/files/logo-hooke-vazada-1000x400-2.png?v=1744292436',
            fit: BoxFit.contain, // Garante que a imagem se ajuste sem distorção.
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.store), 
          ),
        ),
        title: ValueListenableBuilder<AppUser?>(
          valueListenable: authService,
          builder: (context, user, child) {
            return Text(
              user?.name ?? 'Vitrine de Moda',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            );
          },
        ),
        centerTitle: true,
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
