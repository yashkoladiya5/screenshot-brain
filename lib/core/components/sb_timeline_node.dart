import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbTimelineNode extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final bool isCompleted;
  final Widget title;
  final Widget? subtitle;
  final Widget? child;

  const SbTimelineNode({
    super.key,
    this.isFirst = false,
    this.isLast = false,
    this.isCompleted = false,
    required this.title,
    this.subtitle,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final nodeColor = isCompleted ? colorScheme.primary : colorScheme.outlineVariant;
    final lineColor = isCompleted ? colorScheme.primary : colorScheme.surfaceContainerHighest;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Indicator Column
          SizedBox(
            width: 32,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Connecting line
                if (!isLast)
                  Positioned(
                    top: 24, // Start below the node
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: lineColor,
                    ),
                  ),
                // The Node itself
                Positioned(
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isCompleted ? nodeColor : colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: nodeColor,
                        width: 2,
                      ),
                    ),
                    child: isCompleted
                        ? Icon(Icons.check_rounded, size: 10, color: colorScheme.onPrimary)
                        : null,
                  ),
                ),
              ],
            ),
          ),
          
          // Content Column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: SBSpacing.sm, bottom: SBSpacing.lg, top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DefaultTextStyle(
                    style: theme.textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                    ),
                    child: title,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    DefaultTextStyle(
                      style: theme.textTheme.labelMedium!.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                      child: subtitle!,
                    ),
                  ],
                  if (child != null) ...[
                    const SizedBox(height: SBSpacing.sm),
                    child!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
