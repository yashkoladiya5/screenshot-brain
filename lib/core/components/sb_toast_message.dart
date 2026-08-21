import 'package:flutter/material.dart';
import '../design/tokens.dart';

enum SbToastType { success, error, warning, info }

class SbToastMessage extends StatelessWidget {
  final String message;
  final SbToastType type;
  final VoidCallback? onClose;
  final Widget? customIcon;

  const SbToastMessage({
    super.key,
    required this.message,
    this.type = SbToastType.info,
    this.onClose,
    this.customIcon,
  });

  Color _getBackgroundColor(ColorScheme colorScheme) {
    switch (type) {
      case SbToastType.success:
        return Colors.green.shade800;
      case SbToastType.error:
        return colorScheme.error;
      case SbToastType.warning:
        return Colors.orange.shade800;
      case SbToastType.info:
        return colorScheme.primary;
    }
  }

  IconData _getDefaultIcon() {
    switch (type) {
      case SbToastType.success:
        return Icons.check_circle_rounded;
      case SbToastType.error:
        return Icons.error_rounded;
      case SbToastType.warning:
        return Icons.warning_rounded;
      case SbToastType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final backgroundColor = _getBackgroundColor(colorScheme);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: SBSpacing.lg, vertical: SBSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: SBSpacing.md, vertical: 12.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(SBRadius.lg),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          customIcon ?? Icon(_getDefaultIcon(), color: Colors.white, size: 24),
          const SizedBox(width: SBSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onClose != null) ...[
            const SizedBox(width: SBSpacing.sm),
            GestureDetector(
              onTap: onClose,
              child: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
            ),
          ]
        ],
      ),
    );
  }
}
