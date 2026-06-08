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
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SBSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(SBSpacing.xl),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(SBRadius.xxl),
              ),
              child: Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: SBSpacing.xl),
            Text(title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: SBSpacing.sm),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
