import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbInteractiveMagneticParticles extends StatefulWidget {
  final int count;
  final Color particleColor;
  final double magneticRadius;
  final double explosionForce;

  const SbInteractiveMagneticParticles({
    super.key,
    this.count = 250,
    this.particleColor = const Color(0xFF00E5FF),
    this.magneticRadius = 150.0,
    this.explosionForce = 15.0,
  });

  @override
  State<SbInteractiveMagneticParticles> createState() => _SbInteractiveMagneticParticlesState();
}

class _SbInteractiveMagneticParticlesState extends State<SbInteractiveMagneticParticles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<_Particle> _particles = [];
  Offset? _touchPosition;
  bool _isExploding = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updatePhysics);
  }

  void _initParticles(Size size) {
    if (_particles.isNotEmpty) return;
    
    final math.Random random = math.Random();
    _particles = List.generate(widget.count, (index) {
      final double x = random.nextDouble() * size.width;
      final double y = random.nextDouble() * size.height;
      return _Particle(
        baseX: x,
        baseY: y,
        x: x,
        y: y,
        vx: 0,
        vy: 0,
        size: 1.0 + random.nextDouble() * 3.0,
        mass: 0.5 + random.nextDouble() * 1.5,
      );
    });
    _controller.repeat();
  }

  void _updatePhysics() {
    if (_particles.isEmpty || !mounted) return;
    
    setState(() {
      for (final particle in _particles) {
        // 1. Magnetic Touch Interaction
        if (_touchPosition != null) {
          final double dx = _touchPosition!.dx - particle.x;
          final double dy = _touchPosition!.dy - particle.y;
          final double dist = math.sqrt(dx * dx + dy * dy);
          
          if (dist < widget.magneticRadius && dist > 0) {
            // Magnetic force (pulls towards finger)
            final double force = (widget.magneticRadius - dist) / widget.magneticRadius;
            
            if (_isExploding) {
              // Push violently away
              particle.vx -= (dx / dist) * force * widget.explosionForce / particle.mass;
              particle.vy -= (dy / dist) * force * widget.explosionForce / particle.mass;
            } else {
              // Pull gently towards
              particle.vx += (dx / dist) * force * 2.0 / particle.mass;
              particle.vy += (dy / dist) * force * 2.0 / particle.mass;
            }
          }
        }
        
        // 2. Base position spring physics (pulls back to where they started)
        final double springX = particle.baseX - particle.x;
        final double springY = particle.baseY - particle.y;
        
        // Very gentle spring so they can swarm the finger
        particle.vx += springX * 0.01;
        particle.vy += springY * 0.01;
        
        // 3. Friction
        particle.vx *= 0.85;
        particle.vy *= 0.85;
        
        // 4. Update Position
        particle.x += particle.vx;
        particle.y += particle.vy;
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
        _initParticles(Size(constraints.maxWidth, constraints.maxHeight));
        
        return GestureDetector(
          onPanDown: (details) {
            setState(() {
              _touchPosition = details.localPosition;
              _isExploding = false;
            });
          },
          onPanUpdate: (details) {
            setState(() {
              _touchPosition = details.localPosition;
            });
          },
          onPanEnd: (_) {
            setState(() {
              _isExploding = true;
              // We leave touch position active for a moment to trigger the explosion force
            });
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                setState(() {
                  _touchPosition = null;
                  _isExploding = false;
                });
              }
            });
          },
          onPanCancel: () {
            setState(() {
              _touchPosition = null;
            });
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: Colors.black87,
            width: double.infinity,
            height: double.infinity,
            child: CustomPaint(
              painter: _MagneticParticlePainter(
                particles: _particles,
                color: widget.particleColor,
              ),
            ),
          ),
        );
      }
    );
  }
}

class _Particle {
  final double baseX;
  final double baseY;
  double x;
  double y;
  double vx;
  double vy;
  final double size;
  final double mass;

  _Particle({
    required this.baseX,
    required this.baseY,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.mass,
  });
}

class _MagneticParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;

  _MagneticParticlePainter({
    required this.particles,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    final Paint glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    // To create the cool connecting web effect, we draw lines between nearby particles
    // But O(N^2) is too slow for 250 particles. We'll just draw connections for a subset.
    final Paint linePaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int i = 0; i < particles.length; i++) {
      final particle = particles[i];
      
      canvas.drawCircle(Offset(particle.x, particle.y), particle.size * 2, glowPaint);
      canvas.drawCircle(Offset(particle.x, particle.y), particle.size, paint);
      
      // Draw web for first 50 particles
      if (i < 50) {
        for (int j = i + 1; j < particles.length; j++) {
          final other = particles[j];
          final double dx = particle.x - other.x;
          final double dy = particle.y - other.y;
          final double distSq = dx * dx + dy * dy;
          
          if (distSq < 2500) { // 50 pixels squared
            canvas.drawLine(Offset(particle.x, particle.y), Offset(other.x, other.y), linePaint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MagneticParticlePainter oldDelegate) {
    return true; // Always repainting
  }
}
