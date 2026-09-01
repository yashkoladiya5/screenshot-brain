import 'package:flutter/material.dart';

class SbAnimatedCounterText extends StatefulWidget {
  final int value;
  final TextStyle? textStyle;
  final Duration duration;

  const SbAnimatedCounterText({
    super.key,
    required this.value,
    this.textStyle,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<SbAnimatedCounterText> createState() => _SbAnimatedCounterTextState();
}

class _SbAnimatedCounterTextState extends State<SbAnimatedCounterText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _oldValue = 0;

  @override
  void initState() {
    super.initState();
    _oldValue = widget.value;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: _oldValue.toDouble(), end: widget.value.toDouble()).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)
    );
  }

  @override
  void didUpdateWidget(SbAnimatedCounterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _oldValue = oldWidget.value;
      _animation = Tween<double>(begin: _oldValue.toDouble(), end: widget.value.toDouble()).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)
      );
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
        // We use string interpolation to show the exact integer value mid-animation
        final int displayValue = _animation.value.round();
        return Text(
          '$displayValue',
          style: widget.textStyle ?? Theme.of(context).textTheme.headlineMedium,
        );
      },
    );
  }
}
