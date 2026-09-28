import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbKineticTypographyLoader extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double waveAmplitude;
  final double stretchFactor;

  const SbKineticTypographyLoader({
    super.key,
    this.text = 'LOADING...',
    this.style = const TextStyle(
      fontSize: 48,
      fontWeight: FontWeight.w900,
      color: Colors.black,
      letterSpacing: 2.0,
    ),
    this.waveAmplitude = 20.0,
    this.stretchFactor = 1.5,
  });

  @override
  State<SbKineticTypographyLoader> createState() => _SbKineticTypographyLoaderState();
}

class _SbKineticTypographyLoaderState extends State<SbKineticTypographyLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Split the text into individual characters so we can animate them independently
    final List<String> chars = widget.text.split('');

    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double time = _controller.value; // 0.0 to 1.0

          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(chars.length, (index) {
              // Mathematical setup for the kinetic wave
              // Each letter has a slight phase shift based on its index
              final double phaseShift = (index / chars.length) * math.pi * 2;
              
              // We use a sine wave that sweeps through time
              // We multiply time by pi*2 to get a full cycle
              final double rawSine = math.sin((time * math.pi * 2) - phaseShift);
              
              // Normalize sine from [-1, 1] to [0, 1]
              final double normalizedSine = (rawSine + 1.0) / 2.0;

              // 1. Vertical Translation (Bouncing)
              // We want the letters to bounce up, then hit the floor hard
              // A pure sine wave is too smooth, so we take the absolute value of a sine wave
              // to make it "bounce" sharply at the bottom.
              // We shift it slightly so it looks like it hits the ground.
              final double bounceSine = math.sin((time * math.pi * 2) - phaseShift).abs();
              final double translateY = -bounceSine * widget.waveAmplitude;

              // 2. Vertical Stretching (Squash and Stretch physics)
              // When the letter hits the ground (bounceSine approaches 0), it should SQUASH
              // When it is at the peak (bounceSine approaches 1), it should STRETCH
              double stretchY = 1.0;
              double stretchX = 1.0;
              
              if (bounceSine < 0.2) {
                // Hitting the floor - SQUASH (wider, shorter)
                final double intensity = (0.2 - bounceSine) / 0.2; // 0 to 1
                stretchY = 1.0 - (intensity * 0.4);
                stretchX = 1.0 + (intensity * 0.3);
              } else if (bounceSine > 0.8) {
                // Peak of the jump - STRETCH (thinner, taller)
                final double intensity = (bounceSine - 0.8) / 0.2; // 0 to 1
                stretchY = 1.0 + (intensity * (widget.stretchFactor - 1.0));
                stretchX = 1.0 - (intensity * 0.2);
              }

              // Apply the transforms
              final Matrix4 transform = Matrix4.identity()
                ..translate(0.0, translateY)
                ..scale(stretchX, stretchY);

              return Transform(
                transform: transform,
                alignment: Alignment.bottomCenter, // Scale from the bottom floor
                child: Text(
                  chars[index],
                  style: widget.style.copyWith(
                    // Dynamic color interpolation for extra kinetic feel
                    color: Color.lerp(
                      widget.style.color,
                      Colors.grey.shade300,
                      normalizedSine,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
