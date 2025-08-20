// CONTEÚDO COMPLETO PARA: lib/presentation/home/home_controller.dart

import 'dart:async';

import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';

class HomeController {
  final ProductRepository _productRepository;

  // Estado de carregamento
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  // Stream de erro
  final StreamController<String> _errorController = StreamController.broadcast();
  Stream<String> get errorStream => _errorController.stream;

  // Stream principal de produtos
  late final Stream<List<ProductModel>> productsStream;

  HomeController(this._productRepository) {
    _initialize();
  }

  void _initialize() {
    isLoading.value = true;

    productsStream = _productRepository.getProductsStream().handleError((error) {
      _errorController.add(error.toString());
    }).map((products) {
      isLoading.value = false;
      return products;
    });
  }

  // Filtro de produtos por nome
  Stream<List<ProductModel>> getFilteredProducts(String query) {
    return productsStream.map((products) =>
      products.where((p) => p.name.toLowerCase().contains(query.toLowerCase())).toList()
    );
  }

  void dispose() {
    _errorController.close();
    isLoading.dispose();
  }
}