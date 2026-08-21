import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbWaveProgress extends StatefulWidget {
  final double size;
  final double progress; // 0.0 to 1.0
  final Color? color;
  final Color? backgroundColor;

  const SbWaveProgress({
    super.key,
    this.size = 100.0,
    required this.progress,
    this.color,
    this.backgroundColor,
  }) : assert(progress >= 0.0 && progress <= 1.0);

  @override
  State<SbWaveProgress> createState() => _SbWaveProgressState();
}

class _SbWaveProgressState extends State<SbWaveProgress> with SingleTickerProviderStateMixin {
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
    final theme = Theme.of(context);
    final waveColor = widget.color ?? theme.colorScheme.primary;
    final bgColor = widget.backgroundColor ?? theme.colorScheme.surfaceContainerHighest;

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: Border.all(
          color: waveColor.withValues(alpha: 0.3),
          width: 4.0,
        ),
      ),
      child: ClipOval(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _WavePainter(
                progress: widget.progress,
                animationValue: _controller.value,
                color: waveColor,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final double animationValue;
  final Color color;

  _WavePainter({
    required this.progress,
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0.0) return;
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    if (progress == 1.0) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      return;
    }

    final path = Path();
    final waveHeight = size.height * 0.05;
    final baseHeight = size.height * (1.0 - progress);

    path.moveTo(0, size.height);
    path.lineTo(0, baseHeight);

    for (double i = 0.0; i < size.width; i++) {
      // Create two sine waves offset slightly and combine them for a more organic look
      final wave1 = math.sin((i / size.width * 2 * math.pi) + (animationValue * 2 * math.pi));
      final wave2 = math.cos((i / size.width * math.pi) + (animationValue * 2 * math.pi));
      
      path.lineTo(i, baseHeight + (wave1 + wave2) * waveHeight);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.progress != progress || 
           oldDelegate.animationValue != animationValue ||
           oldDelegate.color != color;
  }
}
