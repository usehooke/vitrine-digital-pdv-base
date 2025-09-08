// CRIE ESTE NOVO FICHEIRO: lib/presentation/product/product_detail_controller.dart

import '../../data/models/variant_model.dart';
import '../../data/models/sku_model.dart';
import '../../data/repositories/product_repository.dart';

class ProductDetailController {
  final ProductRepository _repository;
  final String productId;

  ProductDetailController(this._repository, this.productId);

  Stream<List<VariantModel>> get variantsStream => _repository.getVariantsStream(productId);

  Stream<List<SkuModel>> getSkusStream(String variantId) {
    return _repository.getSkusStream(productId, variantId);
  }
}