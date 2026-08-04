import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbEmptyList extends StatelessWidget {
  final String title;
  final String? message;
  final IconData? icon;
  final Widget? action;

  const SbEmptyList({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SBSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(SBSpacing.lg),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: SBSpacing.lg),
            ],
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: SBSpacing.xs),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: SBSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
