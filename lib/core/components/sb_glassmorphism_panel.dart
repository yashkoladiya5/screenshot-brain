import 'package:flutter/material.dart';
import 'dart:ui';

class SbGlassmorphismPanel extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;

  const SbGlassmorphismPanel({
    super.key,
    required this.child,
    this.width = double.infinity,
    this.height = double.infinity,
    this.blur = 10.0,
    this.opacity = 0.2,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(16.0);
    
    return ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            // Backdrop Filter for the blur effect
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: effectiveBorderRadius,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2), // Subtle white border
                    width: 1.5,
                  ),
                  // Slight white tint to make the glass visible
                  color: Colors.white.withValues(alpha: opacity),
                ),
              ),
            ),
            
            // Adding a subtle gradient reflection (shine) to sell the glass look
            Container(
              decoration: BoxDecoration(
                borderRadius: effectiveBorderRadius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                  stops: const [0.1, 1.0],
                ),
              ),
            ),
            
            // The content
            Center(child: child),
          ],
        ),
      ),
    );
  }
}
