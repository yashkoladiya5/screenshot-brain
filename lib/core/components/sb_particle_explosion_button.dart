import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbParticleExplosionButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color particleColor;
  final int particleCount;
  final double width;
  final double height;

  const SbParticleExplosionButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.particleColor = const Color(0xFFFF4081),
    this.particleCount = 30,
    this.width = 200.0,
    this.height = 60.0,
  });

  @override
  State<SbParticleExplosionButton> createState() => _SbParticleExplosionButtonState();
}

class _SbParticleExplosionButtonState extends State<SbParticleExplosionButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final math.Random _random = math.Random();
  final List<_Particle> _particles = [];
  bool _isExploding = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _controller.addListener(() {
      setState(() {});
    });
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isExploding = false;
        });
        _controller.reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerExplosion() {
    if (_isExploding) return;

    // Generate random particles
    _particles.clear();
    for (int i = 0; i < widget.particleCount; i++) {
      // Random angle (0 to 2pi)
      final double angle = _random.nextDouble() * 2 * math.pi;
      
      // Random velocity/distance multiplier
      final double velocity = 50.0 + _random.nextDouble() * 100.0;
      
      // Random size
      final double size = 3.0 + _random.nextDouble() * 6.0;

      _particles.add(_Particle(
        angle: angle,
        velocity: velocity,
        size: size,
      ));
    }

    setState(() {
      _isExploding = true;
    });
    
    _controller.forward(from: 0.0);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width + 150, // Add padding for particles to explode into
      height: widget.height + 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The particles
          if (_isExploding)
            CustomPaint(
              size: Size(widget.width + 150, widget.height + 150),
              painter: _ParticlePainter(
                particles: _particles,
                progress: Curves.easeOutCubic.transform(_controller.value),
                color: widget.particleColor,
              ),
            ),
            
          // The button itself
          GestureDetector(
            onTap: _triggerExplosion,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // Button scales down slightly when tapped, then bounces back
                final double scale = _controller.isAnimating 
                    ? 1.0 - (math.sin(_controller.value * math.pi) * 0.1)
                    : 1.0;
                    
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: widget.width,
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: widget.particleColor,
                      borderRadius: BorderRadius.circular(30.0),
                      boxShadow: [
                        BoxShadow(
                          color: widget.particleColor.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ]
                    ),
                    alignment: Alignment.center,
                    child: widget.child,
                  ),
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle {
  final double angle;
  final double velocity;
  final double size;

  _Particle({
    required this.angle,
    required this.velocity,
    required this.size,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    
    for (final particle in particles) {
      // Calculate current position based on velocity and progress
      final double distance = particle.velocity * progress;
      final double dx = center.dx + math.cos(particle.angle) * distance;
      final double dy = center.dy + math.sin(particle.angle) * distance;
      
      // Calculate current opacity (fade out as they expand)
      final double opacity = (1.0 - progress).clamp(0.0, 1.0);
      
      // Calculate current size (shrink as they fade)
      final double currentSize = particle.size * opacity;
      
      if (currentSize > 0) {
        final Paint paint = Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;
          
        canvas.drawCircle(Offset(dx, dy), currentSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.particles != particles;
  }
}
