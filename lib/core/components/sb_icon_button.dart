import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final EdgeInsetsGeometry? padding;

  const SbIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.backgroundColor,
    this.size = SBSizes.iconMd,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final iconColor = color ?? colorScheme.primary;
    final bg = backgroundColor ?? colorScheme.primary.withValues(alpha: 0.1);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(SBRadius.md),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(SBRadius.md),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(SBSpacing.sm),
          child: Icon(
            icon,
            size: size,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
