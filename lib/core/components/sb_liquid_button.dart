import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../design/tokens.dart';

class SbLiquidButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  final Color baseColor;
  final Color liquidColor;
  final double width;
  final double height;

  const SbLiquidButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.baseColor = Colors.blue,
    this.liquidColor = Colors.lightBlueAccent,
    this.width = 200.0,
    this.height = 60.0,
  });

  @override
  State<SbLiquidButton> createState() => _SbLiquidButtonState();
}

class _SbLiquidButtonState extends State<SbLiquidButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
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
      onTap: widget.onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.height / 2),
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            children: [
              // Background
              Container(color: widget.baseColor),
              
              // Animated Liquid waves
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _LiquidWavePainter(
                      progress: _controller.value,
                      color: widget.liquidColor,
                    ),
                    size: Size(widget.width, widget.height),
                  );
                },
              ),
              
              // Text
              Center(
                child: Text(
                  widget.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiquidWavePainter extends CustomPainter {
  final double progress;
  final Color color;

  _LiquidWavePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // Draw two waves overlapping
    _drawWave(canvas, size, paint, progress * 2 * math.pi, 10.0, size.height * 0.4);
    
    final solidPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    _drawWave(canvas, size, solidPaint, (progress + 0.5) * 2 * math.pi, 8.0, size.height * 0.5);
  }

  void _drawWave(Canvas canvas, Size size, Paint paint, double phase, double amplitude, double fillY) {
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, fillY);

    for (double x = 0; x <= size.width; x++) {
      final normalizedX = (x / size.width) * 2 * math.pi;
      final y = fillY + math.sin(normalizedX + phase) * amplitude;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidWavePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
