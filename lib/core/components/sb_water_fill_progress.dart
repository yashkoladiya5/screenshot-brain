import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbWaterFillProgress extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final Color waterColor;
  final Color backgroundColor;
  final TextStyle? textStyle;

  const SbWaterFillProgress({
    super.key,
    required this.progress,
    this.size = 150.0,
    this.waterColor = Colors.cyanAccent,
    this.backgroundColor = const Color(0xFF1E1E1E),
    this.textStyle,
  }) : assert(progress >= 0.0 && progress <= 1.0);

  @override
  State<SbWaterFillProgress> createState() => _SbWaterFillProgressState();
}

class _SbWaterFillProgressState extends State<SbWaterFillProgress> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
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
    final theme = Theme.of(context);
    final style = widget.textStyle ?? theme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: widget.waterColor.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 2,
          )
        ],
      ),
      child: ClipOval(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Water Waves
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _WaterWavePainter(
                    progress: widget.progress,
                    animationValue: _controller.value,
                    color: widget.waterColor,
                  ),
                  size: Size(widget.size, widget.size),
                );
              },
            ),
            
            // Percentage Text
            Text(
              '${(widget.progress * 100).toInt()}%',
              style: style,
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterWavePainter extends CustomPainter {
  final double progress;
  final double animationValue;
  final Color color;

  _WaterWavePainter({
    required this.progress,
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // We will draw two overlapping sine waves to simulate liquid
    
    // Wave parameters
    final double waveHeight = 10.0;
    
    // Map progress (0-1) to Y coordinate (height -> 0)
    final double fillY = size.height - (progress * size.height);
    
    // Draw back wave (lighter, moving slower, offset phase)
    _drawWave(
      canvas: canvas, 
      size: size, 
      fillY: fillY, 
      waveHeight: waveHeight * 1.2, 
      phase: (animationValue * 2 * math.pi) + math.pi, // Offset by Pi
      frequency: 1.5,
      color: color.withValues(alpha: 0.5),
    );

    // Draw front wave (solid, moving faster)
    _drawWave(
      canvas: canvas, 
      size: size, 
      fillY: fillY, 
      waveHeight: waveHeight, 
      phase: (animationValue * 2 * math.pi * 1.5), // Moves 1.5x faster
      frequency: 2.0,
      color: color,
    );
  }
  
  void _drawWave({
    required Canvas canvas,
    required Size size,
    required double fillY,
    required double waveHeight,
    required double phase,
    required double frequency,
    required Color color,
  }) {
    final Path path = Path();
    
    // Start at bottom left
    path.moveTo(0, size.height);
    // Line to start of wave on the left edge
    path.lineTo(0, fillY);
    
    // Draw the sine wave across the width
    for (double x = 0; x <= size.width; x++) {
      // Normalize X to 0-1, multiply by frequency * 2Pi to get full sine cycles
      final double normalizedX = (x / size.width) * frequency * 2 * math.pi;
      
      // Calculate Y using sine function
      // Y = BaseHeight + Sin(X + Phase) * Amplitude
      final double y = fillY + math.sin(normalizedX + phase) * waveHeight;
      
      path.lineTo(x, y);
    }
    
    // Close the path to bottom right and back to bottom left
    path.lineTo(size.width, size.height);
    path.close();
    
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _WaterWavePainter oldDelegate) {
    return oldDelegate.progress != progress || 
           oldDelegate.animationValue != animationValue ||
           oldDelegate.color != color;
  }
}
