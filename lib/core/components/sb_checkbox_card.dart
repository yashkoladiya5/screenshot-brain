import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbCheckboxCard extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final Widget title;
  final Widget? subtitle;
  final Widget? icon;

  const SbCheckboxCard({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final activeColor = colorScheme.primary;
    final borderColor = value ? activeColor : colorScheme.outlineVariant.withValues(alpha: 0.5);
    final backgroundColor = value 
        ? activeColor.withValues(alpha: 0.08)
        : colorScheme.surface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(SBRadius.lg),
        border: Border.all(
          color: borderColor,
          width: value ? 2.0 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(SBRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(SBSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: SBSpacing.md, top: 2),
                    child: IconTheme(
                      data: IconThemeData(
                        color: value ? activeColor : colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                      child: icon!,
                    ),
                  ),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DefaultTextStyle(
                        style: theme.textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        child: title,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        DefaultTextStyle(
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          child: subtitle!,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: SBSpacing.sm),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: value ? activeColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(SBRadius.sm),
                    border: Border.all(
                      color: value ? activeColor : colorScheme.outline,
                      width: 2.0,
                    ),
                  ),
                  child: value 
                      ? Icon(Icons.check_rounded, size: 16, color: colorScheme.onPrimary)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
