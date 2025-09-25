import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:qr/qr.dart';

Future<Uint8List> generateQrPngBytes(String data, {int modulePixel = 8, int paddingModules = 4}) async {
  // Create a canvas sized to the QR code
  final qr = QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.L);
  final modules = qr.moduleCount;
  final size = (modules + paddingModules * 2) * modulePixel;
  final canvas = html.CanvasElement(width: size, height: size);
  final ctx = canvas.context2D;
  ctx.fillStyle = '#ffffff';
  ctx.fillRect(0, 0, size, size);
  ctx.fillStyle = '#000000';
  for (int r = 0; r < modules; r++) {
    for (int c = 0; c < modules; c++) {
  if (qr.isDark(r, c)) {
        final x = (c + paddingModules) * modulePixel;
        final y = (r + paddingModules) * modulePixel;
        ctx.fillRect(x, y, modulePixel, modulePixel);
      }
    }
  }

  // Convert canvas to blob and then to Uint8List
  final blob = await canvas.toBlob('image/png');
  final reader = html.FileReader();
  final completer = Completer<Uint8List>();
  reader.onLoad.listen((_) {
    final result = reader.result as Object;
    if (result is ByteBuffer) {
      completer.complete(Uint8List.view(result));
    } else if (result is Uint8List) {
      completer.complete(result);
    } else {
      completer.completeError(Exception('Unexpected FileReader result type'));
    }
  });
  reader.onError.listen((event) {
    completer.completeError(Exception('Failed to read canvas blob'));
  });
  reader.readAsArrayBuffer(blob!);
  return completer.future;
}
