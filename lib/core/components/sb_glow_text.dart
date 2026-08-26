import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class SbGlowText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color glowColor;
  final double blurRadius;
  final Offset offset;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  const SbGlowText(
    this.text, {
    super.key,
    required this.glowColor,
    this.blurRadius = 8.0,
    this.offset = Offset.zero,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    // Create a shadow that acts as a glow
    final glowShadow = Shadow(
      color: glowColor,
      blurRadius: blurRadius,
      offset: offset,
    );

    // Merge the provided style with the glow shadow
    final effectiveStyle = style?.copyWith(
      shadows: [
        if (style?.shadows != null) ...style!.shadows!,
        glowShadow,
        // Add a second stronger shadow to intensify the glow core
        Shadow(
          color: glowColor.withValues(alpha: 0.5),
          blurRadius: blurRadius * 0.5,
          offset: offset,
        ),
      ],
    ) ?? TextStyle(
      shadows: [
        glowShadow,
        Shadow(
          color: glowColor.withValues(alpha: 0.5),
          blurRadius: blurRadius * 0.5,
          offset: offset,
        ),
      ],
    );

    return Text(
      text,
      style: effectiveStyle,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}
