import 'package:flutter/material.dart';

class SbGlowButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color glowColor;
  final double blurRadius;
  final double spreadRadius;

  const SbGlowButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.glowColor = Colors.cyanAccent,
    this.blurRadius = 20.0,
    this.spreadRadius = 2.0,
  });

  @override
  State<SbGlowButton> createState() => _SbGlowButtonState();
}

class _SbGlowButtonState extends State<SbGlowButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
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
    return GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30.0),
              boxShadow: [
                BoxShadow(
                  color: widget.glowColor.withValues(alpha: 0.5 * _glowAnimation.value),
                  blurRadius: widget.blurRadius * _glowAnimation.value,
                  spreadRadius: widget.spreadRadius * _glowAnimation.value,
                )
              ]
            ),
            child: widget.child,
          );
        },
      ),
    );
  }
}
