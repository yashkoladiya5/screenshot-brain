import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../design/tokens.dart';

class SbConfettiParticle {
  double x;
  double y;
  double vx;
  double vy;
  double angle;
  double spinSpeed;
  Color color;
  double size;

  SbConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.angle,
    required this.spinSpeed,
    required this.color,
    required this.size,
  });

  void update() {
    x += vx;
    y += vy;
    vy += 0.5; // Gravity
    angle += spinSpeed;
  }
}

class SbConfettiButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const SbConfettiButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.backgroundColor,
    this.borderRadius = SBRadius.md,
    this.padding = const EdgeInsets.symmetric(horizontal: SBSpacing.xl, vertical: SBSpacing.md),
  });

  @override
  State<SbConfettiButton> createState() => _SbConfettiButtonState();
}

class _SbConfettiButtonState extends State<SbConfettiButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<SbConfettiParticle> _particles = [];
  final math.Random _random = math.Random();
  
  // To track where the button is
  final GlobalKey _buttonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Max life of confetti
    )..addListener(() {
        _updateParticles();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _explode() {
    final RenderBox? renderBox = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      widget.onPressed();
      return;
    }

    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);
    
    // Calculate exact center of the button in global coordinates
    final center = Offset(position.dx + size.width / 2, position.dy + size.height / 2);

    _particles.clear();
    
    final List<Color> colors = [
      Colors.redAccent,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.yellowAccent,
      Colors.purpleAccent,
      Colors.orangeAccent,
    ];

    for (int i = 0; i < 40; i++) {
      // Explode radially
      final angle = _random.nextDouble() * math.pi * 2;
      final velocity = _random.nextDouble() * 15 + 5;
      
      _particles.add(SbConfettiParticle(
        x: center.dx, // Start exactly at button center
        y: center.dy,
        vx: math.cos(angle) * velocity,
        vy: math.sin(angle) * velocity - 5, // Extra upward push
        angle: _random.nextDouble() * math.pi * 2,
        spinSpeed: (_random.nextDouble() - 0.5) * 0.5,
        color: colors[_random.nextInt(colors.length)],
        size: _random.nextDouble() * 8 + 4,
      ));
    }

    // Pass the click through immediately
    widget.onPressed();

    // Start animation from 0
    _controller.forward(from: 0.0);
  }

  void _updateParticles() {
    setState(() {
      for (var p in _particles) {
        p.update();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = widget.backgroundColor ?? theme.colorScheme.primary;

    return Stack(
      clipBehavior: Clip.none, // Allow confetti to fly outside container bounds
      children: [
        // 1. Confetti Layer
        if (_controller.isAnimating)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                // We use a custom painter that understands global coordinates 
                // but draws relative to this stack's origin. 
                painter: _ConfettiPainter(
                  particles: _particles,
                  // We need to offset the global particles back into local space
                  localOrigin: _getOrigin(),
                  opacity: 1.0 - _controller.value, // Fade out near the end
                ),
              ),
            ),
          ),
          
        // 2. The Button Layer
        ElevatedButton(
          key: _buttonKey,
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: theme.colorScheme.onPrimary,
            padding: widget.padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            elevation: 4,
          ),
          onPressed: _explode,
          child: widget.child,
        ),
      ],
    );
  }

  Offset _getOrigin() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      return renderBox.localToGlobal(Offset.zero);
    }
    return Offset.zero;
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<SbConfettiParticle> particles;
  final Offset localOrigin;
  final double opacity;

  _ConfettiPainter({
    required this.particles,
    required this.localOrigin,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.color.a * opacity)
        ..style = PaintingStyle.fill;
        
      // Convert global particle coordinates to local canvas coordinates
      final localX = p.x - localOrigin.dx;
      final localY = p.y - localOrigin.dy;

      canvas.save();
      canvas.translate(localX, localY);
      canvas.rotate(p.angle);
      
      // Draw a small rectangle for the confetti piece
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6), 
        paint
      );
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true; // Constantly animating
}
