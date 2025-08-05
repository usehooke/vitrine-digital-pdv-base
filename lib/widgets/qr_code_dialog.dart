import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:image_gallery_saver/image_gallery_saver.dart';

class QrCodePrintDialog extends StatelessWidget {
  final String productName;
  final String sku;
  final GlobalKey _printKey = GlobalKey();

  QrCodePrintDialog({super.key, required this.productName, required this.sku});

  Future<void> _downloadQrCode(BuildContext context) async {
    try {
      // 🔍 Verifica se o contexto está disponível antes de tentar capturar
      final boundaryContext = _printKey.currentContext;
      if (boundaryContext == null) {
        print("Render ainda não está pronto.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A etiqueta ainda não está pronta para ser capturada.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final boundary = boundaryContext.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      if (kIsWeb) {
        // 🌐 Download via navegador
        final base64String = base64Encode(pngBytes);
        final anchor = html.AnchorElement(
          href: 'data:application/octet-stream;base64,$base64String',
        )
          ..setAttribute('download', '$sku.png')
          ..click();
      } else {
        // 📱 Salvamento em dispositivos móveis
        final result = await ImageGallerySaver.saveImage(
          pngBytes,
          quality: 100,
          name: sku,
        );

        if (result['isSuccess']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Etiqueta salva na galeria de imagens!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          final errorMsg = result['errorMessage'] ?? 'Erro desconhecido.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar etiqueta: $errorMsg')),
          );
        }
      }
    } catch (e) {
      print("### ERRO AO FAZER DOWNLOAD DA ETIQUETA: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar etiqueta: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1e293b),
      content: SizedBox(
        width: 300,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RepaintBoundary(
                key: _printKey,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        productName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sku,
                        style: const TextStyle(color: Colors.black, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      QrImageView(
                        data: sku,
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _downloadQrCode(context),
                icon: const Icon(Icons.download),
                label: const Text('Baixar PNG'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}