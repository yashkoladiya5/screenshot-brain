import 'package:flutter/material.dart';

class SbDotIndicator extends StatelessWidget {
  final int itemCount;
  final int currentIndex;
  final Color? activeColor;
  final Color? inactiveColor;
  final double dotSize;
  final double activeDotWidth;
  final double spacing;

  const SbDotIndicator({
    super.key,
    required this.itemCount,
    required this.currentIndex,
    this.activeColor,
    this.inactiveColor,
    this.dotSize = 8.0,
    this.activeDotWidth = 24.0,
    this.spacing = 6.0,
  }) : assert(itemCount > 0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final active = activeColor ?? colorScheme.primary;
    final inactive = inactiveColor ?? colorScheme.outlineVariant.withValues(alpha: 0.5);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        itemCount,
        (index) {
          final isSelected = currentIndex == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: EdgeInsets.symmetric(horizontal: spacing / 2),
            height: dotSize,
            width: isSelected ? activeDotWidth : dotSize,
            decoration: BoxDecoration(
              color: isSelected ? active : inactive,
              borderRadius: BorderRadius.circular(dotSize / 2),
            ),
          );
        },
      ),
    );
  }
}
