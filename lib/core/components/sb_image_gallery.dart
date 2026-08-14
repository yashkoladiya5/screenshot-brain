import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbImageGallery extends StatelessWidget {
  final List<String> imageUrls;
  final double height;
  final double spacing;
  final double borderRadius;
  final ValueChanged<int>? onImageTap;

  const SbImageGallery({
    super.key,
    required this.imageUrls,
    this.height = 120.0,
    this.spacing = SBSpacing.sm,
    this.borderRadius = SBRadius.md,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        separatorBuilder: (context, index) => SizedBox(width: spacing),
        itemBuilder: (context, index) {
          final url = imageUrls[index];
          
          return GestureDetector(
            onTap: onImageTap != null ? () => onImageTap!(index) : null,
            child: AspectRatio(
              aspectRatio: 1.0, // Force square items
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  color: colorScheme.surfaceContainerHighest,
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary.withValues(alpha: 0.5),
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
