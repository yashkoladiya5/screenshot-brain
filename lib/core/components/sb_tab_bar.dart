import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbTab extends StatelessWidget {
  final String label;
  final int count;

  const SbTab({super.key, required this.label, this.count = 0});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final widthBox = const SizedBox(width: SBSpacing.xs);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: textTheme.titleSmall),
        if (count > 0) ...[
          widthBox,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: SBSpacing.sm, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(SBRadius.full),
            ),
            child: Text('$count', style: textTheme.labelSmall?.copyWith(color: colorScheme.primary)),
          ),
        ],
      ],
    );
  }
}
