import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbAnimatedWaveBackground extends StatefulWidget {
  final Widget child;
  final List<Color> waveColors;
  final double waveHeight;
  final Duration animationDuration;
  final Color backgroundColor;

  const SbAnimatedWaveBackground({
    super.key,
    required this.child,
    required this.waveColors,
    this.waveHeight = 100.0,
    this.animationDuration = const Duration(seconds: 4),
    this.backgroundColor = Colors.white,
  });

  @override
  State<SbAnimatedWaveBackground> createState() => _SbAnimatedWaveBackgroundState();
}

class _SbAnimatedWaveBackgroundState extends State<SbAnimatedWaveBackground> with SingleTickerProviderStateMixin {
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
    return Stack(
      children: [
        // Base Background Color
        Positioned.fill(
          child: Container(color: widget.backgroundColor),
        ),
        
        // Multi-layered waves
        ...List.generate(widget.waveColors.length, (index) {
          return Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            // Stagger the height slightly for each wave layer
            height: widget.waveHeight + (index * 20.0),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _WavePainter(
                    animationValue: _controller.value,
                    color: widget.waveColors[index],
                    // Offset the animation for each layer so they don't overlap perfectly
                    layerOffset: index * 0.25,
                    // Give different layers slightly different frequencies
                    frequencyModulator: 1.0 + (index * 0.2),
                  ),
                );
              },
            ),
          );
        }),

        // Content
        Positioned.fill(
          child: widget.child,
        ),
      ],
    );
  }
}

class _WavePainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final double layerOffset;
  final double frequencyModulator;

  _WavePainter({
    required this.animationValue,
    required this.color,
    required this.layerOffset,
    required this.frequencyModulator,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height); // Start bottom left
    
    // We draw the wave at the top of this container
    // The wave uses two combined sine waves to make it look organic rather than mathematical
    for (double i = 0; i <= size.width; i++) {
      // Base wave
      final double normalizedX = (i / size.width);
      
      // We calculate time based on the animation value plus the offset for this specific layer
      final double time = (animationValue + layerOffset) * 2 * math.pi;
      
      // Wave 1: The main slow rolling wave
      final double wave1 = math.sin((normalizedX * 2 * math.pi * frequencyModulator) + time) * 15.0;
      
      // Wave 2: A faster, smaller wave added to wave 1 to create turbulence
      final double wave2 = math.cos((normalizedX * 3 * math.pi * frequencyModulator) - (time * 1.5)) * 8.0;
      
      // Y goes down in Flutter, so subtracting wave height pushes the wave UP from the bottom
      // We also start drawing the wave a bit below the top of the container (at 40px)
      path.lineTo(i, 40.0 - wave1 - wave2);
    }
    
    path.lineTo(size.width, size.height); // Drop down to bottom right
    path.close(); // Close path back to bottom left

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.color != color ||
           oldDelegate.layerOffset != layerOffset ||
           oldDelegate.frequencyModulator != frequencyModulator;
  }
}
