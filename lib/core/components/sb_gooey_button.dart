import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbGooeyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color color;
  final double width;
  final double height;

  const SbGooeyButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.color = Colors.deepPurpleAccent,
    this.width = 160.0,
    this.height = 60.0,
  });

  @override
  State<SbGooeyButton> createState() => _SbGooeyButtonState();
}

class _SbGooeyButtonState extends State<SbGooeyButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(widget.width, widget.height),
                  painter: _GooeyPainter(
                    animationValue: _controller.value,
                    color: widget.color,
                  ),
                );
              },
            ),
            widget.child,
          ],
        ),
      ),
    );
  }
}

class _GooeyPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _GooeyPainter({
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double width = size.width;
    final double height = size.height;

    // Use multiple sine waves at different phases to create an organic, morphing blob edge
    final double phase1 = animationValue * 2 * math.pi;
    final double phase2 = (animationValue * 2 * math.pi) * 1.5;

    final path = Path();

    // Start at top left
    path.moveTo(0, height / 2);
    
    // Top Edge
    for (double x = 0; x <= width; x++) {
      final double normalizedX = (x / width) * 2 * math.pi;
      // Wobble Y based on X and time
      final double yWobble = math.sin(normalizedX + phase1) * 3 + math.cos(normalizedX * 2 + phase2) * 2;
      path.lineTo(x, 0 + yWobble + 5); 
    }
    
    // Right Edge
    for (double y = 0; y <= height; y++) {
      final double normalizedY = (y / height) * 2 * math.pi;
      final double xWobble = math.cos(normalizedY + phase2) * 3 + math.sin(normalizedY * 2 + phase1) * 2;
      path.lineTo(width + xWobble - 5, y);
    }
    
    // Bottom Edge
    for (double x = width; x >= 0; x--) {
      final double normalizedX = (x / width) * 2 * math.pi;
      final double yWobble = math.sin(normalizedX + phase2) * 3 + math.cos(normalizedX * 2 + phase1) * 2;
      path.lineTo(x, height + yWobble - 5);
    }
    
    // Left Edge
    for (double y = height; y >= 0; y--) {
      final double normalizedY = (y / height) * 2 * math.pi;
      final double xWobble = math.cos(normalizedY + phase1) * 3 + math.sin(normalizedY * 2 + phase2) * 2;
      path.lineTo(0 + xWobble + 5, y);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GooeyPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.color != color;
  }
}
