import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String? label;
  final Color? activeColor;

  const SbCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final checkbox = Checkbox(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor ?? colorScheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SBRadius.sm),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    if (label == null) return checkbox;

    return InkWell(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      borderRadius: BorderRadius.circular(SBRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: SBSpacing.xs, horizontal: SBSpacing.xxs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            checkbox,
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
