import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../utils/context_extensions.dart';

/// Consistent error-state presentation with a real, wired-in retry action.
///
/// Backward compatible with `AppErrorWidget(message: ..., onRetry: ...)`;
/// adds an optional [title], custom [icon], [iconSize] and [retryLabel],
/// plus a screen-reader [semanticsLabel]. When [onRetry] is provided a
/// filled "Try Again" (or [retryLabel]) button is rendered and invokes it.
class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  /// Optional heading above the error message; hidden when null.
  final String? title;

  /// Badge icon; override for different failure kinds.
  final IconData icon;

  /// Badge icon size; defaults to the state-family size (40).
  final double? iconSize;

  /// Label of the retry button; defaults to `Try Again`.
  final String? retryLabel;

  /// Accessibility announcement; defaults to the [message].
  final String? semanticsLabel;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.title,
    this.icon = Icons.error_outline_rounded,
    this.iconSize,
    this.retryLabel,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Semantics(
      container: true,
      label: semanticsLabel ?? message,
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
                  color: colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(SBRadius.xxl),
                ),
                child: Icon(
                  icon,
                  size: iconSize ?? 40,
                  color: colorScheme.error,
                ),
              ),
              if (title != null) ...[
                const SizedBox(height: SBSpacing.xl),
                Text(
                  title!,
                  style: textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: SBSpacing.lg),
              Text(
                message,
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: SBSpacing.lg),
                FilledButton.icon(
                  key: const Key('appErrorRetryButton'),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: SBSizes.iconMd),
                  label: Text(retryLabel ?? 'Try Again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
