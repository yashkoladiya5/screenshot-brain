import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbQuantumLoadingSpinner extends StatefulWidget {
  final double size;
  final Color coreColor;
  final Color orbitalColor1;
  final Color orbitalColor2;
  final int electronCount;

  const SbQuantumLoadingSpinner({
    super.key,
    this.size = 120.0,
    this.coreColor = const Color(0xFFE91E63), // Pink core
    this.orbitalColor1 = const Color(0xFF00E5FF), // Cyan orbit
    this.orbitalColor2 = const Color(0xFF7C4DFF), // Purple orbit
    this.electronCount = 5, // Number of electrons per orbital path
  });

  @override
  State<SbQuantumLoadingSpinner> createState() => _SbQuantumLoadingSpinnerState();
}

class _SbQuantumLoadingSpinnerState extends State<SbQuantumLoadingSpinner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000), // One full cycle every 3 seconds
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _QuantumPainter(
              time: _controller.value,
              coreColor: widget.coreColor,
              orbitalColor1: widget.orbitalColor1,
              orbitalColor2: widget.orbitalColor2,
              electronCount: widget.electronCount,
            ),
          );
        },
      ),
    );
  }
}

class _QuantumPainter extends CustomPainter {
  final double time;
  final Color coreColor;
  final Color orbitalColor1;
  final Color orbitalColor2;
  final int electronCount;

  _QuantumPainter({
    required this.time,
    required this.coreColor,
    required this.orbitalColor1,
    required this.orbitalColor2,
    required this.electronCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2;
    
    // Draw the pulsing quantum core
    _drawCore(canvas, center, radius);
    
    // Draw complex 3D orbital paths
    _drawOrbitalRing(canvas, center, radius, time * 2, orbitalColor1, isVertical: true);
    _drawOrbitalRing(canvas, center, radius, time * -3, orbitalColor2, isVertical: false);
    _drawOrbitalRing(canvas, center, radius, time * 4, orbitalColor1.withValues(alpha: 0.5), angleOffset: math.pi / 4);
    _drawOrbitalRing(canvas, center, radius, time * -2.5, orbitalColor2.withValues(alpha: 0.5), angleOffset: -math.pi / 4);
  }

  void _drawCore(Canvas canvas, Offset center, double maxRadius) {
    // Pulse math using multiple sine waves for organic breathing
    final double pulse = (math.sin(time * math.pi * 8) * 0.2) + 
                         (math.sin(time * math.pi * 12) * 0.1);
                         
    final double coreRadius = maxRadius * 0.2 * (1.0 + pulse);
    
    // Solid inner core
    final Paint corePaint = Paint()
      ..color = coreColor
      ..style = PaintingStyle.fill;
      
    // Glowing aura
    final Paint glowPaint = Paint()
      ..color = coreColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      
    canvas.drawCircle(center, coreRadius * 2, glowPaint);
    canvas.drawCircle(center, coreRadius, corePaint);
  }

  void _drawOrbitalRing(Canvas canvas, Offset center, double maxRadius, double timeShift, Color color, {bool isVertical = false, double angleOffset = 0.0}) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    
    // Rotate the entire orbital ring in 2D space based on its offset
    if (angleOffset != 0.0) {
      canvas.rotate(angleOffset);
    }
    
    // Draw the faint electron path
    final Paint pathPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
      
    // Calculate 3D perspective ellipse for the path
    final Rect pathRect = isVertical 
      ? Rect.fromCenter(center: Offset.zero, width: maxRadius * 0.5, height: maxRadius * 1.8)
      : Rect.fromCenter(center: Offset.zero, width: maxRadius * 1.8, height: maxRadius * 0.5);
      
    canvas.drawOval(pathRect, pathPaint);
    
    // Draw the electrons orbiting on this path
    final Paint electronPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    final Paint electronGlowPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    // Spread the electrons evenly along the orbital path
    final double angleStep = (2 * math.pi) / electronCount;
    
    for (int i = 0; i < electronCount; i++) {
      // Current angle of this specific electron (base angle + time shift for orbit)
      final double currentAngle = (i * angleStep) + (timeShift * 2 * math.pi);
      
      // Parametric equation for an ellipse
      final double ellipseWidth = isVertical ? maxRadius * 0.25 : maxRadius * 0.9;
      final double ellipseHeight = isVertical ? maxRadius * 0.9 : maxRadius * 0.25;
      
      final double ex = math.cos(currentAngle) * ellipseWidth;
      final double ey = math.sin(currentAngle) * ellipseHeight;
      
      // Calculate depth (Z-axis) to simulate 3D scale and opacity
      // If it's vertical, the Y axis represents depth. If horizontal, the X axis.
      // But actually, we need a 3rd dimension. 
      // A simple trick: use the sine/cosine of the angle.
      // 1.0 is closest to camera (large, opaque). -1.0 is farthest (small, transparent).
      final double depth = isVertical ? math.cos(currentAngle) : math.sin(currentAngle);
      
      // Map depth (-1 to 1) to scale (0.5 to 1.5) and opacity (0.2 to 1.0)
      final double scale = 1.0 + (depth * 0.5);
      final double opacity = 0.6 + (depth * 0.4);
      
      // Don't draw if it's completely behind the core (depth < -0.8) to simulate occlusion
      if (depth > -0.8) {
        final double electronRadius = 3.0 * scale;
        
        electronPaint.color = color.withValues(alpha: opacity);
        
        canvas.drawCircle(Offset(ex, ey), electronRadius * 2, electronGlowPaint);
        canvas.drawCircle(Offset(ex, ey), electronRadius, electronPaint);
      }
    }
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _QuantumPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}
