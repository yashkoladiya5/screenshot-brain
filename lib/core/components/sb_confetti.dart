import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbConfettiController extends ChangeNotifier {
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  void play() {
    _isPlaying = true;
    notifyListeners();
  }

  void stop() {
    _isPlaying = false;
    notifyListeners();
  }
}

class SbConfettiParticle {
  double x;
  double y;
  double velocityX;
  double velocityY;
  double angle;
  double angularVelocity;
  final Color color;
  final double size;

  SbConfettiParticle({
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.angle,
    required this.angularVelocity,
    required this.color,
    required this.size,
  });

  void update(double gravity, double drag) {
    velocityY += gravity;
    velocityX *= drag;
    velocityY *= drag;
    
    x += velocityX;
    y += velocityY;
    
    angle += angularVelocity;
  }
}

class SbConfetti extends StatefulWidget {
  final SbConfettiController controller;
  final int particleCount;
  final double gravity;
  final double drag;
  final List<Color> colors;

  const SbConfetti({
    super.key,
    required this.controller,
    this.particleCount = 50,
    this.gravity = 0.5,
    this.drag = 0.98,
    this.colors = const [
      Colors.red, Colors.blue, Colors.green, Colors.yellow, 
      Colors.purple, Colors.orange, Colors.pink
    ],
  });

  @override
  State<SbConfetti> createState() => _SbConfettiState();
}

class _SbConfettiState extends State<SbConfetti> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<SbConfettiParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updateParticles);

    widget.controller.addListener(_handleControllerChange);
    
    if (widget.controller.isPlaying) {
      _startBurst();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
    _animationController.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    if (widget.controller.isPlaying) {
      _startBurst();
    } else {
      _animationController.stop();
      setState(() {
        _particles.clear();
      });
    }
  }

  void _startBurst() {
    _particles.clear();
    // Start explosion from bottom center-ish
    final startX = 0.5; // Normalized relative to width
    final startY = 0.8; // Normalized relative to height

    for (int i = 0; i < widget.particleCount; i++) {
      // Shoot upwards and outwards
      final angle = -math.pi / 2 + (_random.nextDouble() - 0.5) * math.pi;
      final velocity = _random.nextDouble() * 20 + 10;
      
      _particles.add(
        SbConfettiParticle(
          x: startX,
          y: startY,
          velocityX: math.cos(angle) * velocity,
          velocityY: math.sin(angle) * velocity,
          angle: _random.nextDouble() * math.pi * 2,
          angularVelocity: (_random.nextDouble() - 0.5) * 0.5,
          color: widget.colors[_random.nextInt(widget.colors.length)],
          size: _random.nextDouble() * 8 + 4,
        ),
      );
    }
    _animationController.repeat(); // Keep updating until they fall off screen
  }

  void _updateParticles() {
    if (!mounted) return;
    
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    bool allDead = true;
    
    setState(() {
      for (var particle in _particles) {
        particle.update(widget.gravity, widget.drag);
        
        // Denormalize for out of bounds check
        final actualY = particle.y * box.size.height + particle.size;
        if (actualY < box.size.height * 2) { 
          // Give it some buffer below screen before killing
          allDead = false;
        }
      }
    });

    if (allDead) {
      widget.controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_particles.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      child: CustomPaint(
        painter: _ConfettiPainter(particles: _particles),
        size: Size.infinite,
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<SbConfettiParticle> particles;

  _ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      canvas.save();
      
      // Calculate actual screen coordinates
      final screenX = particle.x * size.width;
      final screenY = particle.y * size.height;
      
      canvas.translate(screenX, screenY);
      canvas.rotate(particle.angle);
      
      // Draw rectangular confetti piece
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero, 
          width: particle.size * 2, 
          height: particle.size
        ),
        paint,
      );
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
