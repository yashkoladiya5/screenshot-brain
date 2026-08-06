import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbRating extends StatelessWidget {
  final double rating;
  final int maxRating;
  final double iconSize;
  final Color? activeColor;
  final Color? inactiveColor;
  final ValueChanged<int>? onRatingChanged;

  const SbRating({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.iconSize = SBSizes.iconMd,
    this.activeColor,
    this.inactiveColor,
    this.onRatingChanged,
  }) : assert(rating >= 0 && rating <= maxRating);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final active = activeColor ?? Colors.amber;
    final inactive = inactiveColor ?? colorScheme.surfaceContainerHighest;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        final icon = index < rating.floor()
            ? Icons.star_rounded
            : (index < rating
                ? Icons.star_half_rounded
                : Icons.star_border_rounded);
                
        final color = index < rating.ceil() ? active : inactive;

        final child = Icon(
          icon,
          size: iconSize,
          color: color,
        );

        if (onRatingChanged != null) {
          return InkWell(
            onTap: () => onRatingChanged!(index + 1),
            borderRadius: BorderRadius.circular(SBRadius.full),
            child: Padding(
              padding: const EdgeInsets.all(SBSpacing.xxs),
              child: child,
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: SBSpacing.xxs / 2),
          child: child,
        );
      }),
    );
  }
}
