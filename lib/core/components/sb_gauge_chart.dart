import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../design/tokens.dart';

class SbGaugeChart extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color? activeColor;
  final Color? backgroundColor;
  final String? label;

  const SbGaugeChart({
    super.key,
    required this.value,
    this.size = 200.0,
    this.strokeWidth = 20.0,
    this.activeColor,
    this.backgroundColor,
    this.label,
  }) : assert(value >= 0.0 && value <= 1.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final active = activeColor ?? colorScheme.primary;
    final bg = backgroundColor ?? colorScheme.surfaceContainerHighest;

    return SizedBox(
      width: size,
      height: size / 2 + strokeWidth, // Half circle height + stroke
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CustomPaint(
            size: Size(size, size / 2),
            painter: _GaugePainter(
              value: value,
              activeColor: active,
              backgroundColor: bg,
              strokeWidth: strokeWidth,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: strokeWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(value * 100).toInt()}%',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (label != null)
                  Text(
                    label!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color activeColor;
  final Color backgroundColor;
  final double strokeWidth;

  _GaugePainter({
    required this.value,
    required this.activeColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background track (Semi-circle from pi to 2pi)
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );

    // Draw active track
    if (value > 0) {
      final sweepAngle = math.pi * value;
      
      final activePaint = Paint()
        ..color = activeColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi,
        sweepAngle,
        false,
        activePaint,
      );
      
      // Draw inner glow
      final glowPaint = Paint()
        ..color = activeColor.withValues(alpha: 0.3)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
        
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi,
        sweepAngle,
        false,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.value != value ||
           oldDelegate.activeColor != activeColor ||
           oldDelegate.backgroundColor != backgroundColor ||
           oldDelegate.strokeWidth != strokeWidth;
  }
}
