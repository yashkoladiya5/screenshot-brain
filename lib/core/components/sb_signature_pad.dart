import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:ui' as ui;
import '../design/tokens.dart';

class SbSignaturePad extends StatefulWidget {
  final double height;
  final Color strokeColor;
  final double strokeWidth;
  final Color backgroundColor;
  final VoidCallback? onSigned;
  final VoidCallback? onCleared;

  const SbSignaturePad({
    super.key,
    this.height = 200.0,
    this.strokeColor = Colors.black,
    this.strokeWidth = 4.0,
    this.backgroundColor = const Color(0xFFF5F5F5),
    this.onSigned,
    this.onCleared,
  });

  @override
  State<SbSignaturePad> createState() => SbSignaturePadState();
}

class SbSignaturePadState extends State<SbSignaturePad> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _hasSignature = false;

  void _startStroke(Offset position) {
    setState(() {
      _currentStroke = [position];
      _strokes.add(_currentStroke);
    });
  }

  void _updateStroke(Offset position) {
    setState(() {
      _currentStroke.add(position);
      if (!_hasSignature) {
        _hasSignature = true;
        widget.onSigned?.call();
      }
    });
  }

  void clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
      _hasSignature = false;
    });
    widget.onCleared?.call();
  }

  bool get hasSignature => _hasSignature;

  // Potential helper method for users to extract image
  // Future<ui.Image> toImage() async { ... }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(SBRadius.md),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Stack(
        children: [
          // Hint text if empty
          if (!_hasSignature)
            Center(
              child: Text(
                'Sign here',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            
          // Drawing Area
          ClipRRect(
            borderRadius: BorderRadius.circular(SBRadius.md),
            child: Listener(
              onPointerDown: (event) => _startStroke(event.localPosition),
              onPointerMove: (event) => _updateStroke(event.localPosition),
              child: CustomPaint(
                painter: _SignaturePainter(
                  strokes: _strokes,
                  strokeColor: widget.strokeColor,
                  strokeWidth: widget.strokeWidth,
                ),
                size: Size.infinite,
              ),
            ),
          ),
          
          // Clear Button
          if (_hasSignature)
            Positioned(
              top: SBSpacing.sm,
              right: SBSpacing.sm,
              child: IconButton(
                icon: const Icon(Icons.clear_rounded, size: 20),
                onPressed: clear,
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                  foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                tooltip: 'Clear Signature',
              ),
            ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final Color strokeColor;
  final double strokeWidth;

  _SignaturePainter({
    required this.strokes,
    required this.strokeColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      
      final path = Path();
      path.moveTo(stroke.first.dx, stroke.first.dy);
      
      if (stroke.length == 1) {
        // Draw a dot if it's just a tap
        canvas.drawCircle(stroke.first, strokeWidth / 2, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
      } else {
        // Draw smooth lines for multiple points
        for (int i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
    // In a real app, we might optimize this to only repaint the new stroke segment
    return true; 
  }
}
