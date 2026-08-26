import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbBubbleData {
  final double x; // 0.0 to 1.0 (relative to width)
  final double y; // 0.0 to 1.0 (relative to height)
  final double size; // Base radius
  final Color color;
  final String? label;

  const SbBubbleData({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    this.label,
  });
}

class SbBubbleChart extends StatefulWidget {
  final List<SbBubbleData> data;
  final double height;
  final double width;
  final bool animated;

  const SbBubbleChart({
    super.key,
    required this.data,
    this.height = 300.0,
    this.width = double.infinity,
    this.animated = true,
  });

  @override
  State<SbBubbleChart> createState() => _SbBubbleChartState();
}

class _SbBubbleChartState extends State<SbBubbleChart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    if (widget.animated) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }
  
  @override
  void didUpdateWidget(SbBubbleChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data && widget.animated) {
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
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _BubblePainter(
              data: widget.data,
              progress: _animation.value,
              theme: Theme.of(context),
            ),
          );
        },
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  final List<SbBubbleData> data;
  final double progress;
  final ThemeData theme;

  _BubblePainter({
    required this.data,
    required this.progress,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (var bubble in data) {
      // Calculate center position
      final centerX = bubble.x * size.width;
      final centerY = size.height - (bubble.y * size.height); // Invert Y axis
      
      final currentRadius = bubble.size * progress;
      
      if (currentRadius <= 0) continue;

      // Draw shadow
      final shadowPaint = Paint()
        ..color = bubble.color.withValues(alpha: 0.3 * progress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      
      canvas.drawCircle(Offset(centerX, centerY + 8), currentRadius * 0.9, shadowPaint);

      // Draw bubble
      final paint = Paint()
        ..color = bubble.color
        ..style = PaintingStyle.fill;
        
      // Add gradient to make it look like a 3D sphere
      final gradient = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 0.8,
        colors: [
          Colors.white.withValues(alpha: 0.6),
          bubble.color,
          bubble.color.withOpacity(0.8), // using raw opacity here as we're mixing with base color
        ],
        stops: const [0.0, 0.4, 1.0],
      );
      
      final rect = Rect.fromCircle(center: Offset(centerX, centerY), radius: currentRadius);
      paint.shader = gradient.createShader(rect);

      canvas.drawCircle(Offset(centerX, centerY), currentRadius, paint);

      // Draw text label if exists and bubble is large enough
      if (bubble.label != null && currentRadius > 15) {
        textPainter.text = TextSpan(
          text: bubble.label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: bubble.color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: math.max(8, currentRadius / 3), // Scale text with bubble
          ),
        );
        textPainter.layout(maxWidth: currentRadius * 1.8); // Ensure it fits
        
        textPainter.paint(
          canvas,
          Offset(centerX - (textPainter.width / 2), centerY - (textPainter.height / 2)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.data != data;
  }
}
