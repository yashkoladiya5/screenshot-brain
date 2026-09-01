import 'package:flutter/material.dart';

class SbAnimatedScratchCard extends StatefulWidget {
  final Widget child;
  final Widget overlay;
  final double width;
  final double height;
  final double brushSize;

  const SbAnimatedScratchCard({
    super.key,
    required this.child,
    required this.overlay,
    this.width = 300.0,
    this.height = 150.0,
    this.brushSize = 30.0,
  });

  @override
  State<SbAnimatedScratchCard> createState() => _SbAnimatedScratchCardState();
}

class _SbAnimatedScratchCardState extends State<SbAnimatedScratchCard> {
  final List<Offset> _points = [];

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _points.add(details.localPosition);
    });
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _points.add(details.localPosition);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        child: Stack(
          children: [
            SizedBox(
              width: widget.width,
              height: widget.height,
              child: widget.child,
            ),
            
            ClipRect(
              child: CustomPaint(
                size: Size(widget.width, widget.height),
                foregroundPainter: _ScratchPainter(
                  points: _points,
                  brushSize: widget.brushSize,
                ),
                child: SizedBox(
                  width: widget.width,
                  height: widget.height,
                  child: widget.overlay,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScratchPainter extends CustomPainter {
  final List<Offset> points;
  final double brushSize;

  _ScratchPainter({
    required this.points,
    required this.brushSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    final Paint eraser = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.transparent
      ..strokeWidth = brushSize
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      if ((points[i] - points[i + 1]).distance > 50) {
        canvas.drawCircle(points[i], brushSize / 2, eraser..style = PaintingStyle.fill);
        continue;
      }
      canvas.drawLine(points[i], points[i + 1], eraser);
    }
    
    if (points.isNotEmpty) {
      canvas.drawCircle(points.last, brushSize / 2, eraser..style = PaintingStyle.fill);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ScratchPainter oldDelegate) {
    return oldDelegate.points.length != points.length || 
           oldDelegate.brushSize != brushSize;
  }
}
