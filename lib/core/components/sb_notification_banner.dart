import 'package:flutter/material.dart';
import '../design/tokens.dart';

enum SbNotificationType { info, success, warning, error }

class SbNotificationBanner extends StatelessWidget {
  final String message;
  final SbNotificationType type;
  final VoidCallback? onClose;
  final IconData? icon;

  const SbNotificationBanner({
    super.key,
    required this.message,
    this.type = SbNotificationType.info,
    this.onClose,
    this.icon,
  });

  Color _getBackgroundColor(ColorScheme colorScheme) {
    switch (type) {
      case SbNotificationType.info:
        return colorScheme.primaryContainer;
      case SbNotificationType.success:
        return Colors.green.withValues(alpha: 0.2); // Usually need a custom success color in tokens
      case SbNotificationType.warning:
        return Colors.orange.withValues(alpha: 0.2);
      case SbNotificationType.error:
        return colorScheme.errorContainer;
    }
  }

  Color _getForegroundColor(ColorScheme colorScheme) {
    switch (type) {
      case SbNotificationType.info:
        return colorScheme.onPrimaryContainer;
      case SbNotificationType.success:
        return Colors.green.shade800; // Better to rely on theme tokens if available
      case SbNotificationType.warning:
        return Colors.orange.shade900;
      case SbNotificationType.error:
        return colorScheme.onErrorContainer;
    }
  }

  IconData _getDefaultIcon() {
    if (icon != null) return icon!;
    switch (type) {
      case SbNotificationType.info:
        return Icons.info_outline_rounded;
      case SbNotificationType.success:
        return Icons.check_circle_outline_rounded;
      case SbNotificationType.warning:
        return Icons.warning_amber_rounded;
      case SbNotificationType.error:
        return Icons.error_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final bg = _getBackgroundColor(colorScheme);
    final fg = _getForegroundColor(colorScheme);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: SBSpacing.md, vertical: SBSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: SBSpacing.md, vertical: SBSpacing.sm),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(SBRadius.md),
        border: Border.all(
          color: fg.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_getDefaultIcon(), color: fg, size: SBSizes.iconMd),
          const SizedBox(width: SBSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          if (onClose != null) ...[
            const SizedBox(width: SBSpacing.sm),
            GestureDetector(
              onTap: onClose,
              child: Icon(Icons.close_rounded, color: fg, size: SBSizes.iconSm),
            ),
          ],
        ],
      ),
    );
  }
}
