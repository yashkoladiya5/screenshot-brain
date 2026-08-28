import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbShimmerSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const SbShimmerSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 20.0,
    this.borderRadius = SBRadius.sm,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
    this.duration = const Duration(milliseconds: 1500),
  });

  /// Factory constructor for a common circular avatar skeleton
  factory SbShimmerSkeleton.circular({
    double size = 48.0,
    Color baseColor = const Color(0xFFE0E0E0),
    Color highlightColor = const Color(0xFFF5F5F5),
  }) {
    return SbShimmerSkeleton(
      width: size,
      height: size,
      borderRadius: size / 2,
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
  }

  @override
  State<SbShimmerSkeleton> createState() => _SbShimmerSkeletonState();
}

class _SbShimmerSkeletonState extends State<SbShimmerSkeleton> with SingleTickerProviderStateMixin {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // We use ShaderMask to apply the animating gradient exactly over the geometry of the child
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final double percent = _controller.value;
            // Map animation value 0.0 -> 1.0 to gradient stops moving from left to right
            // We expand the range so it smoothly enters and exits the bounds
            final double start = (percent * 2) - 1.0;
            
            return LinearGradient(
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                (start - 0.3).clamp(0.0, 1.0),
                start.clamp(0.0, 1.0),
                (start + 0.3).clamp(0.0, 1.0),
              ],
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3), // Slight diagonal sweep looks more natural
            ).createShader(bounds);
          },
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.white, // The color here doesn't matter due to srcATop blend mode, but it must be opaque to provide the alpha mask
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
        );
      },
    );
  }
}
