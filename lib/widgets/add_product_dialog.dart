import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/product_variants.dart';
import 'qr_code_dialog.dart';

// Classe interna para gerir os controladores de cada variante de cor no formulário.
class _ColorVariantController {
  final TextEditingController corController;
  String? existingImageUrl;
  XFile? newImageFile;

  _ColorVariantController({String cor = '', this.existingImageUrl})
      : corController = TextEditingController(text: cor);
  
  void dispose() {
    corController.dispose();
  }
}

// Classe interna para gerir os controladores de cada variante de SKU na Etapa 3.
class _SkuVariantController {
  final String cor;
  final String tamanho;
  final String sku;
  final TextEditingController precoVarejoController;
  final TextEditingController precoAtacadoController;
  final TextEditingController estoqueController;

  _SkuVariantController({
    required this.cor,
    required this.tamanho,
    required this.sku,
    required double precoVarejo,
    required double precoAtacado,
    required int estoque,
  }) : precoVarejoController = TextEditingController(text: precoVarejo.toString()),
       precoAtacadoController = TextEditingController(text: precoAtacado.toString()),
       estoqueController = TextEditingController(text: estoque.toString());

  void dispose() {
    precoVarejoController.dispose();
    precoAtacadoController.dispose();
    estoqueController.dispose();
  }
}

class AddProductDialog extends StatefulWidget {
  final String? documentId;
  final Map<String, dynamic>? initialData;

  const AddProductDialog({super.key, this.documentId, this.initialData});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _pageController = PageController();
  final _formKeyStep1 = GlobalKey<FormState>();

  final _categoriaController = TextEditingController();
  final _nomeController = TextEditingController();
  final _modeloController = TextEditingController();
  
  List<_ColorVariantController> _colorVariants = [_ColorVariantController()];
  
  final List<String> _todosOsTamanhos = ['P', 'M', 'G', 'GG', 'EXG'];
  final Set<String> _tamanhosSelecionados = {};
  
  List<_SkuVariantController> _generatedVariantControllers = [];

