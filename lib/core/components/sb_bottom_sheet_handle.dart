import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbBottomSheetHandle extends StatelessWidget {
  final double width;
  final double height;
  final Color? color;

  const SbBottomSheetHandle({
    super.key,
    this.width = 40.0,
    this.height = 4.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: SBSpacing.sm),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color ?? colorScheme.outlineVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(SBRadius.full),
        ),
      ),
    );
  }
}
