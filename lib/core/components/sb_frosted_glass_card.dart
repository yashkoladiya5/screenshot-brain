import 'package:flutter/material.dart';
import 'dart:ui';

class SbFrostedGlassCard extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final Border? border;
  final Color baseColor;

  const SbFrostedGlassCard({
    super.key,
    required this.child,
    this.width = double.infinity,
    this.height = 200.0,
    this.blur = 15.0,
    this.opacity = 0.2,
    this.borderRadius,
    this.border,
    this.baseColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(16.0);

    return ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: opacity),
            borderRadius: effectiveBorderRadius,
            border: border ?? Border.all(
              color: Colors.white.withValues(alpha: 0.2), 
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor.withValues(alpha: opacity + 0.1),
                baseColor.withValues(alpha: opacity - 0.1 > 0 ? opacity - 0.1 : 0),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
