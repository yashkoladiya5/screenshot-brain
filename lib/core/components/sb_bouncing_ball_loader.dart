import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbBouncingBallLoader extends StatefulWidget {
  final double size;
  final Color ballColor;
  final Color platformColor;
  final double bounceHeight;

  const SbBouncingBallLoader({
    super.key,
    this.size = 100.0,
    this.ballColor = const Color(0xFFFF3D00),
    this.platformColor = const Color(0xFF37474F),
    this.bounceHeight = 80.0,
  });

  @override
  State<SbBouncingBallLoader> createState() => _SbBouncingBallLoaderState();
}

class _SbBouncingBallLoaderState extends State<SbBouncingBallLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size + widget.bounceHeight, // Extra height for the jump
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double time = _controller.value;
          
          // 1. Calculate physics variables based on time (0.0 to 1.0)
          
          // The bounce is a parabola (y = ax^2 + bx + c)
          // We can approximate a gravity arc with an absolute sine wave,
          // but a true gravity arc looks like this: -4 * (t-0.5)^2 + 1
          final double arc = 1.0 - (4.0 * math.pow(time - 0.5, 2)); // 0.0 at edges, 1.0 at center
          
          // Y translation (0 at floor, -bounceHeight at peak)
          final double translateY = -arc * widget.bounceHeight;
          
          // 2. Squash and Stretch Physics
          double stretchY = 1.0;
          double stretchX = 1.0;
          
          // If time is very close to 0.0 or 1.0, the ball is hitting the ground.
          // It needs to violently squash, then instantly rebound.
          if (time < 0.1) {
            // Hitting ground at start of loop
            final double intensity = (0.1 - time) / 0.1; // 0 to 1
            stretchY = 1.0 - (intensity * 0.5); // Squash down to 50%
            stretchX = 1.0 + (intensity * 0.4); // Bulge out to 140%
          } else if (time > 0.9) {
            // Hitting ground at end of loop
            final double intensity = (time - 0.9) / 0.1; // 0 to 1
            stretchY = 1.0 - (intensity * 0.5);
            stretchX = 1.0 + (intensity * 0.4);
          } else {
            // In the air: stretch vertically based on velocity
            // Velocity is highest near the ground (arc near 0) and zero at peak (arc near 1)
            final double velocity = 1.0 - arc;
            stretchY = 1.0 + (velocity * 0.2); // Stretch up to 120%
            stretchX = 1.0 - (velocity * 0.1); // Thin down to 90%
          }
          
          // 3. Platform Physics (it bends under the weight of the ball)
          // The platform should only bend when the ball hits it (time < 0.1 or time > 0.9)
          double platformBend = 0.0;
          if (time < 0.15) {
            final double intensity = (0.15 - time) / 0.15;
            platformBend = intensity * 15.0; // Bend down 15 pixels
          } else if (time > 0.85) {
            final double intensity = (time - 0.85) / 0.15;
            platformBend = intensity * 15.0;
          }

          // 4. Shadow Physics
          // The shadow gets smaller and lighter as the ball goes higher
          final double shadowScale = 1.0 - (arc * 0.5); // 1.0 to 0.5
          final double shadowOpacity = 0.5 - (arc * 0.4); // 0.5 to 0.1

          final double ballRadius = widget.size * 0.2;

          return Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // The shadow
              Positioned(
                bottom: widget.size * 0.2 - 5,
                child: Transform.scale(
                  scale: shadowScale,
                  child: Container(
                    width: widget.size * 0.4,
                    height: widget.size * 0.05,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: shadowOpacity),
                      borderRadius: BorderRadius.circular(widget.size * 0.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: shadowOpacity * 0.5),
                          blurRadius: 10 * (1.0 - arc),
                        )
                      ]
                    ),
                  ),
                ),
              ),

              // The flexible platform
              Positioned(
                bottom: widget.size * 0.2 - 10,
                child: CustomPaint(
                  size: Size(widget.size, 20),
                  painter: _PlatformPainter(
                    color: widget.platformColor,
                    bendOffset: platformBend,
                  ),
                ),
              ),

              // The Ball
              Positioned(
                bottom: widget.size * 0.2, // Base floor level
                child: Transform(
                  transform: Matrix4.identity()
                    ..translate(0.0, translateY)
                    ..scale(stretchX, stretchY),
                  alignment: Alignment.bottomCenter, // Anchor at the very bottom
                  child: Container(
                    width: ballRadius * 2,
                    height: ballRadius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          widget.ballColor.withValues(alpha: 0.8), // Highlight
                          widget.ballColor,
                          widget.ballColor.withValues(red: (widget.ballColor.r * 0.5), green: (widget.ballColor.g * 0.5), blue: (widget.ballColor.b * 0.5)), // Shadow
                        ],
                        stops: const [0.0, 0.4, 1.0],
                        center: const Alignment(-0.3, -0.3), // Top-left highlight
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.ballColor.withValues(alpha: 0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ]
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlatformPainter extends CustomPainter {
  final Color color;
  final double bendOffset;

  _PlatformPainter({
    required this.color,
    required this.bendOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    final Paint highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final Path path = Path();
    
    // Draw a pill shape that bends in the middle
    path.moveTo(0, size.height / 2);
    
    // Top curve (bends down in the middle)
    path.quadraticBezierTo(
      size.width / 2, size.height / 2 + bendOffset, 
      size.width, size.height / 2
    );
    
    // Right cap
    path.quadraticBezierTo(
      size.width + 10, size.height / 2, 
      size.width, size.height
    );
    
    // Bottom curve (also bends down)
    path.quadraticBezierTo(
      size.width / 2, size.height + bendOffset, 
      0, size.height
    );
    
    // Left cap
    path.quadraticBezierTo(
      -10, size.height / 2, 
      0, size.height / 2
    );
    
    path.close();

    canvas.drawPath(path, paint);
    
    // Draw a highlight line on the top edge to make it pop
    final Path highlightPath = Path();
    highlightPath.moveTo(0, size.height / 2);
    highlightPath.quadraticBezierTo(
      size.width / 2, size.height / 2 + bendOffset, 
      size.width, size.height / 2
    );
    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _PlatformPainter oldDelegate) {
    return oldDelegate.bendOffset != bendOffset;
  }
}
