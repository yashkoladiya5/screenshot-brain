import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbGlowingBorderCard extends StatefulWidget {
  final Widget child;
  final double width;
  final double height;
  final double borderWidth;
  final double borderRadius;
  final List<Color> glowColors;
  final Color backgroundColor;

  const SbGlowingBorderCard({
    super.key,
    required this.child,
    this.width = 300.0,
    this.height = 400.0,
    this.borderWidth = 3.0,
    this.borderRadius = 16.0,
    this.backgroundColor = const Color(0xFF1E1E1E),
    this.glowColors = const [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.red, // Repeat first color for seamless loop
    ],
  });

  @override
  State<SbGlowingBorderCard> createState() => _SbGlowingBorderCardState();
}

class _SbGlowingBorderCardState extends State<SbGlowingBorderCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
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
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // The rotating gradient border (slightly larger than inner card)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _controller.value * 2 * math.pi,
                  child: Container(
                    // Make it significantly larger than the box so the rotating gradient corners don't clip
                    width: widget.width * 1.5,
                    height: widget.width * 1.5, 
                    decoration: BoxDecoration(
                      gradient: SweepGradient(
                        colors: widget.glowColors,
                      ),
                    ),
                  ),
                );
              }
            ),
            
            // Heavy blur on the rotating gradient to create a "glow" bleed effect
            Positioned.fill(
              child: BackdropFilter(
                filter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.1), 
                  BlendMode.darken
                ),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),

            // The inner solid card that masks out the center of the gradient
            Container(
              width: widget.width - (widget.borderWidth * 2),
              height: widget.height - (widget.borderWidth * 2),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(math.max(0.0, widget.borderRadius - widget.borderWidth)),
              ),
              clipBehavior: Clip.antiAlias,
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}
