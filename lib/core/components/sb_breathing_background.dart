import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class SbBreathingBackground extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final Duration cycleDuration;

  const SbBreathingBackground({
    super.key,
    required this.child,
    this.colors = const [
      Color(0xFF2C3E50),
      Color(0xFF3498DB),
      Color(0xFF9B59B6),
    ],
    this.cycleDuration = const Duration(seconds: 10),
  });

  @override
  State<SbBreathingBackground> createState() => _SbBreathingBackgroundState();
}

class _SbBreathingBackgroundState extends State<SbBreathingBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.cycleDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Calculate the current phase of the animation (0.0 to 1.0)
        final double phase = _controller.value;
        
        // Use sine wave to create a smooth breathing effect (expands and contracts)
        // math.sin returns -1.0 to 1.0, we want 0.5 to 1.5 for scale
        final double breatheScale = 1.0 + (math.sin(phase * 2 * math.pi) * 0.2);
        
        // Rotate slowly
        final double rotation = phase * 2 * math.pi;

        // SweepGradient asserts on fewer than two colors, and the stops below
        // divided by (length - 1) — which is zero for a single color, making
        // every stop NaN. Two identical colors render as a flat fill, and the
        // gradient distributes stops evenly on its own.
        final base = widget.colors.isEmpty
            ? const [Colors.transparent]
            : widget.colors;
        final colors = base.length > 1 ? base : [base.first, base.first];

        return Stack(
          children: [
            // The animated gradient background
            Positioned.fill(
              child: ClipRect(
                child: Transform.scale(
                  scale: 1.5 * breatheScale, // Scale up to ensure corners are covered during rotation
                  child: Transform.rotate(
                    angle: rotation,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: SweepGradient(
                          center: Alignment.center,
                          colors: colors,
                          stops: null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Apply a heavy blur to make it look ambient rather than sharp
            Positioned.fill(
              child: BackdropFilter(
                filter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.3), 
                  BlendMode.darken
                ),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
            
            // The actual content on top
            SafeArea(
              child: widget.child,
            ),
          ],
        );
      },
    );
  }
}
