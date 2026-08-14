import 'package:flutter/material.dart';
import '../design/tokens.dart';

enum SbInfoCardType { info, warning, success }

class SbInfoCard extends StatelessWidget {
  final String title;
  final String description;
  final SbInfoCardType type;
  final IconData? iconOverride;

  const SbInfoCard({
    super.key,
    required this.title,
    required this.description,
    this.type = SbInfoCardType.info,
    this.iconOverride,
  });

  IconData get _icon {
    if (iconOverride != null) return iconOverride!;
    switch (type) {
      case SbInfoCardType.info:
        return Icons.info_outline_rounded;
      case SbInfoCardType.warning:
        return Icons.warning_amber_rounded;
      case SbInfoCardType.success:
        return Icons.check_circle_outline_rounded;
    }
  }

  Color _getIconColor(ColorScheme colorScheme) {
    switch (type) {
      case SbInfoCardType.info:
        return colorScheme.primary;
      case SbInfoCardType.warning:
        return Colors.orange.shade800;
      case SbInfoCardType.success:
        return Colors.green.shade700;
    }
  }

  Color _getBackgroundColor(ColorScheme colorScheme) {
    switch (type) {
      case SbInfoCardType.info:
        return colorScheme.primaryContainer.withValues(alpha: 0.3);
      case SbInfoCardType.warning:
        return Colors.orange.withValues(alpha: 0.1);
      case SbInfoCardType.success:
        return Colors.green.withValues(alpha: 0.1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final iconColor = _getIconColor(colorScheme);
    final bgColor = _getBackgroundColor(colorScheme);

    return Container(
      padding: const EdgeInsets.all(SBSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(SBRadius.md),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _icon,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(width: SBSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: SBSpacing.xxs),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
