import 'package:flutter/material.dart';
import 'dart:math' as math;

enum SbWeatherType { sunny, rainy, cloudy, stormy }

class SbAnimatedWeatherCard extends StatefulWidget {
  final SbWeatherType weatherType;
  final String temperature;
  final String location;
  final double width;
  final double height;

  const SbAnimatedWeatherCard({
    super.key,
    required this.weatherType,
    this.temperature = '72°',
    this.location = 'San Francisco',
    this.width = 300.0,
    this.height = 180.0,
  });

  @override
  State<SbAnimatedWeatherCard> createState() => _SbAnimatedWeatherCardState();
}

class _SbAnimatedWeatherCardState extends State<SbAnimatedWeatherCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Define gradients and colors based on weather type
  LinearGradient get _backgroundGradient {
    switch (widget.weatherType) {
      case SbWeatherType.sunny:
        return const LinearGradient(
          colors: [Color(0xFF4CA1AF), Color(0xFFC4E0E5)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        );
      case SbWeatherType.rainy:
        return const LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case SbWeatherType.cloudy:
        return const LinearGradient(
          colors: [Color(0xFF9D50BB), Color(0xFF6E48AA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case SbWeatherType.stormy:
        return const LinearGradient(
          colors: [Color(0xFF141E30), Color(0xFF243B55)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.0),
        gradient: _backgroundGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias, // Keep weather elements inside the card
      child: Stack(
        children: [
          // 1. The animated weather graphics
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _WeatherEffectsPainter(
                  weatherType: widget.weatherType,
                  time: _controller.value,
                ),
                size: Size(widget.width, widget.height),
              );
            },
          ),
          
          // 2. The Text Content Overlay
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.location,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(1, 1))
                    ]
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.temperature,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 64,
                        fontWeight: FontWeight.w200,
                        height: 1.0,
                        shadows: [
                          Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(2, 2))
                        ]
                      ),
                    ),
                    Text(
                      widget.weatherType.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _WeatherEffectsPainter extends CustomPainter {
  final SbWeatherType weatherType;
  final double time;

  _WeatherEffectsPainter({
    required this.weatherType,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (weatherType == SbWeatherType.sunny) {
      _drawSun(canvas, size);
      _drawClouds(canvas, size, cloudCount: 2, speedMultiplier: 0.5, opacity: 0.4);
    } else if (weatherType == SbWeatherType.cloudy) {
      _drawClouds(canvas, size, cloudCount: 5, speedMultiplier: 1.0, opacity: 0.8);
    } else if (weatherType == SbWeatherType.rainy) {
      _drawClouds(canvas, size, cloudCount: 4, speedMultiplier: 0.8, opacity: 0.9, isDark: true);
      _drawRain(canvas, size, isStorm: false);
    } else if (weatherType == SbWeatherType.stormy) {
      _drawClouds(canvas, size, cloudCount: 6, speedMultiplier: 1.5, opacity: 1.0, isDark: true);
      _drawRain(canvas, size, isStorm: true);
      _drawLightning(canvas, size);
    }
  }

  void _drawSun(Canvas canvas, Size size) {
    final Paint sunPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;
      
    final Paint glowPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    // Sun sits in the top right corner
    final Offset sunCenter = Offset(size.width * 0.8, size.height * 0.2);
    
    // Slow pulse effect for the sun based on time
    final double pulse = math.sin(time * 2 * math.pi) * 5.0;

    canvas.drawCircle(sunCenter, 40 + pulse, glowPaint);
    canvas.drawCircle(sunCenter, 30, sunPaint);
  }

  void _drawClouds(Canvas canvas, Size size, {required int cloudCount, required double speedMultiplier, required double opacity, bool isDark = false}) {
    final Paint cloudPaint = Paint()
      ..color = isDark ? const Color(0xFF607D8B).withValues(alpha: opacity) : Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    // Use a fixed seed so the clouds don't completely change every frame
    final math.Random random = math.Random(42);

    for (int i = 0; i < cloudCount; i++) {
      // Generate deterministic but random-looking properties for each cloud
      final double yPos = size.height * (0.1 + random.nextDouble() * 0.4);
      final double scale = 0.5 + random.nextDouble() * 0.8;
      
      // Calculate X position based on time, speed, and a random offset
      // This makes the clouds drift across the screen and loop back around
      final double randomOffset = random.nextDouble();
      // time goes from 0 to 1 over 4 seconds.
      double xProgress = (time * speedMultiplier + randomOffset) % 1.0;
      
      // Map progress to screen width (with extra padding so it spawns off-screen)
      final double startX = -size.width * 0.5;
      final double endX = size.width * 1.5;
      final double xPos = startX + (endX - startX) * xProgress;

      _drawSingleCloud(canvas, Offset(xPos, yPos), scale, cloudPaint);
    }
  }

  void _drawSingleCloud(Canvas canvas, Offset center, double scale, Paint paint) {
    // A cloud is just a cluster of circles
    canvas.drawCircle(Offset(center.dx, center.dy), 20 * scale, paint);
    canvas.drawCircle(Offset(center.dx + 25 * scale, center.dy + 5 * scale), 15 * scale, paint);
    canvas.drawCircle(Offset(center.dx - 20 * scale, center.dy + 10 * scale), 12 * scale, paint);
    
    // Fill the bottom gap
    final Rect bottomRect = Rect.fromLTRB(
      center.dx - 20 * scale,
      center.dy + 5 * scale,
      center.dx + 25 * scale,
      center.dy + 20 * scale,
    );
    canvas.drawRect(bottomRect, paint);
  }

  void _drawRain(Canvas canvas, Size size, {required bool isStorm}) {
    final Paint rainPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = isStorm ? 2.0 : 1.0
      ..strokeCap = StrokeCap.round;

    final int dropCount = isStorm ? 100 : 40;
    final math.Random random = math.Random(123); // fixed seed for drop positions

    for (int i = 0; i < dropCount; i++) {
      final double xPos = random.nextDouble() * size.width;
      
      // Rain falls very fast. Time goes 0 to 1.
      final double speed = isStorm ? 3.0 : 1.5;
      final double offset = random.nextDouble();
      
      // Y progresses downwards, looping modulo 1.0
      final double yProgress = ((time * speed) + offset) % 1.0;
      final double yPos = yProgress * size.height;
      
      // Slant the rain slightly
      final double slant = isStorm ? 15.0 : 5.0;
      final double dropLength = isStorm ? 30.0 : 15.0;
      
      canvas.drawLine(
        Offset(xPos, yPos),
        Offset(xPos - slant, yPos + dropLength),
        rainPaint,
      );
    }
  }

  void _drawLightning(Canvas canvas, Size size) {
    // Lightning only strikes randomly, not constantly.
    // We'll use the current time value to trigger flashes
    // If time is between 0.45 and 0.5, or 0.82 and 0.85
    
    bool isFlashing = (time > 0.45 && time < 0.48) || (time > 0.82 && time < 0.86);
    
    if (!isFlashing) return;

    // The flash overlay
    final Paint flashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
      
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), flashPaint);
    
    // Draw an actual jagged lightning bolt
    final Paint boltPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.miter;

    final Path boltPath = Path();
    boltPath.moveTo(size.width * 0.6, 0); // Start at top
    boltPath.lineTo(size.width * 0.4, size.height * 0.4); // Zig left
    boltPath.lineTo(size.width * 0.5, size.height * 0.45); // Zag right
    boltPath.lineTo(size.width * 0.3, size.height); // Strike bottom
    
    canvas.drawPath(boltPath, boltPaint);
  }

  @override
  bool shouldRepaint(covariant _WeatherEffectsPainter oldDelegate) {
    return oldDelegate.time != time || oldDelegate.weatherType != weatherType;
  }
}
