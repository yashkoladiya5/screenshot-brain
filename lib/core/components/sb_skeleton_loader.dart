import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbSkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool isCircular;

  const SbSkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = SBRadius.sm,
    this.isCircular = false,
  });

  @override
  State<SbSkeletonLoader> createState() => _SbSkeletonLoaderState();
}

class _SbSkeletonLoaderState extends State<SbSkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: _animation.value),
            shape: widget.isCircular ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: widget.isCircular ? null : BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}
