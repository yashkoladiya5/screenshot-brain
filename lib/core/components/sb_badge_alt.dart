import 'package:flutter/material.dart';
import '../design/tokens.dart';

enum SbBadgeAltType { standard, success, warning, error }

class SbBadgeAlt extends StatelessWidget {
  final String label;
  final SbBadgeAltType type;
  final IconData? icon;

  const SbBadgeAlt({
    super.key,
    required this.label,
    this.type = SbBadgeAltType.standard,
    this.icon,
  });

  Color _getForegroundColor(ColorScheme colorScheme) {
    switch (type) {
      case SbBadgeAltType.standard:
        return colorScheme.onSurface;
      case SbBadgeAltType.success:
        return Colors.green.shade700;
      case SbBadgeAltType.warning:
        return Colors.orange.shade800;
      case SbBadgeAltType.error:
        return colorScheme.error;
    }
  }

  Color _getBorderColor(ColorScheme colorScheme) {
    switch (type) {
      case SbBadgeAltType.standard:
        return colorScheme.outlineVariant;
      case SbBadgeAltType.success:
        return Colors.green.withValues(alpha: 0.5);
      case SbBadgeAltType.warning:
        return Colors.orange.withValues(alpha: 0.5);
      case SbBadgeAltType.error:
        return colorScheme.error.withValues(alpha: 0.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final fg = _getForegroundColor(colorScheme);
    final borderColor = _getBorderColor(colorScheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: SBSpacing.sm, vertical: SBSpacing.xxs),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(SBRadius.full),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
