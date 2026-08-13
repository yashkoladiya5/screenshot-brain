import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbEmptyStateImage extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;
  final Widget? action;
  final double imageHeight;

  const SbEmptyStateImage({
    super.key,
    required this.imagePath,
    required this.title,
    required this.description,
    this.action,
    this.imageHeight = 200.0,
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
            Image.asset(
              imagePath,
              height: imageHeight,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.image_not_supported_rounded,
                  size: 100,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                );
              },
            ),
            const SizedBox(height: SBSpacing.xl),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
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
            if (action != null) ...[
              const SizedBox(height: SBSpacing.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
