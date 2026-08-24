import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../design/tokens.dart';

class SbPieChartData {
  final double value;
  final Color color;
  final String label;

  const SbPieChartData({
    required this.value,
    required this.color,
    required this.label,
  });
}

class SbInteractivePieChart extends StatefulWidget {
  final List<SbPieChartData> data;
  final double size;
  final double donutWidth; // If > 0, it's a donut chart. If 0, it's a pie chart.

  const SbInteractivePieChart({
    super.key,
    required this.data,
    this.size = 200.0,
    this.donutWidth = 0.0,
  });

  @override
  State<SbInteractivePieChart> createState() => _SbInteractivePieChartState();
}

class _SbInteractivePieChartState extends State<SbInteractivePieChart> with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(SbInteractivePieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
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

  void _onTapDown(TapDownDetails details) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final position = details.localPosition;
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    
    // Calculate distance from center
    final distance = math.sqrt(dx * dx + dy * dy);
    
    // Check if outside pie chart or inside donut hole
    final outerRadius = widget.size / 2;
    final innerRadius = widget.donutWidth > 0 ? outerRadius - widget.donutWidth : 0.0;
    
    if (distance > outerRadius || distance < innerRadius) {
      setState(() {
        _selectedIndex = null;
      });
      return;
    }

    // Calculate angle from 12 o'clock (standard starting position)
    // math.atan2(y, x) returns angle from 3 o'clock.
    // We want 12 o'clock to be 0 radians.
    double tapAngle = math.atan2(dy, dx) + math.pi / 2;
    if (tapAngle < 0) {
      tapAngle += 2 * math.pi;
    }

    // Calculate which segment was tapped
    double total = 0;
    for (var d in widget.data) {
      total += d.value;
    }

    double currentAngle = 0;
    for (int i = 0; i < widget.data.length; i++) {
      final sweepAngle = (widget.data[i].value / total) * 2 * math.pi;
      if (tapAngle >= currentAngle && tapAngle <= currentAngle + sweepAngle) {
        setState(() {
          _selectedIndex = (_selectedIndex == i) ? null : i;
        });
        return;
      }
      currentAngle += sweepAngle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: _onTapDown,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _PieChartPainter(
                    data: widget.data,
                    selectedIndex: _selectedIndex,
                    progress: CurvedAnimation(
                      parent: _controller,
                      curve: Curves.easeOutCubic,
                    ).value,
                    donutWidth: widget.donutWidth,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: SBSpacing.xl),
        // Legend
        Wrap(
          spacing: SBSpacing.md,
          runSpacing: SBSpacing.sm,
          alignment: WrapAlignment.center,
          children: List.generate(widget.data.length, (index) {
            final item = widget.data[index];
            final isSelected = _selectedIndex == index;
            
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _selectedIndex == null || isSelected ? 1.0 : 0.4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<SbPieChartData> data;
  final int? selectedIndex;
  final double progress;
  final double donutWidth;

  _PieChartPainter({
    required this.data,
    required this.selectedIndex,
    required this.progress,
    required this.donutWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || progress == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2;

    double total = 0;
    for (var d in data) {
      total += d.value;
    }
    if (total == 0) return;

    double startAngle = -math.pi / 2; // 12 o'clock

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final sweepAngle = (item.value / total) * 2 * math.pi * progress;
      final isSelected = selectedIndex == i;
      final isFaded = selectedIndex != null && !isSelected;

      // Outer radius increases slightly if selected
      final radius = baseRadius + (isSelected ? 8.0 : 0.0);
      
      final paint = Paint()
        ..color = isFaded ? item.color.withValues(alpha: 0.4) : item.color
        ..style = donutWidth > 0 ? PaintingStyle.stroke : PaintingStyle.fill;
        
      if (donutWidth > 0) {
        paint.strokeWidth = donutWidth + (isSelected ? 4.0 : 0.0);
        // Draw arc for donut
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius - (paint.strokeWidth / 2)),
          startAngle,
          sweepAngle,
          false,
          paint,
        );
      } else {
        // Draw filled arc for pie
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          true,
          paint,
        );
      }

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.selectedIndex != selectedIndex ||
           oldDelegate.data != data ||
           oldDelegate.donutWidth != donutWidth;
  }
}
