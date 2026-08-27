import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../design/tokens.dart';

class SbLiquidProgress extends StatefulWidget {
  final double value; // 0.0 to 1.0
  final double width;
  final double height;
  final Color? color;
  final Color? backgroundColor;
  final double borderRadius;
  final bool showPercentage;

  const SbLiquidProgress({
    super.key,
    required this.value,
    this.width = double.infinity,
    this.height = 40.0,
    this.color,
    this.backgroundColor,
    this.borderRadius = SBRadius.full,
    this.showPercentage = true,
  });

  @override
  State<SbLiquidProgress> createState() => _SbLiquidProgressState();
}

class _SbLiquidProgressState extends State<SbLiquidProgress> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  late Animation<double> _fillAnimation;
  double _oldValue = 0.0;

  @override
  void initState() {
    super.initState();
    _oldValue = widget.value;
    
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    
    // We'll use this controller to animate the fill level as well
    _fillAnimation = Tween<double>(begin: _oldValue, end: widget.value).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(SbLiquidProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _oldValue = oldWidget.value;
      // We don't want to reset the wave phase, so we use a separate tween 
      // driven by the same continuous controller but we map the current time.
      // Actually, since the controller is repeating, it's easier to just use an implicit animation
      // for the fill level, and keep the explicit one just for the wave.
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final liquidColor = widget.color ?? theme.colorScheme.primary;
    final bgColor = widget.backgroundColor ?? theme.colorScheme.surfaceContainerHighest;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _oldValue, end: widget.value),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, fillValue, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Container(
            width: widget.width,
            height: widget.height,
            color: bgColor,
            child: Stack(
              children: [
                // Liquid Fill Background
                AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(widget.width == double.infinity ? MediaQuery.of(context).size.width : widget.width, widget.height),
                      painter: _LiquidPainter(
                        fillValue: fillValue,
                        wavePhase: _waveController.value * math.pi * 2,
                        color: liquidColor,
                      ),
                    );
                  },
                ),
                
                // Percentage Text
                if (widget.showPercentage)
                  Center(
                    child: Text(
                      '${(fillValue * 100).toInt()}%',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        // MixBlendMode equivalent in Flutter is tricky for text over dynamic backgrounds.
                        // We'll use a shadow to ensure legibility.
                        color: Colors.white,
                        shadows: [
                          const Shadow(
                            color: Colors.black45,
                            blurRadius: 4.0,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LiquidPainter extends CustomPainter {
  final double fillValue;
  final double wavePhase;
  final Color color;

  _LiquidPainter({
    required this.fillValue,
    required this.wavePhase,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double activeWidth = size.width * fillValue;
    if (activeWidth <= 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // We draw two waves to give depth
    _drawWave(canvas, size, activeWidth, wavePhase, color.withValues(alpha: 0.5), amplitude: 6.0, offset: 0);
    _drawWave(canvas, size, activeWidth, wavePhase + math.pi, color, amplitude: 4.0, offset: 2.0);
  }

  void _drawWave(Canvas canvas, Size size, double activeWidth, double phase, Color waveColor, {required double amplitude, required double offset}) {
    final paint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, 0); // Start at top left

    // If fully filled, just draw a rectangle, no wave
    if (fillValue >= 1.0) {
      path.lineTo(activeWidth, 0);
      path.lineTo(activeWidth, size.height);
      path.close();
      canvas.drawPath(path, paint);
      return;
    }

    // Draw the top edge (which is a vertical line in this horizontal bar)
    // Wait, if it's a horizontal bar, the wave should be on the vertical edge!
    
    // Wave on the right edge
    path.lineTo(activeWidth - amplitude, 0); // go to top right (minus wave amp)
    
    // Draw the wavy vertical edge
    final int segments = 40;
    for (int i = 0; i <= segments; i++) {
      final double y = (size.height / segments) * i;
      final double waveShift = math.sin((y / size.height * math.pi * 2) + phase) * amplitude;
      path.lineTo(activeWidth - amplitude + waveShift - offset, y);
    }
    
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter oldDelegate) {
    return oldDelegate.fillValue != fillValue ||
           oldDelegate.wavePhase != wavePhase ||
           oldDelegate.color != color;
  }
}
