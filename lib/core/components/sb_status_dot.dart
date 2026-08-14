import 'package:flutter/material.dart';

enum SbStatusDotState { online, offline, away, busy }

class SbStatusDot extends StatelessWidget {
  final SbStatusDotState state;
  final double size;
  final bool showBorder;

  const SbStatusDot({
    super.key,
    required this.state,
    this.size = 12.0,
    this.showBorder = true,
  });

  Color _getColor(ColorScheme colorScheme) {
    switch (state) {
      case SbStatusDotState.online:
        return Colors.green.shade500;
      case SbStatusDotState.offline:
        return colorScheme.outlineVariant;
      case SbStatusDotState.away:
        return Colors.amber.shade500;
      case SbStatusDotState.busy:
        return colorScheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final color = _getColor(colorScheme);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: theme.scaffoldBackgroundColor,
                width: size * 0.15, // Dynamic border width based on size
              )
            : null,
        boxShadow: [
          if (state == SbStatusDotState.online)
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 4,
              spreadRadius: 1,
            ),
        ],
      ),
    );
  }
}
