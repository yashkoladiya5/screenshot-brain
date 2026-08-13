import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbSnackbar {
  /// Shows a standardized snackbar with the design system tokens.
  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final backgroundColor = isError ? colorScheme.error : colorScheme.inverseSurface;
    final textColor = isError ? colorScheme.onError : colorScheme.onInverseSurface;
    final actionColor = isError ? colorScheme.onError : colorScheme.inversePrimary;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor,
            ),
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SBRadius.sm),
          ),
          margin: const EdgeInsets.all(SBSpacing.md),
          duration: duration,
          action: actionLabel != null
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: actionColor,
                  onPressed: onAction ?? () {},
                )
              : null,
        ),
      );
  }
}
