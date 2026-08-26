import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbShimmerCard extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const SbShimmerCard({
    super.key,
    this.width = double.infinity,
    this.height = 120.0,
    this.borderRadius = SBRadius.md,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<SbShimmerCard> createState() => _SbShimmerCardState();
}

class _SbShimmerCardState extends State<SbShimmerCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
    final base = widget.baseColor ?? theme.colorScheme.surfaceContainerHighest;
    final highlight = widget.highlightColor ?? theme.colorScheme.surface;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: const Alignment(-1.0, -0.5),
              end: const Alignment(2.0, 0.5),
              stops: const [0.0, 0.3, 0.6, 1.0],
              colors: [
                base,
                base,
                highlight,
                base,
              ],
              // Slide the gradient across the container based on the animation value
              transform: _SlidingGradientTransform(slidePercent: _controller.value),
            ),
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // We want the gradient to slide from way off left to way off right
    final double slideDistance = bounds.width * 2;
    // Map the 0.0 -> 1.0 animation into an actual pixel translation
    final double dx = (slidePercent * slideDistance) - (slideDistance / 2);
    return Matrix4.translationValues(dx, 0.0, 0.0);
  }
}
