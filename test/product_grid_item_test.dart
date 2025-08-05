// Importa o pacote de testes do Flutter, que contém ferramentas para testar widgets.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Importa o ficheiro principal para ter acesso ao widget que queremos testar.
import 'package:vitrine_nova/main.dart';

// Uma função auxiliar para envolver o nosso widget num ambiente de teste mínimo.
// Um widget como o ProductGridItem precisa de um `MaterialApp` e `Scaffold`
// para ter acesso a coisas como temas, fontes e direção do texto.
Widget createTestableWidget({required Widget child}) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  // Organiza os testes relacionados com o ProductGridItem.
  group('ProductGridItem - Testes de UI e Interação', () {
    
    // CORREÇÃO: Os dados falsos foram atualizados para incluir o campo 'sku' dentro de cada variação,
    // espelhando a estrutura de dados real no Firebase.
    final mockProductData = {
      'nome': 'Manga Curta Fusca',
      'categoria': 'Camisetas',
      'imagem_principal': 'https://placehold.co/400x600/1e293b/ffffff?text=Fusca',
      'cores': {
        'Preto': {
          'imagem': 'https://placehold.co/400x600/000000/ffffff?text=Preto',
        },
        'Branco': {
          'imagem': 'https://placehold.co/400x600/ffffff/000000?text=Branco',
        }
      },
      'skus': {
        'SKU-FUSCA-PRETO-P': {'sku': 'SKU-FUSCA-PRETO-P', 'cor': 'Preto', 'tamanho': 'P', 'preco_varejo': 50.0, 'preco_atacado': 40.0, 'estoque': 5},
        'SKU-FUSCA-PRETO-M': {'sku': 'SKU-FUSCA-PRETO-M', 'cor': 'Preto', 'tamanho': 'M', 'preco_varejo': 50.0, 'preco_atacado': 40.0, 'estoque': 3},
        'SKU-FUSCA-BRANCO-M': {'sku': 'SKU-FUSCA-BRANCO-M', 'cor': 'Branco', 'tamanho': 'M', 'preco_varejo': 55.0, 'preco_atacado': 45.0, 'estoque': 10},
        'SKU-FUSCA-BRANCO-G': {'sku': 'SKU-FUSCA-BRANCO-G', 'cor': 'Branco', 'tamanho': 'G', 'preco_varejo': 55.0, 'preco_atacado': 45.0, 'estoque': 0},
      }
    };

    // 'testWidgets' é o construtor para um teste de widget.
    // Ele fornece um `WidgetTester`, a nossa ferramenta para interagir com os widgets.
    testWidgets('Deve exibir o nome e o preço de referência iniciais', (WidgetTester tester) async {
      // 1. Preparação (Arrange) & Ação (Act)
      // 'pumpWidget' renderiza o widget no ambiente de teste.
      await tester.pumpWidget(createTestableWidget(
        child: ProductGridItem(id: 'prod-123', data: mockProductData, onEdit: () {}),
      ));

      // 2. Verificação (Assert)
      // 'find.text' procura por um widget de Texto com o conteúdo exato.
      // 'findsOneWidget' verifica se exatamente um widget foi encontrado.
      expect(find.text('Manga Curta Fusca'), findsOneWidget);
      expect(find.text('A partir de R\$ 50.00'), findsOneWidget);
    });

    testWidgets('Ao selecionar uma cor, os tamanhos corretos devem aparecer', (WidgetTester tester) async {
      // 1. Preparação
      await tester.pumpWidget(createTestableWidget(
        child: ProductGridItem(id: 'prod-123', data: mockProductData, onEdit: () {}),
      ));

      // Verificação Inicial: Apenas os tamanhos da cor padrão (Preto) devem estar visíveis.
      expect(find.text('P'), findsOneWidget);
      expect(find.text('M'), findsOneWidget);
      expect(find.text('G'), findsNothing); // Tamanho G não existe para a cor Preta.

      // 2. Ação
      // CORREÇÃO: O seletor de cor "Branco" é o segundo widget InkWell na lista de cores.
      // O finder `find.byType(InkWell)` encontra vários: o cartão, o menu, e depois as cores.
      // Esta abordagem mais específica garante que estamos a clicar no sítio certo.
      await tester.tap(find.byWidgetPredicate(
        (widget) => widget is InkWell && widget.child is Container && (widget.child as Container).decoration != null,
      ).at(1)); // .at(0) é Preto, .at(1) é Branco
      
      // Usa pumpAndSettle para aguardar a conclusão de todas as animações e reconstruções.
      await tester.pumpAndSettle();

      // 3. Verificação
      // Agora, os tamanhos da cor Branca devem estar visíveis.
      expect(find.text('P'), findsNothing); // Tamanho P não existe para a cor Branca.
      expect(find.text('M'), findsOneWidget);
      expect(find.text('G'), findsOneWidget);
    });

    testWidgets('Botão Adicionar só fica ativo após selecionar cor e tamanho', (WidgetTester tester) async {
      // 1. Preparação
      await tester.pumpWidget(createTestableWidget(
        child: ProductGridItem(id: 'prod-123', data: mockProductData, onEdit: () {}),
      ));

      // Verificação Inicial: O seletor de quantidade e o botão não devem estar visíveis.
      expect(find.text('Adicionar'), findsNothing);
      expect(find.byIcon(Icons.remove), findsNothing);

      // 2. Ação: Seleciona um tamanho
      await tester.tap(find.text('P'));
      await tester.pumpAndSettle();

      // 3. Verificação: Agora o seletor de quantidade e o botão devem estar visíveis.
      expect(find.text('Adicionar'), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);

      // Verifica se o botão está ativo.
      final ElevatedButton button = tester.widget(find.widgetWithText(ElevatedButton, 'Adicionar'));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('Adicionar ao carrinho deve limpar a seleção de tamanho', (WidgetTester tester) async {
      // Limpa o carrinho global antes de cada teste que o utiliza.
      cartManager.clearCart();

      // 1. Preparação
      await tester.pumpWidget(createTestableWidget(
        child: ProductGridItem(id: 'prod-123', data: mockProductData, onEdit: () {}),
      ));

      // 2. Ação: Seleciona tamanho e clica em Adicionar
      await tester.tap(find.text('M'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Adicionar'));
      await tester.pumpAndSettle();

      // 3. Verificação
      // O carrinho deve ter 1 item.
      expect(cartManager.totalItems, 1);
      // O botão Adicionar deve desaparecer, pois a seleção de tamanho foi reiniciada.
      expect(find.text('Adicionar'), findsNothing);
    });
  });
}
