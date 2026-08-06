import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbDialog {
  /// Shows a unified styled dialog for the app.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    String? confirmText,
    VoidCallback? onConfirm,
    String? cancelText,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SBRadius.xl),
          ),
          backgroundColor: colorScheme.surface,
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(SBSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: SBSpacing.md),
                DefaultTextStyle(
                  style: theme.textTheme.bodyMedium!.copyWith(color: colorScheme.onSurfaceVariant),
                  child: content,
                ),
                const SizedBox(height: SBSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (cancelText != null) ...[
                      TextButton(
                        onPressed: onCancel ?? () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(horizontal: SBSpacing.md, vertical: SBSpacing.sm),
                        ),
                        child: Text(cancelText),
                      ),
                      const SizedBox(width: SBSpacing.sm),
                    ],
                    if (confirmText != null)
                      FilledButton(
                        onPressed: onConfirm,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: SBSpacing.lg, vertical: SBSpacing.sm),
                        ),
                        child: Text(confirmText),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
