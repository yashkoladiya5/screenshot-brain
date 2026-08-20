import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbTypingIndicator extends StatefulWidget {
  final double size;
  final Color? color;
  final Duration duration;

  const SbTypingIndicator({
    super.key,
    this.size = 8.0,
    this.color,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<SbTypingIndicator> createState() => _SbTypingIndicatorState();
}

class _SbTypingIndicatorState extends State<SbTypingIndicator> with SingleTickerProviderStateMixin {
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
    final theme = Theme.of(context);
    final dotColor = widget.color ?? theme.colorScheme.primary;
    final spacing = widget.size * 0.8;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            // Offset the animation for each dot
            final offset = index * 0.2;
            double progress = (_controller.value + offset) % 1.0;
            
            // Create a bouncing sine wave motion
            final yOffset = math.sin(progress * math.pi * 2) * (widget.size * 0.5);

            return Container(
              margin: EdgeInsets.only(right: index < 2 ? spacing : 0),
              child: Transform.translate(
                offset: Offset(0, -yOffset.abs()),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: dotColor.withValues(alpha: 0.3 + (0.7 * yOffset.abs() / (widget.size * 0.5))),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
