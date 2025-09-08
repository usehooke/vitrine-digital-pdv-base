import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'product_form_controller.dart';

class ProductFormPage extends StatelessWidget {
  final String? productId;
  const ProductFormPage({super.key, this.productId});

  @override
  Widget build(BuildContext context) {
    // A página consome o controller que foi criado na rota (app_router.dart)
    final controller = context.watch<ProductFormController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(controller.isEditMode ? 'Editar Produto' : 'Adicionar Produto'),
      ),
      body: Stack(
        children: [
          // Mostra um indicador de progresso enquanto os dados do produto são carregados
          if (controller.isLoading)
            const Center(child: CircularProgressIndicator())
          else
            // Stepper para um fluxo de preenchimento guiado
            Stepper(
              type: StepperType.horizontal, // Um stepper horizontal é moderno em telas largas
              currentStep: controller.currentStep,
              onStepContinue: () => controller.onStepContinue(context),
              onStepCancel: controller.onStepCancel,
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Row(
                    children: [
                      if (controller.currentStep == 2)
                        FilledButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text('Salvar Produto'),
                          onPressed: details.onStepContinue,
                        )
                      else
                        ElevatedButton(
                          onPressed: details.onStepContinue,
                          child: const Text('Próximo'),
                        ),
                      const SizedBox(width: 8),
                      if (controller.currentStep > 0)
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Anterior'),
                        ),
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: const Text('Informações'),
                  isActive: controller.currentStep >= 0,
                  state: controller.currentStep > 0 ? StepState.complete : StepState.indexed,
                  content: const _BasicInfoStep(),
                ),
                Step(
                  title: const Text('Variantes'),
                  isActive: controller.currentStep >= 1,
                  state: controller.currentStep > 1 ? StepState.complete : StepState.indexed,
                  content: const _VariantsStep(),
                ),
                Step(
                  title: const Text('Preços'),
                  isActive: controller.currentStep >= 2,
                  content: const _PricingStep(),
                ),
              ],
            ),
          // Overlay de loading ao salvar
          if (controller.isSaving)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('A guardar...', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --- WIDGETS AUXILIARES PARA CADA PASSO DO STEPPER ---

class _BasicInfoStep extends StatelessWidget {
  const _BasicInfoStep();
  @override
  Widget build(BuildContext context) {
    final controller = context.read<ProductFormController>();
    return Column(
      children: [
        TextFormField(controller: controller.categoryController, decoration: const InputDecoration(labelText: 'Categoria', hintText: 'ex: Camiseta')),
        const SizedBox(height: 16),
        TextFormField(controller: controller.nameController, decoration: const InputDecoration(labelText: 'Nome do Produto', hintText: 'ex: Estampa Fusca')),
        const SizedBox(height: 16),
        TextFormField(controller: controller.modelController, decoration: const InputDecoration(labelText: 'Modelo', hintText: 'ex: Manga Curta')),
      ],
    );
  }
}

class _VariantsStep extends StatelessWidget {
  const _VariantsStep();
  @override
  Widget build(BuildContext context) {
    // Usamos 'watch' aqui para que esta secção se reconstrua quando variantes são adicionadas/removidas
    final controller = context.watch<ProductFormController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (controller.variants.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Adicione pelo menos uma cor/variante.'),
          ))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.variants.length,
            itemBuilder: (context, index) {
              final variantState = controller.variants[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: variantState.colorController, decoration: const InputDecoration(labelText: 'Cor', hintText: 'ex: Branca'))),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => controller.removeVariant(index)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ImagePickerWidget(
                        selectedFile: variantState.imageFile, 
                        existingImageUrl: variantState.imageUrl,
                        onTap: () => controller.pickImage(variantState),
                      ),
                      const Divider(height: 32),
                      const Text('Tamanhos (SKUs) desta Cor', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (variantState.skus.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('Adicione pelo menos um tamanho.', style: TextStyle(color: Colors.grey)),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: variantState.skus.length,
                          itemBuilder: (context, skuIndex) {
                            final skuState = variantState.skus[skuIndex];
                            return Row(
                              children: [
                                Expanded(flex: 3, child: TextFormField(controller: skuState.sizeController, decoration: const InputDecoration(labelText: 'Tamanho'))),
                                const SizedBox(width: 8),
                                Expanded(flex: 6, child: InputDecorator(decoration: const InputDecoration(labelText: 'SKU Gerado', border: InputBorder.none, contentPadding: EdgeInsets.only(top: 8)), child: SelectableText(skuState.generatedSku.isEmpty ? '...' : skuState.generatedSku))),
                                IconButton(icon: const Icon(Icons.delete_outline, size: 20), onPressed: () => controller.removeSkuFromVariant(variantState, skuIndex)),
                              ],
                            );
                          },
                        ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(icon: const Icon(Icons.add, size: 16), label: const Text('Adicionar Tamanho'), onPressed: () => controller.addSkuToVariant(variantState)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 8),
        ElevatedButton.icon(icon: const Icon(Icons.add_circle_outline), label: const Text('Adicionar Cor/Variante'), onPressed: controller.addVariant),
      ],
    );
  }
}

class _PricingStep extends StatelessWidget {
  const _PricingStep();
  @override
  Widget build(BuildContext context) {
    // Usamos 'watch' para que a lista de SKUs se atualize
    final controller = context.watch<ProductFormController>();
    return Column(
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Atualização em Massa', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Valores preenchidos aqui serão aplicados a TODOS os SKUs abaixo.', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 16),
                TextFormField(controller: controller.batchRetailPriceController, decoration: const InputDecoration(labelText: 'Preço de Varejo (Todos)', prefixText: 'R\$ '), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 16),
                TextFormField(controller: controller.batchWholesalePriceController, decoration: const InputDecoration(labelText: 'Preço de Atacado (Todos)', prefixText: 'R\$ '), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 16),
                TextFormField(controller: controller.batchStockController, decoration: const InputDecoration(labelText: 'Estoque (Todos)'), keyboardType: TextInputType.number),
              ],
            ),
          ),
        ),
        const Divider(height: 32),
        if (controller.allSkus.isEmpty)
          const Center(child: Text('Nenhum SKU para precificar. Adicione tamanhos no passo anterior.'))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.allSkus.length,
            itemBuilder: (context, index) {
              final skuState = controller.allSkus[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(skuState.generatedSku, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: TextFormField(controller: skuState.retailPriceController, decoration: const InputDecoration(labelText: 'Varejo', prefixText: 'R\$ '), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                        const SizedBox(width: 8),
                        Expanded(child: TextFormField(controller: skuState.wholesalePriceController, decoration: const InputDecoration(labelText: 'Atacado', prefixText: 'R\$ '), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                        const SizedBox(width: 8),
                        Expanded(child: TextFormField(controller: skuState.stockController, decoration: const InputDecoration(labelText: 'Estoque'), keyboardType: TextInputType.number)),
                      ]),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _ImagePickerWidget extends StatelessWidget {
  final dynamic selectedFile;
  final String? existingImageUrl;
  final VoidCallback onTap;

  const _ImagePickerWidget({
    this.selectedFile,
    this.existingImageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (selectedFile != null) {
      if (kIsWeb) {
        imageWidget = Image.network(selectedFile!.path, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
      } else {
        imageWidget = Image.file(File(selectedFile!.path), fit: BoxFit.cover, width: double.infinity, height: double.infinity);
      }
    } else if (existingImageUrl != null && existingImageUrl!.isNotEmpty) {
      imageWidget = Image.network(existingImageUrl!, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    } else {
      imageWidget = const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text('Selecionar Imagem'),
          ],
        ),
      );
    }

    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade400, width: 1.5, style: BorderStyle.solid),
          ),
          clipBehavior: Clip.antiAlias,
          child: imageWidget,
        ),
      ),
    );
  }
}