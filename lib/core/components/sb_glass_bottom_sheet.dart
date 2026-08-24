import 'dart:ui';
import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbGlassBottomSheet extends StatelessWidget {
  final Widget child;
  final double blurAmount;
  final double opacity;
  final Color? tintColor;

  const SbGlassBottomSheet({
    super.key,
    required this.child,
    this.blurAmount = 20.0,
    this.opacity = 0.6,
    this.tintColor,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double blurAmount = 20.0,
    double opacity = 0.6,
    Color? tintColor,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: isScrollControlled,
      builder: (context) => SbGlassBottomSheet(
        blurAmount: blurAmount,
        opacity: opacity,
        tintColor: tintColor,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final tint = tintColor ?? colorScheme.surface;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(SBRadius.xl),
        topRight: Radius.circular(SBRadius.xl),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          decoration: BoxDecoration(
            color: tint.withValues(alpha: opacity),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(SBRadius.xl),
              topRight: Radius.circular(SBRadius.xl),
            ),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          padding: EdgeInsets.only(
            top: SBSpacing.md,
            bottom: bottomPadding > 0 ? bottomPadding : SBSpacing.md,
            left: SBSpacing.md,
            right: SBSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: SBSpacing.lg),
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(SBRadius.full),
                ),
              ),
              // Content
              child,
            ],
          ),
        ),
      ),
    );
  }
}
