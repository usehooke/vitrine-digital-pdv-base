// CRIE ESTE NOVO FICHEIRO: lib/presentation/home/home_controller.dart

import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';

class HomeController {
  final ProductRepository _productRepository;

  HomeController(this._productRepository);

  Stream<List<ProductModel>> get productsStream =>
      _productRepository.getProductsStream();
}
