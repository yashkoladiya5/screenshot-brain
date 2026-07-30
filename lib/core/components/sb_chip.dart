import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;
  final bool selected;

  const SbChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final chipColor = color ?? colorScheme.primary;

    final widthBox = const SizedBox(width: SBSpacing.xs);
    final borderRadius = BorderRadius.circular(SBRadius.lg);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: SBAnimations.fast,
        padding: const EdgeInsets.symmetric(horizontal: SBSpacing.md, vertical: SBSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? chipColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: borderRadius,
          border: Border.all(
            color: selected ? chipColor.withValues(alpha: 0.4) : colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: SBSizes.iconSm, color: selected ? chipColor : colorScheme.onSurfaceVariant),
              widthBox,
            ],
            Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                color: selected ? chipColor : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
