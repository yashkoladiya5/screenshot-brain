import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbLoading extends StatelessWidget {
  final String? message;

  const SbLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final heightBox = const SizedBox(height: SBSpacing.lg);
    final sizeMin = MainAxisSize.min;
    return Center(
      child: Column(
        mainAxisSize: sizeMin,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colorScheme.primary,
            ),
          ),
          if (message != null) ...[
            heightBox,
            Text(message!, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}
