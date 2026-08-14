import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbNumberStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  const SbNumberStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final atMin = value <= min;
    final atMax = value >= max;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(SBRadius.full),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            onPressed: atMin ? null : () => onChanged(value - 1),
            colorScheme: colorScheme,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: SBSpacing.sm),
            constraints: const BoxConstraints(minWidth: 40),
            alignment: Alignment.center,
            child: Text(
              '$value',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            onPressed: atMax ? null : () => onChanged(value + 1),
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final ColorScheme colorScheme;

  const _StepperButton({
    required this.icon,
    required this.onPressed,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(SBRadius.full),
        child: Padding(
          padding: const EdgeInsets.all(SBSpacing.sm),
          child: Icon(
            icon,
            size: 20,
            color: onPressed == null
                ? colorScheme.onSurfaceVariant.withValues(alpha: 0.3)
                : colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
