// CONTEÚDO COMPLETO PARA: lib/presentation/admin/product_form_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/product_repository.dart';
import 'product_form_controller.dart';

class ProductFormPage extends StatelessWidget {
  final String? productId;
  const ProductFormPage({super.key, this.productId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProductFormController(
        context.read<ProductRepository>(),
        productId: this.productId,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              context.watch<ProductFormController>().isEditMode
                  ? 'Editar Produto'
                  : 'Adicionar Novo Produto'),
        ),
        body: Consumer<ProductFormController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return Stack(
              children: [
                Stepper(
                  currentStep: controller.currentStep,
                  onStepContinue: () => controller.onStepContinue(context),
                  onStepCancel: controller.onStepCancel,
                  steps: [
                    Step(
                      title: const Text('Informações Básicas'),
                      isActive: controller.currentStep >= 0,
                      state: controller.currentStep > 0 ? StepState.complete : StepState.indexed,
                      content: Column(
                        children: [
                          TextFormField(controller: controller.categoryController, decoration: const InputDecoration(labelText: 'Categoria (ex: Camiseta)')),
                          const SizedBox(height: 16),
                          TextFormField(controller: controller.nameController, decoration: const InputDecoration(labelText: 'Nome do Produto (ex: Estampa Fusca)')),
                          const SizedBox(height: 16),
                          TextFormField(controller: controller.modelController, decoration: const InputDecoration(labelText: 'Modelo (ex: Manga Curta)')),
                        ],
                      ),
                    ),
                    Step(
                      title: const Text('Variantes e SKUs'),
                      isActive: controller.currentStep >= 1,
                      state: controller.currentStep > 1 ? StepState.complete : StepState.indexed,
                      content: Column(
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: controller.variants.length,
                            itemBuilder: (context, index) {
                              final variantState = controller.variants[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(child: TextFormField(controller: variantState.colorController, decoration: const InputDecoration(labelText: 'Cor (ex: Branca)'))),
                                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => controller.removeVariant(index)),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Center(
                                        child: (variantState.imageFile == null && (variantState.imageUrl == null || variantState.imageUrl!.isEmpty))
                                            ? OutlinedButton.icon(
                                                icon: const Icon(Icons.add_a_photo),
                                                label: const Text('Selecionar Imagem'),
                                                onPressed: () => controller.pickImage(variantState),
                                              )
                                            : GestureDetector(
                                                onTap: () => controller.pickImage(variantState),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.network(
                                                    variantState.imageFile?.path ?? variantState.imageUrl!,
                                                    height: 150, width: 150, fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                      ),
                                      const Divider(height: 24),
                                      const Text('Tamanhos e SKUs', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: variantState.skus.length,
                                        itemBuilder: (context, skuIndex) {
                                          final skuState = variantState.skus[skuIndex];
                                          return Row(
                                            children: [
                                              Expanded(flex: 2, child: TextFormField(controller: skuState.sizeController, decoration: const InputDecoration(labelText: 'Tamanho'))),
                                              const SizedBox(width: 8),
                                              Expanded(flex: 5, child: InputDecorator(decoration: const InputDecoration(labelText: 'SKU Gerado', border: InputBorder.none), child: SelectableText(skuState.generatedSku))),
                                              IconButton(icon: const Icon(Icons.delete_outline, size: 20), onPressed: () => controller.removeSkuFromVariant(variantState, skuIndex)),
                                            ],
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      OutlinedButton.icon(icon: const Icon(Icons.add, size: 16), label: const Text('Adicionar Tamanho'), onPressed: () => controller.addSkuToVariant(variantState)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(icon: const Icon(Icons.add), label: const Text('Adicionar Cor/Variante'), onPressed: controller.addVariant),
                        ],
                      ),
                    ),
                    Step(
                      title: const Text('Preços e Estoque'),
                      isActive: controller.currentStep >= 2,
                      content: Column(
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Atualização em Massa', style: Theme.of(context).textTheme.titleLarge),
                                  const SizedBox(height: 8),
                                  Text('Valores preenchidos aqui serão aplicados a TODOS os SKUs abaixo.', style: Theme.of(context).textTheme.bodySmall),
                                  const SizedBox(height: 16),
                                  TextFormField(controller: controller.batchRetailPriceController, decoration: const InputDecoration(labelText: 'Preço de Varejo (Todos)'), keyboardType: TextInputType.number),
                                  const SizedBox(height: 16),
                                  TextFormField(controller: controller.batchWholesalePriceController, decoration: const InputDecoration(labelText: 'Preço de Atacado (Todos)'), keyboardType: TextInputType.number),
                                  const SizedBox(height: 16),
                                  TextFormField(controller: controller.batchStockController, decoration: const InputDecoration(labelText: 'Estoque (Todos)'), keyboardType: TextInputType.number),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 32),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: controller.allSkus.length,
                            itemBuilder: (context, index) {
                              final skuState = controller.allSkus[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(skuState.generatedSku, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      TextFormField(controller: skuState.retailPriceController, decoration: const InputDecoration(labelText: 'Preço de Varejo'), keyboardType: TextInputType.number),
                                      TextFormField(controller: skuState.wholesalePriceController, decoration: const InputDecoration(labelText: 'Preço de Atacado'), keyboardType: TextInputType.number),
                                      TextFormField(controller: skuState.stockController, decoration: const InputDecoration(labelText: 'Estoque'), keyboardType: TextInputType.number),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (controller.isSaving)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}