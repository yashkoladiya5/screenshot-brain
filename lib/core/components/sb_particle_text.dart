import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbTextParticle {
  double x;
  double y;
  final double targetX;
  final double targetY;
  double vx = 0;
  double vy = 0;
  final Color color;

  SbTextParticle({
    required this.x,
    required this.y,
    required this.targetX,
    required this.targetY,
    required this.color,
  });

  void update(Offset? mousePos) {
    // 1. Spring force pulling towards target
    final double dx = targetX - x;
    final double dy = targetY - y;
    
    // Spring physics constants
    const double spring = 0.05;
    const double friction = 0.85;

    vx += dx * spring;
    vy += dy * spring;

    // 2. Mouse repulsion force
    if (mousePos != null) {
      final double mdx = x - mousePos.dx;
      final double mdy = y - mousePos.dy;
      final double distSq = (mdx * mdx) + (mdy * mdy);
      
      const double repelRadiusSq = 50.0 * 50.0;
      if (distSq < repelRadiusSq) {
        final double force = (repelRadiusSq - distSq) / repelRadiusSq;
        // Normalization approximation for speed
        final double length = math.sqrt(distSq) + 0.001; 
        vx += (mdx / length) * force * 10.0;
        vy += (mdy / length) * force * 10.0;
      }
    }

    // Apply friction
    vx *= friction;
    vy *= friction;

    // Apply velocity
    x += vx;
    y += vy;
  }
}

class SbParticleText extends StatefulWidget {
  final String text;
  final double particleDensity; // Lower is more particles
  final Color color;
  final double width;
  final double height;

  const SbParticleText({
    super.key,
    required this.text,
    this.particleDensity = 2.0,
    this.color = Colors.cyanAccent,
    this.width = 300.0,
    this.height = 100.0,
  });

  @override
  State<SbParticleText> createState() => _SbParticleTextState();
}

class _SbParticleTextState extends State<SbParticleText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<SbTextParticle> _particles = [];
  Offset? _mousePos;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
        setState(() {
          for (var p in _particles) {
            p.update(_mousePos);
          }
        });
      });

    // Instead of reading pixels from a canvas (which is very hard in Flutter without dart:ui Image),
    // we will procedurally generate particles for a few specific characters for this demo.
    _generateParticles();
    
    _controller.repeat();
  }

  void _generateParticles() {
    // Extremely simplified procedural font generation
    // We will just map the text to a grid and draw hardcoded shapes for letters
    // A real implementation would render text to an offscreen canvas, read the pixels, and spawn particles on non-transparent pixels.
    
    _particles.clear();
    final math.Random random = math.Random();
    
    double startX = 20.0;
    const double startY = 20.0;
    const double letterWidth = 30.0;
    const double letterHeight = 50.0;
    const double spacing = 40.0;

    for (int i = 0; i < widget.text.length; i++) {
      final char = widget.text[i].toUpperCase();
      
      final double cx = startX + (i * spacing);
      final double cy = startY;

      List<Offset> targetPoints = [];
      
      // Procedurally generate target points for common letters
      // Just a few for the demo
      if (char == 'H') {
        _addLine(targetPoints, cx, cy, cx, cy + letterHeight);
        _addLine(targetPoints, cx + letterWidth, cy, cx + letterWidth, cy + letterHeight);
        _addLine(targetPoints, cx, cy + letterHeight/2, cx + letterWidth, cy + letterHeight/2);
      } else if (char == 'I') {
        _addLine(targetPoints, cx + letterWidth/2, cy, cx + letterWidth/2, cy + letterHeight);
        _addLine(targetPoints, cx, cy, cx + letterWidth, cy);
        _addLine(targetPoints, cx, cy + letterHeight, cx + letterWidth, cy + letterHeight);
      } else if (char == 'O') {
        _addLine(targetPoints, cx, cy, cx, cy + letterHeight);
        _addLine(targetPoints, cx + letterWidth, cy, cx + letterWidth, cy + letterHeight);
        _addLine(targetPoints, cx, cy, cx + letterWidth, cy);
        _addLine(targetPoints, cx, cy + letterHeight, cx + letterWidth, cy + letterHeight);
      } else {
        // Fallback: Just draw a box
        _addLine(targetPoints, cx, cy, cx, cy + letterHeight);
        _addLine(targetPoints, cx + letterWidth, cy, cx + letterWidth, cy + letterHeight);
        _addLine(targetPoints, cx, cy, cx + letterWidth, cy);
        _addLine(targetPoints, cx, cy + letterHeight, cx + letterWidth, cy + letterHeight);
      }
      
      // Spawn particles at random locations, assigned to these target points
      for (var target in targetPoints) {
        _particles.add(SbTextParticle(
          x: random.nextDouble() * widget.width,
          y: random.nextDouble() * widget.height,
          targetX: target.dx,
          targetY: target.dy,
          color: widget.color,
        ));
      }
    }
  }

  void _addLine(List<Offset> points, double x1, double y1, double x2, double y2) {
    // Interpolate points along the line based on density
    final double dx = x2 - x1;
    final double dy = y2 - y1;
    final double length = math.sqrt((dx * dx) + (dy * dy));
    final int numPoints = (length / widget.particleDensity).ceil();
    
    for (int i = 0; i <= numPoints; i++) {
      final double t = i / numPoints;
      points.add(Offset(x1 + (dx * t), y1 + (dy * t)));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        setState(() {
          _mousePos = event.localPosition;
        });
      },
      onExit: (_) {
        setState(() {
          _mousePos = null;
        });
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        color: Colors.black87,
        child: CustomPaint(
          painter: _ParticlePainter(particles: _particles),
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<SbTextParticle> particles;

  _ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      canvas.drawRect(
        Rect.fromCenter(center: Offset(p.x, p.y), width: 2.0, height: 2.0),
        Paint()..color = p.color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true; // Constant animation
}
