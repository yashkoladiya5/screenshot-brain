import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbInteractiveFluidBlob extends StatefulWidget {
  final double size;
  final Color color;
  final int vertexCount;
  
  const SbInteractiveFluidBlob({
    super.key,
    this.size = 200.0,
    this.color = const Color(0xFF6C63FF),
    this.vertexCount = 8,
  });

  @override
  State<SbInteractiveFluidBlob> createState() => _SbInteractiveFluidBlobState();
}

class _SbInteractiveFluidBlobState extends State<SbInteractiveFluidBlob> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset? _touchPosition;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (details) => setState(() => _touchPosition = details.localPosition),
      onPanUpdate: (details) => setState(() => _touchPosition = details.localPosition),
      onPanEnd: (_) => setState(() => _touchPosition = null),
      onPanCancel: () => setState(() => _touchPosition = null),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _BlobPainter(
                time: _controller.value,
                color: widget.color,
                vertexCount: widget.vertexCount,
                touchPosition: _touchPosition,
              ),
            );
          }
        ),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  final double time;
  final Color color;
  final int vertexCount;
  final Offset? touchPosition;

  _BlobPainter({
    required this.time,
    required this.color,
    required this.vertexCount,
    required this.touchPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double baseRadius = size.width * 0.4;
    
    final Path path = Path();
    
    // We calculate a list of points around a circle
    List<Offset> points = [];
    
    for (int i = 0; i < vertexCount; i++) {
      final double angle = (i / vertexCount) * 2 * math.pi;
      
      // Calculate continuous noise using sine waves for organic breathing
      // We use time + angle to make the wave travel around the blob
      final double noise1 = math.sin((time * 2 * math.pi) + (angle * 3)) * 10;
      final double noise2 = math.cos((time * 4 * math.pi) - (angle * 2)) * 5;
      
      double radius = baseRadius + noise1 + noise2;
      
      // Calculate base position for this vertex
      double dx = center.dx + math.cos(angle) * radius;
      double dy = center.dy + math.sin(angle) * radius;
      
      // Apply touch repulsion
      if (touchPosition != null) {
        final Offset vertexPos = Offset(dx, dy);
        final Offset vectorToTouch = touchPosition! - vertexPos;
        final double distance = vectorToTouch.distance;
        
        // If finger is close to this vertex, push it inward
        if (distance < baseRadius) {
          final double pushStrength = (baseRadius - distance) / baseRadius;
          // Push away from touch (towards center)
          final Offset pushVector = -vectorToTouch * pushStrength * 0.5;
          dx += pushVector.dx;
          dy += pushVector.dy;
        }
      }
      
      points.add(Offset(dx, dy));
    }
    
    // Draw the fluid shape using cubic beziers between the calculated points
    path.moveTo(points[0].dx, points[0].dy);
    
    for (int i = 0; i < points.length; i++) {
      final Offset current = points[i];
      final Offset next = points[(i + 1) % points.length];
      
      // Control points are calculated to make the curve perfectly smooth
      // by placing them along the tangent line of the circle
      
      // A simplified approach for smooth blob curves:
      final Offset midPoint = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      
      // We actually want to use quadratic bezier to the midpoints to guarantee smoothness
      if (i == 0) {
        path.moveTo(midPoint.dx, midPoint.dy);
      } else {
        path.quadraticBezierTo(current.dx, current.dy, midPoint.dx, midPoint.dy);
      }
    }
    
    // Close the loop
    path.quadraticBezierTo(points[0].dx, points[0].dy, 
        (points[0].dx + points[1].dx) / 2, 
        (points[0].dy + points[1].dy) / 2);
        
    path.close();
    
    canvas.drawPath(path, paint);
    
    // Inner shadow/highlight for 3D gelatinous effect
    final Paint highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      
    // Draw a smaller offset blob for highlight
    canvas.drawCircle(Offset(center.dx - baseRadius * 0.3, center.dy - baseRadius * 0.3), baseRadius * 0.4, highlight);
  }

  @override
  bool shouldRepaint(covariant _BlobPainter oldDelegate) {
    return oldDelegate.time != time || oldDelegate.touchPosition != touchPosition;
  }
}
