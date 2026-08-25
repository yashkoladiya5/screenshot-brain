import 'package:flutter/material.dart';
import 'dart:ui';
import '../design/tokens.dart';

class SbGlassmorphismCard extends StatelessWidget {
  final Widget child;
  final double blurSigma;
  final double opacity;
  final Color? color;
  final double borderRadius;
  final Border? border;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;

  const SbGlassmorphismCard({
    super.key,
    required this.child,
    this.blurSigma = 10.0,
    this.opacity = 0.2,
    this.color,
    this.borderRadius = SBRadius.xl,
    this.border,
    this.padding = const EdgeInsets.all(SBSpacing.lg),
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.colorScheme.surface;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: cardColor.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ?? Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 24,
                spreadRadius: -12,
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
