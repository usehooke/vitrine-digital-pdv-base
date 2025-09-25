import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../models/sale_model.dart';
import '../models/variant_model.dart';
import '../models/sku_model.dart';

class ProductRepository {
  final FirebaseFirestore _firestore;
  ProductRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream de produtos com variantes e SKUs carregados a partir de subcoleções.
  Stream<List<ProductModel>> getProductsStream() async* {
    final productsRef = _firestore.collection('products');
    await for (final snap in productsRef.snapshots()) {
      final List<ProductModel> products = await Future.wait(snap.docs.map((doc) async {
        final data = doc.data();
        try {
          final variantsSnap = await doc.reference.collection('variants').get();
          final variants = await Future.wait(variantsSnap.docs.map((vDoc) async {
            final skusSnap = await vDoc.reference.collection('skus').limit(1).get();
            final skus = skusSnap.docs.map((s) => SkuModel.fromFirestore(s.data(), s.id)).toList();
            return VariantModel(
              id: vDoc.id,
              color: (vDoc.data()['color'] ?? '').toString(),
              imageUrl: (vDoc.data()['imageUrl'] ?? '').toString(),
              skus: skus,
            );
          }).toList());
          return ProductModel(
            id: doc.id,
            name: (data['name'] ?? '').toString(),
            model: (data['model'] ?? '').toString(),
            category: (data['category'] ?? '').toString(),
            mainImageUrl: (data['mainImageUrl'] ?? '').toString(),
            variants: variants,
          );
        } catch (e) {
          // Em caso de erro ao ler subcoleções, devolve produto sem variantes para evitar crash da stream
          return ProductModel(
            id: doc.id,
            name: (data['name'] ?? '').toString(),
            model: (data['model'] ?? '').toString(),
            category: (data['category'] ?? '').toString(),
            mainImageUrl: (data['mainImageUrl'] ?? '').toString(),
            variants: const [],
          );
        }
      }).toList());
      yield products;
    }
  }

  /// Stream de variantes (cada variante incluindo seus SKUs).
  Stream<List<VariantModel>> getVariantsStream(String productId) async* {
    final variantsRef = _firestore.collection('products').doc(productId).collection('variants');
    await for (final snap in variantsRef.snapshots()) {
      final variants = await Future.wait(snap.docs.map((vDoc) async {
        final skusSnap = await vDoc.reference.collection('skus').get();
        final skus = skusSnap.docs.map((s) => SkuModel.fromFirestore(s.data(), s.id)).toList();
        return VariantModel(
          id: vDoc.id,
          color: (vDoc.data()['color'] ?? '').toString(),
          imageUrl: (vDoc.data()['imageUrl'] ?? '').toString(),
          skus: skus,
        );
      }).toList());
      yield variants;
    }
  }

  /// Stream de SKUs para uma variante específica.
  Stream<List<SkuModel>> getSkusStream(String productId, String variantId) {
    final skusRef = _firestore
        .collection('products')
        .doc(productId)
        .collection('variants')
        .doc(variantId)
        .collection('skus');
    return skusRef.snapshots().map((snap) => snap.docs.map((d) => SkuModel.fromFirestore(d.data(), d.id)).toList());
  }

