import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../design/tokens.dart';

class SbRadarChartData {
  final String label;
  final double value; // 0.0 to 1.0

  const SbRadarChartData({
    required this.label,
    required this.value,
  }) : assert(value >= 0.0 && value <= 1.0);
}

class SbRadarChart extends StatelessWidget {
  final List<SbRadarChartData> data;
  final double size;
  final Color? activeColor;
  final Color? gridColor;
  final int gridSteps;

  const SbRadarChart({
    super.key,
    required this.data,
    this.size = 250.0,
    this.activeColor,
    this.gridColor,
    this.gridSteps = 4,
  }) : assert(data.length >= 3, 'Radar chart requires at least 3 data points');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final active = activeColor ?? colorScheme.primary;
    final grid = gridColor ?? colorScheme.outlineVariant.withValues(alpha: 0.5);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _RadarChartPainter(
          data: data,
          activeColor: active,
          gridColor: grid,
          gridSteps: gridSteps,
          textStyle: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ) ?? const TextStyle(),
        ),
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final List<SbRadarChartData> data;
  final Color activeColor;
  final Color gridColor;
  final int gridSteps;
  final TextStyle textStyle;

  _RadarChartPainter({
    required this.data,
    required this.activeColor,
    required this.gridColor,
    required this.gridSteps,
    required this.textStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Leave room for text labels
    final radius = (size.width / 2) * 0.75;
    final angleStep = (2 * math.pi) / data.length;

    // 1. Draw Grid Web
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int step = 1; step <= gridSteps; step++) {
      final stepRadius = radius * (step / gridSteps);
      final path = Path();
      
      for (int i = 0; i < data.length; i++) {
        final angle = -math.pi / 2 + (i * angleStep);
        final x = center.dx + stepRadius * math.cos(angle);
        final y = center.dy + stepRadius * math.sin(angle);
        
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // 2. Draw Spokes
    for (int i = 0; i < data.length; i++) {
      final angle = -math.pi / 2 + (i * angleStep);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), gridPaint);
    }

    // 3. Draw Data Polygon
    final dataPath = Path();
    for (int i = 0; i < data.length; i++) {
      final angle = -math.pi / 2 + (i * angleStep);
      final dataRadius = radius * data[i].value;
      final x = center.dx + dataRadius * math.cos(angle);
      final y = center.dy + dataRadius * math.sin(angle);
      
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();

    // Fill data polygon
    final fillPaint = Paint()
      ..color = activeColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawPath(dataPath, fillPaint);

    // Stroke data polygon
    final strokePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(dataPath, strokePaint);

    // Draw data points
    final pointPaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;
    for (int i = 0; i < data.length; i++) {
      final angle = -math.pi / 2 + (i * angleStep);
      final dataRadius = radius * data[i].value;
      final x = center.dx + dataRadius * math.cos(angle);
      final y = center.dy + dataRadius * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 4.0, pointPaint);
      
      // Draw white center
      canvas.drawCircle(Offset(x, y), 2.0, Paint()..color = Colors.white);
    }

    // 4. Draw Labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < data.length; i++) {
      final angle = -math.pi / 2 + (i * angleStep);
      // Push text outside the maximum radius
      final labelRadius = radius * 1.25; 
      final x = center.dx + labelRadius * math.cos(angle);
      final y = center.dy + labelRadius * math.sin(angle);

      textPainter.text = TextSpan(text: data[i].label, style: textStyle);
      textPainter.layout();
      
      // Center the text on the calculated coordinate
      textPainter.paint(
        canvas, 
        Offset(x - (textPainter.width / 2), y - (textPainter.height / 2)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) {
    return oldDelegate.data != data ||
           oldDelegate.activeColor != activeColor ||
           oldDelegate.gridColor != gridColor ||
           oldDelegate.gridSteps != gridSteps;
  }
}
