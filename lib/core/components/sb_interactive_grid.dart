import 'package:flutter/material.dart';

class SbInteractiveGrid extends StatefulWidget {
  final double width;
  final double height;
  final double gridSize;
  final Color gridColor;
  final Color highlightColor;
  final Widget? child;

  const SbInteractiveGrid({
    super.key,
    this.width = double.infinity,
    this.height = double.infinity,
    this.gridSize = 40.0,
    this.gridColor = const Color(0xFF2C2C2E),
    this.highlightColor = const Color(0xFF007AFF),
    this.child,
  });

  @override
  State<SbInteractiveGrid> createState() => _SbInteractiveGridState();
}

class _SbInteractiveGridState extends State<SbInteractiveGrid> {
  Offset _pointerPosition = const Offset(-1000, -1000); // Start far off screen

  void _onPointerMove(Offset position) {
    setState(() {
      _pointerPosition = position;
    });
  }

  void _onPointerExit() {
    setState(() {
      _pointerPosition = const Offset(-1000, -1000);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) => _onPointerMove(event.localPosition),
      onExit: (_) => _onPointerExit(),
      child: GestureDetector(
        onPanUpdate: (details) => _onPointerMove(details.localPosition),
        onPanEnd: (_) => _onPointerExit(),
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // The Grid Painter
              CustomPaint(
                painter: _GridPainter(
                  pointerPosition: _pointerPosition,
                  gridSize: widget.gridSize,
                  gridColor: widget.gridColor,
                  highlightColor: widget.highlightColor,
                ),
              ),
              
              // Optional child content on top of grid
              if (widget.child != null) widget.child!,
            ],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Offset pointerPosition;
  final double gridSize;
  final Color gridColor;
  final Color highlightColor;

  _GridPainter({
    required this.pointerPosition,
    required this.gridSize,
    required this.gridColor,
    required this.highlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw the base grid
    final Paint baseGridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final Path baseGridPath = Path();

    // Vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      baseGridPath.moveTo(x, 0);
      baseGridPath.lineTo(x, size.height);
    }

    // Horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      baseGridPath.moveTo(0, y);
      baseGridPath.lineTo(size.width, y);
    }

    canvas.drawPath(baseGridPath, baseGridPaint);

    // 2. Draw the highlight overlay grid
    // We only draw the lines that are close to the pointer to save performance
    // and create a glowing intersection effect
    
    final Paint highlightPaint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      // We use a shader so the highlight fades out smoothly from the exact pointer center
      ..shader = RadialGradient(
        colors: [
          highlightColor,
          highlightColor.withValues(alpha: 0.5),
          highlightColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: pointerPosition, radius: gridSize * 3));

    final Path highlightPath = Path();
    
    // Only calculate lines within a certain radius of the pointer
    final double effectRadius = gridSize * 4;
    
    // Vertical highlight lines
    final double startX = (pointerPosition.dx - effectRadius).clamp(0, size.width);
    final double endX = (pointerPosition.dx + effectRadius).clamp(0, size.width);
    
    // Snap to nearest grid line
    final double snappedStartX = (startX / gridSize).floor() * gridSize;
    
    for (double x = snappedStartX; x <= endX; x += gridSize) {
      highlightPath.moveTo(x, (pointerPosition.dy - effectRadius).clamp(0, size.height));
      highlightPath.lineTo(x, (pointerPosition.dy + effectRadius).clamp(0, size.height));
    }

    // Horizontal highlight lines
    final double startY = (pointerPosition.dy - effectRadius).clamp(0, size.height);
    final double endY = (pointerPosition.dy + effectRadius).clamp(0, size.height);
    
    final double snappedStartY = (startY / gridSize).floor() * gridSize;
    
    for (double y = snappedStartY; y <= endY; y += gridSize) {
      highlightPath.moveTo((pointerPosition.dx - effectRadius).clamp(0, size.width), y);
      highlightPath.lineTo((pointerPosition.dx + effectRadius).clamp(0, size.width), y);
    }

    // Draw the glowing intersection lines
    canvas.drawPath(highlightPath, highlightPaint);
    
    // Draw a small bright node exactly at the nearest intersection point
    final double nearestX = (pointerPosition.dx / gridSize).round() * gridSize;
    final double nearestY = (pointerPosition.dy / gridSize).round() * gridSize;
    
    // Only draw the node if we are actually hovering over the canvas
    if (pointerPosition.dx >= 0 && pointerPosition.dy >= 0) {
      final Paint nodePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
        
      canvas.drawCircle(Offset(nearestX, nearestY), 3.0, nodePaint);
      
      final Paint glowPaint = Paint()
        ..color = highlightColor.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
        
      canvas.drawCircle(Offset(nearestX, nearestY), 8.0, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.pointerPosition != pointerPosition || 
           oldDelegate.gridSize != gridSize || 
           oldDelegate.gridColor != gridColor ||
           oldDelegate.highlightColor != highlightColor;
  }
}
