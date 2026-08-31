import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbConfettiPopper extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final int particleCount;

  const SbConfettiPopper({
    super.key,
    required this.child,
    required this.onPressed,
    this.particleCount = 50,
  });

  @override
  State<SbConfettiPopper> createState() => _SbConfettiPopperState();
}

class _SbConfettiPopperState extends State<SbConfettiPopper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<_ParticleData> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pop() {
    _particles = List.generate(widget.particleCount, (index) {
      final angle = -math.pi * (_random.nextDouble() * 0.8 + 0.1); // mostly up
      final velocity = _random.nextDouble() * 300 + 150;
      return _ParticleData(
        vx: math.cos(angle) * velocity,
        vy: math.sin(angle) * velocity,
        color: Colors.primaries[_random.nextInt(Colors.primaries.length)],
        size: _random.nextDouble() * 8 + 4,
      );
    });
    
    _controller.forward(from: 0.0);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _ParticlePainter(
                progress: _controller.value,
                particles: _particles,
              ),
              size: Size.zero,
            );
          },
        ),
        GestureDetector(
          onTap: _pop,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final bump = math.sin(_controller.value * math.pi * 3) * (1.0 - _controller.value) * 0.1;
              return Transform.scale(
                scale: 1.0 - bump,
                child: child,
              );
            },
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

class _ParticleData {
  double vx;
  double vy;
  Color color;
  double size;

  _ParticleData({
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
  });
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  final List<_ParticleData> particles;

  _ParticlePainter({
    required this.progress,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final gravity = 500.0 * progress;

    for (var p in particles) {
      final double currentX = p.vx * progress;
      final double currentY = (p.vy * progress) + (0.5 * gravity * progress * progress);
      
      final paint = Paint()
        ..color = p.color.withValues(alpha: (1.0 - progress).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
        
      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(progress * math.pi * 6 * p.size);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 1.5), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
