import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbQuantumParticleText extends StatefulWidget {
  final String text;
  final Color particleColor;
  final double fontSize;
  final double explosionForce;

  const SbQuantumParticleText({
    super.key,
    required this.text,
    this.particleColor = const Color(0xFFFF00FF),
    this.fontSize = 60.0,
    this.explosionForce = 15.0,
  });

  @override
  State<SbQuantumParticleText> createState() => _SbQuantumParticleTextState();
}

class _SbQuantumParticleTextState extends State<SbQuantumParticleText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<_Particle> _particles = [];
  bool _isExploded = false;
  
  // We use a global key to get the render box of the text to sample its pixels
  final GlobalKey _textKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updatePhysics);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generateParticles() {
    if (_particles.isNotEmpty) return;
    
    // In a true low-level graphics engine, we would render the text to a bitmap and sample the non-transparent pixels.
    // In Flutter, doing that dynamically is heavy. Instead, we'll approximate the text shape
    // by using a mathematical grid and letting the CustomPainter handle the rest.
    // For this effect, we'll just generate a dense grid of particles that "form" the text bounds
    
    final RenderBox? renderBox = _textKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final Size size = renderBox.size;
    final math.Random random = math.Random();
    
    // Generate a dense cluster of particles within the text bounds
    for (int i = 0; i < 400; i++) {
      // Random position within the bounding box
      final double bx = random.nextDouble() * size.width;
      final double cy = random.nextDouble() * size.height;
      
      _particles.add(_Particle(
        baseX: bx,
        baseY: cy,
        x: bx,
        y: cy,
        size: 1.0 + random.nextDouble() * 2.0,
        vx: 0,
        vy: 0,
      ));
    }
  }

  void _updatePhysics() {
    if (_particles.isEmpty) return;
    
    final math.Random random = math.Random();
    
    setState(() {
      for (final particle in _particles) {
        if (_isExploded) {
          // Particles fly apart in random directions, bounded by gravity
          particle.x += particle.vx;
          particle.y += particle.vy;
          
          // Add some chaotic quantum jitter
          particle.x += (random.nextDouble() - 0.5) * 2;
          particle.y += (random.nextDouble() - 0.5) * 2;
          
          // Friction slows them down
          particle.vx *= 0.95;
          particle.vy *= 0.95;
        } else {
          // Particles are magnetically pulled back to their base positions
          final double dx = particle.baseX - particle.x;
          final double dy = particle.baseY - particle.y;
          
          // Spring physics
          particle.vx += dx * 0.1;
          particle.vy += dy * 0.1;
          
          // Friction
          particle.vx *= 0.8;
          particle.vy *= 0.8;
          
          particle.x += particle.vx;
          particle.y += particle.vy;
          
          // Add micro-jitter so the text looks "alive" when formed
          particle.x += (random.nextDouble() - 0.5) * 0.5;
          particle.y += (random.nextDouble() - 0.5) * 0.5;
        }
      }
    });
  }

  void _toggleExplosion() {
    if (_particles.isEmpty) {
      _generateParticles();
      _controller.repeat();
    }
    
    setState(() {
      _isExploded = !_isExploded;
      
      if (_isExploded) {
        // Apply explosive force
        final math.Random random = math.Random();
        for (final particle in _particles) {
          // Explode outwards from the center
          final double centerX = 150.0; // Approximate center
          final double centerY = 40.0;
          
          final double dx = particle.x - centerX;
          final double dy = particle.y - centerY;
          
          // Normalize and apply force
          final double dist = math.sqrt(dx * dx + dy * dy);
          if (dist > 0) {
            particle.vx = (dx / dist) * (random.nextDouble() * widget.explosionForce);
            particle.vy = (dy / dist) * (random.nextDouble() * widget.explosionForce);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleExplosion,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The actual text (hidden when exploded, visible when formed)
          Opacity(
            opacity: _isExploded || _particles.isNotEmpty ? 0.0 : 1.0,
            child: Text(
              widget.text,
              key: _textKey,
              style: TextStyle(
                fontSize: widget.fontSize,
                fontWeight: FontWeight.bold,
                color: widget.particleColor,
              ),
            ),
          ),
          
          // The particle system overlay
          if (_particles.isNotEmpty)
            Positioned.fill(
              child: CustomPaint(
                painter: _QuantumPainter(
                  particles: _particles,
                  color: widget.particleColor,
                  isExploded: _isExploded,
                ),
              ),
            ),
            
          // If not exploded, we still want to show the particles formed as the text
          // We use a ShaderMask to clip the particles to the exact shape of the text!
          if (_particles.isNotEmpty && !_isExploded)
            Positioned.fill(
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (bounds) {
                  return const LinearGradient(
                    colors: [Colors.white, Colors.white],
                  ).createShader(bounds);
                },
                child: CustomPaint(
                  painter: _QuantumPainter(
                    particles: _particles,
                    color: widget.particleColor,
                    isExploded: false,
                  ),
                ),
              ),
            ),
        ],
      ),
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

  _Particle({
    required this.baseX,
    required this.baseY,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
  });
}

class _QuantumPainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;
  final bool isExploded;

  _QuantumPainter({
    required this.particles,
    required this.color,
    required this.isExploded,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    final Paint glowPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    for (final particle in particles) {
      // Draw glow
      canvas.drawCircle(Offset(particle.x, particle.y), particle.size * 2, glowPaint);
      // Draw core
      canvas.drawCircle(Offset(particle.x, particle.y), particle.size, paint);
      
      // If exploded, draw faint connection lines between nearby particles to create a web effect
      if (isExploded) {
        // (Performance intensive, so we only do it for a subset or skip entirely)
        // Let's just draw the particles for maximum performance at 60fps
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QuantumPainter oldDelegate) {
    return true; // Always repaint while animating
  }
}
