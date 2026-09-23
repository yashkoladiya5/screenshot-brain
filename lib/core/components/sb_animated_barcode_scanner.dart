import 'package:flutter/material.dart';

class SbAnimatedBarcodeScanner extends StatefulWidget {
  final Widget? backgroundCameraView;
  final double scannerSize;
  final Color scannerColor;
  final Color overlayColor;
  final bool isScanning;

  const SbAnimatedBarcodeScanner({
    super.key,
    this.backgroundCameraView,
    this.scannerSize = 250.0,
    this.scannerColor = const Color(0xFF00FF00),
    this.overlayColor = const Color(0x99000000), // Semi-transparent black
    this.isScanning = true,
  });

  @override
  State<SbAnimatedBarcodeScanner> createState() => _SbAnimatedBarcodeScannerState();
}

class _SbAnimatedBarcodeScannerState extends State<SbAnimatedBarcodeScanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    if (widget.isScanning) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SbAnimatedBarcodeScanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning != oldWidget.isScanning) {
      if (widget.isScanning) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. The underlying camera or background view
        if (widget.backgroundCameraView != null)
          Positioned.fill(
            child: widget.backgroundCameraView!,
          )
        else
          Positioned.fill(
            child: Container(
              color: Colors.black, // Fallback if no camera provided
              child: const Center(
                child: Icon(Icons.camera_alt, color: Colors.white24, size: 64),
              ),
            ),
          ),

        // 2. The darkened overlay with a clear cutout in the center
        Positioned.fill(
          child: CustomPaint(
            painter: _ScannerOverlayPainter(
              overlayColor: widget.overlayColor,
              scannerSize: widget.scannerSize,
            ),
          ),
        ),

        // 3. The animated scanning laser line
        Center(
          child: SizedBox(
            width: widget.scannerSize,
            height: widget.scannerSize,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // Animate from top (0.0) to bottom (1.0) of the scanner box
                // We add a tiny padding so the laser doesn't hit the very edges
                final double yOffset = 10.0 + (_controller.value * (widget.scannerSize - 20.0));
                
                return Stack(
                  children: [
                    Positioned(
                      top: yOffset,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: widget.scannerColor,
                          boxShadow: [
                            BoxShadow(
                              color: widget.scannerColor,
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ]
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final Color overlayColor;
  final double scannerSize;

  _ScannerOverlayPainter({
    required this.overlayColor,
    required this.scannerSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint overlayPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;
      
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // The whole screen
    final Path screenPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // The cutout box in the middle
    final double left = (size.width - scannerSize) / 2;
    final double top = (size.height - scannerSize) / 2;
    
    // Create a rounded rectangle for the cutout
    final RRect cutoutRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, scannerSize, scannerSize),
      const Radius.circular(20),
    );
    
    final Path cutoutPath = Path()..addRRect(cutoutRRect);

    // Combine paths to create the overlay with a hole
    // PathFillType.evenOdd ensures the cutout is transparent
    final Path finalPath = Path.combine(
      PathOperation.difference,
      screenPath,
      cutoutPath,
    );

    // Draw the dark overlay
    canvas.drawPath(finalPath, overlayPaint);
    
    // Draw the corner brackets
    final double cornerLength = scannerSize * 0.2;
    final Path cornerPath = Path();
    
    // Top Left
    cornerPath.moveTo(left, top + cornerLength);
    cornerPath.lineTo(left, top + 20); // curve start
    cornerPath.arcToPoint(
      Offset(left + 20, top),
      radius: const Radius.circular(20),
    );
    cornerPath.lineTo(left + cornerLength, top);
    
    // Top Right
    cornerPath.moveTo(left + scannerSize - cornerLength, top);
    cornerPath.lineTo(left + scannerSize - 20, top); // curve start
    cornerPath.arcToPoint(
      Offset(left + scannerSize, top + 20),
      radius: const Radius.circular(20),
    );
    cornerPath.lineTo(left + scannerSize, top + cornerLength);
    
    // Bottom Right
    cornerPath.moveTo(left + scannerSize, top + scannerSize - cornerLength);
    cornerPath.lineTo(left + scannerSize, top + scannerSize - 20); // curve start
    cornerPath.arcToPoint(
      Offset(left + scannerSize - 20, top + scannerSize),
      radius: const Radius.circular(20),
    );
    cornerPath.lineTo(left + scannerSize - cornerLength, top + scannerSize);
    
    // Bottom Left
    cornerPath.moveTo(left + cornerLength, top + scannerSize);
    cornerPath.lineTo(left + 20, top + scannerSize); // curve start
    cornerPath.arcToPoint(
      Offset(left, top + scannerSize - 20),
      radius: const Radius.circular(20),
    );
    cornerPath.lineTo(left, top + scannerSize - cornerLength);

    // Draw the white targeting corners
    canvas.drawPath(cornerPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.overlayColor != overlayColor ||
           oldDelegate.scannerSize != scannerSize;
  }
}
