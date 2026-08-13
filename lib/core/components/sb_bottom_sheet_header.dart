import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbBottomSheetHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showDragHandle;
  final bool showCloseButton;
  final VoidCallback? onClose;

  const SbBottomSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showDragHandle = true,
    this.showCloseButton = true,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDragHandle)
          Container(
            margin: const EdgeInsets.only(top: SBSpacing.sm, bottom: SBSpacing.md),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(SBRadius.full),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(
            left: SBSpacing.md,
            right: SBSpacing.md,
            bottom: SBSpacing.md,
            top: 0, // Top padding handled by drag handle or caller
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: SBSpacing.xxs),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showCloseButton)
                IconButton(
                  icon: Icon(Icons.close_rounded, color: colorScheme.onSurfaceVariant),
                  onPressed: onClose ?? () => Navigator.pop(context),
                  splashRadius: 24,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
        Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ],
    );
  }
}
