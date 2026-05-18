import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../theme.dart';

/// Full-screen QR scanner. Returns the first decoded payload as the
/// route result via Navigator.pop with a String. Caller is expected
/// to normalise (trim whitespace, strip `monero:` URI scheme, etc.).
///
/// Usage example: push a MaterialPageRoute that builds QrScanScreen,
/// then `addressController.text = scanned` on the returned String.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key, this.title = 'Scan QR'});
  final String title;

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  late final MobileScannerController _controller;
  bool _emitted = false;
  bool _permissionDenied = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (!status.isGranted) {
      setState(() => _permissionDenied = true);
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_emitted) return;
    for (final b in capture.barcodes) {
      final raw = b.rawValue;
      if (raw == null || raw.isEmpty) continue;
      _emitted = true;
      Navigator.of(context).pop<String>(_normalise(raw));
      return;
    }
  }

  /// Strip the `monero:` URI scheme so callers get a bare address.
  /// Drop any query parameters (`?tx_amount=...`) — the send screen
  /// has its own amount field; we don't want pre-filling to surprise
  /// the user.
  String _normalise(String raw) {
    final s = raw.trim();
    if (s.toLowerCase().startsWith('monero:')) {
      final stripped = s.substring(7);
      final qIx = stripped.indexOf('?');
      return qIx >= 0 ? stripped.substring(0, qIx) : stripped;
    }
    return s;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PeekColors.bg,
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (_, state, _) => Icon(
                state.torchState == TorchState.on
                    ? Icons.flashlight_on
                    : Icons.flashlight_off,
              ),
            ),
            onPressed: () => _controller.toggleTorch(),
            tooltip: 'Torch',
          ),
        ],
      ),
      body: _permissionDenied
          ? _PermissionDenied(onRetry: _checkPermission)
          : Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                  errorBuilder: (ctx, err) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Camera error: ${err.errorCode.name}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: PeekColors.red),
                        ),
                      ),
                    );
                  },
                ),
                // Sighting overlay — square frame in the middle, semi-
                // transparent mask around. Gives the user something to
                // aim at.
                const IgnorePointer(
                  child: Center(
                    child: _ScanFrame(),
                  ),
                ),
                if (_error != null)
                  Positioned(
                    bottom: 32,
                    left: 24,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: PeekColors.bg2.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: PeekColors.red),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _PermissionDenied extends StatelessWidget {
  const _PermissionDenied({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography, size: 56, color: PeekColors.text3),
            const SizedBox(height: 16),
            const Text(
              'Camera permission denied',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'PeekWallet needs camera access to scan QR codes. The camera is '
              'only used while this screen is open and no photos or videos '
              'are saved.',
              textAlign: TextAlign.center,
              style: TextStyle(color: PeekColors.text2, fontSize: 13),
            ),
            const SizedBox(height: 20),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => openAppSettings(),
              child: const Text('Open app settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        border: Border.all(color: PeekColors.accent, width: 3),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
