import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbAccordion extends StatelessWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;
  final Widget? leading;

  const SbAccordion({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          title,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        leading: leading,
        initiallyExpanded: initiallyExpanded,
        iconColor: colorScheme.primary,
        collapsedIconColor: colorScheme.onSurfaceVariant,
        tilePadding: const EdgeInsets.symmetric(horizontal: SBSpacing.md, vertical: SBSpacing.xs),
        childrenPadding: const EdgeInsets.only(
          left: SBSpacing.md,
          right: SBSpacing.md,
          bottom: SBSpacing.md,
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [child],
      ),
    );
  }
}
