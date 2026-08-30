import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbPulseButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color pulseColor;
  final double radius;
  final Duration duration;

  const SbPulseButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.pulseColor = Colors.blueAccent,
    this.radius = 30.0,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<SbPulseButton> createState() => _SbPulseButtonState();
}

class _SbPulseButtonState extends State<SbPulseButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Calculate three rings of pulses staggered by time
          final double phase1 = _controller.value;
          final double phase2 = (phase1 + 0.33) % 1.0;
          final double phase3 = (phase1 + 0.66) % 1.0;

          return CustomPaint(
            painter: _PulsePainter(
              color: widget.pulseColor,
              radius: widget.radius,
              phases: [phase1, phase2, phase3],
            ),
            child: widget.child,
          );
        },
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  final Color color;
  final double radius;
  final List<double> phases;

  _PulsePainter({
    required this.color,
    required this.radius,
    required this.phases,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    for (var phase in phases) {
      // Phase 0.0 -> 1.0
      // Radius expands from 0 to 2x the base radius
      final currentRadius = radius + (radius * phase * 1.5);
      
      // Opacity fades out as it expands (1.0 -> 0.0)
      final opacity = (1.0 - phase).clamp(0.0, 1.0);
      
      final Paint paint = Paint()
        ..color = color.withValues(alpha: opacity * 0.5)
        ..style = PaintingStyle.fill;
        
      canvas.drawCircle(center, currentRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) => true;
}
