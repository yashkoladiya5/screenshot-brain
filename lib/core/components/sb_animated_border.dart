import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../design/tokens.dart';

class SbAnimatedBorder extends StatefulWidget {
  final Widget child;
  final double borderWidth;
  final double borderRadius;
  final List<Color> gradientColors;
  final Duration duration;
  final Color? backgroundColor;

  const SbAnimatedBorder({
    super.key,
    required this.child,
    this.borderWidth = 3.0,
    this.borderRadius = SBRadius.md,
    this.gradientColors = const [
      Colors.blue,
      Colors.purple,
      Colors.pink,
      Colors.blue, // Repeat first color for seamless loop
    ],
    this.duration = const Duration(seconds: 3),
    this.backgroundColor,
  });

  @override
  State<SbAnimatedBorder> createState() => _SbAnimatedBorderState();
}

class _SbAnimatedBorderState extends State<SbAnimatedBorder> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
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
    final bg = widget.backgroundColor ?? theme.colorScheme.surface;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          // Outer container acts as the border
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: SweepGradient(
              colors: widget.gradientColors,
              // Rotate the gradient based on animation controller
              transform: GradientRotation(_controller.value * 2 * math.pi),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.borderWidth),
            child: Container(
              // Inner container masks the center so only the border is visible
              decoration: BoxDecoration(
                color: bg,
                // Adjust inner radius slightly to avoid clipping artifacts
                borderRadius: BorderRadius.circular(math.max(0, widget.borderRadius - widget.borderWidth)),
              ),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}
