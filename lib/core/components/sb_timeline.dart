import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbTimelineItem {
  final String title;
  final String? description;
  final String? time;
  final bool isCompleted;
  final bool isLast;

  SbTimelineItem({
    required this.title,
    this.description,
    this.time,
    this.isCompleted = false,
    this.isLast = false,
  });
}

class SbTimeline extends StatelessWidget {
  final List<SbTimelineItem> items;

  const SbTimeline({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isCompleted = item.isCompleted;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isCompleted ? colorScheme.primary : colorScheme.surface,
                      border: Border.all(
                        color: isCompleted ? colorScheme.primary : colorScheme.outlineVariant,
                        width: 2,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!item.isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isCompleted ? colorScheme.primary : colorScheme.outlineVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: SBSpacing.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: SBSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (item.time != null) ...[
                            const SizedBox(width: SBSpacing.sm),
                            Text(
                              item.time!,
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (item.description != null) ...[
                        const SizedBox(height: SBSpacing.xxs),
                        Text(
                          item.description!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
