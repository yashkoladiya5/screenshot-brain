import 'package:flutter/material.dart';

class SbShimmerText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const SbShimmerText({
    super.key,
    required this.text,
    this.style,
    this.baseColor = Colors.grey,
    this.highlightColor = Colors.white,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<SbShimmerText> createState() => _SbShimmerTextState();
}

class _SbShimmerTextState extends State<SbShimmerText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
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
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [
                0.0,
                0.5,
                1.0,
              ],
              begin: Alignment(-1.0 + (_controller.value * 3), 0.0),
              end: Alignment(1.0 + (_controller.value * 3), 0.0),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Text(
        widget.text,
        style: widget.style,
      ),
    );
  }
}
