import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../l10n/generated/app_localizations.dart';

// Pushed from the Add Operation screen's scan button, or triggered by a
// hardware scanner acting as a keyboard wedge (handled in that screen's
// search field instead — this is the camera path only). Pops with the
// scanned barcode string, or null if the user backs out.
class CameraScanScreen extends StatefulWidget {
  const CameraScanScreen({super.key});

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen> with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _controller.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        _controller.stop();
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final value = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (value == null || value.isEmpty) return;
    _handled = true;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(AppLocalizations.of(context)!.scanBarcode),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          IgnorePointer(
            child: CustomPaint(
              painter: _ScanFramePainter(),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 48,
            child: Text(
              AppLocalizations.of(context)!.alignBarcode,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cutoutSize = size.shortestSide * 0.62;
    final cutoutRect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: cutoutSize,
      height: cutoutSize,
    );
    final cutoutRRect = RRect.fromRectAndRadius(cutoutRect, const Radius.circular(20));

    final maskPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      Path()..addRRect(cutoutRRect),
    );
    canvas.drawPath(maskPath, Paint()..color = Colors.black.withValues(alpha: 0.55));

    canvas.drawRRect(
      cutoutRRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    const bracketLen = 26.0;
    final bracketPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final r = cutoutRect;
    canvas.drawLine(r.topLeft, r.topLeft.translate(bracketLen, 0), bracketPaint);
    canvas.drawLine(r.topLeft, r.topLeft.translate(0, bracketLen), bracketPaint);
    canvas.drawLine(r.topRight, r.topRight.translate(-bracketLen, 0), bracketPaint);
    canvas.drawLine(r.topRight, r.topRight.translate(0, bracketLen), bracketPaint);
    canvas.drawLine(r.bottomLeft, r.bottomLeft.translate(bracketLen, 0), bracketPaint);
    canvas.drawLine(r.bottomLeft, r.bottomLeft.translate(0, -bracketLen), bracketPaint);
    canvas.drawLine(r.bottomRight, r.bottomRight.translate(-bracketLen, 0), bracketPaint);
    canvas.drawLine(r.bottomRight, r.bottomRight.translate(0, -bracketLen), bracketPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
