import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/cart_item.dart';
import '../managers/cart_manager.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  bool _isProcessing = false;
  String? _lastCode;

  Future<void> _findAndAddProduct(String sku) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('artifacts/hooke-loja-pdv-d2e5c/public/data/produtos')
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final skus = data['skus'] as Map<String, dynamic>? ?? {};

        if (skus.containsKey(sku)) {
          final skuData = skus[sku];
          if (skuData != null && skuData['preco_varejo'] != null) {
            final item = CartItem(
              productId: doc.id,
              sku: sku,
              nome: data['nome'],
              cor: skuData['cor'],
              tamanho: skuData['tamanho'],
              categoria: data['categoria'],
              precoVarejo: skuData['preco_varejo'],
              precoAtacado: skuData['preco_atacado'],
              quantidade: 1,
            );
            cartManager.addItem(item);
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${item.nome} adicionado ao carrinho!'),
                backgroundColor: Colors.green,
              ));
            }
            return;
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('SKU não encontrado no catálogo.'),
          backgroundColor: Colors.orange,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao procurar produto: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apontar para o Código')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final code = capture.barcodes.first.rawValue;
              if (!_isProcessing && code != null && code != _lastCode) {
                _lastCode = code;
                _findAndAddProduct(code);
              }
            },
          ),
          if (_isProcessing)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}