import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? minHeight;
  final Color? color;

  const SbCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.margin,
    this.minHeight,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = Container(
      constraints: minHeight != null ? BoxConstraints(minHeight: minHeight!) : null,
      padding: padding ?? const EdgeInsets.all(SBSpacing.lg),
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(SBRadius.xl),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: child,
    );

    if (onTap != null || onLongPress != null) {
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(SBRadius.xl),
            child: card,
          ),
        ),
      );
    }

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: card,
    );
  }
}

class SbCardHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final IconData? leadingIcon;
  final Color? leadingColor;

  const SbCardHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leadingIcon,
    this.leadingColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (leadingIcon != null) ...[
          Container(
            padding: const EdgeInsets.all(SBSpacing.sm),
            decoration: BoxDecoration(
              color: (leadingColor ?? theme.colorScheme.primary).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(SBRadius.sm),
            ),
            child: Icon(leadingIcon, color: leadingColor ?? theme.colorScheme.primary, size: SBSizes.iconMd),
          ),
          const SizedBox(width: SBSpacing.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: SBSpacing.xxs),
                  child: Text(subtitle!, style: theme.textTheme.bodySmall),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
