import 'package:flutter/material.dart';
import '../design/tokens.dart';
import 'sb_card.dart';

class SbStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final VoidCallback? onTap;

  const SbStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final accentColor = color ?? colorScheme.primary;

    final paddingSm = const EdgeInsets.all(SBSpacing.sm);
    final radiusSm = BorderRadius.circular(SBRadius.sm);

    return SbCard(
      onTap: onTap,
      padding: const EdgeInsets.all(SBSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: paddingSm,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: radiusSm,
            ),
            child: Icon(icon, color: accentColor, size: SBSizes.iconXl),
          ),
          const SizedBox(height: SBSpacing.md),
          Text(value, style: textTheme.displaySmall?.copyWith(color: colorScheme.onSurface)),
          const SizedBox(height: SBSpacing.xxs),
          Text(label, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}
