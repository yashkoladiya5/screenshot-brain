import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../design/tokens.dart';

class SbScratchCard extends StatefulWidget {
  final Widget child; // The content to be revealed
  final Widget cover; // The scratchable cover
  final double strokeWidth;
  final double scratchThreshold; // 0.0 to 1.0, what percentage of the card needs to be scratched to auto-reveal
  final VoidCallback? onScratchCompleted;

  const SbScratchCard({
    super.key,
    required this.child,
    required this.cover,
    this.strokeWidth = 35.0,
    this.scratchThreshold = 0.5,
    this.onScratchCompleted,
  }) : assert(scratchThreshold >= 0.0 && scratchThreshold <= 1.0);

  @override
  State<SbScratchCard> createState() => _SbScratchCardState();
}

class _SbScratchCardState extends State<SbScratchCard> {
  List<Offset?> _points = [];
  bool _isCleared = false;
  
  // To calculate threshold, we'll track the bounding box of points and compare to total area
  // This is a rough estimation for performance
  double _scratchedAreaApproximation = 0.0;
  Size? _cardSize;

  void _addPoint(Offset? point, Size size) {
    if (_isCleared) return;
    
    setState(() {
      _cardSize = size;
      _points.add(point);
      
      // Rough estimation of scratched area
      if (point != null) {
        _scratchedAreaApproximation += (math.pi * math.pow(widget.strokeWidth / 2, 2));
        
        final totalArea = size.width * size.height;
        // Divide by 2 to account for heavy overlap in user strokes
        if ((_scratchedAreaApproximation / 2) / totalArea > widget.scratchThreshold) {
          _isCleared = true;
          widget.onScratchCompleted?.call();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCleared) {
      return widget.child;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        
        return GestureDetector(
          onPanStart: (details) {
            _addPoint(details.localPosition, size);
          },
          onPanUpdate: (details) {
            _addPoint(details.localPosition, size);
          },
          onPanEnd: (details) {
            _addPoint(null, size);
          },
          child: Stack(
            children: [
              // 1. The hidden content
              widget.child,
              
              // 2. The scratchable cover using ShaderMask and CustomPainter to erase
              Positioned.fill(
                child: ShaderMask(
                  blendMode: BlendMode.dstOut,
                  shaderCallback: (bounds) {
                    // We don't actually use the shader here for the drawing, 
                    // we use a CustomPainter inside a CustomPaint which acts as the mask
                    return const LinearGradient(
                      colors: [Colors.black, Colors.black],
                    ).createShader(bounds);
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // The visual cover
                      widget.cover,
                      
                      // The invisible erasing layer that the ShaderMask uses to cut holes
                      CustomPaint(
                        painter: _ScratchPainter(
                          points: _points,
                          strokeWidth: widget.strokeWidth,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
    final paint = Paint()
      ..color = Colors.black // This color doesn't matter, dstOut uses alpha
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.srcOver; // Overrides the stack but gets caught by dstOut

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      } else if (points[i] != null && points[i + 1] == null) {
        // Draw a dot if they just tapped
        canvas.drawCircle(points[i]!, strokeWidth / 2, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ScratchPainter oldDelegate) {
    return oldDelegate.points.length != points.length;
  }
}

import 'dart:math' as math;
