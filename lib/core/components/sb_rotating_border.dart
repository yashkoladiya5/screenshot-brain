import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../design/tokens.dart';

class SbRotatingBorder extends StatefulWidget {
  final Widget child;
  final double borderWidth;
  final double borderRadius;
  final List<Color> gradientColors;
  final Duration animationDuration;
  final Color backgroundColor;

  const SbRotatingBorder({
    super.key,
    required this.child,
    this.borderWidth = 3.0,
    this.borderRadius = SBRadius.md,
    this.gradientColors = const [
      Colors.cyanAccent,
      Colors.pinkAccent,
      Colors.yellowAccent,
      Colors.cyanAccent, // Repeat first color for seamless loop
    ],
    this.animationDuration = const Duration(seconds: 4),
    this.backgroundColor = Colors.black87,
  });

  @override
  State<SbRotatingBorder> createState() => _SbRotatingBorderState();
}

class _SbRotatingBorderState extends State<SbRotatingBorder> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. The animating gradient layer (larger than box to allow rotation without clipping corners)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.5, // Ensure the spinning gradient covers the corners
                  child: Transform.rotate(
                    angle: _controller.value * 2 * math.pi,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: SweepGradient(
                          colors: widget.gradientColors,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // 2. The inner background to hollow out the border
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(widget.borderWidth),
              child: Container(
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(widget.borderRadius - (widget.borderWidth / 2)),
                ),
              ),
            ),
          ),
          
          // 3. The actual content
          Padding(
            padding: EdgeInsets.all(widget.borderWidth),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
