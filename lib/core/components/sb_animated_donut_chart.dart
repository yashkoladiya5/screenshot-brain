import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbDonutChartItem {
  final double value;
  final Color color;
  final String label;

  SbDonutChartItem({
    required this.value,
    required this.color,
    required this.label,
  });
}

class SbAnimatedDonutChart extends StatefulWidget {
  final List<SbDonutChartItem> items;
  final double radius;
  final double holeRadius;
  final Duration animationDuration;

  const SbAnimatedDonutChart({
    super.key,
    required this.items,
    this.radius = 120.0,
    this.holeRadius = 60.0,
    this.animationDuration = const Duration(milliseconds: 1200),
  });

  @override
  State<SbAnimatedDonutChart> createState() => _SbAnimatedDonutChartState();
}

class _SbAnimatedDonutChartState extends State<SbAnimatedDonutChart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(SbAnimatedDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(Offset localPosition, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Offset relativePosition = localPosition - center;
    
    final double distance = relativePosition.distance;
    if (distance < widget.holeRadius || distance > widget.radius + 20) {
      if (_hoveredIndex != null) {
        setState(() => _hoveredIndex = null);
      }
      return;
    }

    double angle = math.atan2(relativePosition.dy, relativePosition.dx);
    angle = (angle + math.pi / 2) % (2 * math.pi);
    if (angle < 0) angle += 2 * math.pi;

    double totalValue = widget.items.fold(0, (sum, item) => sum + item.value);
    if (totalValue == 0) return;

    double currentAngle = 0;
    for (int i = 0; i < widget.items.length; i++) {
      final double sweepAngle = (widget.items[i].value / totalValue) * 2 * math.pi;
      if (angle >= currentAngle && angle <= currentAngle + sweepAngle) {
        if (_hoveredIndex != i) {
          setState(() => _hoveredIndex = i);
        }
        return;
      }
      currentAngle += sweepAngle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double widgetSize = widget.radius * 2 + 40; 

    return GestureDetector(
      onPanDown: (details) => _onPanUpdate(details.localPosition, Size(widgetSize, widgetSize)),
      onPanUpdate: (details) => _onPanUpdate(details.localPosition, Size(widgetSize, widgetSize)),
      onPanEnd: (_) => setState(() => _hoveredIndex = null),
      onPanCancel: () => setState(() => _hoveredIndex = null),
      child: SizedBox(
        width: widgetSize,
        height: widgetSize,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: Size(widgetSize, widgetSize),
              painter: _DonutChartPainter(
                items: widget.items,
                animationValue: Curves.easeOutCubic.transform(_controller.value),
                hoveredIndex: _hoveredIndex,
                radius: widget.radius,
                holeRadius: widget.holeRadius,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<SbDonutChartItem> items;
  final double animationValue;
  final int? hoveredIndex;
  final double radius;
  final double holeRadius;

  _DonutChartPainter({
    required this.items,
    required this.animationValue,
    required this.hoveredIndex,
    required this.radius,
    required this.holeRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double totalValue = items.fold(0, (sum, item) => sum + item.value);
    
    if (totalValue == 0) return;

    double currentAngle = -math.pi / 2; 

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final double sweepAngle = (item.value / totalValue) * 2 * math.pi;
      final double animatedSweepAngle = sweepAngle * animationValue;

      final bool isHovered = i == hoveredIndex;
      final double currentOuterRadius = isHovered ? radius + 15 : radius;
      
      final Paint paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.fill;

      final Path path = Path();
      
      path.moveTo(
        center.dx + holeRadius * math.cos(currentAngle),
        center.dy + holeRadius * math.sin(currentAngle),
      );
      
      path.lineTo(
        center.dx + currentOuterRadius * math.cos(currentAngle),
        center.dy + currentOuterRadius * math.sin(currentAngle),
      );
      
      path.arcTo(
        Rect.fromCircle(center: center, radius: currentOuterRadius),
        currentAngle,
        animatedSweepAngle,
        false,
      );
      
      path.lineTo(
        center.dx + holeRadius * math.cos(currentAngle + animatedSweepAngle),
        center.dy + holeRadius * math.sin(currentAngle + animatedSweepAngle),
      );
      
      path.arcTo(
        Rect.fromCircle(center: center, radius: holeRadius),
        currentAngle + animatedSweepAngle,
        -animatedSweepAngle, 
        false,
      );
      
      path.close();
      
      if (isHovered) {
        canvas.drawShadow(path, Colors.black, 8, true);
      }
      
      canvas.drawPath(path, paint);

      currentAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.hoveredIndex != hoveredIndex ||
           oldDelegate.items != items;
  }
}
