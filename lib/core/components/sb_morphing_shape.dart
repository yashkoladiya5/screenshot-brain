import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbMorphingShape extends StatefulWidget {
  final double size;
  final Color? color;
  final double speedMultiplier;
  final Widget? child;

  const SbMorphingShape({
    super.key,
    this.size = 200.0,
    this.color,
    this.speedMultiplier = 1.0,
    this.child,
  });

  @override
  State<SbMorphingShape> createState() => _SbMorphingShapeState();
}

class _SbMorphingShapeState extends State<SbMorphingShape> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (4000 ~/ widget.speedMultiplier)),
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
    final shapeColor = widget.color ?? theme.colorScheme.primaryContainer;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ClipPath(
          clipper: _OrganicBlobClipper(
            progress: _controller.value,
          ),
          child: Container(
            width: widget.size,
            height: widget.size,
            color: shapeColor,
            alignment: Alignment.center,
            child: widget.child,
          ),
        );
      },
    );
  }
}

class _OrganicBlobClipper extends CustomClipper<Path> {
  final double progress;

  _OrganicBlobClipper({required this.progress});

  @override
  Path getClip(Size size) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // We use a combination of sine waves based on the angle and time (progress)
    // to calculate a continuously morphing radius for a blob shape.
    
    // The number of "lobes" or points on the blob
    const numPoints = 8;
    
    // Time variable mapped to radians
    final t = progress * math.pi * 2;

    // Start path at angle 0
    double getRadiusForAngle(double angle) {
      // Complex waveform to make it look organic
      final wave1 = math.sin(angle * 3 + t) * 0.1;
      final wave2 = math.cos(angle * 2 - t * 1.5) * 0.08;
      final wave3 = math.sin(angle * 5 + t * 2) * 0.04;
      
      // Base radius (0.75) + waves, keeps it mostly circular but squishy
      return radius * (0.78 + wave1 + wave2 + wave3);
    }

    final double startRadius = getRadiusForAngle(0);
    path.moveTo(center.dx + startRadius, center.dy);

    for (int i = 1; i <= numPoints * 4; i++) { // higher resolution for smoothness
      final angle = (i * math.pi * 2) / (numPoints * 4);
      final r = getRadiusForAngle(angle);
      
      final dx = center.dx + math.cos(angle) * r;
      final dy = center.dy + math.sin(angle) * r;
      
      path.lineTo(dx, dy);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _OrganicBlobClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}
