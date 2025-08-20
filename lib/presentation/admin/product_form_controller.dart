// CONTEÚDO COMPLETO PARA: lib/presentation/admin/product_form_controller.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/sku_model.dart';
import '../../data/models/variant_model.dart';
import '../../data/repositories/product_repository.dart';

class SkuFormState {
  final TextEditingController sizeController = TextEditingController();
  final TextEditingController retailPriceController = TextEditingController();
  final TextEditingController wholesalePriceController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  String generatedSku = '';
}

class VariantFormState {
  final TextEditingController colorController = TextEditingController();
  XFile? imageFile;
  String? imageUrl;
  List<SkuFormState> skus = [];
}

class ProductFormController extends ChangeNotifier {
  final ProductRepository _productRepository;
  final String? productId;
  bool get isEditMode => productId != null;

  ProductFormController(this._productRepository, {this.productId}) {
    categoryController.addListener(_updateAllSkus);
    nameController.addListener(_updateAllSkus);
    modelController.addListener(_updateAllSkus);
    batchRetailPriceController.addListener(_applyBatchRetailPrice);
    batchWholesalePriceController.addListener(_applyBatchWholesalePrice);
    batchStockController.addListener(_applyBatchStock);
    if (isEditMode) {
      loadProductForEdit();
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _isSaving = false;
  bool get isSaving => _isSaving;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final TextEditingController categoryController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController modelController = TextEditingController();
  final TextEditingController batchRetailPriceController = TextEditingController();
  final TextEditingController batchWholesalePriceController = TextEditingController();
  final TextEditingController batchStockController = TextEditingController();

  List<VariantFormState> variants = [];
  int _currentStep = 0;
  int get currentStep => _currentStep;
  List<SkuFormState> get allSkus => variants.expand((v) => v.skus).toList();

  Future<void> loadProductForEdit() async {
    _isLoading = true;
    notifyListeners();
    try {
      final product = await _productRepository.getProduct(productId!);
      categoryController.text = product.category;
      nameController.text = product.name;
      modelController.text = product.model;

      final variantList = await _productRepository.getVariantsStream(productId!).first;
      for (var variantModel in variantList) {
        final variantState = VariantFormState();
        variantState.colorController.text = variantModel.color;
        variantState.imageUrl = variantModel.imageUrl;
        final skuList = await _productRepository.getSkusStream(productId!, variantModel.id).first;
        for (var skuModel in skuList) {
          final skuState = SkuFormState();
          skuState.sizeController.text = skuModel.size;
          skuState.retailPriceController.text = skuModel.retailPrice.toString();
          skuState.wholesalePriceController.text = skuModel.wholesalePrice.toString();
          skuState.stockController.text = skuModel.stock.toString();
          variantState.skus.add(skuState);
        }
        variants.add(variantState);
      }
      _updateAllSkus();
    } catch (e) {
      _errorMessage = 'Erro ao carregar o produto para edição.';
      print('### ERRO AO CARREGAR PRODUTO: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveProduct() async {
    _isSaving = true;
    notifyListeners();
    try {
      List<Map<String, dynamic>> variantsData = [];
      for (var variantState in variants) {
        String imageUrl = variantState.imageUrl ?? '';
        if (variantState.imageFile != null) {
          if (isEditMode && imageUrl.isNotEmpty) {
            await _productRepository.deleteImage(imageUrl);
          }
          imageUrl = await _productRepository.uploadImage(variantState.imageFile!, productId ?? DateTime.now().millisecondsSinceEpoch.toString());
        }
        List<Map<String, dynamic>> skusData = [];
        for (var skuState in variantState.skus) {
          skusData.add({
            'size': skuState.sizeController.text, 'sku': skuState.generatedSku,
            'retailPrice': double.tryParse(skuState.retailPriceController.text) ?? 0.0,
            'wholesalePrice': double.tryParse(skuState.wholesalePriceController.text) ?? 0.0,
            'stock': int.tryParse(skuState.stockController.text) ?? 0,
          });
        }
        variantsData.add({'color': variantState.colorController.text, 'imageUrl': imageUrl, 'skus': skusData});
      }
      final productData = {
        'category': categoryController.text, 'name': nameController.text, 'model': modelController.text, 'isActive': true,
        'coverImageUrl': variantsData.isNotEmpty ? variantsData.first['imageUrl'] : '',
      };
      if (isEditMode) {
        await _productRepository.updateProduct(productId: productId!, productData: productData, variantsData: variantsData);
      } else {
        await _productRepository.addNewProduct(productData: productData, variantsData: variantsData);
      }
      return true;
    } catch (e) {
      print('### ERRO AO SALVAR PRODUTO: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
  
  void onStepContinue(BuildContext context) async {
    if (_currentStep < 2) {
      _currentStep += 1;
      notifyListeners();
    } else {
      final success = await saveProduct();
      if (success && context.mounted) {
        GoRouter.of(context).go('/home');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isEditMode ? 'Produto atualizado com sucesso!' : 'Produto salvo com sucesso!'),
          backgroundColor: Colors.green,
        ));
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erro ao salvar o produto.'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }
  
  void onStepCancel() { if (_currentStep > 0) { _currentStep -= 1; notifyListeners(); } }
  void _applyBatchRetailPrice() { for (var sku in allSkus) { sku.retailPriceController.text = batchRetailPriceController.text; } }
  void _applyBatchWholesalePrice() { for (var sku in allSkus) { sku.wholesalePriceController.text = batchWholesalePriceController.text; } }
  void _applyBatchStock() { for (var sku in allSkus) { sku.stockController.text = batchStockController.text; } }
  void addVariant() { final newVariant = VariantFormState(); newVariant.colorController.addListener(_updateAllSkus); variants.add(newVariant); notifyListeners(); }
  void removeVariant(int index) { variants[index].colorController.dispose(); for (var sku in variants[index].skus) { sku.sizeController.dispose(); } variants.removeAt(index); notifyListeners(); }
  void addSkuToVariant(VariantFormState variant) { final newSku = SkuFormState(); newSku.sizeController.addListener(() => _updateSku(variant, newSku)); variant.skus.add(newSku); _updateSku(variant, newSku); notifyListeners(); }
  void removeSkuFromVariant(VariantFormState variant, int skuIndex) { variant.skus[skuIndex].sizeController.dispose(); variant.skus.removeAt(skuIndex); notifyListeners(); }
  void _updateAllSkus() { for (var variant in variants) { for (var sku in variant.skus) { _updateSku(variant, sku); } } notifyListeners(); }
  void _updateSku(VariantFormState variant, SkuFormState sku) { String safeSubstring(String text, int len) { if (text.isEmpty) return ''; return text.length > len ? text.substring(0, len) : text; } final category = safeSubstring(categoryController.text.trim().toUpperCase(), 3); final name = safeSubstring(nameController.text.replaceAll(' ', '').trim().toUpperCase(), 4); final model = safeSubstring(modelController.text.replaceAll(' ', '').trim().toUpperCase(), 2); final color = safeSubstring(variant.colorController.text.replaceAll(' ', '').trim().toUpperCase(), 2); final size = sku.sizeController.text.trim().toUpperCase(); sku.generatedSku = '$category-$name-$model-$color-$size'; notifyListeners(); }
  Future<void> pickImage(VariantFormState variant) async { final ImagePicker picker = ImagePicker(); final XFile? image = await picker.pickImage(source: ImageSource.gallery); if (image != null) { variant.imageFile = image; notifyListeners(); } }

  @override
  void dispose() {
    categoryController.removeListener(_updateAllSkus); nameController.removeListener(_updateAllSkus); modelController.removeListener(_updateAllSkus);
    categoryController.dispose(); nameController.dispose(); modelController.dispose();
    batchRetailPriceController.removeListener(_applyBatchRetailPrice); batchWholesalePriceController.removeListener(_applyBatchWholesalePrice); batchStockController.removeListener(_applyBatchStock);
    batchRetailPriceController.dispose(); batchWholesalePriceController.dispose(); batchStockController.dispose();
    for (var variant in variants) {
      variant.colorController.removeListener(_updateAllSkus);
      variant.colorController.dispose();
      for (var sku in variant.skus) {
        sku.sizeController.dispose(); sku.retailPriceController.dispose(); sku.wholesalePriceController.dispose(); sku.stockController.dispose();
      }
    }
    super.dispose();
  }
}