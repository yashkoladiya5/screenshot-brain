import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbParticleExplosion extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final int particleCount;
  final List<Color> particleColors;

  const SbParticleExplosion({
    super.key,
    required this.child,
    required this.onTap,
    this.particleCount = 40,
    this.particleColors = const [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
    ],
  });

  @override
  State<SbParticleExplosion> createState() => _SbParticleExplosionState();
}

class _SbParticleExplosionState extends State<SbParticleExplosion> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerExplosion() {
    widget.onTap();
    
    // Generate new particles
    _particles = List.generate(widget.particleCount, (index) {
      final double angle = _random.nextDouble() * 2 * math.pi; // Random 360 degrees
      final double distance = 50.0 + _random.nextDouble() * 100.0; // Random distance 50-150px
      final double size = 4.0 + _random.nextDouble() * 6.0; // Random size 4-10px
      final Color color = widget.particleColors[_random.nextInt(widget.particleColors.length)];
      
      return _Particle(
        angle: angle,
        distance: distance,
        size: size,
        color: color,
      );
    });

    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _triggerExplosion,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // The particles
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              if (_controller.value == 0.0 || _controller.value == 1.0) {
                return const SizedBox.shrink();
              }
              
              return Stack(
                clipBehavior: Clip.none,
                children: _particles.map((particle) {
                  // Easing curve for the distance (starts fast, slows down)
                  final double progress = Curves.easeOutCirc.transform(_controller.value);
                  
                  // Calculate current X and Y based on angle and progress
                  final double dx = math.cos(particle.angle) * particle.distance * progress;
                  final double dy = math.sin(particle.angle) * particle.distance * progress;
                  
                  // Fade out in the second half of the animation
                  final double opacity = _controller.value > 0.5 
                      ? (1.0 - ((_controller.value - 0.5) * 2)).clamp(0.0, 1.0)
                      : 1.0;

                  return Transform.translate(
                    offset: Offset(dx, dy),
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: particle.size,
                        height: particle.size,
                        decoration: BoxDecoration(
                          color: particle.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          
          // The original widget (e.g. a button)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Add a tiny bump animation to the button itself
              final double scale = _controller.value == 0.0 || _controller.value == 1.0 
                  ? 1.0 
                  : 1.0 - (math.sin(_controller.value * math.pi) * 0.1);
                  
              return Transform.scale(
                scale: scale,
                child: widget.child,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Particle {
  final double angle;
  final double distance;
  final double size;
  final Color color;

  _Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
  });
}
