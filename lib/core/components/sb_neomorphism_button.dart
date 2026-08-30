import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbNeomorphismButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final double size;
  final double borderRadius;
  final Color backgroundColor;
  final double depth;

  const SbNeomorphismButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.size = 80.0,
    this.borderRadius = SBRadius.xl,
    this.backgroundColor = const Color(0xFFE0E5EC), // Typical neomorphic base color
    this.depth = 10.0,
  });

  @override
  State<SbNeomorphismButton> createState() => _SbNeomorphismButtonState();
}

class _SbNeomorphismButtonState extends State<SbNeomorphismButton> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    widget.onPressed();
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Generate light and dark shadow colors based on the background color
    // A true neomorphic design requires a very specific color math to look physical
    
    // Convert to HSL for safer lightness manipulation
    final HSLColor hsl = HSLColor.fromColor(widget.backgroundColor);
    
    // Light shadow (highlight) is lighter than base
    final Color lightShadow = hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0)).toColor();
    // Dark shadow is darker than base
    final Color darkShadow = hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          // The magic of neomorphism happens here in the shadows
          boxShadow: _isPressed
              ? [
                  // Inner shadow effect when pressed (simulated by inset in Flutter, usually requires custom paint or packages,
                  // but we can approximate a "flat" pressed state by dropping the outer shadows and adding a slight dark border/inner glow)
                  BoxShadow(
                    color: darkShadow.withValues(alpha: 0.5),
                    offset: Offset(widget.depth / 2, widget.depth / 2),
                    blurRadius: widget.depth,
                  ),
                  BoxShadow(
                    color: Colors.transparent, // Flutter doesn't natively support inset shadows easily
                    offset: Offset(-widget.depth / 2, -widget.depth / 2),
                    blurRadius: widget.depth,
                  ),
                ]
              : [
                  // Extruded effect when not pressed
                  BoxShadow(
                    color: darkShadow,
                    offset: Offset(widget.depth, widget.depth),
                    blurRadius: widget.depth * 2,
                  ),
                  BoxShadow(
                    color: lightShadow,
                    offset: Offset(-widget.depth, -widget.depth),
                    blurRadius: widget.depth * 2,
                  ),
                ],
          // Apply a subtle gradient to enhance the 3D bulge
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isPressed 
              ? [
                  darkShadow.withValues(alpha: 0.1),
                  lightShadow.withValues(alpha: 0.1),
                ]
              : [
                  lightShadow.withValues(alpha: 0.5),
                  darkShadow.withValues(alpha: 0.2),
                ],
          ),
        ),
        // Translate slightly when pressed to sell the physical push
        transform: Matrix4.translationValues(
          _isPressed ? widget.depth / 4 : 0.0, 
          _isPressed ? widget.depth / 4 : 0.0, 
          0.0
        ),
        child: Center(
          child: widget.child,
        ),
      ),
    );
  }
}
