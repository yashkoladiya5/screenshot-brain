import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;

  const SbListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final titleColor = isDestructive ? colorScheme.error : colorScheme.onSurface;
    final subtitleColor = isDestructive ? colorScheme.error.withValues(alpha: 0.8) : colorScheme.onSurfaceVariant;
    final iconColor = isDestructive ? colorScheme.error : colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SBRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: SBSpacing.md, vertical: SBSpacing.sm),
          child: Row(
            children: [
              if (leading != null) ...[
                IconTheme(
                  data: IconThemeData(color: iconColor, size: SBSizes.iconMd),
                  child: leading!,
                ),
                const SizedBox(width: SBSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: SBSpacing.xxs),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: SBSpacing.md),
                IconTheme(
                  data: IconThemeData(color: colorScheme.onSurfaceVariant, size: SBSizes.iconSm),
                  child: trailing!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
