import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../design/tokens.dart';

class SbLikeButton extends StatefulWidget {
  final bool isLiked;
  final ValueChanged<bool>? onLikeChanged;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const SbLikeButton({
    super.key,
    this.isLiked = false,
    this.onLikeChanged,
    this.size = 32.0,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<SbLikeButton> createState() => _SbLikeButtonState();
}

class _SbLikeButtonState extends State<SbLikeButton> with TickerProviderStateMixin {
  late bool _isLiked;
  
  // Controller for the heart bounce
  late AnimationController _heartController;
  late Animation<double> _heartScale;
  
  // Controller for the particles
  late AnimationController _particlesController;
  
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;
    
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _heartScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.5), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.2), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _heartController, curve: Curves.easeInOut));
    
    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void didUpdateWidget(SbLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked != oldWidget.isLiked && widget.isLiked != _isLiked) {
      _isLiked = widget.isLiked;
      if (_isLiked) {
        _playAnimation();
      }
    }
  }

  @override
  void dispose() {
    _heartController.dispose();
    _particlesController.dispose();
    super.dispose();
  }

  void _playAnimation() {
    _heartController.forward(from: 0.0);
    _particlesController.forward(from: 0.0);
  }

  void _handleTap() {
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _playAnimation();
      }
    });
    widget.onLikeChanged?.call(_isLiked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = widget.activeColor ?? Colors.redAccent;
    final inactive = widget.inactiveColor ?? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: widget.size * 2, // Space for particles
        height: widget.size * 2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Particles layer
            if (_isLiked)
              AnimatedBuilder(
                animation: _particlesController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(widget.size * 2, widget.size * 2),
                    painter: _ParticlesPainter(
                      progress: _particlesController.value,
                      color: active,
                      seed: _random.nextInt(100),
                    ),
                  );
                },
              ),
              
            // Heart layer
            AnimatedBuilder(
              animation: _heartController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isLiked ? _heartScale.value : 1.0,
                  child: child,
                );
              },
              child: Icon(
                _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _isLiked ? active : inactive,
                size: widget.size,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  final double progress;
  final Color color;
  final int seed;

  _ParticlesPainter({
    required this.progress,
    required this.color,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0.0 || progress == 1.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    final random = math.Random(seed);
    
    // We want particles to fade out towards the end
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: opacity);

    // Draw 6 main directional bursts
    final int burstCount = 6;
    for (int i = 0; i < burstCount; i++) {
      // Calculate angle (spread evenly)
      final double angle = (i * math.pi * 2) / burstCount;
      
      // Calculate distance outward based on progress
      // The `* progress` pushes them out, the `random` adds jitter
      final double distance = maxRadius * progress * (0.8 + random.nextDouble() * 0.4);
      
      final dx = center.dx + math.cos(angle) * distance;
      final dy = center.dy + math.sin(angle) * distance;
      
      // Particle size decreases as it goes out
      final double particleSize = 3.0 * (1.0 - progress);
      
      canvas.drawCircle(Offset(dx, dy), particleSize, paint);
      
      // Draw a secondary smaller trailing particle
      final double trailDistance = distance * 0.6;
      final trailDx = center.dx + math.cos(angle - 0.2) * trailDistance;
      final trailDy = center.dy + math.sin(angle - 0.2) * trailDistance;
      
      canvas.drawCircle(Offset(trailDx, trailDy), particleSize * 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress || 
           oldDelegate.color != color ||
           oldDelegate.seed != seed;
  }
}
