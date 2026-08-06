import 'package:flutter/material.dart';
import '../design/tokens.dart';
import 'sb_icon_button.dart';

class SbPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const SbPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  }) : assert(currentPage >= 1 && currentPage <= totalPages);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canGoBack = currentPage > 1;
    final canGoForward = currentPage < totalPages;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SbIconButton(
          icon: Icons.chevron_left_rounded,
          onPressed: canGoBack ? () => onPageChanged(currentPage - 1) : () {},
          color: canGoBack ? colorScheme.onSurface : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          backgroundColor: Colors.transparent,
        ),
        const SizedBox(width: SBSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: SBSpacing.md, vertical: SBSpacing.xs),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(SBRadius.sm),
          ),
          child: Text(
            'Page $currentPage of $totalPages',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: SBSpacing.sm),
        SbIconButton(
          icon: Icons.chevron_right_rounded,
          onPressed: canGoForward ? () => onPageChanged(currentPage + 1) : () {},
          color: canGoForward ? colorScheme.onSurface : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          backgroundColor: Colors.transparent,
        ),
      ],
    );
  }
}
