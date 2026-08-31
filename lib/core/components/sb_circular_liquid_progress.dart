import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbCircularLiquidProgress extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final Color waveColor;
  final Color backgroundColor;

  const SbCircularLiquidProgress({
    super.key,
    required this.progress,
    this.size = 150.0,
    this.waveColor = Colors.cyan,
    this.backgroundColor = Colors.black12,
  });

  @override
  State<SbCircularLiquidProgress> createState() => _SbCircularLiquidProgressState();
}

class _SbCircularLiquidProgressState extends State<SbCircularLiquidProgress> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.backgroundColor,
        border: Border.all(
          color: widget.waveColor.withValues(alpha: 0.5),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.waveColor.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ]
      ),
      child: ClipOval(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _LiquidPainter(
                animationValue: _controller.value,
                progress: widget.progress,
                color: widget.waveColor,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LiquidPainter extends CustomPainter {
  final double animationValue;
  final double progress;
  final Color color;

  _LiquidPainter({
    required this.animationValue,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double fillY = size.height - (size.height * progress.clamp(0.0, 1.0));
    
    final backPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    _drawWave(canvas, size, backPaint, animationValue * 2 * math.pi, 8.0, fillY);
    
    final frontPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    _drawWave(canvas, size, frontPaint, (animationValue + 0.3) * 2 * math.pi, 12.0, fillY + 2);
  }
  
  void _drawWave(Canvas canvas, Size size, Paint paint, double phase, double amplitude, double fillY) {
    if (progress == 0) return;
    if (progress == 1) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      return;
    }

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, fillY);

    for (double x = 0; x <= size.width; x++) {
      final double normalizedX = (x / size.width) * 2 * math.pi;
      final double y = fillY + math.sin(normalizedX + phase) * amplitude;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || 
           oldDelegate.progress != progress ||
           oldDelegate.color != color;
  }
}
