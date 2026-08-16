import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbRatingDisplay extends StatelessWidget {
  final double rating;
  final int maxRating;
  final double iconSize;
  final int? reviewsCount;

  const SbRatingDisplay({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.iconSize = 16.0,
    this.reviewsCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Clamp the rating between 0 and maxRating
    final clampedRating = rating.clamp(0.0, maxRating.toDouble());

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(maxRating, (index) {
            IconData iconData;
            Color iconColor = Colors.amber.shade500;

            if (index < clampedRating.floor()) {
              iconData = Icons.star_rounded;
            } else if (index == clampedRating.floor() && clampedRating - index > 0) {
              iconData = Icons.star_half_rounded;
            } else {
              iconData = Icons.star_border_rounded;
              iconColor = colorScheme.outlineVariant.withValues(alpha: 0.5);
            }

            return Icon(
              iconData,
              size: iconSize,
              color: iconColor,
            );
          }),
        ),
        const SizedBox(width: SBSpacing.xs),
        Text(
          clampedRating.toStringAsFixed(1),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        if (reviewsCount != null) ...[
          const SizedBox(width: SBSpacing.xxs),
          Text(
            '($reviewsCount)',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
