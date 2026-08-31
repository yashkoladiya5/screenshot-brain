import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbShakeAnimation extends StatefulWidget {
  final Widget child;
  final bool shake;
  final double shakeCount;
  final double shakeOffset;
  final Duration duration;

  const SbShakeAnimation({
    super.key,
    required this.child,
    required this.shake,
    this.shakeCount = 3,
    this.shakeOffset = 10,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  State<SbShakeAnimation> createState() => _SbShakeAnimationState();
}

class _SbShakeAnimationState extends State<SbShakeAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    // We use a sine wave to create the left/right shaking motion
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    if (widget.shake) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(SbShakeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
      _controller.forward(from: 0.0);
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
      animation: _animation,
      builder: (context, child) {
        // Value goes from 0.0 to 1.0
        // We want it to swing left/right shakeCount times
        // sin(progress * pi * 2 * count) gives us smooth oscillation between -1 and 1
        
        // Dampen the effect as it gets closer to the end
        final double dampening = 1.0 - _animation.value;
        
        final double sineValue = math.sin(_animation.value * math.pi * 2 * widget.shakeCount);
        
        final double currentOffset = sineValue * widget.shakeOffset * dampening;

        return Transform.translate(
          offset: Offset(currentOffset, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
