import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbKaleidoscopeLens extends StatefulWidget {
  final Widget child;
  final int segments;
  final double size;
  final double rotationSpeed;

  const SbKaleidoscopeLens({
    super.key,
    required this.child,
    this.segments = 6,
    this.size = 300.0,
    this.rotationSpeed = 0.5,
  }) : assert(segments > 1, 'Segments must be at least 2');

  @override
  State<SbKaleidoscopeLens> createState() => _SbKaleidoscopeLensState();
}

class _SbKaleidoscopeLensState extends State<SbKaleidoscopeLens> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // Interactive variables
  double _touchX = 0;
  double _touchY = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _touchX += details.delta.dx;
      _touchY += details.delta.dy;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              // We slice a circle into N triangular segments.
              // To create the kaleidoscope reflection, every alternating segment is mirrored.
              // We use ClipPath to cut out one triangle, and Transform to duplicate and rotate it.
              
              final double anglePerSegment = (math.pi * 2) / widget.segments;
              
              return Stack(
                children: List.generate(widget.segments, (index) {
                  // Calculate the absolute rotation for this segment
                  final double rotationAngle = index * anglePerSegment;
                  
                  // Alternating segments are mirrored
                  final bool isMirrored = index % 2 != 0;
                  
                  // Base transform: Rotate the segment into place
                  final Matrix4 segmentTransform = Matrix4.identity()
                    ..translate(widget.size / 2, widget.size / 2) // Move to center
                    ..rotateZ(rotationAngle) // Rotate
                    ..scale(isMirrored ? -1.0 : 1.0, 1.0) // Mirror horizontally if needed
                    ..translate(-widget.size / 2, -widget.size / 2); // Move back

                  // Inner content transform: Rotate the child widget slowly, 
                  // and offset it based on touch gestures
                  final Matrix4 contentTransform = Matrix4.identity()
                    ..translate(widget.size / 2, widget.size / 2)
                    ..rotateZ(_controller.value * math.pi * 2 * widget.rotationSpeed)
                    ..translate(-widget.size / 2 + _touchX, -widget.size / 2 + _touchY);

                  return Transform(
                    transform: segmentTransform,
                    alignment: Alignment.center,
                    child: ClipPath(
                      clipper: _KaleidoscopeClipper(angle: anglePerSegment),
                      child: Transform(
                        transform: contentTransform,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: widget.size,
                          height: widget.size,
                          child: widget.child,
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Cuts out a perfect "slice of pie" triangle from the center of the widget
class _KaleidoscopeClipper extends CustomClipper<Path> {
  final double angle;

  _KaleidoscopeClipper({required this.angle});

  @override
  Path getClip(Size size) {
    final Path path = Path();
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = size.width; // Large enough to cover corners

    path.moveTo(centerX, centerY);
    
    // We draw from the center (which we consider angle 0, pointing straight down)
    // to +angle. We actually center it around 0 by drawing from -angle/2 to +angle/2
    
    final double startAngle = -angle / 2;
    final double endAngle = angle / 2;
    
    // Point 1: Corner on the circle edge
    path.lineTo(
      centerX + math.sin(startAngle) * radius,
      centerY + math.cos(startAngle) * radius,
    );
    
    // Point 2: Arc to the other corner
    // For simplicity and since we don't care about the outer edge shape (it's clipped by the parent if needed),
    // we can just draw a straight line to the end angle
    path.lineTo(
      centerX + math.sin(endAngle) * radius,
      centerY + math.cos(endAngle) * radius,
    );
    
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _KaleidoscopeClipper oldClipper) {
    return oldClipper.angle != angle;
  }
}
