import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbOrigamiLoader extends StatefulWidget {
  final double size;
  final Color frontColor;
  final Color backColor;

  const SbOrigamiLoader({
    super.key,
    this.size = 100.0,
    this.frontColor = const Color(0xFFFF5252), // Bright red
    this.backColor = const Color(0xFFD32F2F),  // Darker red for shading
  });

  @override
  State<SbOrigamiLoader> createState() => _SbOrigamiLoaderState();
}

class _SbOrigamiLoaderState extends State<SbOrigamiLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // One full cycle folds and unfolds
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
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
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double time = _controller.value;
          
          // We break the animation into 4 phases:
          // 0.0 - 0.25: Top left folds in
          // 0.25 - 0.50: Top right folds in
          // 0.50 - 0.75: Bottom right folds in
          // 0.75 - 1.00: Bottom left folds in
          // Note: to make it a continuous loop, as one folds in, the opposite folds out.
          // Let's use a simpler overlapping sine wave approach for continuous organic folding.
          
          // We have 4 triangular quadrants.
          // 0: Top Left, 1: Top Right, 2: Bottom Right, 3: Bottom Left
          
          return Stack(
            children: List.generate(4, (index) {
              // Calculate a staggered folding angle for each quadrant based on time
              // Delay each quadrant by 0.25 of the total cycle
              final double phaseShift = index * 0.25;
              
              // We use a sine wave to go from 0 to 180 degrees (0 to pi) and back
              // math.sin() goes from -1 to 1. We want 0 to pi.
              // A full cycle is 2*pi.
              final double foldProgress = (math.sin((time - phaseShift) * 2 * math.pi) + 1.0) / 2.0;
              
              // The angle folds inward. 0 means flat. math.pi (180 deg) means fully folded over.
              final double foldAngle = foldProgress * math.pi * 0.95; // Don't fold exactly flat to prevent z-fighting
              
              return _OrigamiQuadrant(
                quadrantIndex: index,
                size: widget.size,
                foldAngle: foldAngle,
                frontColor: widget.frontColor,
                backColor: widget.backColor,
              );
            }),
          );
        },
      ),
    );
  }
}

class _OrigamiQuadrant extends StatelessWidget {
  final int quadrantIndex; // 0: TL, 1: TR, 2: BR, 3: BL
  final double size;
  final double foldAngle; // 0 to ~pi
  final Color frontColor;
  final Color backColor;

  const _OrigamiQuadrant({
    required this.quadrantIndex,
    required this.size,
    required this.foldAngle,
    required this.frontColor,
    required this.backColor,
  });

  @override
  Widget build(BuildContext context) {
    final double halfSize = size / 2;
    
    // We position each quadrant in its respective corner
    double left = 0;
    double top = 0;
    
    // Alignment determines which edge is the "hinge" of the fold
    Alignment hingeAlignment;
    
    // Axis determines whether it folds horizontally or vertically
    bool isVerticalHinge;
    
    switch (quadrantIndex) {
      case 0: // Top Left
        left = 0;
        top = 0;
        hingeAlignment = Alignment.bottomRight;
        // TL folds across its bottom-right diagonal.
        // To approximate this with standard rotation, we'll just fold along the horizontal axis
        isVerticalHinge = false;
        break;
      case 1: // Top Right
        left = halfSize;
        top = 0;
        hingeAlignment = Alignment.bottomLeft;
        isVerticalHinge = true; // Fold along vertical axis
        break;
      case 2: // Bottom Right
        left = halfSize;
        top = halfSize;
        hingeAlignment = Alignment.topLeft;
        isVerticalHinge = false; // Fold along horizontal axis
        break;
      case 3: // Bottom Left
      default:
        left = 0;
        top = halfSize;
        hingeAlignment = Alignment.topRight;
        isVerticalHinge = true; // Fold along vertical axis
        break;
    }

    // Is the back of the paper visible? (Past 90 degrees)
    final bool isBackVisible = foldAngle > math.pi / 2;
    
    // Calculate shadow based on fold depth
    final double shadowIntensity = math.sin(foldAngle);

    final Matrix4 transform = Matrix4.identity()
      ..setEntry(3, 2, 0.002); // 3D Perspective
      
    if (isVerticalHinge) {
      // If we are on the left side (quad 3), fold inward (positive Y rotation)
      // If we are on the right side (quad 1), fold inward (negative Y rotation)
      double direction = (quadrantIndex == 3) ? 1.0 : -1.0;
      transform.rotateY(foldAngle * direction);
    } else {
      // If we are on the top side (quad 0), fold inward (negative X rotation)
      // If we are on the bottom side (quad 2), fold inward (positive X rotation)
      double direction = (quadrantIndex == 0) ? -1.0 : 1.0;
      transform.rotateX(foldAngle * direction);
    }

    return Positioned(
      left: left,
      top: top,
      width: halfSize,
      height: halfSize,
      child: Transform(
        alignment: hingeAlignment,
        transform: transform,
        child: Container(
          decoration: BoxDecoration(
            color: isBackVisible ? backColor : frontColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4 * shadowIntensity),
                blurRadius: 10 * shadowIntensity,
                offset: isVerticalHinge 
                  ? Offset(5 * shadowIntensity, 5 * shadowIntensity) 
                  : Offset(5 * shadowIntensity, 10 * shadowIntensity),
              )
            ]
          ),
          child: CustomPaint(
            painter: _QuadrantShadowPainter(
              shadowIntensity: shadowIntensity,
              isBackVisible: isBackVisible,
            ),
          ),
        ),
      ),
    );
  }
}

// Applies dynamic shading to the paper to make it look like it's bending under a light source
class _QuadrantShadowPainter extends CustomPainter {
  final double shadowIntensity;
  final bool isBackVisible;

  _QuadrantShadowPainter({
    required this.shadowIntensity,
    required this.isBackVisible,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (shadowIntensity == 0) return;

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isBackVisible ? 0.3 * shadowIntensity : 0.6 * shadowIntensity)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), shadowPaint);
    
    // Add a highlight on the edge
    if (!isBackVisible) {
      final Paint highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3 * shadowIntensity)
        ..style = PaintingStyle.fill;
        
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.1), highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _QuadrantShadowPainter oldDelegate) {
    return oldDelegate.shadowIntensity != shadowIntensity || oldDelegate.isBackVisible != isBackVisible;
  }
}
