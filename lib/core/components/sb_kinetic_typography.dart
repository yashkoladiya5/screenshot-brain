import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbKineticTypography extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double waveAmplitude;
  final double waveFrequency;
  final Duration animationDuration;

  const SbKineticTypography({
    super.key,
    required this.text,
    this.style,
    this.waveAmplitude = 15.0,
    this.waveFrequency = 0.5,
    this.animationDuration = const Duration(seconds: 2),
  });

  @override
  State<SbKineticTypography> createState() => _SbKineticTypographyState();
}

class _SbKineticTypographyState extends State<SbKineticTypography> with SingleTickerProviderStateMixin {
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
    final theme = Theme.of(context);
    final textStyle = widget.style ?? theme.textTheme.displaySmall?.copyWith(
      fontWeight: FontWeight.bold,
    ) ?? const TextStyle(fontSize: 32);

    final List<String> characters = widget.text.split('');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(characters.length, (index) {
        final char = characters[index];
        
        // Handle spaces without animation wrappers for better performance
        if (char == ' ') {
          return Text(' ', style: textStyle);
        }

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Calculate a wave phase based on both the character's index and time
            // index * frequency controls how "tight" the wave is across the string
            // _controller.value * 2pi controls the movement through time
            final double phase = (index * widget.waveFrequency) + (_controller.value * 2 * math.pi);
            
            // Calculate the vertical offset using sine wave
            final double offsetY = math.sin(phase) * widget.waveAmplitude;

            return Transform.translate(
              offset: Offset(0, offsetY),
              child: child,
            );
          },
          child: Text(char, style: textStyle),
        );
      }),
    );
  }
}
