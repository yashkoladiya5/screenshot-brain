import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbCircleProgress extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color? color;
  final Widget? centerChild;

  const SbCircleProgress({
    super.key,
    required this.progress,
    this.size = 48.0,
    this.strokeWidth = 4.0,
    this.color,
    this.centerChild,
  }) : assert(progress >= 0.0 && progress <= 1.0);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progressColor = color ?? colorScheme.primary;
    final bgColor = colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: strokeWidth,
            backgroundColor: bgColor,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
          if (centerChild != null) centerChild!,
        ],
      ),
    );
  }
}
