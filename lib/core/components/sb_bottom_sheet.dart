import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbBottomSheet {
  /// Shows a unified styled bottom sheet for the app.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = true,
    bool useRootNavigator = true,
    String? title,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(SBRadius.xl),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: SBSpacing.sm),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                if (title != null) ...[
                  const SizedBox(height: SBSpacing.md),
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: SBSpacing.sm),
                  Divider(height: 1, color: colorScheme.outlineVariant),
                ],
                const SizedBox(height: SBSpacing.md),
                Flexible(child: child),
                const SizedBox(height: SBSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }
}
