import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbInteractiveBlackHole extends StatefulWidget {
  final double size;
  final Color accentColor;
  final int particleCount;

  const SbInteractiveBlackHole({
    super.key,
    this.size = double.infinity,
    this.accentColor = const Color(0xFFFF0055), // Accretion disk color
    this.particleCount = 150,
  });

  @override
  State<SbInteractiveBlackHole> createState() => _SbInteractiveBlackHoleState();
}

class _SbInteractiveBlackHoleState extends State<SbInteractiveBlackHole> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<_SpaceParticle> _particles = [];
  
  Offset _holePosition = Offset(200, 400); // Default, updated on layout
  double _holeMass = 10.0;
  bool _isDragging = false;
  
  Size _screenSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // 60fps
    )..addListener(_updatePhysics);
  }

  void _initSpace(Size size) {
    if (_particles.isNotEmpty) return;
    _screenSize = size;
    _holePosition = Offset(size.width / 2, size.height / 2);
    
    final math.Random random = math.Random();
    _particles = List.generate(widget.particleCount, (index) {
      return _SpaceParticle(
        x: random.nextDouble() * size.width,
        y: random.nextDouble() * size.height,
        vx: (random.nextDouble() - 0.5) * 2,
        vy: (random.nextDouble() - 0.5) * 2,
        size: 1.0 + random.nextDouble() * 2.0,
        mass: 0.1 + random.nextDouble() * 0.9,
      );
    });
    
    _controller.repeat();
  }

  void _updatePhysics() {
    if (_particles.isEmpty || !mounted) return;
    
    final math.Random random = math.Random();
    
    setState(() {
      // The black hole pulses slightly
      if (!_isDragging) {
        _holeMass = 10.0 + math.sin(_controller.lastElapsedDuration?.inMilliseconds.toDouble() ?? 0 / 200) * 2.0;
      }

      for (final particle in _particles) {
        // Calculate gravitational pull towards the black hole
        final double dx = _holePosition.dx - particle.x;
        final double dy = _holePosition.dy - particle.y;
        final double distSq = dx * dx + dy * dy;
        final double dist = math.sqrt(distSq);
        
        // Event horizon radius
        final double eventHorizon = _holeMass * 4.0;
        
        if (dist > 5.0) { // Avoid division by zero and extreme singularity acceleration
          // Gravity formula: F = G * (m1 * m2) / r^2
          // We simplify it for the visual effect
          final double force = (_holeMass * particle.mass * 50.0) / distSq;
          
          particle.vx += (dx / dist) * force;
          particle.vy += (dy / dist) * force;
          
          // Add a perpendicular force to create an accretion disk (orbit) effect
          final double perpX = -dy / dist;
          final double perpY = dx / dist;
          
          // The closer they get, the faster they orbit
          final double orbitForce = 150.0 / (dist + 10.0);
          particle.vx += perpX * orbitForce * particle.mass;
          particle.vy += perpY * orbitForce * particle.mass;
        }
        
        // Friction (vacuum isn't perfect here)
        particle.vx *= 0.98;
        particle.vy *= 0.98;
        
        particle.x += particle.vx;
        particle.y += particle.vy;
        
        // If particle falls into the event horizon, teleport it far away
        if (dist < eventHorizon) {
          // Respawn at the edge of the screen
          if (random.nextBool()) {
            particle.x = random.nextBool() ? 0 : _screenSize.width;
            particle.y = random.nextDouble() * _screenSize.height;
          } else {
            particle.x = random.nextDouble() * _screenSize.width;
            particle.y = random.nextBool() ? 0 : _screenSize.height;
          }
          // Reset velocity
          particle.vx = (random.nextDouble() - 0.5) * 2;
          particle.vy = (random.nextDouble() - 0.5) * 2;
        }
      }
    });
  }

  void _onPanDown(DragDownDetails details) {
    setState(() {
      _isDragging = true;
      _holePosition = details.localPosition;
      _holeMass = 25.0; // Mass increases significantly when dragging
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _holePosition = details.localPosition;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _holeMass = 10.0;
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
        _initSpace(Size(constraints.maxWidth, constraints.maxHeight));
        
        return GestureDetector(
          onPanDown: _onPanDown,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onPanCancel: () => _onPanEnd(DragEndDetails()),
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: Colors.black, // Deep space
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                // The particles and accretion disk
                CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _BlackHolePainter(
                    particles: _particles,
                    holePosition: _holePosition,
                    holeMass: _holeMass,
                    accentColor: widget.accentColor,
                    time: _controller.lastElapsedDuration?.inMilliseconds.toDouble() ?? 0.0,
                  ),
                ),
                
                // The Singularity (pitch black center)
                Positioned(
                  left: _holePosition.dx - (_holeMass * 3.5),
                  top: _holePosition.dy - (_holeMass * 3.5),
                  child: Container(
                    width: _holeMass * 7.0,
                    height: _holeMass * 7.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black,
                          blurRadius: 10,
                          spreadRadius: 5,
                        )
                      ]
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      }
    );
  }
}

