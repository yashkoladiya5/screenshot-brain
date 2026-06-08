import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbTab extends StatelessWidget {
  final String label;
  final int count;

  const SbTab({super.key, required this.label, this.count = 0});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textTheme.titleSmall),
        if (count > 0) ...[
          const SizedBox(width: SBSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: SBSpacing.sm, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(SBRadius.full),
            ),
            child: Text('$count', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)),
          ),
        ],
      ],
    );
  }
}
