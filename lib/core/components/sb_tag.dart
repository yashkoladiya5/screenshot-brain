import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbTag extends StatelessWidget {
  final String label;
  final Color? color;
  final VoidCallback? onDeleted;
  final IconData? icon;

  const SbTag({
    super.key,
    required this.label,
    this.color,
    this.onDeleted,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final tagColor = color ?? colorScheme.secondaryContainer;
    final onTagColor = colorScheme.onSecondaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: SBSpacing.sm, vertical: SBSpacing.xxs),
      decoration: BoxDecoration(
        color: tagColor,
        borderRadius: BorderRadius.circular(SBRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: SBSizes.iconSm, color: onTagColor),
            const SizedBox(width: SBSpacing.xxs),
          ],
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: onTagColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onDeleted != null) ...[
            const SizedBox(width: SBSpacing.xxs),
            InkWell(
              onTap: onDeleted,
              child: Icon(Icons.close_rounded, size: SBSizes.iconSm, color: onTagColor.withValues(alpha: 0.7)),
            ),
          ],
        ],
      ),
    );
  }
}
