import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../utils/context_extensions.dart';

/// Consistent empty-state presentation with an optional actionable button.
///
/// Backward compatible with the previous `(icon, title, subtitle,
/// actionLabel, onAction)` API; adds a fully custom [action] widget slot,
/// [iconSize] tuning and a screen-reader [semanticsLabel].
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Optional custom action widget. Takes precedence over the built-in
  /// filled button rendered from [actionLabel] + [onAction].
  final Widget? action;

  /// Badge icon size; defaults to the state-family size (40).
  final double? iconSize;

  /// Accessibility announcement; defaults to `title (+ subtitle)`.
  final String? semanticsLabel;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.action,
    this.iconSize,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    final effectiveAction =
        action ??
        ((actionLabel != null && onAction != null)
            ? FilledButton(onPressed: onAction, child: Text(actionLabel!))
            : null);

    return Semantics(
      container: true,
      label: semanticsLabel ?? (subtitle == null ? title : '$title. $subtitle'),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SBSpacing.xxxl,
            vertical: SBSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(SBSpacing.xl),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(SBRadius.xxl),
                ),
                child: Icon(
                  icon,
                  size: iconSize ?? 40,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: SBSpacing.xl),
              Text(
                title,
                style: textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: SBSpacing.sm),
                Text(
                  subtitle!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (effectiveAction != null) ...[
                const SizedBox(height: SBSpacing.xxl),
                effectiveAction,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
