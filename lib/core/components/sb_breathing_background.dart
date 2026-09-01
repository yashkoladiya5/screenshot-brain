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
                          colors: widget.colors,
                          stops: List.generate(
                            widget.colors.length, 
                            (index) => index / (widget.colors.length - 1)
                          ),
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
