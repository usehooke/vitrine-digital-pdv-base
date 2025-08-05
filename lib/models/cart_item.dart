import 'package:equatable/equatable.dart';

/// Modelo de dados para um item no carrinho de compras.
///
/// Utiliza o pacote `equatable` para facilitar a comparação de objetos,
/// o que é útil para testes e para uma gestão de estado mais robusta.
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

  /// Cria uma cópia do objeto `CartItem` com os campos atualizados.
  /// Essencial para trabalhar com estado de forma imutável.
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
  
  /// A lista de propriedades que o `equatable` usará para comparar objetos.
  @override
  List<Object?> get props => [sku];
}
