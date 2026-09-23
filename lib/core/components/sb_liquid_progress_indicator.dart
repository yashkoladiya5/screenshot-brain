import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbLiquidProgressIndicator extends StatefulWidget {
  final double value; // 0.0 to 1.0
  final double width;
  final double height;
  final Color liquidColor;
  final Color backgroundColor;
  final TextStyle? textStyle;

  const SbLiquidProgressIndicator({
    super.key,
    required this.value,
    this.width = 150.0,
    this.height = 150.0,
    this.liquidColor = const Color(0xFF00C6FF),
    this.backgroundColor = const Color(0xFFEEEEEE),
    this.textStyle,
  });

  @override
  State<SbLiquidProgressIndicator> createState() => _SbLiquidProgressIndicatorState();
}

class _SbLiquidProgressIndicatorState extends State<SbLiquidProgressIndicator> with SingleTickerProviderStateMixin {
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
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ]
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Liquid Wave
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _LiquidProgressPainter(
                    value: widget.value,
                    animationValue: _controller.value,
                    color: widget.liquidColor,
                  ),
                );
              },
            ),
          ),
          
          // The percentage text
          Text(
            '${(widget.value * 100).toInt()}%',
            style: widget.textStyle ?? const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiquidProgressPainter extends CustomPainter {
  final double value;
  final double animationValue;
  final Color color;

  _LiquidProgressPainter({
    required this.value,
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (value <= 0.0) return;
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Calculate the Y level of the liquid (inverted because Y goes down)
    final double liquidY = size.height * (1.0 - value.clamp(0.0, 1.0));
    
    path.moveTo(0, size.height); // Start bottom left
    path.lineTo(0, liquidY); // Go up to liquid level
    
    // Draw the waves across the surface
    for (double i = 0; i <= size.width; i++) {
      // Create organic movement using overlapping sine/cosine waves
      final double wave1 = math.sin((i / size.width * 2 * math.pi) + (animationValue * 2 * math.pi)) * 8.0;
      final double wave2 = math.cos((i / size.width * 3 * math.pi) + (animationValue * 4 * math.pi)) * 4.0;
      
      // If we are at 100%, no waves (completely full)
      final double currentWaveAmplitude = value >= 1.0 ? 0.0 : 1.0;
      
      path.lineTo(i, liquidY + ((wave1 + wave2) * currentWaveAmplitude));
    }
    
    path.lineTo(size.width, size.height); // Drop down to bottom right
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidProgressPainter oldDelegate) {
    return oldDelegate.value != value || 
           oldDelegate.animationValue != animationValue ||
           oldDelegate.color != color;
  }
}
