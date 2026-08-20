import 'package:flutter/material.dart';

class SbBouncingIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final double bounceHeight;
  final Duration duration;

  const SbBouncingIcon({
    super.key,
    required this.icon,
    this.size = 24.0,
    this.color,
    this.bounceHeight = 8.0,
    this.duration = const Duration(milliseconds: 1000),
  });

  @override
  State<SbBouncingIcon> createState() => _SbBouncingIconState();
}

class _SbBouncingIconState extends State<SbBouncingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: widget.bounceHeight).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
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
        return Transform.translate(
          offset: Offset(0, -_animation.value),
          child: child,
        );
      },
      child: Icon(
        widget.icon,
        size: widget.size,
        color: widget.color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
