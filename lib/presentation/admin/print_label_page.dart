import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

// The pdf widgets used below don't support const constructors; suppress the
// prefer_const_constructors lint for this file where that applies.
// ignore_for_file: prefer_const_constructors

class PrintLabelPage extends StatelessWidget {
  final String? qrUrl;
  final String? skuText;
  const PrintLabelPage({super.key, this.qrUrl, this.skuText});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Imprimir Etiqueta')),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (qrUrl != null) Image.network(qrUrl!, width: 180, height: 180),
          const SizedBox(height: 8),
          if (skuText != null) Text(skuText!, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: qrUrl == null ? null : () async {
              final pdf = await _buildPdf(qrUrl!, skuText);
              await Printing.layoutPdf(onLayout: (_) => pdf);
            },
            child: const Text('Imprimir / Gerar PDF'),
          ),
        ]),
      ),
    );
  }

  Future<Uint8List> _buildPdf(String url, String? sku) async {
    final resp = await http.get(Uri.parse(url));
    final bytes = resp.bodyBytes;
    final doc = pw.Document();
    final image = pw.MemoryImage(bytes);
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat(72 * PdfPageFormat.mm, 35 * PdfPageFormat.mm), // tamanho etiqueta aproximado
      build: (context) => pw.Column(children: [
        pw.Center(child: pw.Image(image, width: 140, height: 140)),
  if (sku != null) pw.SizedBox(height: 6),
  if (sku != null) pw.Text(sku, style: pw.TextStyle(fontSize: 12))
      ]),
    ));
    return await doc.save();
  }
}