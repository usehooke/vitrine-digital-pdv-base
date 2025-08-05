// Importa o pacote de testes do Flutter.
import 'package:flutter_test/flutter_test.dart';
// Importa o ficheiro principal para ter acesso às classes que queremos testar.
import 'package:vitrine_nova/main.dart';

void main() {
  // 'group' é usado para organizar vários testes relacionados.
  // Neste caso, todos os testes são sobre a classe CartManager.
  group('CartManager - Testes de Lógica do Carrinho', () {
    
    // 'setUp' é uma função especial que é executada ANTES de cada teste neste grupo.
    // É útil para inicializar objetos que são usados em vários testes.
    late CartManager cartManager;
    setUp(() {
      cartManager = CartManager();
    });

    // 'test' define um caso de teste individual.
    // A descrição deve explicar claramente o que o teste está a verificar.
    test('Ao criar, o carrinho deve estar vazio', () {
      // Verificação (Assert)
      // 'expect' compara o valor atual com o valor esperado.
      expect(cartManager.totalItems, 0);
      expect(cartManager.value.isEmpty, isTrue);
    });

    test('Adicionar um novo item deve aumentar o total de itens para 1', () {
      // 1. Preparação (Arrange)
      final item = CartItem(
        productId: 'p1',
        sku: 'SKU-001',
        nome: 'Camiseta',
        cor: 'Preta',
        tamanho: 'M',
        categoria: 'Roupas',
        precoVarejo: 50.0,
        precoAtacado: 40.0,
      );

      // 2. Ação (Act)
      cartManager.addItem(item);

      // 3. Verificação (Assert)
      expect(cartManager.totalItems, 1);
      expect(cartManager.value.length, 1);
      expect(cartManager.value.first.sku, 'SKU-001');
    });

    test('Adicionar um item existente deve incrementar a quantidade, não a lista', () {
      // 1. Preparação
      final item = CartItem(productId: 'p1', sku: 'SKU-001', nome: 'Camiseta', cor: 'Preta', tamanho: 'M', categoria: 'Roupas', precoVarejo: 50.0, precoAtacado: 40.0, quantidade: 1);
      final itemDuplicado = CartItem(productId: 'p1', sku: 'SKU-001', nome: 'Camiseta', cor: 'Preta', tamanho: 'M', categoria: 'Roupas', precoVarejo: 50.0, precoAtacado: 40.0, quantidade: 2);

      // 2. Ação
      cartManager.addItem(item);
      cartManager.addItem(itemDuplicado);

      // 3. Verificação
      expect(cartManager.value.length, 1); // A lista de itens deve ter apenas 1 entrada
      expect(cartManager.totalItems, 3); // A quantidade total deve ser 1 + 2 = 3
    });

    test('Calcular preço de varejo para menos de 5 peças', () {
      // 1. Preparação
      final item1 = CartItem(productId: 'p1', sku: 'SKU-001', nome: 'Camiseta', cor: 'Preta', tamanho: 'M', categoria: 'Roupas', precoVarejo: 50.0, precoAtacado: 40.0, quantidade: 2);
      final item2 = CartItem(productId: 'p2', sku: 'SKU-002', nome: 'Calças', cor: 'Azul', tamanho: 'G', categoria: 'Roupas', precoVarejo: 100.0, precoAtacado: 80.0, quantidade: 1);
      
      // 2. Ação
      cartManager.addItem(item1);
      cartManager.addItem(item2);

      // 3. Verificação
      // Total de peças = 3. O preço deve ser de varejo.
      // (2 * 50.0) + (1 * 100.0) = 200.0
      expect(cartManager.totalItems, 3);
      expect(cartManager.totalPrice, 200.0);
    });

    test('Calcular preço de atacado para 5 ou mais peças', () {
      // 1. Preparação
      final item1 = CartItem(productId: 'p1', sku: 'SKU-001', nome: 'Camiseta', cor: 'Preta', tamanho: 'M', categoria: 'Roupas', precoVarejo: 50.0, precoAtacado: 40.0, quantidade: 3);
      final item2 = CartItem(productId: 'p2', sku: 'SKU-002', nome: 'Calças', cor: 'Azul', tamanho: 'G', categoria: 'Roupas', precoVarejo: 100.0, precoAtacado: 80.0, quantidade: 2);

      // 2. Ação
      cartManager.addItem(item1);
      cartManager.addItem(item2);

      // 3. Verificação
      // Total de peças = 5. O preço deve ser de atacado.
      // (3 * 40.0) + (2 * 80.0) = 120.0 + 160.0 = 280.0
      expect(cartManager.totalItems, 5);
      expect(cartManager.totalPrice, 280.0);
    });

    test('Remover um item deve atualizar o carrinho corretamente', () {
      // 1. Preparação
      final item1 = CartItem(productId: 'p1', sku: 'SKU-001', nome: 'Camiseta', cor: 'Preta', tamanho: 'M', categoria: 'Roupas', precoVarejo: 50.0, precoAtacado: 40.0);
      final item2 = CartItem(productId: 'p2', sku: 'SKU-002', nome: 'Calças', cor: 'Azul', tamanho: 'G', categoria: 'Roupas', precoVarejo: 100.0, precoAtacado: 80.0);
      cartManager.addItem(item1);
      cartManager.addItem(item2);

      // 2. Ação
      cartManager.removeItem('SKU-001');

      // 3. Verificação
      expect(cartManager.totalItems, 1);
      expect(cartManager.value.length, 1);
      expect(cartManager.value.first.sku, 'SKU-002');
    });

    test('Limpar o carrinho deve remover todos os itens', () {
      // 1. Preparação
      final item1 = CartItem(productId: 'p1', sku: 'SKU-001', nome: 'Camiseta', cor: 'Preta', tamanho: 'M', categoria: 'Roupas', precoVarejo: 50.0, precoAtacado: 40.0);
      final item2 = CartItem(productId: 'p2', sku: 'SKU-002', nome: 'Calças', cor: 'Azul', tamanho: 'G', categoria: 'Roupas', precoVarejo: 100.0, precoAtacado: 80.0);
      cartManager.addItem(item1);
      cartManager.addItem(item2);

      // 2. Ação
      cartManager.clearCart();

      // 3. Verificação
      expect(cartManager.totalItems, 0);
      expect(cartManager.value.isEmpty, isTrue);
    });
  });
}
