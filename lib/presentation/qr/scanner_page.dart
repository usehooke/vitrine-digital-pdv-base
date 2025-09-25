import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});
  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _scanned = false;
  bool _cameraAvailable = true;
  bool _initializing = true;
  String? _cameraError;
  bool _starting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ler QR'),
        actions: [
          IconButton(
            tooltip: 'Inserir código manualmente',
            icon: const Icon(Icons.edit),
            onPressed: () => _showManualInputDialog(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Show helpful fallback when running on web where camera may be unavailable
          Positioned.fill(
            child: _cameraAvailable
                ? MobileScanner(
                    controller: cameraController,
                    onDetect: (capture) {
                      try {
                        if (_scanned) return;
                        final List<Barcode> barcodes = capture.barcodes;
                        if (barcodes.isEmpty) return;
                        final raw = barcodes.first.rawValue ?? '';
                        if (raw.isEmpty) return;
                        _scanned = true;
                        Navigator.of(context).pop(raw);
                      } catch (e, s) {
                        // capture unexpected errors and show a friendly message
                        debugPrint('Scanner onDetect error: $e\n$s');
                        setState(() {
                          _cameraError = 'Erro ao ler o QR: ${e.toString()}';
                        });
                      }
                    },
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            kIsWeb ? Icons.wifi_off : Icons.videocam_off,
                            size: 64,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _cameraError ?? 'Câmera não detectada ou inacessível.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tentar novamente'),
                            onPressed: _tryInitCamera,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.keyboard),
                            label: const Text('Inserir código manualmente'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                            ),
                            onPressed: () => _showManualInputDialog(context),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          // Small controller overlay (torch / flip) when camera is available
          if (_cameraAvailable)
            Positioned(
              top: 16,
              right: 16,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'torch',
                    onPressed: () async {
                      try {
                        await cameraController.toggleTorch();
                        setState(() {});
                      } catch (_) {}
                    },
                    child: const Icon(Icons.flash_on),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'camera',
                    onPressed: () async {
                      try {
                        await cameraController.switchCamera();
                      } catch (e) {
                        debugPrint('Switch camera failed: $e');
                        setState(() {
                          _cameraError = 'Falha ao alternar câmera: ${e.toString()}';
                        });
                      }
                    },
                    child: const Icon(Icons.cameraswitch),
                  ),
                ],
              ),
            ),
          // Manual input button overlay (useful when camera is not available on web)
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.keyboard),
                label: const Text('Inserir código manualmente'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: () => _showManualInputDialog(context),
              ),
            ),
          ),
          // Top banner for camera status
          if (_initializing || _cameraError != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                color: const Color.fromRGBO(0, 0, 0, 0.6),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_initializing) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      else const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _initializing ? 'Iniciando câmera...' : (_cameraError ?? ''),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Probe for camera availability; do not call start() directly because
    // MobileScanner manages camera lifecycle and calling start() while it
    // is starting can cause conflicts on web.
    _probeCameraAvailability();
  }

  Future<void> _tryInitCamera() async {
    setState(() {
      _initializing = true;
      _cameraError = null;
    });

    // On web, camera access is frequently blocked or absent. Attempt to start and use a timeout.
    // Keep existing behavior for backward compatibility; callers may still use it.
    if (_starting) {
      setState(() {
        _initializing = false;
        _cameraError = 'Inicialização já em progresso';
      });
      return;
    }
    // Attempt to start, but many web environments will throw; this method is
    // retained for manual retry button but the normal lifecycle is managed by
    // the MobileScanner widget.
    _starting = true;
    try {
      final startFuture = cameraController.start();
      await startFuture;
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() {
        _cameraAvailable = true;
        _cameraError = null;
      });
    } catch (e) {
      debugPrint('Camera init failed: $e');
      setState(() {
        _cameraAvailable = false;
        _cameraError = 'Câmera indisponível: ${e.toString()}';
      });
    } finally {
      _starting = false;
      setState(() {
        _initializing = false;
      });
    }
  }

  /// Probe camera availability without calling start() to avoid conflicts.
  Future<void> _probeCameraAvailability() async {
    setState(() {
      _initializing = true;
      _cameraError = null;
    });
    // On web, presence of ZXing helps. We check window.__zxing_present via
    // `dart:js` interoperability; to keep this file pure Dart/Flutter we use
    // a heuristic delay and rely on MobileScanner's own errors to surface.
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _initializing = false;
    });
  }

  void _showManualInputDialog(BuildContext pageContext) {
    final TextEditingController t = TextEditingController();
    showDialog<void>(
      context: pageContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Inserir código'),
          content: TextField(
            controller: t,
            decoration: const InputDecoration(hintText: 'Cole o código ou QR aqui'),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                final value = t.text.trim();
                if (value.isEmpty) return;
                Navigator.of(dialogContext).pop();
                // Pop the scanner page returning the manual code
                Navigator.of(pageContext).pop(value);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}