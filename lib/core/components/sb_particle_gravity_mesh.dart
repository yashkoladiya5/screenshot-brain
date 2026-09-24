import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbParticleGravityMesh extends StatefulWidget {
  final int particleCount;
  final Color particleColor;
  final Color lineColor;
  final double connectionDistance;
  final Color backgroundColor;

  const SbParticleGravityMesh({
    super.key,
    this.particleCount = 40,
    this.particleColor = const Color(0xFF00FFCC),
    this.lineColor = const Color(0x6600FFCC),
    this.connectionDistance = 120.0,
    this.backgroundColor = const Color(0xFF0F172A),
  });

  @override
  State<SbParticleGravityMesh> createState() => _SbParticleGravityMeshState();
}

class _SbParticleGravityMeshState extends State<SbParticleGravityMesh> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();
  
  Offset? _touchPosition;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // ~60fps
    )..addListener(_updatePhysics);
    
    _controller.repeat();
  }

  void _initParticles(Size size) {
    if (_particles.isNotEmpty) return;
    
    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(_Particle(
        position: Offset(
          _random.nextDouble() * size.width,
          _random.nextDouble() * size.height,
        ),
        velocity: Offset(
          (_random.nextDouble() - 0.5) * 2,
          (_random.nextDouble() - 0.5) * 2,
        ),
        radius: 2.0 + _random.nextDouble() * 3.0,
      ));
    }
  }

  void _updatePhysics() {
    if (_particles.isEmpty) return;
    
    final Size size = MediaQuery.of(context).size;
    
    setState(() {
      for (final particle in _particles) {
        // Apply base velocity
        particle.position += particle.velocity;
        
        // Apply gravitational pull towards finger if touching
        if (_touchPosition != null) {
          final Offset vectorToFinger = _touchPosition! - particle.position;
          final double distance = vectorToFinger.distance;
          
          if (distance > 0 && distance < 300) {
            // Gravity is stronger when closer
            final double gravityStrength = (300 - distance) / 3000.0;
            particle.velocity += vectorToFinger * gravityStrength;
            
            // Limit max speed when being pulled
            if (particle.velocity.distance > 8.0) {
              particle.velocity = (particle.velocity / particle.velocity.distance) * 8.0;
            }
          }
        }
        
        // Bounce off walls
        if (particle.position.dx < 0 || particle.position.dx > size.width) {
          particle.velocity = Offset(-particle.velocity.dx, particle.velocity.dy);
          particle.position = Offset(
            particle.position.dx.clamp(0.0, size.width),
            particle.position.dy
          );
        }
        
        if (particle.position.dy < 0 || particle.position.dy > size.height) {
          particle.velocity = Offset(particle.velocity.dx, -particle.velocity.dy);
          particle.position = Offset(
            particle.position.dx,
            particle.position.dy.clamp(0.0, size.height)
          );
        }
        
        // Add subtle friction if moving too fast
        if (particle.velocity.distance > 2.0 && _touchPosition == null) {
          particle.velocity *= 0.95;
        }
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_particles.isEmpty && mounted) {
        _initParticles(MediaQuery.of(context).size);
      }
    });

    return GestureDetector(
      onPanDown: (details) => _touchPosition = details.localPosition,
      onPanUpdate: (details) => _touchPosition = details.localPosition,
      onPanEnd: (_) => _touchPosition = null,
      onPanCancel: () => _touchPosition = null,
      child: Container(
        color: widget.backgroundColor,
        width: double.infinity,
        height: double.infinity,
        child: CustomPaint(
          painter: _MeshPainter(
            particles: _particles,
            particleColor: widget.particleColor,
            lineColor: widget.lineColor,
            connectionDistance: widget.connectionDistance,
            touchPosition: _touchPosition,
          ),
        ),
      ),
    );
  }
}

class _Particle {
  Offset position;
  Offset velocity;
  final double radius;

  _Particle({
    required this.position,
    required this.velocity,
    required this.radius,
  });
}

class _MeshPainter extends CustomPainter {
  final List<_Particle> particles;
  final Color particleColor;
  final Color lineColor;
  final double connectionDistance;
  final Offset? touchPosition;

  _MeshPainter({
    required this.particles,
    required this.particleColor,
    required this.lineColor,
    required this.connectionDistance,
    required this.touchPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint particlePaint = Paint()
      ..color = particleColor
      ..style = PaintingStyle.fill;
      
    // Draw connections first so they are behind particles
    for (int i = 0; i < particles.length; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        final double distance = (particles[i].position - particles[j].position).distance;
        
        if (distance < connectionDistance) {
          // Line opacity fades out as distance increases
          final double opacityMultiplier = 1.0 - (distance / connectionDistance);
          
          final Paint linePaint = Paint()
            ..color = lineColor.withValues(alpha: lineColor.a * opacityMultiplier)
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke;
            
          canvas.drawLine(particles[i].position, particles[j].position, linePaint);
        }
      }
      
      // Draw connection to finger if touching
      if (touchPosition != null) {
        final double fingerDistance = (particles[i].position - touchPosition!).distance;
        if (fingerDistance < connectionDistance * 1.5) {
          final double opacityMultiplier = 1.0 - (fingerDistance / (connectionDistance * 1.5));
          
          final Paint fingerLinePaint = Paint()
            ..color = particleColor.withValues(alpha: opacityMultiplier)
            ..strokeWidth = 2.0
            ..style = PaintingStyle.stroke;
            
          canvas.drawLine(particles[i].position, touchPosition!, fingerLinePaint);
        }
      }
    }
    
    // Draw particles
    for (final particle in particles) {
      canvas.drawCircle(particle.position, particle.radius, particlePaint);
      
      // Add a subtle glow
      final Paint glowPaint = Paint()
        ..color = particleColor.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(particle.position, particle.radius * 2, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MeshPainter oldDelegate) {
    return true; // Particles constantly moving
  }
}