  final _bulkPrecoVarejoController = TextEditingController();
  final _bulkPrecoAtacadoController = TextEditingController();
  final _bulkEstoqueController = TextEditingController();
  final _bulkEstoqueMinimoController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.documentId != null && widget.initialData != null) {
      _populateFormForEditing();
    }
  }

  void _populateFormForEditing() {
      final data = widget.initialData!;
      _categoriaController.text = data['categoria'] ?? '';
      
      String fullName = data['nome'] ?? '';
      List<String> nameParts = fullName.split(' ');
      if (nameParts.length > 1) {
        _modeloController.text = nameParts.first;
        _nomeController.text = nameParts.sublist(1).join(' ');
      } else {
        _nomeController.text = fullName;
      }

      final cores = data['cores'] as Map<String, dynamic>? ?? {};
      if (cores.isNotEmpty) {
        _colorVariants = cores.entries.map((entry) {
          return _ColorVariantController(
            cor: entry.key,
            existingImageUrl: entry.value['imagem'],
          );
        }).toList();
      }
      
      final skus = data['skus'] as Map<String, dynamic>? ?? {};
      if (skus.isNotEmpty) {
        skus.values.forEach((skuData) {
          _tamanhosSelecionados.add(skuData['tamanho']);
        });
        _bulkEstoqueMinimoController.text = (skus.values.first['estoque_minimo'] ?? 2).toString();
      }
  }

  Future<void> _pickImage(int index) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _colorVariants[index].newImageFile = image;
      });
    }
  }

  Future<String> _uploadImage(XFile imageFile, String sku) async {
    final storageRef = FirebaseStorage.instance.ref();
    final imageRef = storageRef.child('product_images/$sku-${DateTime.now().millisecondsSinceEpoch}');
    
    if (kIsWeb) {
      final bytes = await imageFile.readAsBytes();
      await imageRef.putData(bytes);
    } else {
      await imageRef.putFile(File(imageFile.path));
    }
    
    return await imageRef.getDownloadURL();
  }

  void _generateVariants() {
    final cores = _colorVariants.where((v) => v.corController.text.trim().isNotEmpty).toList();
    if (cores.isEmpty || _tamanhosSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adicione pelo menos uma cor e um tamanho.'), backgroundColor: Colors.orange));
      return;
    }

    final modeloSanitized = _modeloController.text.toUpperCase().replaceAll(' ', '-');
    final nomeSanitized = _nomeController.text.toUpperCase().replaceAll(' ', '-');

    List<_SkuVariantController> variants = [];
    for (var colorController in cores) {
      for (var tamanho in _tamanhosSelecionados) {
        final corSanitized = colorController.corController.text.trim().toUpperCase().replaceAll(' ', '-');
        final skuId = '$modeloSanitized-$nomeSanitized-$corSanitized-$tamanho';

        final existingSkuData = widget.initialData?['skus']?[skuId];

        variants.add(
          _SkuVariantController(
            cor: colorController.corController.text.trim(),
            tamanho: tamanho,
            sku: skuId,
            precoVarejo: (existingSkuData?['preco_varejo'] ?? 0.0).toDouble(),
            precoAtacado: (existingSkuData?['preco_atacado'] ?? 0.0).toDouble(),
            estoque: (existingSkuData?['estoque'] ?? 0),
          )
        );
      }
    }
    setState(() {
      _generatedVariantControllers = variants;
    });
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
  }

  void _applyToAll() {
    for (var variantController in _generatedVariantControllers) {
      variantController.precoVarejoController.text = _bulkPrecoVarejoController.text;
      variantController.precoAtacadoController.text = _bulkPrecoAtacadoController.text;
      variantController.estoqueController.text = _bulkEstoqueController.text;
    }
    setState(() {});
  }

  Future<void> _saveProduct() async {
    setState(() { _isLoading = true; });

    final Map<String, dynamic> coresMap = {};
    for (var colorCtrl in _colorVariants) {
      if (colorCtrl.corController.text.isNotEmpty) {
        String imageUrl = colorCtrl.existingImageUrl ?? '';
        if (colorCtrl.newImageFile != null) {
          imageUrl = await _uploadImage(colorCtrl.newImageFile!, colorCtrl.corController.text);
        }
        coresMap[colorCtrl.corController.text] = {'imagem': imageUrl};
      }
    }

    Map<String, dynamic> skusToSave = {};
    for (var variantController in _generatedVariantControllers) {
      skusToSave[variantController.sku] = {
        'sku': variantController.sku,
        'cor': variantController.cor,
        'tamanho': variantController.tamanho,
        'preco_varejo': double.tryParse(variantController.precoVarejoController.text) ?? 0.0,
        'preco_atacado': double.tryParse(variantController.precoAtacadoController.text) ?? 0.0,
        'estoque': int.tryParse(variantController.estoqueController.text) ?? 0,
        'estoque_minimo': int.tryParse(_bulkEstoqueMinimoController.text) ?? 2,
      };
    }
    
    final productData = {
      'categoria': _categoriaController.text,
      'nome': '${_modeloController.text} ${_nomeController.text}',
      'imagem_principal': coresMap.isNotEmpty ? coresMap.values.first['imagem'] : '',
      'cores': coresMap,
      'skus': skusToSave,
      'createdAt': widget.documentId != null ? widget.initialData!['createdAt'] : FieldValue.serverTimestamp(),
    };

    try {
      final collection = FirebaseFirestore.instance.collection('artifacts/hooke-loja-pdv-d2e5c/public/data/produtos');
      if (widget.documentId != null) {
        await collection.doc(widget.documentId).set(productData);
      } else {
        await collection.add(productData);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Produto ${widget.documentId != null ? 'atualizado' : 'salvo'} com sucesso!'), backgroundColor: Colors.green));
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar produto: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _categoriaController.dispose();
    _nomeController.dispose();
    _modeloController.dispose();
    _bulkPrecoVarejoController.dispose();
    _bulkPrecoAtacadoController.dispose();
    _bulkEstoqueController.dispose();
    _bulkEstoqueMinimoController.dispose();
    for (var controller in _colorVariants) {
      controller.dispose();
    }
    for (var controller in _generatedVariantControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.documentId != null;
    return AlertDialog(
      backgroundColor: const Color(0xFF1e293b),
      title: Text(isEditing ? 'Editar Produto' : 'Adicionar Novo Produto'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStep1(),
            _buildStep2(),
            _buildStep3(),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      child: Form(
        key: _formKeyStep1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Etapa 1 de 3: Informações do Produto", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            TextFormField(controller: _categoriaController, decoration: const InputDecoration(labelText: 'Categoria'), validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _nomeController, decoration: const InputDecoration(labelText: 'Nome do Produto (ex: Fusca, Kombi)'), validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _modeloController, decoration: const InputDecoration(labelText: 'Modelo (ex: Manga Curta, Regata)'), validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_formKeyStep1.currentState!.validate()) {
                      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
                    }
                  },
                  child: const Text('Próximo'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Etapa 2 de 3: Variações (Cores e Tamanhos)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const Divider(height: 24),
        
        Expanded(
          child: ListView.builder(
            itemCount: _colorVariants.length,
            itemBuilder: (context, index) {
              final colorCtrl = _colorVariants[index];
              return Card(
                color: const Color(0xFF0f172a),
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(child: TextFormField(controller: colorCtrl.corController, decoration: const InputDecoration(labelText: 'Cor'))),
                      const SizedBox(width: 8),
                      // Seletor de Imagem
                      GestureDetector(
                        onTap: () => _pickImage(index),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: colorCtrl.newImageFile != null
                              ? (kIsWeb
                                  ? Image.network(colorCtrl.newImageFile!.path, fit: BoxFit.cover)
                                  : Image.file(File(colorCtrl.newImageFile!.path), fit: BoxFit.cover))
                              : (colorCtrl.existingImageUrl != null && colorCtrl.existingImageUrl!.isNotEmpty
                                  ? Image.network(colorCtrl.existingImageUrl!, fit: BoxFit.cover)
                                  : const Icon(Icons.add_a_photo)),
                        ),
                      ),
                      if (_colorVariants.length > 1)
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _colorVariants.removeAt(index))),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        TextButton.icon(onPressed: () => setState(() => _colorVariants.add(_ColorVariantController())), icon: const Icon(Icons.add), label: const Text('Adicionar Cor')),
        
        const Divider(height: 24),
        const Text('Selecione os Tamanhos', style: TextStyle(color: Colors.grey)),
        Wrap(
          spacing: 8.0,
          children: _todosOsTamanhos.map((tamanho) {
            final isSelected = _tamanhosSelecionados.contains(tamanho);
            return ChoiceChip(
              label: Text(tamanho),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) { _tamanhosSelecionados.add(tamanho); } else { _tamanhosSelecionados.remove(tamanho); }
                });
              },
              selectedColor: const Color(0xFF0ea5e9),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn), child: const Text('Voltar')),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _generateVariants,
              child: const Text('Gerar Variações'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Etapa 3 de 3: Preços e Estoques", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const Divider(height: 24),
        
        Card(
          color: const Color(0xFF0f172a),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: TextFormField(controller: _bulkPrecoVarejoController, decoration: const InputDecoration(labelText: 'Varejo Padrão'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: TextFormField(controller: _bulkPrecoAtacadoController, decoration: const InputDecoration(labelText: 'Atacado Padrão'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: TextFormField(controller: _bulkEstoqueController, decoration: const InputDecoration(labelText: 'Estoque Padrão'), keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(controller: _bulkEstoqueMinimoController, decoration: const InputDecoration(labelText: 'Estoque Mínimo Padrão'), keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: _applyToAll, child: const Text('Aplicar a Todos')),
              ],
            ),
          ),
        ),
        const Divider(height: 24),

        Expanded(
          child: _generatedVariantControllers.isEmpty
              ? const Center(child: Text('As variações aparecerão aqui.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: _generatedVariantControllers.length,
                  itemBuilder: (context, index) {
                    final variantController = _generatedVariantControllers[index];
                    return Card(
                      color: const Color(0xFF0f172a),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: Text(variantController.sku, style: const TextStyle(fontSize: 12))),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: variantController.precoVarejoController,
                                decoration: const InputDecoration(labelText: 'Varejo', contentPadding: EdgeInsets.all(8)),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                             Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: variantController.precoAtacadoController,
                                decoration: const InputDecoration(labelText: 'Atacado', contentPadding: EdgeInsets.all(8)),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: variantController.estoqueController,
                                decoration: const InputDecoration(labelText: 'Estoque', contentPadding: EdgeInsets.all(8)),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.qr_code_2),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => QrCodePrintDialog(
                                    productName: '${_modeloController.text} ${_nomeController.text}',
                                    sku: variantController.sku,
                                  ),
                                );
                              },
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn), child: const Text('Voltar')),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isLoading || _generatedVariantControllers.isEmpty ? null : _saveProduct,
              child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(widget.documentId != null ? 'Salvar Alterações' : 'Salvar Produto'),
            ),
          ],
        ),
      ],
    );
  }
}
