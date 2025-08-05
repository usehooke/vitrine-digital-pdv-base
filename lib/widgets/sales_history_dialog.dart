import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SalesHistoryDialog extends StatelessWidget {
  const SalesHistoryDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> salesStream = FirebaseFirestore.instance
        .collection('artifacts/hooke-loja-pdv-d2e5c/public/data/vendas')
        .orderBy('data', descending: true)
        .snapshots();

    return AlertDialog(
      backgroundColor: const Color(0xFF1e293b),
      title: const Text('Histórico de Vendas'),
      content: SizedBox(
        width: 600,
        height: 500,
        child: StreamBuilder<QuerySnapshot>(
          stream: salesStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Erro ao carregar o histórico.'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('Nenhuma venda registada.'));
            }

            return ListView(
              children: snapshot.data!.docs.map((doc) {
                final saleData = doc.data() as Map<String, dynamic>;
                final Timestamp timestamp = saleData['data'] ?? Timestamp.now();
                final String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text('Venda - $formattedDate'),
                    subtitle: Text('${saleData['total_items']} peças - ${saleData['metodo_pagamento']}'),
                    trailing: Text('R\$ ${(saleData['total'] as double).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar')),
      ],
    );
  }
}
