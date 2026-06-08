import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const SbErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SBSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(SBSpacing.xl),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(SBRadius.xxl),
              ),
              child: Icon(Icons.error_outline_rounded, size: 40, color: theme.colorScheme.error),
            ),
            const SizedBox(height: SBSpacing.lg),
            Text(message, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: SBSpacing.lg),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: SBSizes.iconMd),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
