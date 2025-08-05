import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../managers/auth_service.dart';
import '../managers/cart_manager.dart';
import '../models/cart_item.dart';
import 'add_product_dialog.dart';

/// Um widget que representa um único produto na grelha da vitrine.
/// É um `StatefulWidget` para poder gerir o seu próprio estado interno, como a cor
/// e o tamanho selecionados pelo utilizador.
class ProductGridItem extends StatefulWidget {
  final String id;
  final Map<String, dynamic> data;
  final VoidCallback onEdit;

  const ProductGridItem({
    super.key,
    required this.id,
    required this.data,
    required this.onEdit,
  });

  @override
  State<ProductGridItem> createState() => _ProductGridItemState();
}

class _ProductGridItemState extends State<ProductGridItem> {
  String? _selectedColor;
  String? _selectedSize;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    // Ao iniciar, seleciona automaticamente a primeira cor disponível como padrão.
    if (widget.data['cores'] != null && (widget.data['cores'] as Map).isNotEmpty) {
      _selectedColor = (widget.data['cores'] as Map).keys.first;
    }
  }

  /// Exibe um diálogo de confirmação para apagar o produto.
  void _deleteProduct() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem a certeza de que quer apagar este produto? Esta ação é irreversível.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection(
                      'artifacts/hooke-loja-pdv-d2e5c/public/data/produtos')
                  .doc(widget.id)
                  .delete();
              Navigator.of(context).pop();
            },
            child: const Text('Apagar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Extrai os dados do produto do mapa `widget.data`.
    final String nome = widget.data['nome'] ?? 'Produto sem nome';
    final Map<String, dynamic> cores = widget.data['cores'] ?? {};
    final String imagemUrl = _selectedColor != null && cores[_selectedColor] != null
        ? (cores[_selectedColor]['imagem'] ?? widget.data['imagem_principal'])
        : (widget.data['imagem_principal'] ??
            'https://placehold.co/400x600/1e293b/ffffff?text=Sem+Imagem');
    
    final Map<String, dynamic> skus = widget.data['skus'] ?? {};
    final double precoReferencia =
        (skus.isNotEmpty ? (skus.values.first['preco_varejo'] ?? 0.0) : 0.0)
            .toDouble();
    
    // Filtra os tamanhos disponíveis com base na cor selecionada.
    final Map<String, dynamic> tamanhosDisponiveis = {};
    if (_selectedColor != null) {
      skus.forEach((key, value) {
        if (value['cor'] == _selectedColor) {
          tamanhosDisponiveis[value['tamanho']] = value;
        }
      });
    }

    // Ordena os tamanhos na sequência padrão.
    final List<String> tamanhosOrdenados = tamanhosDisponiveis.keys.toList()
      ..sort((a, b) {
        const ordem = {'P': 0, 'M': 1, 'G': 2, 'GG': 3, 'EXG': 4};
        return (ordem[a] ?? 99).compareTo(ordem[b] ?? 99);
      });

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Secção da Imagem com o menu de editar/apagar
          Expanded(
            child: Stack(
              children: [
                Image.network(
                  imagemUrl,
                  semanticLabel: 'Imagem do produto $nome na cor $_selectedColor',
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.error)),
                ),
                if (authService.value?.isAdmin ?? false)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          widget.onEdit();
                        } else if (value == 'delete') {
                          _deleteProduct();
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                            value: 'edit', child: Text('Editar')),
                        const PopupMenuItem<String>(
                            value: 'delete', child: Text('Apagar')),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Secção de informações e seletores
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nome,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                    'A partir de R\$ ${precoReferencia.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Color(0xFF38bdf8), fontSize: 16)),
                const SizedBox(height: 12),
                
                // Seletor de Cores com miniaturas
                Wrap(
                  spacing: 8.0,
                  children: cores.keys.map((cor) {
                    final String colorImageUrl = cores[cor]['imagem'] ?? '';
                    return Semantics(
                      label: 'Selecionar a cor $cor',
                      button: true,
                      child: InkWell(
                        onTap: () => setState(() {
                          _selectedColor = cor;
                          _selectedSize = null;
                          _quantity = 1;
                        }),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: _selectedColor == cor
                                ? Border.all(
                                    color: const Color(0xFF0ea5e9), width: 2)
                                : Border.all(
                                    color: Colors.grey.withOpacity(0.5)),
                          ),
                          child: ClipOval(
                            child: Image.network(
                              colorImageUrl,
                              fit: BoxFit.cover,
                              semanticLabel:
                                  'Miniatura do produto na cor $cor',
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.hide_image, size: 16),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Seletor de Tamanhos (só aparece se uma cor for selecionada)
                if (_selectedColor != null)
                  SizedBox(
                    height: 36,
                    child: Wrap(
                      spacing: 8.0,
                      children: tamanhosOrdenados.map((tamanho) {
                        final skuData = skus.values.firstWhere((s) => s['cor'] == _selectedColor && s['tamanho'] == tamanho, orElse: () => {});
                        final stock = skuData['estoque'] ?? 0;
                        return ChoiceChip(
                          label: Text(tamanho),
                          selected: _selectedSize == tamanho,
                          tooltip: 'Estoque: $stock',
                          onSelected: stock > 0
                              ? (selected) =>
                                  setState(() => _selectedSize = tamanho)
                              : null,
                          backgroundColor: const Color(0xFF334155),
                          selectedColor: const Color(0xFF0ea5e9),
                          labelPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                        );
                      }).toList(),
                    ),
                  ),
                
                const SizedBox(height: 12),
                
                // Seletor de Quantidade e Botão Adicionar (só aparecem se um tamanho for selecionado)
                if (_selectedSize != null)
                  Row(
                    children: [
                      IconButton(
                          icon: const Icon(Icons.remove),
                          tooltip: 'Diminuir quantidade',
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null),
                      Text('$_quantity'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        tooltip: 'Aumentar quantidade',
                        onPressed: () {
                           final skuData = skus.values.firstWhere((s) => s['cor'] == _selectedColor && s['tamanho'] == _selectedSize, orElse: () => {});
                           final stock = skuData['estoque'] ?? 0;
                          if (_quantity < stock) {
                            setState(() => _quantity++);
                          }
                        },
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          final skuData = skus.values.firstWhere((s) => s['cor'] == _selectedColor && s['tamanho'] == _selectedSize);
                          final item = CartItem(
                            productId: widget.id,
                            sku: skuData['sku'],
                            nome: nome,
                            cor: skuData['cor'],
                            tamanho: skuData['tamanho'],
                            categoria: widget.data['categoria'] ?? '',
                            precoVarejo: (skuData['preco_varejo'] as num).toDouble(),
                            precoAtacado: (skuData['preco_atacado'] as num).toDouble(),
                            quantidade: _quantity,
                          );
                          cartManager.addItem(item);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  '$_quantity x $nome adicionado ao carrinho!'),
                              backgroundColor: Colors.green));
                          setState(() {
                            _selectedSize = null;
                            _quantity = 1;
                          });
                        },
                        child: const Text('Adicionar'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
