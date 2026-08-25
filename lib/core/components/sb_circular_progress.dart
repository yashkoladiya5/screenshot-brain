import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../design/tokens.dart';

class SbCircularProgress extends StatefulWidget {
  final double value; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color? activeColor;
  final Color? backgroundColor;
  final Widget? centerChild;
  final bool showPercent;
  final Duration animationDuration;

  const SbCircularProgress({
    super.key,
    required this.value,
    this.size = 120.0,
    this.strokeWidth = 12.0,
    this.activeColor,
    this.backgroundColor,
    this.centerChild,
    this.showPercent = true,
    this.animationDuration = const Duration(milliseconds: 1200),
  }) : assert(value >= 0.0 && value <= 1.0);

  @override
  State<SbCircularProgress> createState() => _SbCircularProgressState();
}

class _SbCircularProgressState extends State<SbCircularProgress> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousValue = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    
    _animation = Tween<double>(begin: _previousValue, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    
    _controller.forward();
  }

  @override
  void didUpdateWidget(SbCircularProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _previousValue = oldWidget.value;
      _animation = Tween<double>(begin: _previousValue, end: widget.value).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final active = widget.activeColor ?? colorScheme.primary;
    final bg = widget.backgroundColor ?? colorScheme.surfaceContainerHighest;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _CircularProgressPainter(
                  progress: _animation.value,
                  activeColor: active,
                  backgroundColor: bg,
                  strokeWidth: widget.strokeWidth,
                ),
              ),
              if (widget.centerChild != null)
                widget.centerChild!
              else if (widget.showPercent)
                Text(
                  '${(_animation.value * 100).toInt()}%',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color backgroundColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.activeColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // Draw background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
      
    canvas.drawCircle(center, radius, bgPaint);

    // Draw active arc
    if (progress > 0) {
      final activePaint = Paint()
        ..color = activeColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start at 12 o'clock
        2 * math.pi * progress,
        false,
        activePaint,
      );
      
      // Draw glow
      final glowPaint = Paint()
        ..color = activeColor.withValues(alpha: 0.3)
        ..strokeWidth = strokeWidth * 2
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0)
        ..strokeCap = StrokeCap.round;
        
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.activeColor != activeColor ||
           oldDelegate.backgroundColor != backgroundColor ||
           oldDelegate.strokeWidth != strokeWidth;
  }
}
