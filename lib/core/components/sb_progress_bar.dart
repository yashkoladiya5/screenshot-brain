import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final Color? color;
  final Color? backgroundColor;

  const SbProgressBar({
    super.key,
    required this.progress,
    this.height = 8.0,
    this.color,
    this.backgroundColor,
  }) : assert(progress >= 0.0 && progress <= 1.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final activeColor = color ?? colorScheme.primary;
    final bgColor = backgroundColor ?? colorScheme.surfaceContainerHighest;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(SBRadius.full),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: activeColor,
            borderRadius: BorderRadius.circular(SBRadius.full),
          ),
        ),
      ),
    );
  }
}
