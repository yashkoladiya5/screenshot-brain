import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SbSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final paddingBtn = const EdgeInsets.symmetric(horizontal: SBSpacing.md, vertical: SBSpacing.xs);
    final mainAlign = MainAxisAlignment.spaceBetween;
    return Row(
      mainAxisAlignment: mainAlign,
      children: [
        Text(title, style: textTheme.titleMedium),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: paddingBtn,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel!, style: textTheme.bodySmall?.copyWith(color: colorScheme.primary)),
          ),
      ],
    );
  }
}