  /// Retorna um produto único com variantes e skus populados.
  Future<ProductModel> getProduct(String productId) async {
    final docSnapshot = await _firestore.collection('products').doc(productId).get();
    final data = docSnapshot.data() ?? <String, dynamic>{};
    final variantsSnap = await docSnapshot.reference.collection('variants').get();
    final variants = await Future.wait(variantsSnap.docs.map((vDoc) async {
      final skusSnap = await vDoc.reference.collection('skus').get();
      final skus = skusSnap.docs.map((s) => SkuModel.fromFirestore(s.data(), s.id)).toList();
      return VariantModel(
        id: vDoc.id,
        color: (vDoc.data()['color'] ?? '').toString(),
        imageUrl: (vDoc.data()['imageUrl'] ?? '').toString(),
        skus: skus,
      );
    }).toList());
    return ProductModel(
      id: docSnapshot.id,
      name: (data['name'] ?? '').toString(),
      model: (data['model'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      mainImageUrl: (data['mainImageUrl'] ?? '').toString(),
      variants: variants,
    );
  }

  Future<String> uploadImage(XFile imageFile, String productId) async {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
    try {
      final fileName = '${productId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref('product_images').child(fileName);
      if (kIsWeb) {
        final imageData = await imageFile.readAsBytes();
        final uploadTask = ref.putData(imageData, SettableMetadata(contentType: 'image/jpeg'));
        final snapshot = await uploadTask.whenComplete(() => {});
        return await snapshot.ref.getDownloadURL();
      } else {
        final uploadTask = ref.putFile(File(imageFile.path));
        final snapshot = await uploadTask.whenComplete(() => {});
        return await snapshot.ref.getDownloadURL();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addNewProduct({
    required Map<String, dynamic> productData,
    required List<Map<String, dynamic>> variantsData,
  }) async {
    final batch = _firestore.batch();
    final productRef = _firestore.collection('products').doc();
    batch.set(productRef, productData);
    for (var variantMap in variantsData) {
      final List<Map<String, dynamic>> skusData = List<Map<String, dynamic>>.from(variantMap.remove('skus') ?? []);
      final variantRef = productRef.collection('variants').doc();
      batch.set(variantRef, variantMap);
      for (var skuMap in skusData) {
        final skuRef = variantRef.collection('skus').doc();

        // If there's a generated SKU code, create a QR image (PNG) and upload it to Storage
        // then include the `qrImageUrl` in the SKU document before committing the batch.
        try {
          final generated = (skuMap['generatedSku'] ?? '').toString();
          if (generated.isNotEmpty) {
            // Ensure we have an auth user for Storage (mirrors uploadImage behaviour)
            if (FirebaseAuth.instance.currentUser == null) {
              await FirebaseAuth.instance.signInAnonymously();
            }

            // Generate QR PNG bytes locally (cross-platform) using QrPainter
            final pngBytes = await _generateQrPngBytes(generated);

            final fileName = '${productRef.id}_${variantRef.id}_${skuRef.id}.png';
            final storageRef = FirebaseStorage.instance.ref('product_qr_images').child(fileName);
            final uploadTask = storageRef.putData(pngBytes, SettableMetadata(contentType: 'image/png'));
            final snapshot = await uploadTask.whenComplete(() => {});
            final url = await snapshot.ref.getDownloadURL();
            skuMap['qrImageUrl'] = url;
          }
        } catch (e) {
          debugPrint('### ERRO ao gerar/upload QR para SKU: $e');
          // Não interromper a criação do produto por causa de falha no upload do QR.
        }

        batch.set(skuRef, skuMap);
      }
    }
    await batch.commit();
  }

  Future<Uint8List> _generateQrPngBytes(String data, {int size = 800}) async {
    // Use QrPainter to render QR to raw PNG bytes. Works on web and mobile.
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
    );
    final picData = await painter.toImageData(size.toDouble());
    if (picData == null) throw Exception('Failed to render QR image');
    return picData.buffer.asUint8List();
  }

  Future<void> deleteImage(String imageUrl) async {
    if (imageUrl.isEmpty) return;
    try {
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Falha ao apagar imagem não é crítico — apenas loggar.
      debugPrint('### ERRO ao apagar imagem (pode ser ignorado): $e');
    }
  }

  Future<void> updateProduct({
    required String productId,
    required Map<String, dynamic> productData,
    required List<Map<String, dynamic>> variantsData,
  }) async {
    final batch = _firestore.batch();
    final productRef = _firestore.collection('products').doc(productId);
    final oldVariants = await productRef.collection('variants').get();
    for (final variantDoc in oldVariants.docs) {
      final oldSkus = await variantDoc.reference.collection('skus').get();
      for (final skuDoc in oldSkus.docs) {
        batch.delete(skuDoc.reference);
      }
      batch.delete(variantDoc.reference);
    }
    batch.update(productRef, productData);
    for (var variantMap in variantsData) {
      final List<Map<String, dynamic>> skusData = List<Map<String, dynamic>>.from(variantMap.remove('skus') ?? []);
      final variantRef = productRef.collection('variants').doc();
      batch.set(variantRef, variantMap);
      for (var skuMap in skusData) {
        final skuRef = variantRef.collection('skus').doc();
        batch.set(skuRef, skuMap);
      }
    }
    await batch.commit();
  }

  Future<void> deleteProduct(String productId) async {
    final productRef = _firestore.collection('products').doc(productId);
    final variantsSnapshot = await productRef.collection('variants').get();
    for (final variantDoc in variantsSnapshot.docs) {
      final imageUrl = variantDoc.data()['imageUrl'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await deleteImage(imageUrl);
      }
    }
    final batch = _firestore.batch();
    for (final variantDoc in variantsSnapshot.docs) {
      final skusSnapshot = await variantDoc.reference.collection('skus').get();
      for (final skuDoc in skusSnapshot.docs) {
        batch.delete(skuDoc.reference);
      }
      batch.delete(variantDoc.reference);
    }
    batch.delete(productRef);
    await batch.commit();
  }

  Future<void> processSale(SaleModel sale) async {
    return _firestore.runTransaction((transaction) async {
      for (final item in sale.items) {
        final skuRef = _firestore
            .collection('products')
            .doc(item.productId)
            .collection('variants')
            .doc(item.variantId)
            .collection('skus')
            .doc(item.skuId);
        final skuDoc = await transaction.get(skuRef);
        if (!skuDoc.exists) throw Exception('SKU ${item.generatedSku} não encontrado!');
        final currentStock = (skuDoc.data()!['stock'] as num).toInt();
        if (currentStock < item.quantity) throw Exception('Estoque insuficiente para ${item.generatedSku}. Disponível: $currentStock');
        final newStock = currentStock - item.quantity;
        transaction.update(skuRef, {'stock': newStock});
      }
      final saleRef = _firestore.collection('sales').doc(sale.id);
      transaction.set(saleRef, sale.toMap());
    });
  }

  /// Atualiza uma venda existente com o resumo gerado pela IA.
  Future<void> updateSaleSummary({required String saleId, required String summary}) async {
    try {
      await _firestore.collection('sales').doc(saleId).update({'geminiSummary': summary});
    } catch (e) {
      debugPrint('### ERRO ao atualizar o resumo da venda no Firestore: $e');
      rethrow;
    }
  }

  /// Procura um SKU pelo campo `generatedSku` nas subcoleções.
  /// Retorna um mapa com `productId`, `variantId`, `skuId` se encontrado, ou null.
  Future<Map<String, String>?> findSkuIndexByGeneratedCode(String generatedCode) async {
    final productsSnap = await _firestore.collection('products').get();
    for (final p in productsSnap.docs) {
      final variantsSnap = await p.reference.collection('variants').get();
      for (final v in variantsSnap.docs) {
        final skusSnap = await v.reference.collection('skus').get();
        for (final s in skusSnap.docs) {
          final data = s.data();
          if ((data['generatedSku'] ?? '') == generatedCode) {
            return {
              'productId': p.id,
              'variantId': v.id,
              'skuId': s.id,
            };
          }
        }
      }
    }
    return null;
  }

  /// Carrega um SKU específico sob demanda.
  Future<SkuModel> getSkuOnDemand(String productId, String variantId, String skuId) async {
    final doc = await _firestore
        .collection('products')
        .doc(productId)
        .collection('variants')
        .doc(variantId)
        .collection('skus')
        .doc(skuId)
        .get();
    if (!doc.exists) throw Exception('SKU não encontrado');
    return SkuModel.fromFirestore(doc.data()!, doc.id);
  }
}