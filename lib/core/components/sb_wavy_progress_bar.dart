import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbWavyProgressBar extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final double width;
  final double height;
  final Color backgroundColor;
  final Color waveColor;

  const SbWavyProgressBar({
    super.key,
    required this.progress,
    this.width = double.infinity,
    this.height = 30.0,
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.waveColor = const Color(0xFF4CAF50),
  });

  @override
  State<SbWavyProgressBar> createState() => _SbWavyProgressBarState();
}

class _SbWavyProgressBarState extends State<SbWavyProgressBar> with SingleTickerProviderStateMixin {
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
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(widget.height / 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _WavePainter(
              progress: widget.progress.clamp(0.0, 1.0),
              animationValue: _controller.value,
              waveColor: widget.waveColor,
            ),
          );
        },
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final double animationValue;
  final Color waveColor;

  _WavePainter({
    required this.progress,
    required this.animationValue,
    required this.waveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // The width of the filled portion
    final fillWidth = size.width * progress;
    
    // If progress is 0, don't draw anything
    if (fillWidth <= 0) return;

    path.moveTo(0, size.height); // Start bottom left
    path.lineTo(0, 0); // Up to top left
    
    // Draw the top edge, waving
    for (double i = 0; i <= fillWidth; i++) {
      // The wave height is small relative to the bar
      final waveHeight = size.height * 0.15;
      // We use sin wave moving backwards (animationValue * 2pi)
      final waveY = math.sin((i / size.width * 4 * math.pi) - (animationValue * 2 * math.pi)) * waveHeight;
      // We offset by waveHeight so it doesn't clip top edge, or just center it
      path.lineTo(i, waveHeight + waveY);
    }

    path.lineTo(fillWidth, size.height); // Down to bottom right of filled section
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.progress != progress || 
           oldDelegate.animationValue != animationValue ||
           oldDelegate.waveColor != waveColor;
  }
}
