import 'package:flutter/material.dart';

class SbSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final Color? activeColor;

  const SbSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.label,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: activeColor ?? colorScheme.primary,
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
        thumbColor: activeColor ?? colorScheme.primary,
        overlayColor: (activeColor ?? colorScheme.primary).withValues(alpha: 0.12),
        valueIndicatorColor: colorScheme.onSurface,
        valueIndicatorTextStyle: theme.textTheme.labelMedium?.copyWith(
          color: colorScheme.surface,
        ),
      ),
      child: Slider(
        value: value,
        onChanged: onChanged,
        min: min,
        max: max,
        divisions: divisions,
        label: label,
      ),
    );
  }
}
