import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../design/tokens.dart';

class SbBarChart3DData {
  final String label;
  final double value;
  final Color? color;

  const SbBarChart3DData({
    required this.label,
    required this.value,
    this.color,
  });
}

class SbBarChart3D extends StatelessWidget {
  final List<SbBarChart3DData> data;
  final double height;
  final double maxValue;
  final double barWidth;
  final double depth;

  const SbBarChart3D({
    super.key,
    required this.data,
    this.height = 250.0,
    required this.maxValue,
    this.barWidth = 40.0,
    this.depth = 15.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: data.map((item) {
          final percentage = (item.value / maxValue).clamp(0.0, 1.0);
          final barHeight = percentage * (height - 40); // 40 for label
          
          final baseColor = item.color ?? theme.colorScheme.primary;
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Value label
              Text(
                item.value.toStringAsFixed(0),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              
              // 3D Bar
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: barHeight),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutElastic,
                builder: (context, val, child) {
                  return SizedBox(
                    width: barWidth + depth,
                    height: val + depth,
                    child: CustomPaint(
                      painter: _Bar3DPainter(
                        color: baseColor,
                        barWidth: barWidth,
                        barHeight: val,
                        depth: depth,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 8),
              // Bottom label
              Text(
                item.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _Bar3DPainter extends CustomPainter {
  final Color color;
  final double barWidth;
  final double barHeight;
  final double depth;

  _Bar3DPainter({
    required this.color,
    required this.barWidth,
    required this.barHeight,
    required this.depth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (barHeight <= 0) return;

    // Calculate darker/lighter shades
    final hsl = HSLColor.fromColor(color);
    final topColor = hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0)).toColor();
    final rightColor = hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();

    // 1. Front Face
    final frontPaint = Paint()..color = color;
    final frontRect = Rect.fromLTWH(0, depth, barWidth, barHeight);
    canvas.drawRect(frontRect, frontPaint);

    // 2. Top Face
    final topPaint = Paint()..color = topColor;
    final topPath = Path()
      ..moveTo(0, depth)
      ..lineTo(depth, 0)
      ..lineTo(barWidth + depth, 0)
      ..lineTo(barWidth, depth)
      ..close();
    canvas.drawPath(topPath, topPaint);

    // 3. Right Face
    final rightPaint = Paint()..color = rightColor;
    final rightPath = Path()
      ..moveTo(barWidth, depth)
      ..lineTo(barWidth + depth, 0)
      ..lineTo(barWidth + depth, barHeight)
      ..lineTo(barWidth, barHeight + depth)
      ..close();
    canvas.drawPath(rightPath, rightPaint);
  }

  @override
  bool shouldRepaint(covariant _Bar3DPainter oldDelegate) {
    return oldDelegate.barHeight != barHeight || 
           oldDelegate.color != color;
  }
}
