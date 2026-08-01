import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbAlert extends StatelessWidget {
  final String title;
  final String? description;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onClose;

  const SbAlert({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.color,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final alertColor = color ?? colorScheme.primaryContainer;
    final onAlertColor = colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(SBSpacing.md),
      decoration: BoxDecoration(
        color: alertColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(SBRadius.md),
        border: Border.all(color: alertColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: alertColor, size: SBSizes.iconMd),
            const SizedBox(width: SBSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(color: onAlertColor, fontWeight: FontWeight.bold),
                ),
                if (description != null) ...[
                  const SizedBox(height: SBSpacing.xxs),
                  Text(
                    description!,
                    style: theme.textTheme.bodySmall?.copyWith(color: onAlertColor),
                  ),
                ],
              ],
            ),
          ),
          if (onClose != null)
            InkWell(
              onTap: onClose,
              child: Icon(Icons.close_rounded, size: SBSizes.iconSm, color: onAlertColor.withValues(alpha: 0.6)),
            ),
        ],
      ),
    );
  }
}
