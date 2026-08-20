import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbShakingIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final Duration duration;
  final bool isShaking;

  const SbShakingIcon({
    super.key,
    required this.icon,
    this.size = 24.0,
    this.color,
    this.duration = const Duration(milliseconds: 500),
    this.isShaking = false,
  });

  @override
  State<SbShakingIcon> createState() => _SbShakingIconState();
}

class _SbShakingIconState extends State<SbShakingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    if (widget.isShaking) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(SbShakingIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isShaking != oldWidget.isShaking) {
      if (widget.isShaking) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Create a shaking effect by rapidly oscillating rotation
        final sineValue = math.sin(_controller.value * math.pi * 6); // 3 full shakes per duration
        final rotation = sineValue * 0.2; // roughly 11 degrees max rotation
        
        return Transform.rotate(
          angle: rotation,
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
