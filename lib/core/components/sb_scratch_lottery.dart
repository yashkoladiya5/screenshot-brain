import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class SbScratchLottery extends StatefulWidget {
  final Widget child; // The prize hidden underneath
  final Widget overlay; // The surface to scratch off
  final double strokeWidth;
  final VoidCallback? onScratchCompleted;

  const SbScratchLottery({
    super.key,
    required this.child,
    required this.overlay,
    this.strokeWidth = 40.0,
    this.onScratchCompleted,
  });

  @override
  State<SbScratchLottery> createState() => _SbScratchLotteryState();
}

class _SbScratchLotteryState extends State<SbScratchLottery> {
  final List<Offset?> _scratchPoints = [];
  bool _isCompleted = false;

  void _addPoint(Offset? point) {
    if (_isCompleted) return;

    setState(() {
      _scratchPoints.add(point);
    });

    if (_scratchPoints.length > 250 && !_isCompleted) {
       _isCompleted = true;
       if (widget.onScratchCompleted != null) {
         widget.onScratchCompleted!();
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. The hidden prize (bottom layer)
        widget.child,
        
        // 2. The scratchable overlay (top layer)
        if (!_isCompleted)
          GestureDetector(
            onPanDown: (details) => _addPoint(details.localPosition),
            onPanUpdate: (details) => _addPoint(details.localPosition),
            onPanEnd: (_) => _addPoint(null),
            child: ShaderMask(
              blendMode: BlendMode.dstOut, // This removes pixels where the mask is drawn
              shaderCallback: (bounds) {
                // Return a dummy shader since we rely on the child CustomPaint to provide the mask
                return const LinearGradient(colors: [Colors.transparent, Colors.transparent]).createShader(bounds);
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // The physical overlay visual
                  widget.overlay,
                  // The custom painter that draws the "eraser" lines
                  CustomPaint(
                    painter: _ScratchPainter(
                      points: _scratchPoints,
                      strokeWidth: widget.strokeWidth,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ScratchPainter extends CustomPainter {
  final List<Offset?> points;
  final double strokeWidth;

  _ScratchPainter({
    required this.points,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black // Color doesn't matter for dstOut, only alpha
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      } else if (points[i] != null && points[i + 1] == null) {
        canvas.drawPoints(ui.PointMode.points, [points[i]!], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ScratchPainter oldDelegate) => true;
}
