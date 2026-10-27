import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../utils/context_extensions.dart';

/// Consistent loading state of the shared widget family.
///
/// Backward compatible with `LoadingWidget(message: ...)`; adds optional
/// [icon] (rendered above the indicator as a contextual hint), indicator
/// sizing via [indicatorSize] / [strokeWidth], and a screen-reader
/// [semanticsLabel] (defaults to `Loading`).
///
/// The body is scrollable so a long `message` on a small surface (320x480)
/// never clips. The spinner animates through the indicator's own controller,
/// which is disposed with the widget and pauses when it is offstage, so there
/// is no leaked ticker to manage here.
class LoadingWidget extends StatelessWidget {
  final String? message;

  /// Optional contextual icon shown above the spinner; hidden when null.
  final IconData? icon;

  /// Diameter of the circular indicator; defaults to 32.
  final double indicatorSize;

  /// Stroke width of the circular indicator; defaults to 3.
  final double strokeWidth;

  /// Accessibility announcement; defaults to `Loading` (+ message).
  final String? semanticsLabel;

  const LoadingWidget({
    super.key,
    this.message,
    this.icon,
    this.indicatorSize = 32,
    this.strokeWidth = 3,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Semantics(
      container: true,
      label:
          semanticsLabel ?? (message == null ? 'Loading' : 'Loading. $message'),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: SBSpacing.xxxl,
            vertical: SBSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: SBSizes.iconXl,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: SBSpacing.lg),
              ],
              SizedBox(
                width: indicatorSize,
                height: indicatorSize,
                child: CircularProgressIndicator(
                  strokeWidth: strokeWidth,
                  color: colorScheme.primary,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: SBSpacing.lg),
                Text(
                  message!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
