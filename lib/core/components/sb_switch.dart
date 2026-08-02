import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final Color? activeColor;

  const SbSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final switchWidget = Switch(
      value: value,
      onChanged: onChanged,
      activeColor: colorScheme.onPrimary,
      activeTrackColor: activeColor ?? colorScheme.primary,
      inactiveThumbColor: colorScheme.outline,
      inactiveTrackColor: colorScheme.surfaceContainerHighest,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    if (label == null) return switchWidget;

    return InkWell(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      borderRadius: BorderRadius.circular(SBRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: SBSpacing.xs, horizontal: SBSpacing.xxs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            switchWidget,
            const SizedBox(width: SBSpacing.sm),
            Text(
              label!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: onChanged != null ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