class _SpaceParticle {
  double x;
  double y;
  double vx;
  double vy;
  final double size;
  final double mass;

  _SpaceParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.mass,
  });
}

class _BlackHolePainter extends CustomPainter {
  final List<_SpaceParticle> particles;
  final Offset holePosition;
  final double holeMass;
  final Color accentColor;
  final double time;

  _BlackHolePainter({
    required this.particles,
    required this.holePosition,
    required this.holeMass,
    required this.accentColor,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw the accretion disk glow
    final double diskRadius = holeMass * 12.0;
    
    // Rotating gravitational waves
    final Rect rect = Rect.fromCircle(center: holePosition, radius: diskRadius);
    
    final Paint diskPaint = Paint()
      ..shader = SweepGradient(
        center: FractionalOffset.center,
        colors: [
          accentColor.withValues(alpha: 0.0),
          accentColor.withValues(alpha: 0.6),
          accentColor.withValues(alpha: 0.0),
          accentColor.withValues(alpha: 0.8),
          accentColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        transform: GradientRotation(time / 500.0), // Spin the gradient
      ).createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      
    canvas.drawCircle(holePosition, diskRadius, diskPaint);

    // 2. Draw the particles
    final Paint particlePaint = Paint()..style = PaintingStyle.fill;
    
    for (final particle in particles) {
      // Calculate how close it is to the hole to apply relativistic color shift
      final double dx = holePosition.dx - particle.x;
      final double dy = holePosition.dy - particle.y;
      final double dist = math.sqrt(dx * dx + dy * dy);
      
      // As particles approach the event horizon, they heat up and shift towards the accent color,
      // and they stretch due to spaghettification
      double spaghettification = 1.0;
      Color pColor = Colors.white.withValues(alpha: 0.6);
      
      if (dist < diskRadius * 1.5) {
        final double heat = 1.0 - (dist / (diskRadius * 1.5));
        pColor = Color.lerp(Colors.white, accentColor, heat)!;
        spaghettification = 1.0 + (heat * 3.0); // Stretch up to 4x
      }
      
      particlePaint.color = pColor;
      
      if (spaghettification > 1.2) {
        // Draw stretched particle (ellipse) aligned with velocity vector
        canvas.save();
        canvas.translate(particle.x, particle.y);
        final double angle = math.atan2(particle.vy, particle.vx);
        canvas.rotate(angle);
        
        final Rect pRect = Rect.fromCenter(
          center: Offset.zero, 
          width: particle.size * spaghettification, 
          height: particle.size / (spaghettification * 0.5).clamp(1.0, 3.0)
        );
        canvas.drawOval(pRect, particlePaint);
        
        canvas.restore();
      } else {
        // Normal spherical particle
        canvas.drawCircle(Offset(particle.x, particle.y), particle.size, particlePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BlackHolePainter oldDelegate) {
    return true; // Always repainting due to continuous physics loop
  }
}
