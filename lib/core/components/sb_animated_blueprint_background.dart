import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbAnimatedBlueprintBackground extends StatefulWidget {
  final Widget child;
  final Color blueprintColor;
  final Color lineColor;
  final double gridSpacing;

  const SbAnimatedBlueprintBackground({
    super.key,
    required this.child,
    this.blueprintColor = const Color(0xFF0F2027), // Dark navy blueprint
    this.lineColor = const Color(0xFF203A43), // Lighter blue lines
    this.gridSpacing = 40.0,
  });

  @override
  State<SbAnimatedBlueprintBackground> createState() => _SbAnimatedBlueprintBackgroundState();
}

class _SbAnimatedBlueprintBackgroundState extends State<SbAnimatedBlueprintBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // The animation simulates a camera panning over an infinite blueprint
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
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
      fit: StackFit.expand,
      children: [
        // The Blueprint Background
        Container(
          color: widget.blueprintColor,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _BlueprintPainter(
                  time: _controller.value,
                  lineColor: widget.lineColor,
                  gridSpacing: widget.gridSpacing,
                ),
              );
            }
          ),
        ),
        
        // The overlay content
        widget.child,
      ],
    );
  }
}

class _BlueprintPainter extends CustomPainter {
  final double time; // 0.0 to 1.0
  final Color lineColor;
  final double gridSpacing;

  _BlueprintPainter({
    required this.time,
    required this.lineColor,
    required this.gridSpacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint thinPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
      
    final Paint thickPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
      
    final Paint highlightPaint = Paint()
      ..color = Colors.cyan.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Simulate panning camera by offsetting the grid based on time
    // We offset by exactly one gridSpacing over the full animation cycle
    // so it loops perfectly seamlessly
    final double offsetX = (time * gridSpacing) % gridSpacing;
    final double offsetY = (time * gridSpacing * 0.5) % gridSpacing;

    // 1. Draw the grid
    
    // Vertical lines
    for (double x = -gridSpacing + offsetX; x <= size.width + gridSpacing; x += gridSpacing) {
      // Every 5th line is thicker
      bool isMajor = ((x - offsetX) / gridSpacing).round() % 5 == 0;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), isMajor ? thickPaint : thinPaint);
    }
    
    // Horizontal lines
    for (double y = -gridSpacing + offsetY; y <= size.height + gridSpacing; y += gridSpacing) {
      bool isMajor = ((y - offsetY) / gridSpacing).round() % 5 == 0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), isMajor ? thickPaint : thinPaint);
    }
    
    // 2. Draw mathematical blueprint elements
    // We'll draw some circles and angles that slowly rotate
    
    canvas.save();
    canvas.translate(size.width * 0.2, size.height * 0.3);
    canvas.rotate(time * math.pi * 2);
    
    // A large technical circle
    canvas.drawCircle(Offset.zero, gridSpacing * 3, thinPaint);
    canvas.drawCircle(Offset.zero, gridSpacing * 2.8, thickPaint);
    
    // Crosshairs
    canvas.drawLine(Offset(-gridSpacing * 3.5, 0), Offset(gridSpacing * 3.5, 0), highlightPaint);
    canvas.drawLine(Offset(0, -gridSpacing * 3.5), Offset(0, gridSpacing * 3.5), highlightPaint);
    
    // Measurements / Hash marks along the edge of the circle
    for (int i = 0; i < 36; i++) {
      final double angle = i * (math.pi * 2 / 36);
      final double innerR = i % 9 == 0 ? gridSpacing * 2.5 : gridSpacing * 2.7;
      final double outerR = gridSpacing * 2.8;
      
      canvas.drawLine(
        Offset(math.cos(angle) * innerR, math.sin(angle) * innerR),
        Offset(math.cos(angle) * outerR, math.sin(angle) * outerR),
        thinPaint
      );
    }
    
    canvas.restore();
    
    // Draw a second set of technical elements elsewhere
    canvas.save();
    canvas.translate(size.width * 0.8, size.height * 0.8);
    // This one rotates backwards
    canvas.rotate(-time * math.pi * 2);
    
    // Connecting arc lines
    final Rect arcRect = Rect.fromCircle(center: Offset.zero, radius: gridSpacing * 4);
    canvas.drawArc(arcRect, 0, math.pi / 2, false, highlightPaint);
    canvas.drawArc(arcRect, math.pi, math.pi / 2, false, highlightPaint);
    
    // A polygon
    final Path polyPath = Path();
    for (int i = 0; i < 6; i++) {
      final double angle = i * (math.pi * 2 / 6);
      final double r = gridSpacing * 2;
      if (i == 0) {
        polyPath.moveTo(math.cos(angle) * r, math.sin(angle) * r);
      } else {
        polyPath.lineTo(math.cos(angle) * r, math.sin(angle) * r);
      }
    }
    polyPath.close();
    canvas.drawPath(polyPath, thickPaint);
    
    canvas.restore();
    
    // 3. Draw a "scanning" laser line across the blueprint
    // It moves up and down based on a sine wave
    final double scanY = size.height * 0.5 + math.sin(time * math.pi * 4) * size.height * 0.4;
    
    final Paint scanPaint = Paint()
      ..color = Colors.cyan.withValues(alpha: 0.5)
      ..strokeWidth = 2.0;
      
    canvas.drawLine(Offset(0, scanY), Offset(size.width, scanY), scanPaint);
    
    // Draw coordinates text near the scanline
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: 'Y: ${scanY.toStringAsFixed(2)}',
        style: TextStyle(
          color: Colors.cyan.withValues(alpha: 0.8),
          fontSize: 12,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(10, scanY - 20));
  }

  @override
  bool shouldRepaint(covariant _BlueprintPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}
