import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbWaveAnimation extends StatefulWidget {
  final double height;
  final Color color;
  final double speed;
  final double amplitude;
  final double waveFrequency;

  const SbWaveAnimation({
    super.key,
    this.height = 100.0,
    required this.color,
    this.speed = 1.0,
    this.amplitude = 15.0,
    this.waveFrequency = 1.5,
  });

  @override
  State<SbWaveAnimation> createState() => _SbWaveAnimationState();
}

class _SbWaveAnimationState extends State<SbWaveAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (2000 / widget.speed).round()),
    )..repeat();
  }

  @override
  void didUpdateWidget(SbWaveAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.speed != oldWidget.speed) {
      _controller.duration = Duration(milliseconds: (2000 / widget.speed).round());
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _WavePainter(
              animationValue: _controller.value,
              color: widget.color,
              amplitude: widget.amplitude,
              waveFrequency: widget.waveFrequency,
            ),
          );
        },
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final double amplitude;
  final double waveFrequency;

  _WavePainter({
    required this.animationValue,
    required this.color,
    required this.amplitude,
    required this.waveFrequency,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Start at bottom left
    path.moveTo(0, size.height);
    
    // Line to top left (starting point of wave)
    path.lineTo(0, size.height - amplitude);

    // Draw the sine wave across the width
    for (double x = 0; x <= size.width; x++) {
      // Calculate y based on sine function
      // (x / size.width) normalizes x from 0 to 1
      // waveFrequency determines how many full waves fit in the width
      // animationValue shifts the phase for animation
      final double normalizedX = x / size.width;
      final double phaseShift = animationValue * math.pi * 2;
      
      final double y = size.height - amplitude - 
          (math.sin((normalizedX * math.pi * 2 * waveFrequency) + phaseShift) * amplitude);
          
      path.lineTo(x, y);
    }

    // Line to bottom right
    path.lineTo(size.width, size.height);
    
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.color != color ||
           oldDelegate.amplitude != amplitude ||
           oldDelegate.waveFrequency != waveFrequency;
  }
}
