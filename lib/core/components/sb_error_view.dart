import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbErrorView extends StatelessWidget {
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onRetry;

  const SbErrorView({
    super.key,
    this.title = 'Something went wrong',
    this.description = 'We encountered an unexpected error. Please try again.',
    this.buttonText = 'Try Again',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SBSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(SBSpacing.xl),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: SBSpacing.xl),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: SBSpacing.sm),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: SBSpacing.xl),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(buttonText),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: SBSpacing.xl, vertical: SBSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SBRadius.full),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
