import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbStatistic extends StatelessWidget {
  final String label;
  final String value;
  final String? prefix;
  final String? suffix;
  final IconData? icon;
  final bool isPositiveTrend;
  final String? trendValue;

  const SbStatistic({
    super.key,
    required this.label,
    required this.value,
    this.prefix,
    this.suffix,
    this.icon,
    this.isPositiveTrend = true,
    this.trendValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: SBSpacing.xxs),
            ],
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: SBSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (prefix != null)
              Text(
                prefix!,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (suffix != null)
              Text(
                suffix!,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        if (trendValue != null) ...[
          const SizedBox(height: SBSpacing.xxs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPositiveTrend ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                size: 14,
                color: isPositiveTrend ? Colors.green.shade600 : colorScheme.error,
              ),
              const SizedBox(width: 4),
              Text(
                trendValue!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isPositiveTrend ? Colors.green.shade700 : colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
