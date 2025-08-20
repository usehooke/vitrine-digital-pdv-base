import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:uuid/uuid.dart';

import 'package:vitrine_nova/data/models/product_model.dart';
import 'package:vitrine_nova/data/models/sku_model.dart';
import 'package:vitrine_nova/data/models/user_model.dart';
import 'package:vitrine_nova/data/models/variant_model.dart';
import 'package:vitrine_nova/data/repositories/product_repository.dart';
import 'package:vitrine_nova/presentation/pdv/pdv_controller.dart';

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late PdvController controller;
  late MockProductRepository mockRepo;
  late UserModel mockUser;

  setUp(() {
    mockRepo = MockProductRepository();
    mockUser = const UserModel(id: 'user123', name: 'Fernando');
    controller = PdvController(mockRepo, mockUser);
  });

  test('Adiciona item ao carrinho com estoque disponível', () {
    final product = ProductModel(id: 'p1', name: 'Tênis', model: 'AirMax');
    final variant = VariantModel(id: 'v1', color: 'Preto', imageUrl: '');
    final sku = SkuModel(
      id: 'sku1',
      size: '42',
      generatedSku: 'AIRMAX-42-PRETO',
      retailPrice: 299.99,
      wholesalePrice: 199.99,
      stock: 10,
    );

    controller.addItem(product, variant, sku);

    expect(controller.cart.length, 1);
    expect(controller.cart.first.quantity, 1);
    expect(controller.totalAmount, sku.retailPrice);
  });

  test('Não adiciona item sem estoque', () {
    final product = ProductModel(id: 'p1', name: 'Tênis', model: 'AirMax');
    final variant = VariantModel(id: 'v1', color: 'Preto', imageUrl: '');
    final sku = SkuModel(
      id: 'sku1',
      size: '42',
      generatedSku: 'AIRMAX-42-PRETO',
      retailPrice: 299.99,
      wholesalePrice: 199.99,
      stock: 0,
    );

    controller.addItem(product, variant, sku);

    expect(controller.cart.isEmpty, true);
  });

  test('Incrementa quantidade respeitando o estoque', () {
    final product = ProductModel(id: 'p1', name: 'Tênis', model: 'AirMax');
    final variant = VariantModel(id: 'v1', color: 'Preto', imageUrl: '');
    final sku = SkuModel(
      id: 'sku1',
      size: '42',
      generatedSku: 'AIRMAX-42-PRETO',
      retailPrice: 299.99,
      wholesalePrice: 199.99,
      stock: 2,
    );

    controller.addItem(product, variant, sku);
    controller.incrementQuantity(sku.id, sku.stock);
    controller.incrementQuantity(sku.id, sku.stock); // deve ser ignorado

    expect(controller.cart.first.quantity, 2);
  });

  test('Remove item do carrinho', () {
    final product = ProductModel(id: 'p1', name: 'Tênis', model: 'AirMax');
    final variant = VariantModel(id: 'v1', color: 'Preto', imageUrl: '');
    final sku = SkuModel(
      id: 'sku1',
      size: '42',
      generatedSku: 'AIRMAX-42-PRETO',
      retailPrice: 299.99,
      wholesalePrice: 199.99,
      stock: 10,
    );

    controller.addItem(product, variant, sku);
    controller.removeItem(sku.id);

    expect(controller.cart.isEmpty, true);
  });

  test('Finaliza venda com sucesso', () async {
    when(mockRepo.processSale(any)).thenAnswer((_) async => Future.value());

    final product = ProductModel(id: 'p1', name: 'Tênis', model: 'AirMax');
    final variant = VariantModel(id: 'v1', color: 'Preto', imageUrl: '');
    final sku = SkuModel(
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
    expect(controller.cart.isEmpty, true);
  });
}