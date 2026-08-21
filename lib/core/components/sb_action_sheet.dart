import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbActionSheetItem {
  final String title;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const SbActionSheetItem({
    required this.title,
    required this.onTap,
    this.icon,
    this.isDestructive = false,
  });
}

class SbActionSheet extends StatelessWidget {
  final String? title;
  final String? message;
  final List<SbActionSheetItem> actions;
  final VoidCallback? onCancel;

  const SbActionSheet({
    super.key,
    this.title,
    this.message,
    required this.actions,
    this.onCancel,
  });

  static Future<void> show(
    BuildContext context, {
    String? title,
    String? message,
    required List<SbActionSheetItem> actions,
    VoidCallback? onCancel,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SbActionSheet(
        title: title,
        message: message,
        actions: actions,
        onCancel: onCancel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Add safe area padding at the bottom for modern devices
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: SBSpacing.md,
        right: SBSpacing.md,
        bottom: bottomPadding > 0 ? bottomPadding : SBSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main Actions Container
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(SBRadius.xl),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null || message != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: SBSpacing.lg, vertical: SBSpacing.md),
                    child: Column(
                      children: [
                        if (title != null)
                          Text(
                            title!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (title != null && message != null) const SizedBox(height: 4),
                        if (message != null)
                          Text(
                            message!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                if (title != null || message != null)
                  Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ...List.generate(actions.length, (index) {
                  final action = actions[index];
                  final isLast = index == actions.length - 1;
                  final itemColor = action.isDestructive ? colorScheme.error : colorScheme.primary;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            action.onTap();
                          },
                          borderRadius: BorderRadius.only(
                            bottomLeft: isLast ? const Radius.circular(SBRadius.xl) : Radius.zero,
                            bottomRight: isLast ? const Radius.circular(SBRadius.xl) : Radius.zero,
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: SBSpacing.md),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (action.icon != null) ...[
                                  Icon(action.icon, color: itemColor, size: 20),
                                  const SizedBox(width: SBSpacing.sm),
                                ],
                                Text(
                                  action.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: itemColor,
                                    fontWeight: action.isDestructive ? FontWeight.w600 : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (!isLast)
                        Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: SBSpacing.sm),
          // Cancel Button Container
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(SBRadius.xl),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  onCancel?.call();
                },
                borderRadius: BorderRadius.circular(SBRadius.xl),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: SBSpacing.md),
                  child: Text(
                    'Cancel',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
