import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbLiquidCircularProgress extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final Color backgroundColor;
  final Color liquidColor;
  final Color borderColor;
  final double borderWidth;

  const SbLiquidCircularProgress({
    super.key,
    required this.progress,
    this.size = 150.0,
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.liquidColor = const Color(0xFF3498DB),
    this.borderColor = const Color(0xFF2980B9),
    this.borderWidth = 4.0,
  });

  @override
  State<SbLiquidCircularProgress> createState() => _SbLiquidCircularProgressState();
}

class _SbLiquidCircularProgressState extends State<SbLiquidCircularProgress> with SingleTickerProviderStateMixin {
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
          color: widget.borderColor,
          width: widget.borderWidth,
        ),
      ),
      // Clip to circle so the liquid doesn't spill out of the bounds
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Liquid Wave
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _LiquidCirclePainter(
                  progress: widget.progress.clamp(0.0, 1.0),
                  animationValue: _controller.value,
                  liquidColor: widget.liquidColor,
                ),
              );
            },
          ),
          
          // The text overlay indicating percentage
          Text(
            '${(widget.progress.clamp(0.0, 1.0) * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black45,
                  blurRadius: 4,
                  offset: Offset(1, 1),
                )
              ]
            ),
          )
        ],
      ),
    );
  }
}

class _LiquidCirclePainter extends CustomPainter {
  final double progress;
  final double animationValue;
  final Color liquidColor;

  _LiquidCirclePainter({
    required this.progress,
    required this.animationValue,
    required this.liquidColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = liquidColor
      ..style = PaintingStyle.fill;

    // Y coordinate of the water level (0 is top, size.height is bottom)
    // So if progress is 1.0, water level is 0. If progress is 0.0, water level is size.height.
    final waterLevel = size.height - (size.height * progress);
    
    // If empty, draw nothing
    if (progress <= 0.0) return;
    
    // If completely full, just draw a rect (which will be clipped to circle by parent)
    if (progress >= 1.0) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      return;
    }

    final path = Path();
    
    // Start at bottom left of the water level
    path.moveTo(0, size.height);
    path.lineTo(0, waterLevel);
    
    // Draw the wavy top
    for (double i = 0; i <= size.width; i++) {
      // The wave height
      final waveHeight = size.height * 0.05;
      
      // Calculate two sine waves and combine them for a more organic sloshing effect
      // Wave 1
      final wave1 = math.sin((i / size.width * 2 * math.pi) + (animationValue * 2 * math.pi)) * waveHeight;
      // Wave 2 (faster, different phase)
      final wave2 = math.cos((i / size.width * 3 * math.pi) + (animationValue * 4 * math.pi)) * (waveHeight * 0.5);
      
      path.lineTo(i, waterLevel + wave1 + wave2);
    }
    
    // Finish path at bottom right
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidCirclePainter oldDelegate) {
    return oldDelegate.progress != progress || 
           oldDelegate.animationValue != animationValue ||
           oldDelegate.liquidColor != liquidColor;
  }
}
