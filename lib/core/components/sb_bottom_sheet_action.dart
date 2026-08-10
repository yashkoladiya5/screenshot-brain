import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbBottomSheetAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const SbBottomSheetAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final foregroundColor = isDestructive ? colorScheme.error : colorScheme.onSurface;
    final backgroundColor = isDestructive 
        ? colorScheme.errorContainer.withValues(alpha: 0.2)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);

    return InkWell(
      onTap: () {
        Navigator.pop(context); // Close the bottom sheet first
        onTap();
      },
      borderRadius: BorderRadius.circular(SBRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: SBSpacing.lg, vertical: SBSpacing.md),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(SBRadius.md),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: foregroundColor,
              size: SBSizes.iconMd,
            ),
            const SizedBox(width: SBSpacing.md),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: foregroundColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
