import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbToast {
  /// Shows a unified styled toast/snackbar for the app.
  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final bgColor = isError ? colorScheme.errorContainer : colorScheme.secondaryContainer;
    final fgColor = isError ? colorScheme.onErrorContainer : colorScheme.onSecondaryContainer;
    final icon = isError ? Icons.error_outline_rounded : Icons.info_outline_rounded;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: fgColor, size: SBSizes.iconSm),
              const SizedBox(width: SBSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(color: fgColor),
                ),
              ),
            ],
          ),
          backgroundColor: bgColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SBRadius.sm),
          ),
          duration: duration,
          margin: const EdgeInsets.all(SBSpacing.md),
        ),
      );
  }
}
