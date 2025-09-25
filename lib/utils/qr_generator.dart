// Conditional import: uses web implementation when running on web, otherwise IO implementation.
import 'qr_generator_io.dart'
    if (dart.library.html) 'qr_generator_web.dart';

// The imported file defines:
// Future<Uint8List> generateQrPngBytes(String data, {int pixelSize = 8, int padding = 4});
