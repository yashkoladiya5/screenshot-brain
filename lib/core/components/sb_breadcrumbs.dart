import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbBreadcrumbs extends StatelessWidget {
  final List<String> paths;
  final ValueChanged<int>? onPathTapped;

  const SbBreadcrumbs({
    super.key,
    required this.paths,
    this.onPathTapped,
  }) : assert(paths.length > 0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(paths.length * 2 - 1, (index) {
          final isSeparator = index % 2 != 0;
          final pathIndex = index ~/ 2;

          if (isSeparator) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: SBSpacing.xxs),
              child: Icon(
                Icons.chevron_right_rounded,
                size: SBSizes.iconSm,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            );
          }

          final isLast = pathIndex == paths.length - 1;
          final color = isLast ? colorScheme.onSurface : colorScheme.primary;
          final weight = isLast ? FontWeight.w600 : FontWeight.normal;

          final child = Text(
            paths[pathIndex],
            style: textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: weight,
            ),
          );

          if (!isLast && onPathTapped != null) {
            return InkWell(
              onTap: () => onPathTapped!(pathIndex),
              borderRadius: BorderRadius.circular(SBRadius.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: SBSpacing.xxs, vertical: SBSpacing.xxs),
                child: child,
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: SBSpacing.xxs, vertical: SBSpacing.xxs),
            child: child,
          );
        }),
      ),
    );
  }
}
