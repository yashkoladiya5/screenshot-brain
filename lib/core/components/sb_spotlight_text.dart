import 'package:flutter/material.dart';

class SbSpotlightText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Color spotlightColor;
  final double spotlightRadius;

  const SbSpotlightText({
    super.key,
    required this.text,
    required this.style,
    this.spotlightColor = Colors.white,
    this.spotlightRadius = 60.0,
  });

  @override
  State<SbSpotlightText> createState() => _SbSpotlightTextState();
}

class _SbSpotlightTextState extends State<SbSpotlightText> {
  Offset _mousePosition = Offset.zero;
  bool _isHovering = false;

  void _onHover(PointerEvent event) {
    if (!mounted) return;
    
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(event.position);
    
    setState(() {
      _mousePosition = localPosition;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onHover: _onHover,
      onExit: (_) => setState(() => _isHovering = false),
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          if (!_isHovering) {
            // When not hovering, show the text normally or slightly dimmed
            // We can just return a solid color shader
            return LinearGradient(
              colors: [widget.style.color ?? Colors.black, widget.style.color ?? Colors.black],
            ).createShader(bounds);
          }

          // Create a radial gradient that acts as a spotlight
          return RadialGradient(
            center: FractionalOffset(
              _mousePosition.dx / bounds.width,
              _mousePosition.dy / bounds.height,
            ),
            radius: widget.spotlightRadius / bounds.width * 2, // Scale radius relative to width
            colors: [
              widget.spotlightColor,
              widget.spotlightColor.withValues(alpha: 0.2),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(bounds);
        },
        blendMode: _isHovering ? BlendMode.srcIn : BlendMode.srcIn,
        child: Text(
          widget.text,
          style: widget.style.copyWith(
            // The actual color is determined by the ShaderMask, but we set it white here as a base
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
