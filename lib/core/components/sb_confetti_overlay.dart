import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbConfettiOverlay extends StatefulWidget {
  final Widget child;
  final bool isPlaying;
  final int count;
  final List<Color>? colors;

  const SbConfettiOverlay({
    super.key,
    required this.child,
    required this.isPlaying,
    this.count = 50,
    this.colors,
  });

  @override
  State<SbConfettiOverlay> createState() => _SbConfettiOverlayState();
}

class _SbConfettiOverlayState extends State<SbConfettiOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(() {
        if (mounted) setState(() {});
      });

    if (widget.isPlaying) {
      _generateParticles();
      _controller.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(SbConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _generateParticles();
      _controller.forward(from: 0.0);
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _controller.stop();
    }
  }

  void _generateParticles() {
    _particles.clear();
    final colors = widget.colors ?? [
      Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.orange
    ];

    for (int i = 0; i < widget.count; i++) {
      _particles.add(_ConfettiParticle(
        x: _random.nextDouble(),
        y: -0.1 - _random.nextDouble() * 0.2, // Start slightly above screen
        vx: (_random.nextDouble() - 0.5) * 0.5, // Horizontal drift
        vy: 0.5 + _random.nextDouble(), // Vertical fall speed
        rotation: _random.nextDouble() * 2 * math.pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 10,
        color: colors[_random.nextInt(colors.length)],
        size: 8.0 + _random.nextDouble() * 8.0,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isPlaying || _controller.isAnimating)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ConfettiPainter(
                  particles: _particles,
                  progress: _controller.value,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ConfettiParticle {
  final double x;
  final double y;
  final double vx;
  final double vy;
  final double rotation;
  final double rotationSpeed;
  final Color color;
  final double size;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
    required this.size,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    for (var particle in particles) {
      // Calculate current position based on progress
      final currentX = size.width * particle.x + (size.width * particle.vx * progress);
      final currentY = size.height * particle.y + (size.height * particle.vy * progress);
      final currentRotation = particle.rotation + (particle.rotationSpeed * progress);

      // Only draw if within bounds
      if (currentY > size.height + particle.size || currentX < -particle.size || currentX > size.width + particle.size) {
        continue;
      }

      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(currentRotation);
      
      // Draw a small rectangle for confetti
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: particle.size, height: particle.size * 0.6),
        paint,
      );
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
