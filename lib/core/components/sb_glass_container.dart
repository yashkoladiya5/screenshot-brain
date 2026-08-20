import 'dart:ui';
import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbGlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadiusGeometry? borderRadius;
  final EdgeInsetsGeometry? padding;

  const SbGlassContainer({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.2,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final radius = borderRadius ?? BorderRadius.circular(SBRadius.lg);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(SBSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: opacity),
            borderRadius: radius,
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: opacity + 0.1),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
