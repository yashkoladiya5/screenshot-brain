import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? action;

  const SbEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final paddingValue = const EdgeInsets.all(SBSpacing.xl);
    final borderRadius = BorderRadius.circular(SBRadius.xxl);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SBSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: paddingValue,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: borderRadius,
              ),
              child: Icon(icon, size: 40, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: SBSpacing.xl),
            Text(title, style: textTheme.headlineSmall, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: SBSpacing.sm),
              Text(
                subtitle!,
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: SBSpacing.xxl),
              action!,
            ] else if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: SBSpacing.xxl),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
