import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

class DashboardDialog extends StatelessWidget {
  const DashboardDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // Streams dos dados do Firebase
    final Stream<QuerySnapshot> salesStream =
        FirebaseFirestore.instance.collection('vendas').snapshots();

    final Stream<QuerySnapshot> productsStream =
        FirebaseFirestore.instance.collection('produtos').snapshots();

    // Stream combinada com Rx.combineLatest2
    final Stream<List<QuerySnapshot>> combinedStream = Rx.combineLatest2(
      salesStream,
      productsStream,
      (QuerySnapshot sales, QuerySnapshot products) => [sales, products],
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: const Color(0xFF1e293b),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: StreamBuilder<List<QuerySnapshot>>(
          stream: combinedStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final sales = snapshot.data![0];
            final products = snapshot.data![1];

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📊 Painel de Métricas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '🛍 Total de vendas: ${sales.docs.length}',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  '📦 Total de produtos cadastrados: ${products.docs.length}',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 24),
                const Text(
                  '📋 Produtos:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                ...products.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nome = data['nome'] ?? 'sem nome';
                  final categoria = data['categoria'] ?? 'sem categoria';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      '- $nome (${categoria})',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}