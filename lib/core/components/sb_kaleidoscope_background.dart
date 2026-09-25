import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbKaleidoscopeBackground extends StatefulWidget {
  final Widget child;
  final int segmentCount;
  final Color baseColor1;
  final Color baseColor2;
  final double animationSpeed; // Higher is faster

  const SbKaleidoscopeBackground({
    super.key,
    required this.child,
    this.segmentCount = 8,
    this.baseColor1 = const Color(0xFFFF00FF),
    this.baseColor2 = const Color(0xFF00FFFF),
    this.animationSpeed = 1.0,
  });

  @override
  State<SbKaleidoscopeBackground> createState() => _SbKaleidoscopeBackgroundState();
}

class _SbKaleidoscopeBackgroundState extends State<SbKaleidoscopeBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // We want a very slow, continuous rotation
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: (20 / widget.animationSpeed).round()),
    )..repeat();
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
        // The background effect
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _KaleidoscopePainter(
                  time: _controller.value,
                  segmentCount: widget.segmentCount,
                  color1: widget.baseColor1,
                  color2: widget.baseColor2,
                ),
              );
            },
          ),
        ),
        
        // The foreground content
        Positioned.fill(
          child: widget.child,
        ),
      ],
    );
  }
}

class _KaleidoscopePainter extends CustomPainter {
  final double time;
  final int segmentCount;
  final Color color1;
  final Color color2;

  _KaleidoscopePainter({
    required this.time,
    required this.segmentCount,
    required this.color1,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = math.sqrt(size.width * size.width + size.height * size.height) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    
    // We generate a "base" shape that we will reflect and rotate around the center
    // to create the kaleidoscope effect
    
    final double sliceAngle = (2 * math.pi) / segmentCount;
    
    // Save the canvas state before we start translating and rotating
    canvas.save();
    canvas.translate(center.dx, center.dy);
    
    // The entire pattern slowly rotates over time
    canvas.rotate(time * 2 * math.pi);
    
    for (int i = 0; i < segmentCount; i++) {
      canvas.save();
      
      // Rotate for each slice
      canvas.rotate(i * sliceAngle);
      
      // Every other slice is mirrored to create perfect radial symmetry
      if (i % 2 != 0) {
        canvas.scale(1.0, -1.0);
      }
      
      // Draw the base pattern for this slice
      _drawPatternSlice(canvas, radius, sliceAngle);
      
      canvas.restore();
    }
    
    // Restore the canvas to its original un-translated state
    canvas.restore();
  }
  
  void _drawPatternSlice(Canvas canvas, double radius, double sliceAngle) {
    // Create a clipping path so we only draw inside this specific pie slice
    final Path slicePath = Path();
    slicePath.moveTo(0, 0);
    slicePath.lineTo(radius, 0);
    
    // Approximate the arc
    for (double i = 0; i <= sliceAngle; i += 0.05) {
      slicePath.lineTo(math.cos(i) * radius, math.sin(i) * radius);
    }
    slicePath.lineTo(math.cos(sliceAngle) * radius, math.sin(sliceAngle) * radius);
    slicePath.close();
    
    canvas.clipPath(slicePath);
    
    // Now draw organic shifting blobs inside the slice
    // They move based on time!
    
    // Blob 1
    final Paint paint1 = Paint()
      ..color = color1.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      
    final double b1x = math.sin(time * math.pi * 4) * radius * 0.4;
    final double b1y = math.cos(time * math.pi * 2) * radius * 0.4;
    canvas.drawCircle(Offset(b1x + radius * 0.3, b1y + radius * 0.2), radius * 0.3, paint1);
    
    // Blob 2
    final Paint paint2 = Paint()
      ..color = color2.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      
    final double b2x = math.cos(time * math.pi * 6) * radius * 0.5;
    final double b2y = math.sin(time * math.pi * 3) * radius * 0.5;
    canvas.drawCircle(Offset(b2x + radius * 0.6, b2y + radius * 0.5), radius * 0.2, paint2);
    
    // Draw some sharp geometric lines for contrast
    final Paint linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
      
    final Path geomPath = Path();
    geomPath.moveTo(0, 0);
    
    final double geomX = math.cos(time * 2 * math.pi) * radius * 0.8;
    final double geomY = math.sin(time * 4 * math.pi) * radius * 0.4;
    
    geomPath.lineTo(geomX, geomY);
    geomPath.lineTo(radius * 0.8, radius * 0.2);
    
    canvas.drawPath(geomPath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _KaleidoscopePainter oldDelegate) {
    return oldDelegate.time != time;
  }
}
