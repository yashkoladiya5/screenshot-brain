import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbRadio<T> extends StatelessWidget {
  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final Color? activeColor;

  const SbRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.label,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final radio = Radio<T>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: activeColor ?? colorScheme.primary,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    if (label == null) return radio;

    return InkWell(
      onTap: onChanged != null ? () => onChanged!(value) : null,
      borderRadius: BorderRadius.circular(SBRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: SBSpacing.xs, horizontal: SBSpacing.xxs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            radio,
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
