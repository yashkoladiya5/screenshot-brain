import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbTooltip extends StatelessWidget {
  final Widget child;
  final String message;
  final bool preferBelow;
  final EdgeInsetsGeometry? padding;

  const SbTooltip({
    super.key,
    required this.child,
    required this.message,
    this.preferBelow = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Tooltip(
      message: message,
      preferBelow: preferBelow,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: SBSpacing.md, vertical: SBSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(SBRadius.sm),
      ),
      textStyle: textTheme.labelSmall?.copyWith(
        color: colorScheme.surface,
      ),
      child: child,
    );
  }
}
