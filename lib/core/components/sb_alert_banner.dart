import 'package:flutter/material.dart';
import '../design/tokens.dart';

enum SbAlertBannerType { info, success, warning, error }

class SbAlertBanner extends StatelessWidget {
  final String message;
  final SbAlertBannerType type;
  final VoidCallback? onClose;
  final Widget? action;

  const SbAlertBanner({
    super.key,
    required this.message,
    this.type = SbAlertBannerType.info,
    this.onClose,
    this.action,
  });

  Color _getBackgroundColor(ColorScheme colorScheme) {
    switch (type) {
      case SbAlertBannerType.info:
        return colorScheme.primaryContainer;
      case SbAlertBannerType.success:
        return Colors.green.shade100;
      case SbAlertBannerType.warning:
        return Colors.orange.shade100;
      case SbAlertBannerType.error:
        return colorScheme.errorContainer;
    }
  }

  Color _getTextColor(ColorScheme colorScheme) {
    switch (type) {
      case SbAlertBannerType.info:
        return colorScheme.onPrimaryContainer;
      case SbAlertBannerType.success:
        return Colors.green.shade900;
      case SbAlertBannerType.warning:
        return Colors.orange.shade900;
      case SbAlertBannerType.error:
        return colorScheme.onErrorContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final bgColor = _getBackgroundColor(colorScheme);
    final textColor = _getTextColor(colorScheme);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: SBSpacing.md, vertical: SBSpacing.sm),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(SBRadius.sm),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: SBSpacing.sm),
            action!,
          ],
          if (onClose != null) ...[
            const SizedBox(width: SBSpacing.sm),
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(SBRadius.full),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: textColor.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
