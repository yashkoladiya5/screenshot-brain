import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbParticle {
  double x;
  double y;
  double vx;
  double vy;
  double radius;
  Color color;

  SbParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.color,
  });

  void update(Size size) {
    x += vx;
    y += vy;

    // Bounce off walls
    if (x <= 0 || x >= size.width) vx *= -1;
    if (y <= 0 || y >= size.height) vy *= -1;
    
    // Clamp to ensure they don't escape during resize
    x = x.clamp(0.0, size.width);
    y = y.clamp(0.0, size.height);
  }
}

class SbParticlesBackground extends StatefulWidget {
  final Widget? child;
  final int particleCount;
  final double maxSpeed;
  final double connectionDistance;
  final Color particleColor;
  final Color lineColor;
  final Color? backgroundColor;

  const SbParticlesBackground({
    super.key,
    this.child,
    this.particleCount = 50,
    this.maxSpeed = 1.0,
    this.connectionDistance = 100.0,
    this.particleColor = const Color(0x66FFFFFF),
    this.lineColor = const Color(0x33FFFFFF),
    this.backgroundColor,
  });

  @override
  State<SbParticlesBackground> createState() => _SbParticlesBackgroundState();
}

class _SbParticlesBackgroundState extends State<SbParticlesBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<SbParticle> _particles = [];
  final math.Random _random = math.Random();
  Size _lastSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
        if (_lastSize != Size.zero) {
          _updateParticles();
        }
      });
      
    _controller.repeat();
  }

  void _initParticles(Size size) {
    _particles.clear();
    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(SbParticle(
        x: _random.nextDouble() * size.width,
        y: _random.nextDouble() * size.height,
        vx: (_random.nextDouble() * 2 - 1) * widget.maxSpeed,
        vy: (_random.nextDouble() * 2 - 1) * widget.maxSpeed,
        radius: _random.nextDouble() * 2 + 1.5,
        color: widget.particleColor,
      ));
    }
  }

  void _updateParticles() {
    setState(() {
      for (var p in _particles) {
        p.update(_lastSize);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        
        // Initialize particles only once or if size radically changes (e.g., orientation change)
        if (_lastSize == Size.zero || 
            (_lastSize.width - size.width).abs() > 100 || 
            (_lastSize.height - size.height).abs() > 100) {
          _lastSize = size;
          // Defer particle initialization until after build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initParticles(size);
          });
        } else {
          _lastSize = size;
        }

        return Container(
          color: widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                size: size,
                painter: _ParticlesPainter(
                  particles: _particles,
                  connectionDistance: widget.connectionDistance,
                  lineColor: widget.lineColor,
                ),
              ),
              if (widget.child != null) widget.child!,
            ],
          ),
        );
      },
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  final List<SbParticle> particles;
  final double connectionDistance;
  final Color lineColor;

  _ParticlesPainter({
    required this.particles,
    required this.connectionDistance,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw connecting lines
    for (int i = 0; i < particles.length; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        final p1 = particles[i];
        final p2 = particles[j];
        
        final dx = p1.x - p2.x;
        final dy = p1.y - p2.y;
        final distance = math.sqrt(dx * dx + dy * dy);

        if (distance < connectionDistance) {
          // Opacity decreases as distance increases
          final opacity = (1.0 - (distance / connectionDistance)).clamp(0.0, 1.0);
          final paint = Paint()
            ..color = lineColor.withValues(alpha: lineColor.a * opacity)
            ..strokeWidth = 1.0;
            
          canvas.drawLine(Offset(p1.x, p1.y), Offset(p2.x, p2.y), paint);
        }
      }
    }

    // 2. Draw particles (nodes)
    for (var p in particles) {
      final paint = Paint()..color = p.color;
      canvas.drawCircle(Offset(p.x, p.y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) => true; // Constantly animating
}
