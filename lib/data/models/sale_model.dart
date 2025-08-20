// CONTEÚDO COMPLETO PARA: lib/data/models/sale_model.dart

import 'sale_item_model.dart';

class SaleModel {
  final String id;
  final DateTime saleDate;
  final String userId;
  final String userName;
  final List<SaleItemModel> items;
  final double totalAmount;
  String? geminiSummary;

  SaleModel({
    required this.id,
    required this.saleDate,
    required this.userId,
    required this.userName,
    required this.items,
    required this.totalAmount,
    this.geminiSummary,
  });

  Map<String, dynamic> toMap() {
    return {
      'saleDate': saleDate,
      'userId': userId,
      'userName': userName,
      'totalAmount': totalAmount,
      'geminiSummary': geminiSummary ?? '',
      'items': items.map((item) => item.toMap()).toList(),
    };
  }
}