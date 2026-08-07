import 'package:flutter/material.dart';
import '../design/tokens.dart';
import 'sb_avatar.dart'; // Assuming this exists or falls back to basic

class SbAvatarGroup extends StatelessWidget {
  final List<String> imageUrls;
  final int maxAvatars;
  final double size;

  const SbAvatarGroup({
    super.key,
    required this.imageUrls,
    this.maxAvatars = 4,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final displayUrls = imageUrls.take(maxAvatars).toList();
    final remainingCount = imageUrls.length - maxAvatars;

    return SizedBox(
      height: size,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          for (int i = 0; i < displayUrls.length; i++)
            Positioned(
              left: i * (size * 0.7), // Overlap effect
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 2),
                ),
                child: CircleAvatar(
                  radius: (size - 4) / 2, // Account for border
                  backgroundImage: NetworkImage(displayUrls[i]),
                  backgroundColor: colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
          if (remainingCount > 0)
            Positioned(
              left: displayUrls.length * (size * 0.7),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$remainingCount',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
