import 'package:flutter/material.dart';

class SbPulsingCircle extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;

  const SbPulsingCircle({
    super.key,
    this.size = 24.0,
    this.color = Colors.blue,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<SbPulsingCircle> createState() => _SbPulsingCircleState();
}

class _SbPulsingCircleState extends State<SbPulsingCircle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();

    _animation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulsing ring
            Container(
              width: widget.size * _animation.value,
              height: widget.size * _animation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: (1.5 - _animation.value).clamp(0.0, 1.0) * 0.4),
              ),
            ),
            // Inner solid circle
            Container(
              width: widget.size * 0.5,
              height: widget.size * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
              ),
            ),
          ],
        );
      },
    );
  }
}
