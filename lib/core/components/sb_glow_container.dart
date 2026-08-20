import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbGlowContainer extends StatelessWidget {
  final Widget child;
  final Color? glowColor;
  final double blurRadius;
  final double spreadRadius;
  final BorderRadiusGeometry? borderRadius;
  final bool isGlowing;

  const SbGlowContainer({
    super.key,
    required this.child,
    this.glowColor,
    this.blurRadius = 20.0,
    this.spreadRadius = 4.0,
    this.borderRadius,
    this.isGlowing = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = glowColor ?? theme.colorScheme.primary;
    final radius = borderRadius ?? BorderRadius.circular(SBRadius.lg);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: isGlowing
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: blurRadius,
                  spreadRadius: spreadRadius,
                ),
              ]
            : [],
      ),
      child: child,
    );
  }
}
