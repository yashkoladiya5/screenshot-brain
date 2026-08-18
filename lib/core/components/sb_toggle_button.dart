import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbToggleButton extends StatelessWidget {
  final bool isSelected;
  final ValueChanged<bool> onToggle;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SbToggleButton({
    super.key,
    required this.isSelected,
    required this.onToggle,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: SBSpacing.md, vertical: SBSpacing.sm),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onToggle(!isSelected),
        borderRadius: BorderRadius.circular(SBRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: padding,
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(SBRadius.md),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: DefaultTextStyle(
            style: theme.textTheme.labelLarge!.copyWith(
              color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            child: IconTheme(
              data: IconThemeData(
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                size: 20,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
