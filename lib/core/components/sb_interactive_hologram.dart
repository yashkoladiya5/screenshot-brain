import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbInteractiveHologram extends StatefulWidget {
  final Widget child;
  final Color hologramColor;
  final double width;
  final double height;

  const SbInteractiveHologram({
    super.key,
    required this.child,
    this.hologramColor = const Color(0xFF00FFFF), // Cyan
    this.width = 250.0,
    this.height = 350.0,
  });

  @override
  State<SbInteractiveHologram> createState() => _SbInteractiveHologramState();
}

class _SbInteractiveHologramState extends State<SbInteractiveHologram> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // For interactive 3D rotation
  double _rotationX = 0;
  double _rotationY = 0;

  @override
  void initState() {
    super.initState();
    // Controls the scanning laser line and flicker effects
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _rotationY += details.delta.dx * 0.01;
      _rotationX -= details.delta.dy * 0.01;
      
      // Limit vertical rotation to not flip entirely upside down
      _rotationX = _rotationX.clamp(-math.pi / 4, math.pi / 4);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    // Slowly return to center when released
    // Instead of snapping, we'll just let it stay where the user left it, 
    // but maybe auto-rotate slightly over time. For now, leaving it is fine.
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Center(
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // 1. Calculate random glitch/flicker
              // Most of the time opacity is 1.0, but occasionally it flickers
              final double time = _controller.value;
              double opacity = 0.85;
              
              if ((time > 0.3 && time < 0.32) || (time > 0.75 && time < 0.78)) {
                opacity = 0.3; // Major flicker
              } else if (math.sin(time * 100) > 0.9) {
                opacity = 0.6 + (math.Random().nextDouble() * 0.4); // Micro flicker
              }

              // 2. Base 3D Transform
              final Matrix4 transform = Matrix4.identity()
                ..setEntry(3, 2, 0.001) // perspective
                ..rotateX(_rotationX)
                ..rotateY(_rotationY);

              return Transform(
                transform: transform,
                alignment: FractionalOffset.center,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // The core child widget, masked and colored
                    Opacity(
                      opacity: opacity,
                      child: ShaderMask(
                        blendMode: BlendMode.srcATop, // Keeps child's alpha, colors it with the shader
                        shaderCallback: (bounds) {
                          // Apply scanlines
                          return LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              widget.hologramColor,
                              widget.hologramColor.withValues(alpha: 0.8),
                            ],
                            stops: const [0.0, 1.0],
                          ).createShader(bounds);
                        },
                        child: widget.child,
                      ),
                    ),
                    
                    // CRT Scanline Overlay Effect
                    Opacity(
                      opacity: opacity * 0.5,
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _ScanlinePainter(
                            color: widget.hologramColor,
                            scanPosition: _controller.value,
                          ),
                        ),
                      ),
                    ),
                    
                    // Hologram Base Emitter Glow (at the bottom)
                    Positioned(
                      bottom: -20,
                      left: 0,
                      right: 0,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.ellipse,
                          boxShadow: [
                            BoxShadow(
                              color: widget.hologramColor.withValues(alpha: opacity * 0.6),
                              blurRadius: 30,
                              spreadRadius: 10,
                            )
                          ]
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          ),
        ),
      ),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  final Color color;
  final double scanPosition; // 0.0 to 1.0

  _ScanlinePainter({
    required this.color,
    required this.scanPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw static horizontal scanlines across the entire box
    final Paint linePaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
      
    for (double i = 0; i < size.height; i += 4.0) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), linePaint);
    }

    // 2. Draw the thick, bright scanning laser that moves top to bottom
    final double currentY = size.height * scanPosition;
    
    // The laser consists of a bright core and a faded gradient trail
    final Rect laserRect = Rect.fromLTRB(0, currentY - 20, size.width, currentY + 2);
    
    final Paint laserPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          color.withValues(alpha: 0.2),
          color.withValues(alpha: 0.8), // Bright tip
        ],
        stops: const [0.0, 0.8, 1.0],
      ).createShader(laserRect);
      
    canvas.drawRect(laserRect, laserPaint);
    
    // Draw the absolute brightest line at the tip
    final Paint tipPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, currentY), Offset(size.width, currentY), tipPaint);
  }

  @override
  bool shouldRepaint(covariant _ScanlinePainter oldDelegate) {
    return oldDelegate.scanPosition != scanPosition;
  }
}
