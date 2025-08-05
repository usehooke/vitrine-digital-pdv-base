/// Modelo de dados puro para uma variante de cor de um produto.
/// Contém apenas os dados, separando a lógica da interface.
class ColorVariant {
  String cor;
  String imagemUrl;

  ColorVariant({this.cor = '', this.imagemUrl = ''});
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
