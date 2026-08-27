import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../design/tokens.dart';

class SbGlassMorphCard extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final double borderRadius;
  final double blurSigma;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final bool enableShadow;

  const SbGlassMorphCard({
    super.key,
    required this.child,
    this.width = double.infinity,
    this.height = 200.0,
    this.borderRadius = SBRadius.lg,
    this.blurSigma = 15.0,
    this.backgroundColor = const Color(0x33FFFFFF), // Highly transparent white
    this.borderColor = const Color(0x66FFFFFF),
    this.borderWidth = 1.0,
    this.enableShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: enableShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: -5,
                  offset: const Offset(0, 10),
                )
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. The Blur Effect
            BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: Container(
                color: Colors.transparent,
              ),
            ),
            
            // 2. The Semi-Transparent Background and Content
            Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: borderColor,
                  width: borderWidth,
                ),
                // Add a very subtle inner glow
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
