import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbDividerText extends StatelessWidget {
  final String text;
  final double padding;

  const SbDividerText({
    super.key,
    required this.text,
    this.padding = SBSpacing.md,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final divider = Expanded(
      child: Divider(
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: padding),
      child: Row(
        children: [
          divider,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SBSpacing.md),
            child: Text(
              text.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          divider,
        ],
      ),
    );
  }
}
