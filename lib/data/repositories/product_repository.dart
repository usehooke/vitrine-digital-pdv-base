// CONTEÚDO COMPLETO E ATUALIZADO PARA: lib/data/repositories/product_repository.dart

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  ProductRepository(this._firestore);

  Stream<List<ProductModel>> getProductsStream() {
    return _firestore.collection('products').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Stream<List<VariantModel>> getVariantsStream(String productId) {
    return _firestore.collection('products').doc(productId).collection('variants').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => VariantModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Stream<List<SkuModel>> getSkusStream(String productId, String variantId) {
    return _firestore.collection('products').doc(productId).collection('variants').doc(variantId).collection('skus').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => SkuModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<ProductModel> getProduct(String productId) async {
    final docSnapshot =
        await _firestore.collection('products').doc(productId).get();
    return ProductModel.fromFirestore(docSnapshot.data()!, docSnapshot.id);
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
    } catch (e) { rethrow; }
  }

  Future<void> addNewProduct({ required Map<String, dynamic> productData, required List<Map<String, dynamic>> variantsData }) async {
    final batch = _firestore.batch();
    final productRef = _firestore.collection('products').doc();
    batch.set(productRef, productData);
    for (var variantMap in variantsData) {
      final List<Map<String, dynamic>> skusData = variantMap.remove('skus');
      final variantRef = productRef.collection('variants').doc();
      batch.set(variantRef, variantMap);
      for (var skuMap in skusData) {
        final skuRef = variantRef.collection('skus').doc();
        batch.set(skuRef, skuMap);
      }
    }
    await batch.commit();
  }

  Future<void> deleteImage(String imageUrl) async {
    if (imageUrl.isEmpty) return;
    try {
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) { print('### ERRO ao apagar imagem (pode ser ignorado): $e'); }
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
      final List<Map<String, dynamic>> skusData = variantMap.remove('skus');
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
            .collection('products').doc(item.productId)
            .collection('variants').doc(item.variantId)
            .collection('skus').doc(item.skuId);
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

  // ------------------- NOVO MÉTODO ADICIONADO AQUI ------------------- //
  
  /// Atualiza uma venda existente com o resumo gerado pela IA.
  ///
  /// Este método é chamado pelo PdvController depois que o resumo do Gemini
  /// foi gerado com sucesso.
  Future<void> updateSaleSummary({required String saleId, required String summary}) async {
    try {
      await _firestore
          .collection('sales')
          .doc(saleId)
          .update({'geminiSummary': summary});
    } catch (e) {
      // Imprime o erro no console para fins de depuração.
      print('### ERRO ao atualizar o resumo da venda no Firestore: $e');
      // Propaga o erro para que a camada que chamou (Controller) possa tratá-lo se necessário.
      rethrow;
    }
  }
}