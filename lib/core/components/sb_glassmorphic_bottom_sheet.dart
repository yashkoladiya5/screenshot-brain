import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class SbGlassmorphicBottomSheet extends StatelessWidget {
  final Widget child;
  final double height;
  final Color backgroundColor;
  final double blurSigma;
  final Color borderColor;

  const SbGlassmorphicBottomSheet({
    super.key,
    required this.child,
    this.height = 400.0,
    this.backgroundColor = const Color(0x33FFFFFF), // Transparent white
    this.blurSigma = 15.0,
    this.borderColor = const Color(0x66FFFFFF),
  });

  /// A static helper method to easily show this bottom sheet
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double height = 400.0,
    Color backgroundColor = const Color(0x33FFFFFF),
    double blurSigma = 15.0,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent, // Must be transparent for blur to work
      isScrollControlled: true,
      elevation: 0,
      builder: (context) {
        return SbGlassmorphicBottomSheet(
          height: height,
          backgroundColor: backgroundColor,
          blurSigma: blurSigma,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        // We only round the top corners for a bottom sheet
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.0),
          topRight: Radius.circular(30.0),
        ),
      ),
      // Clip exactly to the border radius so the blur doesn't bleed out of the corners
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 1. The Blur Layer
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: blurSigma,
                sigmaY: blurSigma,
              ),
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          
          // 2. The Color & Border Layer
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border(
                  top: BorderSide(color: borderColor, width: 1.5),
                  left: BorderSide(color: borderColor, width: 1.5),
                  right: BorderSide(color: borderColor, width: 1.5),
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
              ),
            ),
          ),
          
          // 3. The Content Layer
          SafeArea(
            child: Column(
              children: [
                // The drag handle indicator
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12.0, bottom: 24.0),
                    width: 40.0,
                    height: 5.0,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                
                // The actual provided content
                Expanded(
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
