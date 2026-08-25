import 'package:flutter/material.dart';

class SbBouncingLoader extends StatefulWidget {
  final Color? color;
  final double size;
  final int dotCount;
  final Duration duration;

  const SbBouncingLoader({
    super.key,
    this.color,
    this.size = 12.0,
    this.dotCount = 3,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<SbBouncingLoader> createState() => _SbBouncingLoaderState();
}

class _SbBouncingLoaderState extends State<SbBouncingLoader> with SingleTickerProviderStateMixin {
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.dotCount, (index) {
        // Calculate the timing for each dot
        // We want them to bounce sequentially
        final delay = (index / widget.dotCount) * 0.5; // Offset start times
        
        final animation = TweenSequence([
          TweenSequenceItem(
            tween: Tween(begin: 0.0, end: -widget.size)
                .chain(CurveTween(curve: Curves.easeOutQuad)),
            weight: 30,
          ),
          TweenSequenceItem(
            tween: Tween(begin: -widget.size, end: 0.0)
                .chain(CurveTween(curve: Curves.easeInQuad)),
            weight: 30,
          ),
          TweenSequenceItem(
            tween: ConstantTween(0.0),
            weight: 40, // Pause at the bottom
          ),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(
              delay,
              1.0, // Each dot finishes its animation within the full cycle
              curve: Curves.linear,
            ),
          ),
        );

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, animation.value),
              child: Container(
                width: widget.size,
                height: widget.size,
                margin: EdgeInsets.symmetric(horizontal: widget.size * 0.3),
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    // Add a small shadow that gets larger as the dot jumps up
                    BoxShadow(
                      color: dotColor.withValues(alpha: 0.3),
                      blurRadius: (animation.value.abs() / 2) + 2,
                      offset: Offset(0, (animation.value.abs() / 2) + 2),
                    )
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
