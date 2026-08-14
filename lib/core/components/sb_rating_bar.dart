import 'package:flutter/material.dart';

class SbRatingBar extends StatelessWidget {
  final int rating;
  final int maxRating;
  final ValueChanged<int>? onRatingChanged;
  final double iconSize;
  final Color? activeColor;
  final Color? inactiveColor;

  const SbRatingBar({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.onRatingChanged,
    this.iconSize = 24.0,
    this.activeColor,
    this.inactiveColor,
  }) : assert(rating >= 0 && rating <= maxRating);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final active = activeColor ?? Colors.amber.shade600;
    final inactive = inactiveColor ?? colorScheme.outlineVariant.withValues(alpha: 0.5);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        final isFilled = index < rating;
        
        return GestureDetector(
          onTap: onRatingChanged != null ? () => onRatingChanged!(index + 1) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                key: ValueKey<bool>(isFilled),
                color: isFilled ? active : inactive,
                size: iconSize,
              ),
            ),
          ),
        );
      }),
    );
  }
}
