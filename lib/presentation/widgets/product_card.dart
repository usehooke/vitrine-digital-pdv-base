// CONTEÚDO CORRETO E COMPLETO PARA: lib/presentation/widgets/product_card.dart

import 'package:flutter/material.dart';
import '../../data/models/product_model.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    print('--- ProductCard [${product.name}] está a carregar a imagem: "${product.coverImageUrl}"');
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias, // Garante que a imagem respeita as bordas
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // A "MAGIA" ESTÁ AQUI:
            Expanded(
              // O Expanded diz: "dê todo o espaço vertical que sobrar para este widget"
              child: Image.network(
                product.coverImageUrl,
                fit: BoxFit.cover,
                // Mostra um loading enquanto a imagem carrega
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                // Mostra um ícone de erro se a imagem falhar
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Icon(Icons.error));
                },
              ),
            ),
            
            // O texto ocupa apenas o espaço de que precisa
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category,
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}