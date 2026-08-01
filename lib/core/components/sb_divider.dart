import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbDivider extends StatelessWidget {
  final double height;
  final double thickness;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const SbDivider({
    super.key,
    this.height = SBSpacing.lg,
    this.thickness = 1.0,
    this.color,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final dividerColor = color ?? colorScheme.outlineVariant;

    Widget divider = Divider(
      height: height,
      thickness: thickness,
      color: dividerColor,
    );

    if (padding != null) {
      divider = Padding(
        padding: padding!,
        child: divider,
      );
    }

    return divider;
  }
}
