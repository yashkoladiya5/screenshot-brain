import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbLoading extends StatelessWidget {
  final String? message;

  const SbLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: theme.colorScheme.primary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: SBSpacing.lg),
            Text(message!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}
