import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;

  const SbBadge({
    super.key,
    required this.label,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    final badgeColor = color ?? colorScheme.primary;
    final onBadgeColor = textColor ?? colorScheme.onPrimary;
    
    final paddingBadge = const EdgeInsets.symmetric(horizontal: SBSpacing.sm, vertical: SBSpacing.xxs);
    final radiusBadge = BorderRadius.circular(SBRadius.full);

    return Container(
      padding: paddingBadge,
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: radiusBadge,
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          color: onBadgeColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
