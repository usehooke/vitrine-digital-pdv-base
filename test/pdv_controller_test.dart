import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
// uuid import removed (unused in tests)

import 'package:vitrine_nova/data/models/product_model.dart';
import 'package:vitrine_nova/data/models/sku_model.dart';
import 'package:vitrine_nova/data/models/user_model.dart';
import 'package:vitrine_nova/data/models/sale_model.dart';
import 'package:vitrine_nova/data/models/variant_model.dart';
import 'package:vitrine_nova/data/repositories/product_repository.dart';
import 'package:vitrine_nova/presentation/pdv/pdv_controller.dart';

class MockProductRepository extends Mock implements ProductRepository {}

/// A simple fake that overrides only the `processSale` method to avoid
/// mockito null-safety matcher issues in tests. We keep other behavior from
/// MockProductRepository when not needed.
class FakeProductRepository extends Mock implements ProductRepository {
  @override
  Future<void> processSale(SaleModel sale) async {
    // No-op successful completion
    return Future<void>.value();
  }
}

void main() {
  late PdvController controller;
  late ProductRepository mockRepo;
  late UserModel mockUser;

  setUp(() {
  // Use a fake implementation that guarantees processSale returns a Future.
  mockRepo = FakeProductRepository();
    mockUser = const UserModel(id: 'user123', name: 'Fernando', email: '', role: 'seller');
    controller = PdvController(mockRepo, mockUser);
  });

  test('Adiciona item ao carrinho com estoque disponível', () {
  const product = ProductModel(id: 'p1', name: 'Tênis', model: 'AirMax', category: '', mainImageUrl: '');
    const variant = VariantModel(id: 'v1', color: 'Preto', imageUrl: '');
    const sku = SkuModel(
      id: 'sku1',
      size: '42',
      generatedSku: 'AIRMAX-42-PRETO',
      retailPrice: 299.99,
      wholesalePrice: 199.99,
      stock: 10,
    );

    controller.addItem(product, variant, sku);

  expect(controller.cart.value.length, 1);
  expect(controller.cart.value.first.quantity, 1);
  expect(controller.totalAmount.value, sku.retailPrice);
  });

  test('Não adiciona item sem estoque', () {
  const product = ProductModel(id: 'p1', name: 'Tênis', model: 'AirMax', category: '', mainImageUrl: '');
  const variant = VariantModel(id: 'v1', color: 'Preto', imageUrl: '');
    const sku = SkuModel(
      id: 'sku1',
      size: '42',
      generatedSku: 'AIRMAX-42-PRETO',
      retailPrice: 299.99,
      wholesalePrice: 199.99,
      stock: 0,
    );

    controller.addItem(product, variant, sku);

  expect(controller.cart.value.isEmpty, true);
  });

  test('Incrementa quantidade respeitando o estoque', () {
  const product = ProductModel(id: 'p1', name: 'Tênis', model: 'AirMax', category: '', mainImageUrl: '');
  const variant = VariantModel(id: 'v1', color: 'Preto', imageUrl: '');
  const sku = SkuModel(
      id: 'sku1',
      size: '42',
      generatedSku: 'AIRMAX-42-PRETO',
      retailPrice: 299.99,
      wholesalePrice: 199.99,
      stock: 2,
    );

  controller.addItem(product, variant, sku);
  controller.incrementQuantity(sku.id);
  controller.incrementQuantity(sku.id); // deve ser ignorado (máximo estoque)

  expect(controller.cart.value.first.quantity, 2);
  });

  test('Remove item do carrinho', () {
  const product = ProductModel(id: 'p1', name: 'Tênis', model: 'AirMax', category: '', mainImageUrl: '');
  const variant = VariantModel(id: 'v1', color: 'Preto', imageUrl: '');
    const sku = SkuModel(
      id: 'sku1',
      size: '42',
      generatedSku: 'AIRMAX-42-PRETO',
      retailPrice: 299.99,
      wholesalePrice: 199.99,
      stock: 10,
    );

  controller.addItem(product, variant, sku);
  controller.decrementQuantity(sku.id);

  expect(controller.cart.value.isEmpty, true);
  });

  test('Finaliza venda com sucesso', () async {
  // No explicit stub for processSale; PdvController.finalizeSale handles mocks that return null.
  const product = ProductModel(id: 'p1', name: 'Tênis', model: 'AirMax', category: '', mainImageUrl: '');
  const variant = VariantModel(id: 'v1', color: 'Preto', imageUrl: '');
  const sku = SkuModel(
      id: 'sku1',
      size: '42',
      generatedSku: 'AIRMAX-42-PRETO',
      retailPrice: 299.99,
      wholesalePrice: 199.99,
      stock: 10,
    );

  controller.addItem(product, variant, sku);
  final result = await controller.finalizeSale();

  expect(result, contains('sucesso'));
  expect(controller.cart.value.isEmpty, true);
  });
}