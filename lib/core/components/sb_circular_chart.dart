import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../design/tokens.dart';

class SbCircularChartData {
  final double value;
  final Color color;
  final String? label;

  const SbCircularChartData({
    required this.value,
    required this.color,
    this.label,
  });
}

class SbCircularChart extends StatefulWidget {
  final List<SbCircularChartData> data;
  final double size;
  final double strokeWidth;
  final Widget? centerChild;
  final Duration animationDuration;
  final double gap; // Gap between segments in degrees

  const SbCircularChart({
    super.key,
    required this.data,
    this.size = 200.0,
    this.strokeWidth = 24.0,
    this.centerChild,
    this.animationDuration = const Duration(milliseconds: 1000),
    this.gap = 4.0,
  });

  @override
  State<SbCircularChart> createState() => _SbCircularChartState();
}

class _SbCircularChartState extends State<SbCircularChart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(SbCircularChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Simple re-trigger if data changes
    if (widget.data != oldWidget.data) {
      _controller.value = 0.0;
      _controller.forward();
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
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _CircularChartPainter(
                  data: widget.data,
                  progress: _animation.value,
                  strokeWidth: widget.strokeWidth,
                  gapDegrees: widget.gap,
                ),
              );
            },
          ),
          if (widget.centerChild != null)
            Container(
              width: widget.size - (widget.strokeWidth * 2) - 16,
              height: widget.size - (widget.strokeWidth * 2) - 16,
              alignment: Alignment.center,
              child: widget.centerChild!,
            ),
        ],
      ),
    );
  }
}

class _CircularChartPainter extends CustomPainter {
  final List<SbCircularChartData> data;
  final double progress;
  final double strokeWidth;
  final double gapDegrees;

  _CircularChartPainter({
    required this.data,
    required this.progress,
    required this.strokeWidth,
    required this.gapDegrees,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Calculate total value
    double total = 0;
    for (var d in data) {
      total += d.value;
    }
    if (total == 0) return;

    final gapRadians = (gapDegrees * math.pi) / 180.0;
    
    // If only one item, don't draw a gap
    final effectiveGap = data.length > 1 ? gapRadians : 0.0;
    
    // Calculate total sweep available (2pi minus gaps)
    final totalAvailableRadians = (2 * math.pi) - (effectiveGap * data.length);
    if (totalAvailableRadians <= 0) return;

    double startAngle = -math.pi / 2; // Start at 12 o'clock

    for (var item in data) {
      // Calculate this segment's raw portion of the whole
      final portion = item.value / total;
      
      // Calculate actual sweep angle based on available space and animation progress
      final sweepAngle = (portion * totalAvailableRadians) * progress;
      
      if (sweepAngle > 0) {
        final paint = Paint()
          ..color = item.color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(
          rect,
          startAngle,
          sweepAngle,
          false,
          paint,
        );
      }

      // Move start angle forward for the next segment, including the gap
      // Only include the gap if we actually drew a segment (progress > 0)
      startAngle += sweepAngle + (progress > 0 ? effectiveGap : 0);
    }
  }

  @override
  bool shouldRepaint(covariant _CircularChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.strokeWidth != strokeWidth ||
           oldDelegate.gapDegrees != gapDegrees ||
           oldDelegate.data != data;
  }
}
